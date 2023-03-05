//  global fragment shader

#version 460
#include "include.glsl"

#ifdef implicit

layout(location=0)in VertexInput
{
    vec4 position;
}vertexInput;

#else

layout(location=0)in vec3 tri_normal;

#endif

layout(location=0)out vec4 f_color;

/// SHARED CODE ///
vec3 shading(vec3 normal)
{
    vec3 accum=vec3(0.,0.,0.);
    mat3 rotation=mat3(pc.world[0].xyz,pc.world[1].xyz,pc.world[2].xyz);
    vec3 position=pc.world[3].xyz;
    
    for(int i=0;i<light_uniforms.light_count;i++)
    {
        accum+=light_uniforms.col[i].xyz*((dot(normalize(rotation*normal),normalize(light_uniforms.pos[i].xyz-position))*.5)+.5);
    }
    
    return accum;
}

/// IMPLICIT CODE ///
#ifdef implicit

//#define debug 1

#ifdef debug
const float EPSILON=.0001;
const uint MAX_STEPS=1;
#define NEARPLANE 0.
#define FARPLANE length(vec3(10))
#define gl_GlobalInvocationID uvec3(1)
#else
const float EPSILON=.0001;
const uint MAX_STEPS=50;
#define NEARPLANE 0.
#define FARPLANE length(vec3(10))
#define gl_GlobalInvocationID uvec3(1)
#endif
#include "intervals.glsl"

#ifdef debug
vec3 getNormal(vec3 p,float dens){
    vec3 n;
    n.x=sceneoverride(vec3(p.x+EPSILON,p.y,p.z),false).x;
    n.y=sceneoverride(vec3(p.x,p.y+EPSILON,p.z),false).x;
    n.z=sceneoverride(vec3(p.x,p.y,p.z+EPSILON),false).x;
    return normalize(n-(sceneoverride(p,false).x));
}

vec2 spheretracing(vec3 ori,vec3 dir,out vec3 p){
    vec2 td=vec2(NEARPLANE,1.);
    p=ori;
    for(int i=0;i<MAX_STEPS&&td.y>EPSILON&&td.x<FARPLANE;i++){
        td.y=sceneoverride(p,false).x;
        td.x+=(td.y)*.9;
        p=ori+dir*td.x;
    }
    return td;
}
#else
vec3 getNormal(vec3 p,float dens){
    vec3 n;
    n.x=sceneoverride(vec3(p.x+EPSILON,p.y,p.z),false);
    n.y=sceneoverride(vec3(p.x,p.y+EPSILON,p.z),false);
    n.z=sceneoverride(vec3(p.x,p.y,p.z+EPSILON),false);
    return normalize(n-(sceneoverride(p,false)));
}

vec2 spheretracing(vec3 ori,vec3 dir,out vec3 p){
    vec2 td=vec2(NEARPLANE,1.);
    p=ori;
    for(int i=0;i<MAX_STEPS&&td.y>EPSILON&&td.x<FARPLANE;i++){
        td.y=sceneoverride(p,false);
        td.x+=(td.y)*.9;
        p=ori+dir*td.x;
    }
    return td;
}
#endif

//Implicit Surface Entrypoint
void main(){
    default_mask();
    vec3 raypos=vertexInput.position.xyz;
    vec3 p;
    vec3 raydir=normalize(raypos-(inverse(pc.world)*vec4(camera_uniforms.campos,1)).xyz);
    //raypos-=vec3(5);
    
    //f_color=vec4(raydir,1.);
    //return;

    #ifdef debug
    f_color=vec4(sceneoverride(raypos,false),1);
    return;
    #endif
    
    vec2 td=spheretracing(raypos,raydir,p);
    #ifdef debug
    f_color=vec4(td,0,1);
    return;
    #endif
    vec3 n=getNormal(p,td.y);
    if(td.y<EPSILON)
    {
        f_color=vec4(1.);
        f_color=vec4(shading(n),1.);
        
        vec4 tpoint=camera_uniforms.proj*camera_uniforms.view*pc.world*vec4(p,1);
        gl_FragDepth=(tpoint.z/tpoint.w);
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