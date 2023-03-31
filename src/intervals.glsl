#extension GL_EXT_shader_explicit_arithmetic_types:require

#ifndef intervals
#define intervals 1

#include "instructionset.glsl"

const float INFINITY = 1. / 0.;
const float NINFINITY = (-1.) / 0.;

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
    uint8_t dependencies[][2];
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

float float_stack[8][2];
uint float_stack_head=0;
vec2 vec2_stack[8][2];
uint vec2_stack_head=0;
vec3 vec3_stack[8][2];
uint vec3_stack_head=0;
vec4 vec4_stack[8][2];
uint vec4_stack_head=0;
mat2 mat2_stack[1][2];
uint mat2_stack_head=0;
mat3 mat3_stack[1][2];
uint mat3_stack_head=0;
mat4 mat4_stack[1][2];
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

void push_float(float f[2]){
    float_stack[float_stack_head++]=f;
}

float[2]pull_float(bool c){
    if (c) {
        float f = fconst.floats[desc.floats+float_const_head++];
        return float[2](f,f);
    }
    else {
        return float_stack[--float_stack_head];
    }
}

float cpull_float(){
    return fconst.floats[desc.floats+float_const_head++];
}

void push_vec2(vec2 f[2]){
    vec2_stack[vec2_stack_head++]=f;
}

vec2[2]pull_vec2(bool c){
    if (c) {
        vec2 f = v2const.vec2s[desc.vec2s+vec2_const_head++];
        return vec2[2](f,f);
    }
    else {
        return vec2_stack[--vec2_stack_head];
    }
}

vec2 cpull_vec2(){
    return v2const.vec2s[desc.vec2s+vec2_const_head++];
}

void push_vec3(vec3 f[2]){
    vec3_stack[vec3_stack_head++]=f;
}

vec3[2]pull_vec3(bool c){
    if (c) {
        vec3 f = v3const.vec3s[desc.vec3s+vec3_const_head++].xyz;
        return vec3[2](f,f);
    }
    else {
        return vec3_stack[--vec3_stack_head];
    }
}

vec3 cpull_vec3(){
    return v3const.vec3s[desc.vec3s+vec3_const_head++].xyz;
}

void push_vec4(vec4 f[2]){
    vec4_stack[vec4_stack_head++]=f;
}

vec4[2]pull_vec4(bool c){
    if (c) {
        vec4 f = v4const.vec4s[desc.vec4s+vec4_const_head++];
        return vec4[2](f,f);
    }
    else {
        return vec4_stack[--vec4_stack_head];
    }
}

vec4 cpull_vec4(){
    return v4const.vec4s[desc.vec4s+vec4_const_head++];
}

void push_mat2(mat2 f[2]){
    mat2_stack[mat2_stack_head++]=f;
}

mat2[2]pull_mat2(bool c){
    if (c) {
        mat2 f = m2const.mat2s[desc.mat2s+mat2_const_head++];
        return mat2[2](f,f);
    }
    else {
        return mat2_stack[--mat2_stack_head];
    }
}

mat2 cpull_mat2(){
    return m2const.mat2s[desc.mat2s+mat2_const_head++];
}

void push_mat3(mat3 f[2]){
    mat3_stack[mat3_stack_head++]=f;
}

mat3[2]pull_mat3(bool c){
    if (c) {
        mat3 f = m3const.mat3s[desc.mat3s+mat3_const_head++];
        return mat3[2](f,f);
    }
    else {
        return mat3_stack[--mat3_stack_head];
    }
}

mat3 cpull_mat3(){
    return m3const.mat3s[desc.mat3s+mat3_const_head++];
}

void push_mat4(mat4 f[2]){
    mat4_stack[mat4_stack_head++]=f;
}

mat4[2]pull_mat4(bool c){
    if (c) {
        mat4 f = m4const.mat4s[desc.mat4s+mat4_const_head++];
        return mat4[2](f,f);
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
    temp[0]=in1[0]*in2[0];\
    temp[1]=in1[0]*in2[1];\
    temp[2]=in1[1]*in2[0];\
    temp[3]=in1[1]*in2[1];\
    in1[0]=min(temp[0],min(temp[1],min(temp[2],temp[3])));\
    in1[1]=max(temp[0],max(temp[1],max(temp[2],temp[3])));\
}
//monotonic
#define divide {\
    temp[0]=in1[0]/in2[0];\
    temp[1]=in1[0]/in2[1];\
    temp[2]=in1[1]/in2[0];\
    temp[3]=in1[1]/in2[1];\
    in1[0]=min(temp[0],min(temp[1],min(temp[2],temp[3])));\
    in1[1]=max(temp[0],max(temp[1],max(temp[2],temp[3])));\
}
//monotonic
#define add {\
    in1[0]+=in2[0];\
    in1[1]+=in2[1];\
}
//monotonic
#define subtract {\
    in1[0]-=in2[1];\
    in1[1]-=in2[0];\
}
//???
//THIS IS NOT CORRECT! This is very hard to calculate, and as such the upper bound is over-estimated.
//However, it IS accurate if in2 is constant.
//EDIT: Actually, on further inspection, this may just be entirely incorrect. Who knows, frankly.
#define modulo {\
    temp[0]=in1[0]/in2[0];\
    temp[1]=in1[0]/in2[1];\
    temp[2]=in1[1]/in2[0];\
    temp[3]=in1[1]/in2[1];\
    mixer1=mix(mixer1,lessThan(min(temp[0],min(temp[1],min(temp[2],temp[3]))),zero),greaterThan(max(temp[0],max(temp[1],max(temp[2],temp[3]))),zero));\
    temp[0]=mod(in1[0],in2[0]);\
    temp[1]=mod(in1[0],in2[1]);\
    temp[2]=mod(in1[1],in2[0]);\
    temp[3]=mod(in1[1],in2[1]);\
    in1[0]=mix(min(temp[0],min(temp[1],min(temp[2],temp[3]))),zero,mixer1);\
    in1[1]=mix(max(temp[0],max(temp[1],max(temp[2],temp[3]))),highest,mixer1);\
}
//always monotonic for x>0
#define power {\
    temp[0]=pow(in1[0],in2[0]);\
    temp[1]=pow(in1[0],in2[1]);\
    temp[2]=pow(in1[1],in2[0]);\
    temp[3]=pow(in1[1],in2[1]);\
    in1[0]=min(temp[0],min(temp[1],min(temp[2],temp[3])));\
    in1[1]=max(temp[0],max(temp[1],max(temp[2],temp[3])));\
}
//handled
#define dist {\
    float out1[2];\
    mixer=mix(mixer,greaterThan(in1[1]-in2[0],zero),lessThan(in1[0]-in2[1],zero));\
    out1[0]=length(mix(min(abs(in1[0]-in2[1]),abs(in1[1]-in2[0])),zero,mixer));\
    out1[1]=length(max(abs(in1[0]-in2[1]),abs(in1[1]-in2[0])));\
}
//variable
#define dotprod {\
    float[2] out1;\
    float a=dot(in1[0],in2[0]);\
    float b=dot(in1[0],in2[1]);\
    float c=dot(in1[1],in2[0]);\
    float d=dot(in1[1],in2[1]);\
    out1[0]=min(a,min(b,min(c,d)));\
    out1[1]=max(a,max(b,max(c,d)));\
}
//monotonic
#define clampof {\
    in1[0]=clamp(in1[0],in2[0],in3[0]);\
    in1[1]=clamp(in1[1],in2[1],in3[1]);\
}
//monotonic
#define mixof {\
    in1[0]=mix(in1[0],in2[0],in3[0]);\
    in1[1]=mix(in1[1],in2[1],in3[1]);\
}
//monotonic
#define fmaof {\
    multiply;\
    in2=in3;\
    add;\
}
//variable
#define square {\
    mixer=mix(mixer,greaterThan(in1[1],zero),lessThan(in1[0],zero));\
    out1[0]=mix(min(in1[0]*in1[0],in1[1]*in1[1]),zero,mixer);\
    out1[1]=max(in1[0]*in1[0],in1[1]*in1[1]);\
}
//monotonic
#define cube {\
    out1[0]=in1[0]*in1[0]*in1[0];\
    out1[0]=in1[1]*in1[1]*in1[1];\
}
//mess
#define len {\
    float out1[2];\
    mixer=mix(mixer,greaterThan(in1[1],zero),lessThan(in1[0],zero));\
    out1[0]=length(mix(min(abs(in1[0]),abs(in1[1])),zero,mixer));\
    out1[1]=length(max(abs(in1[0]),abs(in1[1])));\
}
//monotonic
#define mattranspose {\
    in1[0]=transpose(in1[0]);\
    in1[1]=transpose(in1[1]);\
}
//unused
#define matdeterminant {\
    temp[0]=determinant(in1[0]);\
    temp[1]=determinant(in1[1]);\
    in1[0]=min(temp[0],temp[1]);\
    in1[1]=max(temp[0],temp[1]);\
}
//unused
#define matinvert {\
    temp[0]=inverse(in1[0]);\
    temp[1]=inverse(in1[1]);\
    in1[0]=min(temp[0],temp[1]);\
    in1[1]=max(temp[0],temp[1]);\
}
//handled
#define absolute {\
    mixer=mix(mixer,greaterThan(in1[1],zero),lessThan(in1[0],zero));\
    temp[0]=abs(in1[0]);\
    temp[1]=abs(in1[1]);\
    in1[0]=mix(min(temp[0],temp[1]),zero,mixer);\
    in1[1]=max(temp[0],temp[1]);\
}
//monotonic
#define signof {\
    in1[0]=sign(in1[0]);\
    in1[1]=sign(in1[1]);\
}
//monotonic
#define floorof {\
    in1[0]=floor(in1[0]);\
    in1[1]=floor(in1[1]);\
}
//monotonic
#define ceilingof {\
    in1[0]=ceil(in1[0]);\
    in1[1]=ceil(in1[1]);\
}
//handled
//If the integer component changes across the interval, then we've managed to hit 
//a discontinuity, and the max and min are constant.
//Otherwise, it's monotonic.
#define fractionalof {\
    mixer = equal(floor(in1[0]),floor(in1[1]));\
    in1[0]=mix(zero,fract(in1[0]),mixer);\
    in1[1]=mix(one,fract(in1[1]),mixer);\
}
//monotonic
#define squarerootof {\
    in1[0]=sqrt(in1[0]);\
    in1[1]=sqrt(in1[1]);\
}
//monotonic
#define inversesquarerootof {\
    temp[0]=inversesqrt(in1[0]);\
    in1[0]=inversesqrt(in1[1]);\
    in1[1]=temp[0];\
}
//monotonic
#define exponentof {\
    in1[0]=exp(in1[0]);\
    in1[1]=exp(in1[1]);\
}
//monotonic
#define exponent2of {\
    in1[0]=exp2(in1[0]);\
    in1[1]=exp2(in1[0]);\
}
//monotonic
#define logarithmof {\
    in1[0]=log(in1[0]);\
    in1[1]=log(in1[1]);\
}
//monotonic
#define logarithm2of {\
    in1[0]=log2(in1[0]);\
    in1[1]=log2(in1[1]);\
}
#define PI 3.1415926536
//handled
#define sineof {\
    mixer1=equal(floor((in1[0]/PI)+0.5),floor((in1[1]/PI)+0.5));\
    upper=mod(floor((in1[1]/PI)+0.5),2);\
    mixer2=greaterThan(floor((in1[1]/PI)+0.5)-floor((in1[0]/PI)+0.5),one);\
    temp[0]=sin(in1[0]);\
    temp[1]=sin(in1[1]);\
    in1[0]=mix(minusone,min(temp[0],temp[1]),mix(mix(equal(upper,one),vfalse,mixer2),vtrue,mixer1));\
    in1[1]=mix(one,max(temp[0],temp[1]),mix(mix(equal(upper,zero),vfalse,mixer2),vtrue,mixer1));\
}
//handled
#define cosineof {\
    mixer1=equal(floor((in1[0]/PI)),floor((in1[1]/PI)));\
    upper=mod(floor((in1[1]/PI)),2);\
    mixer2=greaterThan(floor((in1[1]/PI))-floor((in1[0]/PI)),one);\
    temp[0]=cos(in1[0]);\
    temp[1]=cos(in1[1]);\
    in1[0]=mix(minusone,min(temp[0],temp[1]),mix(mix(equal(upper,zero),vfalse,mixer2),vtrue,mixer1));\
    in1[1]=mix(one,max(temp[0],temp[1]),mix(mix(equal(upper,one),vfalse,mixer2),vtrue,mixer1));\
}
//handled
#define tangentof {\
    mixer1=equal(floor((in1[0]/PI)),floor((in1[1]/PI)));\
    in1[0]=mix(inf*-1.,tan(in1[0]),mixer1);\
    in1[1]=mix(inf,tan(in1[1]),mixer1);\
}
//monotonic
#define arcsineof {\
    in1[0]=asin(in1[0]);\
    in1[1]=asin(in1[1]);\
}
//negatively monotonic
#define arccosineof {\
    temp[0]=acos(in1[1]);\
    temp[1]=acos(in1[0]);\
    in1[0]=temp[0];\
    in1[1]=temp[1];\
}
//monotonic
#define arctangentof {\
    in1[0]=atan(in1[0]);\
    in1[1]=atan(in1[1]);\
}
//monotonic
#define hyperbolicsineof {\
    in1[0]=sinh(in1[0]);\
    in1[1]=sinh(in1[1]);\
}
//handled
#define hyperboliccosineof {\
    mixer=mix(mixer,greaterThan(in1[1],zero),lessThan(in1[0],zero));\
    out1[0]=mix(min(cosh(in1[0]),cosh(in1[1])),one,mixer);\
    out1[1]=max(cosh(in1[0]),cosh(in1[1]));\
}
//monotonic
#define hyperbolictangentof {\
    in1[0]=tanh(in1[0]);\
    in1[1]=tanh(in1[1]);\
}
//monotonic
#define hyperbolicarcsineof {\
    in1[0]=asinh(in1[0]);\
    in1[1]=asinh(in1[1]);\
}
//monotonic
#define hyperbolicarccosineof {\
    in1[0]=acosh(in1[0]);\
    in1[1]=acosh(in1[1]);\
}
//monotonic
#define hyperbolicarctangentof {\
    in1[0]=atanh(in1[0]);\
    in1[1]=atanh(in1[1]);\
}
//obvious
#define minimum {\
    in1[0]=min(in1[0],in2[0]);\
    in1[1]=min(in1[1],in2[1]);\
}
//obvious
#define maximum {\
    in1[0]=max(in1[0],in2[0]);\
    in1[1]=max(in1[1],in2[1]);\
}
//monotonic
#define roundof {\
    in1[0]=round(in1[0]);\
    in1[1]=round(in1[1]);\
}
//truncate
#define truncof {\
    in1[0]=trunc(in1[0]);\
    in1[1]=trunc(in1[1]);\
}

