import SwiftUI
import MetalKit
import simd
import os

struct Vertex {
    var position: (Float, Float, Float)
    var normal: (Float, Float, Float)
    var texCoords: (Float, Float)
}

@Observable
class Geometry {
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "Geometry")
    var triangleVertexPositions: simd_float3x3 = simd_float3x3(
        [0.0, 2, -5],
        [2, -2, -5],
        [-2, -2, -5]
    )
    var triangleVertexColors: simd_float3x3 = simd_float3x3(
        [1.0, 0.0, 0.0],
        [0.0, 1.0, 0.0],
        [0.0, 0.0, 1.0]
    )
    var vertices = [Vertex]()
    var vertexBuffer: MTLBuffer!
    
    func initVertices() {
        for i in 0..<3 {
            let regularFloatVertexPosition = (triangleVertexPositions[i].x,
                                              triangleVertexPositions[i].y,
                                              triangleVertexPositions[i].z)
            
            vertices.append(Vertex(position: regularFloatVertexPosition,
                                   normal: getNormals(),
                                   texCoords: (0.0, 0.0)))
        }
    }
    
    func updateVertices() {
        vertices = []
        initVertices()
        //logger.debug("Updated vertices: \(self.vertices)")
    }
    
    func setupVertexBuffer(for device: MTLDevice) {
        vertexBuffer = device.makeBuffer(bytes: vertices,
                                         length: vertices.count * MemoryLayout<Vertex>.stride,
                                         options: .storageModeShared)
    }
    
    func updateVertexBuffer(for device: MTLDevice) {
        updateVertices()
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
    
    func getNormals() -> (Float, Float, Float) {
        // Calculate vectors for two edges of the triangle
        let edge1 = triangleVertexPositions[1] - triangleVertexPositions[0]
        let edge2 = triangleVertexPositions[2] - triangleVertexPositions[0]

        // Compute the cross product of the two edge vectors
        let normal = simd_cross(edge1, edge2)

        // Normalize the resulting vector to get the unit normal
        let normalized = simd_normalize(normal)
        // convert this to [[Float]]
        return (normalized.x, normalized.y, normalized.z)
    }
}
