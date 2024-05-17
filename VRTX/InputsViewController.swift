import Cocoa
import MetalKit

/// I want to add a slider for every property that needs one
/// i want to add that slider by name and associate it with the correct value automatically
/// I want a single method that creates labeled sliders, and takes target properties etc as parameters
///     i can use the label to name the slider in the dictionary, and then read that label to get it back out
///     i could use a switch statement to alter the appropriate value based on the name of the slider...
///         the switch could be exhaustive and safe if I make it choose from an enum

enum ProjectionSlider: String {
    case orthographicLeft
    case orthographicRight
    case orthographicTop
    case orthographicBottom
    case projectionNearZ
    case projectionFarZ
}

protocol LabeledSliderDelegate: AnyObject {
    func labeledSliderValueChanged(name: String, value: Float)
}

class LabeledSlider {
    /// Initialize everything to empty here because we need to use self in the setup function, but cannot use it in init()
    var name = ""
    var label = NSTextField()
    var slider = NSSlider()
    var valueLabel = NSTextField()
    var delegate: LabeledSliderDelegate?
    
    func setup(view: NSView, topAnchor: NSLayoutYAxisAnchor, name: String, value: Double, minValue: Double, maxValue: Double) {
        self.name = name
        label = NSTextField(labelWithString: name)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.widthAnchor.constraint(equalToConstant: 62)
        ])
        
        slider = NSSlider(value: value, minValue: minValue, maxValue: maxValue, target: self, action: #selector(valueChanged(_:)))
        slider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(slider)
        
        NSLayoutConstraint.activate([
            slider.topAnchor.constraint(equalTo: label.topAnchor),
            slider.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 5),
            slider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
        
        valueLabel = NSTextField(labelWithString: "0")
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            valueLabel.topAnchor.constraint(equalTo: slider.topAnchor),
            valueLabel.leadingAnchor.constraint(equalTo: slider.trailingAnchor, constant: 5),
            valueLabel.widthAnchor.constraint(equalToConstant: 62)
        ])
    }
    
    @objc func valueChanged(_ sender: NSSlider) {
        let value = sender.floatValue.rounded(to: 2)
        delegate?.labeledSliderValueChanged(name: name, value: value)
    }
}

enum SliderGroup {
    case vertexPosition
    case projectionMatrix
}

class InputsViewController: NSViewController, LabeledSliderDelegate {
    let renderer: Renderer
    
    var labeledSliders: [SliderGroup: [String: LabeledSlider]] = [:]
    var redrawButton: NSButton!
    var projectionMatrixSwitch: NSSwitch!
    
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
    
    func labeledSliderValueChanged(name: String, value: Float) {
        labeledSliders[.vertexPosition]?[name]?.valueLabel.stringValue = String(value)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var topAnchor = view.topAnchor
        topAnchor = setupVertexInputs(topAnchor: topAnchor)
        topAnchor = setupToggleSwitch(topAnchor: topAnchor)
//        topAnchor = setupProjectionMatrixInputs(topAnchor: topAnchor)
        _ = setupRedrawButton(topAnchor: topAnchor)
    }
    
    func setupVertexInputs(topAnchor: NSLayoutYAxisAnchor) -> NSLayoutYAxisAnchor {
        let axisLabels = ["x", "y", "z"]
        let vertexNames = ["A", "B", "C"]
        var lastTopAnchor = topAnchor
        
        if labeledSliders[.vertexPosition] == nil {
            labeledSliders[.vertexPosition] = [:]
        }
        
        for vertexName in vertexNames {
            for axisLabel in axisLabels {
                let name = "\(vertexName)_\(axisLabel)"
                // get a unique tag int...
                let labeledSlider = LabeledSlider()
                labeledSlider.setup(view: view,
                                    topAnchor: lastTopAnchor,
                                    name: name,
                                    value: 0.0,
                                    minValue: 0.0,
                                    maxValue: 100.0)
                
                labeledSlider.delegate = self
                labeledSliders[.vertexPosition]![name] = labeledSlider
                lastTopAnchor = labeledSlider.slider.bottomAnchor
            }
        }
        
        return lastTopAnchor
    }
    
//    func setupProjectionMatrixInputs(topAnchor: NSLayoutYAxisAnchor) -> NSLayoutYAxisAnchor {
//        var bottomAnchor = addLabeledSlider(label: "Ortho Left", tag: 200, topAnchor: topAnchor)
//        bottomAnchor = addLabeledSlider(label: "Ortho Right", tag: 201, topAnchor: bottomAnchor)
//        bottomAnchor = addLabeledSlider(label: "Ortho Top", tag: 201, topAnchor: bottomAnchor)
//        bottomAnchor = addLabeledSlider(label: "Ortho Bottom", tag: 201, topAnchor: bottomAnchor)
//        bottomAnchor = addLabeledSlider(label: "Ortho Right", tag: 201, topAnchor: bottomAnchor)
//        return bottomAnchor
//    }
    
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
    
    @objc func redrawPressed() {
        /// Collect values from all inputs and use them to update the renderer, then redraw the rendering
        
        /// Collect vertex data from vertex sliders
        guard let vertexPositionSliders = labeledSliders[.vertexPosition] else { return }
        
        let vertices: [String: Vertex] = [
            "A": Vertex(position: vector_float4()),
            "B": Vertex(position: vector_float4()),
            "C": Vertex(position: vector_float4()),
        ]
        /// i want to know which vertex I am working with, and then which axis
        for (name, labeledSlider) in vertexPositionSliders {
            let parts = name.split(separator: "_")
            
            guard var vertex = vertices[String(parts[0])] else { continue }
            
            switch String(parts[1]) {
            case "x":
                vertex.position.x = labeledSlider.slider.floatValue
            case "y":
                vertex.position.y = labeledSlider.slider.floatValue
            case "z":
                vertex.position.z = labeledSlider.slider.floatValue
            default:
                break
            }
            
            vertex.position.w = 1.0
        }
        
        renderer.updateVertexBuffer(with: Array(vertices.values))
        
        /// Collect projection matrix data from projection matrix sliders
        
        
        renderer.view.setNeedsDisplay(renderer.view.bounds) // Request redraw
    }
}
