#extension GL_EXT_shader_explicit_arithmetic_types:require

#ifndef interpreter
#define interpreter 1

#include "instructionset.glsl"

struct Description{
    uint scene;
    uint floats;
    uint vec2s;
    uint vec4s;
    uint mat2s;
    uint mat3s;
    uint mat4s;
    uint mats;
    uint dependencies;
    float[6] bounds;
};
Description desc;

layout(set=0,binding=2, std430)restrict readonly buffer SceneDescription{
    Description desc[];
}scene_description;

layout(set=0,binding=3, std430)restrict readonly buffer SceneBuf{
    u32vec4 opcodes[];
}scenes;
layout(set=0,binding=4, std430)restrict readonly buffer FloatConst{
    float floats[];
}fconst;
layout(set=0,binding=5, std430)restrict readonly buffer Vec2Const{
    vec2 vec2s[];
}v2const;
layout(set=0,binding=7, std430)restrict readonly buffer Vec4Const{
    vec4 vec4s[];
}v4const;
layout(set=0,binding=8, std430)restrict readonly buffer Mat2Const{
    mat2 mat2s[];
}m2const;
layout(set=0,binding=9, std430)restrict readonly buffer Mat3Const{
    mat3 mat3s[];
}m3const;
layout(set=0,binding=10, std430)restrict readonly buffer Mat4Const{
    mat4 mat4s[];
}m4const;
layout(set=0,binding=11, std430)restrict readonly buffer MatConst{
    mat4 mats[];
}matconst;
layout(set=0,binding=12, std430)restrict readonly buffer DepInfo{
    uint8_t dependencies[][2] ;
}depinfo;

// unpack integers
#define get_caches u32vec4 major_unpack=scenes.opcodes[desc.scene+major_position];\
minor_integer_cache[0]=major_unpack.x&65535;\
minor_integer_cache[1]=major_unpack.x>>16;\
minor_integer_cache[2]=major_unpack.y&65535;\
minor_integer_cache[3]=major_unpack.y>>16;\
minor_integer_cache[4]=major_unpack.z&65535;\
minor_integer_cache[5]=major_unpack.z>>16;\
minor_integer_cache[6]=major_unpack.w&65535;\
minor_integer_cache[7]=major_unpack.w>>16;

float float_stack[8];
uint float_stack_head=0;
vec2 vec2_stack[8];
uint vec2_stack_head=0;
vec3 vec3_stack[8];
uint vec3_stack_head=0;
vec4 vec4_stack[8];
uint vec4_stack_head=0;
mat2 mat2_stack[1];
uint mat2_stack_head=0;
mat3 mat3_stack[1];
uint mat3_stack_head=0;
mat4 mat4_stack[1];
uint mat4_stack_head=0;

uint float_const_head=0;
uint vec2_const_head=0;
uint vec4_const_head=0;
uint mat2_const_head=0;
uint mat3_const_head=0;
uint mat4_const_head=0;
uint mat_const_head=0;

#define vec3_const_head vec4_const_head
#define v3const v4const
#define vec3s vec4s

void push_float(float f){
    float_stack[float_stack_head++]=f;
}

float pull_float(bool c){
    if (c) {
        return fconst.floats[desc.floats+float_const_head++];
    }
    else {
        return float_stack[--float_stack_head];
    }
}

float cpull_float(){
    return fconst.floats[desc.floats+float_const_head++];
}

void push_vec2(vec2 f){
    vec2_stack[vec2_stack_head++]=f;
}

vec2 pull_vec2(bool c){
    if (c) {
        return v2const.vec2s[desc.vec2s+vec2_const_head++];
    }
    else {
        return vec2_stack[--vec2_stack_head];
    }
}

vec2 cpull_vec2(){
    return v2const.vec2s[desc.vec2s+vec2_const_head++];
}

void push_vec3(vec3 f){
    vec3_stack[vec3_stack_head++]=f;
}

vec3 pull_vec3(bool c){
    if (c) {
        return v3const.vec3s[desc.vec3s+vec3_const_head++].xyz;
    }
    else {
        return vec3_stack[--vec3_stack_head];
    }
}

vec3 cpull_vec3(){
    return v3const.vec3s[desc.vec3s+vec3_const_head++].xyz;
}

void push_vec4(vec4 f){
    vec4_stack[vec4_stack_head++]=f;
}

vec4 pull_vec4(bool c){
    if (c) {
        return v4const.vec4s[desc.vec4s+vec4_const_head++];
    }
    else {
        return vec4_stack[--vec4_stack_head];
    }
}

vec4 cpull_vec4(){
    return v4const.vec4s[desc.vec4s+vec4_const_head++];
}

void push_mat2(mat2 f){
    mat2_stack[mat2_stack_head++]=f;
}

mat2 pull_mat2(bool c){
    if (c) {
        return m2const.mat2s[desc.mat2s+mat2_const_head++];
    }
    else {
        return mat2_stack[--mat2_stack_head];
    }
}

mat2 cpull_mat2(){
    return m2const.mat2s[desc.mat2s+mat2_const_head++];
}

void push_mat3(mat3 f){
    mat3_stack[mat3_stack_head++]=f;
}

mat3 pull_mat3(bool c){
    if (c) {
        return m3const.mat3s[desc.mat3s+mat3_const_head++];;
    }
    else {
        return mat3_stack[--mat3_stack_head];
    }
}

mat3 cpull_mat3(){
    return m3const.mat3s[desc.mat3s+mat3_const_head++];
}

void push_mat4(mat4 f){
    mat4_stack[mat4_stack_head++]=f;
}

mat4 pull_mat4(bool c){
    if (c) {
        return m4const.mat4s[desc.mat4s+mat4_const_head++];
    }
    else {
        return mat4_stack[--mat4_stack_head];
    }
}

mat4 cpull_mat4(){
    return m4const.mat4s[desc.mat4s+mat4_const_head++];
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
    float_const_head=0;
    vec2_const_head=0;
    vec3_const_head=0;
    vec4_const_head=0;
    mat2_const_head=0;
    mat3_const_head=0;
    mat4_const_head=0;
    mat_const_head=0;
}

const int masklen = 29;
uint8_t mask[masklen];

void default_mask()
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
}

