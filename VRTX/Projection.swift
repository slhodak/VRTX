import SwiftUI
import MetalKit
import simd

@Observable
class Projection {
    var projectionMatrix = simd_float4x4(1)
    var projectionPerspectiveAspect: Float
    var usePerspectiveProjection: Bool = true
    var useProjection: Bool = true
    var perspectiveFOVYRadians: Float = Float.pi * 0.25
    var orthographicLeft: Float = 0
    var orthographicRight: Float = 0
    var orthographicTop: Float = 0
    var orthographicBottom: Float = 0
    var projectionNear: Float = 0.0
    var projectionFar: Float = -100.0
    
    init(aspect: Float) {
        projectionPerspectiveAspect = aspect
    }
    
    func updateProjectionMatrix(for device: MTLDevice) {
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
            
            //logger.debug("Projection matrix set with fov: \(self.perspectiveFOVRadians()), aspect: \(self.projectionPerspectiveAspect), near: \(self.projectionNear), far: \(self.projectionFar)")
        }
    }
}
