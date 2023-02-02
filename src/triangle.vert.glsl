#version 450

layout(push_constant)uniform PushConstantData{
    mat4 world;
}pc;

layout(set=0,binding=0)uniform Lights{
    vec4[32]pos;
    vec4[32]col;
    uint light_count;
}light_uniforms;

layout(set=0,binding=1)uniform Camera{
    mat4 view;
    mat4 proj;
    vec3 campos;
}camera_uniforms;

layout(location=0)in vec3 position;
layout(location=1)in vec3 normal;

layout(location=0)out vec3 v_normal;

void main(){
    mat4 worldview=camera_uniforms.view*pc.world;
    v_normal=normal;//normalize(transpose(inverse(mat3(worldview))) * normal);
    gl_Position=camera_uniforms.proj*worldview*vec4(position*1000.,1.);
}