//monotonic
#define multiply {\
    in1 *= in2;\
}
//monotonic
#define divide {\
    in1 /= in2;\
}
//monotonic
#define add {\
    in1 += in2;\
}
//monotonic
#define subtract {\
    in1 -= in2;\
}
#define modulo {\
    in1 = mod(in1,in2);\
}
//always monotonic for x>0
#define power {\
    in1 = pow(in1,in2);\
}
//handled
#define dist {\
    out1 = distance(in1,in2);\
}
//variable
#define dotprod {\
    out1 = dot(in1,in2);\
}
//monotonic
#define clampof {\
    in1=clamp(in1,in2,in3);\
}
//monotonic
#define mixof {\
    in1=mix(in1,in2,in3);\
}
//monotonic
#define fmaof {\
    multiply;\
    in2=in3;\
    add;\
}
//variable
#define square {\
    in1=in1*in1;\
}
//monotonic
#define cube {\
    in1=in1*in1*in1;\
}
//mess
#define len {\
    out1 = length(in1);\
}
//monotonic
#define mattranspose {\
    in1=transpose(in1);\
}
//unused
#define matdeterminant {\
    in1=determinant(in1);\
}
//unused
#define matinvert {\
    in1=inverse(in1);\
}
//handled
#define absolute {\
    in1=abs(in1);\
}
//monotonic
#define signof {\
    in1=sign(in1);\
}
//monotonic
#define floorof {\
    in1=floor(in1);\
}
//monotonic
#define ceilingof {\
    in1=ceil(in1);\
}
//handled
//If the integer component changes across the interval, then we've managed to hit 
//a discontinuity, and the max and min are constant.
//Otherwise, it's monotonic.
#define fractionalof {\
    in1=fract(in1);\
}
//monotonic
#define squarerootof {\
    in1=sqrt(in1);\
}
//monotonic
#define inversesquarerootof {\
    in1=inversesqrt(in1);\
}
//monotonic
#define exponentof {\
    in1=exp(in1);\
}
//monotonic
#define exponent2of {\
    in1=exp2(in1);\
}
//monotonic
#define logarithmof {\
    in1=log(in1);\
}
//monotonic
#define logarithm2of {\
    in1=log2(in1);\
}
#define PI 3.1415926536
//handled
#define sineof {\
    in1=sin(in1);\
}
//handled
#define cosineof {\
    in1=cos(in1);\
}
//handled
#define tangentof {\
    in1=tan(in1);\
}
//monotonic
#define arcsineof {\
    in1=asin(in1);\
}
//negatively monotonic
#define arccosineof {\
    in1=acos(in1);\
}
//monotonic
#define arctangentof {\
    in1=atan(in1);\
}
//monotonic
#define hyperbolicsineof {\
    in1=sinh(in1);\
}
//handled
#define hyperboliccosineof {\
    in1=cosh(in1);\
}
//monotonic
#define hyperbolictangentof {\
    in1=tanh(in1);\
}
//monotonic
#define hyperbolicarcsineof {\
    in1=asinh(in1);\
}
//monotonic
#define hyperbolicarccosineof {\
    in1=acosh(in1);\
}
//monotonic
#define hyperbolicarctangentof {\
    in1=atanh(in1);\
}
//obvious
#define minimum {\
    in1=min(in1,in2);\
}
//obvious
#define maximum {\
    in1=max(in1,in2);\
}
//monotonic
#define roundof {\
    in1=round(in1);\
}
//truncate
#define truncof {\
    in1=trunc(in1);\
}

#define maskdefine (mask[major_position]&(1<<minor_position))==0
#define inputmask1(m_in_1) if(maskdefine){\
    if(ifconst(0)) {m_in_1++;}\
    break;\
}
#define inputmask2(m_in_1,m_in_2) if(maskdefine){\
    if(ifconst(0)) {m_in_1++;}\
    if(ifconst(1)) {m_in_2++;}\
    break;\
}
#define inputmask3(m_in_1,m_in_2,m_in_3) if(maskdefine){\
    if(ifconst(0)) {m_in_1++;}\
    if(ifconst(1)) {m_in_2++;}\
    if(ifconst(2)) {m_in_3++;}\
    break;\
}
#define inputmask4(m_in_1,m_in_2,m_in_3,m_in_4) if(maskdefine){\
    if(ifconst(0)) {m_in_1++;}\
    if(ifconst(1)) {m_in_2++;}\
    if(ifconst(2)) {m_in_3++;}\
    if(ifconst(3)) {m_in_4++;}\
    break;\
}
#define inputmask5(m_in_1,m_in_2,m_in_3,m_in_4,m_in_5) if(maskdefine){\
    if(ifconst(0)) {m_in_1++;}\
    if(ifconst(1)) {m_in_2++;}\
    if(ifconst(2)) {m_in_3++;}\
    if(ifconst(3)) {m_in_4++;}\
    if(ifconst(4)) {m_in_5++;}\
    break;\
}
#define inputmask6(m_in_1,m_in_2,m_in_3,m_in_4,m_in_5,m_in_6) if(maskdefine){\
    if(ifconst(0)) {m_in_1++;}\
    if(ifconst(1)) {m_in_2++;}\
    if(ifconst(2)) {m_in_3++;}\
    if(ifconst(3)) {m_in_4++;}\
    if(ifconst(4)) {m_in_5++;}\
    if(ifconst(5)) {m_in_6++;}\
    break;\
}

