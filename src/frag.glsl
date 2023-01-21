#version 450

layout(location=0)in vec3 fragColor;
layout(location=0)out vec4 f_color;

const vec3 light=normalize(vec3(4,6,8));

void main(){
    f_color=vec4(vec3(dot(fragColor,light))*.5+.5,1.);
}