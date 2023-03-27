use crate::{
    instruction_set::InstructionSet::*, objects::Inputs, Float, Mat2, Mat3, Mat4, Vec2, Vec3, Vec4,
    CSG,
};

use cgmath::{Array, ElementWise, InnerSpace, MetricSpace, VectorSpace};

#[derive(Clone, Debug)]
pub struct Interpreter<'csg> {
    float_stack: Vec<Float>,
    vec2_stack: Vec<Vec2>,
    vec3_stack: Vec<Vec3>,
    vec4_stack: Vec<Vec4>,
    mat2_stack: Vec<Mat2>,
    mat3_stack: Vec<Mat3>,
    mat4_stack: Vec<Mat4>,

    float_const_head: usize,
    vec2_const_head: usize,
    vec3_const_head: usize,
    vec4_const_head: usize,
    mat2_const_head: usize,
    mat3_const_head: usize,
    mat4_const_head: usize,

    csg: &'csg CSG,
}

trait Pull {
    fn pull(inter: &mut Interpreter) -> Self;
}

macro_rules! impl_pull {
    ($type:ty, $stack:ident) => {
        impl Pull for $type {
            fn pull(inter: &mut Interpreter) -> Self {
                inter.$stack.pop().unwrap()
            }
        }
    };
}

impl_pull!(Float, float_stack);
impl_pull!(Vec2, vec2_stack);
impl_pull!(Vec3, vec3_stack);
impl_pull!(Vec4, vec4_stack);
impl_pull!(Mat2, mat2_stack);
impl_pull!(Mat3, mat3_stack);
impl_pull!(Mat4, mat4_stack);

impl From<Inputs> for Float {
    fn from(value: Inputs) -> Self {
        match value {
            Inputs::Float(a) => a,
            _ => panic!("Incorrect float conversion!"),
        }
    }
}

impl From<Inputs> for Vec2 {
    fn from(value: Inputs) -> Self {
        match value {
            Inputs::Vec2(a) => a,
            _ => panic!("Incorrect vec2 conversion!"),
        }
    }
}

impl From<Inputs> for Vec3 {
    fn from(value: Inputs) -> Self {
        match value {
            Inputs::Vec3(a) => a,
            _ => panic!("Incorrect vec3 conversion!"),
        }
    }
}

impl From<Inputs> for Vec4 {
    fn from(value: Inputs) -> Self {
        match value {
            Inputs::Vec4(a) => a,
            _ => panic!("Incorrect vec4 conversion!"),
        }
    }
}

impl From<Inputs> for Mat2 {
    fn from(value: Inputs) -> Self {
        match value {
            Inputs::Mat2(a) => a,
            _ => panic!("Incorrect mat2 conversion!"),
        }
    }
}

impl From<Inputs> for Mat3 {
    fn from(value: Inputs) -> Self {
        match value {
            Inputs::Mat3(a) => a,
            _ => panic!("Incorrect mat3 conversion!"),
        }
    }
}

impl From<Inputs> for Mat4 {
    fn from(value: Inputs) -> Self {
        match value {
            Inputs::Mat4(a) => a,
            _ => panic!("Incorrect mat4 conversion!"),
        }
    }
}

impl From<Mat4> for Inputs {
    fn from(value: Mat4) -> Self {
        Inputs::Mat4(value)
    }
}

impl From<Mat3> for Inputs {
    fn from(value: Mat3) -> Self {
        Inputs::Mat3(value)
    }
}

impl From<Mat2> for Inputs {
    fn from(value: Mat2) -> Self {
        Inputs::Mat2(value)
    }
}

impl From<Vec4> for Inputs {
    fn from(value: Vec4) -> Self {
        Inputs::Vec4(value)
    }
}

impl From<Vec3> for Inputs {
    fn from(value: Vec3) -> Self {
        Inputs::Vec3(value)
    }
}

impl From<Vec2> for Inputs {
    fn from(value: Vec2) -> Self {
        Inputs::Vec2(value)
    }
}

impl From<Float> for Inputs {
    fn from(value: Float) -> Self {
        Inputs::Float(value)
    }
}

impl<'csg> Interpreter<'csg> {
    fn pull<T: Pull + From<Inputs>>(&mut self, consider: Inputs) -> T {
        if consider == Inputs::Variable {
            T::pull(self)
        } else {
            consider.into()
        }
    }
    fn push<T: Into<Inputs>>(&mut self, value: T) {
        let input: Inputs = value.into();
        match input {
            Inputs::Float(f) => self.float_stack.push(f),
            Inputs::Vec2(f) => self.vec2_stack.push(f),
            Inputs::Vec3(f) => self.vec3_stack.push(f),
            Inputs::Vec4(f) => self.vec4_stack.push(f),
            Inputs::Mat2(f) => self.mat2_stack.push(f),
            Inputs::Mat3(f) => self.mat3_stack.push(f),
            Inputs::Mat4(f) => self.mat4_stack.push(f),
            Inputs::Variable => unreachable!(),
        }
    }
}

