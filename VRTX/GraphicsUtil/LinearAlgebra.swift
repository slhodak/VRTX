import simd

typealias LinAlg = LinearAlgebra

enum LinearAlgebra {
    static func perspectiveMatrix(fov: Float, aspect: Float, near: Float, far: Float) -> simd_float4x4 {
        let yScale = 1 / tan(fov * 0.5)
        let xScale = yScale / aspect
        let zRange = far - near
        let zScale = -(far + near) / zRange
        let wzScale = -2 * far * near / zRange
        
        let P = simd_float4x4(columns: (
            vector_float4(xScale,   0,      0,      0),
            vector_float4(0,        yScale, 0,      0),
            vector_float4(0,        0,      zScale, wzScale),
            vector_float4(0,        0,      -1,     0)
        ))
        
        return P
    }
    
    static func orthographicMatrix(left: Float, right: Float, bottom: Float, top: Float, nearZ: Float, farZ: Float) -> simd_float4x4 {
        let ral = right + left
        let rsl = right - left
        let tab = top + bottom
        let tsb = top - bottom
        let fan = farZ + nearZ
        let fsn = farZ - nearZ
        
        let P = simd_float4x4(
            columns: (
                vector_float4(2.0 / rsl, 0.0, 0.0, 0.0),
                vector_float4(0.0, 2.0 / tsb, 0.0, 0.0),
                vector_float4(0.0, 0.0, -2.0 / fsn, 0.0),
                vector_float4(-ral / rsl, -tab / tsb, -fan / fsn, 1.0)
            )
        )
        return P
    }
}
