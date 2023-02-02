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