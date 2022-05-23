
import Foundation
import MetalKit

import MetalKit

class EffectRenderer: NSObject, MTKViewDelegate {
    let effect: MBEBaseEffect
    let mesh: MTKMesh
    let device: MTLDevice
    let commandQueue: MTLCommandQueue

    private let depthStencilState: MTLDepthStencilState!
    private var time: Float = 0

    init(mesh: MTKMesh, effect: MBEBaseEffect) {
        self.effect = effect
        self.mesh = mesh

        device = effect.device
        commandQueue = device.makeCommandQueue()!

        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilDescriptor.depthCompareFunction = .lessEqual
        depthStencilState = device.makeDepthStencilState(descriptor:depthStencilDescriptor)!

        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let aspect = Float(size.width / size.height);
        effect.transform.projectionMatrix = simd_float4x4(perspectiveProjectionFoVY: 1.13,
                                                          aspectRatio: aspect,
                                                          near: 0.1,
                                                          far: 150)
    }

    func draw(in view: MTKView) {
        guard let passDescriptor = view.currentRenderPassDescriptor else { return }

        time += 1 / Float(view.preferredFramesPerSecond)

        let viewMatrix = simd_float4x4(translate: float3(0, 0, -2))
        let modelMatrix = simd_float4x4(rotateAbout: float3(1, 0.6, 0.4), byAngle: time)
        effect.transform.modelViewMatrix = viewMatrix * modelMatrix

        // Bit of a hack to ensure that light positions/directions provided via UI are in world space 
        effect.light0.transform.modelViewMatrix = viewMatrix
        effect.light1.transform.modelViewMatrix = viewMatrix
        effect.light2.transform.modelViewMatrix = viewMatrix

        let commandBuffer = commandQueue.makeCommandBuffer()!

        let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor:passDescriptor)!

        renderCommandEncoder.setFrontFacing(.counterClockwise)
        renderCommandEncoder.setCullMode(.back)
        renderCommandEncoder.setDepthStencilState(depthStencilState)

        renderCommandEncoder.pushDebugGroup("Draw mesh")

        effect.prepareToDraw(in: renderCommandEncoder)

        for (index, meshBuffer) in mesh.vertexBuffers.enumerated() {
            renderCommandEncoder.setVertexBuffer(meshBuffer.buffer,
                                                 offset:meshBuffer.offset,
                                                 index:index)
        }

        for submesh in mesh.submeshes {
            renderCommandEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                             indexCount:submesh.indexCount,
                                              indexType:submesh.indexType,
                                            indexBuffer:submesh.indexBuffer.buffer,
                                      indexBufferOffset:submesh.indexBuffer.offset)
        }

        renderCommandEncoder.popDebugGroup()

        renderCommandEncoder.endEncoding()

        commandBuffer.present(view.currentDrawable!)

        commandBuffer.commit()
    }
}
