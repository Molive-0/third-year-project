//#extension GL_EXT_shader_16bit_storage:require
#extension GL_EXT_shader_explicit_arithmetic_types:require

#ifndef interpreter
#define interpreter 1

#include "instructionset.glsl"

layout(set=0,binding=2)uniform SceneDescription{
    u32vec4 d[13];//stored packed for space efficiency, 8 per index
}scene_description;

// unpack as both integers and floats
#define get_caches u32vec4 major_unpack=scene_description.d[major_position];\
f16vec2 minor_float_unpack=unpackFloat2x16(major_unpack.x);\
minor_float_cache[0]=minor_float_unpack.x;\
minor_float_cache[1]=minor_float_unpack.y;\
minor_float_unpack=unpackFloat2x16(major_unpack.y);\
minor_float_cache[2]=minor_float_unpack.x;\
minor_float_cache[3]=minor_float_unpack.y;\
minor_float_unpack=unpackFloat2x16(major_unpack.z);\
minor_float_cache[4]=minor_float_unpack.x;\
minor_float_cache[5]=minor_float_unpack.y;\
minor_float_unpack=unpackFloat2x16(major_unpack.w);\
minor_float_cache[6]=minor_float_unpack.x;\
minor_float_cache[7]=minor_float_unpack.y;\
u16vec2 minor_integer_unpack=unpackUint2x16(major_unpack.x);\
minor_integer_cache[0]=minor_integer_unpack.x;\
minor_integer_cache[1]=minor_integer_unpack.y;\
minor_integer_unpack=unpackUint2x16(major_unpack.y);\
minor_integer_cache[2]=minor_integer_unpack.x;\
minor_integer_cache[3]=minor_integer_unpack.y;\
minor_integer_unpack=unpackUint2x16(major_unpack.z);\
minor_integer_cache[4]=minor_integer_unpack.x;\
minor_integer_cache[5]=minor_integer_unpack.y;\
minor_integer_unpack=unpackUint2x16(major_unpack.w);\
minor_integer_cache[6]=minor_integer_unpack.x;\
minor_integer_cache[7]=minor_integer_unpack.y;

float float_stack[8];
uint float_stack_head=0;
vec2 vec2_stack[8];
uint vec2_stack_head=0;
vec3 vec3_stack[8];
uint vec3_stack_head=0;
vec4 vec4_stack[8];
uint vec4_stack_head=0;
mat2 mat2_stack[8];
uint mat2_stack_head=0;
mat3 mat3_stack[8];
uint mat3_stack_head=0;
mat4 mat4_stack[8];
uint mat4_stack_head=0;
mat4 material_stack[8];
uint material_stack_head=0;

void push_float(float f){
    float_stack[float_stack_head++]=f;
}

float pull_float(){
    return float_stack[--float_stack_head];
}

void push_vec2(vec2 f){
    vec2_stack[vec2_stack_head++]=f;
}

vec2 pull_vec2(){
    return vec2_stack[--vec2_stack_head];
}

void push_vec3(vec3 f){
    vec3_stack[vec3_stack_head++]=f;
}

vec3 pull_vec3(){
    return vec3_stack[--vec3_stack_head];
}

void push_vec4(vec4 f){
    vec4_stack[vec4_stack_head++]=f;
}

vec4 pull_vec4(){
    return vec4_stack[--vec4_stack_head];
}

void push_mat2(mat2 f){
    mat2_stack[mat2_stack_head++]=f;
}

mat2 pull_mat2(){
    return mat2_stack[--mat2_stack_head];
}

void push_mat3(mat3 f){
    mat3_stack[mat3_stack_head++]=f;
}

mat3 pull_mat3(){
    return mat3_stack[--mat3_stack_head];
}

void push_mat4(mat4 f){
    mat4_stack[mat4_stack_head++]=f;
}

mat4 pull_mat4(){
    return mat4_stack[--mat4_stack_head];
}

void push_material(mat4 f){
    material_stack[material_stack_head++]=f;
}

mat4 pull_material(){
    return material_stack[--material_stack_head];
}

void clear_stacks()
{
    float_stack_head=0;
    vec2_stack_head=0;
    vec3_stack_head=0;
    vec4_stack_head=0;
    mat2_stack_head=0;
    mat3_stack_head=0;
    mat4_stack_head=0;
    material_stack_head=0;
}

uint8_t mask[13];

void default_mask()
{
    mask=uint8_t[13](uint8_t(255),uint8_t(255),uint8_t(255),uint8_t(255),uint8_t(255),uint8_t(255),uint8_t(255),uint8_t(255),uint8_t(255),uint8_t(255),uint8_t(255),uint8_t(255),uint8_t(255));
}

