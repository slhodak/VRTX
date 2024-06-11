import MetalKit
import simd

@Observable
class Material {
    var specularColor = simd_float3(1, 1, 1)  { didSet { handleMaterialUpdate() } }
    var specularPower: Float = 1 { didSet { handleMaterialUpdate() } }
    var baseColorTexture: MTLTexture?
    
    func handleMaterialUpdate() {
        NotificationCenter.default.post(name: .drawMessage, object: self)
    }
}
