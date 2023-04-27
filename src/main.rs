#![feature(variant_count)]
use bytemuck::{Zeroable, Pod};
use cgmath::{
    Deg, EuclideanSpace, Euler, Matrix3, Matrix4, Point3, Rad, SquareMatrix,
    Vector3,
};
use instruction_set::InputTypes;
use vulkano::command_buffer::{CopyBufferInfo, PrimaryCommandBufferAbstract};
use std::io::Cursor;
use std::{sync::Arc, time::Instant};
use vulkano::buffer::allocator::{SubbufferAllocator, SubbufferAllocatorCreateInfo};
use vulkano::buffer::{Buffer, BufferAllocateInfo, Subbuffer};
use vulkano::command_buffer::allocator::StandardCommandBufferAllocator;
use vulkano::descriptor_set::allocator::StandardDescriptorSetAllocator;
use vulkano::descriptor_set::{PersistentDescriptorSet, WriteDescriptorSet};
use vulkano::device::{DeviceOwned, Features, QueueFlags, Queue};
use vulkano::format::Format;

use vulkano::image::view::ImageViewCreateInfo;
use vulkano::image::{AttachmentImage, SampleCount};
use vulkano::memory::allocator::{MemoryAllocatePreference, MemoryUsage, StandardMemoryAllocator};
use vulkano::pipeline::graphics::depth_stencil::DepthStencilState;
use vulkano::pipeline::graphics::multisample::MultisampleState;
use vulkano::pipeline::graphics::rasterization::CullMode;
use vulkano::pipeline::graphics::rasterization::FrontFace::Clockwise;
use vulkano::pipeline::graphics::vertex_input::Vertex;
use vulkano::pipeline::PipelineBindPoint;
use vulkano::shader::{ShaderModule, SpecializationConstants};
use vulkano::swapchain::{PresentMode, SwapchainPresentInfo};
use vulkano::VulkanLibrary;
use winit::event::{DeviceEvent, ElementState, MouseButton, VirtualKeyCode};

use egui_winit_vulkano::{Gui,GuiConfig};
use rayon::prelude::*;
use vulkano::pipeline::StateMode::Fixed;
use vulkano::{
    buffer::BufferUsage,
    command_buffer::{
        AutoCommandBufferBuilder, CommandBufferUsage, RenderPassBeginInfo, SubpassContents,
    },
    device::{
        physical::PhysicalDeviceType, Device, DeviceCreateInfo, DeviceExtensions, QueueCreateInfo,
    },
    image::{view::ImageView, ImageAccess, ImageUsage, SwapchainImage},
    instance::{Instance, InstanceCreateInfo, InstanceExtensions},
    pipeline::{
        graphics::{
            input_assembly::InputAssemblyState,
            rasterization::RasterizationState,
            viewport::{Viewport, ViewportState},
        },
        GraphicsPipeline, Pipeline,
    },
    render_pass::{Framebuffer, FramebufferCreateInfo, RenderPass, Subpass},
    swapchain::{
        acquire_next_image, AcquireError, Swapchain, SwapchainCreateInfo, SwapchainCreationError,
    },
    sync::{self, FlushError, GpuFuture},
};
use vulkano_win::VkSurfaceBuild;
use winit::{
    event::{Event, WindowEvent},
    event_loop::{ControlFlow, EventLoop},
    window::{Window, WindowBuilder},
};

mod gui;
use crate::gui::*;
mod objects;
use crate::interpreter::Interpreter;
use crate::objects::*;
mod mcsg_deserialise;

mod instruction_set {
    include!(concat!(env!("OUT_DIR"), "/instructionset.rs"));
}

use crate::instruction_set::InstructionSet;

mod interpreter;

pub(crate) type MemoryAllocator = StandardMemoryAllocator;

