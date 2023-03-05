// Implicit Mesh shader

#version 460
#extension GL_EXT_mesh_shader:require

#include "include.glsl"
#include "intervals.glsl"

layout(local_size_x=1,local_size_y=1,local_size_z=1)in;
layout(triangles,max_vertices=64,max_primitives=162)out;

layout(location=0)out VertexOutput
{
    vec4 position;
}vertexOutput[];

void main()
{
    uint iid=gl_LocalInvocationID.x;
    
    vec4 offset=vec4(0.,0.,gl_GlobalInvocationID.x,0.);
    
    vec3 signingvec=sign((inverse(pc.world)*vec4(camera_uniforms.campos,1)).xyz);
    
    //clear_stacks();
    default_mask();

    #define CLIPCHECK 65536
    
    float[6]bounds={
        CLIPCHECK-sceneoverride(vec3(CLIPCHECK,0,0),false),
        CLIPCHECK-sceneoverride(vec3(0,CLIPCHECK,0),false),
        CLIPCHECK-sceneoverride(vec3(0,0,CLIPCHECK),false),
        -CLIPCHECK+sceneoverride(vec3(-CLIPCHECK,0,0),false),
        -CLIPCHECK+sceneoverride(vec3(0,-CLIPCHECK,0),false),
        -CLIPCHECK+sceneoverride(vec3(0,0,-CLIPCHECK),false),
    };
    
    vec4[8]positions={
        vec4(bounds[3],bounds[4],bounds[5],1.),
        vec4(bounds[3],bounds[4],bounds[2],1.),
        vec4(bounds[3],bounds[1],bounds[5],1.),
        vec4(bounds[3],bounds[1],bounds[2],1.),
        vec4(bounds[0],bounds[4],bounds[5],1.),
        vec4(bounds[0],bounds[4],bounds[2],1.),
        vec4(bounds[0],bounds[1],bounds[5],1.),
        vec4(bounds[0],bounds[1],bounds[2],1.),
    };
    
    SetMeshOutputsEXT(8,6);
    mat4 mvp=camera_uniforms.proj*camera_uniforms.view*pc.world;
    //mat4 sw=pc.world;
    gl_MeshVerticesEXT[0].gl_Position=mvp*(positions[0]);
    gl_MeshVerticesEXT[1].gl_Position=mvp*(positions[1]);
    gl_MeshVerticesEXT[2].gl_Position=mvp*(positions[2]);
    gl_MeshVerticesEXT[3].gl_Position=mvp*(positions[3]);
    gl_MeshVerticesEXT[4].gl_Position=mvp*(positions[4]);
    gl_MeshVerticesEXT[5].gl_Position=mvp*(positions[5]);
    gl_MeshVerticesEXT[6].gl_Position=mvp*(positions[6]);
    gl_MeshVerticesEXT[7].gl_Position=mvp*(positions[7]);
    vertexOutput[0].position=(positions[0]);
    vertexOutput[1].position=(positions[1]);
    vertexOutput[2].position=(positions[2]);
    vertexOutput[3].position=(positions[3]);
    vertexOutput[4].position=(positions[4]);
    vertexOutput[5].position=(positions[5]);
    vertexOutput[6].position=(positions[6]);
    vertexOutput[7].position=(positions[7]);
    
    if(signingvec.x>0){
        gl_PrimitiveTriangleIndicesEXT[gl_LocalInvocationIndex+0]=uvec3(4,5,6);
        gl_PrimitiveTriangleIndicesEXT[gl_LocalInvocationIndex+1]=uvec3(5,6,7);
    }else{
        gl_PrimitiveTriangleIndicesEXT[gl_LocalInvocationIndex+0]=uvec3(0,1,2);
        gl_PrimitiveTriangleIndicesEXT[gl_LocalInvocationIndex+1]=uvec3(1,2,3);
    }
    if(signingvec.y>0){
        gl_PrimitiveTriangleIndicesEXT[gl_LocalInvocationIndex+2]=uvec3(2,3,6);
        gl_PrimitiveTriangleIndicesEXT[gl_LocalInvocationIndex+3]=uvec3(7,3,6);
    }else{
        gl_PrimitiveTriangleIndicesEXT[gl_LocalInvocationIndex+2]=uvec3(0,1,4);
        gl_PrimitiveTriangleIndicesEXT[gl_LocalInvocationIndex+3]=uvec3(5,1,4);
    }
    if(signingvec.z>0){
        gl_PrimitiveTriangleIndicesEXT[gl_LocalInvocationIndex+4]=uvec3(1,3,5);
        gl_PrimitiveTriangleIndicesEXT[gl_LocalInvocationIndex+5]=uvec3(3,5,7);
    }else{
        gl_PrimitiveTriangleIndicesEXT[gl_LocalInvocationIndex+4]=uvec3(0,2,4);
        gl_PrimitiveTriangleIndicesEXT[gl_LocalInvocationIndex+5]=uvec3(2,4,6);
    }
}