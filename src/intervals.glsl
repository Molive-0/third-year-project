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
    uint vec3s;
    uint vec4s;
    uint mat2s;
    uint mat3s;
    uint mat4s;
    uint dependencies;
};

layout(set=0,binding=2)restrict readonly buffer SceneDescription{
    Description desc[];
}scene_description;

layout(set=0,binding=3)restrict readonly buffer SceneBuf{
    u32vec4 opcodes[];
}scenes;
layout(set=0,binding=4)restrict readonly buffer FloatConst{
    float floats[];
}fconst;
layout(set=0,binding=5)restrict readonly buffer Vec2Const{
    vec2 vec2s[];
}v2const;
layout(set=0,binding=6)restrict readonly buffer Vec3Const{
    vec3 vec3s[];
}v3const;
layout(set=0,binding=7)restrict readonly buffer Vec4Const{
    vec4 vec4s[];
}v4const;
layout(set=0,binding=8)restrict readonly buffer Mat2Const{
    mat2 mat2s[];
}m2const;
layout(set=0,binding=9)restrict readonly buffer Mat3Const{
    mat3 mat3s[];
}m3const;
layout(set=0,binding=10)restrict readonly buffer Mat4Const{
    mat4 mat4s[];
}m4const;
layout(set=0,binding=11)restrict readonly buffer MatConst{
    mat4 mats[];
}matconst;
layout(set=0,binding=12)restrict readonly buffer DepInfo{
    uint8_t dependencies[2][];
}depinfo;

// unpack integers
#define get_caches u32vec4 major_unpack=scenes.opcodes[major_position+desc.scene];\
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
mat2 mat2_stack[4][2];
uint mat2_stack_head=0;
mat3 mat3_stack[4][2];
uint mat3_stack_head=0;
mat4 mat4_stack[4][2];
uint mat4_stack_head=0;

uint float_const_head=0;
uint vec2_const_head=0;
uint vec3_const_head=0;
uint vec4_const_head=0;
uint mat2_const_head=0;
uint mat3_const_head=0;
uint mat4_const_head=0;

void push_float(float f[2]){
    float_stack[float_stack_head++]=f;
}

float[2]pull_float(bool c){
    if (c) {
        float f = fconst.floats[float_const_head++];
        return float[2](f,f);
    }
    else {
        return float_stack[--float_stack_head];
    }
}

float cpull_float(){
    return fconst.floats[float_const_head++];
}

void push_vec2(vec2 f[2]){
    vec2_stack[vec2_stack_head++]=f;
}

vec2[2]pull_vec2(bool c){
    if (c) {
        vec2 f = v2const.vec2s[vec2_const_head++];
        return vec2[2](f,f);
    }
    else {
        return vec2_stack[--vec2_stack_head];
    }
}

vec2 cpull_vec2(){
    return v2const.vec2s[vec2_const_head++];
}

void push_vec3(vec3 f[2]){
    vec3_stack[vec3_stack_head++]=f;
}

vec3[2]pull_vec3(bool c){
    if (c) {
        vec3 f = v3const.vec3s[vec3_const_head++];
        return vec3[2](f,f);
    }
    else {
        return vec3_stack[--vec3_stack_head];
    }
}

vec3 cpull_vec3(){
    return v3const.vec3s[vec3_const_head++];
}

void push_vec4(vec4 f[2]){
    vec4_stack[vec4_stack_head++]=f;
}

vec4[2]pull_vec4(bool c){
    if (c) {
        vec4 f = v4const.vec4s[vec4_const_head++];
        return vec4[2](f,f);
    }
    else {
        return vec4_stack[--vec4_stack_head];
    }
}

vec4 cpull_vec4(){
    return v4const.vec4s[vec4_const_head++];
}

void push_mat2(mat2 f[2]){
    mat2_stack[mat2_stack_head++]=f;
}

mat2[2]pull_mat2(bool c){
    if (c) {
        mat2 f = m2const.mat2s[mat2_const_head++];
        return mat2[2](f,f);
    }
    else {
        return mat2_stack[--mat2_stack_head];
    }
}

mat2 cpull_mat2(){
    return m2const.mat2s[mat2_const_head++];
}

void push_mat3(mat3 f[2]){
    mat3_stack[mat3_stack_head++]=f;
}

