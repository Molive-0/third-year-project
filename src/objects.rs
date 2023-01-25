use std::{collections::HashMap, io::Read, sync::Arc};

use bytemuck::{Pod, Zeroable};
use cgmath::{Deg, Euler, Matrix3, Point3, SquareMatrix, Vector3};
use obj::{LoadConfig, ObjData};
use vulkano::{
    buffer::{BufferUsage, CpuAccessibleBuffer},
    impl_vertex,
};

use crate::MemoryAllocator;

pub const PLATONIC_SOLIDS: [(&str, &[u8]); 1] = [("Buny", include_bytes!("bunny.obj"))];

// We now create a buffer that will store the shape of our triangle.
// We use #[repr(C)] here to force rustc to not do anything funky with our data, although for this
// particular example, it doesn't actually change the in-memory representation.
#[repr(C)]
#[derive(Clone, Copy, Debug, Default, Zeroable, Pod)]
pub struct Vertex {
    position: [f32; 3],
    normal: [f32; 3],
}
impl_vertex!(Vertex, position, normal);

#[derive(Debug)]
pub struct Mesh {
    pub name: String,
    pub vertices: Arc<CpuAccessibleBuffer<[Vertex]>>,
    pub indices: Arc<CpuAccessibleBuffer<[u32]>>,
    pub pos: Point3<f32>,
    pub rot: Euler<Deg<f32>>,
    pub scale: f32,
}

pub fn load_obj(memory_allocator: &MemoryAllocator, input: &mut dyn Read, name: String) -> Mesh {
    let object = ObjData::load_buf_with_config(input, LoadConfig::default()).unwrap();

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
                    vertices.push(Vertex {
                        position: object.position[mapping.0 as usize],
                        normal: object.normal[mapping.1 as usize],
                    });
                    temp_hash_map.insert(mapping, (vertices.len() - 1) as u32);
                    indices.push((vertices.len() - 1) as u32);
                }
            }
        }
    }

    let vertex_buffer = CpuAccessibleBuffer::from_iter(
        memory_allocator,
        BufferUsage {
            vertex_buffer: true,
            ..BufferUsage::empty()
        },
        false,
        vertices,
    )
    .unwrap();

    let index_buffer = CpuAccessibleBuffer::from_iter(
        memory_allocator,
        BufferUsage {
            index_buffer: true,
            ..BufferUsage::empty()
        },
        false,
        indices,
    )
    .unwrap();

    Mesh {
        vertices: vertex_buffer,
        indices: index_buffer,
        pos: Point3 {
            x: 0.,
            y: 0.,
            z: 0.,
        },
        rot: Euler::new(Deg(0.), Deg(0.), Deg(0.)),
        scale: 1.,
        name,
    }
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