macro_rules! mul {
    ($self:ident, $instruction:ident, $type1:ty, Float) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        let in2: Float = $self.pull($instruction.constants[1]);
        $self.push(in1 * in2);
    };
    ($self:ident, $instruction:ident, $type1:ty, $type2:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        let in2: $type2 = $self.pull($instruction.constants[1]);
        $self.push(in1.mul_element_wise(in2));
    };
}

macro_rules! div {
    ($self:ident, $instruction:ident, $type1:ty, Float) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        let in2: Float = $self.pull($instruction.constants[1]);
        $self.push(in1 / in2);
    };
    ($self:ident, $instruction:ident, $type1:ty, $type2:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        let in2: $type2 = $self.pull($instruction.constants[1]);
        $self.push(in1.div_element_wise(in2));
    };
}

macro_rules! add {
    ($self:ident, $instruction:ident, Float, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        let in2: Float = $self.pull($instruction.constants[1]);
        $self.push(in1 + in2);
    };
    ($self:ident, $instruction:ident, $type1:ty, $type2:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        let in2: $type2 = $self.pull($instruction.constants[1]);
        $self.push(in1.add_element_wise(in2));
    };
}

macro_rules! sub {
    ($self:ident, $instruction:ident, Float, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        let in2: Float = $self.pull($instruction.constants[1]);
        $self.push(in1 - in2);
    };
    ($self:ident, $instruction:ident, $type1:ty, $type2:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        let in2: $type2 = $self.pull($instruction.constants[1]);
        $self.push(in1.sub_element_wise(in2));
    };
}

macro_rules! modulo {
    ($self:ident, $instruction:ident, Float, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        let in2: Float = $self.pull($instruction.constants[1]);
        $self.push(in1 % in2);
    };
    ($self:ident, $instruction:ident, $type1:ty, $type2:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        let in2: $type2 = $self.pull($instruction.constants[1]);
        $self.push(in1.rem_element_wise(in2));
    };
}

macro_rules! pow {
    ($self:ident, $instruction:ident, Float, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        let in2: Float = $self.pull($instruction.constants[1]);
        $self.push(in1.powf(in2));
    };
    ($self:ident, $instruction:ident, $type1:ty, Float) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        let in2: Float = $self.pull($instruction.constants[1]);
        $self.push(in1.map(|x| x.powf(in2)));
    };
    ($self:ident, $instruction:ident, $type1:ty, $type2:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        let in2: $type2 = $self.pull($instruction.constants[1]);
        $self.push(in1.zip(in2, Float::powf));
    };
}

macro_rules! distance {
    ($self:ident, $instruction:ident, $type1:ty, $type2:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        let in2: $type2 = $self.pull($instruction.constants[1]);
        $self.push(in1.distance(in2));
    };
}

macro_rules! dot {
    ($self:ident, $instruction:ident, $type1:ty, $type2:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        let in2: $type2 = $self.pull($instruction.constants[1]);
        $self.push(in1.dot(in2));
    };
}

macro_rules! clamp {
    ($self:ident, $instruction:ident, Float, Float, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        let in2: Float = $self.pull($instruction.constants[1]);
        let in3: Float = $self.pull($instruction.constants[2]);
        $self.push(in1.clamp(in2, in3));
    };
    ($self:ident, $instruction:ident, $type1:ty, Float, Float) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        let in2: Float = $self.pull($instruction.constants[1]);
        let in3: Float = $self.pull($instruction.constants[2]);
        $self.push(in1.map(|x| x.clamp(in2, in3)));
    };
    ($self:ident, $instruction:ident, $type1:ty, $type2:ty, $type3:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        let in2: $type2 = $self.pull($instruction.constants[1]);
        let in3: $type3 = $self.pull($instruction.constants[2]);
        $self.push(in1.zip(in2, Float::max).zip(in3, Float::min));
    };
}

macro_rules! mix {
    ($self:ident, $instruction:ident, Float, Float, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        let in2: Float = $self.pull($instruction.constants[1]);
        let in3: Float = $self.pull($instruction.constants[2]);
        $self.push((in1 * ((1 as Float) - in3)) + (in2 * in3));
    };
    ($self:ident, $instruction:ident, $type1:ty, $type2:ty, Float) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        let in2: $type2 = $self.pull($instruction.constants[1]);
        let in3: Float = $self.pull($instruction.constants[2]);
        $self.push(in1.lerp(in2, in3));
    };
    ($self:ident, $instruction:ident, $type1:ty, $type2:ty, $type3:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        let in2: $type2 = $self.pull($instruction.constants[1]);
        let in3: $type3 = $self.pull($instruction.constants[2]);
        $self.push(
            (in1.mul_element_wise(<$type3>::from_value(1 as Float).sub_element_wise(in3)))
                + (in2.mul_element_wise(in3)),
        );
    };
}

macro_rules! fma {
    ($self:ident, $instruction:ident, Float, Float, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        let in2: Float = $self.pull($instruction.constants[1]);
        let in3: Float = $self.pull($instruction.constants[2]);
        $self.push(in1.mul_add(in2, in3));
    };
    ($self:ident, $instruction:ident, $type1:ty, $type2:ty, $type3:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        let in2: $type1 = $self.pull($instruction.constants[1]);
        let in3: $type3 = $self.pull($instruction.constants[2]);
        $self.push((in1.mul_element_wise(in2)) + in3);
    };
}

