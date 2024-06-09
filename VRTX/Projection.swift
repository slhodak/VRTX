import SwiftUI
import MetalKit
import simd

@Observable
class Projection {
    var viewMatrix = matrix_identity_float4x4 { didSet { handleViewMatrixUpdate() } }
    var projectionMatrix = matrix_identity_float4x4
    var viewProjectionMatrix = matrix_identity_float4x4 {
        didSet {
            NotificationCenter.default.post(name: .drawMessage, object: self)
        }
    }
    var projectionPerspectiveAspect: Float { didSet { updateProjectionMatrix() } }
    var usePerspectiveProjection: Bool = true  { didSet { updateProjectionMatrix() } }
    var useProjection: Bool = true  { didSet { updateProjectionMatrix() } }
    var perspectiveFOVYRadians: Float = Float.pi * 0.25  { didSet { updateProjectionMatrix() } }
    var orthographicLeft: Float = 0  { didSet { updateProjectionMatrix() } }
    var orthographicRight: Float = 0  { didSet { updateProjectionMatrix() } }
    var orthographicTop: Float = 0  { didSet { updateProjectionMatrix() } }
    var orthographicBottom: Float = 0  { didSet { updateProjectionMatrix() } }
    var projectionNear: Float = 0.1  { didSet { updateProjectionMatrix() } }
    var projectionFar: Float = 100.0  { didSet { updateProjectionMatrix() } }
    
    init(aspect: Float) {
        projectionPerspectiveAspect = aspect
        viewMatrix = simd_float4x4(translationBy: simd_float3(0, 0, -2))
    }
    
    func handleViewMatrixUpdate() {
        viewProjectionMatrix = projectionMatrix * viewMatrix
    }
    
    func updateProjectionMatrix() {
        if useProjection {
            if usePerspectiveProjection {
                projectionMatrix = simd_float4x4(perspectiveProjectionFov: perspectiveFOVYRadians,
                                                 aspect: projectionPerspectiveAspect,
                                                 near: projectionNear,
                                                 far: projectionFar)
            } else {
                projectionMatrix = simd_float4x4.orthographicMatrix(left: orthographicLeft,
                                                                    right: orthographicRight,
                                                                    bottom: orthographicBottom,
                                                                    top: orthographicTop,
                                                                    nearZ: projectionNear,
                                                                    farZ: projectionFar)
            }
        } else {
            projectionMatrix = matrix_identity_float4x4
        }
        
        viewProjectionMatrix = projectionMatrix * viewMatrix
    }
}