//0 - prune nothing
//1 - prune myself
//2 - prune myself and children
uint8_t pruneallchecks[(masklen*8)+1];

void pruneall (int pos) {
    uint8_t[2] deps;
    for (int i = pos-1; i >= 0; i--)
    {
        deps = depinfo.dependencies[desc.dependencies+i];
        if (deps[1] != 255) {
            switch (int((pruneallchecks[deps[0]] << 4) | (pruneallchecks[deps[1]] << 2) | (pruneallchecks[i] << 0)))
            {
                case ((2 << 4) | (2 << 2) | (2 << 0)):
                case ((2 << 4) | (1 << 2) | (2 << 0)):
                case ((2 << 4) | (0 << 2) | (2 << 0)):
                case ((1 << 4) | (2 << 2) | (2 << 0)):
                case ((1 << 4) | (1 << 2) | (2 << 0)):
                case ((1 << 4) | (0 << 2) | (2 << 0)):
                case ((0 << 4) | (2 << 2) | (2 << 0)):
                case ((0 << 4) | (1 << 2) | (2 << 0)):
                case ((0 << 4) | (0 << 2) | (2 << 0)):

                case ((2 << 4) | (2 << 2) | (1 << 0)):
                case ((2 << 4) | (2 << 2) | (0 << 0)):
                case ((2 << 4) | (1 << 2) | (1 << 0)):
                case ((1 << 4) | (2 << 2) | (1 << 0)):
                pruneallchecks[i]=uint8_t(2);
                mask[i>>3] &= uint8_t(~(1<<(i&7)));
                break;

                case ((2 << 4) | (1 << 2) | (0 << 0)):
                case ((2 << 4) | (0 << 2) | (0 << 0)):
                case ((1 << 4) | (2 << 2) | (0 << 0)):
                case ((0 << 4) | (2 << 2) | (0 << 0)):
                case ((0 << 4) | (0 << 2) | (1 << 0)):
                case ((1 << 4) | (1 << 2) | (1 << 0)):
                case ((2 << 4) | (0 << 2) | (1 << 0)):
                case ((0 << 4) | (2 << 2) | (1 << 0)):
                case ((0 << 4) | (1 << 2) | (1 << 0)):
                case ((1 << 4) | (0 << 2) | (1 << 0)):
                pruneallchecks[i]=uint8_t(1);
                mask[i>>3] &= uint8_t(~(1<<(i&7)));
                break;

                case ((1 << 4) | (1 << 2) | (0 << 0)):
                case ((1 << 4) | (0 << 2) | (0 << 0)):
                case ((0 << 4) | (1 << 2) | (0 << 0)):
                case ((0 << 4) | (0 << 2) | (0 << 0)):
                default:
                break;
            }
        }
        else if (pruneallchecks[i] > 0)
        {
            mask[i>>3] &= uint8_t(~(1<<(i&7)));
        }
        else if (pruneallchecks[deps[0]] > 1) {
            pruneallchecks[i]=uint8_t(2);
            mask[i>>3] &= uint8_t(~(1<<(i&7)));
        }
    }
}

void prunesome (int pos, bool prunemask[6]) {
    uint8_t[2] deps;
    int maskindex = 0;
    for (int i = 0; i < pos; i++)
    {
        deps = depinfo.dependencies[desc.dependencies+i];
        if (deps[1] != 255) {
            if (deps[0] == pos) {
                if (prunemask[maskindex++]) {
                    pruneallchecks[i]++;
                }
            }
            if (deps[1] == pos) {
                if (prunemask[maskindex++]) {
                    pruneallchecks[i]++;
                }
            }
            //pruneallchecks[i] = min(pruneallchecks[i],2);
        }
        else if (deps[0] == pos) {
            if (prunemask[maskindex++]) {
                pruneallchecks[i]=uint8_t(2);
            }
        }
    }
}

void passthroughself (int pos) {
    pruneallchecks[pos]=uint8_t(1);
}
void pruneself (int pos) {
    pruneallchecks[pos]=uint8_t(2);
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

#define minpruning if (prune) { if (all(lessThan(in1[1],in2[0]))) {\
    prunesome(OPPos,bool[6](true,false,false,false,false,false));\
    passthroughself(OPPos);\
} else if (all(lessThan(in2[1],in1[0]))) {\
    prunesome(OPPos,bool[6](false,true,false,false,false,false));\
    passthroughself(OPPos);\
}}

#define maxpruning if (prune) { if (all(greaterThan(in1[0],in2[1]))) {\
    prunesome(OPPos,bool[6](true,false,false,false,false,false));\
    passthroughself(OPPos);\
} else if (all(greaterThan(in2[0],in1[1]))) {\
    prunesome(OPPos,bool[6](false,true,false,false,false,false));\
    passthroughself(OPPos);\
}}

