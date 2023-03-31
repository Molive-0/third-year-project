//  global fragment shader

#version 460
#extension GL_EXT_mesh_shader:require
#define DescriptionIndex gl_PrimitiveID>>11
#include "include.glsl"

#ifdef implicit

layout (constant_id = 0) const bool DISABLE_TRACE = false;

layout(location=0)in VertexInput
{
    vec4 position;
}vertexInput;

#else

layout(location=0)in vec3 tri_normal;
layout(location=1)in vec4 tri_pos;

#endif

layout(location=0)out vec4 f_color;

/// SHARED CODE ///
vec3 shading(vec3 normal, vec4 position)
{
    vec3 accum=vec3(0.,0.,0.);
    mat3 rotation=mat3(pc.world[0].xyz,pc.world[1].xyz,pc.world[2].xyz);
    //vec3 position=pc.world[3].xyz;
    
    for(int i=0;i<light_uniforms.light_count;i++)
    {
        accum+=light_uniforms.col[i].xyz*((dot(normalize(rotation*normal),normalize(light_uniforms.pos[i].xyz-position.xyz))*.5)+.5);
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
#define interval_frags
#include "interpreter.glsl"

layout(set=0,binding=20, std430)restrict readonly buffer fragmentMasks{
    uint8_t masks[][masklen];
}fragmentpassmasks;

#ifdef debug
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
    td.y=scene(p,false).x;
    td.x+=(td.y)*.9;
    p=ori+dir*td.x;
    for(int i=0;i<MAX_STEPS&&td.y>EPSILON&&td.x<FARPLANE;i++){
        td.y=scene(p,false).x;
        td.x+=(td.y)*.9;
        p=ori+dir*td.x;
    }
    return td;
}
#else
vec3 getNormal(vec3 p,float dens){
    vec3 n;
    n.x=scene(vec3(p.x+EPSILON,p.y,p.z),false);
    n.y=scene(vec3(p.x,p.y+EPSILON,p.z),false);
    n.z=scene(vec3(p.x,p.y,p.z+EPSILON),false);
    return normalize(n-(scene(p,false)));
}

vec2 spheretracing(vec3 ori,vec3 dir,out vec3 p){
    vec2 td=vec2(NEARPLANE,1.);
    p=ori;
    for(int i=0;i<MAX_STEPS&&td.y>EPSILON&&td.x<FARPLANE;i++){
        td.y=scene(p,false);
        td.x+=(td.y)*.9;
        p=ori+dir*td.x;
    }
    return td;
}
#endif

//Implicit Surface Entrypoint
void main(){
    //default_mask();
    mask = fragmentpassmasks.masks[gl_PrimitiveID];
    vec3 raypos=vertexInput.position.xyz;
    vec3 p;
    vec3 raydir=normalize(raypos-(inverse(pc.world)*vec4(camera_uniforms.campos,1)).xyz);
    
    //f_color=vec4(raydir,1.);
    
    if (DISABLE_TRACE) {
        f_color=vertexInput.position;
        return;
    }

    #ifdef debug
    f_color=vec4(scene(raypos,false),1);
    return;
    #endif
    
    vec2 td=spheretracing(raypos,raydir,p);
    /*#ifdef debug
    f_color=vec4(td,0,1);
    return;
    #endif*/
    if(td.y<EPSILON)
    {
        vec3 n=getNormal(p,td.y);
        //f_color=vec4(1.);
        f_color=vec4(shading(n, inverse(pc.world)*vec4(p,1.)),1.);
        
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
    f_color=vec4(shading(tri_normal, tri_pos),1.);
}

#endif