#![feature(variant_count)]
use cgmath::{Deg, EuclideanSpace, Euler, Matrix3, Matrix4, Point3, Rad, SquareMatrix, Vector3};
use std::io::Cursor;
use std::{sync::Arc, time::Instant};
use vulkano::buffer::allocator::{SubbufferAllocator, SubbufferAllocatorCreateInfo};
use vulkano::command_buffer::allocator::StandardCommandBufferAllocator;
use vulkano::descriptor_set::allocator::StandardDescriptorSetAllocator;
use vulkano::descriptor_set::{PersistentDescriptorSet, WriteDescriptorSet};
use vulkano::device::{DeviceOwned, Features, QueueFlags};
use vulkano::format::Format;
use vulkano::half::f16;
use vulkano::image::view::ImageViewCreateInfo;
use vulkano::image::{AttachmentImage, SampleCount};
use vulkano::memory::allocator::StandardMemoryAllocator;
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

use egui_winit_vulkano::Gui;
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
use crate::objects::*;
mod mcsg_deserialise;

mod instruction_set {
    include!(concat!(env!("OUT_DIR"), "/instructionset.rs"));
}

use crate::instruction_set::InstructionSet;

pub type MemoryAllocator = StandardMemoryAllocator;

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
        ..DeviceExtensions::empty()
    };

    let (physical_device, queue_family_index) = instance
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
                })
                .map(|i| (p, i as u32))
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
            }],
            enabled_features: Features {
                mesh_shader: true,
                task_shader: true,
                sample_rate_shading: true,
                shader_float16: true,
                shader_int16: true,
                shader_int8: true,
                ..Features::empty()
            },
            ..Default::default()
        },
    )
    .expect("Unable to initialize device");

    let queue = queues.next().expect("Unable to retrieve queues");

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
            types_meta: {
                use bytemuck::{Pod, Zeroable};

                #[derive(Clone, Copy, Zeroable, Pod, Debug)]
            },
            vulkan_version: "1.2",
            spirv_version: "1.6"
        }
    }

    mod mesh_fs {
        vulkano_shaders::shader! {
            ty: "fragment",
            path: "src/frag.glsl",
            types_meta: {
                use bytemuck::{Pod, Zeroable};

                #[derive(Clone, Copy, Zeroable, Pod, Debug)]
            },
            vulkan_version: "1.2",
            spirv_version: "1.6",
            define: [("triangle","1")]
        }
    }

    let mesh_vs = mesh_vs::load(device.clone()).unwrap();
    let mesh_fs = mesh_fs::load(device.clone()).unwrap();

    mod implicit_ms {
        vulkano_shaders::shader! {
            ty: "mesh",
            path: "src/implicit.mesh.glsl",
            types_meta: {
                use bytemuck::{Pod, Zeroable};

                #[derive(Clone, Copy, Zeroable, Pod, Debug)]
            },
            vulkan_version: "1.2",
            spirv_version: "1.6"
        }
    }

    mod implicit_fs {
        vulkano_shaders::shader! {
            ty: "fragment",
            path: "src/frag.glsl",
            types_meta: {
                use bytemuck::{Pod, Zeroable};

                #[derive(Clone, Copy, Zeroable, Pod, Debug)]
            },
            vulkan_version: "1.2",
            spirv_version: "1.6",
            define: [("implicit","1")]
        }
    }

    let implicit_ms = implicit_ms::load(device.clone()).unwrap();
    let implicit_fs = implicit_fs::load(device.clone()).unwrap();

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

    let [RES_X, RES_Y] = images[0].dimensions().width_height();
    let ([mut mesh_pipeline, mut implicit_pipeline], mut framebuffers) =
        window_size_dependent_setup(
            &memory_allocator,
            &mesh_vs,
            &mesh_fs,
            &implicit_ms,
            &implicit_fs,
            &images,
            render_pass.clone(),
            &mut viewport,
            implicit_fs::SpecializationConstants { RES_X, RES_Y },
        );

    let command_buffer_allocator =
        StandardCommandBufferAllocator::new(device.clone(), Default::default());

    let mut recreate_swapchain = false;
    let mut previous_frame_end = Some(sync::now(device.clone()).boxed());

    /*
    // Get a output stream handle to the default physical sound device
    let (_stream, stream_handle) = OutputStream::try_default().unwrap();
    // Load a sound from a file, using a path relative to Cargo.toml
    let freebird = Cursor::new(include_bytes!("freebird.mp3"));
    // Decode that sound file into a source
    let source = Decoder::new(freebird).unwrap().repeat_infinite();
    // Play the sound directly on the device
    stream_handle.play_raw(source.convert_samples()).unwrap();
    */

    let mut render_start = Instant::now();

    let descriptor_set_allocator = StandardDescriptorSetAllocator::new(device.clone());

    let uniform_buffer = SubbufferAllocator::new(
        memory_allocator.clone(),
        SubbufferAllocatorCreateInfo {
            buffer_usage: BufferUsage::UNIFORM_BUFFER,
            ..Default::default()
        },
    );

    // Create an egui GUI
    let mut gui = Gui::new_with_subpass(
        &event_loop,
        surface.clone(),
        None,
        queue.clone(),
        Subpass::from(render_pass.clone(), 1).unwrap(),
    );

    let mut gstate = GState::default();

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
                        println!("MOUSE {:?}, {:?}, {:?}", d, s, b);
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
                    camforward.x = camforward.x + Deg(360f32) % Deg(360f32);
                    camforward.y = camforward.y + Deg(360f32) % Deg(360f32);
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
                    let [RES_X, RES_Y] = images[0].dimensions().width_height();
                    ([mesh_pipeline, implicit_pipeline], framebuffers) =
                        window_size_dependent_setup(
                            &memory_allocator,
                            &mesh_vs,
                            &mesh_fs,
                            &implicit_ms,
                            &implicit_fs,
                            &new_images,
                            render_pass.clone(),
                            &mut viewport,
                            implicit_fs::SpecializationConstants { RES_X, RES_Y },
                        );
                    recreate_swapchain = false;
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

                    let pc = mesh_vs::ty::PushConstantData {
                        world: Matrix4::identity().into(),
                    };

                    let uniform_data = mesh_fs::ty::Camera {
                        view: view.into(),
                        proj: proj.into(),
                        campos: (campos).into(),
                    };

                    let sub = uniform_buffer.allocate_sized().unwrap();
                    *sub.write().unwrap() = uniform_data;

                    if looking {
                        println!("campos: {:?} camforward: {:?}", campos, camforward);
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

                    let uniform_data = mesh_fs::ty::Lights {
                        pos,
                        col,
                        light_count: gstate.lights.len() as u32,
                    };

                    let sub = uniform_buffer.allocate_sized().unwrap();
                    *sub.write().unwrap() = uniform_data;
                    sub
                };

                let csg_object = {
                    let mut data = [[0u32; 4]; 13];

                    let parts = vec![
                        CSGPart::literal(0i8.into()),
                        CSGPart::literal(f16::from_f32(0.2)),
                        CSGPart::literal(0i8.into()),
                        CSGPart::opcode(InstructionSet::OPDupVec3),
                        CSGPart::opcode(InstructionSet::OPPromoteFloatFloatFloatVec3),
                        CSGPart::opcode(InstructionSet::OPSubVec3Vec3),
                        CSGPart::literal(f16::from_f32(0.3)),
                        CSGPart::opcode(InstructionSet::OPSDFSphere),
                        CSGPart::literal(0i8.into()),
                        CSGPart::literal(f16::from_f32(0.2)),
                        CSGPart::literal(0i8.into()),
                        CSGPart::opcode(InstructionSet::OPPromoteFloatFloatFloatVec3),
                        CSGPart::opcode(InstructionSet::OPAddVec3Vec3),
                        CSGPart::literal(f16::from_f32(0.3)),
                        CSGPart::opcode(InstructionSet::OPSDFSphere),
                        CSGPart::literal(f16::from_f32(0.05)),
                        CSGPart::opcode(InstructionSet::OPSmoothMinFloat),
                        CSGPart::opcode(InstructionSet::OPStop),
                    ];

                    let mut lower = true;
                    let mut minor = 0;
                    let mut major = 0;

                    for part in parts {
                        data[major][minor] |= (part.code as u32) << (if lower { 0 } else { 16 });

                        lower = !lower;
                        if lower {
                            minor += 1;
                            if minor == 4 {
                                minor = 0;
                                major += 1;
                                if major == 13 {
                                    panic!("CSGParts Too full!");
                                }
                            }
                        }
                    }

                    //println!("data: {:?}, {:?}", data[0][0], data[0][1]);

                    let uniform_data = implicit_fs::ty::SceneDescription { d: data };

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
                        WriteDescriptorSet::buffer(0, uniform_buffer_subbuffer.clone()),
                        WriteDescriptorSet::buffer(1, cam_set.clone()),
                        WriteDescriptorSet::buffer(2, csg_object.clone()),
                    ],
                )
                .unwrap();

                let (image_index, suboptimal, acquire_future) =
                    match acquire_next_image(swapchain.clone(), None) {
                        Ok(r) => r,
                        Err(AcquireError::OutOfDate) => {
                            recreate_swapchain = true;
                            return;
                        }
                        Err(e) => panic!("Failed to acquire next image: {:?}", e),
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
                        .draw_mesh([1, 1, 1])
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
                        println!("Failed to flush future: {:?}", e);
                        previous_frame_end = Some(sync::now(device.clone()).boxed());
                    }
                }
            }
            _ => (),
        }
    });
}

