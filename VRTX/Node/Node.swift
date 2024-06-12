import Foundation
import MetalKit
import simd

struct Light {
    var worldPosition = simd_float3(0, 0, 0)
    var color = simd_float3(1, 1, 1)
}

@Observable
class Node: Identifiable {
    let id = UUID()
    var name: String
    weak var parent: Node?
    var children = [Node]()
    var modelMatrix = matrix_identity_float4x4
    var currentModelMatrix = matrix_identity_float4x4
    var scale = simd_float3(1, 1, 1) { didSet { updateModelMatrix() } }
    var translation = simd_float3(0, 0, 0) { didSet { updateModelMatrix() } }
    var rotationAxis = simd_float3(0, 1, 0) { didSet { updateModelMatrix() } }
    var rotationAngle: Float = 0 { didSet { updateModelMatrix() } }
    var material = Material()
    
    init(name: String) {
        self.name = name
    }
    
    private func updateModelMatrix() {
        currentModelMatrix = getModelMatrix()
        NotificationCenter.default.post(name: .drawMessage, object: self)
    }
    
    func getModelMatrix() -> simd_float4x4 {
        let scaleMatrix = simd_float4x4(scale3D: scale)
        let translate = simd_float4x4(translationBy: translation)
        let rotate = simd_float4x4(rotationAbout: rotationAxis, by: rotationAngle * Float.pi)
        return modelMatrix * rotate * scaleMatrix * translate
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

class VScene {
    var rootNode = Node(name: "Root")
    var ambientLightColor = simd_float3(0, 0, 0)
    var lights = [Light]()
}