macro_rules! square {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push(in1 * in1);
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.mul_element_wise(in1));
    };
}

macro_rules! cube {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push(in1 * in1 * in1);
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.mul_element_wise(in1).mul_element_wise(in1));
    };
}

macro_rules! len {
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.magnitude());
    };
}

macro_rules! mattranspose {
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.transpose());
    };
}

macro_rules! matdeterminant {
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.determinant());
    };
}

macro_rules! matinvert {
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.inverse());
    };
}

macro_rules! absolute {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push(in1.abs());
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.map(Float::abs));
    };
}

//imitate glsl, not rust
fn sign(f: Float) -> Float {
    if f == 0. {
        f
    } else {
        f.signum()
    }
}

macro_rules! sign {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push(sign(in1));
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.map(sign));
    };
}

macro_rules! floor {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push(in1.floor());
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.map(Float::floor));
    };
}

macro_rules! ceiling {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push(in1.ceil());
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.map(Float::ceil));
    };
}

macro_rules! fract {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push(in1.fract());
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.map(Float::fract));
    };
}

macro_rules! squareroot {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push(in1.sqrt());
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.map(Float::sqrt));
    };
}

macro_rules! inversesquareroot {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push((1 as Float) / in1.sqrt());
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.map(|x| (1 as Float) / x.sqrt()));
    };
}

macro_rules! exponent {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push(in1.exp());
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.map(Float::exp));
    };
}

macro_rules! exponent2 {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push(in1.exp2());
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.map(Float::exp2));
    };
}

macro_rules! logarithm {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push(in1.ln());
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.map(Float::ln));
    };
}

macro_rules! logarithm2 {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push(in1.log2());
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.map(Float::log2));
    };
}

macro_rules! sine {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push(in1.sin());
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.map(Float::sin));
    };
}

macro_rules! cosine {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push(in1.cos());
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.map(Float::cos));
    };
}

macro_rules! tangent {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push(in1.tan());
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.map(Float::tan));
    };
}

macro_rules! arcsine {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push(in1.asin());
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.map(Float::asin));
    };
}

macro_rules! arccosine {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push(in1.acos());
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.map(Float::acos));
    };
}

macro_rules! arctangent {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push(in1.atan());
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.map(Float::atan));
    };
}

macro_rules! hyperbolicsine {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push(in1.sinh());
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.map(Float::sinh));
    };
}

macro_rules! hyperboliccosine {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push(in1.cosh());
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.map(Float::cosh));
    };
}

macro_rules! hyperbolictangent {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push(in1.tanh());
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.map(Float::tanh));
    };
}

macro_rules! hyperbolicarcsine {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push(in1.asinh());
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.map(Float::asinh));
    };
}

macro_rules! hyperbolicarccosine {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push(in1.acosh());
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.map(Float::acosh));
    };
}

macro_rules! hyperbolicarctangent {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push(in1.atanh());
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.map(Float::atanh));
    };
}

macro_rules! min {
    ($self:ident, $instruction:ident, $type1:ty, Float) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        let in2: Float = $self.pull($instruction.constants[1]);
        $self.push(in1.min(in2));
    };
    ($self:ident, $instruction:ident, $type1:ty,$type2:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        let in2: $type2 = $self.pull($instruction.constants[1]);
        $self.push(in1.zip(in2, Float::min));
    };
}

macro_rules! max {
    ($self:ident, $instruction:ident, $type1:ty, Float) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        let in2: Float = $self.pull($instruction.constants[1]);
        $self.push(in1.max(in2));
    };
    ($self:ident, $instruction:ident, $type1:ty,$type2:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        let in2: $type2 = $self.pull($instruction.constants[1]);
        $self.push(in1.zip(in2, Float::max));
    };
}

macro_rules! round {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push(in1.round());
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.map(Float::round));
    };
}

macro_rules! trunc {
    ($self:ident, $instruction:ident, Float) => {
        let in1: Float = $self.pull($instruction.constants[0]);
        $self.push(in1.trunc());
    };
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.map(Float::trunc));
    };
}

macro_rules! normalise {
    ($self:ident, $instruction:ident, $type1:ty) => {
        let in1: $type1 = $self.pull($instruction.constants[0]);
        $self.push(in1.normalize());
    };
}

impl<'csg> Interpreter<'csg> {
    pub fn new(csg: &'csg CSG) -> Self {
        Interpreter {
            float_stack: vec![],
            vec2_stack: vec![],
            vec3_stack: vec![],
            vec4_stack: vec![],
            mat2_stack: vec![],
            mat3_stack: vec![],
            mat4_stack: vec![],
            float_const_head: 0,
            vec2_const_head: 0,
            vec3_const_head: 0,
            vec4_const_head: 0,
            mat2_const_head: 0,
            mat3_const_head: 0,
            mat4_const_head: 0,
            csg,
        }
    }

