// Implicit Fragment shader

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

layout(constant_id=0)const uint RES_X=1920;
layout(constant_id=1)const uint RES_Y=1080;

layout(location=0)in VertexInput
{
    vec4 position;
}vertexInput;

layout(location=0)out vec4 f_color;

const float EPSILON=.0001;
const uint MAX_STEPS=50;

float scene(vec3 p)
{
    return length(p-vec3(5.))-5.;
}

vec3 getNormal(vec3 p,float dens){
    vec3 n;
    n.x=scene(vec3(p.x+EPSILON,p.y,p.z));
    n.y=scene(vec3(p.x,p.y+EPSILON,p.z));
    n.z=scene(vec3(p.x,p.y,p.z+EPSILON));
    return normalize(n-scene(p));
}

vec2 spheretracing(vec3 ori,vec3 dir,out vec3 p){
    vec2 td=vec2(0.);
    for(int i=0;i<MAX_STEPS;i++){
        p=ori+dir*td.x;
        td.y=scene(p);
        if(td.y<EPSILON)break;
        td.x+=(td.y)*.9;
    }
    return td;
}
#define frac_pi_2 1.57079632679489661923132169163975144
void main(){
    
    vec3 raypos=vertexInput.position.xyz;
    vec2 iResolution=vec2(RES_X,RES_Y);
    vec2 iuv=gl_FragCoord.xy/iResolution.xy*2.-1.;
    vec2 uv=iuv;
    uv.x*=iResolution.x/iResolution.y;
    vec3 p;
    vec3 raydir=normalize(raypos-camera_uniforms.campos);
    //raydir=(camera_uniforms.view*vec4(raydir,1.)).xyz;
    vec2 td=spheretracing(raypos,raydir,p);
    vec3 n=getNormal(p,td.y);
    if(td.y<EPSILON)
    {
        vec3 accum=vec3(0.,0.,0.);
        
        for(int i=0;i<light_uniforms.light_count;i++)
        {
            accum+=light_uniforms.col[i].xyz*((dot(normalize(n),light_uniforms.pos[i].xyz)*.5)+.5);
        }
        
        f_color=vec4(accum,1.);
    }
    else
    {
        //f_color=vec4(raydir,0.);
        discard;
    }
}