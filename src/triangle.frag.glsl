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

layout(location=0)in vec3 normal;

layout(location=0)out vec4 f_color;

void main(){
    vec3 accum=vec3(0.,0.,0.);
    
    for(int i=0;i<light_uniforms.light_count;i++)
    {
        accum+=light_uniforms.col[i].xyz*((dot(normalize(normal),light_uniforms.pos[i].xyz)*.5)+.5);
    }
    
    f_color=vec4(accum,1.);
}