float scene(vec3 p,bool material)
{
    uint major_position=0;
    uint minor_position=0;
    
    float16_t minor_float_cache[8];
    uint16_t minor_integer_cache[8];
    
    clear_stacks();
    push_vec3(p);
    
    bool cont=true;
    
    while(cont){
        if(minor_position==0){
            get_caches;
        }
        /*if(float(minor_float_cache[minor_position])==5)
        return vec3(0.,0.,1.);
        if(isnan(minor_float_cache[minor_position+1]))
        return vec3(0.,1.,0.);
        if(isnan(minor_float_cache[minor_position+2]))
        return vec3(1.,0.,0.);
        if(isnan(minor_float_cache[minor_position+3]))
        return vec3(1.,0.,1.);
        if(isnan(minor_float_cache[minor_position+4]))
        return vec3(0.,1.,1.);
        if(isnan(minor_float_cache[minor_position+5]))
        return vec3(1.,1.,0.);
        //if (float(minor_float_cache[minor_position+5]) == 5)
        return vec3(1.,1.,1.);
        
        return vec3(float(minor_float_cache[minor_position]),float(minor_float_cache[minor_position+1]),float(minor_float_cache[minor_position+2]));
        */
        if((mask[major_position]&(1<<minor_position))>0)
        {
            //return vec3(1.,1.,0.);
            if(isnan(minor_float_cache[minor_position]))
            {
                float floattemp;
                vec2 vec2temp;
                vec3 vec3temp;
                vec4 vec4temp;
                mat2 mat2temp;
                mat3 mat3temp;
                mat4 mat4temp;
                
                switch(uint(minor_integer_cache[minor_position])&511)
                {
                    case OPAddFloatFloat:
                    push_float(pull_float()+pull_float());
                    break;
                    case OPAddVec2Vec2:
                    push_vec2(pull_vec2()+pull_vec2());
                    break;
                    case OPAddVec2Float:
                    push_vec2(pull_vec2()+pull_float());
                    break;
                    case OPAddVec3Vec3:
                    push_vec3(pull_vec3()+pull_vec3());
                    break;
                    case OPAddVec3Float:
                    push_vec3(pull_vec3()+pull_float());
                    break;
                    case OPAddVec4Vec4:
                    push_vec4(pull_vec4()+pull_vec4());
                    break;
                    case OPAddVec4Float:
                    push_vec4(pull_vec4()+pull_float());
                    break;
                    case OPAddMat2Mat2:
                    push_mat2(pull_mat2()+pull_mat2());
                    break;
                    case OPAddMat2Float:
                    push_mat2(pull_mat2()+pull_float());
                    break;
                    case OPAddMat3Mat3:
                    push_mat3(pull_mat3()+pull_mat3());
                    break;
                    case OPAddMat3Float:
                    push_mat3(pull_mat3()+pull_float());
                    break;
                    case OPAddMat4Mat4:
                    push_mat4(pull_mat4()+pull_mat4());
                    break;
                    case OPAddMat4Float:
                    push_mat4(pull_mat4()+pull_float());
                    break;
                    
                    case OPMulFloatFloat:
                    push_float(pull_float()*pull_float());
                    break;
                    case OPMulVec2Vec2:
                    push_vec2(pull_vec2()*pull_vec2());
                    break;
                    case OPMulVec2Float:
                    push_vec2(pull_vec2()*pull_float());
                    break;
                    case OPMulVec3Vec3:
                    push_vec3(pull_vec3()*pull_vec3());
                    break;
                    case OPMulVec3Float:
                    push_vec3(pull_vec3()*pull_float());
                    break;
                    case OPMulVec4Vec4:
                    push_vec4(pull_vec4()*pull_vec4());
                    break;
                    case OPMulVec4Float:
                    push_vec4(pull_vec4()*pull_float());
                    break;
                    case OPMulMat2Mat2:
                    push_mat2(pull_mat2()*pull_mat2());
                    break;
                    case OPMulMat2Float:
                    push_mat2(pull_mat2()*pull_float());
                    break;
                    case OPMulMat3Mat3:
                    push_mat3(pull_mat3()*pull_mat3());
                    break;
                    case OPMulMat3Float:
                    push_mat3(pull_mat3()*pull_float());
                    break;
                    case OPMulMat4Mat4:
                    push_mat4(pull_mat4()*pull_mat4());
                    break;
                    case OPMulMat4Float:
                    push_mat4(pull_mat4()*pull_float());
                    break;
                    
                    case OPSubFloatFloat:
                    push_float(pull_float()-pull_float());
                    break;
                    case OPSubVec2Vec2:
                    push_vec2(pull_vec2()-pull_vec2());
                    break;
                    case OPSubVec2Float:
                    push_vec2(pull_vec2()-pull_float());
                    break;
                    case OPSubVec3Vec3:
                    push_vec3(pull_vec3()-pull_vec3());
                    break;
                    case OPSubVec3Float:
                    push_vec3(pull_vec3()-pull_float());
                    break;
                    case OPSubVec4Vec4:
                    push_vec4(pull_vec4()-pull_vec4());
                    break;
                    case OPSubVec4Float:
                    push_vec4(pull_vec4()-pull_float());
                    break;
                    case OPSubMat2Mat2:
                    push_mat2(pull_mat2()-pull_mat2());
                    break;
                    case OPSubMat2Float:
                    push_mat2(pull_mat2()-pull_float());
                    break;
                    case OPSubMat3Mat3:
                    push_mat3(pull_mat3()-pull_mat3());
                    break;
                    case OPSubMat3Float:
                    push_mat3(pull_mat3()-pull_float());
                    break;
                    case OPSubMat4Mat4:
                    push_mat4(pull_mat4()-pull_mat4());
                    break;
                    case OPSubMat4Float:
                    push_mat4(pull_mat4()-pull_float());
                    break;
                    
                    case OPDivFloatFloat:
                    push_float(pull_float()/pull_float());
                    break;
                    case OPDivVec2Vec2:
                    push_vec2(pull_vec2()/pull_vec2());
                    break;
                    case OPDivVec2Float:
                    push_vec2(pull_vec2()/pull_float());
                    break;
                    case OPDivVec3Vec3:
                    push_vec3(pull_vec3()/pull_vec3());
                    break;
                    case OPDivVec3Float:
                    push_vec3(pull_vec3()/pull_float());
                    break;
                    case OPDivVec4Vec4:
                    push_vec4(pull_vec4()/pull_vec4());
                    break;
                    case OPDivVec4Float:
                    push_vec4(pull_vec4()/pull_float());
                    break;
                    case OPDivMat2Mat2:
                    push_mat2(pull_mat2()/pull_mat2());
                    break;
                    case OPDivMat2Float:
                    push_mat2(pull_mat2()/pull_float());
                    break;
                    case OPDivMat3Mat3:
                    push_mat3(pull_mat3()/pull_mat3());
                    break;
                    case OPDivMat3Float:
                    push_mat3(pull_mat3()/pull_float());
                    break;
                    case OPDivMat4Mat4:
                    push_mat4(pull_mat4()/pull_mat4());
                    break;
                    case OPDivMat4Float:
                    push_mat4(pull_mat4()/pull_float());
                    break;
                    
                    case OPModFloatFloat:
                    push_float(mod(pull_float(),pull_float()));
                    break;
                    case OPModVec2Vec2:
                    push_vec2(mod(pull_vec2(),pull_vec2()));
                    break;
                    case OPModVec3Vec3:
                    push_vec3(mod(pull_vec3(),pull_vec3()));
                    break;
                    case OPModVec4Vec4:
                    push_vec4(mod(pull_vec4(),pull_vec4()));
                    break;
                    case OPModVec2Float:
                    push_vec2(mod(pull_vec2(),pull_float()));
                    break;
                    case OPModVec3Float:
                    push_vec3(mod(pull_vec3(),pull_float()));
                    break;
                    case OPModVec4Float:
                    push_vec4(mod(pull_vec4(),pull_float()));
                    break;
                    
                    case OPPowFloatFloat:
                    push_float(pow(pull_float(),pull_float()));
                    break;
                    case OPPowVec2Vec2:
                    push_vec2(pow(pull_vec2(),pull_vec2()));
                    break;
                    case OPPowVec3Vec3:
                    push_vec3(pow(pull_vec3(),pull_vec3()));
                    break;
                    case OPPowVec4Vec4:
                    push_vec4(pow(pull_vec4(),pull_vec4()));
                    break;
                    
                    case OPCrossVec3:
                    push_vec3(cross(pull_vec3(),pull_vec3()));
                    break;
                    case OPDotVec2:
                    push_float(dot(pull_vec2(),pull_vec2()));
                    break;
                    case OPDotVec3:
                    push_float(dot(pull_vec3(),pull_vec3()));
                    break;
                    case OPDotVec4:
                    push_float(dot(pull_vec4(),pull_vec4()));
                    break;
                    case OPDistanceVec2:
                    push_float(distance(pull_vec2(),pull_vec2()));
                    break;
                    case OPDistanceVec3:
                    push_float(distance(pull_vec3(),pull_vec3()));
                    break;
                    case OPDistanceVec4:
                    push_float(distance(pull_vec4(),pull_vec4()));
                    break;
                    case OPLengthVec2:
                    push_float(length(pull_vec2()));
                    break;
                    case OPLengthVec3:
                    push_float(length(pull_vec3()));
                    break;
                    case OPLengthVec4:
                    push_float(length(pull_vec4()));
                    break;
                    case OPNormalizeVec2:
                    push_vec2(normalize(pull_vec2()));
                    break;
                    case OPNormalizeVec3:
                    push_vec3(normalize(pull_vec3()));
                    break;
                    case OPNormalizeVec4:
                    push_vec4(normalize(pull_vec4()));
                    break;
                    case OPTransposeMat2:
                    push_mat2(transpose(pull_mat2()));
                    break;
                    case OPTransposeMat3:
                    push_mat3(transpose(pull_mat3()));
                    break;
                    case OPTransposeMat4:
                    push_mat4(transpose(pull_mat4()));
                    break;
                    case OPInvertMat2:
                    push_mat2(inverse(pull_mat2()));
                    break;
                    case OPInvertMat3:
                    push_mat3(inverse(pull_mat3()));
                    break;
                    case OPInvertMat4:
                    push_mat4(inverse(pull_mat4()));
                    break;
                    case OPDeterminantMat2:
                    push_float(determinant(pull_mat2()));
                    break;
                    case OPDeterminantMat3:
                    push_float(determinant(pull_mat3()));
                    break;
                    case OPDeterminantMat4:
                    push_float(determinant(pull_mat4()));
                    break;
                    
                    case OPAbsFloat:
                    push_float(abs(pull_float()));
                    break;
                    case OPSignFloat:
                    push_float(sign(pull_float()));
                    break;
                    case OPFloorFloat:
                    push_float(floor(pull_float()));
                    break;
                    case OPCeilFloat:
                    push_float(ceil(pull_float()));
                    break;
                    case OPFractFloat:
                    push_float(fract(pull_float()));
                    break;
                    case OPSqrtFloat:
                    push_float(sqrt(pull_float()));
                    break;
                    case OPInverseSqrtFloat:
                    push_float(inversesqrt(pull_float()));
                    break;
                    case OPExpFloat:
                    push_float(exp(pull_float()));
                    break;
                    case OPExp2Float:
                    push_float(exp2(pull_float()));
                    break;
                    case OPLogFloat:
                    push_float(log(pull_float()));
                    break;
                    case OPLog2Float:
                    push_float(log2(pull_float()));
                    break;
                    case OPSinFloat:
                    push_float(sin(pull_float()));
                    break;
                    case OPCosFloat:
                    push_float(cos(pull_float()));
                    break;
                    case OPTanFloat:
                    push_float(tan(pull_float()));
                    break;
                    case OPAsinFloat:
                    push_float(asin(pull_float()));
                    break;
                    case OPAcosFloat:
                    push_float(acos(pull_float()));
                    break;
                    case OPAtanFloat:
                    push_float(atan(pull_float()));
                    break;
                    case OPAsinhFloat:
                    push_float(asinh(pull_float()));
                    break;
                    case OPAcoshFloat:
                    push_float(acosh(pull_float()));
                    break;
                    case OPAtanhFloat:
                    push_float(atanh(pull_float()));
                    break;
                    case OPSinhFloat:
                    push_float(sinh(pull_float()));
                    break;
                    case OPCoshFloat:
                    push_float(cosh(pull_float()));
                    break;
                    case OPTanhFloat:
                    push_float(tanh(pull_float()));
                    break;
                    case OPRoundFloat:
                    push_float(round(pull_float()));
                    break;
                    case OPTruncFloat:
                    push_float(trunc(pull_float()));
                    break;
                    case OPSwap2Float:
                    floattemp=float_stack[float_stack_head-1];
                    float_stack[float_stack_head-1]=float_stack[float_stack_head-2];
                    float_stack[float_stack_head-2]=floattemp;
                    break;
                    case OPSwap3Float:
                    floattemp=float_stack[float_stack_head-1];
                    float_stack[float_stack_head-1]=float_stack[float_stack_head-3];
                    float_stack[float_stack_head-3]=floattemp;
                    break;
                    case OPSwap4Float:
                    floattemp=float_stack[float_stack_head-1];
                    float_stack[float_stack_head-1]=float_stack[float_stack_head-4];
                    float_stack[float_stack_head-4]=floattemp;
                    break;
                    case OPDupFloat:
                    push_float(float_stack[float_stack_head-1]);
                    break;
                    case OPDup2Float:
                    push_float(float_stack[float_stack_head-2]);
                    break;
                    case OPDup3Float:
                    push_float(float_stack[float_stack_head-3]);
                    break;
                    case OPDup4Float:
                    push_float(float_stack[float_stack_head-4]);
                    break;
                    case OPDropFloat:
                    float_stack_head--;
                    break;
                    case OPDrop2Float:
                    float_stack[float_stack_head-2]=float_stack[float_stack_head-1];
                    float_stack_head--;
                    break;
                    case OPDrop3Float:
                    float_stack[float_stack_head-3]=float_stack[float_stack_head-2];
                    float_stack[float_stack_head-2]=float_stack[float_stack_head-1];
                    float_stack_head--;
                    break;
                    case OPDrop4Float:
                    float_stack[float_stack_head-4]=float_stack[float_stack_head-3];
                    float_stack[float_stack_head-3]=float_stack[float_stack_head-2];
                    float_stack[float_stack_head-2]=float_stack[float_stack_head-1];
                    float_stack_head--;
                    break;
                    
                    case OPAbsVec2:
                    push_vec2(abs(pull_vec2()));
                    break;
                    case OPSignVec2:
                    push_vec2(sign(pull_vec2()));
                    break;
                    case OPFloorVec2:
                    push_vec2(floor(pull_vec2()));
                    break;
                    case OPCeilVec2:
                    push_vec2(ceil(pull_vec2()));
                    break;
                    case OPFractVec2:
                    push_vec2(fract(pull_vec2()));
                    break;
                    case OPSqrtVec2:
                    push_vec2(sqrt(pull_vec2()));
                    break;
                    case OPInverseSqrtVec2:
                    push_vec2(inversesqrt(pull_vec2()));
                    break;
                    case OPExpVec2:
                    push_vec2(exp(pull_vec2()));
                    break;
                    case OPExp2Vec2:
                    push_vec2(exp2(pull_vec2()));
                    break;
                    case OPLogVec2:
                    push_vec2(log(pull_vec2()));
                    break;
                    case OPLog2Vec2:
                    push_vec2(log2(pull_vec2()));
                    break;
                    case OPSinVec2:
                    push_vec2(sin(pull_vec2()));
                    break;
                    case OPCosVec2:
                    push_vec2(cos(pull_vec2()));
                    break;
                    case OPTanVec2:
                    push_vec2(tan(pull_vec2()));
                    break;
                    case OPAsinVec2:
                    push_vec2(asin(pull_vec2()));
                    break;
                    case OPAcosVec2:
                    push_vec2(acos(pull_vec2()));
                    break;
                    case OPAtanVec2:
                    push_vec2(atan(pull_vec2()));
                    break;
                    case OPAsinhVec2:
                    push_vec2(asinh(pull_vec2()));
                    break;
                    case OPAcoshVec2:
                    push_vec2(acosh(pull_vec2()));
                    break;
                    case OPAtanhVec2:
                    push_vec2(atanh(pull_vec2()));
                    break;
                    case OPSinhVec2:
                    push_vec2(sinh(pull_vec2()));
                    break;
                    case OPCoshVec2:
                    push_vec2(cosh(pull_vec2()));
                    break;
                    case OPTanhVec2:
                    push_vec2(tanh(pull_vec2()));
                    break;
                    case OPRoundVec2:
                    push_vec2(round(pull_vec2()));
                    break;
                    case OPTruncVec2:
                    push_vec2(trunc(pull_vec2()));
                    break;
                    case OPSwap2Vec2:
                    vec2temp=vec2_stack[vec2_stack_head-1];
                    vec2_stack[vec2_stack_head-1]=vec2_stack[vec2_stack_head-2];
                    vec2_stack[vec2_stack_head-2]=vec2temp;
                    break;
                    case OPSwap3Vec2:
                    vec2temp=vec2_stack[vec2_stack_head-1];
                    vec2_stack[vec2_stack_head-1]=vec2_stack[vec2_stack_head-3];
                    vec2_stack[vec2_stack_head-3]=vec2temp;
                    break;
                    case OPSwap4Vec2:
                    vec2temp=vec2_stack[vec2_stack_head-1];
                    vec2_stack[vec2_stack_head-1]=vec2_stack[vec2_stack_head-4];
                    vec2_stack[vec2_stack_head-4]=vec2temp;
                    break;
                    case OPDupVec2:
                    push_vec2(vec2_stack[vec2_stack_head-1]);
                    break;
                    case OPDup2Vec2:
                    push_vec2(vec2_stack[vec2_stack_head-2]);
                    break;
                    case OPDup3Vec2:
                    push_vec2(vec2_stack[vec2_stack_head-3]);
                    break;
                    case OPDup4Vec2:
                    push_vec2(vec2_stack[vec2_stack_head-4]);
                    break;
                    case OPDropVec2:
                    vec2_stack_head--;
                    break;
                    case OPDrop2Vec2:
                    vec2_stack[vec2_stack_head-2]=vec2_stack[vec2_stack_head-1];
                    vec2_stack_head--;
                    break;
                    case OPDrop3Vec2:
                    vec2_stack[vec2_stack_head-3]=vec2_stack[vec2_stack_head-2];
                    vec2_stack[vec2_stack_head-2]=vec2_stack[vec2_stack_head-1];
                    vec2_stack_head--;
                    break;
                    case OPDrop4Vec2:
                    vec2_stack[vec2_stack_head-4]=vec2_stack[vec2_stack_head-3];
                    vec2_stack[vec2_stack_head-3]=vec2_stack[vec2_stack_head-2];
                    vec2_stack[vec2_stack_head-2]=vec2_stack[vec2_stack_head-1];
                    vec2_stack_head--;
                    break;
                    
                    case OPAbsVec3:
                    push_vec3(abs(pull_vec3()));
                    break;
                    case OPSignVec3:
                    push_vec3(sign(pull_vec3()));
                    break;
                    case OPFloorVec3:
                    push_vec3(floor(pull_vec3()));
                    break;
                    case OPCeilVec3:
                    push_vec3(ceil(pull_vec3()));
                    break;
                    case OPFractVec3:
                    push_vec3(fract(pull_vec3()));
                    break;
                    case OPSqrtVec3:
                    push_vec3(sqrt(pull_vec3()));
                    break;
                    case OPInverseSqrtVec3:
                    push_vec3(inversesqrt(pull_vec3()));
                    break;
                    case OPExpVec3:
                    push_vec3(exp(pull_vec3()));
                    break;
                    case OPExp2Vec3:
                    push_vec3(exp2(pull_vec3()));
                    break;
                    case OPLogVec3:
                    push_vec3(log(pull_vec3()));
                    break;
                    case OPLog2Vec3:
                    push_vec3(log2(pull_vec3()));
                    break;
                    case OPSinVec3:
                    push_vec3(sin(pull_vec3()));
                    break;
                    case OPCosVec3:
                    push_vec3(cos(pull_vec3()));
                    break;
                    case OPTanVec3:
                    push_vec3(tan(pull_vec3()));
                    break;
                    case OPAsinVec3:
                    push_vec3(asin(pull_vec3()));
                    break;
                    case OPAcosVec3:
                    push_vec3(acos(pull_vec3()));
                    break;
                    case OPAtanVec3:
                    push_vec3(atan(pull_vec3()));
                    break;
                    case OPAsinhVec3:
                    push_vec3(asinh(pull_vec3()));
                    break;
                    case OPAcoshVec3:
                    push_vec3(acosh(pull_vec3()));
                    break;
                    case OPAtanhVec3:
                    push_vec3(atanh(pull_vec3()));
                    break;
                    case OPSinhVec3:
                    push_vec3(sinh(pull_vec3()));
                    break;
                    case OPCoshVec3:
                    push_vec3(cosh(pull_vec3()));
                    break;
                    case OPTanhVec3:
                    push_vec3(tanh(pull_vec3()));
                    break;
                    case OPRoundVec3:
                    push_vec3(round(pull_vec3()));
                    break;
                    case OPTruncVec3:
                    push_vec3(trunc(pull_vec3()));
                    break;
                    case OPSwap2Vec3:
                    vec3temp=vec3_stack[vec3_stack_head-1];
                    vec3_stack[vec3_stack_head-1]=vec3_stack[vec3_stack_head-2];
                    vec3_stack[vec3_stack_head-2]=vec3temp;
                    break;
                    case OPSwap3Vec3:
                    vec3temp=vec3_stack[vec3_stack_head-1];
                    vec3_stack[vec3_stack_head-1]=vec3_stack[vec3_stack_head-3];
                    vec3_stack[vec3_stack_head-3]=vec3temp;
                    break;
                    case OPSwap4Vec3:
                    vec3temp=vec3_stack[vec3_stack_head-1];
                    vec3_stack[vec3_stack_head-1]=vec3_stack[vec3_stack_head-4];
                    vec3_stack[vec3_stack_head-4]=vec3temp;
                    break;
                    case OPDupVec3:
                    push_vec3(vec3_stack[vec3_stack_head-1]);
                    break;
                    case OPDup2Vec3:
                    push_vec3(vec3_stack[vec3_stack_head-2]);
                    break;
                    case OPDup3Vec3:
                    push_vec3(vec3_stack[vec3_stack_head-3]);
                    break;
                    case OPDup4Vec3:
                    push_vec3(vec3_stack[vec3_stack_head-4]);
                    break;
                    case OPDropVec3:
                    vec3_stack_head--;
                    break;
                    case OPDrop2Vec3:
                    vec3_stack[vec3_stack_head-2]=vec3_stack[vec3_stack_head-1];
                    vec3_stack_head--;
                    break;
                    case OPDrop3Vec3:
                    vec3_stack[vec3_stack_head-3]=vec3_stack[vec3_stack_head-2];
                    vec3_stack[vec3_stack_head-2]=vec3_stack[vec3_stack_head-1];
                    vec3_stack_head--;
                    break;
                    case OPDrop4Vec3:
                    vec3_stack[vec3_stack_head-4]=vec3_stack[vec3_stack_head-3];
                    vec3_stack[vec3_stack_head-3]=vec3_stack[vec3_stack_head-2];
                    vec3_stack[vec3_stack_head-2]=vec3_stack[vec3_stack_head-1];
                    vec3_stack_head--;
                    break;
                    
                    case OPAbsVec4:
                    push_vec4(abs(pull_vec4()));
                    break;
                    case OPSignVec4:
                    push_vec4(sign(pull_vec4()));
                    break;
                    case OPFloorVec4:
                    push_vec4(floor(pull_vec4()));
                    break;
                    case OPCeilVec4:
                    push_vec4(ceil(pull_vec4()));
                    break;
                    case OPFractVec4:
                    push_vec4(fract(pull_vec4()));
                    break;
                    case OPSqrtVec4:
                    push_vec4(sqrt(pull_vec4()));
                    break;
                    case OPInverseSqrtVec4:
                    push_vec4(inversesqrt(pull_vec4()));
                    break;
                    case OPExpVec4:
                    push_vec4(exp(pull_vec4()));
                    break;
                    case OPExp2Vec4:
                    push_vec4(exp2(pull_vec4()));
                    break;
                    case OPLogVec4:
                    push_vec4(log(pull_vec4()));
                    break;
                    case OPLog2Vec4:
                    push_vec4(log2(pull_vec4()));
                    break;
                    case OPSinVec4:
                    push_vec4(sin(pull_vec4()));
                    break;
                    case OPCosVec4:
                    push_vec4(cos(pull_vec4()));
                    break;
                    case OPTanVec4:
                    push_vec4(tan(pull_vec4()));
                    break;
                    case OPAsinVec4:
                    push_vec4(asin(pull_vec4()));
                    break;
                    case OPAcosVec4:
                    push_vec4(acos(pull_vec4()));
                    break;
                    case OPAtanVec4:
                    push_vec4(atan(pull_vec4()));
                    break;
                    case OPAsinhVec4:
                    push_vec4(asinh(pull_vec4()));
                    break;
                    case OPAcoshVec4:
                    push_vec4(acosh(pull_vec4()));
                    break;
                    case OPAtanhVec4:
                    push_vec4(atanh(pull_vec4()));
                    break;
                    case OPSinhVec4:
                    push_vec4(sinh(pull_vec4()));
                    break;
                    case OPCoshVec4:
                    push_vec4(cosh(pull_vec4()));
                    break;
                    case OPTanhVec4:
                    push_vec4(tanh(pull_vec4()));
                    break;
                    case OPRoundVec4:
                    push_vec4(round(pull_vec4()));
                    break;
                    case OPTruncVec4:
                    push_vec4(trunc(pull_vec4()));
                    break;
                    case OPSwap2Vec4:
                    vec4temp=vec4_stack[vec4_stack_head-1];
                    vec4_stack[vec4_stack_head-1]=vec4_stack[vec4_stack_head-2];
                    vec4_stack[vec4_stack_head-2]=vec4temp;
                    break;
                    case OPSwap3Vec4:
                    vec4temp=vec4_stack[vec4_stack_head-1];
                    vec4_stack[vec4_stack_head-1]=vec4_stack[vec4_stack_head-3];
                    vec4_stack[vec4_stack_head-3]=vec4temp;
                    break;
                    case OPSwap4Vec4:
                    vec4temp=vec4_stack[vec4_stack_head-1];
                    vec4_stack[vec4_stack_head-1]=vec4_stack[vec4_stack_head-4];
                    vec4_stack[vec4_stack_head-4]=vec4temp;
                    break;
                    case OPDupVec4:
                    push_vec4(vec4_stack[vec4_stack_head-1]);
                    break;
                    case OPDup2Vec4:
                    push_vec4(vec4_stack[vec4_stack_head-2]);
                    break;
                    case OPDup3Vec4:
                    push_vec4(vec4_stack[vec4_stack_head-3]);
                    break;
                    case OPDup4Vec4:
                    push_vec4(vec4_stack[vec4_stack_head-4]);
                    break;
                    case OPDropVec4:
                    vec4_stack_head--;
                    break;
                    case OPDrop2Vec4:
                    vec4_stack[vec4_stack_head-2]=vec4_stack[vec4_stack_head-1];
                    vec4_stack_head--;
                    break;
                    case OPDrop3Vec4:
                    vec4_stack[vec4_stack_head-3]=vec4_stack[vec4_stack_head-2];
                    vec4_stack[vec4_stack_head-2]=vec4_stack[vec4_stack_head-1];
                    vec4_stack_head--;
                    break;
                    case OPDrop4Vec4:
                    vec4_stack[vec4_stack_head-4]=vec4_stack[vec4_stack_head-3];
                    vec4_stack[vec4_stack_head-3]=vec4_stack[vec4_stack_head-2];
                    vec4_stack[vec4_stack_head-2]=vec4_stack[vec4_stack_head-1];
                    vec4_stack_head--;
                    break;
                    
                    case OPSwap2Mat2:
                    mat2temp=mat2_stack[mat2_stack_head-1];
                    mat2_stack[mat2_stack_head-1]=mat2_stack[mat2_stack_head-2];
                    mat2_stack[mat2_stack_head-2]=mat2temp;
                    break;
                    case OPSwap3Mat2:
                    mat2temp=mat2_stack[mat2_stack_head-1];
                    mat2_stack[mat2_stack_head-1]=mat2_stack[mat2_stack_head-3];
                    mat2_stack[mat2_stack_head-3]=mat2temp;
                    break;
                    case OPSwap4Mat2:
                    mat2temp=mat2_stack[mat2_stack_head-1];
                    mat2_stack[mat2_stack_head-1]=mat2_stack[mat2_stack_head-4];
                    mat2_stack[mat2_stack_head-4]=mat2temp;
                    break;
                    case OPDupMat2:
                    push_mat2(mat2_stack[mat2_stack_head-1]);
                    break;
                    case OPDup2Mat2:
                    push_mat2(mat2_stack[mat2_stack_head-2]);
                    break;
                    case OPDup3Mat2:
                    push_mat2(mat2_stack[mat2_stack_head-3]);
                    break;
                    case OPDup4Mat2:
                    push_mat2(mat2_stack[mat2_stack_head-4]);
                    break;
                    case OPDropMat2:
                    mat2_stack_head--;
                    break;
                    case OPDrop2Mat2:
                    mat2_stack[mat2_stack_head-2]=mat2_stack[mat2_stack_head-1];
                    mat2_stack_head--;
                    break;
                    case OPDrop3Mat2:
                    mat2_stack[mat2_stack_head-3]=mat2_stack[mat2_stack_head-2];
                    mat2_stack[mat2_stack_head-2]=mat2_stack[mat2_stack_head-1];
                    mat2_stack_head--;
                    break;
                    case OPDrop4Mat2:
                    mat2_stack[mat2_stack_head-4]=mat2_stack[mat2_stack_head-3];
                    mat2_stack[mat2_stack_head-3]=mat2_stack[mat2_stack_head-2];
                    mat2_stack[mat2_stack_head-2]=mat2_stack[mat2_stack_head-1];
                    mat2_stack_head--;
                    break;
                    
                    case OPSwap2Mat3:
                    mat3temp=mat3_stack[mat3_stack_head-1];
                    mat3_stack[mat3_stack_head-1]=mat3_stack[mat3_stack_head-2];
                    mat3_stack[mat3_stack_head-2]=mat3temp;
                    break;
                    case OPSwap3Mat3:
                    mat3temp=mat3_stack[mat3_stack_head-1];
                    mat3_stack[mat3_stack_head-1]=mat3_stack[mat3_stack_head-3];
                    mat3_stack[mat3_stack_head-3]=mat3temp;
                    break;
                    case OPSwap4Mat3:
                    mat3temp=mat3_stack[mat3_stack_head-1];
                    mat3_stack[mat3_stack_head-1]=mat3_stack[mat3_stack_head-4];
                    mat3_stack[mat3_stack_head-4]=mat3temp;
                    break;
                    case OPDupMat3:
                    push_mat3(mat3_stack[mat3_stack_head-1]);
                    break;
                    case OPDup2Mat3:
                    push_mat3(mat3_stack[mat3_stack_head-2]);
                    break;
                    case OPDup3Mat3:
                    push_mat3(mat3_stack[mat3_stack_head-3]);
                    break;
                    case OPDup4Mat3:
                    push_mat3(mat3_stack[mat3_stack_head-4]);
                    break;
                    case OPDropMat3:
                    mat3_stack_head--;
                    break;
                    case OPDrop2Mat3:
                    mat3_stack[mat3_stack_head-2]=mat3_stack[mat3_stack_head-1];
                    mat3_stack_head--;
                    break;
                    case OPDrop3Mat3:
                    mat3_stack[mat3_stack_head-3]=mat3_stack[mat3_stack_head-2];
                    mat3_stack[mat3_stack_head-2]=mat3_stack[mat3_stack_head-1];
                    mat3_stack_head--;
                    break;
                    case OPDrop4Mat3:
                    mat3_stack[mat3_stack_head-4]=mat3_stack[mat3_stack_head-3];
                    mat3_stack[mat3_stack_head-3]=mat3_stack[mat3_stack_head-2];
                    mat3_stack[mat3_stack_head-2]=mat3_stack[mat3_stack_head-1];
                    mat3_stack_head--;
                    break;
                    
                    case OPSwap2Mat4:
                    mat4temp=mat4_stack[mat4_stack_head-1];
                    mat4_stack[mat4_stack_head-1]=mat4_stack[mat4_stack_head-2];
                    mat4_stack[mat4_stack_head-2]=mat4temp;
                    break;
                    case OPSwap3Mat4:
                    mat4temp=mat4_stack[mat4_stack_head-1];
                    mat4_stack[mat4_stack_head-1]=mat4_stack[mat4_stack_head-3];
                    mat4_stack[mat4_stack_head-3]=mat4temp;
                    break;
                    case OPSwap4Mat4:
                    mat4temp=mat4_stack[mat4_stack_head-1];
                    mat4_stack[mat4_stack_head-1]=mat4_stack[mat4_stack_head-4];
                    mat4_stack[mat4_stack_head-4]=mat4temp;
                    break;
                    case OPDupMat4:
                    push_mat4(mat4_stack[mat4_stack_head-1]);
                    break;
                    case OPDup2Mat4:
                    push_mat4(mat4_stack[mat4_stack_head-2]);
                    break;
                    case OPDup3Mat4:
                    push_mat4(mat4_stack[mat4_stack_head-3]);
                    break;
                    case OPDup4Mat4:
                    push_mat4(mat4_stack[mat4_stack_head-4]);
                    break;
                    case OPDropMat4:
                    mat4_stack_head--;
                    break;
                    case OPDrop2Mat4:
                    mat4_stack[mat4_stack_head-2]=mat4_stack[mat4_stack_head-1];
                    mat4_stack_head--;
                    break;
                    case OPDrop3Mat4:
                    mat4_stack[mat4_stack_head-3]=mat4_stack[mat4_stack_head-2];
                    mat4_stack[mat4_stack_head-2]=mat4_stack[mat4_stack_head-1];
                    mat4_stack_head--;
                    break;
                    case OPDrop4Mat4:
                    mat4_stack[mat4_stack_head-4]=mat4_stack[mat4_stack_head-3];
                    mat4_stack[mat4_stack_head-3]=mat4_stack[mat4_stack_head-2];
                    mat4_stack[mat4_stack_head-2]=mat4_stack[mat4_stack_head-1];
                    mat4_stack_head--;
                    break;
                    
                    case OPMinFloat:
                    push_float(min(pull_float(),pull_float()));
                    break;
                    case OPMaxFloat:
                    push_float(max(pull_float(),pull_float()));
                    break;
                    case OPSmoothMinFloat:{
                        float k=pull_float();
                        float a=pull_float();
                        float b=pull_float();
                        float h=max(k-abs(a-b),0.)/k;
                        push_float(min(a,b)-h*h*k*(1./4.));
                    }
                    break;
                    case OPSmoothMinMaterialFloat:{
                        float k=pull_float();
                        float a=pull_float();
                        float b=pull_float();
                        float h=max(k-abs(a-b),0.)/k;
                        float m=h*h*.5;
                        float s=m*k*(1./2.);
                        push_float(min(a,b)-s);
                        if(material){
                            m=(a<b)?m:1.-m;
                            push_material((pull_material()*m)+(pull_material()*(1-m)));
                        }
                    }
                    break;
                    case OPSmoothMaxFloat:{
                        float k=pull_float();
                        float a=pull_float();
                        float b=pull_float();
                        float h=max(k-abs(a-b),0.)/k;
                        push_float(max(a,b)+h*h*k*(1./4.));
                    }
                    break;
                    case OPSmoothMaxMaterialFloat:{
                        float k=pull_float();
                        float a=pull_float();
                        float b=pull_float();
                        float h=max(k-abs(a-b),0.)/k;
                        float m=h*h*.5;
                        float s=m*k*(1./2.);
                        push_float(max(a,b)+s);
                        if(material){
                            m=(a>b)?m:1.-m;
                            push_material((pull_material()*m)+(pull_material()*(1-m)));
                        }
                    }
                    break;
                    
                    case OPMinMaterialFloat:
                    {
                        float a=pull_float();
                        float b=pull_float();
                        push_float(min(a,b));
                        if(material){
                            material_stack_head--;
                            if(a<b){
                                material_stack[material_stack_head-1]=material_stack[material_stack_head];
                            }
                        }
                    }
                    break;
                    case OPMaxMaterialFloat:
                    {
                        float a=pull_float();
                        float b=pull_float();
                        push_float(max(a,b));
                        if(material){
                            material_stack_head--;
                            if(a>b){
                                material_stack[material_stack_head-1]=material_stack[material_stack_head];
                            }
                        }
                    }
                    break;
                    
                    case OPPromoteFloatFloatVec2:
                    push_vec2(vec2(pull_float(),pull_float()));
                    break;
                    case OPPromoteFloatFloatFloatVec3:
                    push_vec3(vec3(pull_float(),pull_float(),pull_float()));
                    break;
                    case OPPromoteVec2FloatVec3:
                    push_vec3(vec3(pull_vec2(),pull_float()));
                    break;
                    case OPPromoteFloatFloatFloatFloatVec4:
                    push_vec4(vec4(pull_float(),pull_float(),pull_float(),pull_float()));
                    break;
                    case OPPromoteVec2FloatFloatVec4:
                    push_vec4(vec4(pull_vec2(),pull_float(),pull_float()));
                    break;
                    case OPPromoteVec3FloatVec4:
                    push_vec4(vec4(pull_vec3(),pull_float()));
                    break;
                    case OPPromoteVec2Vec2Vec4:
                    push_vec4(vec4(pull_vec2(),pull_vec2()));
                    break;
                    case OPPromote2Vec2Mat2:
                    push_mat2(mat2(pull_vec2(),pull_vec2()));
                    break;
                    case OPPromote4FloatMat2:
                    push_mat2(mat2(pull_float(),pull_float(),pull_float(),pull_float()));
                    break;
                    case OPPromoteVec4Mat2:
                    push_mat2(mat2(pull_vec4()));
                    break;
                    case OPPromote3Vec3Mat3:
                    push_mat3(mat3(pull_vec3(),pull_vec3(),pull_vec3()));
                    break;
                    case OPPromote4Vec4Mat4:
                    push_mat4(mat4(pull_vec4(),pull_vec4(),pull_vec4(),pull_vec4()));
                    break;
                    case OPPromoteMat2Mat3:
                    push_mat3(mat3(pull_mat2()));
                    break;
                    case OPPromoteMat2Mat4:
                    push_mat4(mat4(pull_mat2()));
                    break;
                    case OPPromoteMat3Mat4:
                    push_mat4(mat4(pull_mat3()));
                    break;
                    
                    case OPDemoteMat2Float:
                    mat2temp=pull_mat2();
                    push_float(mat2temp[1].y);
                    push_float(mat2temp[1].x);
                    push_float(mat2temp[0].y);
                    push_float(mat2temp[0].x);
                    break;
                    case OPDemoteMat2Vec2:
                    mat2temp=pull_mat2();
                    push_vec2(mat2temp[1]);
                    push_vec2(mat2temp[0]);
                    break;
                    case OPDemoteMat3Vec3:
                    mat3temp=pull_mat3();
                    push_vec3(mat3temp[2]);
                    push_vec3(mat3temp[1]);
                    push_vec3(mat3temp[0]);
                    break;
                    case OPDemoteMat4Vec4:
                    mat4temp=pull_mat4();
                    push_vec4(mat4temp[3]);
                    push_vec4(mat4temp[2]);
                    push_vec4(mat4temp[1]);
                    push_vec4(mat4temp[0]);
                    break;
                    case OPDemoteMat2Vec4:
                    mat2temp=pull_mat2();
                    push_vec4(vec4(mat2temp[0],mat2temp[1]));
                    break;
                    case OPDemoteVec2FloatFloat:
                    vec2temp=pull_vec2();
                    push_float(vec2temp.y);
                    push_float(vec2temp.x);
                    break;
                    case OPDemoteVec3FloatFloatFloat:
                    vec3temp=pull_vec3();
                    push_float(vec3temp.z);
                    push_float(vec3temp.y);
                    push_float(vec3temp.x);
                    break;
                    case OPDemoteVec4FloatFloatFloatFloat:
                    vec4temp=pull_vec4();
                    push_float(vec4temp.w);
                    push_float(vec4temp.z);
                    push_float(vec4temp.y);
                    push_float(vec4temp.x);
                    break;
                    
                    case OPMinVec2:
                    push_vec2(min(pull_vec2(),pull_vec2()));
                    break;
                    case OPMaxVec2:
                    push_vec2(max(pull_vec2(),pull_vec2()));
                    break;
                    case OPMinVec3:
                    push_vec3(min(pull_vec3(),pull_vec3()));
                    break;
                    case OPMaxVec3:
                    push_vec3(max(pull_vec3(),pull_vec3()));
                    break;
                    case OPMinVec4:
                    push_vec4(min(pull_vec4(),pull_vec4()));
                    break;
                    case OPMaxVec4:
                    push_vec4(max(pull_vec4(),pull_vec4()));
                    break;
                    
                    case OPFMAFloat:
                    push_float(fma(pull_float(),pull_float(),pull_float()));
                    break;
                    case OPFMAVec2:
                    push_vec2(fma(pull_vec2(),pull_vec2(),pull_vec2()));
                    break;
                    case OPFMAVec3:
                    push_vec3(fma(pull_vec3(),pull_vec3(),pull_vec3()));
                    break;
                    case OPFMAVec4:
                    push_vec4(fma(pull_vec4(),pull_vec4(),pull_vec4()));
                    break;
                    
                    case OPOuterProductMat2:
                    push_mat2(outerProduct(pull_vec2(),pull_vec2()));
                    break;
                    case OPOuterProductMat3:
                    push_mat3(outerProduct(pull_vec3(),pull_vec3()));
                    break;
                    case OPOuterProductMat4:
                    push_mat4(outerProduct(pull_vec4(),pull_vec4()));
                    break;
                    
                    case OPCompMultMat2:
                    push_mat2(matrixCompMult(pull_mat2(),pull_mat2()));
                    break;
                    case OPCompMultMat3:
                    push_mat3(matrixCompMult(pull_mat3(),pull_mat3()));
                    break;
                    case OPCompMultMat4:
                    push_mat4(matrixCompMult(pull_mat4(),pull_mat4()));
                    break;
                    
                    case OPClampFloatFloat:
                    push_float(clamp(pull_float(),pull_float(),pull_float()));
                    break;
                    case OPClampVec2Vec2:
                    push_vec2(clamp(pull_vec2(),pull_vec2(),pull_vec2()));
                    break;
                    case OPClampVec3Vec3:
                    push_vec3(clamp(pull_vec3(),pull_vec3(),pull_vec3()));
                    break;
                    case OPClampVec4Vec4:
                    push_vec4(clamp(pull_vec4(),pull_vec4(),pull_vec4()));
                    break;
                    case OPClampVec2Float:
                    push_vec2(clamp(pull_vec2(),pull_float(),pull_float()));
                    break;
                    case OPClampVec3Float:
                    push_vec3(clamp(pull_vec3(),pull_float(),pull_float()));
                    break;
                    case OPClampVec4Float:
                    push_vec4(clamp(pull_vec4(),pull_float(),pull_float()));
                    break;
                    
                    case OPMixFloatFloat:
                    push_float(mix(pull_float(),pull_float(),pull_float()));
                    break;
                    case OPMixVec2Vec2:
                    push_vec2(mix(pull_vec2(),pull_vec2(),pull_vec2()));
                    break;
                    case OPMixVec3Vec3:
                    push_vec3(mix(pull_vec3(),pull_vec3(),pull_vec3()));
                    break;
                    case OPMixVec4Vec4:
                    push_vec4(mix(pull_vec4(),pull_vec4(),pull_vec4()));
                    break;
                    case OPMixVec2Float:
                    push_vec2(mix(pull_vec2(),pull_vec2(),pull_float()));
                    break;
                    case OPMixVec3Float:
                    push_vec3(mix(pull_vec3(),pull_vec3(),pull_float()));
                    break;
                    case OPMixVec4Float:
                    push_vec4(mix(pull_vec4(),pull_vec4(),pull_float()));
                    break;
                    
                    case OPSquareFloat:
                    floattemp=pull_float();
                    push_float(floattemp*floattemp);
                    break;
                    case OPCubeFloat:
                    floattemp=pull_float();
                    push_float(floattemp*floattemp*floattemp);
                    break;
                    case OPSquareVec2:
                    vec2temp=pull_vec2();
                    push_vec2(vec2temp*vec2temp);
                    break;
                    case OPCubeVec2:
                    vec2temp=pull_vec2();
                    push_vec2(vec2temp*vec2temp*vec2temp);
                    break;
                    case OPSquareVec3:
                    vec3temp=pull_vec3();
                    push_vec3(vec3temp*vec3temp);
                    break;
                    case OPCubeVec3:
                    vec3temp=pull_vec3();
                    push_vec3(vec3temp*vec3temp*vec3temp);
                    break;
                    case OPSquareVec4:
                    vec4temp=pull_vec4();
                    push_vec4(vec4temp*vec4temp);
                    break;
                    case OPCubeVec4:
                    vec4temp=pull_vec4();
                    push_vec4(vec4temp*vec4temp*vec4temp);
                    break;
                    case OPSquareMat2:
                    mat2temp=pull_mat2();
                    push_mat2(mat2temp*mat2temp);
                    break;
                    case OPCubeMat2:
                    mat2temp=pull_mat2();
                    push_mat2(mat2temp*mat2temp*mat2temp);
                    break;
                    case OPSquareMat3:
                    mat3temp=pull_mat3();
                    push_mat3(mat3temp*mat3temp);
                    break;
                    case OPCubeMat3:
                    mat3temp=pull_mat3();
                    push_mat3(mat3temp*mat3temp*mat3temp);
                    break;
                    case OPSquareMat4:
                    mat4temp=pull_mat4();
                    push_mat4(mat4temp*mat4temp);
                    break;
                    case OPCubeMat4:
                    mat4temp=pull_mat4();
                    push_mat4(mat4temp*mat4temp*mat4temp);
                    break;
                    
                    case OPMulMat2Vec2:
                    push_vec2(pull_mat2()*pull_vec2());
                    break;
                    case OPMulMat3Vec3:
                    push_vec3(pull_mat3()*pull_vec3());
                    break;
                    case OPMulMat4Vec4:
                    push_vec4(pull_mat4()*pull_vec4());
                    break;
                    
                    case OPSDFSphere:
                    {
                        float r=pull_float();
                        vec3 p=pull_vec3();
                        
                        push_float(length(p)-r);
                        if(material){
                            push_material(pull_mat4());
                        }
                        //return p;
                        //return vec3(0.,1.,1.);
                    }
                    break;
                    
                    case OPNop:
                    break;
                    case OPStop:
                    return pull_float();
                    case OPInvalid:
                    default:
                    return float(minor_float_cache[minor_position]);
                }
            }else{
                //return vec3(float(minor_float_cache[minor_position]));
                push_float(float(minor_float_cache[minor_position]));
            }
        }
        minor_position++;
        if(minor_position==8)
        {
            minor_position=0;
            major_position++;
            if(major_position==13)
            {
                return pull_float();
            }
        }
    }
}

#endif//ifndef interpreter