/* Copyright (c) 2021, Sascha Willems
*
* SPDX-License-Identifier: MIT
*
*/

#version 450
#extension GL_EXT_mesh_shader:require

layout(push_constant)uniform PushConstantData{
    mat4 world;
    mat4 view;
    mat4 proj;
}pc;

layout(local_size_x=1,local_size_y=1,local_size_z=1)in;
layout(triangles,max_vertices=3,max_primitives=1)out;

layout(location=0)out VertexOutput
{
    vec4 color;
}vertexOutput[];

const vec4[3]positions={
    vec4(0.,-1.,0.,1.),
    vec4(-1.,1.,0.,1.),
    vec4(1.,1.,0.,1.)
};

const vec4[3]colors={
    vec4(0.,1.,0.,1.),
    vec4(0.,0.,1.,1.),
    vec4(1.,0.,0.,1.)
};

void main()
{
    uint iid=gl_LocalInvocationID.x;
    
    vec4 offset=vec4(0.,0.,gl_GlobalInvocationID.x,0.);
    
    SetMeshOutputsEXT(3,1);
    mat4 mvp=pc.proj*pc.view*pc.world;
    gl_MeshVerticesEXT[0].gl_Position=mvp*(positions[0]+offset);
    gl_MeshVerticesEXT[1].gl_Position=mvp*(positions[1]+offset);
    gl_MeshVerticesEXT[2].gl_Position=mvp*(positions[2]+offset);
    vertexOutput[0].color=colors[0];
    vertexOutput[1].color=colors[1];
    vertexOutput[2].color=colors[2];
    gl_PrimitiveTriangleIndicesEXT[gl_LocalInvocationIndex]=uvec3(0,1,2);
}