fn main() {
    let library = VulkanLibrary::new().expect("Vulkan is not installed???");
    let required_extensions = vulkano_win::required_extensions(&library);

    let instance = Instance::new(
        library,
        InstanceCreateInfo {
            enabled_extensions: InstanceExtensions {
                ..required_extensions
            },
            // Enable enumerating devices that use non-conformant vulkan implementations. (ex. MoltenVK)
            enumerate_portability: true,
            ..Default::default()
        },
    )
    .unwrap();

    let event_loop = EventLoop::new();
    let surface = WindowBuilder::new()
        .with_title("Implicit Surfaces")
        .build_vk_surface(&event_loop, instance.clone())
        .unwrap();

    let device_extensions = DeviceExtensions {
        khr_swapchain: true,
        ext_mesh_shader: true,
        khr_fragment_shading_rate: true,
        ..DeviceExtensions::empty()
    };

    let (physical_device, (queue_family_index, transfer_index)) = instance
        .enumerate_physical_devices()
        .unwrap()
        .filter(|p| p.supported_extensions().contains(&device_extensions))
        .filter_map(|p| {
            p.queue_family_properties()
                .iter()
                .enumerate()
                .position(|(i, q)| {
                    q.queue_flags.intersects(QueueFlags::GRAPHICS)
                        && p.surface_support(i as u32, &surface).unwrap_or(false)
                }).and_then( | graphics| {
                    p.queue_family_properties()
                .iter()
                .enumerate()
                .position(|(i, q)| {
                    q.queue_flags.intersects(QueueFlags::TRANSFER) && i != graphics
                }).or_else( || {
                    p.queue_family_properties()
                .iter()
                .enumerate()
                .position(|(_i, q)| {
                    q.queue_flags.intersects(QueueFlags::TRANSFER)
                })}
                
                ).map(|i| (graphics as u32, i as u32))}).map(|i| (p, i))
        })
        .min_by_key(|(p, _)| {
            // We assign a lower score to device types that are likely to be faster/better.
            match p.properties().device_type {
                PhysicalDeviceType::DiscreteGpu => 0,
                PhysicalDeviceType::IntegratedGpu => 1,
                PhysicalDeviceType::VirtualGpu => 2,
                PhysicalDeviceType::Cpu => 3,
                PhysicalDeviceType::Other => 4,
                _ => 5,
            }
        })
        .expect("No suitable physical device found. Do you have a Mesh Shader capable GPU and are your drivers up to date?");

    // Some little debug infos.
    println!(
        "Using device: {} (type: {:?})",
        physical_device.properties().device_name,
        physical_device.properties().device_type,
    );

    let (device, mut queues) = Device::new(
        physical_device,
        DeviceCreateInfo {
            enabled_extensions: device_extensions,
            queue_create_infos: vec![QueueCreateInfo {
                queue_family_index,
                ..Default::default()
            },
            QueueCreateInfo {
                queue_family_index: transfer_index,
                ..Default::default()
            }],
            enabled_features: Features {
                mesh_shader: true,
                task_shader: true,
                sample_rate_shading: true,
                //shader_float16: true,
                shader_int16: true,
                shader_int8: true,
                storage_buffer8_bit_access: true,
                geometry_shader: true,
                primitive_fragment_shading_rate: true,
                ..Features::empty()
            },
            ..Default::default()
        },
    )
    .expect("Unable to initialize device");

    let queue = queues.next().expect("Unable to retrieve queues");
    let transfer_queue = queues.next().expect("Unable to retrieve queues");

    let (mut swapchain, images) = {
        let surface_capabilities = device
            .physical_device()
            .surface_capabilities(&surface, Default::default())
            .unwrap();

        let image_format = Some(
            device
                .physical_device()
                .surface_formats(&surface, Default::default())
                .unwrap()[0]
                .0,
        );
        let window = surface.object().unwrap().downcast_ref::<Window>().unwrap();

        Swapchain::new(
            device.clone(),
            surface.clone(),
            SwapchainCreateInfo {
                min_image_count: 3
                    .max(surface_capabilities.min_image_count)
                    .min(surface_capabilities.max_image_count.unwrap_or(u32::MAX)),

                image_format,
                image_extent: window.inner_size().into(),

                image_usage: ImageUsage::COLOR_ATTACHMENT,

                composite_alpha: surface_capabilities
                    .supported_composite_alpha
                    .into_iter()
                    .next()
                    .unwrap(),

                present_mode: PresentMode::Fifo,

                ..Default::default()
            },
        )
        .unwrap()
    };

    mod mesh_vs {
        vulkano_shaders::shader! {
            ty: "vertex",
            path: "src/triangle.vert.glsl",
            vulkan_version: "1.2",
            spirv_version: "1.5",
            custom_derives: [Debug, Clone, Copy],
        }
    }

    mod mesh_fs {
        vulkano_shaders::shader! {
            ty: "fragment",
            path: "src/frag.glsl",
            vulkan_version: "1.2",
            spirv_version: "1.5",
            define: [("triangle","1")],
            custom_derives: [Debug, Clone, Copy],
        }
    }

    mod implicit_ms {
        vulkano_shaders::shader! {
            ty: "mesh",
            path: "src/implicit.mesh.glsl",
            vulkan_version: "1.2",
            spirv_version: "1.5",
            custom_derives: [Debug, Clone, Copy],
        }
    }

    mod implicit_ts {
        vulkano_shaders::shader! {
            ty: "task",
            path: "src/implicit.task.glsl",
            vulkan_version: "1.2",
            spirv_version: "1.5",
            custom_derives: [Debug, Clone, Copy],
        }
    }

    mod implicit_fs {
        vulkano_shaders::shader! {
            ty: "fragment",
            path: "src/frag.glsl",
            vulkan_version: "1.2",
            spirv_version: "1.5",
            define: [("implicit","1")],
            custom_derives: [Debug, Clone, Copy],
        }
    }

    mod cs {
        vulkano_shaders::shader!{
            ty: "compute",
            path: "src/fuzz.comp.glsl",
            vulkan_version: "1.2",
            spirv_version: "1.5",
            custom_derives: [Debug, Clone, Copy],
        }
    }
    

    let loaders: Vec<
        fn(
            ::std::sync::Arc<::vulkano::device::Device>,
        ) -> Result<
            ::std::sync::Arc<::vulkano::shader::ShaderModule>,
            ::vulkano::shader::ShaderCreationError,
        >,
    > = vec![
        ((mesh_vs::load)
            as fn(
                ::std::sync::Arc<::vulkano::device::Device>,
            ) -> Result<
                ::std::sync::Arc<::vulkano::shader::ShaderModule>,
                ::vulkano::shader::ShaderCreationError,
            >),
        ((mesh_fs::load)
            as fn(
                ::std::sync::Arc<::vulkano::device::Device>,
            ) -> Result<
                ::std::sync::Arc<::vulkano::shader::ShaderModule>,
                ::vulkano::shader::ShaderCreationError,
            >),
        ((implicit_ms::load)
            as fn(
                ::std::sync::Arc<::vulkano::device::Device>,
            ) -> Result<
                ::std::sync::Arc<::vulkano::shader::ShaderModule>,
                ::vulkano::shader::ShaderCreationError,
            >),
        ((implicit_ts::load)
            as fn(
                ::std::sync::Arc<::vulkano::device::Device>,
            ) -> Result<
                ::std::sync::Arc<::vulkano::shader::ShaderModule>,
                ::vulkano::shader::ShaderCreationError,
            >),
        ((implicit_fs::load)
            as fn(
                ::std::sync::Arc<::vulkano::device::Device>,
            ) -> Result<
                ::std::sync::Arc<::vulkano::shader::ShaderModule>,
                ::vulkano::shader::ShaderCreationError,
            >),
        ((cs::load)
            as fn(
                ::std::sync::Arc<::vulkano::device::Device>,
            ) -> Result<
                ::std::sync::Arc<::vulkano::shader::ShaderModule>,
                ::vulkano::shader::ShaderCreationError,
            >),
    ];

    let pariter = loaders
        .par_iter()
        .map(|load| load(device.clone()).unwrap())
        .collect::<Vec<_>>();

    let mesh_vs = pariter[0].clone();
    let mesh_fs = pariter[1].clone();

    let implicit_ms = pariter[2].clone();
    let implicit_ts = pariter[3].clone();
    let implicit_fs = pariter[4].clone();

    let compute_shader = pariter[5].clone();

    drop(pariter);

    use vulkano::pipeline::ComputePipeline;

    let compute_pipeline = ComputePipeline::new(
    device.clone(),
    compute_shader.entry_point("main").unwrap(),
    &(),
    None,
    |_| {},
    )   
    .expect("failed to create compute pipeline");

    let memory_allocator = Arc::new(MemoryAllocator::new_default(device.clone()));

    let render_pass = vulkano::ordered_passes_renderpass!(
        device.clone(),
        attachments: {
            intermediary: {
                load: Clear,
                store: DontCare,
                format: swapchain.image_format(),
                samples: 4,
            },
            color: {
                load: DontCare,
                store: Store,
                format: swapchain.image_format(),
                samples: 1,
            },
            multi_depth: {
                load: Clear,
                store: DontCare,
                format: Format::D16_UNORM,
                samples: 4,
            }
        },
        passes: [{
            color: [intermediary],
            depth_stencil: {multi_depth},
            input: [],
            resolve: [color]
        },{
            color: [color],
            depth_stencil: {},
            input: []
        }]
    )
    .unwrap();

    let mut viewport = Viewport {
        origin: [0.0, 0.0],
        dimensions: [0.0, 0.0],
        depth_range: 0.0..1.0,
    };

    let mut gstate = GState::default();

    //let [RES_X, RES_Y] = images[0].dimensions().width_height();
    let ([mut mesh_pipeline, mut implicit_pipeline], mut framebuffers) =
        window_size_dependent_setup(
            &memory_allocator,
            &mesh_vs,
            &mesh_fs,
            &implicit_ms,
            &implicit_ts,
            &implicit_fs,
            &images,
            render_pass.clone(),
            &mut viewport,
            
            implicit_fs::SpecializationConstants {DISABLE_TRACE:gstate.debug.bounding_boxes as u32,
                BRUTE_FORCE:gstate.debug.brute_force as u32,},
            implicit_ms::SpecializationConstants {DISABLE_TRACE:gstate.debug.disable_meshcull as u32,
                DISABLE_SCALING_1:gstate.debug.disable_meshscale1 as u32,
                DISABLE_SCALING_2:gstate.debug.disable_meshscale2 as u32,
                BRUTE_FORCE:gstate.debug.brute_force as u32,},
            implicit_ts::SpecializationConstants {DISABLE_TRACE:gstate.debug.disable_taskcull as u32},
            gstate.debug.brute_force,
        );

    let command_buffer_allocator =
        StandardCommandBufferAllocator::new(device.clone(), Default::default());

    let mut recreate_swapchain = false;
    let mut previous_frame_end = Some(sync::now(device.clone()).boxed());

    let descriptor_set_allocator = StandardDescriptorSetAllocator::new(device.clone());

    let uniform_buffer = SubbufferAllocator::new(
        memory_allocator.clone(),
        SubbufferAllocatorCreateInfo {
            buffer_usage: BufferUsage::UNIFORM_BUFFER | BufferUsage::STORAGE_BUFFER,
            ..Default::default()
        },
    );

    // Create an egui GUI
    let mut gui = Gui::new_with_subpass(
        &event_loop,
        surface.clone(),
        queue.clone(),
        Subpass::from(render_pass.clone(), 1).unwrap(),
        GuiConfig {
            preferred_format: Some(images[0].format()),
            is_overlay: true,
            samples: SampleCount::Sample4
        }
    );

    let mut campos = Point3 {
        x: 0f32,
        y: 0f32,
        z: 3f32,
    };

    let mut camforward = Euler::new(Deg(0f32), Deg(0f32), Deg(0f32));

    let mut looking = false;
    struct Keys {
        w: bool,
        s: bool,
        a: bool,
        d: bool,
    }
    let mut keys = Keys {
        w: false,
        s: false,
        a: false,
        d: false,
    };

    gstate.meshes.append(
        &mut load_obj(
            &memory_allocator,
            &mut Cursor::new(PLATONIC_SOLIDS[0].1),
            PLATONIC_SOLIDS[0].0.to_string(),
        )
        .unwrap(),
    );

    gstate.csg.append(
        &mut load_csg(
            &memory_allocator,
            &mut Cursor::new(CSG_SOLIDS[0].1),
            CSG_SOLIDS[0].0.to_string(),
        )
        .unwrap(),
    );

    gstate
        .lights
        .push(Light::new([4., 6., 8.], [1., 1., 8.], 0.05));
    gstate
        .lights
        .push(Light::new([-4., 6., -8.], [8., 4., 1.], 0.05));

    let subbuffers = object_size_dependent_setup(memory_allocator.clone(), &gstate.csg, &command_buffer_allocator, transfer_queue.clone(), None, false);

    let mut prevdub = PreviousDebug::default();

    let mut render_start = Instant::now();

    event_loop.run(move |event, _, control_flow| {
        if let Event::WindowEvent { event: we, .. } = &event {
            if !gui.update(we) {
                match &we {
                    WindowEvent::CloseRequested => {
                        *control_flow = ControlFlow::Exit;
                    }
                    WindowEvent::Resized(_) => {
                        recreate_swapchain = true;
                    }
                    WindowEvent::ScaleFactorChanged { .. } => {
                        recreate_swapchain = true;
                    }
                    WindowEvent::DroppedFile(_file) => {
                        todo!()
                    }
                    WindowEvent::MouseInput {
                        device_id: d,
                        state: s,
                        button: b,
                        ..
                    } => {
                        println!("MOUSE {d:?}, {s:?}, {b:?}");
                        if b == &MouseButton::Right {
                            looking = s == &ElementState::Pressed;
                        }
                    }
                    WindowEvent::KeyboardInput { input, .. } => match input.virtual_keycode {
                        Some(VirtualKeyCode::W) => {
                            keys.w = input.state == ElementState::Pressed;
                        }
                        Some(VirtualKeyCode::S) => {
                            keys.s = input.state == ElementState::Pressed;
                        }
                        Some(VirtualKeyCode::A) => {
                            keys.a = input.state == ElementState::Pressed;
                        }
                        Some(VirtualKeyCode::D) => {
                            keys.d = input.state == ElementState::Pressed;
                        }
                        _ => {}
                    },
                    _ => {}
                }
            }
        }
        match event {
            Event::DeviceEvent {
                event: DeviceEvent::MouseMotion { delta },
                ..
            } => {
                if looking {
                    camforward.x -= Deg(delta.1 as f32) * gstate.cursor_sensitivity * 0.3;
                    camforward.y += Deg(delta.0 as f32) * gstate.cursor_sensitivity * 0.3;
                    camforward.x += Deg(360f32) % Deg(360f32);
                    camforward.y += Deg(360f32) % Deg(360f32);
                }
            }
            Event::RedrawEventsCleared => {
                for i in 1..gstate.fps.len() {
                    gstate.fps[i - 1] = gstate.fps[i];
                }

                gstate.fps[gstate.fps.len() - 1] =
                    1.0 / (Instant::now() - render_start).as_secs_f64();

                render_start = Instant::now();

                let window = surface.object().unwrap().downcast_ref::<Window>().unwrap();
                let dimensions = window.inner_size();
                if dimensions.width == 0 || dimensions.height == 0 {
                    return;
                }

                previous_frame_end.as_mut().unwrap().cleanup_finished();

                if prevdub != gstate.debug {
                    recreate_swapchain = true;
                }

                if recreate_swapchain {
                    let (new_swapchain, new_images) =
                        match swapchain.recreate(SwapchainCreateInfo {
                            image_extent: dimensions.into(),
                            ..swapchain.create_info()
                        }) {
                            Ok(r) => r,
                            Err(SwapchainCreationError::ImageExtentNotSupported { .. }) => return,
                            Err(e) => panic!("Failed to recreate swapchain: {e:?}"),
                        };

                    swapchain = new_swapchain;
                    //let [RES_X, RES_Y] = images[0].dimensions().width_height();
                    ([mesh_pipeline, implicit_pipeline], framebuffers) =
                        window_size_dependent_setup(
                            &memory_allocator,
                            &mesh_vs,
                            &mesh_fs,
                            &implicit_ms,
                            &implicit_ts,
                            &implicit_fs,
                            &new_images,
                            render_pass.clone(),
                            &mut viewport,
                            implicit_fs::SpecializationConstants {DISABLE_TRACE:gstate.debug.bounding_boxes as u32,
                                BRUTE_FORCE:gstate.debug.brute_force as u32},
                            implicit_ms::SpecializationConstants {DISABLE_TRACE:gstate.debug.disable_meshcull as u32,
                                DISABLE_SCALING_1:gstate.debug.disable_meshscale1 as u32,
                                DISABLE_SCALING_2:gstate.debug.disable_meshscale2 as u32,
                                BRUTE_FORCE:gstate.debug.brute_force as u32},
                            implicit_ts::SpecializationConstants {DISABLE_TRACE:gstate.debug.disable_taskcull as u32},
                            gstate.debug.brute_force,
                        );
                    recreate_swapchain = false;
                    prevdub = gstate.debug;
                }

                let (mut push_constants, cam_set) = {
                    if looking {
                        if keys.w {
                            campos -= Matrix3::from_angle_y(camforward.y)
                                * Matrix3::from_angle_x(camforward.x)
                                * Vector3::unit_z()
                                * 0.01
                                * gstate.move_speed;
                        }
                        if keys.s {
                            campos += Matrix3::from_angle_y(camforward.y)
                                * Matrix3::from_angle_x(camforward.x)
                                * Vector3::unit_z()
                                * 0.01
                                * gstate.move_speed;
                        }
                        if keys.a {
                            campos += Matrix3::from_angle_y(camforward.y)
                                * Matrix3::from_angle_x(camforward.x)
                                * Vector3::unit_x()
                                * 0.01
                                * gstate.move_speed;
                        }
                        if keys.d {
                            campos -= Matrix3::from_angle_y(camforward.y)
                                * Matrix3::from_angle_x(camforward.x)
                                * Vector3::unit_x()
                                * 0.01
                                * gstate.move_speed;
                        }
                    } else {
                        keys.w = false;
                        keys.s = false;
                        keys.a = false;
                        keys.d = false;
                    }

                    let near = 0.01;
                    let far = 100.0;

                    let aspect_ratio =
                        swapchain.image_extent()[0] as f32 / swapchain.image_extent()[1] as f32;
                    let proj = cgmath::perspective(
                        Rad(std::f32::consts::FRAC_PI_2),
                        aspect_ratio,
                        near,
                        far,
                    );
                    let view = Matrix4::from(camforward)
                        * Matrix4::from_angle_z(Deg(180f32))
                        * Matrix4::from_translation(Point3::origin() - campos);

                    let pc = mesh_vs::PushConstantData {
                        world: Matrix4::identity().into(),
                    };

                    let uniform_data = implicit_fs::Camera {
                        view: view.into(),
                        proj: proj.into(),
                        campos: (campos).into(),
                    };

                    let sub = uniform_buffer.allocate_sized().unwrap();
                    *sub.write().unwrap() = uniform_data;

                    if looking {
                        println!("campos: {campos:?} camforward: {camforward:?}");
                    }

                    (pc, sub)
                };

                let uniform_buffer_subbuffer = {
                    let mut pos = [[0f32; 4]; 32];
                    let mut col = [[0f32; 4]; 32];

                    for (i, light) in gstate.lights.iter().enumerate() {
                        pos[i][0] = light.pos.x;
                        pos[i][1] = light.pos.y;
                        pos[i][2] = light.pos.z;
                        col[i][0] = light.colour.x;
                        col[i][1] = light.colour.y;
                        col[i][2] = light.colour.z;
                    }

                    let uniform_data = mesh_fs::Lights {
                        pos,
                        col,
                        light_count: gstate.lights.len() as u32,
                    };

                    let sub = uniform_buffer.allocate_sized().unwrap();
                    *sub.write().unwrap() = uniform_data;
                    sub
                };
                
                let mesh_layout = mesh_pipeline.layout().set_layouts().get(0).unwrap();
                let mesh_set = PersistentDescriptorSet::new(
                    &descriptor_set_allocator,
                    mesh_layout.clone(),
                    [
                        WriteDescriptorSet::buffer(0, uniform_buffer_subbuffer.clone()),
                        WriteDescriptorSet::buffer(1, cam_set.clone()),
                    ],
                )
                .unwrap();

                let implicit_layout = implicit_pipeline.layout().set_layouts().get(0).unwrap();
                let implicit_set = PersistentDescriptorSet::new(
                    &descriptor_set_allocator,
                    implicit_layout.clone(),
                    [
                        WriteDescriptorSet::buffer(0, uniform_buffer_subbuffer),
                        WriteDescriptorSet::buffer(1, cam_set),
                        WriteDescriptorSet::buffer(2, subbuffers.desc.clone()),
                        WriteDescriptorSet::buffer(3, subbuffers.scene.clone()),
                        WriteDescriptorSet::buffer(4, subbuffers.floats.clone()),
                        WriteDescriptorSet::buffer(5, subbuffers.vec2s.clone()),
                        //WriteDescriptorSet::buffer(6, subbuffers.vec3s.clone()),
                        WriteDescriptorSet::buffer(7, subbuffers.vec4s.clone()),
                        //WriteDescriptorSet::buffer(8, subbuffers.mat2s.clone()),
                        //WriteDescriptorSet::buffer(9, subbuffers.mat3s.clone()),
                        //WriteDescriptorSet::buffer(10, subbuffers.mat4s.clone()),
                        //WriteDescriptorSet::buffer(11, subbuffers.mats.clone()),
                        WriteDescriptorSet::buffer(12, subbuffers.deps.clone()),
                        WriteDescriptorSet::buffer(20, subbuffers.masks.clone()),
                    ],
                )
                .unwrap();

                const COMPUTE_FUZZING: bool = false;
                
                if COMPUTE_FUZZING {

                    let mut fake_csg = vec![];
                    for i in 0..32
                    {
                        fake_csg.push(
                            CSG{ name: format!("fuzz_{i}"), parts: vec![
                                CSGPart::opcode(InstructionSet::OPMulVec3Float, vec![Inputs::Variable, Inputs::Float(0.9)]),
                                CSGPart::opcode(InstructionSet::OPDupVec3, vec![Inputs::Variable]),
                                CSGPart::opcode(InstructionSet::OPAddVec3Vec3, vec![Inputs::Variable, Inputs::Vec3([-0.7, (i as f64), -0.7].into())]),
                                CSGPart::opcode(InstructionSet::OPSDFSphere,vec![Inputs::Float(0.5), Inputs::Variable]),
                                //CSGPart::opcode(InstructionSet::OPNop,vec![]),
                                //CSGPart::opcode(InstructionSet::OPDupVec3, vec![Inputs::Variable]),
                                //CSGPart::opcode(InstructionSet::OPAddVec3Vec3, vec![Inputs::Variable, Inputs::Vec3([-0.2, -0.2, -0.2].into())]),
                                //CSGPart::opcode(InstructionSet::OPAddVec3Vec3, vec![Inputs::Variable, Inputs::Vec3([-0.0, -0.0, -0.0].into())]),
                                CSGPart::opcode(InstructionSet::OPSDFSphere,vec![Inputs::Float(1.2), Inputs::Variable]),
                                //CSGPart::opcode(InstructionSet::OPSDFBox, vec![Inputs::Variable, Inputs::Vec3([0.7, 0.7, 0.7].into())]),
                                CSGPart::opcode(InstructionSet::OPMinFloat, vec![Inputs::Variable,Inputs::Variable]),
                                CSGPart::opcode(InstructionSet::OPDivFloatFloat, vec![Inputs::Variable, Inputs::Float(0.9)]),
                                CSGPart::opcode(InstructionSet::OPStop, vec![Inputs::Variable]),
                            ], pos: Point3::origin(), rot: Euler { x: Deg(0.), y: Deg(0.), z: Deg(0.) }, scale: Vector3 { x: 1., y: 1., z: 1. } }
                        )
                    }
                
                    let compute_subbuffers = object_size_dependent_setup(memory_allocator.clone(), &fake_csg, &command_buffer_allocator, transfer_queue.clone(), Some(
                        [1.,1.,1.,1.,5.,1.]
                    ),true);

                    let compute_result_buffer:Subbuffer<[cs::Results]> = uniform_buffer.allocate_slice((fake_csg.len()+1) as u64).unwrap();


                    let compute_layout = compute_pipeline.layout().set_layouts().get(0).unwrap();
                    let compute_set = PersistentDescriptorSet::new(
                        &descriptor_set_allocator,
                        compute_layout.clone(),
                        [
                            //WriteDescriptorSet::buffer(0, uniform_buffer_subbuffer.clone()),
                            //WriteDescriptorSet::buffer(1, cam_set.clone()),
                            WriteDescriptorSet::buffer(2, compute_subbuffers.desc.clone()),
                            WriteDescriptorSet::buffer(3, compute_subbuffers.scene.clone()),
                            WriteDescriptorSet::buffer(4, compute_subbuffers.floats.clone()),
                            WriteDescriptorSet::buffer(5, compute_subbuffers.vec2s.clone()),
                            //WriteDescriptorSet::buffer(6, compute_subbuffers.vec3s.clone()),
                            WriteDescriptorSet::buffer(7, compute_subbuffers.vec4s.clone()),
                            //WriteDescriptorSet::buffer(8, compute_subbuffers.mat2s.clone()),
                            //WriteDescriptorSet::buffer(9, compute_subbuffers.mat3s.clone()),
                            //WriteDescriptorSet::buffer(10, compute_subbuffers.mat4s.clone()),
                            //WriteDescriptorSet::buffer(11, compute_subbuffers.mats.clone()),
                            WriteDescriptorSet::buffer(12, compute_subbuffers.deps),
                            //WriteDescriptorSet::buffer(20, compute_subbuffers.masks.clone()),
                            WriteDescriptorSet::buffer(30, compute_result_buffer.clone()),],
                    )
                    .unwrap();

                    let mut builder = AutoCommandBufferBuilder::primary(
                        &command_buffer_allocator,
                        queue.queue_family_index(),
                        CommandBufferUsage::OneTimeSubmit,
                    )
                    .unwrap();

                    builder
                        .bind_pipeline_compute(compute_pipeline.clone())
                        .bind_descriptor_sets(
                            PipelineBindPoint::Compute,
                            compute_pipeline.layout().clone(),
                            0, // 0 is the index of our set
                            compute_set,
                        )
                        .dispatch([1, 1, 1])
                        .unwrap();
                    
                    let command_buffer = builder.build().unwrap();

                    let future = sync::now(device.clone())
                        .then_execute(queue.clone(), command_buffer)
                        .unwrap()
                        .then_signal_fence_and_flush()
                        .unwrap();

                    future.wait(None).unwrap();

                    let content = compute_result_buffer.read().unwrap();
                    for (val,csg) in content.iter().zip(fake_csg.iter()) {
                        println!("{val:?}");
                        let expected = Interpreter::new(csg).scene(Vector3::new(1.,1.,1.)) as f32;
                        if expected != val.f[0] {
                            println!("ERROR: expected {}, got {}", expected, val.f[0]);
                        }
                    }
                }

                let (image_index, suboptimal, acquire_future) =
                    match acquire_next_image(swapchain.clone(), None) {
                        Ok(r) => r,
                        Err(AcquireError::OutOfDate) => {
                            recreate_swapchain = true;
                            return;
                        }
                        Err(e) => panic!("Failed to acquire next image: {e:?}"),
                    };

                if suboptimal {
                    recreate_swapchain = true;
                }

                gui_up(&mut gui, &mut gstate);

                let mut builder = AutoCommandBufferBuilder::primary(
                    &command_buffer_allocator,
                    queue.queue_family_index(),
                    CommandBufferUsage::OneTimeSubmit,
                )
                .unwrap();

                let guicb = gui.draw_on_subpass_image(dimensions.into());

                builder
                    .begin_render_pass(
                        RenderPassBeginInfo {
                            clear_values: vec![
                                Some([0.12, 0.1, 0.1, 1.0].into()),
                                None,
                                Some(1.0.into()),
                            ],
                            ..RenderPassBeginInfo::framebuffer(
                                framebuffers[image_index as usize].clone(),
                            )
                        },
                        SubpassContents::Inline,
                    )
                    .unwrap()
                    .set_viewport(0, [viewport.clone()])
                    .bind_pipeline_graphics(mesh_pipeline.clone())
                    .bind_descriptor_sets(
                        PipelineBindPoint::Graphics,
                        mesh_pipeline.layout().clone(),
                        0,
                        mesh_set,
                    );

                for object in &gstate.meshes {
                    push_constants.world =
                        (Matrix4::from_translation(object.pos * 0.01 - Point3::origin())
                            * Matrix4::from(object.rot)
                            * Matrix4::from_nonuniform_scale(
                                object.scale.x,
                                object.scale.y,
                                object.scale.z,
                            ))
                        .into();
                    builder
                        .bind_vertex_buffers(0, object.vertices.clone())
                        .bind_index_buffer(object.indices.clone())
                        .push_constants(mesh_pipeline.layout().clone(), 0, push_constants)
                        .draw_indexed(object.indices.len() as u32, 1, 0, 0, 0)
                        .unwrap();
                }

                builder
                    .bind_pipeline_graphics(implicit_pipeline.clone())
                    .bind_descriptor_sets(
                        PipelineBindPoint::Graphics,
                        implicit_pipeline.layout().clone(),
                        0,
                        implicit_set,
                    );

                for csg in &gstate.csg {
                    push_constants.world =
                        (Matrix4::from_translation(csg.pos * 0.01 - Point3::origin())
                            * Matrix4::from(csg.rot)
                            * Matrix4::from_nonuniform_scale(
                                csg.scale.x,
                                csg.scale.y,
                                csg.scale.z,
                            ))
                        .into();
                    builder
                        .push_constants(implicit_pipeline.layout().clone(), 0, push_constants)
                        .draw_mesh([1, 1, 2])
                        .unwrap();
                }

                builder
                    .next_subpass(SubpassContents::SecondaryCommandBuffers)
                    .unwrap()
                    .execute_commands(guicb)
                    .unwrap()
                    .end_render_pass()
                    .unwrap();

                let command_buffer = builder.build().unwrap();

                let future = previous_frame_end
                    .take()
                    .unwrap()
                    .join(acquire_future)
                    .then_execute(queue.clone(), command_buffer)
                    .unwrap()
                    .then_swapchain_present(
                        queue.clone(),
                        SwapchainPresentInfo::swapchain_image_index(swapchain.clone(), image_index),
                    )
                    .then_signal_fence_and_flush();

                match future {
                    Ok(future) => {
                        previous_frame_end = Some(future.boxed());
                    }
                    Err(FlushError::OutOfDate) => {
                        recreate_swapchain = true;
                        previous_frame_end = Some(sync::now(device.clone()).boxed());
                    }
                    Err(e) => {
                        println!("Failed to flush future: {e:?}");
                        previous_frame_end = Some(sync::now(device.clone()).boxed());
                    }
                }
            }
            _ => (),
        }
    });
}

