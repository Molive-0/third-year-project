# instruction set
## arithmetic
### component-wise types
- FloatFloat (returns float)
- Vec2Vec2 (returns vec2)
- Vec2Float (returns vec2)
- FloatVec2 (returns vec2)
- Vec3Vec3 (returns vec3)
- FloatVec3 (returns vec3)
- Vec3Float (returns vec3)
- Mat2Mat2 + AddVec4Vec4 (returns mat2/vec4)
- Mat2Float + AddVec4Float (returns mat2/vec4)
- FloatMat2 + AddFloatVec4 (returns mat2/vec4)
- Mat3Mat3 (returns mat3)
- Mat3Float (returns mat3)
- FloatMat3 (returns mat3)
- Mat4Mat4 (returns mat4)
- Mat4Float (returns mat4)
- FloatMat4 (returns mat4)
### instructions
- Add
- Sub
- Mul
- Div
### Extra Multiplication
- MulMat2Vec2 (returns vec2)
- MulVec2Mat2 (returns vec2)
- MulMat3Vec3 (returns vec3)
- MulVec3Mat3 (returns vec3)
- MulMat4Vec4 (returns vec4)
- MulVec4Mat4 (returns vec4)
## Matrix manipulation
- TransposeMat2
- TransposeMat3
- TransposeMat4
- InvertMat2
- InvertMat3
- InvertMat4
## Data manipulation
### Types
- Float
- Vec2
- Vec3
- Vec4
- Mat3
- Mat4
### Swaps
SWAP aaabbb
where a is type1  
where b is type2 

### Dups
DUPLICATE aaaddddd
where a is type
where d is distance back in floats