#ifdef debug
vec3 scene(vec3 p, bool materials)
#else
float scene(vec3 p, bool materials)
#endif
{
    uint major_position=0;
    uint minor_position=0;
    
    uint minor_integer_cache[8];

    desc = scene_description.desc[(DescriptionIndex)+1];
    
    clear_stacks();
    push_vec3(p);
    
    while(true){
        if(minor_position==0){
            get_caches;
        }
        /*#ifdef implicit
        if (mask[major_position] != 255) discard;
        if (mask[major_position+1] != 255) discard;
        if (mask[major_position+2] != 255) discard;
        if (mask[major_position+3] != 255) discard;
        #endif*/
        #ifdef debug
        /*if((minor_integer_cache[minor_position]&1023)==OPStop) {
            return vec3(0.,0.,1.);
        }
        if((minor_integer_cache[minor_position]&1023)==OPSDFSphere) {
            return vec3(1.,0.,0.);
        }*/
        /*if((minor_integer_cache[minor_position] & (1 << (15 - 1))) > 0) {
            return vec3(1.,0.,0.);
        }
        if((minor_integer_cache[minor_position] & (1 << (15 - 0))) > 0) {
            return vec3(0.,0.,1.);
        }*/
        //return vec3(0.,1.,0.);
        return vec3(desc.floats,desc.scene,DescriptionIndex);
        #endif

                switch(minor_integer_cache[minor_position]&1023)
                {
                    #define ifconst(pos) (minor_integer_cache[minor_position] & (1 << (15 - pos))) > 0
                    #define OPPos int((major_position<<3)|minor_position)
                    case OPAddFloatFloat:{
                        inputmask2(float_const_head,float_const_head);
                        float in1=pull_float(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        add;
                        push_float(in1);
                    }
                    break;
                    case OPAddVec2Vec2:{
                        inputmask2(vec2_const_head,vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        vec2 in2=pull_vec2(ifconst(1));
                        add;
                        push_vec2(in1);
                    }
                    break;
                    case OPAddVec2Float:{
                        inputmask2(vec2_const_head,float_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        add;
                        push_vec2(in1);
                    }
                    break;
                    case OPAddVec3Vec3:{
                        inputmask2(vec3_const_head,vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        vec3 in2=pull_vec3(ifconst(1));
                        add;
                        push_vec3(in1);
                    }
                    break;
                    case OPAddVec3Float:{
                        inputmask2(vec3_const_head,float_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        add;
                        push_vec3(in1);
                    }
                    break;
                    case OPAddVec4Vec4:{
                        inputmask2(vec4_const_head,vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        vec4 in2=pull_vec4(ifconst(1));
                        add;
                        push_vec4(in1);
                    }
                    break;
                    case OPAddVec4Float:{
                        inputmask2(vec4_const_head,float_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        add;
                        push_vec4(in1);
                    }
                    break;
                    
                    case OPSubFloatFloat:{
                        inputmask2(float_const_head,float_const_head);
                        float in1=pull_float(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        subtract;
                        push_float(in1);
                    }
                    break;
                    case OPSubVec2Vec2:{
                        inputmask2(vec2_const_head,vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        vec2 in2=pull_vec2(ifconst(1));
                        subtract;
                        push_vec2(in1);
                    }
                    break;
                    case OPSubVec2Float:{
                        inputmask2(vec2_const_head,float_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        subtract;
                        push_vec2(in1);
                    }
                    break;
                    case OPSubVec3Vec3:{
                        inputmask2(vec3_const_head,vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        vec3 in2=pull_vec3(ifconst(1));
                        subtract;
                        push_vec3(in1);
                    }
                    break;
                    case OPSubVec3Float:{
                        inputmask2(vec3_const_head,float_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        subtract;
                        push_vec3(in1);
                    }
                    break;
                    case OPSubVec4Vec4:{
                        inputmask2(vec4_const_head,vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        vec4 in2=pull_vec4(ifconst(1));
                        subtract;
                        push_vec4(in1);
                    }
                    break;
                    case OPSubVec4Float:{
                        inputmask2(vec4_const_head,float_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        subtract;
                        push_vec4(in1);
                    }
                    break;
                    
                    case OPMulFloatFloat:{
                        inputmask2(float_const_head,float_const_head);
                        float in1=pull_float(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        multiply;
                        push_float(in1);
                    }
                    break;
                    case OPMulVec2Vec2:{
                        inputmask2(vec2_const_head,vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        vec2 in2=pull_vec2(ifconst(1));
                        multiply;
                        push_vec2(in1);
                    }
                    break;
                    case OPMulVec2Float:{
                        inputmask2(vec2_const_head,float_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        multiply;
                        push_vec2(in1);
                    }
                    break;
                    case OPMulVec3Vec3:{
                        inputmask2(vec3_const_head,vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        vec3 in2=pull_vec3(ifconst(1));
                        multiply;
                        push_vec3(in1);
                    }
                    break;
                    case OPMulVec3Float:{
                        inputmask2(vec3_const_head,float_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        multiply;
                        push_vec3(in1);
                    }
                    break;
                    case OPMulVec4Vec4:{
                        inputmask2(vec4_const_head,vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        vec4 in2=pull_vec4(ifconst(1));
                        multiply;
                        push_vec4(in1);
                    }
                    break;
                    case OPMulVec4Float:{
                        inputmask2(vec4_const_head,float_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        multiply;
                        push_vec4(in1);
                    }
                    break;
                    
                    case OPDivFloatFloat:{
                        inputmask2(float_const_head,float_const_head);
                        float in1=pull_float(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        divide;
                        push_float(in1);
                    }
                    break;
                    case OPDivVec2Vec2:{
                        inputmask2(vec2_const_head,vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        vec2 in2=pull_vec2(ifconst(1));
                        divide;
                        push_vec2(in1);
                    }
                    break;
                    case OPDivVec2Float:{
                        inputmask2(vec2_const_head,float_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        divide;
                        push_vec2(in1);
                    }
                    break;
                    case OPDivVec3Vec3:{
                        inputmask2(vec3_const_head,vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        vec3 in2=pull_vec3(ifconst(1));
                        divide;
                        push_vec3(in1);
                    }
                    break;
                    case OPDivVec3Float:{
                        inputmask2(vec3_const_head,float_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        divide;
                        push_vec3(in1);
                    }
                    break;
                    case OPDivVec4Vec4:{
                        inputmask2(vec4_const_head,vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        vec4 in2=pull_vec4(ifconst(1));
                        divide;
                        push_vec4(in1);
                    }
                    break;
                    case OPDivVec4Float:{
                        inputmask2(vec4_const_head,float_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        divide;
                        push_vec4(in1);
                    }
                    break;
                    
                    case OPPowFloatFloat:{
                        inputmask2(float_const_head,float_const_head);
                        float in1=pull_float(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        power;
                        push_float(in1);
                    }
                    break;
                    case OPPowVec2Vec2:{
                        inputmask2(vec2_const_head,vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        vec2 in2=pull_vec2(ifconst(1));
                        power;
                        push_vec2(in1);
                    }
                    break;
                    case OPPowVec3Vec3:{
                        inputmask2(vec3_const_head,vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        vec3 in2=pull_vec3(ifconst(1));
                        power;
                        push_vec3(in1);
                    }
                    break;
                    case OPPowVec4Vec4:{
                        inputmask2(vec4_const_head,vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        vec4 in2=pull_vec4(ifconst(1));
                        power;
                        push_vec4(in1);
                    }
                    break;
                    
                    case OPModFloatFloat:{
                        inputmask2(float_const_head,float_const_head);
                        float in1=pull_float(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        modulo;
                        push_float(in1);
                    }
                    break;
                    case OPModVec2Vec2:{
                        inputmask2(vec2_const_head,vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        vec2 in2=pull_vec2(ifconst(1));
                        modulo;
                        push_vec2(in1);
                    }
                    break;
                    case OPModVec2Float:{
                        inputmask2(vec2_const_head,float_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        modulo;
                        push_vec2(in1);
                    }
                    break;
                    case OPModVec3Vec3:{
                        inputmask2(vec3_const_head,vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        vec3 in2=pull_vec3(ifconst(1));
                        modulo;
                        push_vec3(in1);
                    }
                    break;
                    case OPModVec3Float:{
                        inputmask2(vec3_const_head,float_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        modulo;
                        push_vec3(in1);
                    }
                    break;
                    case OPModVec4Vec4:{
                        inputmask2(vec4_const_head,vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        vec4 in2=pull_vec4(ifconst(1));
                        modulo;
                        push_vec4(in1);
                    }
                    break;
                    case OPModVec4Float:{
                        inputmask2(vec4_const_head,float_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        modulo;
                        push_vec4(in1);
                    }
                    break;


                    case OPCrossVec3:{
                        inputmask2(vec3_const_head,vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        vec3 in2=pull_vec3(ifconst(1));
                        push_vec3(cross(in1,in2));
                    }
                    break;

                    case OPDotVec2:{
                        inputmask2(vec2_const_head,vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        vec2 in2=pull_vec2(ifconst(1));
                        float out1;
                        dotprod;
                        push_float(out1);
                    }
                    break;
                    case OPDotVec3:{
                        inputmask2(vec3_const_head,vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        vec3 in2=pull_vec3(ifconst(1));
                        float out1;
                        dotprod;
                        push_float(out1);
                    }
                    break;
                    case OPDotVec4:{
                        inputmask2(vec4_const_head,vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        vec4 in2=pull_vec4(ifconst(1));
                        float out1;
                        dotprod;
                        push_float(out1);
                    }
                    break;

                    case OPLengthVec2:{
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        float out1;
                        len;
                        push_float(out1);
                    }
                    break;
                    case OPLengthVec3:{
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        float out1;
                        len;
                        push_float(out1);
                    }
                    break;
                    case OPLengthVec4:{
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        float out1;
                        len;
                        push_float(out1);
                    }
                    break;

                    case OPDistanceVec2:{
                        inputmask2(vec2_const_head,vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        vec2 in2=pull_vec2(ifconst(1));
                        float out1;
                        dist;
                        push_float(out1);
                    }
                    break;
                    case OPDistanceVec3:{
                        inputmask2(vec3_const_head,vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        vec3 in2=pull_vec3(ifconst(1));
                        float out1;
                        len;
                        push_float(out1);
                    }
                    break;
                    case OPDistanceVec4:{
                        inputmask2(vec4_const_head,vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        vec4 in2=pull_vec4(ifconst(1));
                        float out1;
                        dist;
                        push_float(out1);
                    }
                    break;

                    case OPAbsFloat: {
                        inputmask1(float_const_head);
                        float in1=pull_float(ifconst(0));
                        absolute;
                        push_float(in1);
                    }
                    break;
                    case OPSignFloat: {
                        inputmask1(float_const_head);
                        float in1=pull_float(ifconst(0));
                        signof;
                        push_float(in1);
                    }
                    break;
                    case OPFloorFloat: {
                        inputmask1(float_const_head);
                        float in1=pull_float(ifconst(0));
                        floorof;
                        push_float(in1);
                    }
                    break;
                    case OPCeilFloat: {
                        inputmask1(float_const_head);
                        float in1=pull_float(ifconst(0));
                        ceilingof;
                        push_float(in1);
                    }
                    break;
                    case OPFractFloat: {
                        inputmask1(float_const_head);
                        float in1=pull_float(ifconst(0));
                        fractionalof;\
                        push_float(in1);
                    }
                    break;
                    case OPSqrtFloat: {
                        inputmask1(float_const_head);
                        float in1=pull_float(ifconst(0));
                        squarerootof;
                        push_float(in1);
                    }
                    break;
                    case OPInverseSqrtFloat: {
                        inputmask1(float_const_head);
                        float in1=pull_float(ifconst(0));
                        inversesquarerootof;
                        push_float(in1);
                    }
                    break;
                    case OPExpFloat: {
                        inputmask1(float_const_head);
                        float in1=pull_float(ifconst(0));
                        exponentof;
                        push_float(in1);
                    }
                    break;
                    case OPExp2Float: {
                        inputmask1(float_const_head);
                        float in1=pull_float(ifconst(0));
                        exponent2of;
                        push_float(in1);
                    }
                    break;
                    case OPLogFloat: {
                        inputmask1(float_const_head);
                        float in1=pull_float(ifconst(0));
                        logarithmof;
                        push_float(in1);
                    }
                    break;
                    case OPLog2Float: {
                        inputmask1(float_const_head);
                        float in1=pull_float(ifconst(0));
                        logarithm2of;
                        push_float(in1);
                    }
                    break;
                    case OPSinFloat: {
                        inputmask1(float_const_head);
                        float in1=pull_float(ifconst(0));
                        sineof;
                        push_float(in1);
                    }
                    break;
                    case OPCosFloat: {
                        inputmask1(float_const_head);
                        float in1=pull_float(ifconst(0));
                        cosineof;
                        push_float(in1);
                    }
                    break;
                    case OPTanFloat: {
                        inputmask1(float_const_head);
                        float in1=pull_float(ifconst(0));
                        tangentof;
                        push_float(in1);
                    }
                    break;
                    case OPAsinFloat: {
                        inputmask1(float_const_head);
                        float in1=pull_float(ifconst(0));
                        arcsineof;
                        push_float(in1);
                    }
                    break;
                    case OPAcosFloat: {
                        inputmask1(float_const_head);
                        float in1=pull_float(ifconst(0));
                        arccosineof;
                        push_float(in1);
                    }
                    break;
                    case OPAtanFloat: {
                        inputmask1(float_const_head);
                        float in1=pull_float(ifconst(0));
                        arctangentof;
                        push_float(in1);
                    }
                    break;
                    case OPAcoshFloat:{
                        inputmask1(float_const_head);
                        float in1=pull_float(ifconst(0));
                        hyperbolicarccosineof;
                        push_float(in1);
                    }
                    break;
                    case OPAsinhFloat:{
                        inputmask1(float_const_head);
                        float in1=pull_float(ifconst(0));
                        hyperbolicarcsineof;
                        push_float(in1);
                    }
                    break;
                    case OPAtanhFloat:{
                        inputmask1(float_const_head);
                        float in1=pull_float(ifconst(0));
                        hyperbolicarctangentof;
                        push_float(in1);
                    }
                    break;
                    case OPCoshFloat:{
                        inputmask1(float_const_head);
                        float in1=pull_float(ifconst(0));
                        hyperboliccosineof;
                        push_float(in1);
                    }
                    break;
                    case OPSinhFloat:{
                        inputmask1(float_const_head);
                        float in1=pull_float(ifconst(0));
                        hyperbolicsineof;
                        push_float(in1);
                    }
                    break;
                    case OPTanhFloat:{
                        inputmask1(float_const_head);
                        float in1=pull_float(ifconst(0));
                        hyperbolictangentof;
                        push_float(in1);
                    }
                    break;
                    case OPRoundFloat:{
                        inputmask1(float_const_head);
                        float in1=pull_float(ifconst(0));
                        roundof;
                        push_float(in1);
                    }
                    break;
                    case OPTruncFloat:{
                        inputmask1(float_const_head);
                        float in1=pull_float(ifconst(0));
                        truncof;
                        push_float(in1);
                    }
                    break;
                    case OPMinMaterialFloat:
                    case OPMinFloat: {
                        inputmask2(float_const_head,float_const_head);
                        float in1=pull_float(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        minimum;
                        push_float(in1);
                    }
                    break;
                    case OPMaxMaterialFloat:
                    case OPMaxFloat: {
                        inputmask2(float_const_head,float_const_head);
                        float in1=pull_float(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        maximum;
                        push_float(in1);
                    }
                    break;
                    case OPFMAFloat: {
                        inputmask3(float_const_head,float_const_head,float_const_head);
                        float in1=pull_float(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        float in3=pull_float(ifconst(2));
                        fmaof;
                        push_float(in1);
                    }
                    break;

                    case OPAbsVec2: {
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        absolute;
                        push_vec2(in1);
                    }
                    break;
                    case OPSignVec2: {
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        signof;
                        push_vec2(in1);
                    }
                    break;
                    case OPFloorVec2: {
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        floorof;
                        push_vec2(in1);
                    }
                    break;
                    case OPCeilVec2: {
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        ceilingof;
                        push_vec2(in1);
                    }
                    break;
                    case OPFractVec2: {
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        fractionalof;
                        push_vec2(in1);
                    }
                    break;
                    case OPSqrtVec2: {
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        squarerootof;
                        push_vec2(in1);
                    }
                    break;
                    case OPInverseSqrtVec2: {
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        inversesquarerootof;
                        push_vec2(in1);
                    }
                    break;
                    case OPExpVec2: {
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        exponentof;
                        push_vec2(in1);
                    }
                    break;
                    case OPExp2Vec2: {
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        exponent2of;
                        push_vec2(in1);
                    }
                    break;
                    case OPLogVec2: {
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        logarithmof;
                        push_vec2(in1);
                    }
                    break;
                    case OPLog2Vec2: {
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        logarithm2of;
                        push_vec2(in1);
                    }
                    break;
                    case OPSinVec2: {
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        sineof;
                        push_vec2(in1);
                    }
                    break;
                    case OPCosVec2: {
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        cosineof;
                        push_vec2(in1);
                    }
                    break;
                    case OPTanVec2: {
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        tangentof;
                        push_vec2(in1);
                    }
                    break;
                    case OPAsinVec2: {
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        arcsineof;
                        push_vec2(in1);
                    }
                    break;
                    case OPAcosVec2: {
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        arccosineof;
                        push_vec2(in1);
                    }
                    break;
                    case OPAtanVec2: {
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        arctangentof;
                        push_vec2(in1);
                    }
                    break;
                    case OPAcoshVec2:{
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        hyperbolicarccosineof;
                        push_vec2(in1);
                    }
                    break;
                    case OPAsinhVec2:{
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        hyperbolicarcsineof;
                        push_vec2(in1);
                    }
                    break;
                    case OPAtanhVec2:{
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        hyperbolicarctangentof;
                        push_vec2(in1);
                    }
                    break;
                    case OPCoshVec2:{
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        hyperboliccosineof;
                        push_vec2(in1);
                    }
                    break;
                    case OPSinhVec2:{
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        hyperbolicsineof;
                        push_vec2(in1);
                    }
                    break;
                    case OPTanhVec2:{
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        hyperbolictangentof;
                        push_vec2(in1);
                    }
                    break;
                    case OPRoundVec2:{
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        roundof;
                        push_vec2(in1);
                    }
                    break;
                    case OPTruncVec2:{
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        truncof;
                        push_vec2(in1);
                    }
                    break;
                    case OPMinVec2: {
                        inputmask2(vec2_const_head,vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        vec2 in2=pull_vec2(ifconst(1));
                        minimum;
                        push_vec2(in1);
                    }
                    break;
                    case OPMaxVec2: {
                        inputmask2(vec2_const_head,vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        vec2 in2=pull_vec2(ifconst(1));
                        maximum;
                        push_vec2(in1);
                    }
                    break;
                    case OPFMAVec2: {
                        inputmask3(vec2_const_head,vec2_const_head,vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        vec2 in2=pull_vec2(ifconst(1));
                        vec2 in3=pull_vec2(ifconst(2));
                        fmaof;
                        push_vec2(in1);
                    }
                    break;

                    case OPAbsVec3: {
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        absolute;
                        push_vec3(in1);
                    }
                    break;
                    case OPSignVec3: {
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        signof;
                        push_vec3(in1);
                    }
                    break;
                    case OPFloorVec3: {
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        floorof;
                        push_vec3(in1);
                    }
                    break;
                    case OPCeilVec3: {
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        ceilingof;
                        push_vec3(in1);
                    }
                    break;
                    case OPFractVec3: {
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        fractionalof;
                        push_vec3(in1);
                    }
                    break;
                    case OPSqrtVec3: {
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        squarerootof;
                        push_vec3(in1);
                    }
                    break;
                    case OPInverseSqrtVec3: {
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        inversesquarerootof;
                        push_vec3(in1);
                    }
                    break;
                    case OPExpVec3: {
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        exponentof;
                        push_vec3(in1);
                    }
                    break;
                    case OPExp2Vec3: {
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        exponent2of;
                        push_vec3(in1);
                    }
                    break;
                    case OPLogVec3: {
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        logarithmof;
                        push_vec3(in1);
                    }
                    break;
                    case OPLog2Vec3: {
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        logarithm2of;
                        push_vec3(in1);
                    }
                    break;
                    case OPSinVec3: {
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        sineof;
                        push_vec3(in1);
                    }
                    break;
                    case OPCosVec3: {
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        cosineof;
                        push_vec3(in1);
                    }
                    break;
                    case OPTanVec3: {
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        tangentof;
                        push_vec3(in1);
                    }
                    break;
                    case OPAsinVec3: {
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        arcsineof;
                        push_vec3(in1);
                    }
                    break;
                    case OPAcosVec3: {
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        arccosineof;
                        push_vec3(in1);
                    }
                    break;
                    case OPAtanVec3: {
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        arctangentof;
                        push_vec3(in1);
                    }
                    break;
                    case OPAcoshVec3:{
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        hyperbolicarccosineof;
                        push_vec3(in1);
                    }
                    break;
                    case OPAsinhVec3:{
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        hyperbolicarcsineof;
                        push_vec3(in1);
                    }
                    break;
                    case OPAtanhVec3:{
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        hyperbolicarctangentof;
                        push_vec3(in1);
                    }
                    break;
                    case OPCoshVec3:{
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        hyperboliccosineof;
                        push_vec3(in1);
                    }
                    break;
                    case OPSinhVec3:{
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        hyperbolicsineof;
                        push_vec3(in1);
                    }
                    break;
                    case OPTanhVec3:{
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        hyperbolictangentof;
                        push_vec3(in1);
                    }
                    break;
                    case OPRoundVec3:{
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        roundof;
                        push_vec3(in1);
                    }
                    break;
                    case OPTruncVec3:{
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        truncof;
                        push_vec3(in1);
                    }
                    break;
                    case OPMinVec3: {
                        inputmask2(vec3_const_head,vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        vec3 in2=pull_vec3(ifconst(1));
                        minimum;
                        push_vec3(in1);
                    }
                    break;
                    case OPMaxVec3: {
                        inputmask2(vec3_const_head,vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        vec3 in2=pull_vec3(ifconst(1));
                        maximum;
                        push_vec3(in1);
                    }
                    break;
                    case OPFMAVec3: {
                        inputmask3(vec3_const_head,vec3_const_head,vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        vec3 in2=pull_vec3(ifconst(1));
                        vec3 in3=pull_vec3(ifconst(2));
                        fmaof;
                        push_vec3(in1);
                    }
                    break;

                    case OPAbsVec4: {
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        absolute;
                        push_vec4(in1);
                    }
                    break;
                    case OPSignVec4: {
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        signof;
                        push_vec4(in1);
                    }
                    break;
                    case OPFloorVec4: {
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        floorof;
                        push_vec4(in1);
                    }
                    break;
                    case OPCeilVec4: {
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        ceilingof;
                        push_vec4(in1);
                    }
                    break;
                    case OPFractVec4: {
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        fractionalof;
                        push_vec4(in1);
                    }
                    break;
                    case OPSqrtVec4: {
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        squarerootof;
                        push_vec4(in1);
                    }
                    break;
                    case OPInverseSqrtVec4: {
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        inversesquarerootof;
                        push_vec4(in1);
                    }
                    break;
                    case OPExpVec4: {
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        exponentof;
                        push_vec4(in1);
                    }
                    break;
                    case OPExp2Vec4: {
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        exponent2of;
                        push_vec4(in1);
                    }
                    break;
                    case OPLogVec4: {
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        logarithmof;
                        push_vec4(in1);
                    }
                    break;
                    case OPLog2Vec4: {
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        logarithm2of;
                        push_vec4(in1);
                    }
                    break;
                    case OPSinVec4: {
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        sineof;
                        push_vec4(in1);
                    }
                    break;
                    case OPCosVec4: {
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        cosineof;
                        push_vec4(in1);
                    }
                    break;
                    case OPTanVec4: {
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        tangentof;
                        push_vec4(in1);
                    }
                    break;
                    case OPAsinVec4: {
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        arcsineof;
                        push_vec4(in1);
                    }
                    break;
                    case OPAcosVec4: {
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        arccosineof;
                        push_vec4(in1);
                    }
                    break;
                    case OPAtanVec4: {
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        arctangentof;
                        push_vec4(in1);
                    }
                    break;
                    case OPAcoshVec4:{
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        hyperbolicarccosineof;
                        push_vec4(in1);
                    }
                    break;
                    case OPAsinhVec4:{
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        hyperbolicarcsineof;
                        push_vec4(in1);
                    }
                    break;
                    case OPAtanhVec4:{
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        hyperbolicarctangentof;
                        push_vec4(in1);
                    }
                    break;
                    case OPCoshVec4:{
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        hyperboliccosineof;
                        push_vec4(in1);
                    }
                    break;
                    case OPSinhVec4:{
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        hyperbolicsineof;
                        push_vec4(in1);
                    }
                    break;
                    case OPTanhVec4:{
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        hyperbolictangentof;
                        push_vec4(in1);
                    }
                    break;
                    case OPRoundVec4:{
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        roundof;
                        push_vec4(in1);
                    }
                    break;
                    case OPTruncVec4:{
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        truncof;
                        push_vec4(in1);
                    }
                    break;
                    case OPMinVec4: {
                        inputmask2(vec4_const_head,vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        vec4 in2=pull_vec4(ifconst(1));
                        minimum;
                        push_vec4(in1);
                    }
                    break;
                    case OPMaxVec4: {
                        inputmask2(vec4_const_head,vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        vec4 in2=pull_vec4(ifconst(1));
                        maximum;
                        push_vec4(in1);
                    }
                    break;
                    case OPFMAVec4: {
                        inputmask3(vec4_const_head,vec4_const_head,vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        vec4 in2=pull_vec4(ifconst(1));
                        vec4 in3=pull_vec4(ifconst(2));
                        fmaof;
                        push_vec4(in1);
                    }
                    break;

                    case OPClampFloatFloat:{
                        inputmask3(float_const_head,float_const_head,float_const_head);
                        float in1=pull_float(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        float in3=pull_float(ifconst(2));
                        clampof;
                        push_float(in1);
                    }
                    break;
                    case OPMixFloatFloat:{
                        inputmask3(float_const_head,float_const_head,float_const_head);
                        float in1=pull_float(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        float in3=pull_float(ifconst(2));
                        mixof;
                        push_float(in1);
                    }
                    break;
                    case OPClampVec2Vec2:{
                        inputmask3(vec2_const_head,vec2_const_head,vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        vec2 in2=pull_vec2(ifconst(1));
                        vec2 in3=pull_vec2(ifconst(2));
                        clampof;
                        push_vec2(in1);
                    }
                    break;
                    case OPMixVec2Vec2:{
                        inputmask3(vec2_const_head,vec2_const_head,vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        vec2 in2=pull_vec2(ifconst(1));
                        vec2 in3=pull_vec2(ifconst(2));
                        mixof;
                        push_vec2(in1);
                    }
                    break;
                    case OPClampVec2Float:{
                        inputmask3(vec2_const_head,float_const_head,float_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        float in3=pull_float(ifconst(2));
                        clampof;
                        push_vec2(in1);
                    }
                    break;
                    case OPMixVec2Float:{
                        inputmask3(vec2_const_head,vec2_const_head,float_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        vec2 in2=pull_vec2(ifconst(1));
                        float in3=pull_float(ifconst(2));
                        mixof;
                        push_vec2(in1);
                    }
                    break;
                    case OPClampVec3Vec3:{
                        inputmask3(vec3_const_head,vec3_const_head,vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        vec3 in2=pull_vec3(ifconst(1));
                        vec3 in3=pull_vec3(ifconst(2));
                        clampof;
                        push_vec3(in1);
                    }
                    break;
                    case OPMixVec3Vec3:{
                        inputmask3(vec3_const_head,vec3_const_head,vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        vec3 in2=pull_vec3(ifconst(1));
                        vec3 in3=pull_vec3(ifconst(2));
                        mixof;
                        push_vec3(in1);
                    }
                    break;
                    case OPClampVec3Float:{
                        inputmask3(vec3_const_head,float_const_head,float_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        float in3=pull_float(ifconst(2));
                        clampof;
                        push_vec3(in1);
                    }
                    break;
                    case OPMixVec3Float:{
                        inputmask3(vec3_const_head,vec3_const_head,float_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        vec3 in2=pull_vec3(ifconst(1));
                        float in3=pull_float(ifconst(2));
                        mixof;
                        push_vec3(in1);
                    }
                    break;
                    case OPClampVec4Vec4:{
                        inputmask3(vec4_const_head,vec4_const_head,vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        vec4 in2=pull_vec4(ifconst(1));
                        vec4 in3=pull_vec4(ifconst(2));
                        clampof;
                        push_vec4(in1);
                    }
                    break;
                    case OPMixVec4Vec4:{
                        inputmask3(vec4_const_head,vec4_const_head,vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        vec4 in2=pull_vec4(ifconst(1));
                        vec4 in3=pull_vec4(ifconst(2));
                        mixof;
                        push_vec4(in1);
                    }
                    break;
                    case OPClampVec4Float:{
                        inputmask3(vec4_const_head,float_const_head,float_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        float in2=pull_float(ifconst(1));
                        float in3=pull_float(ifconst(2));
                        clampof;
                        push_vec4(in1);
                    }
                    break;
                    case OPMixVec4Float:{
                        inputmask3(vec4_const_head,vec4_const_head,float_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        vec4 in2=pull_vec4(ifconst(1));
                        float in3=pull_float(ifconst(2));
                        mixof;
                        push_vec4(in1);
                    }
                    break;
                    
                    case OPNormalizeVec2:{
                        inputmask1(vec2_const_head);
                        vec2 in1=pull_vec2(ifconst(0));
                        push_vec2(normalize(in1));
                    }
                    break;
                    case OPNormalizeVec3:{
                        inputmask1(vec3_const_head);
                        vec3 in1=pull_vec3(ifconst(0));
                        push_vec3(normalize(in1));
                    }
                    break;
                    case OPNormalizeVec4:{
                        inputmask1(vec4_const_head);
                        vec4 in1=pull_vec4(ifconst(0));
                        push_vec4(normalize(in1));
                    }
                    break;

                    case OPPromoteFloatFloatVec2:{
                        inputmask2(float_const_head,float_const_head);
                        float  a = pull_float(ifconst(0));
                        float  b = pull_float(ifconst(1));
                        push_vec2(vec2 (a,b));
                    }
                    break;
                    case OPPromoteFloatFloatFloatVec3:{
                        inputmask3(float_const_head,float_const_head,float_const_head);
                        float  a = pull_float(ifconst(0));
                        float  b = pull_float(ifconst(1));
                        float  c = pull_float(ifconst(2));
                        push_vec3(vec3 (a,b,c));
                    }
                    break;
                    case OPPromoteVec2FloatVec3:{
                        inputmask2(vec2_const_head,float_const_head);
                        vec2  a = pull_vec2(ifconst(0));
                        float  b = pull_float(ifconst(1));
                        push_vec3(vec3 (a,b));
                    }
                    break;
                    case OPPromoteFloatFloatFloatFloatVec4:{
                        inputmask4(float_const_head,float_const_head,float_const_head,float_const_head);
                        float  a = pull_float(ifconst(0));
                        float  b = pull_float(ifconst(1));
                        float  c = pull_float(ifconst(2));
                        float  d = pull_float(ifconst(3));
                        push_vec4(vec4 (a,b,c,d));
                    }
                    break;
                    case OPPromoteVec2FloatFloatVec4:{
                        inputmask3(vec2_const_head,float_const_head,float_const_head);
                        vec2  a = pull_vec2(ifconst(0));
                        float  b = pull_float(ifconst(1));
                        float  c = pull_float(ifconst(2));
                        push_vec4(vec4 (a,b,c));
                    }
                    break;
                    case OPPromoteVec3FloatVec4:{
                        inputmask2(vec3_const_head,float_const_head);
                        vec3  a = pull_vec3(ifconst(0));
                        float  b = pull_float(ifconst(1));
                        push_vec4(vec4 (a,b));
                    }
                    break;
                    case OPPromoteVec2Vec2Vec4:{
                        inputmask2(vec2_const_head,vec2_const_head);
                        vec2  a = pull_vec2(ifconst(0));
                        vec2  b = pull_vec2(ifconst(1));
                        push_vec4(vec4 (a,b));
                    }
                    break;

                    /*
                    case OPDemoteMat2Float:{
                    mat2  mat2temp=pull_mat2(ifconst(0));
                    push_float(float (mat2temp[0][1].y,mat2temp[1][1].y));
                    push_float(float (mat2temp[0][1].x,mat2temp[1][1].x));
                    push_float(float (mat2temp[0][0].y,mat2temp[1][0].y));
                    push_float(float (mat2temp[0][0].x,mat2temp[1][0].x));
                    }
                    break;
                    case OPDemoteMat2Vec2:{
                    mat2  mat2temp=pull_mat2(ifconst(0));
                    push_vec2(vec2 (mat2temp[0][1],mat2temp[1][1]));
                    push_vec2(vec2 (mat2temp[0][0],mat2temp[1][0]));
                    }
                    break;
                    case OPDemoteMat3Vec3:{
                    mat3  mat3temp=pull_mat3(ifconst(0));
                    push_vec3(vec3 (mat3temp[0] ,mat3temp[1] ));
                    push_vec3(vec3 (mat3temp[0][1],mat3temp[1][1]));
                    push_vec3(vec3 (mat3temp[0][0],mat3temp[1][0]));
                    }
                    break;
                    case OPDemoteMat4Vec4:{
                    mat4  mat4temp=pull_mat4(ifconst(0));
                    push_vec4(vec4 (mat4temp[0][3],mat4temp[1][3]));
                    push_vec4(vec4 (mat4temp[0] ,mat4temp[1] ));
                    push_vec4(vec4 (mat4temp[0][1],mat4temp[1][1]));
                    push_vec4(vec4 (mat4temp[0][0],mat4temp[1][0]));
                    }
                    break;
                    case OPDemoteMat2Vec4:{
                    mat2  mat2temp=pull_mat2(ifconst(0));
                    push_vec4(vec4 (vec4(mat2temp[0][0],mat2temp[0][1]),vec4(mat2temp[1][0],mat2temp[1][1])));
                    }
                    break;
                    case OPDemoteVec2FloatFloat:{
                    vec2  vec2temp=pull_vec2(ifconst(0));
                    push_float(float (vec2temp[0].y,vec2temp[1].y));
                    push_float(float (vec2temp[0].x,vec2temp[1].x));
                    }
                    break;
                    case OPDemoteVec3FloatFloatFloat:{
                    vec3  vec3temp=pull_vec3(ifconst(0));
                    push_float(float (vec3temp[0].z,vec3temp[1].z));
                    push_float(float (vec3temp[0].y,vec3temp[1].y));
                    push_float(float (vec3temp[0].x,vec3temp[1].x));
                    }
                    break;
                    case OPDemoteVec4FloatFloatFloatFloat:{
                    vec4  vec4temp=pull_vec4(ifconst(0));
                    push_float(float (vec4temp[0].w,vec4temp[1].w));
                    push_float(float (vec4temp[0].z,vec4temp[1].z));
                    push_float(float (vec4temp[0].y,vec4temp[1].y));
                    push_float(float (vec4temp[0].x,vec4temp[1].x));
                    }
                    break;
                    */

                    case OPSquareFloat:{
                        inputmask1(float_const_head);
                        float  in1 = pull_float(ifconst(0));
                        square;
                        push_float(in1);
                    }
                    break;
                    case OPCubeFloat:{
                        inputmask1(float_const_head);
                        float  in1 = pull_float(ifconst(0));
                        cube;
                        push_float(in1);
                    }
                    break;
                    case OPSquareVec2:{
                        inputmask1(vec2_const_head);
                        vec2  in1 = pull_vec2(ifconst(0));
                        square;
                        push_vec2(in1);
                    }
                    break;
                    case OPCubeVec2:{
                        inputmask1(vec2_const_head);
                        vec2  in1 = pull_vec2(ifconst(0));
                        cube;
                        push_vec2(in1);
                    }
                    break;
                    case OPSquareVec3:{
                        inputmask1(vec3_const_head);
                        vec3  in1 = pull_vec3(ifconst(0));
                        square;
                        push_vec3(in1);
                    }
                    break;
                    case OPCubeVec3:{
                        inputmask1(vec3_const_head);
                        vec3  in1 = pull_vec3(ifconst(0));
                        cube;
                        push_vec3(in1);
                    }
                    break;
                    case OPSquareVec4:{
                        inputmask1(vec4_const_head);
                        vec4  in1 = pull_vec4(ifconst(0));
                        square;
                        push_vec4(in1);
                    }
                    break;
                    case OPCubeVec4:{
                        inputmask1(vec4_const_head);
                        vec4  in1 = pull_vec4(ifconst(0));
                        cube;
                        push_vec4(in1);
                    }
                    break;

                    case OPSmoothMinMaterialFloat:
                    case OPSmoothMinFloat:{
                        inputmask3(float_const_head,float_const_head,float_const_head);
                        float k=pull_float(ifconst(0));
                        float a=pull_float(ifconst(1));
                        float b=pull_float(ifconst(2));
                        float h=max(k-abs(a-b),0.);
                        float s=min(a,b)-h*h*.25/k;
                        push_float(s);
                    }
                    break;
                    case OPSmoothMaxMaterialFloat:
                    case OPSmoothMaxFloat:{
                        inputmask3(float_const_head,float_const_head,float_const_head);
                        float k=pull_float(ifconst(0));
                        float a=pull_float(ifconst(1));
                        float b=pull_float(ifconst(2));
                        float h=max(k-abs(a-b),0.);
                        float s=max(a,b)+h*h*.25/k;
                        push_float(s);
                    }
                    break;

                    /*
                    case OPSwap2Float:{
                        float floattemp=float_stack[float_stack_head-1];
                        float_stack[float_stack_head-1]=float_stack[float_stack_head-2];
                    }
                    break;
                    case OPSwap3Float:{
                        float floattemp=float_stack[float_stack_head-1];
                        float_stack[float_stack_head-1]=float_stack[float_stack_head-3];
                    }
                    break;
                    case OPSwap4Float:{
                        float floattemp=float_stack[float_stack_head-1];
                        float_stack[float_stack_head-1]=float_stack[float_stack_head-4];
                    }
                    */
                    break;
                    case OPDupFloat:{
                        inputmask1(float_const_head);
                        push_float(float_stack[float_stack_head-1]);
                    }
                    break;
                    case OPDup2Float:{
                        inputmask1(float_const_head);
                        push_float(float_stack[float_stack_head-2]);
                    }
                    break;
                    case OPDup3Float:{
                        inputmask1(float_const_head);
                        push_float(float_stack[float_stack_head-3]);
                    }
                    break;
                    case OPDup4Float:{
                        inputmask1(float_const_head);
                        push_float(float_stack[float_stack_head-4]);
                    }
                    break;
                    /*
                    case OPDropFloat:{
                        float_stack_head--;
                    }
                    break;
                    case OPDrop2Float:{
                        float_stack[float_stack_head-2]=float_stack[float_stack_head-1];
                        float_stack_head--;
                    }
                    break;
                    case OPDrop3Float:{
                        float_stack[float_stack_head-3]=float_stack[float_stack_head-2];
                        float_stack[float_stack_head-2]=float_stack[float_stack_head-1];
                        float_stack_head--;
                    }
                    break;
                    case OPDrop4Float:{
                        float_stack[float_stack_head-4]=float_stack[float_stack_head-3];
                        float_stack[float_stack_head-3]=float_stack[float_stack_head-2];
                        float_stack[float_stack_head-2]=float_stack[float_stack_head-1];
                        float_stack_head--;
                    }
                    break;
                    */
                    /*
                    case OPSwap2Vec2:{
                        vec2 vec2temp=vec2_stack[vec2_stack_head-1];
                        vec2_stack[vec2_stack_head-1]=vec2_stack[vec2_stack_head-2];
                    }
                    break;
                    case OPSwap3Vec2:{
                        vec2 vec2temp=vec2_stack[vec2_stack_head-1];
                        vec2_stack[vec2_stack_head-1]=vec2_stack[vec2_stack_head-3];
                    }
                    break;
                    case OPSwap4Vec2:{
                        vec2 vec2temp=vec2_stack[vec2_stack_head-1];
                        vec2_stack[vec2_stack_head-1]=vec2_stack[vec2_stack_head-4];
                    }
                    break;
                    */
                    case OPDupVec2:{
                        inputmask1(vec2_const_head);
                        push_vec2(vec2_stack[vec2_stack_head-1]);
                    }
                    break;
                    case OPDup2Vec2:{
                        inputmask1(vec2_const_head);
                        push_vec2(vec2_stack[vec2_stack_head-2]);
                    }
                    break;
                    case OPDup3Vec2:{
                        inputmask1(vec2_const_head);
                        push_vec2(vec2_stack[vec2_stack_head-3]);
                    }
                    break;
                    case OPDup4Vec2:{
                        inputmask1(vec2_const_head);
                        push_vec2(vec2_stack[vec2_stack_head-4]);
                    }
                    break;
                    /*
                    case OPDropVec2:{
                        vec2_stack_head--;
                    }
                    break;
                    case OPDrop2Vec2:{
                        vec2_stack[vec2_stack_head-2]=vec2_stack[vec2_stack_head-1];
                        vec2_stack_head--;
                    }
                    break;
                    case OPDrop3Vec2:{
                        vec2_stack[vec2_stack_head-3]=vec2_stack[vec2_stack_head-2];
                        vec2_stack[vec2_stack_head-2]=vec2_stack[vec2_stack_head-1];
                        vec2_stack_head--;
                    }
                    break;
                    case OPDrop4Vec2:{
                        vec2_stack[vec2_stack_head-4]=vec2_stack[vec2_stack_head-3];
                        vec2_stack[vec2_stack_head-3]=vec2_stack[vec2_stack_head-2];
                        vec2_stack[vec2_stack_head-2]=vec2_stack[vec2_stack_head-1];
                        vec2_stack_head--;
                    }
                    break;
                    */
                    /*
                    case OPSwap2Vec3:{
                        vec3 vec3temp=vec3_stack[vec3_stack_head-1];
                        vec3_stack[vec3_stack_head-1]=vec3_stack[vec3_stack_head-2];
                    }
                    break;
                    case OPSwap3Vec3:{
                        vec3 vec3temp=vec3_stack[vec3_stack_head-1];
                        vec3_stack[vec3_stack_head-1]=vec3_stack[vec3_stack_head-3];
                    }
                    break;
                    case OPSwap4Vec3:{
                        vec3 vec3temp=vec3_stack[vec3_stack_head-1];
                        vec3_stack[vec3_stack_head-1]=vec3_stack[vec3_stack_head-4];
                    }
                    break;
                    */
                    case OPDupVec3:{
                        inputmask1(vec3_const_head);
                        push_vec3(vec3_stack[vec3_stack_head-1]);
                    }
                    break;
                    case OPDup2Vec3:{
                        inputmask1(vec3_const_head);
                        push_vec3(vec3_stack[vec3_stack_head-2]);
                    }
                    break;
                    case OPDup3Vec3:{
                        inputmask1(vec3_const_head);
                        push_vec3(vec3_stack[vec3_stack_head-3]);
                    }
                    break;
                    case OPDup4Vec3:{
                        inputmask1(vec3_const_head);
                        push_vec3(vec3_stack[vec3_stack_head-4]);
                    }
                    break;
                    /*
                    case OPDropVec3:{
                        vec3_stack_head--;
                    }
                    break;
                    case OPDrop2Vec3:{
                        vec3_stack[vec3_stack_head-2]=vec3_stack[vec3_stack_head-1];
                        vec3_stack_head--;
                    }
                    break;
                    case OPDrop3Vec3:{
                        vec3_stack[vec3_stack_head-3]=vec3_stack[vec3_stack_head-2];
                        vec3_stack[vec3_stack_head-2]=vec3_stack[vec3_stack_head-1];
                        vec3_stack_head--;
                    }
                    break;
                    case OPDrop4Vec3:{
                        vec3_stack[vec3_stack_head-4]=vec3_stack[vec3_stack_head-3];
                        vec3_stack[vec3_stack_head-3]=vec3_stack[vec3_stack_head-2];
                        vec3_stack[vec3_stack_head-2]=vec3_stack[vec3_stack_head-1];
                        vec3_stack_head--;
                    }
                    break;
                    */
                    /*
                    case OPSwap2Vec4:{
                        vec4 vec4temp=vec4_stack[vec4_stack_head-1];
                        vec4_stack[vec4_stack_head-1]=vec4_stack[vec4_stack_head-2];
                    }
                    break;
                    case OPSwap3Vec4:{
                        vec4 vec4temp=vec4_stack[vec4_stack_head-1];
                        vec4_stack[vec4_stack_head-1]=vec4_stack[vec4_stack_head-3];
                    }
                    break;
                    case OPSwap4Vec4:{
                        vec4 vec4temp=vec4_stack[vec4_stack_head-1];
                        vec4_stack[vec4_stack_head-1]=vec4_stack[vec4_stack_head-4];
                    }
                    break;
                    */
                    case OPDupVec4:{
                        inputmask1(vec4_const_head);
                        push_vec4(vec4_stack[vec4_stack_head-1]);
                    }
                    break;
                    case OPDup2Vec4:{
                        inputmask1(vec4_const_head);
                        push_vec4(vec4_stack[vec4_stack_head-2]);
                    }
                    break;
                    case OPDup3Vec4:{
                        inputmask1(vec4_const_head);
                        push_vec4(vec4_stack[vec4_stack_head-3]);
                    }
                    break;
                    case OPDup4Vec4:{
                        inputmask1(vec4_const_head);
                        push_vec4(vec4_stack[vec4_stack_head-4]);
                    }
                    break;
                    /*
                    case OPDropVec4:{
                        vec4_stack_head--;
                    }
                    break;
                    case OPDrop2Vec4:{
                        vec4_stack[vec4_stack_head-2]=vec4_stack[vec4_stack_head-1];
                        vec4_stack_head--;
                    }
                    break;
                    case OPDrop3Vec4:{
                        vec4_stack[vec4_stack_head-3]=vec4_stack[vec4_stack_head-2];
                        vec4_stack[vec4_stack_head-2]=vec4_stack[vec4_stack_head-1];
                        vec4_stack_head--;
                    }
                    break;
                    case OPDrop4Vec4:{
                        vec4_stack[vec4_stack_head-4]=vec4_stack[vec4_stack_head-3];
                        vec4_stack[vec4_stack_head-3]=vec4_stack[vec4_stack_head-2];
                        vec4_stack[vec4_stack_head-2]=vec4_stack[vec4_stack_head-1];
                        vec4_stack_head--;
                    }
                    break;
                    */
                    

                    case OPSDFSphere:
                    {
                        inputmask2(float_const_head,vec3_const_head);
                        float  in2=pull_float(ifconst(0));
                        /*#ifdef debug
                        if (in2[0] == in2[1] && in2[0] == 0.2)
                        {return vec3(in2[0],in2[1],0.);
                        }else{
                            return vec3(in2[0],in2[1],1.);
                        }
                        #endif*/
                        vec3  in1=pull_vec3(ifconst(1));
                        /*#ifdef debug
                        return in1[0];
                        #endif*/
                        
                        push_float(length(in1)-in2);
                    }
                    break;

                    case OPSDFTorus:
                    {
                        inputmask2(vec2_const_head,vec3_const_head);
                        vec2  t=pull_vec2(ifconst(0)); //t
                        vec3  p=pull_vec3(ifconst(1)); //p

                        vec2 q = vec2(length(p.xz)-t.x,p.y);
                        push_float(length(q)-t.y);
                    }
                    break;

                    //this doesn't work internally but it's probably fiiiine
                    case OPSDFBox:
                    {
                        inputmask2(vec3_const_head,vec3_const_head);
                        vec3  b=pull_vec3(ifconst(0)); //r
                        vec3  p=pull_vec3(ifconst(1)); //p

                        vec3 q = abs(p) - b;

                        push_float(length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0));
                    }
                    break;
                    
                    case OPNop:
                    break;
                    case OPStop:
                    #ifdef debug
                    return vec3(pull_float(ifconst(0)));
                    #else
                    return pull_float(ifconst(0));
                    #endif
                    case OPInvalid:
                    default:
                    #ifdef debug
                    return vec3(float(minor_integer_cache[minor_position]));
                    #else
                    return float (-1);
                    #endif
                }
        
        minor_position++;
        if(minor_position==8)
        {
            minor_position=0;
            major_position++;
            if(major_position==masklen)
            {
                #ifdef debug
                return vec3(pull_float(false));
                #else
                return pull_float(false);
                #endif
            }
        }
    }
}

#endif//ifndef interpreter