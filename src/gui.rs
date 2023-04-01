use egui::{
    plot::{Line, Plot, PlotPoints},
    Color32, Frame, Id,
};
use egui_winit_vulkano::Gui;

use crate::objects::{Light, Mesh, CSG};

fn sized_text(ui: &mut egui::Ui, text: impl Into<String>, size: f32) {
    ui.label(egui::RichText::new(text).size(size));
}

#[derive(Copy, Clone, Debug, Default, PartialEq, Eq)]
pub struct PreviousDebug {
    pub bounding_boxes: bool,
    pub disable_meshcull: bool,
    pub disable_meshscale1: bool,
    pub disable_meshscale2: bool,
    pub disable_taskcull: bool,
}

#[derive(Debug)]
pub struct GState {
    pub cursor_sensitivity: f32,
    pub move_speed: f32,

    pub meshes: Vec<Mesh>,
    pub lights: Vec<Light>,
    pub csg: Vec<CSG>,

    pub fps: [f64; 128],

    pub debug: PreviousDebug,
}

impl Default for GState {
    fn default() -> Self {
        Self {
            cursor_sensitivity: 1.0,
            move_speed: 1.0,

            meshes: vec![],
            lights: vec![],
            csg: vec![],

            fps: [0.0; 128],

            debug: Default::default(),
        }
    }
}

pub fn gui_up(gui: &mut Gui, state: &mut GState) {
    gui.immediate_ui(|gui| {
        let ctx = gui.context();
        egui::SidePanel::left(Id::new("main_left"))
            .frame(Frame::default().fill(Color32::from_rgba_unmultiplied(50, 50, 50, 200)))
            .show(&ctx, |ui| {
                ui.vertical_centered(|ui| {
                    ui.add(egui::widgets::Label::new("Efficient Realtime Rendering of Complex Closed Form Implicit Surfaces Using Modern RTX Enabled GPUs"));
                    sized_text(ui, "Settings", 32.0);
                });
                ui.separator();
                egui::ScrollArea::vertical().show(ui, |ui| {
                    ui.vertical_centered(|ui| {
                        ui.heading("Camera Control");
                        ui.add(egui::Slider::new(&mut state.cursor_sensitivity, 0.0..=2.0).text("Mouse Sensitivity"));
                        ui.add(egui::Slider::new(&mut state.move_speed, 0.0..=2.0).text("Movement Speed"));
                        ui.heading("Meshes");
                        let mut meshdel = vec![];
                        for mesh in &mut state.meshes {
                            ui.label(mesh.name.clone());
                            meshdel.push(ui.small_button("remove mesh").clicked());
                            ui.add(egui::Slider::new(&mut mesh.pos.x, -100.0..=100.0).text("Position.x"));
                            ui.add(egui::Slider::new(&mut mesh.pos.y, -100.0..=100.0).text("Position.y"));
                            ui.add(egui::Slider::new(&mut mesh.pos.z, -100.0..=100.0).text("Position.z"));
                            ui.add(egui::Slider::new(&mut mesh.rot.x.0, 0.0..=360.0).text("Rotation.x"));
                            ui.add(egui::Slider::new(&mut mesh.rot.y.0, 0.0..=360.0).text("Rotation.y"));
                            ui.add(egui::Slider::new(&mut mesh.rot.z.0, 0.0..=360.0).text("Rotation.z"));
                            ui.add(egui::Slider::new(&mut mesh.scale.x, 0.0..=2.0).text("Scale.x"));
                            ui.add(egui::Slider::new(&mut mesh.scale.y, 0.0..=2.0).text("Scale.y"));
                            ui.add(egui::Slider::new(&mut mesh.scale.z, 0.0..=2.0).text("Scale.z"));
                        }
                        for i in meshdel.into_iter().enumerate().filter_map(|(a,b)| if b {Some(a)} else {None})
                        {
                            state.meshes.remove(i);
                        }
                        ui.heading("Implicit Surfaces");
                        let mut csgdel = vec![];
                        for csg in &mut state.csg {
                            ui.label(csg.name.clone());
                            csgdel.push(ui.small_button("remove csg").clicked());
                            ui.add(egui::Slider::new(&mut csg.pos.x, -100.0..=100.0).text("Position.x"));
                            ui.add(egui::Slider::new(&mut csg.pos.y, -100.0..=100.0).text("Position.y"));
                            ui.add(egui::Slider::new(&mut csg.pos.z, -100.0..=100.0).text("Position.z"));
                            ui.add(egui::Slider::new(&mut csg.rot.x.0, 0.0..=360.0).text("Rotation.x"));
                            ui.add(egui::Slider::new(&mut csg.rot.y.0, 0.0..=360.0).text("Rotation.y"));
                            ui.add(egui::Slider::new(&mut csg.rot.z.0, 0.0..=360.0).text("Rotation.z"));
                            ui.add(egui::Slider::new(&mut csg.scale.x, 0.0..=2.0).text("Scale.x"));
                            ui.add(egui::Slider::new(&mut csg.scale.y, 0.0..=2.0).text("Scale.y"));
                            ui.add(egui::Slider::new(&mut csg.scale.z, 0.0..=2.0).text("Scale.z"));
                        }
                        for i in csgdel.into_iter().enumerate().filter_map(|(a,b)| if b {Some(a)} else {None})
                        {
                            state.csg.remove(i);
                        }
                        ui.heading("Lights");
                        let mut lightdel = vec![];
                        for light in &mut state.lights {
                            ui.label("Light");
                            lightdel.push(ui.small_button("remove light").clicked());
                            ui.add(egui::Slider::new(&mut light.pos.x, -100.0..=100.0).text("Position.x"));
                            ui.add(egui::Slider::new(&mut light.pos.y, -100.0..=100.0).text("Position.y"));
                            ui.add(egui::Slider::new(&mut light.pos.z, -100.0..=100.0).text("Position.z"));
                            ui.add(egui::Slider::new(&mut light.colour.x, 0.0..=1.0).text("Colour.r"));
                            ui.add(egui::Slider::new(&mut light.colour.y, 0.0..=1.0).text("Colour.g"));
                            ui.add(egui::Slider::new(&mut light.colour.z, 0.0..=1.0).text("Colour.b"));
                        }
                        for i in lightdel.into_iter().enumerate().filter_map(|(a,b)| if b {Some(a)} else {None})
                        {
                            state.lights.remove(i);
                        }
                        if (state.lights.len() < 32) {
                            if ui.small_button("add light").clicked()
                            {
                                state.lights.push(Light::default());
                            }
                        }

                        let fps: PlotPoints = state.fps.iter().enumerate().map(|(x,y)| [x as f64,*y]).collect::<Vec<_>>().into();
                        let line = Line::new(fps);
                        ui.heading("FPS");
                        Plot::new("fps").view_aspect(2.0).show(ui, |plot_ui| plot_ui.line(line));

                        ui.heading("Debug");
                        ui.toggle_value(&mut state.debug.bounding_boxes, "Render bounding boxes instead");
                        ui.toggle_value(&mut state.debug.disable_meshcull, "Disable mesh shader culling");
                        ui.toggle_value(&mut state.debug.disable_meshscale1, "Disable mesh shader scaling part 1");
                        ui.toggle_value(&mut state.debug.disable_meshscale2, "Disable mesh shader scaling part 2");
                        ui.toggle_value(&mut state.debug.disable_taskcull, "Disable task shader culling");
                    });
                });
            });
    });
}
