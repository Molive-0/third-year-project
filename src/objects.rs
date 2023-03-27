use std::{
    collections::HashMap,
    default,
    io::{Cursor, Read},
    mem,
};

use bytemuck::{Pod, Zeroable};
use cgmath::{
    num_traits::float, Deg, EuclideanSpace, Euler, Matrix2, Matrix3, Matrix4, Point3, SquareMatrix,
    Vector2, Vector3, Vector4,
};
use obj::{LoadConfig, ObjData, ObjError};
use serde::{Deserialize, Serialize};
use vulkano::{
    buffer::{Buffer, BufferAllocateInfo, BufferUsage, Subbuffer},
    half::f16,
    pipeline::graphics::vertex_input::Vertex,
};

use crate::instruction_set::InstructionSet;
use crate::{mcsg_deserialise::from_reader, MemoryAllocator};

pub const PLATONIC_SOLIDS: [(&str, &[u8]); 1] = [("Buny", include_bytes!("bunny.obj"))];
pub const CSG_SOLIDS: [(&str, &[u8]); 1] = [("Primitives", include_bytes!("primitive.mcsg"))];

// We now create a buffer that will store the shape of our triangle.
// We use #[repr(C)] here to force rustc to not do anything funky with our data, although for this
// particular example, it doesn't actually change the in-memory representation.
#[repr(C)]
#[derive(Clone, Copy, Debug, Default, Zeroable, Pod, Vertex)]
pub struct OVertex {
    #[format(R32G32B32_SFLOAT)]
    position: [f32; 3],
    #[format(R32G32B32_SFLOAT)]
    normal: [f32; 3],
}

#[derive(Debug)]
pub struct Mesh {
    pub name: String,
    pub vertices: Subbuffer<[OVertex]>,
    pub indices: Subbuffer<[u32]>,
    pub pos: Point3<f32>,
    pub rot: Euler<Deg<f32>>,
    pub scale: Vector3<f32>,
}

#[derive(Debug)]
pub struct CSG {
    pub name: String,
    pub parts: Vec<CSGPart>,
    pub pos: Point3<f32>,
    pub rot: Euler<Deg<f32>>,
    pub scale: Vector3<f32>,
}

pub type Float = f64;
pub type Vec2 = Vector2<Float>;
pub type Vec3 = Vector3<Float>;
pub type Vec4 = Vector4<Float>;
pub type Mat2 = Matrix2<Float>;
pub type Mat3 = Matrix3<Float>;
pub type Mat4 = Matrix4<Float>;

#[derive(Clone, Copy, Debug, Default, PartialEq)]
pub enum Inputs {
    #[default]
    Variable,
    Float(Float),
    Vec2(Vec2),
    Vec3(Vec3),
    Vec4(Vec4),
    Mat2(Mat2),
    Mat3(Mat3),
    Mat4(Mat4),
}

#[repr(C)]
#[derive(Clone, Debug)]
pub struct CSGPart {
    pub code: u16,
    pub opcode: InstructionSet,
    pub constants: Vec<Inputs>,
    pub material: Option<Mat4>,
}

impl CSGPart {
    pub fn opcode(opcode: InstructionSet, inputs: Vec<Inputs>) -> CSGPart {
        CSGPart {
            code: (opcode as u16 & 1023)
                | inputs
                    .iter()
                    .enumerate()
                    .map(|(i, n)| {
                        if n != &Inputs::Variable {
                            1 << (15 - i)
                        } else {
                            0
                        }
                    })
                    .fold(0, |a, i| a | i),
            opcode,
            constants: inputs,
            material: None,
        }
    }

    pub fn opcode_with_material(
        opcode: InstructionSet,
        inputs: Vec<Inputs>,
        material: Mat4,
    ) -> CSGPart {
        let mut c = CSGPart::opcode(opcode, inputs);
        c.material = Some(material);
        c
    }
}

