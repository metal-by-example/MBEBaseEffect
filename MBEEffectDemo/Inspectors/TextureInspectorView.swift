
import Cocoa
import AppKit
import MetalKit

extension MTLTexture {
    var nsImage: NSImage? {
        let bytesPerRow = width * 4
        let imageBytes = UnsafeMutableRawPointer.allocate(byteCount: bytesPerRow * height, alignment: 4)
        defer { imageBytes.deallocate() }
        getBytes(imageBytes, bytesPerRow: bytesPerRow, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        let context = CGContext(data: imageBytes,
                                width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: bitmapInfo)
        if let cgImage = context?.makeImage() {
            return NSImage(cgImage: cgImage, size: CGSize(width: width, height: height))
        }
        return nil
    }
}

class TextureInspectorView : InspectorView {
    var device: MTLDevice!
    
    var texture: MBEEffectTexture? {
        didSet {
            bindToEffect()
        }
    }

    var title: String {
        get { return titleLabel.stringValue }
        set { titleLabel.stringValue = newValue }
    }

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var enabledButton: NSButton!
    @IBOutlet weak var textureModePopupButton: NSPopUpButton!
    @IBOutlet weak var textureImageWell: NSImageView!

    override var disclosedHeight: CGFloat { return 108 }

    func bindToEffect() {
        guard let texture = texture else { return }

        enabledButton.state = texture.enabled ? .on : .off
        textureModePopupButton.selectItem(at: Int(texture.mode.rawValue - 1))
        textureImageWell.image = texture.texture?.nsImage
    }

    @IBAction func disclosureButtonValueDidChange(_ sender: Any) {
        setDisclosed(disclosureButton!.state == .on, animate: true)
    }

    @IBAction func enabledButtonDidChangeValue(_ sender: Any) {
        guard let texture = texture else { return }
        texture.enabled = enabledButton.state == .on
    }

    @IBAction func textureModeValueDidChange(_ sender: Any) {
        guard let texture = texture else { return }
        texture.mode = MBEEffectTextureMode(rawValue: UInt32(textureModePopupButton.indexOfSelectedItem) + 1) ?? .replace
    }

    @IBAction func textureImageValueDidChange(_ sender: Any) {
        guard let texture = texture else { return }

        if let image = textureImageWell.image,
           let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        {
            let textureOptions = [MTKTextureLoader.Option.generateMipmaps : true]
            let textureLoader = MTKTextureLoader(device: device)
            do {
                let newTexture = try textureLoader.newTexture(cgImage: cgImage, options: textureOptions)
                texture.texture = newTexture
            } catch {
                print("Could not load texture: \(error)")
                textureImageWell.image = nil
            }
        }
    }
}