/// This method is called once during initialization, then again whenever the window is resized
fn window_size_dependent_setup<Fs,Ms,Ts>(
    allocator: &StandardMemoryAllocator,
    mesh_vs: &ShaderModule,
    mesh_fs: &ShaderModule,
    implicit_ms: &ShaderModule,
    implicit_ts: &ShaderModule,
    implicit_fs: &ShaderModule,
    images: &[Arc<SwapchainImage>],
    render_pass: Arc<RenderPass>,
    viewport: &mut Viewport,
    implicit_fs_specs: Fs,
    implicit_ms_specs: Ms,
    implicit_ts_specs: Ts,
    brute_force: bool,
) -> ([Arc<GraphicsPipeline>; 2], Vec<Arc<Framebuffer>>)
where
    Fs: SpecializationConstants + Clone,
    Ms: SpecializationConstants + Clone,
    Ts: SpecializationConstants + Clone,
{
    let dimensions = images[0].dimensions().width_height();
    viewport.dimensions = [dimensions[0] as f32, dimensions[1] as f32];

    let depth_buffer = ImageView::new_default(
        AttachmentImage::transient_multisampled(
            allocator,
            dimensions,
            SampleCount::Sample4,
            Format::D16_UNORM, // D24_UNORM_S8_UINT
        )
        .unwrap(),
    )
    .unwrap();

    let intermediary_image = AttachmentImage::transient_multisampled(
        allocator,
        dimensions,
        SampleCount::Sample4,
        images[0].format(),
    )
    .unwrap();

    let intermediary = ImageView::new(
        intermediary_image.clone(),
        ImageViewCreateInfo {
            usage: ImageUsage::COLOR_ATTACHMENT | ImageUsage::TRANSIENT_ATTACHMENT,
            ..ImageViewCreateInfo::from_image(&intermediary_image)
        },
    )
    .unwrap();

    let framebuffers = images
        .iter()
        .map(|image| {
            let view = ImageView::new(
                image.clone(),
                ImageViewCreateInfo {
                    usage: ImageUsage::COLOR_ATTACHMENT | ImageUsage::TRANSFER_DST,
                    ..ImageViewCreateInfo::from_image(&intermediary_image)
                },
            )
            .unwrap();
            Framebuffer::new(
                render_pass.clone(),
                FramebufferCreateInfo {
                    attachments: vec![intermediary.clone(), view, depth_buffer.clone()],
                    ..Default::default()
                },
            )
            .unwrap()
        })
        .collect::<Vec<_>>();

    let mesh_pipeline = GraphicsPipeline::start()
        .render_pass(Subpass::from(render_pass.clone(), 0).unwrap())
        .vertex_input_state(OVertex::per_vertex())
        .input_assembly_state(InputAssemblyState::new())
        .vertex_shader(mesh_vs.entry_point("main").unwrap(), ())
        .viewport_state(ViewportState::viewport_fixed_scissor_irrelevant([
            Viewport {
                origin: [0.0, 0.0],
                dimensions: [dimensions[0] as f32, dimensions[1] as f32],
                depth_range: 0.0..1.0,
            },
        ]))
        .fragment_shader(mesh_fs.entry_point("main").unwrap(), ())
        .depth_stencil_state(DepthStencilState::simple_depth_test())
        .rasterization_state(RasterizationState {
            front_face: Fixed(Clockwise),
            cull_mode: Fixed(CullMode::Back),
            ..RasterizationState::default()
        })
        .multisample_state(MultisampleState {
            rasterization_samples: Subpass::from(render_pass.clone(), 0)
                .unwrap()
                .num_samples()
                .unwrap(),
            ..Default::default()
        })
        .build(allocator.device().clone())
        .unwrap();

    println!("Recompiling implicit pipeline... (may take up to 10 minutes)");

    let implicit_pipeline = GraphicsPipeline::start()
        .render_pass(Subpass::from(render_pass.clone(), 0).unwrap())
        .vertex_input_state(OVertex::per_vertex())
        .input_assembly_state(InputAssemblyState::new())
        .viewport_state(ViewportState::viewport_fixed_scissor_irrelevant([
            Viewport {
                origin: [0.0, 0.0],
                dimensions: [dimensions[0] as f32, dimensions[1] as f32],
                depth_range: 0.0..1.0,
            },
        ]))
        .fragment_shader(implicit_fs.entry_point("main").unwrap(), implicit_fs_specs)
        .mesh_shader(implicit_ms.entry_point("main").unwrap(), implicit_ms_specs)
        .depth_stencil_state(DepthStencilState::simple_depth_test())
        .rasterization_state(RasterizationState {
            //front_face: Fixed(Clockwise),
            //cull_mode: Fixed(CullMode::Back),
            ..RasterizationState::default()
        })
        .multisample_state(MultisampleState {
            rasterization_samples: Subpass::from(render_pass, 0)
                .unwrap()
                .num_samples()
                .unwrap(),
            sample_shading: Some(0.5),
            ..Default::default()
        });
    
    let built_implicit_pipeline = 
        if !brute_force {
            implicit_pipeline.task_shader(implicit_ts.entry_point("main").unwrap(),implicit_ts_specs)
            .build(allocator.device().clone())
            .unwrap()
        } else {
            implicit_pipeline
            .build(allocator.device().clone())
            .unwrap()
        };

    println!("Implicit pipeline compiled");

    ([mesh_pipeline, built_implicit_pipeline], framebuffers)
}


