//#extension GL_EXT_shader_16bit_storage:require
#extension GL_EXT_shader_explicit_arithmetic_types:require

layout(set=1,binding=0)uniform SceneDescription{
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

uint major_position=0;
uint minor_position=0;

float16_t float_stack[8];
uint float_stack_head=0;
f16vec2 vec2_stack[8];
uint vec2_stack_head=0;
f16vec3 vec3_stack[8];
uint vec3_stack_head=0;
f16vec4 vec4_stack[8];
uint vec4_stack_head=0;
f16mat2 mat2_stack[8];
uint mat2_stack_head=0;
f16mat3 mat3_stack[8];
uint mat3_stack_head=0;
f16mat4 mat4_stack[8];
uint mat4_stack_head=0;

void push_float(float16_t f){
    float_stack[float_stack_head++]=f;
}

float16_t pull_float(){
    return float_stack[--float_stack_head];
}

void push_vec2(f16vec2 f){
    vec2_stack[vec2_stack_head++]=f;
}

f16vec2 pull_vec2(){
    return vec2_stack[--vec2_stack_head];
}

void push_vec3(f16vec3 f){
    vec3_stack[vec3_stack_head++]=f;
}

f16vec3 pull_vec3(){
    return vec3_stack[--vec3_stack_head];
}

void push_vec4(f16vec4 f){
    vec4_stack[vec4_stack_head++]=f;
}

f16vec4 pull_vec4(){
    return vec4_stack[--vec4_stack_head];
}

void push_mat2(f16mat2 f){
    mat2_stack[mat2_stack_head++]=f;
}

f16mat2 pull_mat2(){
    return mat2_stack[--mat2_stack_head];
}

void push_mat3(f16mat3 f){
    mat3_stack[mat3_stack_head++]=f;
}

f16mat3 pull_mat3(){
    return mat3_stack[--mat3_stack_head];
}

void push_mat4(f16mat4 f){
    mat4_stack[mat4_stack_head++]=f;
}

f16mat4 pull_mat4(){
    return mat4_stack[--mat4_stack_head];
}

float scene(vec3 p)
{
    major_position=0;
    minor_position=0;
    
    float16_t minor_float_cache[8];
    uint16_t minor_integer_cache[8];
    
    if(minor_position==0){
        get_caches;
    }
    
    if(isnan(minor_float_cache[minor_position]))
    {
        
    }
    
    return length(p-vec3(5.))-5.;
}