pub fn load_obj(
    memory_allocator: &MemoryAllocator,
    input: &mut dyn Read,
    name: String,
) -> Result<Vec<Mesh>, ObjError> {
    let object = ObjData::load_buf_with_config(input, LoadConfig::default())?;

    let mut vertices = vec![];

    let mut indices = vec![];

    let mut temp_hash_map = HashMap::<(u32, u32), u32>::new();

    // We're gonna have to remap all the indices that OBJ uses. Annoying.
    // Get each pair of vertex position to vertex normal and assign it a new index. This might duplicate
    // vertices or normals but each *pair* needs a unique index
    // Uses the hash map to check that we're not duplicating unnecessarily
    for g in &object.objects[0].groups {
        for p in &g.polys {
            for v in &p.0 {
                //println!("{:?}", v);
                let mapping = ((v.0) as u32, (v.2.unwrap_or(0)) as u32);
                if let Some(&exist) = &temp_hash_map.get(&mapping) {
                    //println!("{:?}", exist);
                    indices.push(exist);
                } else {
                    vertices.push(OVertex {
                        position: object.position[mapping.0 as usize],
                        normal: object.normal[mapping.1 as usize],
                    });
                    temp_hash_map.insert(mapping, (vertices.len() - 1) as u32);
                    indices.push((vertices.len() - 1) as u32);
                }
            }
        }
    }

    let vertex_buffer = Buffer::from_iter(
        memory_allocator,
        BufferAllocateInfo {
            buffer_usage: BufferUsage::VERTEX_BUFFER,
            ..Default::default()
        },
        vertices,
    )
    .unwrap();

    let index_buffer = Buffer::from_iter(
        memory_allocator,
        BufferAllocateInfo {
            buffer_usage: BufferUsage::INDEX_BUFFER,
            ..Default::default()
        },
        indices,
    )
    .unwrap();

    Ok(vec![Mesh {
        vertices: vertex_buffer,
        indices: index_buffer,
        pos: Point3 {
            x: 0.,
            y: 0.,
            z: 0.,
        },
        rot: Euler::new(Deg(0.), Deg(0.), Deg(0.)),
        scale: Vector3 {
            x: 1.,
            y: 1.,
            z: 1.,
        },
        name,
    }])
}

#[derive(Serialize, Deserialize)]
struct MCSG {
    object: Vec<MCSGObject>,
    csg: Vec<MCSGCSG>,
}
type MCSGObject = HashMap<String, String>;
type MCSGCSG = Vec<MCSGCSGPart>;
type MCSGCSGPart = HashMap<String, String>;

fn matrix3_from_string(input: &String) -> Result<Matrix3<f32>, String> {
    let vec = input
        .split(" ")
        .map(|s| s.parse::<f32>())
        .collect::<Result<Vec<f32>, _>>()
        .map_err(|_| "not floats")?;
    let array: [f32; 9] = vec.try_into().map_err(|_| "wrong number of values")?;
    let matrix: &Matrix3<f32> = (&array).into();
    Ok(*matrix)
}

fn vector3_from_string(input: &String) -> Result<Vector3<f32>, String> {
    let vec = input
        .split(" ")
        .map(|s| s.parse::<f32>())
        .collect::<Result<Vec<f32>, _>>()
        .map_err(|_| "not floats")?;
    let array: [f32; 3] = vec.try_into().map_err(|_| "wrong number of values")?;
    let vector: &Vector3<f32> = (&array).into();
    Ok(*vector)
}

fn point3_from_string(input: &String) -> Result<Point3<f32>, String> {
    let vec = input
        .split(" ")
        .map(|s| s.parse::<f32>())
        .collect::<Result<Vec<f32>, _>>()
        .map_err(|_| "not floats")?;
    let array: [f32; 3] = vec.try_into().map_err(|_| "wrong number of values")?;
    let point: &Point3<f32> = (&array).into();
    Ok(*point)
}
struct TRS {
    translation: Point3<f32>,
    rotation: Matrix3<f32>,
    scale: Vector3<f32>,
}

fn get_trs(o: &HashMap<String, String>) -> Result<TRS, String> {
    Ok(TRS {
        translation: o
            .get("t")
            .map(point3_from_string)
            .transpose()
            .map_err(|e| e.to_string())?
            .unwrap_or(Point3::origin()),
        rotation: o
            .get("r")
            .map(matrix3_from_string)
            .transpose()
            .map_err(|e| e.to_string())?
            .unwrap_or(Matrix3::identity()),
        scale: o
            .get("s")
            .map(vector3_from_string)
            .transpose()
            .map_err(|e| e.to_string())?
            .unwrap_or(Vector3 {
                x: 1.,
                y: 1.,
                z: 1.,
            }),
    })
}
fn get_color(o: &HashMap<String, String>) -> Result<Vector3<f32>, String> {
    Ok(o.get("color")
        .map(vector3_from_string)
        .transpose()
        .map_err(|e| e.to_string())?
        .unwrap_or(Vector3 {
            x: 255.,
            y: 255.,
            z: 255.,
        }))
}

