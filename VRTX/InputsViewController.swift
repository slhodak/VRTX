import Cocoa
import MetalKit
import os

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
    func vertexSliderValueChanged(name: String, value: Float)
    func projectionSliderValueChanged(name: String, value: Float)
}

class LabeledSlider {
    /// Initialize everything to empty here because we need to use self in the setup function, but cannot use it in init()
    var name = ""
    var type: SliderGroup
    var label = NSTextField()
    var slider = NSSlider()
    var valueLabel = NSTextField()
    var delegate: LabeledSliderDelegate?
    
    init(type: SliderGroup) {
        self.type = type
    }
    
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
        switch self.type {
        case .vertexPosition:
            delegate?.vertexSliderValueChanged(name: name, value: value)
        case .projectionMatrix:
            delegate?.projectionSliderValueChanged(name: name, value: value)
        }
    }
}

enum SliderGroup {
    case vertexPosition
    case projectionMatrix
}

class InputsViewController: NSViewController, LabeledSliderDelegate {
    let renderer: Renderer
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "InputsViewController")
    
    var labeledSliders: [SliderGroup: [String: LabeledSlider]] = [:]
    var redrawButton: NSButton!
    var projectionMatrixSwitch: NSSwitch!
    var projectionMatrixTypeSwitch: NSSwitch!
    
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
    
    func vertexSliderValueChanged(name: String, value: Float) {
        labeledSliders[.vertexPosition]?[name]?.valueLabel.stringValue = String(value)
        
        let nameParts = name.split(separator: "_")
        guard let index = Int(nameParts[0]) else {
            logger.error("Name part \(nameParts[0]) cast to Int failed")
            return
        }
        renderer.updateVertex(index: index, axis: String(nameParts[1]), value: value)
    }
    
    func projectionSliderValueChanged(name: String, value: Float) {
        labeledSliders[.projectionMatrix]?[name]?.valueLabel.stringValue = String(value)
        updateRendererProjectionProperties()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var topAnchor = view.topAnchor
        topAnchor = setupVertexInputs(topAnchor: topAnchor)
        topAnchor = setupLabeledSwitch(name: "Projection", topAnchor: topAnchor, action: #selector(toggleProjectionSwitch(_:)))
        topAnchor = setupLabeledSwitch(name: "Ortho/Persp", topAnchor: topAnchor, action: #selector(toggleProjectionTypeSwitch(_:)))
        topAnchor = setupProjectionMatrixInputs(topAnchor: topAnchor)
        _ = setupRedrawButton(topAnchor: topAnchor)
    }
    
    func setupVertexInputs(topAnchor: NSLayoutYAxisAnchor) -> NSLayoutYAxisAnchor {
        let axisLabels = ["x", "y", "z"]
        var lastTopAnchor = topAnchor
        
        if labeledSliders[.vertexPosition] == nil {
            labeledSliders[.vertexPosition] = [:]
        }
        
        for i in 0..<3 {
            for axisLabel in axisLabels {
                let name = "\(i)_\(axisLabel)"
                let labeledSlider = LabeledSlider(type: .vertexPosition)
                labeledSlider.setup(view: view,
                                    topAnchor: lastTopAnchor,
                                    name: name,
                                    value: 0.0,
                                    minValue: -1.0,
                                    maxValue: 1.0)
                
                labeledSlider.delegate = self
                labeledSliders[.vertexPosition]![name] = labeledSlider
                lastTopAnchor = labeledSlider.slider.bottomAnchor
            }
        }
        
        return lastTopAnchor
    }
    
    func setupProjectionMatrixInputs(topAnchor: NSLayoutYAxisAnchor) -> NSLayoutYAxisAnchor {
        if labeledSliders[.projectionMatrix] == nil {
            labeledSliders[.projectionMatrix] = [:]
        }
        
        var bottomAnchor = addProjectionMatrixSlider(name: "ortho_left", topAnchor: topAnchor)
        bottomAnchor = addProjectionMatrixSlider(name: "ortho_right", topAnchor: bottomAnchor)
        bottomAnchor = addProjectionMatrixSlider(name: "ortho_top", topAnchor: bottomAnchor)
        bottomAnchor = addProjectionMatrixSlider(name: "ortho_bottom", topAnchor: bottomAnchor)
        bottomAnchor = addProjectionMatrixSlider(name: "near_z", topAnchor: bottomAnchor)
        bottomAnchor = addProjectionMatrixSlider(name: "far_z", topAnchor: bottomAnchor)
        
        return bottomAnchor
    }
    
    func addProjectionMatrixSlider(name: String, topAnchor: NSLayoutYAxisAnchor) -> NSLayoutYAxisAnchor {
        let labeledSlider = LabeledSlider(type: .projectionMatrix)
        labeledSlider.setup(view: view,
                            topAnchor: topAnchor,
                            name: name,
                            value: 0.0,
                            minValue: 0.0,
                            maxValue: 100.0)
        labeledSlider.delegate = self
        labeledSliders[.projectionMatrix]![name] = labeledSlider
        
        return labeledSlider.slider.bottomAnchor
    }
    
    func setupLabeledSwitch(name: String, topAnchor: NSLayoutYAxisAnchor, action: Selector) -> NSLayoutYAxisAnchor {
        let label = NSTextField(labelWithString: name)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.widthAnchor.constraint(equalToConstant: 100)
        ])
        
        projectionMatrixSwitch = NSSwitch(frame: NSRect(x: 20, y: 20, width: 40, height: 20))
        projectionMatrixSwitch.target = self
        projectionMatrixSwitch.action = action
        view.addSubview(projectionMatrixSwitch)
        projectionMatrixSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            projectionMatrixSwitch.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            projectionMatrixSwitch.centerXAnchor.constraint(equalTo: label.trailingAnchor),
        ])
        
        return projectionMatrixSwitch.bottomAnchor
    }
    
    @objc func toggleProjectionSwitch(_ sender: NSSwitch) {
        renderer.useProjection = sender.state == .on
        updateRendererProjectionProperties()
    }
    
    @objc func toggleProjectionTypeSwitch(_ sender: NSSwitch) {
        renderer.usePerspectiveProjection = sender.state == .on
        updateRendererProjectionProperties()
    }
    
    func setupRedrawButton(topAnchor: NSLayoutYAxisAnchor) -> NSLayoutYAxisAnchor {
        // Create a button to apply changes and redraw
        redrawButton = NSButton(title: "Redraw", target: self, action: #selector(redraw))
        redrawButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(redrawButton)
        
        NSLayoutConstraint.activate([
            redrawButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            redrawButton.topAnchor.constraint(equalTo: topAnchor, constant: 10)
        ])
        
        return redrawButton.bottomAnchor
    }
    
    @objc func redraw() {
        renderer.draw()
    }
    
    func updateRendererProjectionProperties() {
        guard let projectionMatrixSliders = labeledSliders[.projectionMatrix] else {
            logger.error("No projection sliders found")
            return
        }
        
        for (name, labeledSlider) in projectionMatrixSliders {
            if name == "ortho_Left" {
                renderer.orthographicLeft = labeledSlider.slider.floatValue
            }
            if name == "orthog_right" {
                renderer.orthographicRight = labeledSlider.slider.floatValue
            }
            if name == "ortho_top" {
                renderer.orthographicTop = labeledSlider.slider.floatValue
            }
            if name == "ortho_bottom" {
                renderer.orthographicBottom = labeledSlider.slider.floatValue
            }
            if name == "near_z" {
                renderer.projectionNearZ = labeledSlider.slider.floatValue
            }
            if name == "far_z" {
                renderer.projectionFarZ = labeledSlider.slider.floatValue
            }
        }
    }
}
