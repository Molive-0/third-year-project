use egui::{
    plot::{Line, Plot, PlotPoints},
    Color32, Frame, Id,
};
use egui_winit_vulkano::Gui;

use crate::objects::{Light, Mesh, CSG};

fn sized_text(ui: &mut egui::Ui, text: impl Into<String>, size: f32) {
    ui.label(egui::RichText::new(text).size(size));
}

#[derive(Debug)]
pub struct GState {
    pub cursor_sensitivity: f32,
    pub move_speed: f32,

    pub meshes: Vec<Mesh>,
    pub lights: Vec<Light>,
    pub csg: Vec<CSG>,

    pub fps: [f64; 128],
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
        }
    }
}

pub fn gui_up(gui: &mut Gui, state: &mut GState) {
    gui.immediate_ui(|gui| {
        let ctx = gui.context();
        egui::SidePanel::left(Id::new("main_left"))
            .frame(Frame::default().fill(Color32::from_rgba_unmultiplied(100, 100, 100, 200)))
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
                        for mesh in &mut state.meshes {
                            ui.label(mesh.name.clone());
                            ui.add(egui::Slider::new(&mut mesh.pos.x, -100.0..=100.0).text("Position.x"));
                            ui.add(egui::Slider::new(&mut mesh.pos.y, -100.0..=100.0).text("Position.y"));
                            ui.add(egui::Slider::new(&mut mesh.pos.z, -100.0..=100.0).text("Position.z"));
                            ui.add(egui::Slider::new(&mut mesh.rot.x.0, 0.0..=360.0).text("Rotation.x"));
                            ui.add(egui::Slider::new(&mut mesh.rot.y.0, 0.0..=360.0).text("Rotation.y"));
                            ui.add(egui::Slider::new(&mut mesh.rot.z.0, 0.0..=360.0).text("Rotation.z"));
                        }
                        ui.heading("Lights");
                        for light in &mut state.lights {
                            ui.label("Light");
                            ui.add(egui::Slider::new(&mut light.pos.x, -100.0..=100.0).text("Position.x"));
                            ui.add(egui::Slider::new(&mut light.pos.y, -100.0..=100.0).text("Position.y"));
                            ui.add(egui::Slider::new(&mut light.pos.z, -100.0..=100.0).text("Position.z"));
                            ui.add(egui::Slider::new(&mut light.colour.x, 0.0..=1.0).text("Colour.r"));
                            ui.add(egui::Slider::new(&mut light.colour.y, 0.0..=1.0).text("Colour.g"));
                            ui.add(egui::Slider::new(&mut light.colour.z, 0.0..=1.0).text("Colour.b"));
                        }
                        let fps: PlotPoints = state.fps.iter().enumerate().map(|(x,y)| [x as f64,*y]).collect::<Vec<_>>().into();
                        let line = Line::new(fps);
                        ui.heading("FPS");
                        Plot::new("fps").view_aspect(2.0).show(ui, |plot_ui| plot_ui.line(line));
                    });
                });
            });
    });
}
