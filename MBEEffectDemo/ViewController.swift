
import Cocoa
import MetalKit
import SwiftUI

class ViewController: NSViewController {
    var effectRenderer: EffectRenderer? {
        didSet {
            guard let effectRenderer = effectRenderer else {
                mtkView.delegate = nil
                return
            }

            let effect = effectRenderer.effect
            effect.colorPixelFormat = mtkView.colorPixelFormat
            effect.depthPixelFormat = mtkView.depthStencilPixelFormat
            mtkView.device = effectRenderer.device
            mtkView.delegate = effectRenderer

            effectRenderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)

            inspectorView.effect = effect
        }
    }

    @IBOutlet weak var mtkView: MTKView!
    @IBOutlet weak var inspectorView: EffectInspectorView!

    // Ordinarily we'd just let MTKView manage its own display link,
    // but on macOS, this causes a noticeable pause when a popup or
    // context menu closes, since the main run loop is only run in
    // the com.apple.hitoolbox.windows.flushmode mode during
    // menu animation. So, to avoid such hitches, we run our own
    // display link and force synchronous draw submission.
    private var displayLink: CVDisplayLink?

    override func viewDidLoad() {
        super.viewDidLoad()

        mtkView.colorPixelFormat = .bgra8Unorm_srgb
        mtkView.depthStencilPixelFormat = .depth32Float
        mtkView.isPaused = true
        mtkView.enableSetNeedsDisplay = false
    }

    func displayLinkDidFire() {
        // Draw immediately. We don't use the setNeedsDisplay mechanism
        // because we're on a background thread and setNeedsDisplay is
        // not thread-safe. Using setNeedsDisplay may also cause us to
        // wait until the next display update, whereas doing it synchronously
        // gets us to the glass as quickly as possible.
        // We might be able to get the same effect by merging into a
        // dispatch source configured with the appropriate run loop modes,
        // but we'll use the bigger hammer for now.
        mtkView.draw()
    }

    override func viewDidAppear() {
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        if let displayLink = displayLink {
            CVDisplayLinkSetOutputHandler(displayLink) { [unowned self]
                displayLink, callbackTimeStamp, presentationTimeStamp, options, outOptions in
                self.displayLinkDidFire()
                return kCVReturnSuccess
            }
            CVDisplayLinkStart(displayLink)
        }
    }

    override func viewDidDisappear() {
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
        }
        displayLink = nil
    }
}
