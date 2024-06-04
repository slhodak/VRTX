import simd

extension simd_float4x4 {
    func toString() -> String {
        return """
        [\(columns.0.x), \(columns.1.x), \(columns.2.x), \(columns.3.x)]
        [\(columns.0.y), \(columns.1.y), \(columns.2.y), \(columns.3.y)]
        [\(columns.0.z), \(columns.1.z), \(columns.2.z), \(columns.3.z)]
        [\(columns.0.w), \(columns.1.w), \(columns.2.w), \(columns.3.w)]
        """
    }
    
    init(scaleBy s: Float) {
        self.init(simd_float4(s, 0, 0, 0),
                  simd_float4(0, s, 0, 0),
                  simd_float4(0, 0, s, 0),
                  simd_float4(0, 0, 0, 1))
    }
    
    init(rotationAbout axis: SIMD3<Float>, by angleRadians: Float) {
        let x = axis.x, y = axis.y, z = axis.z
        let c = cos(angleRadians)
        let s = sinf(angleRadians)
        let t = 1 - c
        self.init(simd_float4( t * x * x + c,     t * x * y + z * s, t * x * z - y * s, 0),
                  simd_float4( t * x * y - z * s, t * y * y + c,     t * y * z + x * s, 0),
                  simd_float4( t * x * z + y * s, t * y * z - x * s,     t * z * z + c, 0),
                  simd_float4(                 0,                 0,                 0, 1))
    }
    
    init(translationBy t: SIMD3<Float>) {
        self.init(simd_float4(1, 0, 0, 0),
                  simd_float4(0, 1, 0, 0),
                  simd_float4(0, 0, 1, 0),
                  simd_float4(t[0], t[1], t[2], 1))
    }
    
    init(perspectiveProjectionFov fovRadians: Float, aspect: Float, near nearZ: Float, far farZ: Float) {
        let yScale = 1 / tan(fovRadians * 0.5)
        let xScale = yScale / aspect
        let zRange = farZ - nearZ
        let zScale = -(farZ + nearZ) / zRange
        let wzScale = -2 * farZ * nearZ / zRange
        
        let xx = xScale
        let yy = yScale
        let zz = zScale
        let zw = Float(-1)
        let wz = wzScale
        
        self.init(simd_float4(xx,  0,  0,  0),
                  simd_float4( 0, yy,  0,  0),
                  simd_float4( 0,  0, zz, zw),
                  simd_float4( 0,  0, wz,  0))
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
    
    var normalMatrix: simd_float3x3 {
        let upperLeft = simd_float3x3(
            simd_float3(self.columns.0.x, self.columns.0.y, self.columns.0.z),
            simd_float3(self.columns.1.x, self.columns.1.y, self.columns.1.z),
            simd_float3(self.columns.2.x, self.columns.2.y, self.columns.2.z)
        )
        
        return upperLeft.transpose.inverse
    }
}
