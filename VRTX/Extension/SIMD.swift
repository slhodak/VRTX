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
}
