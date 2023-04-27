// Implicit Mesh shader

#version 460
#extension GL_EXT_mesh_shader:require

uint DescriptionIndex;

#include "include.glsl"
#include "intervals.glsl"

layout (constant_id = 0) const bool DISABLE_TRACE = false;
layout (constant_id = 1) const bool DISABLE_SCALING_1 = false;
layout (constant_id = 2) const bool DISABLE_SCALING_2 = false;
layout (constant_id = 3) const bool BRUTE_FORCE = false;

layout(local_size_x=32,local_size_y=1,local_size_z=1)in;
layout(triangles,max_vertices=256,max_primitives=192)out;

layout(location=0)out VertexOutput
{
    vec4 position;
}vertexOutput[];

struct MeshMasks
{
    uint8_t masks[32][masklen];  //928
    uint8_t enabled[32];        //32
    vec3 bottomleft;            //12
    vec3 topright;              //12
    uint globalindex;           //4
};                              //total = 988 bytes
taskPayloadSharedEXT MeshMasks meshmasks;

layout(set=0,binding=20, std430)restrict writeonly buffer fragmentMasks{
    uint8_t masks[][masklen];
}fragmentpassmasks;

void main()
{    
    //clear_stacks();
    //default_mask();

    mat4 mvp=camera_uniforms.proj*camera_uniforms.view*pc.world;
    uint vindex = gl_LocalInvocationID.x*8;
    uint pindex = gl_LocalInvocationID.x*6;

    if (BRUTE_FORCE)
    {
        SetMeshOutputsEXT(8,6);
        float[6]bounds=scene_description.desc[gl_WorkGroupID.x+1].bounds;
        vec3 bottomleft = vec3(bounds[3],bounds[4],bounds[5]);
        vec3 topright   = vec3(bounds[0],bounds[1],bounds[2]);   

        vec4[8]positions={
            vec4(bottomleft,1.),
            vec4(bottomleft.x,bottomleft.y,topright.z,1.),
            vec4(bottomleft.x,topright.y,bottomleft.z,1.),
            vec4(bottomleft.x,topright.y,topright.z,1.),
            vec4(topright.x,bottomleft.y,bottomleft.z,1.),
            vec4(topright.x,bottomleft.y,topright.z,1.),
            vec4(topright.x,topright.y,bottomleft.z,1.),
            vec4(topright,1.),
        };  
        
        bvec3 signingvec=greaterThan((inverse(pc.world)*vec4(camera_uniforms.campos,1)).xyz,(topright+bottomleft)/2);

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

        if(signingvec.x){
            gl_PrimitiveTriangleIndicesEXT[0]=uvec3(4,5,6);
            gl_PrimitiveTriangleIndicesEXT[1]=uvec3(5,6,7);
        }else{
            gl_PrimitiveTriangleIndicesEXT[0]=uvec3(0,1,2);
            gl_PrimitiveTriangleIndicesEXT[1]=uvec3(1,2,3);
        }
        if(signingvec.y){
            gl_PrimitiveTriangleIndicesEXT[2]=uvec3(2,3,6);
            gl_PrimitiveTriangleIndicesEXT[3]=uvec3(7,3,6);
        }else{
            gl_PrimitiveTriangleIndicesEXT[2]=uvec3(0,1,4);
            gl_PrimitiveTriangleIndicesEXT[3]=uvec3(5,1,4);
        }
        if(signingvec.z){
            gl_PrimitiveTriangleIndicesEXT[4]=uvec3(1,3,5);
            gl_PrimitiveTriangleIndicesEXT[5]=uvec3(3,5,7);
        }else{
            gl_PrimitiveTriangleIndicesEXT[4]=uvec3(0,2,4);
            gl_PrimitiveTriangleIndicesEXT[5]=uvec3(2,4,6);
        }
        return;
    }

    //This can be optimised
    SetMeshOutputsEXT(256,192);

    vec3 bottomleft = meshmasks.bottomleft;
    vec3 topright = meshmasks.topright;
    vec3 center = (topright + bottomleft) / 2.;
    
    vec4[8]positions={
        vec4(bottomleft,1.),
        vec4(bottomleft.x,bottomleft.y,topright.z,1.),
        vec4(bottomleft.x,topright.y,bottomleft.z,1.),
        vec4(bottomleft.x,topright.y,topright.z,1.),
        vec4(topright.x,bottomleft.y,bottomleft.z,1.),
        vec4(topright.x,bottomleft.y,topright.z,1.),
        vec4(topright.x,topright.y,bottomleft.z,1.),
        vec4(topright,1.),
    };

    uint localindex = uint(meshmasks.enabled[gl_WorkGroupID.x]);
    DescriptionIndex = meshmasks.globalindex/2;

    mask = meshmasks.masks[gl_WorkGroupID.x];

    int GlobalInvocationIndex = int((meshmasks.globalindex*32+localindex)*32+gl_LocalInvocationID.x);
    
    //adjust scale and position
    if (!DISABLE_SCALING_1) {
        for (int i = 0; i<8; i++)
        {
            positions[i] *= vec4(0.25,0.25,0.5,1.);
            positions[i].x += (topright.x-bottomleft.x)*0.25 * (mod(localindex,4.)-1.5) + (topright.x+bottomleft.x)*0.375;
            positions[i].y += (topright.y-bottomleft.y)*0.25 * (mod(floor(localindex/4.),4.)-1.5) + (topright.y+bottomleft.y)*0.375;
            positions[i].z += ((topright.z-bottomleft.z)*0.5 * (floor(localindex/16.)-0.5) + (topright.z+bottomleft.z)*0.25);
        }
    }

    vec4 localtopright=positions[0];
    vec4 localbottomleft=positions[7];

    if (!DISABLE_SCALING_2) {
        for (int i = 0; i<8; i++)
        {
            positions[i] *= vec4(0.25,0.25,0.5,1.);
            positions[i].x += (localtopright.x-localbottomleft.x)*(0.25) * (mod(gl_LocalInvocationID.x,4.)-1.5) + (localtopright.x+localbottomleft.x)*0.375;
            positions[i].y += (localtopright.y-localbottomleft.y)*(0.25) * (mod(floor(gl_LocalInvocationID.x/4.),4.)-1.5) + (localtopright.y+localbottomleft.y)*0.375;
            positions[i].z += (localtopright.z-localbottomleft.z)*(0.5) * (floor(gl_LocalInvocationID.x/16.)-0.5) + (localtopright.z+localbottomleft.z)*0.25;
        }
    }

    bvec3 signingvec=greaterThan((inverse(pc.world)*vec4(camera_uniforms.campos,1)).xyz,(positions[0].xyz+positions[7].xyz)/2);

    gl_MeshPrimitivesEXT[pindex+0].gl_PrimitiveID=GlobalInvocationIndex;
    gl_MeshPrimitivesEXT[pindex+1].gl_PrimitiveID=GlobalInvocationIndex;
    gl_MeshPrimitivesEXT[pindex+2].gl_PrimitiveID=GlobalInvocationIndex;
    gl_MeshPrimitivesEXT[pindex+3].gl_PrimitiveID=GlobalInvocationIndex;
    gl_MeshPrimitivesEXT[pindex+4].gl_PrimitiveID=GlobalInvocationIndex;
    gl_MeshPrimitivesEXT[pindex+5].gl_PrimitiveID=GlobalInvocationIndex;

    bool triangle_fine;
    if (!DISABLE_TRACE) {
        float[2] check = scene(vec3[2](vec3(positions[0].xyz),vec3(positions[7].xyz)), true);
        triangle_fine = (check[0] <= 0) && (check[1] >= 0);
    } else {
        triangle_fine = true;
    }

    if (triangle_fine)
    {
        fragmentpassmasks.masks[GlobalInvocationIndex]=mask;
        
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

        if(signingvec.x){
            gl_PrimitiveTriangleIndicesEXT[pindex+0]=uvec3(4,5,6)+uvec3(vindex);
            gl_PrimitiveTriangleIndicesEXT[pindex+1]=uvec3(5,6,7)+uvec3(vindex);
        }else{
            gl_PrimitiveTriangleIndicesEXT[pindex+0]=uvec3(0,1,2)+uvec3(vindex);
            gl_PrimitiveTriangleIndicesEXT[pindex+1]=uvec3(1,2,3)+uvec3(vindex);
        }
        if(signingvec.y){
            gl_PrimitiveTriangleIndicesEXT[pindex+2]=uvec3(2,3,6)+uvec3(vindex);
            gl_PrimitiveTriangleIndicesEXT[pindex+3]=uvec3(7,3,6)+uvec3(vindex);
        }else{
            gl_PrimitiveTriangleIndicesEXT[pindex+2]=uvec3(0,1,4)+uvec3(vindex);
            gl_PrimitiveTriangleIndicesEXT[pindex+3]=uvec3(5,1,4)+uvec3(vindex);
        }
        if(signingvec.z){
            gl_PrimitiveTriangleIndicesEXT[pindex+4]=uvec3(1,3,5)+uvec3(vindex);
            gl_PrimitiveTriangleIndicesEXT[pindex+5]=uvec3(3,5,7)+uvec3(vindex);
        }else{
            gl_PrimitiveTriangleIndicesEXT[pindex+4]=uvec3(0,2,4)+uvec3(vindex);
            gl_PrimitiveTriangleIndicesEXT[pindex+5]=uvec3(2,4,6)+uvec3(vindex);
        }

    } else
    {
        gl_MeshVerticesEXT[vindex+0].gl_Position=mvp*(vec4(0,0,0,1));
        gl_MeshVerticesEXT[vindex+1].gl_Position=mvp*(vec4(0,0,0,1));
        gl_MeshVerticesEXT[vindex+2].gl_Position=mvp*(vec4(0,0,0,1));
        gl_MeshVerticesEXT[vindex+3].gl_Position=mvp*(vec4(0,0,0,1));
        gl_MeshVerticesEXT[vindex+4].gl_Position=mvp*(vec4(0,0,0,1));
        gl_MeshVerticesEXT[vindex+5].gl_Position=mvp*(vec4(0,0,0,1));
        gl_MeshVerticesEXT[vindex+6].gl_Position=mvp*(vec4(0,0,0,1));
        gl_MeshVerticesEXT[vindex+7].gl_Position=mvp*(vec4(0,0,0,1));

        gl_PrimitiveTriangleIndicesEXT[pindex+0]=uvec3(vindex);
        gl_PrimitiveTriangleIndicesEXT[pindex+1]=uvec3(vindex);
        gl_PrimitiveTriangleIndicesEXT[pindex+2]=uvec3(vindex);
        gl_PrimitiveTriangleIndicesEXT[pindex+3]=uvec3(vindex);
        gl_PrimitiveTriangleIndicesEXT[pindex+4]=uvec3(vindex);
        gl_PrimitiveTriangleIndicesEXT[pindex+5]=uvec3(vindex);
    }
}