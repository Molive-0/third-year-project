// Copyright (c) 2016 The vulkano developers
// Licensed under the Apache License, Version 2.0
// <LICENSE-APACHE or
// https://www.apache.org/licenses/LICENSE-2.0> or the MIT
// license <LICENSE-MIT or https://opensource.org/licenses/MIT>,
// at your option. All files in the project carrying such
// notice may not be copied, modified, or distributed except
// according to those terms.

// Welcome to the triangle example!
//
// This is the only example that is entirely detailed. All the other examples avoid code
// duplication by using helper functions.
//
// This example assumes that you are already more or less familiar with graphics programming
// and that you want to learn Vulkan. This means that for example it won't go into details about
// what a vertex or a shader is.
use bytemuck::{Pod, Zeroable};
use cgmath::{
    AbsDiffEq, Basis3, Deg, EuclideanSpace, Euler, Matrix3, Matrix4, Point3, Quaternion, Rad,
    SquareMatrix, Transform, Vector3,
};
use obj::{LoadConfig, ObjData};
use rodio::{source::Source, Decoder, OutputStream};
use std::io::Cursor;
use std::{sync::Arc, time::Instant};
use vulkano::buffer::CpuBufferPool;
use vulkano::command_buffer::allocator::StandardCommandBufferAllocator;
use vulkano::descriptor_set::allocator::StandardDescriptorSetAllocator;
use vulkano::descriptor_set::{PersistentDescriptorSet, WriteDescriptorSet};
use vulkano::device::DeviceOwned;
use vulkano::format::Format;
use vulkano::image::AttachmentImage;
use vulkano::memory::allocator::{MemoryUsage, StandardMemoryAllocator};
use vulkano::pipeline::graphics::depth_stencil::DepthStencilState;
use vulkano::pipeline::graphics::rasterization::CullMode;
use vulkano::pipeline::graphics::rasterization::FrontFace::Clockwise;
use vulkano::pipeline::PipelineBindPoint;
use vulkano::shader::ShaderModule;
use vulkano::swapchain::{PresentMode, SwapchainPresentInfo};
use vulkano::VulkanLibrary;
use winit::event::{DeviceEvent, DeviceId, ElementState, MouseButton, VirtualKeyCode};

