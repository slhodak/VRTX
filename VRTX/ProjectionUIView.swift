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
                              min: 0.1,
                              max: 0.9)
                LabeledSlider(name: "Far Z",
                              value: $projection.projectionFar,
                              min: 1,
                              max: 101)
            }
        }
        .padding()
    }
}
