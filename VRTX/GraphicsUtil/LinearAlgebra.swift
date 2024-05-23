import simd

typealias LinAlg = LinearAlgebra

enum LinearAlgebra {
    static func perspectiveMatrix(fovY: Float, aspect: Float, near: Float, far: Float) -> simd_float4x4 {
        let yScale = 1 / tan(fovY * 0.5)
        let xScale = yScale / aspect
        let zRange = far - near
        let zScale = far / zRange
        let wzScale = zScale * near
        
        let P = simd_float4(xScale, 0, 0, 0)
        let Q = simd_float4(0, yScale, 0, 0)
        let R = simd_float4(0, 0, zScale, 1)
        let S = simd_float4(0, 0, wzScale, 0)
        
        return simd_float4x4(P, Q, R, S)
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
