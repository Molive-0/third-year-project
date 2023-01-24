use egui::{Color32, Frame, Id, ScrollArea, TextEdit, TextStyle};
use egui_winit_vulkano::Gui;

fn sized_text(ui: &mut egui::Ui, text: impl Into<String>, size: f32) {
    ui.label(egui::RichText::new(text).size(size));
}

const CODE: &str = r#"
# Some markup
```
let mut gui = Gui::new(&event_loop, renderer.surface(), renderer.queue());
```
Vulkan(o) is hard, that I know...
"#;

#[derive(Debug)]
pub struct GState {
    pub cursor_sensitivity: f32,
    pub move_speed: f32,
}

impl Default for GState {
    fn default() -> Self {
        Self {
            cursor_sensitivity: 1.0,
            move_speed: 1.0,
        }
    }
}

pub fn gui_up(gui: &mut Gui, state: &mut GState) {
    let mut code = CODE.to_owned();
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
                ui.vertical_centered(|ui| {
                    //ui.heading("Camera Control");
                    ui.add(egui::Slider::new(&mut state.cursor_sensitivity, 0.0..=2.0).text("Mouse Sensitivity"));
                    ui.add(egui::Slider::new(&mut state.move_speed, 0.0..=2.0).text("Movement Speed"));
                });   
            });
    });
}
