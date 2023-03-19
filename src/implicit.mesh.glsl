// Implicit Mesh shader

#version 460
#extension GL_EXT_mesh_shader:require

#include "include.glsl"
#include "intervals.glsl"

layout(local_size_x=32,local_size_y=1,local_size_z=1)in;
layout(triangles,max_vertices=256,max_primitives=192)out;

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
    
    //This can be optimised
    SetMeshOutputsEXT(256,192);
    mat4 mvp=camera_uniforms.proj*camera_uniforms.view*pc.world;
    uint vindex = gl_LocalInvocationID.x*8;
    uint pindex = gl_LocalInvocationID.x*6;

    //adjust scale and position
    for (int i = 0; i<8; i++)
    {
        positions[i] *= vec4(0.25,0.25,0.25,1.);
        positions[i].x += (bounds[0]-bounds[3])*0.25 * (mod(gl_LocalInvocationID.x,4.)-1.5);
        positions[i].y += (bounds[1]-bounds[4])*0.25 * (mod(floor(gl_LocalInvocationID.x/4.),4.)-1.5);
        positions[i].z += (bounds[2]-bounds[5])*0.25 * (floor(gl_LocalInvocationID.x/16.)-1.5+gl_WorkGroupID.z*2.);
    }

    float[2] check = scene(vec3[2](vec3(positions[0].xyz),vec3(positions[7].xyz)), true);
    if ((check[0] < 0) && (check[1] > 0))
    {
        //mat4 sw=pc.world;
        gl_MeshVerticesEXT[vindex+0].gl_Position=mvp*(positions[0]);
        gl_MeshVerticesEXT[vindex+1].gl_Position=mvp*(positions[1]);
        gl_MeshVerticesEXT[vindex+2].gl_Position=mvp*(positions[2]);
        gl_MeshVerticesEXT[vindex+3].gl_Position=mvp*(positions[3]);
        gl_MeshVerticesEXT[vindex+4].gl_Position=mvp*(positions[4]);
        gl_MeshVerticesEXT[vindex+5].gl_Position=mvp*(positions[5]);
        gl_MeshVerticesEXT[vindex+6].gl_Position=mvp*(positions[6]);
        gl_MeshVerticesEXT[vindex+7].gl_Position=mvp*(positions[7]);
        vertexOutput[vindex+0].position=(positions[0]);
        vertexOutput[vindex+1].position=(positions[1]);
        vertexOutput[vindex+2].position=(positions[2]);
        vertexOutput[vindex+3].position=(positions[3]);
        vertexOutput[vindex+4].position=(positions[4]);
        vertexOutput[vindex+5].position=(positions[5]);
        vertexOutput[vindex+6].position=(positions[6]);
        vertexOutput[vindex+7].position=(positions[7]);

        if(signingvec.x>0){
            gl_PrimitiveTriangleIndicesEXT[pindex+0]=uvec3(4,5,6)+uvec3(vindex);
            gl_PrimitiveTriangleIndicesEXT[pindex+1]=uvec3(5,6,7)+uvec3(vindex);
        }else{
            gl_PrimitiveTriangleIndicesEXT[pindex+0]=uvec3(0,1,2)+uvec3(vindex);
            gl_PrimitiveTriangleIndicesEXT[pindex+1]=uvec3(1,2,3)+uvec3(vindex);
        }
        if(signingvec.y>0){
            gl_PrimitiveTriangleIndicesEXT[pindex+2]=uvec3(2,3,6)+uvec3(vindex);
            gl_PrimitiveTriangleIndicesEXT[pindex+3]=uvec3(7,3,6)+uvec3(vindex);
        }else{
            gl_PrimitiveTriangleIndicesEXT[pindex+2]=uvec3(0,1,4)+uvec3(vindex);
            gl_PrimitiveTriangleIndicesEXT[pindex+3]=uvec3(5,1,4)+uvec3(vindex);
        }
        if(signingvec.z>0){
            gl_PrimitiveTriangleIndicesEXT[pindex+4]=uvec3(1,3,5)+uvec3(vindex);
            gl_PrimitiveTriangleIndicesEXT[pindex+5]=uvec3(3,5,7)+uvec3(vindex);
        }else{
            gl_PrimitiveTriangleIndicesEXT[pindex+4]=uvec3(0,2,4)+uvec3(vindex);
            gl_PrimitiveTriangleIndicesEXT[pindex+5]=uvec3(2,4,6)+uvec3(vindex);
        }
    } else
    {
        gl_MeshVerticesEXT[vindex+0].gl_Position=vec4(0,0,0,1);
        gl_MeshVerticesEXT[vindex+1].gl_Position=vec4(0,0,0,1);
        gl_MeshVerticesEXT[vindex+2].gl_Position=vec4(0,0,0,1);
        gl_MeshVerticesEXT[vindex+3].gl_Position=vec4(0,0,0,1);
        gl_MeshVerticesEXT[vindex+4].gl_Position=vec4(0,0,0,1);
        gl_MeshVerticesEXT[vindex+5].gl_Position=vec4(0,0,0,1);
        gl_MeshVerticesEXT[vindex+6].gl_Position=vec4(0,0,0,1);
        gl_MeshVerticesEXT[vindex+7].gl_Position=vec4(0,0,0,1);

        gl_PrimitiveTriangleIndicesEXT[pindex+0]=uvec3(0,0,0);
        gl_PrimitiveTriangleIndicesEXT[pindex+1]=uvec3(0,0,0);
        gl_PrimitiveTriangleIndicesEXT[pindex+2]=uvec3(0,0,0);
        gl_PrimitiveTriangleIndicesEXT[pindex+3]=uvec3(0,0,0);
        gl_PrimitiveTriangleIndicesEXT[pindex+4]=uvec3(0,0,0);
        gl_PrimitiveTriangleIndicesEXT[pindex+5]=uvec3(0,0,0);
    }
}