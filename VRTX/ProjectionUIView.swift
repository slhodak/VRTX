import SwiftUI
import os

struct ProjectionUIView: View {
    let renderer: Renderer
    @State var projection: Projection
    // make projection a property here, wrangle the need to expose it in various places
    // or use a publisher for update events
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "ProjectionUIViewController")
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack() {
                Toggle(isOn: $projection.useProjection) {
                    Text("Projection")
                }
                .onChange(of: projection.useProjection) {
                    renderer.draw()
                }
                Toggle(isOn: $projection.usePerspectiveProjection) {
                    Text("Ortho/Persp")
                }
                .onChange(of: projection.usePerspectiveProjection) {
                    renderer.draw()
                }
            }
            Slider(value: $projection.orthographicTop) {
                Text("Orthographic Top")
            }
            //... more sliders
        }
        .padding()
    }
}