#[repr(C)]
#[derive(Clone,Copy,Pod,Zeroable, Default, Debug)]
struct Description {
    pointers: [u32; 9],
    bounds: [f32;6],
}

struct Subbuffers {
    masks: Subbuffer<[[u8; 29]]>,
    floats: Subbuffer<[f32]>,
    vec2s: Subbuffer<[[f32; 2]]>,
    //vec3s: Subbuffer<[[f32; 4]]>,
    vec4s: Subbuffer<[[f32; 4]]>,
    mat2s: Subbuffer<[[[f32; 2]; 2]]>,
    mat3s: Subbuffer<[[[f32; 3]; 3]]>,
    mat4s: Subbuffer<[[[f32; 4]; 4]]>,
    mats: Subbuffer<[[[f32; 4]; 4]]>,
    scene: Subbuffer<[[u32; 4]]>,
    deps: Subbuffer<[[u8; 2]]>,
    desc: Subbuffer<[Description]>,
}

impl PartialEq<InputTypes> for Inputs {
    fn eq(&self, other: &InputTypes) -> bool {
        match *self {
            Inputs::Variable => true,
            Inputs::Float(_) => *other == InputTypes::Float,
            Inputs::Vec2(_) => *other == InputTypes::Vec2,
            Inputs::Vec3(_) => *other == InputTypes::Vec3,
            Inputs::Vec4(_) => *other == InputTypes::Vec4,
            Inputs::Mat2(_) => *other == InputTypes::Mat2,
            Inputs::Mat3(_) => *other == InputTypes::Mat3,
            Inputs::Mat4(_) => *other == InputTypes::Mat4,
        }
    }
}