mat3[2]pull_mat3(bool c){
    if (c) {
        mat3 f = m3const.mat3s[mat3_const_head++];
        return mat3[2](f,f);
    }
    else {
        return mat3_stack[--mat3_stack_head];
    }
}

mat3 cpull_mat3(){
    return m3const.mat3s[mat3_const_head++];
}

void push_mat4(mat4 f[2]){
    mat4_stack[mat4_stack_head++]=f;
}

mat4[2]pull_mat4(bool c){
    if (c) {
        mat4 f = m4const.mat4s[mat4_const_head++];
        return mat4[2](f,f);
    }
    else {
        return mat4_stack[--mat4_stack_head];
    }
}

mat4 cpull_mat4(){
    return m4const.mat4s[mat4_const_head++];
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
}

uint8_t mask[29];

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

Description desc;

void pruneall (uint8_t pos) {
    uint8_t[2] deps;
    for (int i = 0; i < pos; i++)
    {
        deps = depinfo.dependencies[desc.dependencies+i];
        if (deps[1] != 255) {
            //this is a dual output function (dup)
            //todo
        }
        else if (deps[0] == pos) {
            pruneall(i);
        }
    }
    mask[pos>>3] &= ~(1<<(pos&7));
}

#ifdef debug
vec3 scene(vec3 p[2], bool prune)
#else
float[2]scene(vec3 p[2], bool prune)
#endif
{
    uint major_position=0;
    uint minor_position=0;
    
    uint minor_integer_cache[8];

    desc = scene_description.desc[gl_GlobalInvocationID.x];
    
    clear_stacks();
    push_vec3(p);
    
    bool cont=true;
    
    while(cont){
        if(minor_position==0){
            get_caches;
        }
        /*#ifdef debug
        if((minor_integer_cache[minor_position]&1023)==OPStop) {
            return vec3(0.,0.,1.);
        }
        if((minor_integer_cache[minor_position]&1023)==OPSDFSphere) {
            return vec3(1.,0.,0.);
        }
        return vec3(0.,1.,0.);
        #endif*/

        if((mask[major_position]&(1<<minor_position))>0)
        {
                switch(minor_integer_cache[minor_position]&1023)
                {
                    #define ifconst(pos) (minor_integer_cache[minor_position] & (1 << (15 - pos))) > 0
                    case OPAddFloatFloat:{
                        float[2]in1=pull_float(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        add;
                        push_float(in1);
                    }
                    break;
                    case OPAddVec2Vec2:{
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]in2=pull_vec2(ifconst(1));
                        add;
                        push_vec2(in1);
                    }
                    break;
                    case OPAddVec2Float:{
                        vec2[2]in1=pull_vec2(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        add;
                        push_vec2(in1);
                    }
                    break;
                    case OPAddVec3Vec3:{
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        add;
                        push_vec3(in1);
                    }
                    break;
                    case OPAddVec3Float:{
                        vec3[2]in1=pull_vec3(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        add;
                        push_vec3(in1);
                    }
                    break;
                    case OPAddVec4Vec4:{
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]in2=pull_vec4(ifconst(1));
                        add;
                        push_vec4(in1);
                    }
                    break;
                    case OPAddVec4Float:{
                        vec4[2]in1=pull_vec4(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        add;
                        push_vec4(in1);
                    }
                    break;
                    
                    case OPSubFloatFloat:{
                        float[2]in1=pull_float(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        subtract;
                        push_float(in1);
                    }
                    break;
                    case OPSubVec2Vec2:{
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]in2=pull_vec2(ifconst(1));
                        subtract;
                        push_vec2(in1);
                    }
                    break;
                    case OPSubVec2Float:{
                        vec2[2]in1=pull_vec2(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        subtract;
                        push_vec2(in1);
                    }
                    break;
                    case OPSubVec3Vec3:{
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        subtract;
                        push_vec3(in1);
                    }
                    break;
                    case OPSubVec3Float:{
                        vec3[2]in1=pull_vec3(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        subtract;
                        push_vec3(in1);
                    }
                    break;
                    case OPSubVec4Vec4:{
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]in2=pull_vec4(ifconst(1));
                        subtract;
                        push_vec4(in1);
                    }
                    break;
                    case OPSubVec4Float:{
                        vec4[2]in1=pull_vec4(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        subtract;
                        push_vec4(in1);
                    }
                    break;
                    
                    case OPMulFloatFloat:{
                        float[2]in1=pull_float(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        float[4]temp;
                        multiply;
                        push_float(in1);
                    }
                    break;
                    case OPMulVec2Vec2:{
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]in2=pull_vec2(ifconst(1));
                        vec2[4]temp;
                        multiply;
                        push_vec2(in1);
                    }
                    break;
                    case OPMulVec2Float:{
                        vec2[2]in1=pull_vec2(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        vec2[4]temp;
                        multiply;
                        push_vec2(in1);
                    }
                    break;
                    case OPMulVec3Vec3:{
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        vec3[4]temp;
                        multiply;
                        push_vec3(in1);
                    }
                    break;
                    case OPMulVec3Float:{
                        vec3[2]in1=pull_vec3(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        vec3[4]temp;
                        multiply;
                        push_vec3(in1);
                    }
                    break;
                    case OPMulVec4Vec4:{
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]in2=pull_vec4(ifconst(1));
                        vec4[4]temp;
                        multiply;
                        push_vec4(in1);
                    }
                    break;
                    case OPMulVec4Float:{
                        vec4[2]in1=pull_vec4(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        vec4[4]temp;
                        multiply;
                        push_vec4(in1);
                    }
                    break;
                    
                    case OPDivFloatFloat:{
                        float[2]in1=pull_float(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        float[4]temp;
                        divide;
                        push_float(in1);
                    }
                    break;
                    case OPDivVec2Vec2:{
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]in2=pull_vec2(ifconst(1));
                        vec2[4]temp;
                        divide;
                        push_vec2(in1);
                    }
                    break;
                    case OPDivVec2Float:{
                        vec2[2]in1=pull_vec2(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        vec2[4]temp;
                        divide;
                        push_vec2(in1);
                    }
                    break;
                    case OPDivVec3Vec3:{
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        vec3[4]temp;
                        divide;
                        push_vec3(in1);
                    }
                    break;
                    case OPDivVec3Float:{
                        vec3[2]in1=pull_vec3(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        vec3[4]temp;
                        divide;
                        push_vec3(in1);
                    }
                    break;
                    case OPDivVec4Vec4:{
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]in2=pull_vec4(ifconst(1));
                        vec4[4]temp;
                        divide;
                        push_vec4(in1);
                    }
                    break;
                    case OPDivVec4Float:{
                        vec4[2]in1=pull_vec4(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        vec4[4]temp;
                        divide;
                        push_vec4(in1);
                    }
                    break;
                    
                    case OPPowFloatFloat:{
                        float[2]in1=pull_float(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        float[4]temp;
                        power;
                        push_float(in1);
                    }
                    break;
                    case OPPowVec2Vec2:{
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]in2=pull_vec2(ifconst(1));
                        vec2[4]temp;
                        power;
                        push_vec2(in1);
                    }
                    break;
                    case OPPowVec3Vec3:{
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        vec3[4]temp;
                        power;
                        push_vec3(in1);
                    }
                    break;
                    case OPPowVec4Vec4:{
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]in2=pull_vec4(ifconst(1));
                        vec4[4]temp;
                        power;
                        push_vec4(in1);
                    }
                    break;
                    
                    case OPModFloatFloat:{
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
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]in2=pull_vec2(ifconst(1));
                        float[2]out1;
                        dotprod;
                        push_float(out1);
                    }
                    break;
                    case OPDotVec3:{
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        float[2]out1;
                        dotprod;
                        push_float(out1);
                    }
                    break;
                    case OPDotVec4:{
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]in2=pull_vec4(ifconst(1));
                        float[2]out1;
                        dotprod;
                        push_float(out1);
                    }
                    break;

                    case OPLengthVec2:{
                        vec2[2]in1=pull_vec2(ifconst(0));
                        bvec2 mixer = bvec2(false);
                        vec2 zero = vec2(0);
                        float[2]out1;
                        len;
                        push_float(out1);
                    }
                    break;
                    case OPLengthVec3:{
                        vec3[2]in1=pull_vec3(ifconst(0));
                        bvec3 mixer = bvec3(false);
                        vec3 zero = vec3(0);
                        float[2]out1;
                        len;
                        push_float(out1);
                    }
                    break;
                    case OPLengthVec4:{
                        vec4[2]in1=pull_vec4(ifconst(0));
                        bvec4 mixer = bvec4(false);
                        vec4 zero = vec4(0);
                        float[2]out1;
                        len;
                        push_float(out1);
                    }
                    break;

                    case OPDistanceVec2:{
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
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        signof;
                        push_float(in1);
                    }
                    break;
                    case OPFloorFloat: {
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        floorof;
                        push_float(in1);
                    }
                    break;
                    case OPCeilFloat: {
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        ceilingof;
                        push_float(in1);
                    }
                    break;
                    case OPFractFloat: {
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
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        squarerootof;
                        push_float(in1);
                    }
                    break;
                    case OPInverseSqrtFloat: {
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        inversesquarerootof;
                        push_float(in1);
                    }
                    break;
                    case OPExpFloat: {
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        exponentof;
                        push_float(in1);
                    }
                    break;
                    case OPExp2Float: {
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        exponent2of;
                        push_float(in1);
                    }
                    break;
                    case OPLogFloat: {
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        logarithmof;
                        push_float(in1);
                    }
                    break;
                    case OPLog2Float: {
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        logarithm2of;
                        push_float(in1);
                    }
                    break;
                    case OPSinFloat: {
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
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        arcsineof;
                        push_float(in1);
                    }
                    break;
                    case OPAcosFloat: {
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        arccosineof;
                        push_float(in1);
                    }
                    break;
                    case OPAtanFloat: {
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        arctangentof;
                        push_float(in1);
                    }
                    break;
                    case OPAcoshFloat:{
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        hyperbolicarccosineof;
                        push_float(in1);
                    }
                    break;
                    case OPAsinhFloat:{
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        hyperbolicarcsineof;
                        push_float(in1);
                    }
                    break;
                    case OPAtanhFloat:{
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        hyperbolicarctangentof;
                        push_float(in1);
                    }
                    break;
                    case OPCoshFloat:{
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
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        hyperbolicsineof;
                        push_float(in1);
                    }
                    break;
                    case OPTanhFloat:{
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        hyperbolictangentof;
                        push_float(in1);
                    }
                    break;
                    case OPRoundFloat:{
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        roundof;
                        push_float(in1);
                    }
                    break;
                    case OPTruncFloat:{
                        float[2]in1=pull_float(ifconst(0));
                        float[2]temp;
                        truncof;
                        push_float(in1);
                    }
                    break;
                    case OPMinMaterialFloat:
                    case OPMinFloat: {
                        float[2]in1=pull_float(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        float[2]temp;
                        minimum;
                        push_float(in1);
                    }
                    break;
                    case OPMaxMaterialFloat:
                    case OPMaxFloat: {
                        float[2]in1=pull_float(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        float[2]temp;
                        maximum;
                        push_float(in1);
                    }
                    break;
                    case OPFMAFloat: {
                        float[2]in1=pull_float(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        float[2]in3=pull_float(ifconst(2));
                        float[4]temp;
                        fmaof;
                        push_float(in1);
                    }
                    break;

                    case OPAbsVec2: {
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        bvec2 mixer = bvec2(false);
                        vec2 zero = vec2(0);
                        absolute;
                        push_vec2(in1);
                    }
                    break;
                    case OPSignVec2: {
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        signof;
                        push_vec2(in1);
                    }
                    break;
                    case OPFloorVec2: {
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        floorof;
                        push_vec2(in1);
                    }
                    break;
                    case OPCeilVec2: {
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        ceilingof;
                        push_vec2(in1);
                    }
                    break;
                    case OPFractVec2: {
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
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        squarerootof;
                        push_vec2(in1);
                    }
                    break;
                    case OPInverseSqrtVec2: {
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        inversesquarerootof;
                        push_vec2(in1);
                    }
                    break;
                    case OPExpVec2: {
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        exponentof;
                        push_vec2(in1);
                    }
                    break;
                    case OPExp2Vec2: {
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        exponent2of;
                        push_vec2(in1);
                    }
                    break;
                    case OPLogVec2: {
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        logarithmof;
                        push_vec2(in1);
                    }
                    break;
                    case OPLog2Vec2: {
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        logarithm2of;
                        push_vec2(in1);
                    }
                    break;
                    case OPSinVec2: {
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
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        bvec2 mixer1 = bvec2(false);
                        vec2 inf = vec2(INFINITY);
                        tangentof;
                        push_vec2(in1);
                    }
                    break;
                    case OPAsinVec2: {
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        arcsineof;
                        push_vec2(in1);
                    }
                    break;
                    case OPAcosVec2: {
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        arccosineof;
                        push_vec2(in1);
                    }
                    break;
                    case OPAtanVec2: {
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        arctangentof;
                        push_vec2(in1);
                    }
                    break;
                    case OPAcoshVec2:{
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        hyperbolicarccosineof;
                        push_vec2(in1);
                    }
                    break;
                    case OPAsinhVec2:{
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        hyperbolicarcsineof;
                        push_vec2(in1);
                    }
                    break;
                    case OPAtanhVec2:{
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        hyperbolicarctangentof;
                        push_vec2(in1);
                    }
                    break;
                    case OPCoshVec2:{
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
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        hyperbolicsineof;
                        push_vec2(in1);
                    }
                    break;
                    case OPTanhVec2:{
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        hyperbolictangentof;
                        push_vec2(in1);
                    }
                    break;
                    case OPRoundVec2:{
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        roundof;
                        push_vec2(in1);
                    }
                    break;
                    case OPTruncVec2:{
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]temp;
                        truncof;
                        push_vec2(in1);
                    }
                    break;
                    case OPMinVec2: {
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]in2=pull_vec2(ifconst(1));
                        vec2[2]temp;
                        minimum;
                        push_vec2(in1);
                    }
                    break;
                    case OPMaxVec2: {
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]in2=pull_vec2(ifconst(1));
                        vec2[2]temp;
                        maximum;
                        push_vec2(in1);
                    }
                    break;
                    case OPFMAVec2: {
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]in2=pull_vec2(ifconst(1));
                        vec2[2]in3=pull_vec2(ifconst(2));
                        vec2[4]temp;
                        fmaof;
                        push_vec2(in1);
                    }
                    break;

                    case OPAbsVec3: {
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        bvec3 mixer = bvec3(false);
                        vec3 zero = vec3(0);
                        absolute;
                        push_vec3(in1);
                    }
                    break;
                    case OPSignVec3: {
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        signof;
                        push_vec3(in1);
                    }
                    break;
                    case OPFloorVec3: {
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        floorof;
                        push_vec3(in1);
                    }
                    break;
                    case OPCeilVec3: {
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        ceilingof;
                        push_vec3(in1);
                    }
                    break;
                    case OPFractVec3: {
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
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        squarerootof;
                        push_vec3(in1);
                    }
                    break;
                    case OPInverseSqrtVec3: {
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        inversesquarerootof;
                        push_vec3(in1);
                    }
                    break;
                    case OPExpVec3: {
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        exponentof;
                        push_vec3(in1);
                    }
                    break;
                    case OPExp2Vec3: {
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        exponent2of;
                        push_vec3(in1);
                    }
                    break;
                    case OPLogVec3: {
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        logarithmof;
                        push_vec3(in1);
                    }
                    break;
                    case OPLog2Vec3: {
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        logarithm2of;
                        push_vec3(in1);
                    }
                    break;
                    case OPSinVec3: {
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
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        bvec3 mixer1 = bvec3(false);
                        vec3 inf = vec3(INFINITY);
                        tangentof;
                        push_vec3(in1);
                    }
                    break;
                    case OPAsinVec3: {
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        arcsineof;
                        push_vec3(in1);
                    }
                    break;
                    case OPAcosVec3: {
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        arccosineof;
                        push_vec3(in1);
                    }
                    break;
                    case OPAtanVec3: {
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        arctangentof;
                        push_vec3(in1);
                    }
                    break;
                    case OPAcoshVec3:{
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        hyperbolicarccosineof;
                        push_vec3(in1);
                    }
                    break;
                    case OPAsinhVec3:{
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        hyperbolicarcsineof;
                        push_vec3(in1);
                    }
                    break;
                    case OPAtanhVec3:{
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        hyperbolicarctangentof;
                        push_vec3(in1);
                    }
                    break;
                    case OPCoshVec3:{
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
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        hyperbolicsineof;
                        push_vec3(in1);
                    }
                    break;
                    case OPTanhVec3:{
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        hyperbolictangentof;
                        push_vec3(in1);
                    }
                    break;
                    case OPRoundVec3:{
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        roundof;
                        push_vec3(in1);
                    }
                    break;
                    case OPTruncVec3:{
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]temp;
                        truncof;
                        push_vec3(in1);
                    }
                    break;
                    case OPMinVec3: {
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        vec3[2]temp;
                        minimum;
                        push_vec3(in1);
                    }
                    break;
                    case OPMaxVec3: {
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        vec3[2]temp;
                        maximum;
                        push_vec3(in1);
                    }
                    break;
                    case OPFMAVec3: {
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        vec3[2]in3=pull_vec3(ifconst(2));
                        vec3[4]temp;
                        fmaof;
                        push_vec3(in1);
                    }
                    break;

                    case OPAbsVec4: {
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        bvec4 mixer = bvec4(false);
                        vec4 zero = vec4(0);
                        absolute;
                        push_vec4(in1);
                    }
                    break;
                    case OPSignVec4: {
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        signof;
                        push_vec4(in1);
                    }
                    break;
                    case OPFloorVec4: {
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        floorof;
                        push_vec4(in1);
                    }
                    break;
                    case OPCeilVec4: {
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        ceilingof;
                        push_vec4(in1);
                    }
                    break;
                    case OPFractVec4: {
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
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        squarerootof;
                        push_vec4(in1);
                    }
                    break;
                    case OPInverseSqrtVec4: {
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        inversesquarerootof;
                        push_vec4(in1);
                    }
                    break;
                    case OPExpVec4: {
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        exponentof;
                        push_vec4(in1);
                    }
                    break;
                    case OPExp2Vec4: {
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        exponent2of;
                        push_vec4(in1);
                    }
                    break;
                    case OPLogVec4: {
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        logarithmof;
                        push_vec4(in1);
                    }
                    break;
                    case OPLog2Vec4: {
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        logarithm2of;
                        push_vec4(in1);
                    }
                    break;
                    case OPSinVec4: {
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
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        bvec4 mixer1 = bvec4(false);
                        vec4 inf = vec4(INFINITY);
                        tangentof;
                        push_vec4(in1);
                    }
                    break;
                    case OPAsinVec4: {
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        arcsineof;
                        push_vec4(in1);
                    }
                    break;
                    case OPAcosVec4: {
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        arccosineof;
                        push_vec4(in1);
                    }
                    break;
                    case OPAtanVec4: {
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        arctangentof;
                        push_vec4(in1);
                    }
                    break;
                    case OPAcoshVec4:{
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        hyperbolicarccosineof;
                        push_vec4(in1);
                    }
                    break;
                    case OPAsinhVec4:{
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        hyperbolicarcsineof;
                        push_vec4(in1);
                    }
                    break;
                    case OPAtanhVec4:{
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        hyperbolicarctangentof;
                        push_vec4(in1);
                    }
                    break;
                    case OPCoshVec4:{
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
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        hyperbolicsineof;
                        push_vec4(in1);
                    }
                    break;
                    case OPTanhVec4:{
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        hyperbolictangentof;
                        push_vec4(in1);
                    }
                    break;
                    case OPRoundVec4:{
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        roundof;
                        push_vec4(in1);
                    }
                    break;
                    case OPTruncVec4:{
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]temp;
                        truncof;
                        push_vec4(in1);
                    }
                    break;
                    case OPMinVec4: {
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]in2=pull_vec4(ifconst(1));
                        vec4[2]temp;
                        minimum;
                        push_vec4(in1);
                    }
                    break;
                    case OPMaxVec4: {
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]in2=pull_vec4(ifconst(1));
                        vec4[2]temp;
                        maximum;
                        push_vec4(in1);
                    }
                    break;
                    case OPFMAVec4: {
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]in2=pull_vec4(ifconst(1));
                        vec4[2]in3=pull_vec4(ifconst(2));
                        vec4[4]temp;
                        fmaof;
                        push_vec4(in1);
                    }
                    break;

                    case OPClampFloatFloat:{
                        float[2]in1=pull_float(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        float[2]in3=pull_float(ifconst(2));
                        clampof;
                        push_float(in1);
                    }
                    break;
                    case OPMixFloatFloat:{
                        float[2]in1=pull_float(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        float[2]in3=pull_float(ifconst(2));
                        mixof;
                        push_float(in1);
                    }
                    break;
                    case OPClampVec2Vec2:{
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]in2=pull_vec2(ifconst(1));
                        vec2[2]in3=pull_vec2(ifconst(2));
                        clampof;
                        push_vec2(in1);
                    }
                    break;
                    case OPMixVec2Vec2:{
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]in2=pull_vec2(ifconst(1));
                        vec2[2]in3=pull_vec2(ifconst(2));
                        mixof;
                        push_vec2(in1);
                    }
                    break;
                    case OPClampVec2Float:{
                        vec2[2]in1=pull_vec2(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        float[2]in3=pull_float(ifconst(2));
                        clampof;
                        push_vec2(in1);
                    }
                    break;
                    case OPMixVec2Float:{
                        vec2[2]in1=pull_vec2(ifconst(0));
                        vec2[2]in2=pull_vec2(ifconst(1));
                        float[2]in3=pull_float(ifconst(2));
                        mixof;
                        push_vec2(in1);
                    }
                    break;
                    case OPClampVec3Vec3:{
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        vec3[2]in3=pull_vec3(ifconst(2));
                        clampof;
                        push_vec3(in1);
                    }
                    break;
                    case OPMixVec3Vec3:{
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        vec3[2]in3=pull_vec3(ifconst(2));
                        mixof;
                        push_vec3(in1);
                    }
                    break;
                    case OPClampVec3Float:{
                        vec3[2]in1=pull_vec3(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        float[2]in3=pull_float(ifconst(2));
                        clampof;
                        push_vec3(in1);
                    }
                    break;
                    case OPMixVec3Float:{
                        vec3[2]in1=pull_vec3(ifconst(0));
                        vec3[2]in2=pull_vec3(ifconst(1));
                        float[2]in3=pull_float(ifconst(2));
                        mixof;
                        push_vec3(in1);
                    }
                    break;
                    case OPClampVec4Vec4:{
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]in2=pull_vec4(ifconst(1));
                        vec4[2]in3=pull_vec4(ifconst(2));
                        clampof;
                        push_vec4(in1);
                    }
                    break;
                    case OPMixVec4Vec4:{
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]in2=pull_vec4(ifconst(1));
                        vec4[2]in3=pull_vec4(ifconst(2));
                        mixof;
                        push_vec4(in1);
                    }
                    break;
                    case OPClampVec4Float:{
                        vec4[2]in1=pull_vec4(ifconst(0));
                        float[2]in2=pull_float(ifconst(1));
                        float[2]in3=pull_float(ifconst(2));
                        clampof;
                        push_vec4(in1);
                    }
                    break;
                    case OPMixVec4Float:{
                        vec4[2]in1=pull_vec4(ifconst(0));
                        vec4[2]in2=pull_vec4(ifconst(1));
                        float[2]in3=pull_float(ifconst(2));
                        mixof;
                        push_vec4(in1);
                    }
                    break;
                    
                    case OPNormalizeVec2:{
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
                        float[2] a = pull_float(ifconst(0));
                        float[2] b = pull_float(ifconst(1));
                        push_vec2(vec2[2](vec2(a[0],b[0]),vec2(a[1],b[1])));
                    }
                    break;
                    case OPPromoteFloatFloatFloatVec3:{
                        float[2] a = pull_float(ifconst(0));
                        float[2] b = pull_float(ifconst(1));
                        float[2] c = pull_float(ifconst(2));
                        push_vec3(vec3[2](vec3(a[0],b[0],c[0]),vec3(a[1],b[1],c[1])));
                    }
                    break;
                    case OPPromoteVec2FloatVec3:{
                        vec2[2] a = pull_vec2(ifconst(0));
                        float[2] b = pull_float(ifconst(1));
                        push_vec3(vec3[2](vec3(a[0],b[0]),vec3(a[1],b[1])));
                    }
                    break;
                    case OPPromoteFloatFloatFloatFloatVec4:{
                        float[2] a = pull_float(ifconst(0));
                        float[2] b = pull_float(ifconst(1));
                        float[2] c = pull_float(ifconst(2));
                        float[2] d = pull_float(ifconst(3));
                        push_vec4(vec4[2](vec4(a[0],b[0],c[0],d[0]),vec4(a[1],b[1],c[1],d[1])));
                    }
                    break;
                    case OPPromoteVec2FloatFloatVec4:{
                        vec2[2] a = pull_vec2(ifconst(0));
                        float[2] b = pull_float(ifconst(1));
                        float[2] c = pull_float(ifconst(2));
                        push_vec4(vec4[2](vec4(a[0],b[0],c[0]),vec4(a[1],b[1],c[1])));
                    }
                    break;
                    case OPPromoteVec3FloatVec4:{
                        vec3[2] a = pull_vec3(ifconst(0));
                        float[2] b = pull_float(ifconst(1));
                        push_vec4(vec4[2](vec4(a[0],b[0]),vec4(a[1],b[1])));
                    }
                    break;
                    case OPPromoteVec2Vec2Vec4:{
                        vec2[2] a = pull_vec2(ifconst(0));
                        vec2[2] b = pull_vec2(ifconst(1));
                        push_vec4(vec4[2](vec4(a[0],b[0]),vec4(a[1],b[1])));
                    }
                    break;

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

                    case OPSquareFloat:{
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
                        float[2] in1 = pull_float(ifconst(0));
                        float[2] out1;
                        bool mixer = false;
                        float zero = 0;
                        cube;
                        push_float(out1);
                    }
                    break;
                    case OPSquareVec2:{
                        vec2[2] in1 = pull_vec2(ifconst(0));
                        vec2[2] out1;
                        bvec2 mixer = bvec2(false);
                        vec2 zero = vec2(0);
                        square;
                        push_vec2(out1);
                    }
                    break;
                    case OPCubeVec2:{
                        vec2[2] in1 = pull_vec2(ifconst(0));
                        vec2[2] out1;
                        bvec2 mixer = bvec2(false);
                        vec2 zero = vec2(0);
                        cube;
                        push_vec2(out1);
                    }
                    break;
                    case OPSquareVec3:{
                        vec3[2] in1 = pull_vec3(ifconst(0));
                        vec3[2] out1;
                        bvec3 mixer = bvec3(false);
                        vec3 zero = vec3(0);
                        square;
                        push_vec3(out1);
                    }
                    break;
                    case OPCubeVec3:{
                        vec3[2] in1 = pull_vec3(ifconst(0));
                        vec3[2] out1;
                        bvec3 mixer = bvec3(false);
                        vec3 zero = vec3(0);
                        cube;
                        push_vec3(out1);
                    }
                    break;
                    case OPSquareVec4:{
                        vec4[2] in1 = pull_vec4(ifconst(0));
                        vec4[2] out1;
                        bvec4 mixer = bvec4(false);
                        vec4 zero = vec4(0);
                        square;
                        push_vec4(out1);
                    }
                    break;
                    case OPCubeVec4:{
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
                        float k=cpull_float();
                        float[2] a=pull_float(ifconst(0));
                        float[2] b=pull_float(ifconst(1));
                        float hmin=max(k-abs(a[0]-b[0]),0.);
                        float hmax=max(k-abs(a[1]-b[1]),0.);
                        float smin=min(a[0],b[0])-hmin*hmin*.25/k;
                        float smax=min(a[1],b[1])-hmax*hmax*.25/k;
                        push_float(float[2](smin,smax));
                    }
                    break;
                    case OPSmoothMaxMaterialFloat:
                    case OPSmoothMaxFloat:{
                        float k=cpull_float();
                        float[2] a=pull_float(ifconst(0));
                        float[2] b=pull_float(ifconst(1));
                        float hmin=max(k-abs(a[0]-b[0]),0.);
                        float hmax=max(k-abs(a[1]-b[1]),0.);
                        float smin=max(a[0],b[0])+hmin*hmin*.25/k;
                        float smax=max(a[1],b[1])+hmax*hmax*.25/k;
                        push_float(float[2](smin,smax));
                    }
                    break;

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
                    

                    case OPSDFSphere:
                    {
                        float[2] in2=pull_float(ifconst(0));
                        /*#ifdef debug
                        return vec3(in2[0],in2[1],0.);
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
                    
                    case OPNop:
                    break;
                    case OPStop:
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
                    return float[2](0,0);
                    #endif
                }
            /*}else{
                //return vec3(float(minor_float_cache[minor_position]));
                push_float(float[2](float(minor_float_cache[minor_position]),float(minor_float_cache[minor_position])));
            }*/
        }
        minor_position++;
        if(minor_position==8)
        {
            minor_position=0;
            major_position++;
            if(major_position==13)
            {
                #ifdef debug
                return vec3(pull_float(ifconst(0))[0]);
                #else
                return pull_float(ifconst(0));
                #endif
            }
        }
    }
}

#ifdef debug
vec3 sceneoverride(vec3 p, bool m)
{
    return scene(vec3[2](p,p));
}
#else
float sceneoverride(vec3 p, bool m)
{
    return scene(vec3[2](p,p))[0];
}
#endif

#endif//ifndef intervals