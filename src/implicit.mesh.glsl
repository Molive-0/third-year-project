// Implicit Mesh shader

#version 450
#extension GL_EXT_mesh_shader:require

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

layout(local_size_x=1,local_size_y=1,local_size_z=1)in;
layout(triangles,max_vertices=64,max_primitives=162)out;

layout(location=0)out VertexOutput
{
    vec4 color;
}vertexOutput[];

const vec4[8]positions={
    vec4(0.,0.,0.,1.),
    vec4(0.,0.,1.,1.),
    vec4(0.,1.,0.,1.),
    vec4(0.,1.,1.,1.),
    vec4(1.,0.,0.,1.),
    vec4(1.,0.,1.,1.),
    vec4(1.,1.,0.,1.),
    vec4(1.,1.,1.,1.),
};
const mat4 scale=mat4(
    10.,0.,0.,0.,
    0.,10.,0.,0.,
    0.,0.,10.,0.,
    0.,0.,0.,1.
);

void main()
{
    uint iid=gl_LocalInvocationID.x;
    
    vec4 offset=vec4(0.,0.,gl_GlobalInvocationID.x,0.);
    
    SetMeshOutputsEXT(8,12);
    mat4 mvp=camera_uniforms.proj*camera_uniforms.view*scale;
    gl_MeshVerticesEXT[0].gl_Position=mvp*(positions[0]+offset);
    gl_MeshVerticesEXT[1].gl_Position=mvp*(positions[1]+offset);
    gl_MeshVerticesEXT[2].gl_Position=mvp*(positions[2]+offset);
    gl_MeshVerticesEXT[3].gl_Position=mvp*(positions[3]+offset);
    gl_MeshVerticesEXT[4].gl_Position=mvp*(positions[4]+offset);
    gl_MeshVerticesEXT[5].gl_Position=mvp*(positions[5]+offset);
    gl_MeshVerticesEXT[6].gl_Position=mvp*(positions[6]+offset);
    gl_MeshVerticesEXT[7].gl_Position=mvp*(positions[7]+offset);
    vertexOutput[0].color=scale*positions[0];
    vertexOutput[1].color=scale*positions[1];
    vertexOutput[2].color=scale*positions[2];
    vertexOutput[3].color=scale*positions[3];
    vertexOutput[4].color=scale*positions[4];
    vertexOutput[5].color=scale*positions[5];
    vertexOutput[6].color=scale*positions[6];
    vertexOutput[7].color=scale*positions[7];
    gl_PrimitiveTriangleIndicesEXT[gl_LocalInvocationIndex+0]=uvec3(0,1,2);
    gl_PrimitiveTriangleIndicesEXT[gl_LocalInvocationIndex+1]=uvec3(1,2,3);
    gl_PrimitiveTriangleIndicesEXT[gl_LocalInvocationIndex+2]=uvec3(4,5,6);
    gl_PrimitiveTriangleIndicesEXT[gl_LocalInvocationIndex+3]=uvec3(5,6,7);
    gl_PrimitiveTriangleIndicesEXT[gl_LocalInvocationIndex+4]=uvec3(0,2,4);
    gl_PrimitiveTriangleIndicesEXT[gl_LocalInvocationIndex+5]=uvec3(2,4,6);
    gl_PrimitiveTriangleIndicesEXT[gl_LocalInvocationIndex+6]=uvec3(1,3,5);
    gl_PrimitiveTriangleIndicesEXT[gl_LocalInvocationIndex+7]=uvec3(3,5,7);
    gl_PrimitiveTriangleIndicesEXT[gl_LocalInvocationIndex+8]=uvec3(2,3,6);
    gl_PrimitiveTriangleIndicesEXT[gl_LocalInvocationIndex+9]=uvec3(3,6,7);
    gl_PrimitiveTriangleIndicesEXT[gl_LocalInvocationIndex+10]=uvec3(0,1,4);
    gl_PrimitiveTriangleIndicesEXT[gl_LocalInvocationIndex+11]=uvec3(1,4,5);
}
/*
0 1 2 3 0
4 5 6 7 4
0 1 2
1 2 3
4 5 6
5 6 7
0 1 4
1 4 5
1 2
*/