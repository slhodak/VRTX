//
//  VectorView.swift
//  VRTX
//
//  Created by Sam Hodak on 6/3/24.
//

import Foundation
import SwiftUI
import simd

struct VectorView: View {
    let name: String
    @Binding var vector: simd_float3
    var labels = ["x", "y", "z"]
    
    var body: some View {
        HStack {
            Text(name)
            TextField(labels[0], value: $vector[0], format: .number).frame(width: 45)
            TextField(labels[1], value: $vector[1], format: .number).frame(width: 45)
            TextField(labels[2], value: $vector[2], format: .number).frame(width: 45)
        }
    }
}
