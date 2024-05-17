import Cocoa

class InputsViewController: NSViewController {
    let renderer: Renderer
    
    var sliders: [String: NSSlider] = [:]
    var sliderValuelabels: [String: NSTextField] = [:]
    var labels: [NSTextField] = []
    var redrawButton: NSButton!
    
    var projectionMatrixSwitch: NSSwitch!
    var orthographicLeftSlider: NSSlider!
    var orthographicRightSlider: NSSlider!
    var orthographicTopSlider: NSSlider!
    var orthographicBottomSlider: NSSlider!
    var projectionNearZSlider: NSSlider!
    var projectionFarZSlider: NSSlider!
    
    init(renderer: Renderer) {
        self.renderer = renderer
        super.init(nibName: nil, bundle: nil)
    }
    
    /// Must implement this method if and only if you plan to instantiate this ViewController in the Storyboard
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibName:bundle:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var topAnchor = view.topAnchor
        topAnchor = setupVertexInputs(topAnchor: topAnchor)
        topAnchor = setupToggleSwitch(topAnchor: topAnchor)
//        topAnchor = setupProjectionMatrixInputs(topAnchor: topAnchor)
        _ = setupRedrawButton(topAnchor: topAnchor)
    }
    
    func setupProjectionMatrixInputs(topAnchor: NSLayoutYAxisAnchor) -> NSLayoutYAxisAnchor {
        return topAnchor
    }
    
    func setupToggleSwitch(topAnchor: NSLayoutYAxisAnchor) -> NSLayoutYAxisAnchor {
        projectionMatrixSwitch = NSSwitch(frame: NSRect(x: 20, y: 20, width: 40, height: 20))
        projectionMatrixSwitch.target = self
        projectionMatrixSwitch.action = #selector(toggleSwitch(_:))
        view.addSubview(projectionMatrixSwitch)
        projectionMatrixSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            projectionMatrixSwitch.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            projectionMatrixSwitch.topAnchor.constraint(equalTo: topAnchor)
        ])
        
        return projectionMatrixSwitch.bottomAnchor
    }
    
    @objc func toggleSwitch(_ sender: NSSwitch) {
        renderer.usePerspectiveProjection = sender.state == .on
    }
    
    func setupRedrawButton(topAnchor: NSLayoutYAxisAnchor) -> NSLayoutYAxisAnchor {
        // Create a button to apply changes and redraw
        redrawButton = NSButton(title: "Redraw", target: self, action: #selector(redrawPressed))
        redrawButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(redrawButton)
        
        NSLayoutConstraint.activate([
            redrawButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            redrawButton.topAnchor.constraint(equalTo: topAnchor, constant: 10)
        ])
        
        return redrawButton.bottomAnchor
    }
    
    func setupVertexInputs(topAnchor: NSLayoutYAxisAnchor) -> NSLayoutYAxisAnchor {
        let axisLabels = ["X", "Y", "Z"]
        var lastTopAnchor = topAnchor
        // Create 3 sliders for each vertex
        for i in 0..<3 {
            // Create one slider each for x, y, and z
            for j in 0..<3 {
                let label = "Vertex \(i+1) \(axisLabels[j])"
                let tag = 100 + (i * 3 + j) /// Use 100s for vertex input slider tags
                lastTopAnchor = createLabeledSlider(label: label,
                                                    tag: tag,
                                                    topAnchor: lastTopAnchor)
            }
        }
        
        return lastTopAnchor
    }
    
    func createLabeledSlider(label: String, tag: Int, topAnchor: NSLayoutYAxisAnchor) -> NSLayoutYAxisAnchor {
        let label = NSTextField(labelWithString: label)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.widthAnchor.constraint(equalToConstant: 62)
        ])
        
        let slider = NSSlider(value: 0.0, minValue: 0.0, maxValue: 10.0, target: self, action: #selector(sliderValueChanged(_:)))
        slider.tag = tag // Use tag to identify the slider
        slider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(slider)
        sliders[String(slider.tag)] = slider
        
        NSLayoutConstraint.activate([
            slider.topAnchor.constraint(equalTo: label.topAnchor),
            slider.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 5),
            slider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
        
        let sliderValueLabel = NSTextField(labelWithString: "0")
        sliderValueLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sliderValueLabel)
        sliderValuelabels[String(slider.tag)] = sliderValueLabel
        
        NSLayoutConstraint.activate([
            sliderValueLabel.topAnchor.constraint(equalTo: slider.topAnchor),
            sliderValueLabel.leadingAnchor.constraint(equalTo: slider.trailingAnchor, constant: 5),
            sliderValueLabel.widthAnchor.constraint(equalToConstant: 62)
        ])
        
        return slider.bottomAnchor
    }
    
    @objc func sliderValueChanged(_ sender: NSSlider) {
        sender.floatValue = sender.floatValue.rounded(to: 2)
        sliderValuelabels[String(sender.tag)]?.stringValue = String(sender.floatValue)
    }
    
    @objc func redrawPressed() {
        // Apply slider values to vertex positions
        var vertexData: [Vertex] = []
        for i in 0..<3 {
            guard let x = sliders[String(i * 3)]?.floatValue,
                  let y = sliders[String(i * 3 + 1)]?.floatValue,
                  let z = sliders[String(i * 3 + 2)]?.floatValue else {
                print("Missing a slider value in group \(i+1))")
                return
            }
            
            vertexData.append(Vertex(position: [x, y, z, 1.0]))
        }
        
        renderer.updateVertexBuffer(with: vertexData)
        renderer.view.setNeedsDisplay(renderer.view.bounds) // Request redraw
    }
}
