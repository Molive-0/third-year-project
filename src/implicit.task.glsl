// Implicit Mesh shader

#version 460
#extension GL_EXT_mesh_shader:require

#define DescriptionIndex gl_WorkGroupID.x

#include "include.glsl"
#include "intervals.glsl"

layout (constant_id = 0) const bool DISABLE_TRACE = false;

layout(local_size_x=32,local_size_y=1,local_size_z=1)in;

struct MeshMasks
{
    uint8_t masks[32][masklen];  //928
    uint8_t enabled[32];        //32
    vec3 bottomleft;            //12
    vec3 topright;              //12
    uint globalindex;           //4
    vec3 globaloffset;          //12
};                              //total = 1000 bytes
taskPayloadSharedEXT MeshMasks meshmasks;

shared uint index;

void main()
{    
    //clear_stacks();
    default_mask();
    meshmasks.masks[gl_LocalInvocationID.x] = mask;

    if (gl_LocalInvocationID.x==0)
    {
        index=0;
    }

    //#define CLIPCHECK 65536
    
    /*float[6]bounds={
        CLIPCHECK-sceneoverride(vec3(CLIPCHECK,0,0),false),
        CLIPCHECK-sceneoverride(vec3(0,CLIPCHECK,0),false),
        CLIPCHECK-sceneoverride(vec3(0,0,CLIPCHECK),false),
        -CLIPCHECK+sceneoverride(vec3(-CLIPCHECK,0,0),false),
        -CLIPCHECK+sceneoverride(vec3(0,-CLIPCHECK,0),false),
        -CLIPCHECK+sceneoverride(vec3(0,0,-CLIPCHECK),false),
    };*/
    /*const float[6]bounds={
        1,1,1,-1,-1,-1,
    };*/

    float[6]bounds=scene_description.desc[gl_WorkGroupID.x+1].bounds;
 

    /*bounds[0] += abs(bounds[0] * 0.01);
    bounds[1] += abs(bounds[1] * 0.01);
    bounds[2] += abs(bounds[2] * 0.01);
    bounds[3] -= abs(bounds[3] * 0.01);
    bounds[4] -= abs(bounds[4] * 0.01);
    bounds[5] -= abs(bounds[5] * 0.01);*/
    
    vec3 bottomleft = vec3(bounds[3],bounds[4],bounds[5]);
    vec3 topright   = vec3(bounds[0],bounds[1],bounds[2]);
    vec3 globaloffset = vec3(0);//(topright+bottomleft)/2.;

#define adjust(var) \
    var *= vec3(0.25,0.25,0.25);\
    var.x += ((bounds[0]-bounds[3]) * 0.25 * (mod(gl_LocalInvocationID.x,4.)-1.5)) + ((bounds[0]+bounds[3])*0.375)                        ;\
    var.y += ((bounds[1]-bounds[4]) * 0.25 * (mod(floor(gl_LocalInvocationID.x/4.),4.)-1.5)) + ((bounds[1]+bounds[4])*0.375)              ;\
    var.z += ((bounds[2]-bounds[5]) * 0.25 * (floor(gl_LocalInvocationID.x/16.)-1.5+gl_WorkGroupID.z*2.)) + ((bounds[2]+bounds[5])*0.375) ;\
    
    adjust(bottomleft);
    adjust(topright);

    barrier();

    bool triangle_fine;
    if (!DISABLE_TRACE) {
        float[2] check = scene(vec3[2](bottomleft+globaloffset,topright+globaloffset), true);
        triangle_fine = (check[0] <= 0) && (check[1] >= 0);
    } else {
        triangle_fine = true;
    }

    //default_mask();
    //float[2] check = scene(vec3[2](bottomleft,topright), false);
    //float[2] check = scene(vec3[2](bottomleft-globaloffset,topright-globaloffset), false);
    //float[2] check = scene(vec3[2](vec3(bounds[3],bounds[4],bounds[5]),vec3(bounds[0],bounds[1],bounds[2])), false);

    //if (((check[0] <= 0) && (check[1] >= 0)) )//|| ((check[1] <= 0) && ()))
    //if ((bottomleft.x >= -1) && (bottomleft.y >= -1) && (bottomleft.z >= -1) && (topright.x <= 1) && (topright.y <= 1) && (topright.z <= 1))
    //if ((gl_LocalInvocationID.x == 0) && (bottomleft.x >= 0))
    if (triangle_fine)
    {
        uint localindex = atomicAdd(index, 1);
        //if (localindex < 32) {
        meshmasks.masks[localindex]=mask;
        meshmasks.enabled[localindex]=uint8_t(gl_LocalInvocationID.x);
        //}
    }

    if (gl_LocalInvocationID.x==0)
    {
        meshmasks.bottomleft = vec3(bounds[3],bounds[4],(bounds[5]*0.5) + ((bounds[2]-bounds[5])*0.5 * (-0.5+gl_WorkGroupID.z)));
        meshmasks.topright   = vec3(bounds[0],bounds[1],(bounds[2]*0.5) + ((bounds[2]-bounds[5])*0.5 * (-0.5+gl_WorkGroupID.z)));
        meshmasks.globalindex = gl_WorkGroupID.x*2+gl_WorkGroupID.z;
        meshmasks.globaloffset = globaloffset/0.25;
    }

    barrier();
    if (gl_LocalInvocationID.x==0)
    {
    EmitMeshTasksEXT(index,1,1);
    }
}