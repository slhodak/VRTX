import SwiftUI
import MetalKit
import simd
import os

struct Vertex {
    var position: vector_float4
    var color: vector_float4
    
    func scale(by scalar: Float) -> Vertex {
        return Vertex(position: [
            position.x * scalar,
            position.y * scalar,
            position.z * scalar,
            position.w
        ],
                      color: self.color
        )
    }
}

@Observable
class Geometry {
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "Geometry")
    var vertices: [Vertex] = [
        Vertex(position: [0.0, -1.0, 0.5, 1.0], color: [1, 0, 0, 1]),
        Vertex(position: [0.5, 0.0, 0.5, 1.0], color: [0, 1, 0, 1]),
        Vertex(position: [1.0, -1.0, 0.5, 1.0], color: [0, 0, 1, 1]),
    ]
    var vertexBuffer: MTLBuffer!
    var scale: Float = 1.0
    var translateX: Float = 0.0
    var translateY: Float = 0.0
    var translateZ: Float = 0.0
    
    func updateVertices(_ vertices: [[Float]]) {
        for (i, vertex) in vertices.enumerated() {
            guard vertex.count == 3 else { continue }
            
            let position = vector_float4(x: vertex[0],
                                         y: vertex[1],
                                         z: vertex[2],
                                         w: 1)
            let color = self.vertices[i].color
            self.vertices[i] = Vertex(position: position, color: color)
        }
        logger.debug("Updated vertices: \(self.vertices)")
    }
    
    func setupVertexBuffer(for device: MTLDevice) {
        let transformedVertices = transform(self.vertices)
        vertexBuffer = device.makeBuffer(bytes: transformedVertices,
                                         length: transformedVertices.count * MemoryLayout<Vertex>.stride,
                                         options: .storageModeShared)
    }
    
    func updateVertexBuffer(for device: MTLDevice) {
        let transformedVertices = transform(self.vertices)
        let newBufferSize = transformedVertices.count * MemoryLayout<Vertex>.stride
        
        // Check if the existing buffer can accommodate the new data
        if newBufferSize > vertexBuffer.length {
            // Reallocate the buffer if new data size exceeds the current buffer size
            vertexBuffer = device.makeBuffer(bytes: transformedVertices,
                                             length: newBufferSize,
                                             options: .storageModeShared)
            if vertexBuffer == nil {
                print("Failed to allocate vertex buffer.")
                return
            }
        } else {
            // Update the buffer contents directly if it fits
            let bufferPointer = vertexBuffer.contents()
            bufferPointer.copyMemory(from: transformedVertices, byteCount: newBufferSize)
        }
    }
    
    func scale(_ vertices: [Vertex]) -> [Vertex] {
        let scaledVertices = vertices.map { vertex in
            vertex.scale(by: scale)
        }
        return scaledVertices
    }
    
    func translateX(_ vertices: [Vertex]) -> [Vertex] {
        // move all vertices along the x axis
        let translatedVertices = vertices.map { vertex in
            Vertex(position: vertex.position + [translateX, 0, 0, 0], color: vertex.color)
        }
        return translatedVertices
    }
    
    func translateY(_ vertices: [Vertex]) -> [Vertex] {
        // move all vertices along the x axis
        let translatedVertices = vertices.map { vertex in
            Vertex(position: vertex.position + [0, translateY, 0, 0], color: vertex.color)
        }
        return translatedVertices
    }
    
    func translateZ(_ vertices: [Vertex]) -> [Vertex] {
        // move all vertices along the x axis
        let translatedVertices = vertices.map { vertex in
            Vertex(position: vertex.position + [0, 0, translateZ, 0], color: vertex.color)
        }
        return translatedVertices
    }
    
    func transform(_ vertices: [Vertex]) -> [Vertex] {
        /// In the future, can apply other transformations here
        var transformedVertices = scale(vertices)
        transformedVertices = translateX(transformedVertices)
        transformedVertices = translateY(transformedVertices)
        transformedVertices = translateZ(transformedVertices)
        return transformedVertices
    }
}
