#version 460
#include "include.glsl"

layout(location=0)in vec3 position;
layout(location=1)in vec3 normal;

layout(location=0)out vec3 v_normal;

void main(){
    mat4 worldview=camera_uniforms.view*pc.world;
    v_normal=normal;//normalize(transpose(inverse(mat3(worldview))) * normal);
    gl_Position=camera_uniforms.proj*worldview*vec4(position,1.);
}