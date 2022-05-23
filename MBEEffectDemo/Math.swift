
import simd
import Accelerate

typealias float3 = SIMD3<Float>
typealias float4 = SIMD4<Float>

extension SIMD4 {
    var xyz: SIMD3<Scalar> {
        return SIMD3<Scalar>(x, y, z)
    }
}

extension float4x4 {
    init(scale2D s: SIMD2<Float>) {
        self.init(SIMD4<Float>(s.x,   0, 0, 0),
                  SIMD4<Float>(  0, s.y, 0, 0),
                  SIMD4<Float>(  0,   0, 1, 0),
                  SIMD4<Float>(  0,   0, 0, 1))
    }

    init(rotateZ zRadians: Float) {
        let s = sin(zRadians)
        let c = cos(zRadians)
        self.init(SIMD4<Float>( c, s, 0, 0),
                  SIMD4<Float>(-s, c, 0, 0),
                  SIMD4<Float>( 0, 0, 1, 0),
                  SIMD4<Float>( 0, 0, 0, 1))
    }

    init(translate2D t: SIMD2<Float>) {
        self.init(SIMD4<Float>(  1,   0, 0, 0),
                  SIMD4<Float>(  0,   1, 0, 0),
                  SIMD4<Float>(  0,   0, 1, 0),
                  SIMD4<Float>(t.x, t.y, 0, 1))
    }

    init(scale s: SIMD3<Float>) {
        self.init(SIMD4<Float>(s.x,   0,   0, 0),
                  SIMD4<Float>(  0, s.y,   0, 0),
                  SIMD4<Float>(  0,   0, s.z, 0),
                  SIMD4<Float>(  0,   0,   0, 1))
    }

    init(rotateAbout axis: SIMD3<Float>, byAngle radians: Float) {
        let a = normalize(axis)
        let x = a.x
        let y = a.y
        let z = a.z
        let s = sin(radians)
        let c = cos(radians)

        self.init(
            SIMD4<Float>(x * x + (1 - x * x) * c, x * y * (1 - c) - z * s, x * z * (1 - c) + y * s, 0),
            SIMD4<Float>(x * y * (1 - c) + z * s, y * y + (1 - y * y) * c, y * z * (1 - c) - x * s, 0),
            SIMD4<Float>(x * z * (1 - c) - y * s, y * z * (1 - c) + x * s, z * z + (1 - z * z) * c, 0),
            SIMD4<Float>(                      0,                       0,                       0, 1)
        )
    }

    init(translate t: SIMD3<Float>) {
        self.init(SIMD4<Float>(  1,   0,   0, 0),
                  SIMD4<Float>(  0,   1,   0, 0),
                  SIMD4<Float>(  0,   0,   1, 0),
                  SIMD4<Float>(t.x, t.y, t.z, 1))
    }

    init(lookAt at: SIMD3<Float>, from: SIMD3<Float>, up: SIMD3<Float>) {
        let zNeg = normalize(at - from)
        let x = normalize(cross(zNeg, up))
        let y = normalize(cross(x, zNeg))
        self.init(SIMD4<Float>(x, 0),
                  SIMD4<Float>(y, 0),
                  SIMD4<Float>(-zNeg, 0),
                  SIMD4<Float>(from, 1))
    }

    init(perspectiveProjectionFoVY fovYRadians: Float,
         aspectRatio: Float,
         near: Float,
         far: Float)
    {
        let sy = 1 / tan(fovYRadians * 0.5)
        let sx = sy / aspectRatio
        let zRange = far - near
        let sz = -(far + near) / zRange
        let tz = -2 * far * near / zRange
        self.init(SIMD4<Float>(sx, 0,  0,  0),
                  SIMD4<Float>(0, sy,  0,  0),
                  SIMD4<Float>(0,  0, sz, -1),
                  SIMD4<Float>(0,  0, tz,  0))
    }

    var upperLeft3x3: float3x3 {
        return float3x3(columns.0.xyz, columns.1.xyz, columns.2.xyz)
    }
}
