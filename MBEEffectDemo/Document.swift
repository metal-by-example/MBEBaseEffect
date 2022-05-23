
import Cocoa
import MetalKit
import ModelIO

class Document: NSDocument {
    let device: MTLDevice!
    let textureLoader: MTKTextureLoader
    let bufferAllocator: MTKMeshBufferAllocator
    let mesh: MTKMesh
    let effect: MBEBaseEffect

    static var lastCascadePoint = CGPoint.zero

    override init() {
        device = MTLCreateSystemDefaultDevice()!
        effect = MBEBaseEffect(device: device)
        textureLoader = MTKTextureLoader(device: device)
        bufferAllocator = MTKMeshBufferAllocator(device: device)

        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes_[0].name = MDLVertexAttributePosition
        vertexDescriptor.attributes_[0].format = .float3
        vertexDescriptor.attributes_[0].bufferIndex = 0
        vertexDescriptor.attributes_[0].offset = 0
        vertexDescriptor.attributes_[1].name = MDLVertexAttributeNormal
        vertexDescriptor.attributes_[1].format = .float3
        vertexDescriptor.attributes_[1].bufferIndex = 0
        vertexDescriptor.attributes_[1].offset = 12
        vertexDescriptor.attributes_[2].name = MDLVertexAttributeColor
        vertexDescriptor.attributes_[2].format = .float4
        vertexDescriptor.attributes_[2].bufferIndex = 0
        vertexDescriptor.attributes_[2].offset = 24
        vertexDescriptor.attributes_[3].name = MDLVertexAttributeTextureCoordinate
        vertexDescriptor.attributes_[3].format = .float2
        vertexDescriptor.attributes_[3].bufferIndex = 0
        vertexDescriptor.attributes_[3].offset = 40
        vertexDescriptor.attributes_[4].name = MDLVertexAttributeTextureCoordinate
        vertexDescriptor.attributes_[4].format = .float2
        vertexDescriptor.attributes_[4].bufferIndex = 0
        vertexDescriptor.attributes_[4].offset = 48
        vertexDescriptor.layouts_[0].stride = 56

        let mdlMesh = MDLMesh.newBox(withDimensions: SIMD3<Float>(1, 1, 1),
                                     segments: SIMD3<UInt32>(1, 1, 1),
                                     geometryType: .triangles,
                                     inwardNormals: false,
                                     allocator: bufferAllocator)
        mdlMesh.vertexDescriptor = vertexDescriptor

        mesh = try! MTKMesh(mesh: mdlMesh, device: device)

        let textureOptions: [MTKTextureLoader.Option : Any] = [
            .generateMipmaps : true,
        ]
        let textureURL = Bundle.main.url(forResource: "crate", withExtension:"jpg")!
        let crateTexture = try? textureLoader.newTexture(URL: textureURL, options: textureOptions)

        effect.light0.position = float4(1, 1, 1, 0)
        effect.light0.diffuseColor = float4(0.8, 0.8, 0.8, 1)
        effect.light0.specularColor = float4(1, 1, 1, 1)
        effect.light0.ambientColor = float4(0.05, 0.05, 0.05, 1)

        effect.material.diffuseColor = float4(1, 1, 1, 1)
        effect.material.ambientColor = float4(1, 1, 1, 1)
        effect.material.specularColor = float4(1, 1, 1, 1)
        effect.material.shininess = 0.5

        effect.texture0.enabled = true
        effect.texture0.mode = .modulate
        effect.texture0.texture = crateTexture

        effect.lightingMode = .perFragment

        super.init()
    }

    override class var autosavesInPlace: Bool {
        return true
    }

    override func makeWindowControllers() {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier("Document Window Controller")
        let windowController = storyboard.instantiateController(withIdentifier: identifier) as! NSWindowController
        self.addWindowController(windowController)

        if let viewController = windowController.contentViewController as? ViewController {
            let effectRenderer = EffectRenderer(mesh: mesh, effect: effect)
            _ = viewController.view // force load
            viewController.effectRenderer = effectRenderer
        }

        if let cascadePoint = windowController.window?.cascadeTopLeft(from: Document.lastCascadePoint) {
            Document.lastCascadePoint = cascadePoint
        }
    }

    override func data(ofType typeName: String) throws -> Data {
        // Insert code here to write your document to data of the specified type, throwing an error in case of failure.
        // Alternatively, you could remove this method and override fileWrapper(ofType:), write(to:ofType:), or write(to:ofType:for:originalContentsURL:) instead.
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        // Insert code here to read your document from the given data of the specified type, throwing an error in case of failure.
        // Alternatively, you could remove this method and override read(from:ofType:) instead.
        // If you do, you should also override isEntireFileLoaded to return false if the contents are lazily loaded.
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }
}
