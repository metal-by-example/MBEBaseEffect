
import ModelIO

extension MDLVertexDescriptor {
    var attributes_: [MDLVertexAttribute] {
        return attributes as! [MDLVertexAttribute]
    }

    var layouts_: [MDLVertexBufferLayout] {
        return layouts as! [MDLVertexBufferLayout]
    }
}
