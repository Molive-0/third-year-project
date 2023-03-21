use std::env;
use std::fmt::format;
use std::fs;
use std::fs::File;
use std::io;
use std::io::BufRead;
use std::io::BufReader;
use std::path::Path;

fn main() -> io::Result<()> {
    println!("cargo:rerun-if-changed=src/instructionset.glsl");
    let out_dir = env::var_os("OUT_DIR").unwrap();
    let dest_path = Path::new(&out_dir).join("instructionset.rs");
    let f = File::open("src/instructionset.glsl")?;
    let f = BufReader::new(f);
    let mut out = "#[allow(non_snake_case)]
    #[derive(Clone, Copy, Debug, PartialEq, Eq)]
    pub enum InputTypes{
        #[allow(non_snake_case)]
        Float,
        #[allow(non_snake_case)]
        Vec2,
        #[allow(non_snake_case)]
        Vec3,
        #[allow(non_snake_case)]
        Vec4,
        #[allow(non_snake_case)]
        Mat2,
        #[allow(non_snake_case)]
        Mat3,
        #[allow(non_snake_case)]
        Mat4,
    }

    #[repr(u16)]
    #[allow(non_snake_case)]
    #[derive(Clone, Copy, Debug, PartialEq, Eq)]
    pub enum InstructionSet{

    "
    .to_owned();

    let mut outputimpl = "
    pub fn output(&self) -> Vec<InputTypes>
    {
        match self {

    "
    .to_owned();

    let mut inputimpl = "
    pub fn input(&self) -> Vec<InputTypes>
    {
        match self {

    "
    .to_owned();

    for (index, l) in f.lines().enumerate() {
        let line = l?;
        let entries = line.split("//").map(str::trim).collect::<Vec<&str>>();
        if entries[0].len() == 0 {
            continue;
        }

        let name = &entries[0][11..entries[0].len() - 12];

        out += &format!(
            "#[allow(non_snake_case)]\n#[allow(dead_code)]\n{}={},\n",
            name, index
        );

        inputimpl += &format!(
            "#[allow(non_snake_case)]\nInstructionSet::{} => vec![",
            name
        );
        for input in entries[1].split(" ").map(str::trim) {
            if input.len() == 0 {
                continue;
            }
            match input {
                "F" => inputimpl += "InputTypes::Float,",
                "V2" => inputimpl += "InputTypes::Vec2,",
                "V3" => inputimpl += "InputTypes::Vec3,",
                "V4" => inputimpl += "InputTypes::Vec4,",
                "M2" => inputimpl += "InputTypes::Mat2,",
                "M3" => inputimpl += "InputTypes::Mat3,",
                "M4" => inputimpl += "InputTypes::Mat4,",
                _ => panic!("unknown input?? [{}]", input),
            }
        }
        inputimpl += "],\n";

        outputimpl += &format!(
            "#[allow(non_snake_case)]\nInstructionSet::{} => vec![",
            name
        );
        for output in entries[2].split(" ").map(str::trim) {
            if output.len() == 0 {
                continue;
            }
            match output {
                "F" => outputimpl += "InputTypes::Float,",
                "V2" => outputimpl += "InputTypes::Vec2,",
                "V3" => outputimpl += "InputTypes::Vec3,",
                "V4" => outputimpl += "InputTypes::Vec4,",
                "M2" => outputimpl += "InputTypes::Mat2,",
                "M3" => outputimpl += "InputTypes::Mat3,",
                "M4" => outputimpl += "InputTypes::Mat4,",
                _ => panic!("unknown output?? [{}]", output),
            }
        }
        outputimpl += "],\n";
    }
    out += "}";
    inputimpl += "}}";
    outputimpl += "}}";
    out += "#[allow(non_snake_case)]\nimpl InstructionSet {\n";
    out += &inputimpl;
    out += &outputimpl;
    out += "}";

    fs::write(&dest_path, out).unwrap();
    println!("cargo:rerun-if-changed=build.rs");
    Ok(())
}
