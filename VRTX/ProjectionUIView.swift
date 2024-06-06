import SwiftUI
import os

struct ProjectionUIView: View {
    let renderer: Renderer
    @State var projection: Projection
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "ProjectionUIViewController")
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Projection").bold()
            Text("Projection Matrix")
            Matrix4x4View(mat: $projection.projectionMatrix)
                .onChange(of: projection.projectionMatrix) {
                    NotificationCenter.default.post(name: .drawMessage, object: self)
                }
            
            HStack {
                Toggle(isOn: $projection.useProjection) {
                    Text("Use Projection Algorithm")
                }
                Spacer()
            }
            
            if projection.useProjection {
                HStack {
                    Toggle("Orthographic", isOn: $projection.usePerspectiveProjection)
                        .toggleStyle(.switch)
                    Text("Perspective")
                }
                LabeledSlider(name: "Pi FOV Y Radians",
                              value: $projection.perspectiveFOVYRadians,
                              min: Float.pi * 0.10,
                              max: Float.pi * 0.99)
                Text("FOV Degrees: \(projection.perspectiveFOVYRadians/Float.pi * 180)")
                Text("Aspect Ratio: \(projection.projectionPerspectiveAspect)")
                LabeledSlider(name: "Orthographic Top", value: $projection.orthographicTop)
                LabeledSlider(name: "Orthographic Bottom", value: $projection.orthographicBottom)
                LabeledSlider(name: "Orthographic Left", value: $projection.orthographicLeft)
                LabeledSlider(name: "Orthographic Right", value: $projection.orthographicRight)
                LabeledSlider(name: "Near Z",
                              value: $projection.projectionNear,
                              min: -4.5,
                              max: 0)
                LabeledSlider(name: "Far Z",
                              value: $projection.projectionFar,
                              min: -100,
                              max: -5)
            }
        }
        .padding()
        .onChange(of: projection.useProjection) {
            NotificationCenter.default.post(name: .drawMessage, object: self)
        }
        .onChange(of: projection.usePerspectiveProjection) {
            NotificationCenter.default.post(name: .drawMessage, object: self)
        }
        .onChange(of: projection.perspectiveFOVYRadians) {
            NotificationCenter.default.post(name: .drawMessage, object: self)
        }
        .onChange(of: projection.orthographicTop) {
            NotificationCenter.default.post(name: .drawMessage, object: self)
        }
        .onChange(of: projection.orthographicBottom) {
            NotificationCenter.default.post(name: .drawMessage, object: self)
        }
        .onChange(of: projection.orthographicLeft) {
            NotificationCenter.default.post(name: .drawMessage, object: self)
        }
        .onChange(of: projection.orthographicRight) {
            NotificationCenter.default.post(name: .drawMessage, object: self)
        }
        .onChange(of: projection.projectionNear) {
            NotificationCenter.default.post(name: .drawMessage, object: self)
        }
        .onChange(of: projection.projectionFar) {
            NotificationCenter.default.post(name: .drawMessage, object: self)
        }
    }
}
