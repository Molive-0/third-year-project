use std::env;
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
    let mut out = "
    #[repr(u16)]
    pub enum InstructionSet{

    "
    .to_owned();

    for l in f.lines() {
        let line = l?;
        out += &line[11..line.len() - 12];
        out += ",\n";
    }
    out += "}";

    fs::write(&dest_path, out).unwrap();
    println!("cargo:rerun-if-changed=build.rs");
    Ok(())
}