fn gpu_buffer<T>(
    input: Vec<T>,
    allocator: &StandardMemoryAllocator,
    sub_allocator: &SubbufferAllocator,
    command_allocator: &StandardCommandBufferAllocator,
    transfer_queue: Arc<Queue>,
) -> Subbuffer<[T]>
where
    T: bytemuck::Pod + Send + Sync
{
    let buffer = Buffer::new_slice(
        allocator,
        BufferAllocateInfo {
            buffer_usage: BufferUsage::STORAGE_BUFFER | BufferUsage::TRANSFER_DST,
            memory_usage: MemoryUsage::GpuOnly,
            allocate_preference: MemoryAllocatePreference::AlwaysAllocate,
            ..Default::default()
        },
        (input.len()) as u64,
    )
    .unwrap();

    let staging = sub_allocator.allocate_slice(input.len() as u64).unwrap();
    staging.write().unwrap().copy_from_slice(&input[..]);

    let mut builder = AutoCommandBufferBuilder::primary(
        command_allocator,
        transfer_queue.queue_family_index(),
        CommandBufferUsage::OneTimeSubmit,
    )
    .unwrap();
    builder.copy_buffer(CopyBufferInfo::buffers(
        staging,
        buffer.clone())
    ).unwrap();
    let commands = builder.build().unwrap();

    commands.execute(transfer_queue)
            .unwrap()
            .then_signal_fence_and_flush()
            .unwrap()
            .wait(None)
            .unwrap();

    buffer
}