    fn clear_stacks(&mut self) -> () {
        self.float_stack.clear();
        self.vec2_stack.clear();
        self.vec3_stack.clear();
        self.vec4_stack.clear();
        self.mat2_stack.clear();
        self.mat3_stack.clear();
        self.mat4_stack.clear();
        self.float_const_head = 0;
        self.vec2_const_head = 0;
        self.vec3_const_head = 0;
        self.vec4_const_head = 0;
        self.mat2_const_head = 0;
        self.mat3_const_head = 0;
        self.mat4_const_head = 0;
    }

    //const masklen: usize = 29;
    //mask: [u8; masklen];

    /*void default_mask()
    {
        mask=uint8_t[29](
            uint8_t(255),
            uint8_t(255),
            uint8_t(255),
            uint8_t(255),
            uint8_t(255),
            uint8_t(255),
            uint8_t(255),
            uint8_t(255),
            uint8_t(255),
            uint8_t(255),
            uint8_t(255),
            uint8_t(255),
            uint8_t(255),
            uint8_t(255),
            uint8_t(255),
            uint8_t(255),
            uint8_t(255),
            uint8_t(255),
            uint8_t(255),
            uint8_t(255),
            uint8_t(255),
            uint8_t(255),
            uint8_t(255),
            uint8_t(255),
            uint8_t(255),
            uint8_t(255),
            uint8_t(255),
            uint8_t(255),
            uint8_t(255)
        );
    }*/

