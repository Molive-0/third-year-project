//  global fragment shader

#version 450
#include "include.glsl"

layout(constant_id=0)const uint RES_X=1920;
layout(constant_id=1)const uint RES_Y=1080;

#ifdef implicit

layout(location=0)in VertexInput
{
    vec4 position;
}vertexInput;

#else

layout(location=0)in vec3 tri_normal;

#endif

layout(location=0)out vec4 f_color;

const float EPSILON=.0001;
const uint MAX_STEPS=50;

/// SHARED CODE ///
vec3 shading(vec3 normal)
{
    vec3 accum=vec3(0.,0.,0.);
    
    for(int i=0;i<light_uniforms.light_count;i++)
    {
        accum+=light_uniforms.col[i].xyz*((dot(normalize(normal),light_uniforms.pos[i].xyz)*.5)+.5);
    }
    
    return accum;
}

/// IMPLICIT CODE ///
#ifdef implicit

#define NEARPLANE 0.
#define FARPLANE length(vec3(10))

#include "interpreter.glsl"

vec3 getNormal(vec3 p,float dens){
    vec3 n;
    n.x=scene(vec3(p.x+EPSILON,p.y,p.z),false).x;
    n.y=scene(vec3(p.x,p.y+EPSILON,p.z),false).x;
    n.z=scene(vec3(p.x,p.y,p.z+EPSILON),false).x;
    return normalize(n-(scene(p,false).x));
}

vec2 spheretracing(vec3 ori,vec3 dir,out vec3 p){
    vec2 td=vec2(NEARPLANE,1.);
    p=ori;
    for(int i=0;i<MAX_STEPS&&td.y>EPSILON&&td.x<FARPLANE;i++){
        td.y=scene(p,false).x;
        td.x+=(td.y)*.9;
        p=ori+dir*td.x;
    }
    return td;
}

//Implicit Surface Entrypoint
void main(){
    default_mask();
    vec3 raypos=vertexInput.position.xyz;
    vec2 iResolution=vec2(RES_X,RES_Y);
    vec2 iuv=(gl_FragCoord.xy+gl_SamplePosition)/iResolution.xy*2.-1.;
    vec2 uv=iuv;
    uv.x*=iResolution.x/iResolution.y;
    vec3 p;
    vec3 raydir=normalize(raypos-camera_uniforms.campos);
    raypos-=vec3(5);
    //scene(raypos,false);
    //f_color=vec4(scene(raypos,false),1.);
    ///return;
    
    vec2 td=spheretracing(raypos,raydir,p);
    vec3 n=getNormal(p,td.y);
    if(td.y<EPSILON)
    {
        f_color=vec4(1.);
        f_color=vec4(shading(n),1.);
        
        vec4 tpoint=camera_uniforms.proj*camera_uniforms.view*vec4(p,1);
        gl_FragDepth=(tpoint.z/tpoint.w);
        //gl_FragDepth=gl_DepthRange.diff*(((tpoint.z/tpoint.w)+1.)*.5)+gl_DepthRange.near;
    }
    else
    {
        discard;
    }
}

#else
/// TRIANGLE CODE ///

//Mesh Surface Entrypoint
void main(){
    f_color=vec4(shading(tri_normal),1.);
}

#endif