use egui_winit_vulkano::Gui;
use vulkano::pipeline::StateMode::Fixed;
use vulkano::{
    buffer::{BufferUsage, CpuAccessibleBuffer, TypedBufferAccess},
    command_buffer::{
        AutoCommandBufferBuilder, CommandBufferUsage, RenderPassBeginInfo, SubpassContents,
    },
    device::{
        physical::PhysicalDeviceType, Device, DeviceCreateInfo, DeviceExtensions, QueueCreateInfo,
    },
    image::{view::ImageView, ImageAccess, ImageUsage, SwapchainImage},
    impl_vertex,
    instance::{Instance, InstanceCreateInfo},
    pipeline::{
        graphics::{
            input_assembly::InputAssemblyState,
            rasterization::RasterizationState,
            vertex_input::BuffersDefinition,
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

pub type MemoryAllocator = StandardMemoryAllocator;

fn main() {
    // The first step of any Vulkan program is to create an instance.
    //
    // When we create an instance, we have to pass a list of extensions that we want to enable.
    //
    // All the window-drawing functionalities are part of non-core extensions that we need
    // to enable manually. To do so, we ask the `vulkano_win` crate for the list of extensions
    // required to draw to a window.
    let library = VulkanLibrary::new().expect("Vulkan is not installed???");
    let required_extensions = vulkano_win::required_extensions(&library);

    // Now creating the instance.
    let instance = Instance::new(
        library,
        InstanceCreateInfo {
            enabled_extensions: required_extensions,
            // Enable enumerating devices that use non-conformant vulkan implementations. (ex. MoltenVK)
            enumerate_portability: true,
            ..Default::default()
        },
    )
    .unwrap();

    // The objective of this example is to draw a triangle on a window. To do so, we first need to
    // create the window.
    //
    // This is done by creating a `WindowBuilder` from the `winit` crate, then calling the
    // `build_vk_surface` method provided by the `VkSurfaceBuild` trait from `vulkano_win`. If you
    // ever get an error about `build_vk_surface` being undefined in one of your projects, this
    // probably means that you forgot to import this trait.
    //
    // This returns a `vulkano::swapchain::Surface` object that contains both a cross-platform winit
    // window and a cross-platform Vulkan surface that represents the surface of the window.
    let event_loop = EventLoop::new();
    let surface = WindowBuilder::new()
        .with_title("horizontally spinning bunny")
        .build_vk_surface(&event_loop, instance.clone())
        .unwrap();

    // Choose device extensions that we're going to use.
    // In order to present images to a surface, we need a `Swapchain`, which is provided by the
    // `khr_swapchain` extension.
    let device_extensions = DeviceExtensions {
        khr_swapchain: true,
        ..DeviceExtensions::empty()
    };

    // We then choose which physical device to use. First, we enumerate all the available physical
    // devices, then apply filters to narrow them down to those that can support our needs.
    let (physical_device, queue_family_index) = instance
        .enumerate_physical_devices()
        .unwrap()
        .filter(|p| {
            // Some devices may not support the extensions or features that your application, or
            // report properties and limits that are not sufficient for your application. These
            // should be filtered out here.
            p.supported_extensions().contains(&device_extensions)
        })
        .filter_map(|p| {
            // For each physical device, we try to find a suitable queue family that will execute
            // our draw commands.
            //
            // Devices can provide multiple queues to run commands in parallel (for example a draw
            // queue and a compute queue), similar to CPU threads. This is something you have to
            // have to manage manually in Vulkan. Queues of the same type belong to the same
            // queue family.
            //
            // Here, we look for a single queue family that is suitable for our purposes. In a
            // real-life application, you may want to use a separate dedicated transfer queue to
            // handle data transfers in parallel with graphics operations. You may also need a
            // separate queue for compute operations, if your application uses those.
            p.queue_family_properties()
                .iter()
                .enumerate()
                .position(|(i, q)| {
                    // We select a queue family that supports graphics operations. When drawing to
                    // a window surface, as we do in this example, we also need to check that queues
                    // in this queue family are capable of presenting images to the surface.
                    q.queue_flags.graphics && p.surface_support(i as u32, &surface).unwrap_or(false)
                })
                // The code here searches for the first queue family that is suitable. If none is
                // found, `None` is returned to `filter_map`, which disqualifies this physical
                // device.
                .map(|i| (p, i as u32))
        })
        // All the physical devices that pass the filters above are suitable for the application.
        // However, not every device is equal, some are preferred over others. Now, we assign
        // each physical device a score, and pick the device with the
        // lowest ("best") score.
        //
        // In this example, we simply select the best-scoring device to use in the application.
        // In a real-life setting, you may want to use the best-scoring device only as a
        // "default" or "recommended" device, and let the user choose the device themselves.
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
        .expect("No suitable physical device found");

    // Some little debug infos.
    println!(
        "Using device: {} (type: {:?})",
        physical_device.properties().device_name,
        physical_device.properties().device_type,
    );

    // Now initializing the device. This is probably the most important object of Vulkan.
    //
    // The iterator of created queues is returned by the function alongside the device.
    let (device, mut queues) = Device::new(
        // Which physical device to connect to.
        physical_device,
        DeviceCreateInfo {
            // A list of optional features and extensions that our program needs to work correctly.
            // Some parts of the Vulkan specs are optional and must be enabled manually at device
            // creation. In this example the only thing we are going to need is the `khr_swapchain`
            // extension that allows us to draw to a window.
            enabled_extensions: device_extensions,

            // The list of queues that we are going to use. Here we only use one queue, from the
            // previously chosen queue family.
            queue_create_infos: vec![QueueCreateInfo {
                queue_family_index,
                ..Default::default()
            }],

            ..Default::default()
        },
    )
    .expect("Unable to initialize device");

    // Since we can request multiple queues, the `queues` variable is in fact an iterator. We
    // only use one queue in this example, so we just retrieve the first and only element of the
    // iterator.
    let queue = queues.next().expect("Unable to retrieve queues");

    // Before we can draw on the surface, we have to create what is called a swapchain. Creating
    // a swapchain allocates the color buffers that will contain the image that will ultimately
    // be visible on the screen. These images are returned alongside the swapchain.
    let (mut swapchain, images) = {
        // Querying the capabilities of the surface. When we create the swapchain we can only
        // pass values that are allowed by the capabilities.
        let surface_capabilities = device
            .physical_device()
            .surface_capabilities(&surface, Default::default())
            .unwrap();

        // Choosing the internal format that the images will have.
        let image_format = Some(
            device
                .physical_device()
                .surface_formats(&surface, Default::default())
                .unwrap()[0]
                .0,
        );
        let window = surface.object().unwrap().downcast_ref::<Window>().unwrap();

        // Please take a look at the docs for the meaning of the parameters we didn't mention.
        Swapchain::new(
            device.clone(),
            surface.clone(),
            SwapchainCreateInfo {
                min_image_count: 3
                    .max(surface_capabilities.min_image_count)
                    .min(surface_capabilities.max_image_count.unwrap_or(u32::MAX)),

                image_format,
                // The dimensions of the window, only used to initially setup the swapchain.
                // NOTE:
                // On some drivers the swapchain dimensions are specified by
                // `surface_capabilities.current_extent` and the swapchain size must use these
                // dimensions.
                // These dimensions are always the same as the window dimensions.
                //
                // However, other drivers don't specify a value, i.e.
                // `surface_capabilities.current_extent` is `None`. These drivers will allow
                // anything, but the only sensible value is the window
                // dimensions.
                //
                // Both of these cases need the swapchain to use the window dimensions, so we just
                // use that.
                image_extent: window.inner_size().into(),

                image_usage: ImageUsage {
                    color_attachment: true,
                    ..ImageUsage::empty()
                },

                // The alpha mode indicates how the alpha value of the final image will behave. For
                // example, you can choose whether the window will be opaque or transparent.
                composite_alpha: surface_capabilities
                    .supported_composite_alpha
                    .iter()
                    .next()
                    .unwrap(),

                present_mode: PresentMode::Fifo,

                ..Default::default()
            },
        )
        .unwrap()
    };

    // The next step is to create the shaders.
    //
    // The raw shader creation API provided by the vulkano library is unsafe for various
    // reasons, so The `shader!` macro provides a way to generate a Rust module from GLSL
    // source - in the example below, the source is provided as a string input directly to
    // the shader, but a path to a source file can be provided as well. Note that the user
    // must specify the type of shader (e.g., "vertex," "fragment, etc.") using the `ty`
    // option of the macro.
    //
    // The module generated by the `shader!` macro includes a `load` function which loads
    // the shader using an input logical device. The module also includes type definitions
    // for layout structures defined in the shader source, for example, uniforms and push
    // constants.
    //
    // A more detailed overview of what the `shader!` macro generates can be found in the
    // `vulkano-shaders` crate docs. You can view them at https://docs.rs/vulkano-shaders/
    mod mesh_vs {
        vulkano_shaders::shader! {
            ty: "vertex",
            src: "
                #version 450
            
                layout(location = 0) in vec3 position;
                layout(location = 1) in vec3 normal;
                
                layout(location = 0) out vec3 v_normal;
                
                layout(push_constant) uniform PushConstantData {
                    mat4 world;
                    mat4 view;
                    mat4 proj;
                } pc;
                
                void main() {
                    mat4 worldview = pc.view * pc.world;
                    v_normal = normal; //normalize(transpose(inverse(mat3(worldview))) * normal);
                    gl_Position = pc.proj * worldview * vec4(position*1000.0, 1.0);
                }
			",
            types_meta: {
                use bytemuck::{Pod, Zeroable};

                #[derive(Clone, Copy, Zeroable, Pod, Debug)]
            },
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
        }
    }

    let mesh_vs = mesh_vs::load(device.clone()).unwrap();
    let mesh_fs = mesh_fs::load(device.clone()).unwrap();

    /*let uniform_buffer =
    CpuBufferPool::<vs::ty::PushConstantData>::uniform_buffer(memory_allocator);*/

    let memory_allocator = Arc::new(MemoryAllocator::new_default(device.clone()));

    // At this point, OpenGL initialization would be finished. However in Vulkan it is not. OpenGL
    // implicitly does a lot of computation whenever you draw. In Vulkan, you have to do all this
    // manually.

    // The next step is to create a *render pass*, which is an object that describes where the
    // output of the graphics pipeline will go. It describes the layout of the images
    // where the colors, depth and/or stencil information will be written.
    let render_pass = vulkano::ordered_passes_renderpass!(
        device.clone(),
        attachments: {
            // `color` is a custom name we give to the first and only attachment.
            color: {
                // `load: Clear` means that we ask the GPU to clear the content of this
                // attachment at the start of the drawing.
                load: Clear,
                // `store: Store` means that we ask the GPU to store the output of the draw
                // in the actual image. We could also ask it to discard the result.
                store: Store,
                // `format: <ty>` indicates the type of the format of the image. This has to
                // be one of the types of the `vulkano::format` module (or alternatively one
                // of your structs that implements the `FormatDesc` trait). Here we use the
                // same format as the swapchain.
                format: swapchain.image_format(),
                // `samples: 1` means that we ask the GPU to use one sample to determine the value
                // of each pixel in the color attachment. We could use a larger value (multisampling)
                // for antialiasing. An example of this can be found in msaa-renderpass.rs.
                samples: 1,
            },
            depth: {
                load: Clear,
                store: DontCare,
                format: Format::D16_UNORM,
                samples: 1,
            }
        },
        passes: [{
            // We use the attachment named `color` as the one and only color attachment.
            color: [color],
            // No depth-stencil attachment is indicated with empty brackets.
            depth_stencil: {depth},
            input: []
        },{
            // We use the attachment named `color` as the one and only color attachment.
            color: [color],
            // No depth-stencil attachment is indicated with empty brackets.
            depth_stencil: {depth},
            input: []
        }]
    )
    .unwrap();

    // Dynamic viewports allow us to recreate just the viewport when the window is resized
    // Otherwise we would have to recreate the whole pipeline.
    let mut viewport = Viewport {
        origin: [0.0, 0.0],
        dimensions: [0.0, 0.0],
        depth_range: 0.0..1.0,
    };

    // The render pass we created above only describes the layout of our framebuffers. Before we
    // can draw we also need to create the actual framebuffers.
    //
    // Since we need to draw to multiple images, we are going to create a different framebuffer for
    // each image.
    let ([mut mesh_pipeline], mut framebuffers) = window_size_dependent_setup(
        &memory_allocator,
        &mesh_vs,
        &mesh_fs,
        &images,
        render_pass.clone(),
        &mut viewport,
    );

    // Before we can start creating and recording command buffers, we need a way of allocating
    // them. Vulkano provides a command buffer allocator, which manages raw Vulkan command pools
    // underneath and provides a safe interface for them.
    let command_buffer_allocator =
        StandardCommandBufferAllocator::new(device.clone(), Default::default());

    // Initialization is finally finished!

    // In some situations, the swapchain will become invalid by itself. This includes for example
    // when the window is resized (as the images of the swapchain will no longer match the
    // window's) or, on Android, when the application went to the background and goes back to the
    // foreground.
    //
    // In this situation, acquiring a swapchain image or presenting it will return an error.
    // Rendering to an image of that swapchain will not produce any error, but may or may not work.
    // To continue rendering, we need to recreate the swapchain by creating a new swapchain.
    // Here, we remember that we need to do this for the next loop iteration.
    let mut recreate_swapchain = false;

    // In the loop below we are going to submit commands to the GPU. Submitting a command produces
    // an object that implements the `GpuFuture` trait, which holds the resources for as long as
    // they are in use by the GPU.
    //
    // Destroying the `GpuFuture` blocks until the GPU is finished executing it. In order to avoid
    // that, we store the submission of the previous frame here.
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

    let uniform_buffer = CpuBufferPool::<mesh_fs::ty::Data>::new(
        memory_allocator.clone(),
        BufferUsage {
            uniform_buffer: true,
            ..BufferUsage::empty()
        },
        MemoryUsage::Upload,
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

    gstate.meshes.push(load_obj(
        &memory_allocator,
        &mut Cursor::new(PLATONIC_SOLIDS[0].1),
        PLATONIC_SOLIDS[0].0.to_string(),
    ));

    gstate
        .lights
        .push(Light::new([4., 6., 8.], [1., 1., 8.], 0.01));
    gstate
        .lights
        .push(Light::new([-4., 6., -8.], [8., 4., 1.], 0.01));

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
                    WindowEvent::DroppedFile(file) => {
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
                //println!("AXISM {:?}", delta);
            }
            Event::RedrawEventsCleared => {
                for i in 1..gstate.fps.len() {
                    gstate.fps[i - 1] = gstate.fps[i];
                }

                gstate.fps[gstate.fps.len() - 1] =
                    1.0 / (Instant::now() - render_start).as_secs_f64();

                render_start = Instant::now();

                // Do not draw frame when screen dimensions are zero.
                // On Windows, this can occur from minimizing the application.
                let window = surface.object().unwrap().downcast_ref::<Window>().unwrap();
                let dimensions = window.inner_size();
                if dimensions.width == 0 || dimensions.height == 0 {
                    return;
                }

                // It is important to call this function from time to time, otherwise resources will keep
                // accumulating and you will eventually reach an out of memory error.
                // Calling this function polls various fences in order to determine what the GPU has
                // already processed, and frees the resources that are no longer needed.
                previous_frame_end.as_mut().unwrap().cleanup_finished();

                // Whenever the window resizes we need to recreate everything dependent on the window size.
                // In this example that includes the swapchain, the framebuffers and the dynamic state viewport.
                if recreate_swapchain {
                    // Use the new dimensions of the window.

                    let (new_swapchain, new_images) =
                        match swapchain.recreate(SwapchainCreateInfo {
                            image_extent: dimensions.into(),
                            ..swapchain.create_info()
                        }) {
                            Ok(r) => r,
                            // This error tends to happen when the user is manually resizing the window.
                            // Simply restarting the loop is the easiest way to fix this issue.
                            Err(SwapchainCreationError::ImageExtentNotSupported { .. }) => return,
                            Err(e) => panic!("Failed to recreate swapchain: {e:?}"),
                        };

                    swapchain = new_swapchain;
                    // Because framebuffers contains an Arc on the old swapchain, we need to
                    // recreate framebuffers as well.
                    ([mesh_pipeline], framebuffers) = window_size_dependent_setup(
                        &memory_allocator,
                        &mesh_vs,
                        &mesh_fs,
                        &new_images,
                        render_pass.clone(),
                        &mut viewport,
                    );
                    recreate_swapchain = false;
                }

                //println!("{:?}", right);

                let mut push_constants = {
                    if looking {
                        if keys.w {
                            campos -= Matrix3::from_angle_y(camforward.y)
                                * Matrix3::from_angle_x(camforward.x)
                                * Vector3::unit_z()
                                * 0.02
                                * gstate.move_speed;
                        }
                        if keys.s {
                            campos += Matrix3::from_angle_y(camforward.y)
                                * Matrix3::from_angle_x(camforward.x)
                                * Vector3::unit_z()
                                * 0.02
                                * gstate.move_speed;
                        }
                        if keys.a {
                            campos += Matrix3::from_angle_y(camforward.y)
                                * Matrix3::from_angle_x(camforward.x)
                                * Vector3::unit_x()
                                * 0.02
                                * gstate.move_speed;
                        }
                        if keys.d {
                            campos -= Matrix3::from_angle_y(camforward.y)
                                * Matrix3::from_angle_x(camforward.x)
                                * Vector3::unit_x()
                                * 0.02
                                * gstate.move_speed;
                        }
                    } else {
                        keys.w = false;
                        keys.s = false;
                        keys.a = false;
                        keys.d = false;
                    }

                    // note: this teapot was meant for OpenGL where the origin is at the lower left
                    //       instead the origin is at the upper left in Vulkan, so we reverse the Y axis
                    let aspect_ratio =
                        swapchain.image_extent()[0] as f32 / swapchain.image_extent()[1] as f32;
                    let proj = cgmath::perspective(
                        Rad(std::f32::consts::FRAC_PI_2),
                        aspect_ratio,
                        0.01,
                        100.0,
                    );
                    let scale = 0.01;
                    let view = Matrix4::from(camforward)
                        * Matrix4::from_angle_z(Deg(180f32))
                        * Matrix4::from_translation(Point3::origin() - campos)
                        * Matrix4::from_scale(scale);
                    //*Matrix4::from_angle_z(Deg(180f32));

                    let pc = mesh_vs::ty::PushConstantData {
                        world: Matrix4::identity().into(),
                        view: view.into(),
                        proj: proj.into(),
                    };

                    if looking {
                        /*println!(
                            "world: {:?} view: {:?} proj: {:?}",
                            pc.world, pc.view, pc.proj
                        );*/
                        println!("campos: {:?} camforward: {:?}", campos, camforward);
                    }

                    pc
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

                    let uniform_data = mesh_fs::ty::Data {
                        pos,
                        col,
                        light_count: gstate.lights.len() as u32,
                    };

                    uniform_buffer.from_data(uniform_data).unwrap()
                };

                let layout = mesh_pipeline.layout().set_layouts().get(0).unwrap();
                let set = PersistentDescriptorSet::new(
                    &descriptor_set_allocator,
                    layout.clone(),
                    [WriteDescriptorSet::buffer(0, uniform_buffer_subbuffer)],
                )
                .unwrap();

                // Before we can draw on the output, we have to *acquire* an image from the swapchain. If
                // no image is available (which happens if you submit draw commands too quickly), then the
                // function will block.
                // This operation returns the index of the image that we are allowed to draw upon.
                //
                // This function can block if no image is available. The parameter is an optional timeout
                // after which the function call will return an error.
                let (image_index, suboptimal, acquire_future) =
                    match acquire_next_image(swapchain.clone(), None) {
                        Ok(r) => r,
                        Err(AcquireError::OutOfDate) => {
                            recreate_swapchain = true;
                            return;
                        }
                        Err(e) => panic!("Failed to acquire next image: {:?}", e),
                    };

                // acquire_next_image can be successful, but suboptimal. This means that the swapchain image
                // will still work, but it may not display correctly. With some drivers this can be when
                // the window resizes, but it may not cause the swapchain to become out of date.
                if suboptimal {
                    recreate_swapchain = true;
                }

                gui_up(&mut gui, &mut gstate);

                // In order to draw, we have to build a *command buffer*. The command buffer object holds
                // the list of commands that are going to be executed.
                //
                // Building a command buffer is an expensive operation (usually a few hundred
                // microseconds), but it is known to be a hot path in the driver and is expected to be
                // optimized.
                //
                // Note that we have to pass a queue family when we create the command buffer. The command
                // buffer will only be executable on that given queue family.
                let mut builder = AutoCommandBufferBuilder::primary(
                    &command_buffer_allocator,
                    queue.queue_family_index(),
                    CommandBufferUsage::OneTimeSubmit,
                )
                .unwrap();

                let cb = gui.draw_on_subpass_image(dimensions.into());

                builder
                    // Before we can draw, we have to *enter a render pass*.
                    .begin_render_pass(
                        RenderPassBeginInfo {
                            // A list of values to clear the attachments with. This list contains
                            // one item for each attachment in the render pass. In this case,
                            // there is only one attachment, and we clear it with a blue color.
                            //
                            // Only attachments that have `LoadOp::Clear` are provided with clear
                            // values, any others should use `ClearValue::None` as the clear value.
                            clear_values: vec![
                                Some([0.12, 0.1, 0.1, 1.0].into()),
                                Some(1.0.into()),
                            ],
                            ..RenderPassBeginInfo::framebuffer(
                                framebuffers[image_index as usize].clone(),
                            )
                        },
                        // The contents of the first (and only) subpass. This can be either
                        // `Inline` or `SecondaryCommandBuffers`. The latter is a bit more advanced
                        // and is not covered here.
                        SubpassContents::Inline,
                    )
                    .unwrap()
                    // We are now inside the first subpass of the render pass. We add a draw command.
                    //
                    // The last two parameters contain the list of resources to pass to the shaders.
                    // Since we used an `EmptyPipeline` object, the objects have to be `()`.
                    .set_viewport(0, [viewport.clone()])
                    .bind_pipeline_graphics(mesh_pipeline.clone())
                    .bind_descriptor_sets(
                        PipelineBindPoint::Graphics,
                        mesh_pipeline.layout().clone(),
                        0,
                        set,
                    );

                for object in &gstate.meshes {
                    push_constants.world =
                        (Matrix4::from_translation(object.pos - Point3::origin())
                            * Matrix4::from(object.rot)
                            * object.scale)
                            .into();
                    builder
                        .bind_vertex_buffers(0, object.vertices.clone())
                        .bind_index_buffer(object.indices.clone())
                        .push_constants(mesh_pipeline.layout().clone(), 0, push_constants)
                        .draw_indexed(object.indices.len() as u32, 1, 0, 0, 0)
                        .unwrap();
                }

                // We leave the render pass. Note that if we had multiple
                // subpasses we could have called `next_subpass` to jump to the next subpass.
                builder
                    .next_subpass(SubpassContents::SecondaryCommandBuffers)
                    .unwrap()
                    .execute_commands(cb)
                    .unwrap()
                    .end_render_pass()
                    .unwrap();

                // Finish building the command buffer by calling `build`.
                let command_buffer = builder.build().unwrap();

                let future = previous_frame_end
                    .take()
                    .unwrap()
                    .join(acquire_future)
                    .then_execute(queue.clone(), command_buffer)
                    .unwrap()
                    // The color output is now expected to contain our triangle. But in order to show it on
                    // the screen, we have to *present* the image by calling `present`.
                    //
                    // This function does not actually present the image immediately. Instead it submits a
                    // present command at the end of the queue. This means that it will only be presented once
                    // the GPU has finished executing the command buffer that draws the triangle.
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
fn window_size_dependent_setup(
    allocator: &StandardMemoryAllocator,
    mesh_vs: &ShaderModule,
    mesh_fs: &ShaderModule,
    images: &[Arc<SwapchainImage>],
    render_pass: Arc<RenderPass>,
    viewport: &mut Viewport,
) -> ([Arc<GraphicsPipeline>; 1], Vec<Arc<Framebuffer>>) {
    let dimensions = images[0].dimensions().width_height();
    viewport.dimensions = [dimensions[0] as f32, dimensions[1] as f32];

    let depth_buffer = ImageView::new_default(
        AttachmentImage::transient(allocator, dimensions, Format::D16_UNORM).unwrap(),
    )
    .unwrap();

    let framebuffers = images
        .iter()
        .map(|image| {
            let view = ImageView::new_default(image.clone()).unwrap();
            Framebuffer::new(
                render_pass.clone(),
                FramebufferCreateInfo {
                    attachments: vec![view, depth_buffer.clone()],
                    ..Default::default()
                },
            )
            .unwrap()
        })
        .collect::<Vec<_>>();

    // Before we draw we have to create what is called a pipeline. This is similar to an OpenGL
    // program, but much more specific.
    let mesh_pipeline = GraphicsPipeline::start()
        // We have to indicate which subpass of which render pass this pipeline is going to be used
        // in. The pipeline will only be usable from this particular subpass.
        .render_pass(Subpass::from(render_pass.clone(), 0).unwrap())
        // We need to indicate the layout of the vertices.
        .vertex_input_state(BuffersDefinition::new().vertex::<Vertex>())
        // The content of the vertex buffer describes a list of triangles.
        .input_assembly_state(InputAssemblyState::new())
        // A Vulkan shader can in theory contain multiple entry points, so we have to specify
        // which one.
        .vertex_shader(mesh_vs.entry_point("main").unwrap(), ())
        .viewport_state(ViewportState::viewport_fixed_scissor_irrelevant([
            Viewport {
                origin: [0.0, 0.0],
                dimensions: [dimensions[0] as f32, dimensions[1] as f32],
                depth_range: 0.0..1.0,
            },
        ]))
        // See `vertex_shader`.
        .fragment_shader(mesh_fs.entry_point("main").unwrap(), ())
        .depth_stencil_state(DepthStencilState::simple_depth_test())
        .rasterization_state(RasterizationState {
            front_face: Fixed(Clockwise),
            cull_mode: Fixed(CullMode::Back),
            ..RasterizationState::default()
        })
        // Now that our builder is filled, we call `build()` to obtain an actual pipeline.
        .build(allocator.device().clone())
        .unwrap();

    ([mesh_pipeline], framebuffers)
}
