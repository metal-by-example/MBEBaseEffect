
import Cocoa
import AppKit

class MaterialInspectorView : InspectorView {
    var effect: MBEBaseEffect? {
        didSet {
            bindToEffect()
        }
    }

    @IBOutlet weak var ambientColorWell: NSColorWell!
    @IBOutlet weak var diffuseColorWell: NSColorWell!
    @IBOutlet weak var specularColorWell: NSColorWell!
    @IBOutlet weak var emissiveColorWell: NSColorWell!
    @IBOutlet weak var shininessSlider: NSSlider!

    override var disclosedHeight: CGFloat { return 152 }

    func bindToEffect() {
        guard let effect = effect else { return }
        let material = effect.material
        self.ambientColorWell.color = NSColor(red: CGFloat(material.ambientColor.x),
                                              green: CGFloat(material.ambientColor.y),
                                              blue: CGFloat(material.ambientColor.z),
                                              alpha: CGFloat(material.ambientColor.w))
        self.diffuseColorWell.color = NSColor(red: CGFloat(material.diffuseColor.x),
                                              green: CGFloat(material.diffuseColor.y),
                                              blue: CGFloat(material.diffuseColor.z),
                                              alpha: CGFloat(material.diffuseColor.w))
        self.specularColorWell.color = NSColor(red: CGFloat(material.specularColor.x),
                                               green: CGFloat(material.specularColor.y),
                                               blue: CGFloat(material.specularColor.z),
                                               alpha: CGFloat(material.specularColor.w))
        self.emissiveColorWell.color = NSColor(red: CGFloat(material.emissiveColor.x),
                                               green: CGFloat(material.emissiveColor.y),
                                               blue: CGFloat(material.emissiveColor.z),
                                               alpha: CGFloat(material.emissiveColor.w))
        self.shininessSlider.floatValue = material.shininess
    }

    @IBAction func disclosureButtonValueDidChange(_ sender: Any) {
        setDisclosed(disclosureButton!.state == .on, animate: true)
    }

    @IBAction func ambientColorWellValueDidChange(_ sender: Any) {
        guard let effect = effect else { return }
        let material = effect.material
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        ambientColorWell.color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        material.ambientColor = MBEVector4(Float(red), Float(green), Float(blue), Float(alpha))
    }

    @IBAction func diffuseColorWellValueDidChange(_ sender: Any) {
        guard let effect = effect else { return }
        let material = effect.material
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        diffuseColorWell.color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        material.diffuseColor = MBEVector4(Float(red), Float(green), Float(blue), Float(alpha))
    }

    @IBAction func specularColorWellValueDidChange(_ sender: Any) {
        guard let effect = effect else { return }
        let material = effect.material
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        specularColorWell.color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        material.specularColor = MBEVector4(Float(red), Float(green), Float(blue), Float(alpha))
    }

    @IBAction func emissiveColorWellValueDidChange(_ sender: Any) {
        guard let effect = effect else { return }
        let material = effect.material
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        emissiveColorWell.color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        material.emissiveColor = MBEVector4(Float(red), Float(green), Float(blue), Float(alpha))
    }

    @IBAction func shininessValueDidChange(_ sender: Any) {
        guard let effect = effect else { return }
        let material = effect.material
        material.shininess = shininessSlider.floatValue
    }
}