    pub fn scene(&mut self, p: Vec3) -> Float {
        self.clear_stacks();
        self.push(p);

        for instruction in &self.csg.parts {
            match instruction.opcode {
                OPAddFloatFloat => {
                    add!(self, instruction, Float, Float);
                }

                OPAddVec2Vec2 => {
                    add!(self, instruction, Vec2, Vec2);
                }

                OPAddVec2Float => {
                    add!(self, instruction, Vec2, Float);
                }

                OPAddVec3Vec3 => {
                    add!(self, instruction, Vec3, Vec3);
                }

                OPAddVec3Float => {
                    add!(self, instruction, Vec3, Float);
                }

                OPAddVec4Vec4 => {
                    add!(self, instruction, Vec4, Vec4);
                }

                OPAddVec4Float => {
                    add!(self, instruction, Vec4, Float);
                }

                OPSubFloatFloat => {
                    sub!(self, instruction, Float, Float);
                }

                OPSubVec2Vec2 => {
                    sub!(self, instruction, Vec2, Vec2);
                }

                OPSubVec2Float => {
                    sub!(self, instruction, Vec2, Float);
                }

                OPSubVec3Vec3 => {
                    sub!(self, instruction, Vec3, Vec3);
                }

                OPSubVec3Float => {
                    sub!(self, instruction, Vec3, Float);
                }

                OPSubVec4Vec4 => {
                    sub!(self, instruction, Vec4, Vec4);
                }

                OPSubVec4Float => {
                    sub!(self, instruction, Vec4, Float);
                }

                OPMulFloatFloat => {
                    mul!(self, instruction, Float, Float);
                }

                OPMulVec2Vec2 => {
                    mul!(self, instruction, Vec2, Vec2);
                }

                OPMulVec2Float => {
                    mul!(self, instruction, Vec2, Float);
                }

                OPMulVec3Vec3 => {
                    mul!(self, instruction, Vec3, Vec3);
                }

                OPMulVec3Float => {
                    mul!(self, instruction, Vec3, Float);
                }

                OPMulVec4Vec4 => {
                    mul!(self, instruction, Vec4, Vec4);
                }

                OPMulVec4Float => {
                    mul!(self, instruction, Vec4, Float);
                }

                OPDivFloatFloat => {
                    div!(self, instruction, Float, Float);
                }

                OPDivVec2Vec2 => {
                    div!(self, instruction, Vec2, Vec2);
                }

                OPDivVec2Float => {
                    div!(self, instruction, Vec2, Float);
                }

                OPDivVec3Vec3 => {
                    div!(self, instruction, Vec3, Vec3);
                }

                OPDivVec3Float => {
                    div!(self, instruction, Vec3, Float);
                }

                OPDivVec4Vec4 => {
                    div!(self, instruction, Vec4, Vec4);
                }

                OPDivVec4Float => {
                    div!(self, instruction, Vec4, Float);
                }

                OPPowFloatFloat => {
                    pow!(self, instruction, Float, Float);
                }

                OPPowVec2Vec2 => {
                    pow!(self, instruction, Vec2, Vec2);
                }

                OPPowVec3Vec3 => {
                    pow!(self, instruction, Vec3, Vec3);
                }

                OPPowVec4Vec4 => {
                    pow!(self, instruction, Vec4, Vec4);
                }

                OPModFloatFloat => {
                    modulo!(self, instruction, Float, Float);
                }

                OPModVec2Vec2 => {
                    modulo!(self, instruction, Vec2, Vec2);
                }

                OPModVec2Float => {
                    modulo!(self, instruction, Vec2, Float);
                }

                OPModVec3Vec3 => {
                    modulo!(self, instruction, Vec3, Vec3);
                }

                OPModVec3Float => {
                    modulo!(self, instruction, Vec3, Float);
                }

                OPModVec4Vec4 => {
                    modulo!(self, instruction, Vec4, Vec4);
                }

                OPModVec4Float => {
                    modulo!(self, instruction, Vec4, Float);
                }

                OPCrossVec3 => {
                    let in1: Vec3 = self.pull(instruction.constants[0]);
                    let in2: Vec3 = self.pull(instruction.constants[1]);
                    self.push(in1.cross(in2));
                }

                OPDotVec2 => {
                    dot!(self, instruction, Vec2, Vec2);
                }

                OPDotVec3 => {
                    dot!(self, instruction, Vec3, Vec3);
                }

                OPDotVec4 => {
                    dot!(self, instruction, Vec4, Vec4);
                }

                OPLengthVec2 => {
                    len!(self, instruction, Vec2);
                }

                OPLengthVec3 => {
                    len!(self, instruction, Vec3);
                }

                OPLengthVec4 => {
                    len!(self, instruction, Vec4);
                }

                OPDistanceVec2 => {
                    distance!(self, instruction, Vec2, Vec2);
                }

                OPDistanceVec3 => {
                    distance!(self, instruction, Vec3, Vec3);
                }

                OPDistanceVec4 => {
                    distance!(self, instruction, Vec4, Vec4);
                }

                OPAbsFloat => {
                    absolute!(self, instruction, Float);
                }

                OPSignFloat => {
                    sign!(self, instruction, Float);
                }

                OPFloorFloat => {
                    floor!(self, instruction, Float);
                }

                OPCeilFloat => {
                    ceiling!(self, instruction, Float);
                }

                OPFractFloat => {
                    fract!(self, instruction, Float);
                }

                OPSqrtFloat => {
                    squareroot!(self, instruction, Float);
                }

                OPInverseSqrtFloat => {
                    inversesquareroot!(self, instruction, Float);
                }

                OPExpFloat => {
                    exponent!(self, instruction, Float);
                }

                OPExp2Float => {
                    exponent2!(self, instruction, Float);
                }

                OPLogFloat => {
                    logarithm!(self, instruction, Float);
                }

                OPLog2Float => {
                    logarithm2!(self, instruction, Float);
                }

                OPSinFloat => {
                    sine!(self, instruction, Float);
                }

                OPCosFloat => {
                    cosine!(self, instruction, Float);
                }

                OPTanFloat => {
                    tangent!(self, instruction, Float);
                }

                OPAsinFloat => {
                    arcsine!(self, instruction, Float);
                }

                OPAcosFloat => {
                    arccosine!(self, instruction, Float);
                }

                OPAtanFloat => {
                    arctangent!(self, instruction, Float);
                }

                OPAcoshFloat => {
                    hyperbolicarccosine!(self, instruction, Float);
                }

                OPAsinhFloat => {
                    hyperbolicarcsine!(self, instruction, Float);
                }

                OPAtanhFloat => {
                    hyperbolicarctangent!(self, instruction, Float);
                }

                OPCoshFloat => {
                    hyperboliccosine!(self, instruction, Float);
                }

                OPSinhFloat => {
                    hyperbolicsine!(self, instruction, Float);
                }

                OPTanhFloat => {
                    hyperbolictangent!(self, instruction, Float);
                }

                OPRoundFloat => {
                    round!(self, instruction, Float);
                }

                OPTruncFloat => {
                    trunc!(self, instruction, Float);
                }

                OPMinMaterialFloat | OPMinFloat => {
                    min!(self, instruction, Float, Float);
                }

                OPMaxMaterialFloat | OPMaxFloat => {
                    max!(self, instruction, Float, Float);
                }

                OPFMAFloat => {
                    fma!(self, instruction, Float, Float, Float);
                }

                OPAbsVec2 => {
                    absolute!(self, instruction, Vec2);
                }

                OPSignVec2 => {
                    sign!(self, instruction, Vec2);
                }

                OPFloorVec2 => {
                    floor!(self, instruction, Vec2);
                }

                OPCeilVec2 => {
                    ceiling!(self, instruction, Vec2);
                }

                OPFractVec2 => {
                    fract!(self, instruction, Vec2);
                }

                OPSqrtVec2 => {
                    squareroot!(self, instruction, Vec2);
                }

                OPInverseSqrtVec2 => {
                    inversesquareroot!(self, instruction, Vec2);
                }

                OPExpVec2 => {
                    exponent!(self, instruction, Vec2);
                }

                OPExp2Vec2 => {
                    exponent2!(self, instruction, Vec2);
                }

                OPLogVec2 => {
                    logarithm!(self, instruction, Vec2);
                }

                OPLog2Vec2 => {
                    logarithm2!(self, instruction, Vec2);
                }

                OPSinVec2 => {
                    sine!(self, instruction, Vec2);
                }

                OPCosVec2 => {
                    cosine!(self, instruction, Vec2);
                }

                OPTanVec2 => {
                    tangent!(self, instruction, Vec2);
                }

                OPAsinVec2 => {
                    arcsine!(self, instruction, Vec2);
                }

                OPAcosVec2 => {
                    arccosine!(self, instruction, Vec2);
                }

                OPAtanVec2 => {
                    arctangent!(self, instruction, Vec2);
                }

                OPAcoshVec2 => {
                    hyperbolicarccosine!(self, instruction, Vec2);
                }

                OPAsinhVec2 => {
                    hyperbolicarcsine!(self, instruction, Vec2);
                }

                OPAtanhVec2 => {
                    hyperbolicarctangent!(self, instruction, Vec2);
                }

                OPCoshVec2 => {
                    hyperboliccosine!(self, instruction, Vec2);
                }

                OPSinhVec2 => {
                    hyperbolicsine!(self, instruction, Vec2);
                }

                OPTanhVec2 => {
                    hyperbolictangent!(self, instruction, Vec2);
                }

                OPRoundVec2 => {
                    round!(self, instruction, Vec2);
                }

                OPTruncVec2 => {
                    trunc!(self, instruction, Vec2);
                }

                OPMinVec2 => {
                    min!(self, instruction, Vec2, Vec2);
                }

                OPMaxVec2 => {
                    max!(self, instruction, Vec2, Vec2);
                }

                OPFMAVec2 => {
                    fma!(self, instruction, Vec2, Vec2, Vec2);
                }

                OPAbsVec3 => {
                    absolute!(self, instruction, Vec3);
                }

                OPSignVec3 => {
                    sign!(self, instruction, Vec3);
                }

                OPFloorVec3 => {
                    floor!(self, instruction, Vec3);
                }

                OPCeilVec3 => {
                    ceiling!(self, instruction, Vec3);
                }

                OPFractVec3 => {
                    fract!(self, instruction, Vec3);
                }

                OPSqrtVec3 => {
                    squareroot!(self, instruction, Vec3);
                }

                OPInverseSqrtVec3 => {
                    inversesquareroot!(self, instruction, Vec3);
                }

                OPExpVec3 => {
                    exponent!(self, instruction, Vec3);
                }

                OPExp2Vec3 => {
                    exponent2!(self, instruction, Vec3);
                }

                OPLogVec3 => {
                    logarithm!(self, instruction, Vec3);
                }

                OPLog2Vec3 => {
                    logarithm2!(self, instruction, Vec3);
                }

                OPSinVec3 => {
                    sine!(self, instruction, Vec3);
                }

                OPCosVec3 => {
                    cosine!(self, instruction, Vec3);
                }

                OPTanVec3 => {
                    tangent!(self, instruction, Vec3);
                }

                OPAsinVec3 => {
                    arcsine!(self, instruction, Vec3);
                }

                OPAcosVec3 => {
                    arccosine!(self, instruction, Vec3);
                }

                OPAtanVec3 => {
                    arctangent!(self, instruction, Vec3);
                }

                OPAcoshVec3 => {
                    hyperbolicarccosine!(self, instruction, Vec3);
                }

                OPAsinhVec3 => {
                    hyperbolicarcsine!(self, instruction, Vec3);
                }

                OPAtanhVec3 => {
                    hyperbolicarctangent!(self, instruction, Vec3);
                }

                OPCoshVec3 => {
                    hyperboliccosine!(self, instruction, Vec3);
                }

                OPSinhVec3 => {
                    hyperbolicsine!(self, instruction, Vec3);
                }

                OPTanhVec3 => {
                    hyperbolictangent!(self, instruction, Vec3);
                }

                OPRoundVec3 => {
                    round!(self, instruction, Vec3);
                }

                OPTruncVec3 => {
                    trunc!(self, instruction, Vec3);
                }

                OPMinVec3 => {
                    min!(self, instruction, Vec3, Vec3);
                }

                OPMaxVec3 => {
                    max!(self, instruction, Vec3, Vec3);
                }

                OPFMAVec3 => {
                    fma!(self, instruction, Vec3, Vec3, Vec3);
                }

                OPAbsVec4 => {
                    absolute!(self, instruction, Vec4);
                }

                OPSignVec4 => {
                    sign!(self, instruction, Vec4);
                }

                OPFloorVec4 => {
                    floor!(self, instruction, Vec4);
                }

                OPCeilVec4 => {
                    ceiling!(self, instruction, Vec4);
                }

                OPFractVec4 => {
                    fract!(self, instruction, Vec4);
                }

                OPSqrtVec4 => {
                    squareroot!(self, instruction, Vec4);
                }

                OPInverseSqrtVec4 => {
                    inversesquareroot!(self, instruction, Vec4);
                }

                OPExpVec4 => {
                    exponent!(self, instruction, Vec4);
                }

                OPExp2Vec4 => {
                    exponent2!(self, instruction, Vec4);
                }

                OPLogVec4 => {
                    logarithm!(self, instruction, Vec4);
                }

                OPLog2Vec4 => {
                    logarithm2!(self, instruction, Vec4);
                }

                OPSinVec4 => {
                    sine!(self, instruction, Vec4);
                }

                OPCosVec4 => {
                    cosine!(self, instruction, Vec4);
                }

                OPTanVec4 => {
                    tangent!(self, instruction, Vec4);
                }

                OPAsinVec4 => {
                    arcsine!(self, instruction, Vec4);
                }

                OPAcosVec4 => {
                    arccosine!(self, instruction, Vec4);
                }

                OPAtanVec4 => {
                    arctangent!(self, instruction, Vec4);
                }

                OPAcoshVec4 => {
                    hyperbolicarccosine!(self, instruction, Vec4);
                }

                OPAsinhVec4 => {
                    hyperbolicarcsine!(self, instruction, Vec4);
                }

                OPAtanhVec4 => {
                    hyperbolicarctangent!(self, instruction, Vec4);
                }

                OPCoshVec4 => {
                    hyperboliccosine!(self, instruction, Vec4);
                }

                OPSinhVec4 => {
                    hyperbolicsine!(self, instruction, Vec4);
                }

                OPTanhVec4 => {
                    hyperbolictangent!(self, instruction, Vec4);
                }

                OPRoundVec4 => {
                    round!(self, instruction, Vec4);
                }

                OPTruncVec4 => {
                    trunc!(self, instruction, Vec4);
                }

                OPMinVec4 => {
                    min!(self, instruction, Vec4, Vec4);
                }

                OPMaxVec4 => {
                    max!(self, instruction, Vec4, Vec4);
                }

                OPFMAVec4 => {
                    fma!(self, instruction, Vec4, Vec4, Vec4);
                }

                OPClampFloatFloat => {
                    clamp!(self, instruction, Float, Float, Float);
                }

                OPMixFloatFloat => {
                    mix!(self, instruction, Float, Float, Float);
                }

                OPClampVec2Vec2 => {
                    clamp!(self, instruction, Vec2, Vec2, Vec2);
                }

                OPMixVec2Vec2 => {
                    mix!(self, instruction, Vec2, Vec2, Vec2);
                }

                OPClampVec2Float => {
                    clamp!(self, instruction, Vec2, Float, Float);
                }

                OPMixVec2Float => {
                    mix!(self, instruction, Vec2, Vec2, Float);
                }

                OPClampVec3Vec3 => {
                    clamp!(self, instruction, Vec3, Vec3, Vec3);
                }

                OPMixVec3Vec3 => {
                    mix!(self, instruction, Vec3, Vec3, Vec3);
                }

                OPClampVec3Float => {
                    clamp!(self, instruction, Vec3, Float, Float);
                }

                OPMixVec3Float => {
                    mix!(self, instruction, Vec3, Vec3, Float);
                }

                OPClampVec4Vec4 => {
                    clamp!(self, instruction, Vec4, Vec4, Vec4);
                }

                OPMixVec4Vec4 => {
                    mix!(self, instruction, Vec4, Vec4, Vec4);
                }

                OPClampVec4Float => {
                    clamp!(self, instruction, Vec4, Float, Float);
                }

                OPMixVec4Float => {
                    mix!(self, instruction, Vec4, Vec4, Float);
                }

                OPNormalizeVec2 => {
                    normalise!(self, instruction, Vec2);
                }

                OPNormalizeVec3 => {
                    normalise!(self, instruction, Vec3);
                }

                OPNormalizeVec4 => {
                    normalise!(self, instruction, Vec4);
                }

                OPPromoteFloatFloatVec2 => {
                    let in1: Float = self.pull(instruction.constants[0]);
                    let in2: Float = self.pull(instruction.constants[1]);
                    self.push(Vec2::new(in1, in2));
                }

                OPPromoteFloatFloatFloatVec3 => {
                    let in1: Float = self.pull(instruction.constants[0]);
                    let in2: Float = self.pull(instruction.constants[1]);
                    let in3: Float = self.pull(instruction.constants[2]);
                    self.push(Vec3::new(in1, in2, in3));
                }

                OPPromoteVec2FloatVec3 => {
                    let in1: Vec2 = self.pull(instruction.constants[0]);
                    let in2: Float = self.pull(instruction.constants[1]);
                    self.push(Vec3::new(in1.x, in1.y, in2));
                }

                OPPromoteFloatFloatFloatFloatVec4 => {
                    let in1: Float = self.pull(instruction.constants[0]);
                    let in2: Float = self.pull(instruction.constants[1]);
                    let in3: Float = self.pull(instruction.constants[2]);
                    let in4: Float = self.pull(instruction.constants[3]);
                    self.push(Vec4::new(in1, in2, in3, in4));
                }

                OPPromoteVec2FloatFloatVec4 => {
                    let in1: Vec2 = self.pull(instruction.constants[0]);
                    let in2: Float = self.pull(instruction.constants[1]);
                    let in3: Float = self.pull(instruction.constants[2]);
                    self.push(Vec4::new(in1.x, in1.y, in2, in3));
                }

                OPPromoteVec3FloatVec4 => {
                    let in1: Vec3 = self.pull(instruction.constants[0]);
                    let in2: Float = self.pull(instruction.constants[1]);
                    self.push(Vec4::new(in1.x, in1.y, in1.z, in2));
                }

                OPPromoteVec2Vec2Vec4 => {
                    let in1: Vec2 = self.pull(instruction.constants[0]);
                    let in2: Vec2 = self.pull(instruction.constants[1]);
                    self.push(Vec4::new(in1.x, in1.y, in2.x, in2.y));
                }

                OPSquareFloat => {
                    square!(self, instruction, Float);
                }

                OPCubeFloat => {
                    cube!(self, instruction, Float);
                }

                OPSquareVec2 => {
                    square!(self, instruction, Vec2);
                }

                OPCubeVec2 => {
                    cube!(self, instruction, Vec2);
                }

                OPSquareVec3 => {
                    square!(self, instruction, Vec3);
                }

                OPCubeVec3 => {
                    cube!(self, instruction, Vec3);
                }

                OPSquareVec4 => {
                    square!(self, instruction, Vec4);
                }

                OPCubeVec4 => {
                    cube!(self, instruction, Vec4);
                }

                OPSmoothMinMaterialFloat | OPSmoothMinFloat => {
                    let k: Float = self.pull(instruction.constants[0]);
                    let a: Float = self.pull(instruction.constants[1]);
                    let b: Float = self.pull(instruction.constants[2]);
                    let h: Float = (k - (a - b).abs()).max(0.) / k;
                    self.push(a.min(b) - h * h * k * (1. / 4.));
                }

                OPSmoothMaxMaterialFloat | OPSmoothMaxFloat => {
                    let k: Float = self.pull(instruction.constants[0]);
                    let a: Float = self.pull(instruction.constants[1]);
                    let b: Float = self.pull(instruction.constants[2]);
                    let h: Float = (k - (a - b).abs()).max(0.) / k;
                    self.push(a.max(b) + h * h * k * (1. / 4.));
                }

                OPDupFloat => {
                    self.float_stack
                        .push(self.float_stack[self.float_stack.len() - 1]);
                }

                OPDup2Float => {
                    self.float_stack
                        .push(self.float_stack[self.float_stack.len() - 2]);
                }

                OPDup3Float => {
                    self.float_stack
                        .push(self.float_stack[self.float_stack.len() - 3]);
                }

                OPDup4Float => {
                    self.float_stack
                        .push(self.float_stack[self.float_stack.len() - 4]);
                }

                OPDupVec2 => {
                    self.vec2_stack
                        .push(self.vec2_stack[self.vec2_stack.len() - 1]);
                }

                OPDup2Vec2 => {
                    self.vec2_stack
                        .push(self.vec2_stack[self.vec2_stack.len() - 2]);
                }

                OPDup3Vec2 => {
                    self.vec2_stack
                        .push(self.vec2_stack[self.vec2_stack.len() - 3]);
                }

                OPDup4Vec2 => {
                    self.vec2_stack
                        .push(self.vec2_stack[self.vec2_stack.len() - 4]);
                }

                OPDupVec3 => {
                    self.vec3_stack
                        .push(self.vec3_stack[self.vec3_stack.len() - 1]);
                }

                OPDup2Vec3 => {
                    self.vec3_stack
                        .push(self.vec3_stack[self.vec3_stack.len() - 2]);
                }

                OPDup3Vec3 => {
                    self.vec3_stack
                        .push(self.vec3_stack[self.vec3_stack.len() - 3]);
                }

                OPDup4Vec3 => {
                    self.vec3_stack
                        .push(self.vec3_stack[self.vec3_stack.len() - 4]);
                }

                OPDupVec4 => {
                    self.vec4_stack
                        .push(self.vec4_stack[self.vec4_stack.len() - 1]);
                }

                OPDup2Vec4 => {
                    self.vec4_stack
                        .push(self.vec4_stack[self.vec4_stack.len() - 2]);
                }

                OPDup3Vec4 => {
                    self.vec4_stack
                        .push(self.vec4_stack[self.vec4_stack.len() - 3]);
                }

                OPDup4Vec4 => {
                    self.vec4_stack
                        .push(self.vec4_stack[self.vec4_stack.len() - 4]);
                }

                OPSDFSphere => {
                    let r: Float = self.pull(instruction.constants[0]);
                    let p: Vec3 = self.pull(instruction.constants[1]);
                    self.push(p.magnitude() - r);
                }

                OPSDFBox => {
                    let r: Vec3 = self.pull(instruction.constants[0]);
                    let p: Vec3 = self.pull(instruction.constants[1]);
                    let q = p.map(Float::abs) - r;
                    self.push(
                        (q.map(|x| x.max(0 as Float))).magnitude() + q.x.max(q.y.max(q.z)).min(0.),
                    );
                }

                OPSDFTorus => {
                    let t: Vec2 = self.pull(instruction.constants[0]);
                    let p: Vec3 = self.pull(instruction.constants[1]);
                    let q = Vec2::new(((p.x * p.x) + (p.z * p.z)).sqrt() - t.x, p.y);
                    self.push(q.magnitude() - t.y);
                }

                OPNop => {}

                OPStop => {
                    return self.pull(instruction.constants[0]);
                }
                _ => {
                    unreachable!("invalid instruction");
                }
            }
        }
        return self.pull(Inputs::Variable);
    }
}
