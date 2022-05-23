
import Cocoa

class LightInspectorView: InspectorView {
    var light: MBEEffectLight? {
        didSet {
            bindToEffect()
        }
    }

    var title: String {
        get {
            return titleLabel.stringValue
        }
        set {
            titleLabel.stringValue = newValue
        }
    }

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var enabledButton: NSButton!
    @IBOutlet weak var lightTypePopupButton: NSPopUpButton!
    @IBOutlet weak var positionDirectionLabel: NSTextField!
    @IBOutlet weak var lightDirectionXTextField: NSTextField!
    @IBOutlet weak var lightDirectionYTextField: NSTextField!
    @IBOutlet weak var lightDirectionZTextField: NSTextField!
    @IBOutlet weak var ambientLightColorWell: NSColorWell!
    @IBOutlet weak var diffuseLightColorWell: NSColorWell!
    @IBOutlet weak var specularLightColorWell: NSColorWell!
    @IBOutlet weak var spotDirectionXTextField: NSTextField!
    @IBOutlet weak var spotDirectionYTextField: NSTextField!
    @IBOutlet weak var spotDirectionZTextField: NSTextField!
    @IBOutlet weak var spotCutoffTextField: NSTextField!
    @IBOutlet weak var spotExponentTextField: NSTextField!
    @IBOutlet weak var attenuationConstantTextField: NSTextField!
    @IBOutlet weak var attenuationLinearTextField: NSTextField!
    @IBOutlet weak var attenuationQuadraticTextField: NSTextField!

    override var disclosedHeight: CGFloat { return 284 }

    func bindToEffect() {
        guard let light = light else { return }

        enabledButton.state = light.enabled ? .on : .off

        if light.position.w == 0 {
            lightTypePopupButton.selectItem(at: 0) // directional
        } else if light.spotCutoff == 180 {
            lightTypePopupButton.selectItem(at: 1) // point
        } else {
            lightTypePopupButton.selectItem(at: 2) // spot
        }

        lightDirectionXTextField.stringValue = NSString(format: "%0.2f", light.position.x) as String
        lightDirectionYTextField.stringValue = NSString(format: "%0.2f", light.position.y) as String
        lightDirectionZTextField.stringValue = NSString(format: "%0.2f", light.position.z) as String

        ambientLightColorWell.color = NSColor(red: CGFloat(light.ambientColor.x),
                                              green: CGFloat(light.ambientColor.y),
                                              blue: CGFloat(light.ambientColor.z),
                                              alpha: CGFloat(light.ambientColor.w))

        diffuseLightColorWell.color = NSColor(red: CGFloat(light.diffuseColor.x),
                                              green: CGFloat(light.diffuseColor.y),
                                              blue: CGFloat(light.diffuseColor.z),
                                              alpha: CGFloat(light.diffuseColor.w))

        specularLightColorWell.color = NSColor(red: CGFloat(light.specularColor.x),
                                              green: CGFloat(light.specularColor.y),
                                              blue: CGFloat(light.specularColor.z),
                                              alpha: CGFloat(light.specularColor.w))

        spotDirectionXTextField.stringValue = NSString(format: "%0.2f", light.spotDirection.x) as String
        spotDirectionYTextField.stringValue = NSString(format: "%0.2f", light.spotDirection.y) as String
        spotDirectionZTextField.stringValue = NSString(format: "%0.2f", light.spotDirection.z) as String
        spotCutoffTextField.stringValue = NSString(format: "%0.1f", light.spotCutoff) as String
        spotExponentTextField.stringValue = NSString(format: "%0.1f", light.spotExponent) as String

        attenuationConstantTextField.stringValue = NSString(format: "%0.2f", light.constantAttenuation) as String
        attenuationLinearTextField.stringValue = NSString(format: "%0.2f", light.linearAttenuation) as String
        attenuationQuadraticTextField.stringValue = NSString(format: "%0.2f", light.quadraticAttenuation) as String
    }

    @IBAction func disclosureButtonValueDidChange(_ sender: Any) {
        setDisclosed(disclosureButton!.state == .on, animate: true)
    }

    @IBAction func enabledButtonValueDidChange(_ sender: Any) {
        light?.enabled = (enabledButton.state == .on)
    }

    @IBAction func lightTypeValueDidChange(_ sender: Any) {
        if lightTypePopupButton.indexOfSelectedItem == 0 {
            light?.position.w = 0
        } else if lightTypePopupButton.indexOfSelectedItem == 1 {
            light?.position.w = 1
            light?.spotCutoff = 180
        } else {
            light?.position.w = 1
        }

        spotCutoffValueDidChange(sender)
    }

    @IBAction func directionXValueDidChange(_ sender: Any) {
        light?.position.x = lightDirectionXTextField.floatValue
    }

    @IBAction func directionYValueDidChange(_ sender: Any) {
        light?.position.y = lightDirectionYTextField.floatValue
    }

    @IBAction func directionZValueDidChange(_ sender: Any) {
        light?.position.z = lightDirectionZTextField.floatValue
    }

    @IBAction func ambientColorValueDidChange(_ sender: Any) {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        ambientLightColorWell.color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        light?.ambientColor = MBEVector4(Float(red), Float(green), Float(blue), Float(alpha))
    }

    @IBAction func diffuseColorValueDidChange(_ sender: Any) {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        diffuseLightColorWell.color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        light?.diffuseColor = MBEVector4(Float(red), Float(green), Float(blue), Float(alpha))
    }

    @IBAction func specularColorValueDidChange(_ sender: Any) {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        specularLightColorWell.color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        light?.specularColor = MBEVector4(Float(red), Float(green), Float(blue), Float(alpha))
    }

    @IBAction func spotDirectionXValueDidChange(_ sender: Any) {
        light?.spotDirection.x = self.spotDirectionXTextField.floatValue
    }

    @IBAction func spotDirectionYValueDidChange(_ sender: Any) {
        light?.spotDirection.y = self.spotDirectionYTextField.floatValue
    }

    @IBAction func spotDirectionZValueDidChange(_ sender: Any) {
        light?.spotDirection.z = self.spotDirectionZTextField.floatValue
    }

    @IBAction func spotCutoffValueDidChange(_ sender: Any) {
        light?.spotCutoff = self.spotCutoffTextField.floatValue
    }

    @IBAction func spotExponentValueDidChange(_ sender: Any) {
        light?.spotExponent = self.spotExponentTextField.floatValue
    }

    @IBAction func attenuationConstantValueDidChange(_ sender: Any) {
        light?.constantAttenuation = attenuationConstantTextField.floatValue
    }

    @IBAction func attenuationLinearValueDidChange(_ sender: Any) {
        light?.linearAttenuation = attenuationLinearTextField.floatValue
    }

    @IBAction func attenuationQuadraticValueDidChange(_ sender: Any) {
        light?.quadraticAttenuation = attenuationQuadraticTextField.floatValue
    }
}