fn get_rgb(o: &HashMap<String, String>) -> Result<Vector3<f32>, String> {
    Ok(o.get("rgb")
        .map(vector3_from_string)
        .transpose()
        .map_err(|e| e.to_string())?
        .unwrap_or(Vector3 {
            x: 255.,
            y: 255.,
            z: 255.,
        }))
}

fn get_f32(o: &HashMap<String, String>, tag: &str) -> Result<f32, String> {
    get_f32_default(o, tag, 0.)
}

fn get_f32_default(o: &HashMap<String, String>, tag: &str, default: f32) -> Result<f32, String> {
    Ok(o.get(tag)
        .map(|c| c.parse::<f32>())
        .transpose()
        .map_err(|e| e.to_string())?
        .unwrap_or_default())
}

fn get_percentage(o: &HashMap<String, String>, tag: &str) -> Result<f32, String> {
    get_f32(o, tag).map(|c| c / 100.0)
}

fn get_percentage_default(
    o: &HashMap<String, String>,
    tag: &str,
    default: f32,
) -> Result<f32, String> {
    get_f32_default(o, tag, default).map(|c| c / 100.0)
}

#[repr(u8)]
enum Half {
    X,
    Y,
    Z,
    XM,
    YM,
    ZM,
}

fn get_half(o: &HashMap<String, String>) -> Result<Half, String> {
    Ok({
        let half = o
            .get("half")
            .map(|c| c.parse::<u8>())
            .transpose()
            .map_err(|e| e.to_string())?
            .unwrap_or(0);
        if half as usize >= mem::variant_count::<Half>() {
            return Err("invalid enum".to_owned());
        }
        unsafe { mem::transmute(half) }
    })
}

pub fn load_csg(
    memory_allocator: &MemoryAllocator,
    input: &mut dyn Read,
    name: String,
) -> Result<Vec<CSG>, String> {
    let mcsg: MCSG =
        from_reader(&mut Cursor::new("{").chain(input).chain(Cursor::new("}"))).unwrap();

    mcsg.object
        .iter()
        .enumerate()
        .map(|(i, o)| {
            let name = name.clone() + "_" + o.get("name").unwrap_or(&"unknown".to_owned());
            let trs = get_trs(&o)?;
            let color = get_color(&o)?;

            let cid = o
                .get("cid")
                .map(|c| c.parse::<usize>())
                .transpose()
                .map_err(|e| e.to_string())?
                .unwrap_or(0);
            if o.get("type").map(|ty| &ty[..] != "csg").unwrap_or(false) {
                return Err("Type unknown".to_owned());
            }

            let parts = mcsg
                .csg
                .get(cid)
                .ok_or("unknown cid")?
                .iter()
                .map(|inpart| {
                    let ty = inpart.get("type").ok_or("no type!")?.as_str();
                    let mut csgpart = CSGPart::opcode(InstructionSet::OPNop, vec![]);
                    match ty {
                        "sphere" => {
                            let blend = get_f32(&inpart, "blend")?;
                            let shell = get_percentage(&inpart, "shell%")?;
                            let power = get_f32_default(&inpart, "power", 2.)?;
                            let rgb = get_rgb(&inpart)?;
                            let trs = get_trs(&inpart)?;
                            let half = get_half(&inpart)?;
                        }
                        _ => {} //return Err("unknown type of csg".to_owned()),
                    }
                    Ok(csgpart)
                })
                .collect::<Result<Vec<CSGPart>, String>>()?;

            Ok(CSG {
                parts,
                pos: Point3 {
                    x: 0.,
                    y: 0.,
                    z: 0.,
                },
                rot: Euler::new(Deg(0.), Deg(0.), Deg(0.)),
                scale: Vector3 {
                    x: 1.,
                    y: 1.,
                    z: 1.,
                },
                name,
            })
        })
        .collect::<Result<Vec<CSG>, String>>()
}

#[derive(Debug)]
pub struct Light {
    pub pos: Point3<f32>,
    pub colour: Vector3<f32>,
}

impl Light {
    pub fn new(pos: [f32; 3], colour: [f32; 3], intensity: f32) -> Light {
        let c: Vector3<f32> = colour.into();
        Light {
            pos: pos.into(),
            colour: c * intensity,
        }
    }
}

impl Default for Light {
    fn default() -> Self {
        Self {
            pos: Point3::origin(),
            colour: Vector3 {
                x: 1.,
                y: 1.,
                z: 1.,
            },
        }
    }
}
