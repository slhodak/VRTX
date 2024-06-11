import SwiftUI

struct MaterialUIView: View {
    @State var material: Material
    
    var body: some View {
        VStack {
            Text("Materials").bold()
            VectorView(name: "Specular Color",
                       vector: $material.specularColor,
                       labels: ["r", "g", "b"])
            LabeledSlider(name: "Specular Power",
                          value: $material.specularPower,
                          min: 0,
                          max: 300)
        }
    }
}
