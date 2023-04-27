use std::{
    collections::HashMap,
    io::{Cursor, Read},
    mem,
};

use bytemuck::{Pod, Zeroable};
use cgmath::{
    Deg, EuclideanSpace, Euler, Matrix2, Matrix3, Matrix4, Point3, SquareMatrix, Vector2, Vector3,
    Vector4,
};
use obj::{LoadConfig, ObjData, ObjError};
use serde::{Deserialize, Serialize};
use vulkano::{
    buffer::{Buffer, BufferAllocateInfo, BufferUsage, Subbuffer},
    pipeline::graphics::vertex_input::Vertex,
};

use crate::instruction_set::InstructionSet;
use crate::{mcsg_deserialise::from_reader, MemoryAllocator};

pub(crate) const PLATONIC_SOLIDS: [(&str, &[u8]); 1] = [("Buny", include_bytes!("bunny.obj"))];
pub(crate) const CSG_SOLIDS: [(&str, &[u8]); 1] =
    [("Primitives", include_bytes!("primitive.mcsg"))];

// We now create a buffer that will store the shape of our triangle.
// We use #[repr(C)] here to force rustc to not do anything funky with our data, although for this
// particular example, it doesn't actually change the in-memory representation.
#[repr(C)]
#[derive(Clone, Copy, Debug, Default, Zeroable, Pod, Vertex)]
pub(crate) struct OVertex {
    #[format(R32G32B32_SFLOAT)]
    position: [f32; 3],
    #[format(R32G32B32_SFLOAT)]
    normal: [f32; 3],
}

#[derive(Debug)]
pub(crate) struct Mesh {
    pub(crate) name: String,
    pub(crate) vertices: Subbuffer<[OVertex]>,
    pub(crate) indices: Subbuffer<[u32]>,
    pub(crate) pos: Point3<f32>,
    pub(crate) rot: Euler<Deg<f32>>,
    pub(crate) scale: Vector3<f32>,
}

#[derive(Debug)]
pub(crate) struct CSG {
    pub(crate) name: String,
    pub(crate) parts: Vec<CSGPart>,
    pub(crate) pos: Point3<f32>,
    pub(crate) rot: Euler<Deg<f32>>,
    pub(crate) scale: Vector3<f32>,
}

pub(crate) type Float = f64;
pub(crate) type Vec2 = Vector2<Float>;
pub(crate) type Vec3 = Vector3<Float>;
pub(crate) type Vec4 = Vector4<Float>;
pub(crate) type Mat2 = Matrix2<Float>;
pub(crate) type Mat3 = Matrix3<Float>;
pub(crate) type Mat4 = Matrix4<Float>;

#[derive(Clone, Copy, Debug, Default, PartialEq)]
pub(crate) enum Inputs {
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
pub(crate) struct CSGPart {
    pub(crate) code: u16,
    pub(crate) opcode: InstructionSet,
    pub(crate) constants: Vec<Inputs>,
    pub(crate) material: Option<Mat4>,
}

impl CSGPart {
    pub(crate) fn opcode(opcode: InstructionSet, inputs: Vec<Inputs>) -> CSGPart {
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

    pub(crate) fn opcode_with_material(
        opcode: InstructionSet,
        inputs: Vec<Inputs>,
        material: Mat4,
    ) -> CSGPart {
        let mut c = CSGPart::opcode(opcode, inputs);
        c.material = Some(material);
        c
    }
}

pub(crate) fn load_obj(
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

fn matrix3_from_string(input: &str) -> Result<Matrix3<f32>, String> {
    let vec = input
        .split(' ')
        .map(|s| s.parse::<f32>())
        .collect::<Result<Vec<f32>, _>>()
        .map_err(|_| "not floats")?;
    let array: [f32; 9] = vec.try_into().map_err(|_| "wrong number of values")?;
    let matrix: &Matrix3<f32> = (&array).into();
    Ok(*matrix)
}

fn vector3_from_string(input: &str) -> Result<Vector3<f32>, String> {
    let vec = input
        .split(' ')
        .map(|s| s.parse::<f32>())
        .collect::<Result<Vec<f32>, _>>()
        .map_err(|_| "not floats")?;
    let array: [f32; 3] = vec.try_into().map_err(|_| "wrong number of values")?;
    let vector: &Vector3<f32> = (&array).into();
    Ok(*vector)
}

fn point3_from_string(input: &str) -> Result<Point3<f32>, String> {
    let vec = input
        .split(' ')
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
            .map(String::as_str)
            .map(point3_from_string)
            .transpose()?
            .unwrap_or(Point3::origin()),
        rotation: o
            .get("r")
            .map(String::as_str)
            .map(matrix3_from_string)
            .transpose()?
            .unwrap_or(Matrix3::identity()),
        scale: o
            .get("s")
            .map(String::as_str)
            .map(vector3_from_string)
            .transpose()?
            .unwrap_or(Vector3 {
                x: 1.,
                y: 1.,
                z: 1.,
            }),
    })
}
fn get_color(o: &HashMap<String, String>) -> Result<Vector3<f32>, String> {
    Ok(o.get("color")
        .map(String::as_str)
        .map(vector3_from_string)
        .transpose()?
        .unwrap_or(Vector3 {
            x: 255.,
            y: 255.,
            z: 255.,
        }))
}

fn get_rgb(o: &HashMap<String, String>) -> Result<Vector3<f32>, String> {
    Ok(o.get("rgb")
        .map(String::as_str)
        .map(vector3_from_string)
        .transpose()?
        .unwrap_or(Vector3 {
            x: 255.,
            y: 255.,
            z: 255.,
        }))
}

fn get_f32(o: &HashMap<String, String>, tag: &str) -> Result<f32, String> {
    get_f32_default(o, tag, 0.)
}

fn get_f32_default(o: &HashMap<String, String>, tag: &str, _default: f32) -> Result<f32, String> {
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

pub(crate) fn load_csg(
    _memory_allocator: &MemoryAllocator,
    input: &mut dyn Read,
    name: String,
) -> Result<Vec<CSG>, String> {
    let mcsg: MCSG =
        from_reader(&mut Cursor::new("{").chain(input).chain(Cursor::new("}"))).unwrap();

    mcsg.object
        .iter()
        .enumerate()
        .map(|(_i, o)| {
            let name = name.clone() + "_" + o.get("name").unwrap_or(&"unknown".to_owned());
            let _trs = get_trs(o)?;
            let _color = get_color(o)?;

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
                    let csgpart = CSGPart::opcode(InstructionSet::OPNop, vec![]);
                    match ty {
                        "sphere" => {
                            let _blend = get_f32(inpart, "blend")?;
                            let _shell = get_percentage(inpart, "shell%")?;
                            let _power = get_f32_default(inpart, "power", 2.)?;
                            let _rgb = get_rgb(inpart)?;
                            let _trs = get_trs(inpart)?;
                            let _half = get_half(inpart)?;
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
pub(crate) struct Light {
    pub(crate) pos: Point3<f32>,
    pub(crate) colour: Vector3<f32>,
}

impl Light {
    pub(crate) fn new(pos: [f32; 3], colour: [f32; 3], intensity: f32) -> Light {
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
