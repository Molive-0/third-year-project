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
- Vec4Vec4 (returns vec4)
- FloatVec4 (returns vec4)
- Vec4Float (returns vec4)
- Mat2Mat2 (returns mat2)
- Mat2Float (returns mat2)
- FloatMat2 (returns mat2)
- Mat3Mat3 (returns mat3)
- Mat3Float (returns mat3)
- FloatMat3 (returns mat3)
- Mat4Mat4 (returns mat4)
- Mat4Float (returns mat4)
- FloatMat4 (returns mat4)
### duo instructions
- Add
- Sub
- Mul
- Div
- Mod
- Pow
### unary types
- Float
- Vec2
- Vec3
- Vec4
- Mat2
- Mat3
- Mat4
### unary instructions
- abs
- sign
- floor
- ceil
- fract
- sqrt
- inversesqrt
- exp
- exp2
- log
- log2
- sin
- cos
- tan
- asin
- acos
- atan
### Extra Matrix
- MulMat2Vec2 (returns vec2)
- MulVec2Mat2 (returns vec2)
- MulMat3Vec3 (returns vec3)
- MulVec3Mat3 (returns vec3)
- MulMat4Vec4 (returns vec4)
- MulVec4Mat4 (returns vec4)
### Extra Vector
- CrossVec3Vec3 (returns vec3)
- DotVec2Vec2 (returns vec2)
- DotVec3Vec3 (returns vec3)
- DotVec4Vec4 (returns vec4)
- LengthVec2 (returns float)
- LengthVec3 (returns float)
- LengthVec4 (returns float)
- DistanceVec2 (returns float)
- DistanceVec3 (returns float)
- DistanceVec4 (returns float)
- NormaliseVec2 (returns float)
- NormaliseVec3 (returns float)
- NormaliseVec4 (returns float)
## Matrix manipulation
- TransposeMat2
- TransposeMat3
- TransposeMat4
- InvertMat2
- InvertMat3
- InvertMat4
## Promotion and Demotion
- PromoteFloatFloatVec2
- PromoteFloatFloatFloatVec3
- PromoteFloatFloatFloatFloatVec4
- PromoteVec2FloatVec3
- PromoteVec2FloatFloatVec4
- PromoteVec2Vec2Vec4
- PromoteVec3FloatVec4
- Promote4FloatMat2
- Promote2Vec2Mat2
- PromoteVec4Mat2
- Promote3Vec3Mat3
- Promote4Vec4Mat4
- PromoteMat2Mat3
- PromoteMat2Mat4
- Promote4Mat2Mat4
- PromoteMat3Mat4
- DemoteVec2FloatFloat
- DemoteVec3FloatFloatFloat
- DemoteVec4FloatFloatFloatFloat
- DemoteMat2Float
- DemoteMat2Vec2
- DemoteMat2Vec4
- DemoteMat3Vec3
- DemoteMat4Vec4
## Data manipulation
### Types
- Float
- Vec2
- Vec3
- Vec4
- Mat2
- Mat3
- Mat4
### Instructions
- Swap2 (a b -- b a)
- Swap3 (a b c -- c b a)
- [Swap4 (a b c d -- d b c a)]
- Dup (a -- a a)
- Dup2 (a b -- a b a)
- Dup3 (a b c -- a b c a)
- [Dup4 (a b c d-- a b c d a)]
- Drop (a -- )
- Drop2 (a b -- b)
- Drop3 (a b c -- b c)
- [Drop4 (a b c d -- b c d)]
## Extra
- Stop
- Nop