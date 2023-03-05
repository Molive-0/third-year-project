; SPIR-V
; Version: 1.5
; Generator: Google Shaderc over Glslang; 11
; Bound: 127
; Schema: 0
               OpCapability Shader
          %1 = OpExtInstImport "GLSL.std.450"
               OpMemoryModel Logical GLSL450
               OpEntryPoint Fragment %4 "main" %67 %72
               OpExecutionMode %4 OriginUpperLeft
               OpDecorate %67 Location 0
               OpDecorate %72 Location 0
       %void = OpTypeVoid
          %3 = OpTypeFunction %void
      %float = OpTypeFloat 32
    %v4float = OpTypeVector %float 4
       %uint = OpTypeInt 32 0
     %uint_2 = OpConstant %uint 2
%_arr_v4float_uint_2 = OpTypeArray %v4float %uint_2
       %bool = OpTypeBool
     %v4bool = OpTypeVector %bool 4
      %false = OpConstantFalse %bool
         %34 = OpConstantComposite %v4bool %false %false %false %false
    %float_0 = OpConstant %float 0
         %38 = OpConstantComposite %v4float %float_0 %float_0 %float_0 %float_0
%_ptr_Input__arr_v4float_uint_2 = OpTypePointer Input %_arr_v4float_uint_2
         %67 = OpVariable %_ptr_Input__arr_v4float_uint_2 Input
%_ptr_Output_v4float = OpTypePointer Output %v4float
         %72 = OpVariable %_ptr_Output_v4float Output
    %float_1 = OpConstant %float 1
          %4 = OpFunction %void None %3
          %5 = OpLabel
         %69 = OpLoad %_arr_v4float_uint_2 %67
        %125 = OpCompositeExtract %v4float %69 0
        %126 = OpCompositeExtract %v4float %69 1
         %86 = OpExtInst %v4float %1 FAbs %125
         %89 = OpExtInst %v4float %1 FAbs %126
         %90 = OpExtInst %v4float %1 FMin %86 %89
         %93 = OpFOrdLessThan %v4bool %125 %38
         %96 = OpFOrdGreaterThan %v4bool %126 %38
         %97 = OpSelect %v4bool %96 %93 %34
        %100 = OpSelect %v4float %97 %38 %90
        %102 = OpExtInst %float %1 Length %100
        %110 = OpExtInst %v4float %1 FMax %86 %89
        %111 = OpExtInst %float %1 Length %110
         %78 = OpCompositeConstruct %v4float %102 %111 %float_0 %float_1
               OpStore %72 %78
               OpReturn
               OpFunctionEnd
