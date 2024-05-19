import SwiftUI
import MetalKit
import simd
import os

struct Vertex {
    var position: vector_float4
}

@Observable
class Geometry {
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "Geometry")
    var vertices: [Vertex] = [
        Vertex(position: [0.0, -1.0, 0.1, 1.0]),
        Vertex(position: [0.5, 0.0, 0.1, 1.0]),
        Vertex(position: [1.0, -1.0, 0.1, 1.0]),
    ]
    var vertexBuffer: MTLBuffer!
    
    func updateVertices(_ vertices: [[Float]]) {
        for (i, vertex) in vertices.enumerated() {
            guard vertex.count == 3 else { continue }
            
            let position = vector_float4(x: vertex[0],
                                         y: vertex[1],
                                         z: vertex[2],
                                         w: 1)
            self.vertices[i] = Vertex(position: position)
        }
        logger.debug("Update vertices: \(self.vertices)")
    }
    
    func setupVertexBuffer(for device: MTLDevice) {
        vertexBuffer = device.makeBuffer(bytes: vertices,
                                         length: vertices.count * MemoryLayout<Vertex>.stride,
                                         options: .storageModeShared)
    }
    
    func updateVertexBuffer(for device: MTLDevice) {
        let newBufferSize = vertices.count * MemoryLayout<Vertex>.stride
        
        // Check if the existing buffer can accommodate the new data
        if newBufferSize > vertexBuffer.length {
            // Reallocate the buffer if new data size exceeds the current buffer size
            vertexBuffer = device.makeBuffer(bytes: vertices,
                                             length: newBufferSize,
                                             options: .storageModeShared)
            if vertexBuffer == nil {
                print("Failed to allocate vertex buffer.")
                return
            }
        } else {
            // Update the buffer contents directly if it fits
            let bufferPointer = vertexBuffer.contents()
            bufferPointer.copyMemory(from: vertices, byteCount: newBufferSize)
        }
    }
    
    func scale(vertices: [Vertex], by scalar: Float) -> [Vertex] {
        var scaledVertices: [Vertex] = []
        for vertex in vertices {
            scaledVertices.append(Vertex(position: vertex.position * scalar))
        }
        
        return scaledVertices
    }
}
