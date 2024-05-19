import SwiftUI
import MetalKit
import simd

@Observable
class Projection {
    var projectionMatrix = simd_float4x4(1)
    var projectionMatrixBuffer: MTLBuffer?
    var projectionPerspectiveAspect: Float!
    var usePerspectiveProjection: Bool = false
    var useProjection: Bool = false
    var perspectiveFOVDenominator: Float = 4.0
    var orthographicLeft: Float = 0
    var orthographicRight: Float = 0
    var orthographicTop: Float = 0
    var orthographicBottom: Float = 0
    var projectionNear: Float = 0.0
    var projectionFar: Float = 100.0
    
    func perspectiveFOVRadians() -> Float {
        return Float.pi / perspectiveFOVDenominator
    }
    
    func setProjectionMatrixAspect(for view: NSView) {
        projectionPerspectiveAspect = Float(view.bounds.width / view.bounds.size.height)
    }
    
    func setupProjectionMatrixBuffer(for device: MTLDevice) {
        if useProjection {
            if usePerspectiveProjection {
                projectionMatrix = LinAlg.perspectiveMatrix(fov: perspectiveFOVRadians(),
                                                            aspect: projectionPerspectiveAspect,
                                                            near: projectionNear,
                                                            far: projectionFar)
            } else {
                projectionMatrix = LinAlg.orthographicMatrix(left: orthographicLeft,
                                                             right: orthographicRight,
                                                             bottom: orthographicBottom,
                                                             top: orthographicTop,
                                                             nearZ: projectionNear,
                                                             farZ: projectionFar)
            }
            
            //logger.debug("Projection matrix set with fov: \(self.perspectiveFOVRadians()), aspect: \(self.projectionPerspectiveAspect), near: \(self.projectionNear), far: \(self.projectionFar)")
        } else {
            projectionMatrix = simd_float4x4(1)
        }
        
        projectionMatrixBuffer = device.makeBuffer(bytes: &projectionMatrix,
                                                   length: MemoryLayout<simd_float4x4>.stride,
                                                   options: .storageModeShared)
    }
}
