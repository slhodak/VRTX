import simd

typealias LinAlg = LinearAlgebra

enum LinearAlgebra {
    static func perspectiveMatrix(fovyRadians: Float, aspect: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
        let yScale = 1 / tan(fovyRadians * 0.5)
        let xScale = yScale / aspect
        let zRange = farZ - nearZ
        let zScale = -(farZ + nearZ) / zRange
        let wzScale = -2 * farZ * nearZ / zRange
        
        let p00 = xScale
        let p11 = yScale
        let p22 = zScale
        let p23: Float = -1
        let p32 = wzScale
        
        let mat = matrix_float4x4(columns: (
            vector_float4(p00, 0, 0, 0),
            vector_float4(0, p11, 0, 0),
            vector_float4(0, 0, p22, p23),
            vector_float4(0, 0, p32, 0)
        ))
        
        return mat
    }
    
    static func orthographicMatrix(left: Float, right: Float, bottom: Float, top: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
        let ral = right + left
        let rsl = right - left
        let tab = top + bottom
        let tsb = top - bottom
        let fan = farZ + nearZ
        let fsn = farZ - nearZ
        
        let P = matrix_float4x4(
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