fn f64tof32<const A:usize>(input: [[f64;A];A]) -> [[f32;A];A]
{
    let mut out = [[0_f32;A];A];
    for x in 0..input.len()
    {
    for y in 0..input.len()
    {
        out[x][y] = input[x][y] as f32;
    }
}
    out
}

fn object_size_dependent_setup(
    allocator: Arc<StandardMemoryAllocator>,
    state: &Vec<CSG>,
    command_allocator: &StandardCommandBufferAllocator,
    queue: Arc<Queue>,
    set_bound: Option<[f32;6]>,
    actual: bool,
) -> Subbuffers {
    let mut floats: Vec<f32> = vec![Default::default()];
    let mut vec2s: Vec<[f32; 2]> = vec![Default::default()];
    let mut vec4s: Vec<[f32; 4]> = vec![Default::default()];
    let mut mat2s: Vec<[[f32; 2]; 2]> = vec![Default::default()];
    let mut mat3s: Vec<[[f32; 3]; 3]> = vec![Default::default()];
    let mut mat4s: Vec<[[f32; 4]; 4]> = vec![Default::default()];
    let mats: Vec<[[f32; 4]; 4]> = vec![Default::default()];
    let mut scene: Vec<[u32; 4]> = vec![Default::default()];
    let mut deps: Vec<[u8; 2]> = vec![Default::default()];
    let mut desc: Vec<Description> = vec![Default::default()];

    'nextcsg: for csg in state {
        let mut data: Vec<[u32; 4]> = vec![];

        let to_push = [
            scene.len() as u32,
            floats.len() as u32,
            vec2s.len() as u32,
            vec4s.len() as u32,
            mat2s.len() as u32,
            mat3s.len() as u32,
            mat4s.len() as u32,
            mats.len() as u32,
            deps.len() as u32,
        ];

        let example = vec![
            CSGPart::opcode(InstructionSet::OPMulVec3Float, vec![Inputs::Variable, Inputs::Float(0.9)]),
            CSGPart::opcode(InstructionSet::OPDupVec3, vec![Inputs::Variable]),
            CSGPart::opcode(InstructionSet::OPAddVec3Vec3, vec![Inputs::Variable, Inputs::Vec3([-0.7, -1.2, -0.7].into())]),
            CSGPart::opcode(InstructionSet::OPSDFSphere,vec![Inputs::Float(0.5), Inputs::Variable]),
            //CSGPart::opcode(InstructionSet::OPNop,vec![]),
            //CSGPart::opcode(InstructionSet::OPDupVec3, vec![Inputs::Variable]),
            //CSGPart::opcode(InstructionSet::OPAddVec3Vec3, vec![Inputs::Variable, Inputs::Vec3([-0.2, -0.2, -0.2].into())]),
            //CSGPart::opcode(InstructionSet::OPAddVec3Vec3, vec![Inputs::Variable, Inputs::Vec3([-0.0, -0.0, -0.0].into())]),
            //CSGPart::opcode(InstructionSet::OPSDFSphere,vec![Inputs::Float(1.2), Inputs::Variable]),
            CSGPart::opcode(InstructionSet::OPSDFTorus, vec![Inputs::Vec2([0.7, 0.4].into()), Inputs::Variable]),
            //CSGPart::opcode(InstructionSet::OPSDFBox, vec![Inputs::Vec3([0.7, 0.4, 0.7].into()), Inputs::Variable]),
            CSGPart::opcode(InstructionSet::OPMinFloat, vec![Inputs::Variable,Inputs::Variable]),
            CSGPart::opcode(InstructionSet::OPDivFloatFloat, vec![Inputs::Variable, Inputs::Float(0.9)]),
            CSGPart::opcode(InstructionSet::OPStop, vec![Inputs::Variable]),
        ];

        let parts = if actual {&csg.parts} else {&example};

        let mut dependencies: Vec<[u8; 2]> = vec![];
        for _ in 0..parts.len() {
            dependencies.push([u8::MAX, u8::MAX]);
        }

        let mut runtime_floats: Vec<usize> = vec![];
        let mut runtime_vec2s: Vec<usize> = vec![];
        let mut runtime_vec3s: Vec<usize> = vec![usize::MAX];
        let mut runtime_vec4s: Vec<usize> = vec![];
        let mut runtime_mat2s: Vec<usize> = vec![];
        let mut runtime_mat3s: Vec<usize> = vec![];
        let mut runtime_mat4s: Vec<usize> = vec![];

        for (index, part) in parts.iter().enumerate() {
            let inputs = part.opcode.input();
            for (expected, actual) in inputs.iter().zip(part.constants.iter()) {
                if actual != expected {
                    eprintln!(
                        "csg {} is invalid ({:?} != {:?})",
                        csg.name, actual, expected
                    );
                    continue 'nextcsg;
                }
                if actual == &Inputs::Variable {
                    match *expected {
                        InputTypes::Float => match runtime_floats.pop() {
                            Some(u) => {
                                if dependencies[u][0] != u8::MAX {
                                    dependencies[u][1] = index as u8
                                } else {
                                    dependencies[u][0] = index as u8
                                }
                            }
                            None => {
                                eprintln!("csg {} underflowed on floats", csg.name);
                                continue 'nextcsg;
                            }
                        },
                        InputTypes::Vec2 => match runtime_vec2s.pop() {
                            Some(u) => {
                                if dependencies[u][0] != u8::MAX {
                                    dependencies[u][1] = index as u8
                                } else {
                                    dependencies[u][0] = index as u8
                                }
                            }
                            None => {
                                eprintln!("csg {} underflowed on vec2s", csg.name);
                                continue 'nextcsg;
                            }
                        },
                        InputTypes::Vec3 => match runtime_vec3s.pop() {
                            Some(u) => {
                                if u != usize::MAX {
                                    if dependencies[u][0] != u8::MAX {
                                        dependencies[u][1] = index as u8
                                    } else {
                                        dependencies[u][0] = index as u8
                                    }
                                }
                            }
                            None => {
                                eprintln!("csg {} underflowed on vec3s", csg.name);
                                continue 'nextcsg;
                            }
                        },
                        InputTypes::Vec4 => match runtime_vec4s.pop() {
                            Some(u) => {
                                if dependencies[u][0] != u8::MAX {
                                    dependencies[u][1] = index as u8
                                } else {
                                    dependencies[u][0] = index as u8
                                }
                            }
                            None => {
                                eprintln!("csg {} underflowed on vec4s", csg.name);
                                continue 'nextcsg;
                            }
                        },
                        InputTypes::Mat2 => match runtime_mat2s.pop() {
                            Some(u) => {
                                if dependencies[u][0] != u8::MAX {
                                    dependencies[u][1] = index as u8
                                } else {
                                    dependencies[u][0] = index as u8
                                }
                            }
                            None => {
                                eprintln!("csg {} underflowed on mat2s", csg.name);
                                continue 'nextcsg;
                            }
                        },
                        InputTypes::Mat3 => match runtime_mat3s.pop() {
                            Some(u) => {
                                if dependencies[u][0] != u8::MAX {
                                    dependencies[u][1] = index as u8
                                } else {
                                    dependencies[u][0] = index as u8
                                }
                            }
                            None => {
                                eprintln!("csg {} underflowed on mat3s", csg.name);
                                continue 'nextcsg;
                            }
                        },
                        InputTypes::Mat4 => match runtime_mat4s.pop() {
                            Some(u) => {
                                if dependencies[u][0] != u8::MAX {
                                    dependencies[u][1] = index as u8
                                } else {
                                    dependencies[u][0] = index as u8
                                }
                            }
                            None => {
                                eprintln!("csg {} underflowed on mat4s", csg.name);
                                continue 'nextcsg;
                            }
                        },
                    }
                } else {
                    match *actual {
                        Inputs::Float(f) => floats.push(f as f32),
                        Inputs::Vec2(f) => vec2s.push(f.map(|x| x as f32).into()),
                        Inputs::Vec3(f) => vec4s.push(f.map(|x| x as f32).extend(1.).into()),
                        Inputs::Vec4(f) => vec4s.push(f.map(|x| x as f32).into()),
                        Inputs::Mat2(f) => mat2s.push(f64tof32(f.into())),
                        Inputs::Mat3(f) => mat3s.push(f64tof32(f.into())),
                        Inputs::Mat4(f) => mat4s.push(f64tof32(f.into())),
                        Inputs::Variable => unreachable!(),
                    }
                }
            }
            let outputs = part.opcode.output();
            for output in outputs {
                match output {
                    InputTypes::Float => runtime_floats.push(index),
                    InputTypes::Vec2 => runtime_vec2s.push(index),
                    InputTypes::Vec3 => runtime_vec3s.push(index),
                    InputTypes::Vec4 => runtime_vec4s.push(index),
                    InputTypes::Mat2 => runtime_mat2s.push(index),
                    InputTypes::Mat3 => runtime_mat3s.push(index),
                    InputTypes::Mat4 => runtime_mat4s.push(index),
                }
            }
        }

        let mut lower = true;
        let mut minor = 0;
        let mut major = 0;

        for part in parts.iter() {
            if major == data.len() {
                data.push([0; 4]);
            }
            data[major][minor] |= (part.code as u32) << (if lower { 0 } else { 16 });

            lower = !lower;
            if lower {
                minor += 1;
                if minor == 4 {
                    minor = 0;
                    major += 1;
                    if major == 29 {
                        panic!("CSGParts Too full!");
                    }
                }
            }
        }

        let temp_csg = &CSG { name: "test".to_string(), parts: parts.to_vec(), pos: Point3::origin(), rot: Euler::new(Deg(0.), Deg(0.), Deg(0.)), scale: Vector3 { x: 1., y: 1., z: 1. } };

        let mut interpreter = interpreter::Interpreter::new( temp_csg);
        const CLIPCHECK:Float =65536.;

        let bounds = set_bound.unwrap_or([
            ((CLIPCHECK-interpreter.scene(Vector3::new(CLIPCHECK,0.,0.)))*1.00001) as f32,
            ((CLIPCHECK-interpreter.scene(Vector3::new(0.,CLIPCHECK,0.)))*1.00001)  as f32,
            ((CLIPCHECK-interpreter.scene(Vector3::new(0.,0.,CLIPCHECK)))*1.00001)  as f32,
            ((-CLIPCHECK+interpreter.scene(Vector3::new(-CLIPCHECK,0.,0.)))*1.00001)  as f32,
            ((-CLIPCHECK+interpreter.scene(Vector3::new(0.,-CLIPCHECK,0.)))*1.00001)  as f32,
            ((-CLIPCHECK+interpreter.scene(Vector3::new(0.,0.,-CLIPCHECK)))*1.00001)  as f32,
        ]);

        //println!("bounds: {:?}",bounds);

        desc.push(Description {pointers:to_push,bounds});

        scene.append(&mut data);

        deps.append(&mut dependencies);

        
    }

    println!("floats: {floats:?}");
    println!("vec2s: {vec2s:?}");
    println!("vec3/4s: {vec4s:?}");
    println!("mat2s: {mat2s:?}");
    println!("mat3s: {mat3s:?}");
    println!("mat4s: {mat4s:?}");
    println!("mats: {mats:?}");
    println!("scene: {scene:?}");
    println!("deps: {deps:?}");
    println!("desc: {desc:?}");

    let fragment_masks_buffer = Buffer::new_slice(
        &allocator,
        BufferAllocateInfo {
            buffer_usage: BufferUsage::STORAGE_BUFFER,
            memory_usage: MemoryUsage::GpuOnly,
            allocate_preference: MemoryAllocatePreference::AlwaysAllocate,
            ..Default::default()
        },
        ((desc.len()-1) * (4 * 4 * 4) * (4 * 4 * 2) * 29) as u64,
    )
    .unwrap();

    let staging = SubbufferAllocator::new(
        allocator.clone(),
        SubbufferAllocatorCreateInfo {
            buffer_usage: BufferUsage::TRANSFER_SRC,
            memory_usage: MemoryUsage::Upload,
            ..Default::default()
        },
    );

    let csg_scene = gpu_buffer(scene, &allocator, &staging, command_allocator, queue.clone());
    let csg_desc = gpu_buffer(desc, &allocator, &staging, command_allocator, queue.clone());
    let csg_floats = gpu_buffer(floats, &allocator, &staging, command_allocator, queue.clone());
    let csg_vec2s = gpu_buffer(vec2s, &allocator, &staging, command_allocator, queue.clone());
    //let csg_vec3s = gpu_buffer(vec3s, &allocator, &staging, command_allocator, queue.clone());
    let csg_vec4s = gpu_buffer(vec4s, &allocator, &staging, command_allocator, queue.clone());
    let csg_mat2s = gpu_buffer(mat2s, &allocator, &staging, command_allocator, queue.clone());
    let csg_mat3s = gpu_buffer(mat3s, &allocator, &staging, command_allocator, queue.clone());
    let csg_mat4s = gpu_buffer(mat4s, &allocator, &staging, command_allocator, queue.clone());
    let csg_mats = gpu_buffer(mats, &allocator, &staging, command_allocator, queue.clone());
    let csg_deps = gpu_buffer(deps, &allocator, &staging, command_allocator, queue);

    Subbuffers {
        masks: fragment_masks_buffer,
        floats: csg_floats,
        vec2s: csg_vec2s,
        //vec3s: csg_vec3s,
        vec4s: csg_vec4s,
        mat2s: csg_mat2s,
        mat3s: csg_mat3s,
        mat4s: csg_mat4s,
        mats: csg_mats,
        scene: csg_scene,
        deps: csg_deps,
        desc: csg_desc,
    }
}
