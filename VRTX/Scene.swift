import Foundation
import MetalKit
import simd

class Node: Identifiable {
    let id = UUID()
    var name: String
    weak var parent: Node?
    var children = [Node]()
    var modelMatrix = matrix_identity_float4x4
    
    init(name: String) {
        self.name = name
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