#ifdef debug
vec3 scene(vec3 p[2], bool prune)
#else
float[2]scene(vec3 p[2], bool prune)
#endif
{
    if (prune)
    {
        for (int i = 0; i<=(masklen*8); i++)
        pruneallchecks[i] = uint8_t(0);
    }
    //p[0]=p[0].yxz;
    //p[1]=p[1].yxz;
    uint major_position=0;
    uint minor_position=0;
    
    uint minor_integer_cache[8];

    desc = scene_description.desc[(DescriptionIndex)+1];
    
    clear_stacks();
    push_vec3(p);
    
    bool cont=true;
    
    while(cont){
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
                        float[2]in1=pull_float(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        add;
                        push_float(in1);
                    }
                    break;
                    case OPAddVec2Vec2:{
                        inputmask2(vec2_const_head,vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]in2=pull_vec2(ifconst(1));
                        add;
                        push_vec2(in1);
                    }
                    break;
                    case OPAddVec2Float:{
                        inputmask2(vec2_const_head,float_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        add;
                        push_vec2(in1);
                    }
                    break;
                    case OPAddVec3Vec3:{
                        inputmask2(vec3_const_head,vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        add;
                        push_vec3(in1);
                    }
                    break;
                    case OPAddVec3Float:{
                        inputmask2(vec3_const_head,float_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        add;
                        push_vec3(in1);
                    }
                    break;
                    case OPAddVec4Vec4:{
                        inputmask2(vec4_const_head,vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]in2=pull_vec4(ifconst(1));
                        add;
                        push_vec4(in1);
                    }
                    break;
                    case OPAddVec4Float:{
                        inputmask2(vec4_const_head,float_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        add;
                        push_vec4(in1);
                    }
                    break;
                    
                    case OPSubFloatFloat:{
                        inputmask2(float_const_head,float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        subtract;
                        push_float(in1);
                    }
                    break;
                    case OPSubVec2Vec2:{
                        inputmask2(vec2_const_head,vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]in2=pull_vec2(ifconst(1));
                        subtract;
                        push_vec2(in1);
                    }
                    break;
                    case OPSubVec2Float:{
                        inputmask2(vec2_const_head,float_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        subtract;
                        push_vec2(in1);
                    }
                    break;
                    case OPSubVec3Vec3:{
                        inputmask2(vec3_const_head,vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        subtract;
                        push_vec3(in1);
                    }
                    break;
                    case OPSubVec3Float:{
                        inputmask2(vec3_const_head,float_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        subtract;
                        push_vec3(in1);
                    }
                    break;
                    case OPSubVec4Vec4:{
                        inputmask2(vec4_const_head,vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]in2=pull_vec4(ifconst(1));
                        subtract;
                        push_vec4(in1);
                    }
                    break;
                    case OPSubVec4Float:{
                        inputmask2(vec4_const_head,float_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        subtract;
                        push_vec4(in1);
                    }
                    break;
                    
                    case OPMulFloatFloat:{
                        inputmask2(float_const_head,float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        float[4]temp;
                        multiply;
                        push_float(in1);
                    }
                    break;
                    case OPMulVec2Vec2:{
                        inputmask2(vec2_const_head,vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]in2=pull_vec2(ifconst(1));
                        vec2[4]temp;
                        multiply;
                        push_vec2(in1);
                    }
                    break;
                    case OPMulVec2Float:{
                        inputmask2(vec2_const_head,float_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        vec2[4]temp;
                        multiply;
                        push_vec2(in1);
                    }
                    break;
                    case OPMulVec3Vec3:{
                        inputmask2(vec3_const_head,vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        vec3[4]temp;
                        multiply;
                        push_vec3(in1);
                    }
                    break;
                    case OPMulVec3Float:{
                        inputmask2(vec3_const_head,float_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        vec3[4]temp;
                        multiply;
                        push_vec3(in1);
                    }
                    break;
                    case OPMulVec4Vec4:{
                        inputmask2(vec4_const_head,vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]in2=pull_vec4(ifconst(1));
                        vec4[4]temp;
                        multiply;
                        push_vec4(in1);
                    }
                    break;
                    case OPMulVec4Float:{
                        inputmask2(vec4_const_head,float_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        vec4[4]temp;
                        multiply;
                        push_vec4(in1);
                    }
                    break;
                    
                    case OPDivFloatFloat:{
                        inputmask2(float_const_head,float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        float[4]temp;
                        divide;
                        push_float(in1);
                    }
                    break;
                    case OPDivVec2Vec2:{
                        inputmask2(vec2_const_head,vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]in2=pull_vec2(ifconst(1));
                        vec2[4]temp;
                        divide;
                        push_vec2(in1);
                    }
                    break;
                    case OPDivVec2Float:{
                        inputmask2(vec2_const_head,float_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        vec2[4]temp;
                        divide;
                        push_vec2(in1);
                    }
                    break;
                    case OPDivVec3Vec3:{
                        inputmask2(vec3_const_head,vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        vec3[4]temp;
                        divide;
                        push_vec3(in1);
                    }
                    break;
                    case OPDivVec3Float:{
                        inputmask2(vec3_const_head,float_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        vec3[4]temp;
                        divide;
                        push_vec3(in1);
                    }
                    break;
                    case OPDivVec4Vec4:{
                        inputmask2(vec4_const_head,vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]in2=pull_vec4(ifconst(1));
                        vec4[4]temp;
                        divide;
                        push_vec4(in1);
                    }
                    break;
                    case OPDivVec4Float:{
                        inputmask2(vec4_const_head,float_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        vec4[4]temp;
                        divide;
                        push_vec4(in1);
                    }
                    break;
                    
                    case OPPowFloatFloat:{
                        inputmask2(float_const_head,float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        float[4]temp;
                        power;
                        push_float(in1);
                    }
                    break;
                    case OPPowVec2Vec2:{
                        inputmask2(vec2_const_head,vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]in2=pull_vec2(ifconst(1));
                        vec2[4]temp;
                        power;
                        push_vec2(in1);
                    }
                    break;
                    case OPPowVec3Vec3:{
                        inputmask2(vec3_const_head,vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        vec3[4]temp;
                        power;
                        push_vec3(in1);
                    }
                    break;
                    case OPPowVec4Vec4:{
                        inputmask2(vec4_const_head,vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]in2=pull_vec4(ifconst(1));
                        vec4[4]temp;
                        power;
                        push_vec4(in1);
                    }
                    break;
                    
                    case OPModFloatFloat:{
                        inputmask2(float_const_head,float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        float a=in1[0]/in2[0];
                        float b=in1[0]/in2[1];
                        float c=in1[1]/in2[0];
                        float d=in1[1]/in2[1];
                        if ((min(a,min(b,min(c,d))) < 0) && (max(a,max(b,max(c,d))) > 0))
                        {
                            in1[0]=0;
                            in1[1]=in2[1];
                        }
                        else {
                            a=mod(in1[0],in2[0]);
                            b=mod(in1[0],in2[1]);
                            c=mod(in1[1],in2[0]);
                            d=mod(in1[1],in2[1]);
                            in1[0]=min(a,min(b,min(c,d)));
                            in1[1]=max(a,max(b,max(c,d)));
                        }
                        push_float(in1);
                    }
                    break;
                    case OPModVec2Vec2:{
                        inputmask2(vec2_const_head,vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]in2=pull_vec2(ifconst(1));
                        vec2[4]temp;
                        bvec2 mixer1 = bvec2(false);
                        vec2 zero = vec2(0);
                        vec2 highest = in2[1];
                        modulo;
                        push_vec2(in1);
                    }
                    break;
                    case OPModVec2Float:{
                        inputmask2(vec2_const_head,float_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        vec2[4]temp;
                        bvec2 mixer1 = bvec2(false);
                        vec2 zero = vec2(0);
                        vec2 highest = vec2(in2[1]);
                        modulo;
                        push_vec2(in1);
                    }
                    break;
                    case OPModVec3Vec3:{
                        inputmask2(vec3_const_head,vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        vec3[4]temp;
                        bvec3 mixer1 = bvec3(false);
                        vec3 zero = vec3(0);
                        vec3 highest = in2[1];
                        modulo;
                        push_vec3(in1);
                    }
                    break;
                    case OPModVec3Float:{
                        inputmask2(vec3_const_head,float_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        vec3[4]temp;
                        bvec3 mixer1 = bvec3(false);
                        vec3 zero = vec3(0);
                        vec3 highest = vec3(in2[1]);
                        modulo;
                        push_vec3(in1);
                    }
                    break;
                    case OPModVec4Vec4:{
                        inputmask2(vec4_const_head,vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]in2=pull_vec4(ifconst(1));
                        vec4[4]temp;
                        bvec4 mixer1 = bvec4(false);
                        vec4 zero = vec4(0);
                        vec4 highest = in2[1];
                        modulo;
                        push_vec4(in1);
                    }
                    break;
                    case OPModVec4Float:{
                        inputmask2(vec4_const_head,float_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        vec4[4]temp;
                        bvec4 mixer1 = bvec4(false);
                        vec4 zero = vec4(0);
                        vec4 highest = vec4(in2[1]);
                        modulo;
                        push_vec4(in1);
                    }
                    break;


                    case OPCrossVec3:{
                        inputmask2(vec3_const_head,vec3_const_head);
                        /*#define getminmaxleft minleft = min(minleft, check); maxleft = max(maxleft, check);
                        #define getminmaxright minright = min(minright, check); maxright = max(maxright, check);
                        #define resetminmax minleft = 9999999999; minright = minleft; maxleft = -9999999999; maxright = maxleft;
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        vec3 outmax;
                        vec3 outmin;
                        float check;
                        float maxleft;
                        float minleft;
                        float maxright;
                        float minright;

                        resetminmax;
                        check = (in1[0].y*in2[0].z); getminmaxleft;
                        check = (in1[0].y*in2[1].z); getminmaxleft;
                        check = (in1[1].y*in2[0].z); getminmaxleft;
                        check = (in1[1].y*in2[1].z); getminmaxleft;
                        check = (in1[0].z*in2[0].y); getminmaxright;
                        check = (in1[0].z*in2[1].y); getminmaxright;
                        check = (in1[1].z*in2[0].y); getminmaxright;
                        check = (in1[1].z*in2[1].y); getminmaxright;

                        outmax.x = maxleft - minright; outmin.x = minleft - maxright;

                        resetminmax;
                        check = (in1[0].z*in2[0].x); getminmaxleft;
                        check = (in1[0].z*in2[1].x); getminmaxleft;
                        check = (in1[1].z*in2[0].x); getminmaxleft;
                        check = (in1[1].z*in2[1].x); getminmaxleft;
                        check = (in1[0].x*in2[0].z); getminmaxright;
                        check = (in1[0].x*in2[1].z); getminmaxright;
                        check = (in1[1].x*in2[0].z); getminmaxright;
                        check = (in1[1].x*in2[1].z); getminmaxright;

                        outmax.y = maxleft - minright; outmin.y = minleft - maxright;

                        resetminmax;
                        check = (in1[0].x*in2[0].y); getminmaxleft;
                        check = (in1[0].x*in2[1].y); getminmaxleft;
                        check = (in1[1].x*in2[0].y); getminmaxleft;
                        check = (in1[1].x*in2[1].y); getminmaxleft;
                        check = (in1[0].y*in2[0].x); getminmaxright;
                        check = (in1[0].y*in2[1].x); getminmaxright;
                        check = (in1[1].y*in2[0].x); getminmaxright;
                        check = (in1[1].y*in2[1].x); getminmaxright;

                        outmax.z = maxleft - minright; outmin.z = minleft - maxright;

                        push_vec3(vec3[2](outmin,outmax));*/

                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));

                        vec3 a=cross(in1[0],in2[0]);
                        vec3 b=cross(in1[0],in2[1]);
                        vec3 c=cross(in1[1],in2[0]);
                        vec3 d=cross(in1[1],in2[1]);

                        push_vec3(vec3[2](
                            min(a,min(b,min(c,d))),
                            max(a,max(b,max(c,d)))
                        ));
                    }
                    break;

                    case OPDotVec2:{
                        inputmask2(vec2_const_head,vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]in2=pull_vec2(ifconst(1));
                        float[2]out1;
                        dotprod;
                        push_float(out1);
                    }
                    break;
                    case OPDotVec3:{
                        inputmask2(vec3_const_head,vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        float[2]out1;
                        dotprod;
                        push_float(out1);
                    }
                    break;
                    case OPDotVec4:{
                        inputmask2(vec4_const_head,vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]in2=pull_vec4(ifconst(1));
                        float[2]out1;
                        dotprod;
                        push_float(out1);
                    }
                    break;

                    case OPLengthVec2:{
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        bvec2 mixer = bvec2(false);
                        vec2 zero = vec2(0);
                        float[2]out1;
                        len;
                        push_float(out1);
                    }
                    break;
                    case OPLengthVec3:{
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        bvec3 mixer = bvec3(false);
                        vec3 zero = vec3(0);
                        float[2]out1;
                        len;
                        push_float(out1);
                    }
                    break;
                    case OPLengthVec4:{
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        bvec4 mixer = bvec4(false);
                        vec4 zero = vec4(0);
                        float[2]out1;
                        len;
                        push_float(out1);
                    }
                    break;

                    case OPDistanceVec2:{
                        inputmask2(vec2_const_head,vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]in2=pull_vec2(ifconst(1));
                        bvec2 mixer = bvec2(false);
                        vec2 zero = vec2(0);
                        float[2]out1;
                        dist;
                        push_float(out1);
                    }
                    break;
                    case OPDistanceVec3:{
                        inputmask2(vec3_const_head,vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        bvec3 mixer = bvec3(false);
                        vec3 zero = vec3(0);
                        float[2]out1;
                        len;
                        push_float(out1);
                    }
                    break;
                    case OPDistanceVec4:{
                        inputmask2(vec4_const_head,vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]in2=pull_vec4(ifconst(1));
                        bvec4 mixer = bvec4(false);
                        vec4 zero = vec4(0);
                        float[2]out1;
                        dist;
                        push_float(out1);
                    }
                    break;

                    case OPAbsFloat: {
                        inputmask1(float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float a=abs(in1[0]);
                        float b=abs(in1[1]);
                        if ((in1[1] > 0) && (in1[0] < 0))
                        {
                            in1[0] = 0;
                        }
                        else
                        {
                        in1[0]=min(a,b);
                        }
                        in1[1]=max(a,b);
                        push_float(in1);
                    }
                    break;
                    case OPSignFloat: {
                        inputmask1(float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        signof;
                        push_float(in1);
                    }
                    break;
                    case OPFloorFloat: {
                        inputmask1(float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        floorof;
                        push_float(in1);
                    }
                    break;
                    case OPCeilFloat: {
                        inputmask1(float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        ceilingof;
                        push_float(in1);
                    }
                    break;
                    case OPFractFloat: {
                        inputmask1(float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        if (floor(in1[0]) == floor(in1[1])) {
                            in1[0] = fract(in1[0]);
                            in1[1] = fract(in1[1]);
                        }
                        else {
                            in1[0] = 0;
                            in1[1] = 1;
                        }
                        push_float(in1);
                    }
                    break;
                    case OPSqrtFloat: {
                        inputmask1(float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        squarerootof;
                        push_float(in1);
                    }
                    break;
                    case OPInverseSqrtFloat: {
                        inputmask1(float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        inversesquarerootof;
                        push_float(in1);
                    }
                    break;
                    case OPExpFloat: {
                        inputmask1(float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        exponentof;
                        push_float(in1);
                    }
                    break;
                    case OPExp2Float: {
                        inputmask1(float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        exponent2of;
                        push_float(in1);
                    }
                    break;
                    case OPLogFloat: {
                        inputmask1(float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        logarithmof;
                        push_float(in1);
                    }
                    break;
                    case OPLog2Float: {
                        inputmask1(float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        logarithm2of;
                        push_float(in1);
                    }
                    break;
                    case OPSinFloat: {
                        inputmask1(float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float a=sin(in1[0]);
                        float b=sin(in1[1]);
                        if (floor((in1[0]/PI)+0.5) == floor((in1[1]/PI)+0.5)) {
                            in1[0] = min(a,b);
                            in1[1] = max(a,b);
                        }
                        else if (floor((in1[1]/PI)+0.5)-floor((in1[0]/PI)+0.5) > 1)
                        {
                            in1[0] = -1;
                            in1[1] = 1;
                        }
                        else if (mod(floor((in1[1]/PI)+0.5),2) == 0) {
                            in1[0] = min(a,b);
                            in1[1] = 1;
                        }
                        else {
                            in1[0] = -1;
                            in1[1] = max(a,b);
                        }
                        push_float(in1);
                    }
                    break;
                    case OPCosFloat: {
                        inputmask1(float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float a=cos(in1[0]);
                        float b=cos(in1[1]);
                        if (floor((in1[0]/PI)) == floor((in1[1]/PI))) {
                            in1[0] = min(a,b);
                            in1[1] = max(a,b);
                        }
                        else if (floor((in1[1]/PI))-floor((in1[0]/PI)) > 1)
                        {
                            in1[0] = -1;
                            in1[1] = 1;
                        }
                        else if (mod(floor((in1[1]/PI)),2) == 1) {
                            in1[0] = min(a,b);
                            in1[1] = 1;
                        }
                        else {
                            in1[0] = -1;
                            in1[1] = max(a,b);
                        }
                        push_float(in1);
                    }
                    break;
                    case OPTanFloat: {
                        inputmask1(float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        if (floor((in1[0]/PI)) == floor((in1[1]/PI)))
                        {
                            in1[0] = NINFINITY;
                            in1[1] = INFINITY;
                        }
                        else {
                            in1[0] = tan(in1[0]);
                            in1[1] = tan(in1[1]);
                        }
                        push_float(in1);
                    }
                    break;
                    case OPAsinFloat: {
                        inputmask1(float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        arcsineof;
                        push_float(in1);
                    }
                    break;
                    case OPAcosFloat: {
                        inputmask1(float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        arccosineof;
                        push_float(in1);
                    }
                    break;
                    case OPAtanFloat: {
                        inputmask1(float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        arctangentof;
                        push_float(in1);
                    }
                    break;
                    case OPAcoshFloat:{
                        inputmask1(float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        hyperbolicarccosineof;
                        push_float(in1);
                    }
                    break;
                    case OPAsinhFloat:{
                        inputmask1(float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        hyperbolicarcsineof;
                        push_float(in1);
                    }
                    break;
                    case OPAtanhFloat:{
                        inputmask1(float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        hyperbolicarctangentof;
                        push_float(in1);
                    }
                    break;
                    case OPCoshFloat:{
                        inputmask1(float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        if ((in1[1] > 0) && (in1[0] < 0))
                        {
                            in1[0] = 1;
                        }
                        else {
                            in1[0] = min(cosh(in1[0]),cosh(in1[1]));
                        }
                        in1[1] = max(cosh(in1[0]),cosh(in1[1]));
                        push_float(in1);
                    }
                    break;
                    case OPSinhFloat:{
                        inputmask1(float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        hyperbolicsineof;
                        push_float(in1);
                    }
                    break;
                    case OPTanhFloat:{
                        inputmask1(float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        hyperbolictangentof;
                        push_float(in1);
                    }
                    break;
                    case OPRoundFloat:{
                        inputmask1(float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        roundof;
                        push_float(in1);
                    }
                    break;
                    case OPTruncFloat:{
                        inputmask1(float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        truncof;
                        push_float(in1);
                    }
                    break;
                    case OPMinMaterialFloat:
                    case OPMinFloat: {
                        inputmask2(float_const_head,float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        if (prune) {
                        if (in1[1] < in2[0])
                        {
                            //return float[2](-1,-1);
                            prunesome(OPPos,bool[6](true,false,false,false,false,false));
                            passthroughself(OPPos);
                        } else if (in2[1] < in1[0])
                        {
                            prunesome(OPPos,bool[6](false,true,false,false,false,false));
                            passthroughself(OPPos);
                        }}
                        float[2]temp;
                        minimum;
                        push_float(in1);
                    }
                    break;
                    case OPMaxMaterialFloat:
                    case OPMaxFloat: {
                        inputmask2(float_const_head,float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        if (prune) {
                        if (in1[0] > in2[1])
                        {
                            prunesome(OPPos,bool[6](true,false,false,false,false,false));
                            passthroughself(OPPos);
                        } else if (in2[0] > in1[1])
                        {
                            prunesome(OPPos,bool[6](false,true,false,false,false,false));
                            passthroughself(OPPos);
                        }}
                        float[2]temp;
                        maximum;
                        push_float(in1);
                    }
                    break;
                    case OPFMAFloat: {
                        inputmask3(float_const_head,float_const_head,float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        float[2]in3=pull_float(ifconst(2));
                        float[4]temp;
                        fmaof;
                        push_float(in1);
                    }
                    break;

                    case OPAbsVec2: {
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        bvec2 mixer = bvec2(false);
                        vec2 zero = vec2(0);
                        absolute;
                        push_vec2(in1);
                    }
                    break;
                    case OPSignVec2: {
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        signof;
                        push_vec2(in1);
                    }
                    break;
                    case OPFloorVec2: {
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        floorof;
                        push_vec2(in1);
                    }
                    break;
                    case OPCeilVec2: {
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        ceilingof;
                        push_vec2(in1);
                    }
                    break;
                    case OPFractVec2: {
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        bvec2 mixer = bvec2(false);
                        vec2 zero = vec2(0);
                        vec2 one = vec2(1);
                        fractionalof;
                        push_vec2(in1);
                    }
                    break;
                    case OPSqrtVec2: {
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        squarerootof;
                        push_vec2(in1);
                    }
                    break;
                    case OPInverseSqrtVec2: {
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        inversesquarerootof;
                        push_vec2(in1);
                    }
                    break;
                    case OPExpVec2: {
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        exponentof;
                        push_vec2(in1);
                    }
                    break;
                    case OPExp2Vec2: {
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        exponent2of;
                        push_vec2(in1);
                    }
                    break;
                    case OPLogVec2: {
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        logarithmof;
                        push_vec2(in1);
                    }
                    break;
                    case OPLog2Vec2: {
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        logarithm2of;
                        push_vec2(in1);
                    }
                    break;
                    case OPSinVec2: {
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        bvec2 mixer1 = bvec2(false);
                        bvec2 mixer2 = bvec2(false);
                        bvec2 vfalse = bvec2(false);
                        bvec2 vtrue = bvec2(true);
                        vec2 upper;
                        vec2 one = vec2(1);
                        vec2 zero = vec2(0);
                        vec2 minusone = vec2(-1);
                        sineof;
                        push_vec2(in1);
                    }
                    break;
                    case OPCosVec2: {
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        bvec2 mixer1 = bvec2(false);
                        bvec2 mixer2 = bvec2(false);
                        bvec2 vfalse = bvec2(false);
                        bvec2 vtrue = bvec2(true);
                        vec2 upper;
                        vec2 one = vec2(1);
                        vec2 zero = vec2(0);
                        vec2 minusone = vec2(-1);
                        cosineof;
                        push_vec2(in1);
                    }
                    break;
                    case OPTanVec2: {
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        bvec2 mixer1 = bvec2(false);
                        vec2 inf = vec2(INFINITY);
                        tangentof;
                        push_vec2(in1);
                    }
                    break;
                    case OPAsinVec2: {
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        arcsineof;
                        push_vec2(in1);
                    }
                    break;
                    case OPAcosVec2: {
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        arccosineof;
                        push_vec2(in1);
                    }
                    break;
                    case OPAtanVec2: {
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        arctangentof;
                        push_vec2(in1);
                    }
                    break;
                    case OPAcoshVec2:{
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        hyperbolicarccosineof;
                        push_vec2(in1);
                    }
                    break;
                    case OPAsinhVec2:{
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        hyperbolicarcsineof;
                        push_vec2(in1);
                    }
                    break;
                    case OPAtanhVec2:{
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        hyperbolicarctangentof;
                        push_vec2(in1);
                    }
                    break;
                    case OPCoshVec2:{
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        bvec2 mixer = bvec2(false);
                        vec2 one = vec2(1);
                        vec2 zero = vec2(0);
                        vec2[2] out1;
                        hyperboliccosineof;
                        push_vec2(out1);
                    }
                    break;
                    case OPSinhVec2:{
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        hyperbolicsineof;
                        push_vec2(in1);
                    }
                    break;
                    case OPTanhVec2:{
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        hyperbolictangentof;
                        push_vec2(in1);
                    }
                    break;
                    case OPRoundVec2:{
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        roundof;
                        push_vec2(in1);
                    }
                    break;
                    case OPTruncVec2:{
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        truncof;
                        push_vec2(in1);
                    }
                    break;
                    case OPMinVec2: {
                        inputmask2(vec2_const_head,vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]in2=pull_vec2(ifconst(1));
                        minpruning;
                        vec2[2]temp;
                        minimum;
                        push_vec2(in1);
                    }
                    break;
                    case OPMaxVec2: {
                        inputmask2(vec2_const_head,vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]in2=pull_vec2(ifconst(1));
                        maxpruning;
                        vec2[2]temp;
                        maximum;
                        push_vec2(in1);
                    }
                    break;
                    case OPFMAVec2: {
                        inputmask3(vec2_const_head,vec2_const_head,vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]in2=pull_vec2(ifconst(1));
                        vec2[2]in3=pull_vec2(ifconst(2));
                        vec2[4]temp;
                        fmaof;
                        push_vec2(in1);
                    }
                    break;

                    case OPAbsVec3: {
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        bvec3 mixer = bvec3(false);
                        vec3 zero = vec3(0);
                        absolute;
                        push_vec3(in1);
                    }
                    break;
                    case OPSignVec3: {
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        signof;
                        push_vec3(in1);
                    }
                    break;
                    case OPFloorVec3: {
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        floorof;
                        push_vec3(in1);
                    }
                    break;
                    case OPCeilVec3: {
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        ceilingof;
                        push_vec3(in1);
                    }
                    break;
                    case OPFractVec3: {
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        bvec3 mixer = bvec3(false);
                        vec3 zero = vec3(0);
                        vec3 one = vec3(1);
                        fractionalof;
                        push_vec3(in1);
                    }
                    break;
                    case OPSqrtVec3: {
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        squarerootof;
                        push_vec3(in1);
                    }
                    break;
                    case OPInverseSqrtVec3: {
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        inversesquarerootof;
                        push_vec3(in1);
                    }
                    break;
                    case OPExpVec3: {
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        exponentof;
                        push_vec3(in1);
                    }
                    break;
                    case OPExp2Vec3: {
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        exponent2of;
                        push_vec3(in1);
                    }
                    break;
                    case OPLogVec3: {
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        logarithmof;
                        push_vec3(in1);
                    }
                    break;
                    case OPLog2Vec3: {
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        logarithm2of;
                        push_vec3(in1);
                    }
                    break;
                    case OPSinVec3: {
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        bvec3 mixer1 = bvec3(false);
                        bvec3 mixer2 = bvec3(false);
                        bvec3 vfalse = bvec3(false);
                        bvec3 vtrue = bvec3(true);
                        vec3 upper;
                        vec3 one = vec3(1);
                        vec3 zero = vec3(0);
                        vec3 minusone = vec3(-1);
                        sineof;
                        push_vec3(in1);
                    }
                    break;
                    case OPCosVec3: {
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        bvec3 mixer1 = bvec3(false);
                        bvec3 mixer2 = bvec3(false);
                        bvec3 vfalse = bvec3(false);
                        bvec3 vtrue = bvec3(true);
                        vec3 upper;
                        vec3 one = vec3(1);
                        vec3 zero = vec3(0);
                        vec3 minusone = vec3(-1);
                        cosineof;
                        push_vec3(in1);
                    }
                    break;
                    case OPTanVec3: {
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        bvec3 mixer1 = bvec3(false);
                        vec3 inf = vec3(INFINITY);
                        tangentof;
                        push_vec3(in1);
                    }
                    break;
                    case OPAsinVec3: {
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        arcsineof;
                        push_vec3(in1);
                    }
                    break;
                    case OPAcosVec3: {
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        arccosineof;
                        push_vec3(in1);
                    }
                    break;
                    case OPAtanVec3: {
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        arctangentof;
                        push_vec3(in1);
                    }
                    break;
                    case OPAcoshVec3:{
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        hyperbolicarccosineof;
                        push_vec3(in1);
                    }
                    break;
                    case OPAsinhVec3:{
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        hyperbolicarcsineof;
                        push_vec3(in1);
                    }
                    break;
                    case OPAtanhVec3:{
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        hyperbolicarctangentof;
                        push_vec3(in1);
                    }
                    break;
                    case OPCoshVec3:{
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        bvec3 mixer = bvec3(false);
                        vec3 one = vec3(1);
                        vec3 zero = vec3(0);
                        vec3[2] out1;
                        hyperboliccosineof;
                        push_vec3(out1);
                    }
                    break;
                    case OPSinhVec3:{
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        hyperbolicsineof;
                        push_vec3(in1);
                    }
                    break;
                    case OPTanhVec3:{
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        hyperbolictangentof;
                        push_vec3(in1);
                    }
                    break;
                    case OPRoundVec3:{
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        roundof;
                        push_vec3(in1);
                    }
                    break;
                    case OPTruncVec3:{
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        truncof;
                        push_vec3(in1);
                    }
                    break;
                    case OPMinVec3: {
                        inputmask2(vec3_const_head,vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        minpruning;
                        vec3[2]temp;
                        minimum;
                        push_vec3(in1);
                    }
                    break;
                    case OPMaxVec3: {
                        inputmask2(vec3_const_head,vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        maxpruning;
                        vec3[2]temp;
                        maximum;
                        push_vec3(in1);
                    }
                    break;
                    case OPFMAVec3: {
                        inputmask3(vec3_const_head,vec3_const_head,vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        vec3[2]in3=pull_vec3(ifconst(2));
                        vec3[4]temp;
                        fmaof;
                        push_vec3(in1);
                    }
                    break;

                    case OPAbsVec4: {
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        bvec4 mixer = bvec4(false);
                        vec4 zero = vec4(0);
                        absolute;
                        push_vec4(in1);
                    }
                    break;
                    case OPSignVec4: {
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        signof;
                        push_vec4(in1);
                    }
                    break;
                    case OPFloorVec4: {
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        floorof;
                        push_vec4(in1);
                    }
                    break;
                    case OPCeilVec4: {
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        ceilingof;
                        push_vec4(in1);
                    }
                    break;
                    case OPFractVec4: {
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        bvec4 mixer = bvec4(false);
                        vec4 zero = vec4(0);
                        vec4 one = vec4(1);
                        fractionalof;
                        push_vec4(in1);
                    }
                    break;
                    case OPSqrtVec4: {
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        squarerootof;
                        push_vec4(in1);
                    }
                    break;
                    case OPInverseSqrtVec4: {
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        inversesquarerootof;
                        push_vec4(in1);
                    }
                    break;
                    case OPExpVec4: {
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        exponentof;
                        push_vec4(in1);
                    }
                    break;
                    case OPExp2Vec4: {
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        exponent2of;
                        push_vec4(in1);
                    }
                    break;
                    case OPLogVec4: {
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        logarithmof;
                        push_vec4(in1);
                    }
                    break;
                    case OPLog2Vec4: {
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        logarithm2of;
                        push_vec4(in1);
                    }
                    break;
                    case OPSinVec4: {
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        bvec4 mixer1 = bvec4(false);
                        bvec4 mixer2 = bvec4(false);
                        bvec4 vfalse = bvec4(false);
                        bvec4 vtrue = bvec4(true);
                        vec4 upper;
                        vec4 one = vec4(1);
                        vec4 zero = vec4(0);
                        vec4 minusone = vec4(-1);
                        sineof;
                        push_vec4(in1);
                    }
                    break;
                    case OPCosVec4: {
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        bvec4 mixer1 = bvec4(false);
                        bvec4 mixer2 = bvec4(false);
                        bvec4 vfalse = bvec4(false);
                        bvec4 vtrue = bvec4(true);
                        vec4 upper;
                        vec4 one = vec4(1);
                        vec4 zero = vec4(0);
                        vec4 minusone = vec4(-1);
                        cosineof;
                        push_vec4(in1);
                    }
                    break;
                    case OPTanVec4: {
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        bvec4 mixer1 = bvec4(false);
                        vec4 inf = vec4(INFINITY);
                        tangentof;
                        push_vec4(in1);
                    }
                    break;
                    case OPAsinVec4: {
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        arcsineof;
                        push_vec4(in1);
                    }
                    break;
                    case OPAcosVec4: {
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        arccosineof;
                        push_vec4(in1);
                    }
                    break;
                    case OPAtanVec4: {
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        arctangentof;
                        push_vec4(in1);
                    }
                    break;
                    case OPAcoshVec4:{
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        hyperbolicarccosineof;
                        push_vec4(in1);
                    }
                    break;
                    case OPAsinhVec4:{
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        hyperbolicarcsineof;
                        push_vec4(in1);
                    }
                    break;
                    case OPAtanhVec4:{
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        hyperbolicarctangentof;
                        push_vec4(in1);
                    }
                    break;
                    case OPCoshVec4:{
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        bvec4 mixer = bvec4(false);
                        vec4 one = vec4(1);
                        vec4 zero = vec4(0);
                        vec4[2] out1;
                        hyperboliccosineof;
                        push_vec4(out1);
                    }
                    break;
                    case OPSinhVec4:{
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        hyperbolicsineof;
                        push_vec4(in1);
                    }
                    break;
                    case OPTanhVec4:{
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        hyperbolictangentof;
                        push_vec4(in1);
                    }
                    break;
                    case OPRoundVec4:{
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        roundof;
                        push_vec4(in1);
                    }
                    break;
                    case OPTruncVec4:{
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        truncof;
                        push_vec4(in1);
                    }
                    break;
                    case OPMinVec4: {
                        inputmask2(vec4_const_head,vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]in2=pull_vec4(ifconst(1));
                        minpruning;
                        vec4[2]temp;
                        minimum;
                        push_vec4(in1);
                    }
                    break;
                    case OPMaxVec4: {
                        inputmask2(vec4_const_head,vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]in2=pull_vec4(ifconst(1));
                        maxpruning;
                        vec4[2]temp;
                        maximum;
                        push_vec4(in1);
                    }
                    break;
                    case OPFMAVec4: {
                        inputmask3(vec4_const_head,vec4_const_head,vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]in2=pull_vec4(ifconst(1));
                        vec4[2]in3=pull_vec4(ifconst(2));
                        vec4[4]temp;
                        fmaof;
                        push_vec4(in1);
                    }
                    break;

                    case OPClampFloatFloat:{
                        inputmask3(float_const_head,float_const_head,float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        float[2]in3=pull_float(ifconst(2));
                        clampof;
                        push_float(in1);
                    }
                    break;
                    case OPMixFloatFloat:{
                        inputmask3(float_const_head,float_const_head,float_const_head);
                        float[2]in1=pull_float(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        float[2]in3=pull_float(ifconst(2));
                        mixof;
                        push_float(in1);
                    }
                    break;
                    case OPClampVec2Vec2:{
                        inputmask3(vec2_const_head,vec2_const_head,vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]in2=pull_vec2(ifconst(1));
                        vec2[2]in3=pull_vec2(ifconst(2));
                        clampof;
                        push_vec2(in1);
                    }
                    break;
                    case OPMixVec2Vec2:{
                        inputmask3(vec2_const_head,vec2_const_head,vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]in2=pull_vec2(ifconst(1));
                        vec2[2]in3=pull_vec2(ifconst(2));
                        mixof;
                        push_vec2(in1);
                    }
                    break;
                    case OPClampVec2Float:{
                        inputmask3(vec2_const_head,float_const_head,float_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        float[2]in3=pull_float(ifconst(2));
                        clampof;
                        push_vec2(in1);
                    }
                    break;
                    case OPMixVec2Float:{
                        inputmask3(vec2_const_head,vec2_const_head,float_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]in2=pull_vec2(ifconst(1));
                        float[2]in3=pull_float(ifconst(2));
                        mixof;
                        push_vec2(in1);
                    }
                    break;
                    case OPClampVec3Vec3:{
                        inputmask3(vec3_const_head,vec3_const_head,vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        vec3[2]in3=pull_vec3(ifconst(2));
                        clampof;
                        push_vec3(in1);
                    }
                    break;
                    case OPMixVec3Vec3:{
                        inputmask3(vec3_const_head,vec3_const_head,vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        vec3[2]in3=pull_vec3(ifconst(2));
                        mixof;
                        push_vec3(in1);
                    }
                    break;
                    case OPClampVec3Float:{
                        inputmask3(vec3_const_head,float_const_head,float_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        float[2]in3=pull_float(ifconst(2));
                        clampof;
                        push_vec3(in1);
                    }
                    break;
                    case OPMixVec3Float:{
                        inputmask3(vec3_const_head,vec3_const_head,float_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        float[2]in3=pull_float(ifconst(2));
                        mixof;
                        push_vec3(in1);
                    }
                    break;
                    case OPClampVec4Vec4:{
                        inputmask3(vec4_const_head,vec4_const_head,vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]in2=pull_vec4(ifconst(1));
                        vec4[2]in3=pull_vec4(ifconst(2));
                        clampof;
                        push_vec4(in1);
                    }
                    break;
                    case OPMixVec4Vec4:{
                        inputmask3(vec4_const_head,vec4_const_head,vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]in2=pull_vec4(ifconst(1));
                        vec4[2]in3=pull_vec4(ifconst(2));
                        mixof;
                        push_vec4(in1);
                    }
                    break;
                    case OPClampVec4Float:{
                        inputmask3(vec4_const_head,float_const_head,float_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        float[2]in3=pull_float(ifconst(2));
                        clampof;
                        push_vec4(in1);
                    }
                    break;
                    case OPMixVec4Float:{
                        inputmask3(vec4_const_head,vec4_const_head,float_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]in2=pull_vec4(ifconst(1));
                        float[2]in3=pull_float(ifconst(2));
                        mixof;
                        push_vec4(in1);
                    }
                    break;
                    
                    case OPNormalizeVec2:{
                        inputmask1(vec2_const_head);
                        vec2[2]in1=pull_vec2(ifconst(0));
                        bvec2 mixer=mix(bvec2(false),greaterThan(in1[1],vec2(0)),lessThan(in1[0],vec2(0)));
                        vec2 smallest=mix(min(abs(in1[0]),abs(in1[1])),vec2(0),mixer);
                        vec2 largest=max(abs(in1[0]),abs(in1[1]));
                        vec2 outmax=max(vec2(
                                in1[1].x/length(vec2(in1[1].x,smallest.y)),
                                in1[1].y/length(vec2(smallest.x,in1[1].y))
                            ),
                            vec2(
                                in1[1].x/length(vec2(in1[1].x,largest.y)),
                                in1[1].y/length(vec2(largest.x,in1[1].y))
                            )
                        );
                        vec2 outmin=min(vec2(
                                in1[0].x/length(vec2(in1[0].x,smallest.y)),
                                in1[0].y/length(vec2(smallest.x,in1[0].y))
                            ),
                            vec2(
                                in1[0].x/length(vec2(in1[0].x,largest.y)),
                                in1[0].y/length(vec2(largest.x,in1[0].y))
                            )
                        );
                        push_vec2(vec2[2](outmin,outmax));
                    }
                    break;
                    case OPNormalizeVec3:{
                        inputmask1(vec3_const_head);
                        vec3[2]in1=pull_vec3(ifconst(0));
                        bvec3 mixer=mix(bvec3(false),greaterThan(in1[1],vec3(0)),lessThan(in1[0],vec3(0)));
                        vec3 smallest=mix(min(abs(in1[0]),abs(in1[1])),vec3(0),mixer);
                        vec3 largest=max(abs(in1[0]),abs(in1[1]));
                        vec3 outmax=max(vec3(
                                in1[1].x/length(vec3(in1[1].x,smallest.y,smallest.z)),
                                in1[1].y/length(vec3(smallest.x,in1[1].y,smallest.z)),
                                in1[1].z/length(vec3(smallest.x,smallest.y,in1[1].z))
                            ),
                            vec3(
                                in1[1].x/length(vec3(in1[1].x,largest.y,largest.z)),
                                in1[1].y/length(vec3(largest.x,in1[1].y,largest.z)),
                                in1[1].z/length(vec3(largest.x,largest.y,in1[1].z))
                            )
                        );
                        vec3 outmin=min(vec3(
                                in1[0].x/length(vec3(in1[0].x,smallest.y,smallest.z)),
                                in1[0].y/length(vec3(smallest.x,in1[0].y,smallest.z)),
                                in1[0].z/length(vec3(smallest.x,smallest.y,in1[0].z))
                            ),
                            vec3(
                                in1[0].x/length(vec3(in1[0].x,largest.y,largest.z)),
                                in1[0].y/length(vec3(largest.x,in1[0].y,largest.z)),
                                in1[0].z/length(vec3(largest.x,largest.y,in1[0].z))
                            )
                        );
                        push_vec3(vec3[2](outmin,outmax));
                    }
                    break;
                    case OPNormalizeVec4:{
                        inputmask1(vec4_const_head);
                        vec4[2]in1=pull_vec4(ifconst(0));
                        bvec4 mixer=mix(bvec4(false),greaterThan(in1[1],vec4(0)),lessThan(in1[0],vec4(0)));
                        vec4 smallest=mix(min(abs(in1[0]),abs(in1[1])),vec4(0),mixer);
                        vec4 largest=max(abs(in1[0]),abs(in1[1]));
                        vec4 outmax=max(vec4(
                                in1[1].x/length(vec4(in1[1].x,smallest.y,smallest.z,smallest.w)),
                                in1[1].y/length(vec4(smallest.x,in1[1].y,smallest.z,smallest.w)),
                                in1[1].z/length(vec4(smallest.x,smallest.y,in1[1].z,smallest.w)),
                                in1[1].w/length(vec4(smallest.x,smallest.y,smallest.z,in1[1].w))
                            ),
                            vec4(
                                in1[1].x/length(vec4(in1[1].x,largest.y,largest.z,largest.w)),
                                in1[1].y/length(vec4(largest.x,in1[1].y,largest.z,largest.w)),
                                in1[1].z/length(vec4(largest.x,largest.y,in1[1].z,largest.w)),
                                in1[1].w/length(vec4(largest.x,largest.y,largest.z,in1[1].w))
                            )
                        );
                        vec4 outmin=min(vec4(
                                in1[0].x/length(vec4(in1[0].x,smallest.y,smallest.z,smallest.w)),
                                in1[0].y/length(vec4(smallest.x,in1[0].y,smallest.z,smallest.w)),
                                in1[0].z/length(vec4(smallest.x,smallest.y,in1[0].z,smallest.w)),
                                in1[0].w/length(vec4(smallest.x,smallest.y,smallest.z,in1[0].w))
                            ),
                            vec4(
                                in1[0].x/length(vec4(in1[0].x,largest.y,largest.z,largest.w)),
                                in1[0].y/length(vec4(largest.x,in1[0].y,largest.z,largest.w)),
                                in1[0].z/length(vec4(largest.x,largest.y,in1[0].z,largest.w)),
                                in1[0].w/length(vec4(largest.x,largest.y,largest.z,in1[0].w))
                            )
                        );
                        push_vec4(vec4[2](outmin,outmax));
                    }
                    break;

                    case OPPromoteFloatFloatVec2:{
                        inputmask2(float_const_head,float_const_head);
                        float[2] a = pull_float(ifconst(0));
                        float[2] b = pull_float(ifconst(1));
                        push_vec2(vec2[2](vec2(a[0],b[0]),vec2(a[1],b[1])));
                    }
                    break;
                    case OPPromoteFloatFloatFloatVec3:{
                        inputmask3(float_const_head,float_const_head,float_const_head);
                        float[2] a = pull_float(ifconst(0));
                        float[2] b = pull_float(ifconst(1));
                        float[2] c = pull_float(ifconst(2));
                        push_vec3(vec3[2](vec3(a[0],b[0],c[0]),vec3(a[1],b[1],c[1])));
                    }
                    break;
                    case OPPromoteVec2FloatVec3:{
                        inputmask2(vec2_const_head,float_const_head);
                        vec2[2] a = pull_vec2(ifconst(0));
                        float[2] b = pull_float(ifconst(1));
                        push_vec3(vec3[2](vec3(a[0],b[0]),vec3(a[1],b[1])));
                    }
                    break;
                    case OPPromoteFloatFloatFloatFloatVec4:{
                        inputmask4(float_const_head,float_const_head,float_const_head,float_const_head);
                        float[2] a = pull_float(ifconst(0));
                        float[2] b = pull_float(ifconst(1));
                        float[2] c = pull_float(ifconst(2));
                        float[2] d = pull_float(ifconst(3));
                        push_vec4(vec4[2](vec4(a[0],b[0],c[0],d[0]),vec4(a[1],b[1],c[1],d[1])));
                    }
                    break;
                    case OPPromoteVec2FloatFloatVec4:{
                        inputmask3(vec2_const_head,float_const_head,float_const_head);
                        vec2[2] a = pull_vec2(ifconst(0));
                        float[2] b = pull_float(ifconst(1));
                        float[2] c = pull_float(ifconst(2));
                        push_vec4(vec4[2](vec4(a[0],b[0],c[0]),vec4(a[1],b[1],c[1])));
                    }
                    break;
                    case OPPromoteVec3FloatVec4:{
                        inputmask2(vec3_const_head,float_const_head);
                        vec3[2] a = pull_vec3(ifconst(0));
                        float[2] b = pull_float(ifconst(1));
                        push_vec4(vec4[2](vec4(a[0],b[0]),vec4(a[1],b[1])));
                    }
                    break;
                    case OPPromoteVec2Vec2Vec4:{
                        inputmask2(vec2_const_head,vec2_const_head);
                        vec2[2] a = pull_vec2(ifconst(0));
                        vec2[2] b = pull_vec2(ifconst(1));
                        push_vec4(vec4[2](vec4(a[0],b[0]),vec4(a[1],b[1])));
                    }
                    break;

                    /*
                    case OPDemoteMat2Float:{
                    mat2[2] mat2temp=pull_mat2(ifconst(0));
                    push_float(float[2](mat2temp[0][1].y,mat2temp[1][1].y));
                    push_float(float[2](mat2temp[0][1].x,mat2temp[1][1].x));
                    push_float(float[2](mat2temp[0][0].y,mat2temp[1][0].y));
                    push_float(float[2](mat2temp[0][0].x,mat2temp[1][0].x));
                    }
                    break;
                    case OPDemoteMat2Vec2:{
                    mat2[2] mat2temp=pull_mat2(ifconst(0));
                    push_vec2(vec2[2](mat2temp[0][1],mat2temp[1][1]));
                    push_vec2(vec2[2](mat2temp[0][0],mat2temp[1][0]));
                    }
                    break;
                    case OPDemoteMat3Vec3:{
                    mat3[2] mat3temp=pull_mat3(ifconst(0));
                    push_vec3(vec3[2](mat3temp[0][2],mat3temp[1][2]));
                    push_vec3(vec3[2](mat3temp[0][1],mat3temp[1][1]));
                    push_vec3(vec3[2](mat3temp[0][0],mat3temp[1][0]));
                    }
                    break;
                    case OPDemoteMat4Vec4:{
                    mat4[2] mat4temp=pull_mat4(ifconst(0));
                    push_vec4(vec4[2](mat4temp[0][3],mat4temp[1][3]));
                    push_vec4(vec4[2](mat4temp[0][2],mat4temp[1][2]));
                    push_vec4(vec4[2](mat4temp[0][1],mat4temp[1][1]));
                    push_vec4(vec4[2](mat4temp[0][0],mat4temp[1][0]));
                    }
                    break;
                    case OPDemoteMat2Vec4:{
                    mat2[2] mat2temp=pull_mat2(ifconst(0));
                    push_vec4(vec4[2](vec4(mat2temp[0][0],mat2temp[0][1]),vec4(mat2temp[1][0],mat2temp[1][1])));
                    }
                    break;
                    case OPDemoteVec2FloatFloat:{
                    vec2[2] vec2temp=pull_vec2(ifconst(0));
                    push_float(float[2](vec2temp[0].y,vec2temp[1].y));
                    push_float(float[2](vec2temp[0].x,vec2temp[1].x));
                    }
                    break;
                    case OPDemoteVec3FloatFloatFloat:{
                    vec3[2] vec3temp=pull_vec3(ifconst(0));
                    push_float(float[2](vec3temp[0].z,vec3temp[1].z));
                    push_float(float[2](vec3temp[0].y,vec3temp[1].y));
                    push_float(float[2](vec3temp[0].x,vec3temp[1].x));
                    }
                    break;
                    case OPDemoteVec4FloatFloatFloatFloat:{
                    vec4[2] vec4temp=pull_vec4(ifconst(0));
                    push_float(float[2](vec4temp[0].w,vec4temp[1].w));
                    push_float(float[2](vec4temp[0].z,vec4temp[1].z));
                    push_float(float[2](vec4temp[0].y,vec4temp[1].y));
                    push_float(float[2](vec4temp[0].x,vec4temp[1].x));
                    }
                    break;
                    */

                    case OPSquareFloat:{
                        inputmask1(float_const_head);
                        float[2] in1 = pull_float(ifconst(0));
                        float[2] out1;
                        if (in1[1] > 0 && in1[0] < 0)
                        {
                            out1[0] = 0;
                        }
                        else {
                            out1[0] = min(in1[0]*in1[0],in1[1]*in1[1]);
                        }
                        out1[1]=max(in1[0]*in1[0],in1[1]*in1[1]);
                        push_float(out1);
                    }
                    break;
                    case OPCubeFloat:{
                        inputmask1(float_const_head);
                        float[2] in1 = pull_float(ifconst(0));
                        float[2] out1;
                        bool mixer = false;
                        float zero = 0;
                        cube;
                        push_float(out1);
                    }
                    break;
                    case OPSquareVec2:{
                        inputmask1(vec2_const_head);
                        vec2[2] in1 = pull_vec2(ifconst(0));
                        vec2[2] out1;
                        bvec2 mixer = bvec2(false);
                        vec2 zero = vec2(0);
                        square;
                        push_vec2(out1);
                    }
                    break;
                    case OPCubeVec2:{
                        inputmask1(vec2_const_head);
                        vec2[2] in1 = pull_vec2(ifconst(0));
                        vec2[2] out1;
                        bvec2 mixer = bvec2(false);
                        vec2 zero = vec2(0);
                        cube;
                        push_vec2(out1);
                    }
                    break;
                    case OPSquareVec3:{
                        inputmask1(vec3_const_head);
                        vec3[2] in1 = pull_vec3(ifconst(0));
                        vec3[2] out1;
                        bvec3 mixer = bvec3(false);
                        vec3 zero = vec3(0);
                        square;
                        push_vec3(out1);
                    }
                    break;
                    case OPCubeVec3:{
                        inputmask1(vec3_const_head);
                        vec3[2] in1 = pull_vec3(ifconst(0));
                        vec3[2] out1;
                        bvec3 mixer = bvec3(false);
                        vec3 zero = vec3(0);
                        cube;
                        push_vec3(out1);
                    }
                    break;
                    case OPSquareVec4:{
                        inputmask1(vec4_const_head);
                        vec4[2] in1 = pull_vec4(ifconst(0));
                        vec4[2] out1;
                        bvec4 mixer = bvec4(false);
                        vec4 zero = vec4(0);
                        square;
                        push_vec4(out1);
                    }
                    break;
                    case OPCubeVec4:{
                        inputmask1(vec4_const_head);
                        vec4[2] in1 = pull_vec4(ifconst(0));
                        vec4[2] out1;
                        bvec4 mixer = bvec4(false);
                        vec4 zero = vec4(0);
                        cube;
                        push_vec4(out1);
                    }
                    break;

                    case OPSmoothMinMaterialFloat:
                    case OPSmoothMinFloat:{
                        inputmask3(float_const_head,float_const_head,float_const_head);
                        float[2] k=pull_float(ifconst(0));
                        float[2] a=pull_float(ifconst(1));
                        float[2] b=pull_float(ifconst(2));
                        float hmin=max(k[0]-abs(a[0]-b[0]),0.);
                        float hmax=max(k[0]-abs(a[1]-b[1]),0.);
                        float smin=min(a[0],b[0])-hmin*hmin*.25/k[0];
                        float smax=min(a[1],b[1])-hmax*hmax*.25/k[0];
                        push_float(float[2](smin,smax));
                    }
                    break;
                    case OPSmoothMaxMaterialFloat:
                    case OPSmoothMaxFloat:{
                        inputmask3(float_const_head,float_const_head,float_const_head);
                        float[2] k=pull_float(ifconst(0));
                        float[2] a=pull_float(ifconst(1));
                        float[2] b=pull_float(ifconst(2));
                        float hmin=max(k[0]-abs(a[0]-b[0]),0.);
                        float hmax=max(k[0]-abs(a[1]-b[1]),0.);
                        float smin=max(a[0],b[0])+hmin*hmin*.25/k[0];
                        float smax=max(a[1],b[1])+hmax*hmax*.25/k[0];
                        push_float(float[2](smin,smax));
                    }
                    break;

                    /*
                    case OPSwap2Float:{
                        float[2]floattemp=float_stack[float_stack_head-1];
                        float_stack[float_stack_head-1]=float_stack[float_stack_head-2];
                        float_stack[float_stack_head-2]=floattemp;
                    }
                    break;
                    case OPSwap3Float:{
                        float[2]floattemp=float_stack[float_stack_head-1];
                        float_stack[float_stack_head-1]=float_stack[float_stack_head-3];
                        float_stack[float_stack_head-3]=floattemp;
                    }
                    break;
                    case OPSwap4Float:{
                        float[2]floattemp=float_stack[float_stack_head-1];
                        float_stack[float_stack_head-1]=float_stack[float_stack_head-4];
                        float_stack[float_stack_head-4]=floattemp;
                    }
                    */
                    break;
                    case OPDupFloat:{
                        push_float(float_stack[float_stack_head-1]);
                    }
                    break;
                    case OPDup2Float:{
                        push_float(float_stack[float_stack_head-2]);
                    }
                    break;
                    case OPDup3Float:{
                        push_float(float_stack[float_stack_head-3]);
                    }
                    break;
                    case OPDup4Float:{
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
                        vec2[2]vec2temp=vec2_stack[vec2_stack_head-1];
                        vec2_stack[vec2_stack_head-1]=vec2_stack[vec2_stack_head-2];
                        vec2_stack[vec2_stack_head-2]=vec2temp;
                    }
                    break;
                    case OPSwap3Vec2:{
                        vec2[2]vec2temp=vec2_stack[vec2_stack_head-1];
                        vec2_stack[vec2_stack_head-1]=vec2_stack[vec2_stack_head-3];
                        vec2_stack[vec2_stack_head-3]=vec2temp;
                    }
                    break;
                    case OPSwap4Vec2:{
                        vec2[2]vec2temp=vec2_stack[vec2_stack_head-1];
                        vec2_stack[vec2_stack_head-1]=vec2_stack[vec2_stack_head-4];
                        vec2_stack[vec2_stack_head-4]=vec2temp;
                    }
                    break;
                    */
                    case OPDupVec2:{
                        push_vec2(vec2_stack[vec2_stack_head-1]);
                    }
                    break;
                    case OPDup2Vec2:{
                        push_vec2(vec2_stack[vec2_stack_head-2]);
                    }
                    break;
                    case OPDup3Vec2:{
                        push_vec2(vec2_stack[vec2_stack_head-3]);
                    }
                    break;
                    case OPDup4Vec2:{
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
                        vec3[2]vec3temp=vec3_stack[vec3_stack_head-1];
                        vec3_stack[vec3_stack_head-1]=vec3_stack[vec3_stack_head-2];
                        vec3_stack[vec3_stack_head-2]=vec3temp;
                    }
                    break;
                    case OPSwap3Vec3:{
                        vec3[2]vec3temp=vec3_stack[vec3_stack_head-1];
                        vec3_stack[vec3_stack_head-1]=vec3_stack[vec3_stack_head-3];
                        vec3_stack[vec3_stack_head-3]=vec3temp;
                    }
                    break;
                    case OPSwap4Vec3:{
                        vec3[2]vec3temp=vec3_stack[vec3_stack_head-1];
                        vec3_stack[vec3_stack_head-1]=vec3_stack[vec3_stack_head-4];
                        vec3_stack[vec3_stack_head-4]=vec3temp;
                    }
                    break;
                    */
                    case OPDupVec3:{
                        push_vec3(vec3_stack[vec3_stack_head-1]);
                    }
                    break;
                    case OPDup2Vec3:{
                        push_vec3(vec3_stack[vec3_stack_head-2]);
                    }
                    break;
                    case OPDup3Vec3:{
                        push_vec3(vec3_stack[vec3_stack_head-3]);
                    }
                    break;
                    case OPDup4Vec3:{
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
                        vec4[2]vec4temp=vec4_stack[vec4_stack_head-1];
                        vec4_stack[vec4_stack_head-1]=vec4_stack[vec4_stack_head-2];
                        vec4_stack[vec4_stack_head-2]=vec4temp;
                    }
                    break;
                    case OPSwap3Vec4:{
                        vec4[2]vec4temp=vec4_stack[vec4_stack_head-1];
                        vec4_stack[vec4_stack_head-1]=vec4_stack[vec4_stack_head-3];
                        vec4_stack[vec4_stack_head-3]=vec4temp;
                    }
                    break;
                    case OPSwap4Vec4:{
                        vec4[2]vec4temp=vec4_stack[vec4_stack_head-1];
                        vec4_stack[vec4_stack_head-1]=vec4_stack[vec4_stack_head-4];
                        vec4_stack[vec4_stack_head-4]=vec4temp;
                    }
                    break;
                    */
                    case OPDupVec4:{
                        push_vec4(vec4_stack[vec4_stack_head-1]);
                    }
                    break;
                    case OPDup2Vec4:{
                        push_vec4(vec4_stack[vec4_stack_head-2]);
                    }
                    break;
                    case OPDup3Vec4:{
                        push_vec4(vec4_stack[vec4_stack_head-3]);
                    }
                    break;
                    case OPDup4Vec4:{
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
                        float[2] in2=pull_float(ifconst(0));
                        /*#ifdef debug
                        if (in2[0] == in2[1] && in2[0] == 0.2)
                        {return vec3(in2[0],in2[1],0.);
                        }else{
                            return vec3(in2[0],in2[1],1.);
                        }
                        #endif*/
                        vec3[2] in1=pull_vec3(ifconst(1));
                        /*#ifdef debug
                        return in1[0];
                        #endif*/
                        float[2] out1;

                        bvec3 mixer=mix(bvec3(false),greaterThan(in1[1],vec3(0)),lessThan(in1[0],vec3(0)));
                        out1[0]=length(mix(min(abs(in1[0]),abs(in1[1])),vec3(0),mixer))-in2[1];
                        out1[1]=length(max(abs(in1[0]),abs(in1[1])))-in2[0];

                        #ifdef debug
                        //return vec3(out1[0],out1[1],0.);
                        #endif
                        
                        push_float(out1);
                    }
                    break;

                    case OPSDFTorus:
                    {
                        inputmask2(vec2_const_head,vec3_const_head);
                        vec2[2] in2=pull_vec2(ifconst(0)); //t
                        vec3[2] in1=pull_vec3(ifconst(1)); //p
                        vec2[2] out1;
                        float[2] out2;

                        bvec2 mixer=mix(bvec2(false),greaterThan(in1[1].xz,vec2(0)),lessThan(in1[0].xz,vec2(0)));
                        out1[0].x=length(mix(min(abs(in1[0].xz),abs(in1[1].xz)),vec2(0),mixer))-in2[1].x;
                        out1[1].x=length(max(abs(in1[0].xz),abs(in1[1].xz)))-in2[0].x;
                        out1[0].y = p[0].y;
                        out1[1].y = p[1].y;

                        mixer=mix(bvec2(false),greaterThan(out1[1],vec2(0)),lessThan(out1[0],vec2(0)));
                        out2[0]=length(mix(min(abs(out1[0]),abs(out1[1])),vec2(0),mixer))-in2[1].y;
                        out2[1]=length(max(abs(out1[0]),abs(out1[1])))-in2[0].y;
                        
                        push_float(out2);
                    }
                    break;

                    //this doesn't work internally but it's probably fiiiine
                    case OPSDFBox:
                    {
                        inputmask2(vec3_const_head,vec3_const_head);
                        vec3[2] in2=pull_vec3(ifconst(0)); //r
                        vec3[2] in1=pull_vec3(ifconst(1)); //p

                        #ifdef debug
                        return in1[0];
                        #endif

                        vec3[2]temp;
                        bvec3 mixer = bvec3(false);
                        vec3 zero = vec3(0);
                        absolute;
                        subtract;
                        float out1 = length(max(in1[0],0.0))+min(max(in1[0].x,max(in1[0].y,in1[0].z)),0.0);
                        float out2 = length(max(in1[1],0.0))+min(max(in1[1].x,max(in1[1].y,in1[1].z)),0.0);
                        push_float(float[2](min(out1,out2),max(out1,out2)));
                    }
                    break;
                    
                    case OPNop:
                    break;
                    case OPStop:
                    if (prune) {
                        //return float[2](-1,-1);
                        pruneall(uint8_t((major_position<<3)|minor_position));
                    }
                    #ifdef debug
                    return vec3(pull_float(ifconst(0))[0]);
                    #else
                    return pull_float(ifconst(0));
                    #endif
                    case OPInvalid:
                    default:
                    #ifdef debug
                    return vec3(float(minor_integer_cache[minor_position]));
                    #else
                    return float[2](-1,-1);
                    #endif
                }
        
        minor_position++;
        if(minor_position==8)
        {
            minor_position=0;
            major_position++;
            if(major_position==masklen)
            {
                if (prune) {
                    pruneall(uint8_t(masklen<<3));
                }
                #ifdef debug
                return vec3(pull_float(false)[0]);
                #else
                return pull_float(false);
                #endif
            }
        }
    }
}
#endif//ifndef intervals