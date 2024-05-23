import SwiftUI
import simd

struct Matrix4x4View: View {
    @Binding var mat: simd_float4x4
    
    var body: some View {
        VStack {
            HStack {
                TextField("m00", value: $mat[0][0], format: .number).frame(width: 45)
                TextField("m01", value: $mat[0][1], format: .number).frame(width: 45)
                TextField("m02", value: $mat[0][2], format: .number).frame(width: 45)
                TextField("m03", value: $mat[0][3], format: .number).frame(width: 45)
            }
            HStack {
                TextField("m10", value: $mat[1][0], format: .number).frame(width: 45)
                TextField("m11", value: $mat[1][1], format: .number).frame(width: 45)
                TextField("m12", value: $mat[1][2], format: .number).frame(width: 45)
                TextField("m13", value: $mat[1][3], format: .number).frame(width: 45)
            }
            HStack {
                TextField("m20", value: $mat[2][0], format: .number).frame(width: 45)
                TextField("m21", value: $mat[2][1], format: .number).frame(width: 45)
                TextField("m22", value: $mat[2][2], format: .number).frame(width: 45)
                TextField("m23", value: $mat[2][3], format: .number).frame(width: 45)
            }
            HStack {
                TextField("m30", value: $mat[3][0], format: .number).frame(width: 45)
                TextField("m31", value: $mat[3][1], format: .number).frame(width: 45)
                TextField("m32", value: $mat[3][2], format: .number).frame(width: 45)
                TextField("m33", value: $mat[3][3], format: .number).frame(width: 45)
            }
        }
    }
}

struct Matrix3x4View: View {
    @Binding var mat: simd_float3x4
    
    var body: some View {
        VStack {
            HStack {
                TextField("m00", value: $mat[0][0], format: .number).frame(width: 45)
                TextField("m01", value: $mat[0][1], format: .number).frame(width: 45)
                TextField("m02", value: $mat[0][2], format: .number).frame(width: 45)
                TextField("m03", value: $mat[0][3], format: .number).frame(width: 45)
            }
            HStack {
                TextField("m10", value: $mat[1][0], format: .number).frame(width: 45)
                TextField("m11", value: $mat[1][1], format: .number).frame(width: 45)
                TextField("m12", value: $mat[1][2], format: .number).frame(width: 45)
                TextField("m13", value: $mat[1][3], format: .number).frame(width: 45)
            }
            HStack {
                TextField("m20", value: $mat[2][0], format: .number).frame(width: 45)
                TextField("m21", value: $mat[2][1], format: .number).frame(width: 45)
                TextField("m22", value: $mat[2][2], format: .number).frame(width: 45)
                TextField("m23", value: $mat[2][3], format: .number).frame(width: 45)
            }
        }
    }
}
