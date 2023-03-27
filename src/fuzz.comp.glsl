#version 460

uint DescriptionIndex;

//#include "include.glsl"
#include "intervals.glsl"
struct Results {
    float[2] f;
    vec2[2] v2;
    vec4[2] v3;
    vec4[2] v4;
    uint8_t[masklen] mask;
};

layout(set=0,binding=30, std430)buffer ResultsArray{
    Results r[];
}results;

layout(local_size_x=32,local_size_y=1,local_size_z=1)in;

void main ()
{
    DescriptionIndex = gl_LocalInvocationID.x;
    default_mask();
    float[6]bounds=scene_description.desc[DescriptionIndex+1].bounds;
    vec3 bottomleft = vec3(bounds[3],bounds[4],bounds[5]);
    vec3 topright   = vec3(bounds[0],bounds[1],bounds[2]);
    desc = scene_description.desc[(DescriptionIndex)+1];
    clear_stacks();
    results.r[gl_GlobalInvocationID.x].f = scene(vec3[2](bottomleft, topright), true);
    vec3[2] v3 = pull_vec3(false);
    results.r[gl_GlobalInvocationID.x].v3[0] = vec4(v3[0],1.);
    results.r[gl_GlobalInvocationID.x].v3[1] = vec4(v3[1],1.);
    results.r[gl_GlobalInvocationID.x].v2 = pull_vec2(false);
    results.r[gl_GlobalInvocationID.x].v4 = pull_vec4(false);
    //results.r[gl_GlobalInvocationID.x].f[1] = float(gl_GlobalInvocationID.x);
    /*results.r[gl_GlobalInvocationID.x].f = pull_float(true);//scene(vec3[2](bottomleft, topright), false);
    vec3[2] v3 = pull_vec3(true);
    results.r[gl_GlobalInvocationID.x].v3[0] = vec4(v3[0],1.);
    results.r[gl_GlobalInvocationID.x].v3[1] = vec4(v3[1],1.);
    results.r[gl_GlobalInvocationID.x].v2 = pull_vec2(true);
    results.r[gl_GlobalInvocationID.x].v4 = pull_vec4(true);
    results.r[gl_GlobalInvocationID.x].f[1] = float(gl_GlobalInvocationID.x);*/
    results.r[gl_GlobalInvocationID.x].mask = mask;
}