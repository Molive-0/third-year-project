// Implicit Mesh shader

#version 460
#extension GL_EXT_mesh_shader:require

#define DescriptionIndex gl_WorkGroupID.x

#include "include.glsl"
#include "intervals.glsl"

layout(local_size_x=32,local_size_y=1,local_size_z=1)in;

struct MeshMasks
{
    uint8_t masks[32][masklen];  //928
    uint8_t enabled[32];        //32
    vec3 bottomleft;            //12
    vec3 topright;              //12
    uint globalindex;           //4
    //uint objectindex;           //4
};                              //total = 992 bytes
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

    #define CLIPCHECK 65536
    
    float[6]bounds={
        CLIPCHECK-sceneoverride(vec3(CLIPCHECK,0,0),false),
        CLIPCHECK-sceneoverride(vec3(0,CLIPCHECK,0),false),
        CLIPCHECK-sceneoverride(vec3(0,0,CLIPCHECK),false),
        -CLIPCHECK+sceneoverride(vec3(-CLIPCHECK,0,0),false),
        -CLIPCHECK+sceneoverride(vec3(0,-CLIPCHECK,0),false),
        -CLIPCHECK+sceneoverride(vec3(0,0,-CLIPCHECK),false),
    };
    /*const float[6]bounds={
        1,1,1,-1,-1,-1,
    };*/
    
    vec3 bottomleft = vec3(bounds[3],bounds[4],bounds[5]);
    vec3 topright   = vec3(bounds[0],bounds[1],bounds[2]);
    vec3 center = (topright + bottomleft) / 2;

#define adjust(var) var -= center;\
    var *= vec3(0.25,0.25,0.25);\
    var.x += (bounds[0]-bounds[3]) * 0.25 * (mod(gl_LocalInvocationID.x,4.)-1.5)                        ;\
    var.y += (bounds[1]-bounds[4]) * 0.25 * (mod(floor(gl_LocalInvocationID.x/4.),4.)-1.5)              ;\
    var.z += (bounds[2]-bounds[5]) * 0.25 * (floor(gl_LocalInvocationID.x/16.)-1.5+gl_WorkGroupID.z*2.) ;\
    var += center;
    

    adjust(bottomleft);
    adjust(topright);

    barrier();

    float[2] check = scene(vec3[2](bottomleft,topright), false);
    //float[2] check = scene(vec3[2](vec3(bounds[3],bounds[4],bounds[5]),vec3(bounds[0],bounds[1],bounds[2])), false);

    if ((check[0] < 0) && (check[1] > 0))
    //if ((bottomleft.x >= -1) && (bottomleft.y >= -1) && (bottomleft.z >= -1) && (topright.x <= 1) && (topright.y <= 1) && (topright.z <= 1))
    //if ((gl_LocalInvocationID.x == 0) && (bottomleft.x >= 0))
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
        //meshmasks.objectindex = DescriptionIndex;
    }

    barrier();
    EmitMeshTasksEXT(index,1,1);
}