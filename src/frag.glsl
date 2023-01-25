#version 450

layout(location=0)in vec3 normal;
layout(location=0)out vec4 f_color;

layout(set=0,binding=0)uniform Data{
    vec4[32]pos;
    vec4[32]col;
    uint light_count;
}uniforms;

void main(){
    vec3 accum=vec3(0.,0.,0.);
    
    for(int i=0;i<uniforms.light_count;i++)
    {
        accum+=uniforms.col[i].xyz*((dot(normalize(normal),uniforms.pos[i].xyz)*.5)+.5);
    }
    
    f_color=vec4(accum,1.);
}