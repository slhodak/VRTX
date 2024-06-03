import Foundation
import MetalKit
import simd

class Node: Identifiable {
    let id = UUID()
    var name: String
    weak var parent: Node?
    var children = [Node]()
    var modelMatrix = matrix_identity_float4x4
    var scale: Float = 1 { didSet { updateModelMatrix() } }
    var translation = simd_float3(0, 0, 0) { didSet { updateModelMatrix() } }
    var rotationAxis = simd_float3(0, 1, 0) { didSet { updateModelMatrix() } }
    var rotationAngle: Float = 0 { didSet { updateModelMatrix() } }
    
    init(name: String) {
        self.name = name
    }
    
    private func updateModelMatrix() {
        NotificationCenter.default.post(name: .drawMessage, object: nil)
    }
    
    func getModelMatrix() -> simd_float4x4 {
        let scaleMatrix = simd_float4x4(scaleBy: scale)
        let translate = simd_float4x4(translationBy: translation)
        let rotate = simd_float4x4(rotationAbout: rotationAxis, by: rotationAngle)
        return modelMatrix * scaleMatrix * rotate * translate
    }
}

class CustomNode: Node {
    var geometry: Geometry
    
    init(name: String, geometry: Geometry) {
        self.geometry = geometry
        super.init(name: name)
    }
}

class ModelNode: Node {
    var mesh: MTKMesh
    
    init(name: String, mesh: MTKMesh) {
        self.mesh = mesh
        super.init(name: name)
    }
}