/// This method is called once during initialization, then again whenever the window is resized
fn window_size_dependent_setup<Mms>(
    allocator: &StandardMemoryAllocator,
    mesh_vs: &ShaderModule,
    mesh_fs: &ShaderModule,
    implicit_ms: &ShaderModule,
    implicit_fs: &ShaderModule,
    images: &[Arc<SwapchainImage>],
    render_pass: Arc<RenderPass>,
    viewport: &mut Viewport,
    specs: Mms,
) -> ([Arc<GraphicsPipeline>; 2], Vec<Arc<Framebuffer>>)
where
    Mms: SpecializationConstants + Clone,
{
    let dimensions = images[0].dimensions().width_height();
    viewport.dimensions = [dimensions[0] as f32, dimensions[1] as f32];

    let depth_buffer = ImageView::new_default(
        AttachmentImage::transient_multisampled(
            allocator,
            dimensions,
            SampleCount::Sample4,
            Format::D16_UNORM,
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
        .fragment_shader(mesh_fs.entry_point("main").unwrap(), specs.clone())
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
        .fragment_shader(implicit_fs.entry_point("main").unwrap(), specs)
        .mesh_shader(implicit_ms.entry_point("main").unwrap(), ())
        .depth_stencil_state(DepthStencilState::simple_depth_test())
        .rasterization_state(RasterizationState {
            //front_face: Fixed(Clockwise),
            //cull_mode: Fixed(CullMode::Back),
            ..RasterizationState::default()
        })
        .multisample_state(MultisampleState {
            rasterization_samples: Subpass::from(render_pass.clone(), 0)
                .unwrap()
                .num_samples()
                .unwrap(),
            sample_shading: Some(0.5),
            ..Default::default()
        })
        .build(allocator.device().clone())
        .unwrap();

    ([mesh_pipeline, implicit_pipeline], framebuffers)
}
