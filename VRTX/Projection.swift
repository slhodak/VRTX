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
    var perspectiveFOVYDenominator: Float = 4.0
    var orthographicLeft: Float = 0
    var orthographicRight: Float = 0
    var orthographicTop: Float = 0
    var orthographicBottom: Float = 0
    var projectionNear: Float = 0.0
    var projectionFar: Float = 100.0
    
    init(size: CGSize) {
        setProjectionMatrixAspect(for: CGSize(width: 500, height: 500))
    }
    
    func perspectiveFOVYRadians() -> Float {
        return Float.pi / perspectiveFOVYDenominator
    }
    
    func setProjectionMatrixAspect(for size: CGSize) {
        projectionPerspectiveAspect = Float(size.width / size.height)
    }
    
    func setupProjectionMatrixBuffer(for device: MTLDevice) {
        if useProjection {
            if usePerspectiveProjection {
                projectionMatrix = LinAlg.perspectiveMatrix(fovY: perspectiveFOVYRadians(),
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
        }
        
        projectionMatrixBuffer = device.makeBuffer(bytes: &projectionMatrix,
                                                   length: MemoryLayout<simd_float4x4>.stride,
                                                   options: .storageModeShared)
    }
}
