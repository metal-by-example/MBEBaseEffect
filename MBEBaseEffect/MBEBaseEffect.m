
#import "MBEBaseEffect.h"

#define MBELightCount 3

enum {
    MBEVertexBufferIndexVertexAttributes = 0,
    MBEVertexBufferIndexInstanceConstants = 16,
};

enum {
    MBEFragmentBufferIndexInstanceConstants = 16
};

static float MBERadFromDeg(float x) {
    return x * (M_PI / 180);
}

static float MBEClamp(float lo, float hi, float x) {
    return fmax(lo, fmin(x, hi));
}

static float MBERemap(float a, float b, float c, float d, float t) {
    float p = (t - a) / (b - a);
    return c + p * (d - c);
}

static MBEVector3 MBEMakeVector3(simd_float3 xyz) {
    return (MBEVector3){ xyz[0], xyz[1], xyz[2] };
}

static MBEVector4 MBEMakeVector4(MBEVector3 xyz, float w) {
    return simd_make_float4(xyz.x, xyz.y, xyz.z, w);
}

static MBEMatrix3 MBEMatrix4UpperLeft(MBEMatrix4 mat) {
    return (MBEMatrix3){{
        { mat.columns[0][0], mat.columns[0][1], mat.columns[0][2] },
        { mat.columns[1][0], mat.columns[1][1], mat.columns[1][2] },
        { mat.columns[2][0], mat.columns[2][1], mat.columns[2][2] },
    }};
}

typedef struct { // 96 bytes
    MBEVector4 position;
    MBEVector4 ambientColor;
    MBEVector4 diffuseColor;
    MBEVector4 specularColor;
    MBEVector3 spotDirection;
    float spotExponent;
    float spotCosCutoff;
    float constantAttenuation;
    float linearAttenuation;
    float quadraticAttenuation;
} MBELight;

typedef struct { // 80 bytes
    MBEVector4 ambientColor;
    MBEVector4 diffuseColor;
    MBEVector4 specularColor;
    MBEVector4 emissiveColor;
    float shininess;
    float _pad0, _pad1, _pad2;
} MBEMaterial;

typedef struct { // 32 bytes
    MBEVector4 color;
    MBEFogMode mode;
    float density;
    float start;
    float end;
} MBEFogParams;

typedef struct { // 640 bytes
    MBEMatrix4 modelViewMatrix;
    MBEMatrix4 projectionMatrix;
    MBEMatrix3 normalMatrix;
    MBEMaterial material;
    MBEFogParams fog;
    MBELight lights[MBELightCount];
    MBEVector4 ambientLightColor;
    MBEVector4 constantVertexColor;
    MBEEffectLightingMode lightingMode;
    MBEEffectTextureMode textureModes[2];
    uint32_t colorMaterialEnabled;
    uint32_t lightModelTwoSided;
    uint32_t useConstantColor;
    uint32_t activeLightCount;
    float _pad0;
} MBEInstanceConstants;

@interface MBEBaseEffect (Internal)
- (void)didUpdatePropertyWithKeyPath:(NSString *)keyPath;
@end

@implementation MBEEffectTransform

- (instancetype)init {
    if (self = [super init]) {
        _modelViewMatrix = matrix_identity_float4x4;
        _projectionMatrix = matrix_identity_float4x4;
    }
    return self;
}

- (MBEMatrix3)normalMatrix {
    // FIXME: Technically we want the inverse transpose here.
    return MBEMatrix4UpperLeft(self.modelViewMatrix);
}

@end

@implementation MBEEffectLight : NSObject

- (instancetype)init {
    if (self = [super init]) {
        _enabled = YES;
        _position = simd_make_float4(0.0, 0.0, 1.0, 0.0);
        _ambientColor = simd_make_float4(0.0, 0.0, 0.0, 1.0);
        _diffuseColor = simd_make_float4(1.0, 1.0, 1.0, 1.0);
        _specularColor = simd_make_float4(1.0, 1.0, 1.0, 1.0);
        _spotDirection = (MBEVector3){ 0.0, 0.0, -1.0 };
        _spotExponent = 0.0;
        _spotCutoff = 180.0;
        _constantAttenuation = 1.0;
        _linearAttenuation = 0.0;
        _quadraticAttenuation = 0.0;
        _transform = [MBEEffectTransform new];
    }
    return self;
}

@end

@implementation MBEEffectMaterial

- (instancetype)init {
    if (self = [super init]) {
        _ambientColor = simd_make_float4(0.2, 0.2, 0.2, 1.0);
        _diffuseColor = simd_make_float4(0.8, 0.8, 0.8, 1.0);
        _specularColor = simd_make_float4(0.0, 0.0, 0.0, 1.0);
        _emissiveColor = simd_make_float4(0.0, 0.0, 0.0, 1.0);
        _shininess = 0.0;
    }
    return self;
}

@end

@implementation MBEEffectTexture

- (instancetype)init {
    if (self = [super init]) {
        _enabled = NO;
        _type = MBEEffectTextureType2D;
        _mode = MBEEffectTextureModeReplace;
    }
    return self;
}

@end

@implementation MBEEffectFog

- (instancetype)init {
    if (self = [super init]) {
        _enabled =  NO;
        _mode = MBEFogModeExp;
        _color = simd_make_float4(0.0, 0.0, 0.0, 0.0);
        _density = 1.0;
        _start = 0.0;
        _end = 1.0;
    }
    return self;
}

@end

@interface MBEBaseEffect ()
@property (nonatomic, assign) BOOL needsPipelineUpdate;
@property (nonatomic, strong) id<MTLRenderPipelineState> renderPipelineState;
@end

@implementation MBEBaseEffect

@synthesize colorPixelFormat=_colorPixelFormat;
@synthesize depthPixelFormat=_depthPixelFormat;

+ (MTLVertexDescriptor *)defaultVertexDescriptor {
    MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor vertexDescriptor];
    vertexDescriptor.attributes[MBEEffectVertexAttributePosition].format = MTLVertexFormatFloat3;
    vertexDescriptor.attributes[MBEEffectVertexAttributePosition].bufferIndex = MBEVertexBufferIndexVertexAttributes;
    vertexDescriptor.attributes[MBEEffectVertexAttributePosition].offset = 0;
    vertexDescriptor.attributes[MBEEffectVertexAttributeNormal].format = MTLVertexFormatFloat3;
    vertexDescriptor.attributes[MBEEffectVertexAttributeNormal].bufferIndex = MBEVertexBufferIndexVertexAttributes;
    vertexDescriptor.attributes[MBEEffectVertexAttributeNormal].offset = 12;
    vertexDescriptor.attributes[MBEEffectVertexAttributeColor].format = MTLVertexFormatFloat4;
    vertexDescriptor.attributes[MBEEffectVertexAttributeColor].bufferIndex = MBEVertexBufferIndexVertexAttributes;
    vertexDescriptor.attributes[MBEEffectVertexAttributeColor].offset = 24;
    vertexDescriptor.attributes[MBEEffectVertexAttributeTexCoord0].format = MTLVertexFormatFloat2;
    vertexDescriptor.attributes[MBEEffectVertexAttributeTexCoord0].bufferIndex = MBEVertexBufferIndexVertexAttributes;
    vertexDescriptor.attributes[MBEEffectVertexAttributeTexCoord0].offset = 40;
    vertexDescriptor.attributes[MBEEffectVertexAttributeTexCoord1].format = MTLVertexFormatFloat2;
    vertexDescriptor.attributes[MBEEffectVertexAttributeTexCoord1].bufferIndex = MBEVertexBufferIndexVertexAttributes;
    vertexDescriptor.attributes[MBEEffectVertexAttributeTexCoord1].offset = 48;
    vertexDescriptor.layouts[MBEVertexBufferIndexVertexAttributes].stride = 56;
    return vertexDescriptor;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device {
    return [self initWithDevice:device vertexDescriptor:MBEBaseEffect.defaultVertexDescriptor];
}

- (instancetype)initWithDevice:(id<MTLDevice>)device vertexDescriptor:(MTLVertexDescriptor *)vertexDescriptor {
    if (self = [super init]) {
        _device = device;
        _vertexDescriptor = vertexDescriptor;
        _colorMaterialEnabled = YES;
        _lightModelTwoSided = NO;
        _useConstantColor = YES;
        _transform = [MBEEffectTransform new];
        _light0 = [MBEEffectLight new];
        _light1 = [MBEEffectLight new];
        _light1.enabled = NO;
        _light2 = [MBEEffectLight new];
        _light2.enabled = NO;
        _lightingMode = MBEEffectLightingModePerVertex;
        _ambientLightColor = simd_make_float4(0.2, 0.2, 0.2, 1.0);
        _material = [MBEEffectMaterial new];
        _texture0 = [MBEEffectTexture new];
        _texture1 = [MBEEffectTexture new];
        _textureOrder = @[_texture0, _texture1];
        _constantColor = simd_make_float4(1.0, 1.0, 1.0, 1.0);
        _fog = [MBEEffectFog new];
        _label = @"MBEBaseEffect";
        _colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
        _depthPixelFormat = MTLPixelFormatDepth32Float;
        _needsPipelineUpdate = YES;
    }
    return self;
}

- (void)setColorPixelFormat:(MTLPixelFormat)colorPixelFormat {
    _colorPixelFormat = colorPixelFormat;
    self.needsPipelineUpdate = YES;
}

- (void)setDepthPixelFormat:(MTLPixelFormat)depthPixelFormat {
    _depthPixelFormat = depthPixelFormat;
    self.needsPipelineUpdate = YES;
}

- (void)makePipeline {
    NSError *error = nil;

    id<MTLLibrary> library = [_device newDefaultLibrary];
    id<MTLFunction> vertexFunction = [library newFunctionWithName:@"vertex_base_effect"];
    id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"fragment_base_effect"];

    MTLRenderPipelineDescriptor *renderPipelineDescriptor = [MTLRenderPipelineDescriptor new];
    renderPipelineDescriptor.vertexFunction = vertexFunction;
    renderPipelineDescriptor.fragmentFunction = fragmentFunction;
    renderPipelineDescriptor.vertexDescriptor = self.vertexDescriptor;
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat;
    renderPipelineDescriptor.colorAttachments[0].blendingEnabled = YES;
    renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorOne;
    renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorOne;
    renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
    renderPipelineDescriptor.depthAttachmentPixelFormat = self.depthPixelFormat;

    self.renderPipelineState = [self.device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor
                                                                           error:&error];
    if (error != nil) {
        NSLog(@"%@", error);
    }

    _needsPipelineUpdate = NO;
}

- (void)prepareToDraw:(id<MTLRenderCommandEncoder>)renderCommandEncoder {
    if (self.needsPipelineUpdate) {
        [self makePipeline];
    }

    if (self.renderPipelineState == nil) {
        return;
    }

    [renderCommandEncoder pushDebugGroup:[NSString stringWithFormat:@"%@ prepareToDraw", self.label]];

    [renderCommandEncoder setRenderPipelineState:self.renderPipelineState];

    __block MBEInstanceConstants constants;
    memset(&constants, 0, sizeof(MBEInstanceConstants));

    constants.projectionMatrix = self.transform.projectionMatrix;
    constants.modelViewMatrix = self.transform.modelViewMatrix;
    constants.normalMatrix = self.transform.normalMatrix;

    if (self.colorMaterialEnabled) {
        constants.material.ambientColor = self.material.ambientColor;
        constants.material.diffuseColor = self.material.diffuseColor;
        constants.material.specularColor = self.material.specularColor;
        constants.material.emissiveColor = self.material.emissiveColor;
    } else {
        constants.material.ambientColor = simd_make_float4(1, 1, 1, 1);
        constants.material.diffuseColor = simd_make_float4(1, 1, 1, 1);
        constants.material.specularColor = simd_make_float4(1, 1, 1, 1);
        constants.material.emissiveColor = simd_make_float4(0, 0, 0, 1);
    }
    constants.material.shininess = MBERemap(0, 1, 1, 1024, MBEClamp(0, 1, self.material.shininess));

    if (self.fog.enabled) {
        constants.fog.color = self.fog.color;
        constants.fog.mode = self.fog.mode;
        constants.fog.density = self.fog.density;
        constants.fog.start = self.fog.start;
        constants.fog.end = self.fog.end;
    }

    NSArray<MBEEffectLight *> *lights = @[_light0, _light1, _light2];
    __block int activeLightIndex = 0;
    [lights enumerateObjectsUsingBlock:^(MBEEffectLight *light, NSUInteger lightIndex, BOOL *stop) {
        if (!light.enabled) { return; }
        MBEVector4 lightPosition = light.position.w == 0 ?
            simd_make_float4(simd_mul(light.transform.normalMatrix, light.position.xyz), 0) :
            simd_mul(light.transform.modelViewMatrix, light.position);
        constants.lights[activeLightIndex].position = lightPosition;
        constants.lights[activeLightIndex].ambientColor = light.ambientColor;
        constants.lights[activeLightIndex].diffuseColor = light.diffuseColor;
        constants.lights[activeLightIndex].specularColor = light.specularColor;
        MBEVector4 spotDirection = simd_mul(light.transform.modelViewMatrix, MBEMakeVector4(light.spotDirection, 0));
        constants.lights[activeLightIndex].spotDirection = MBEMakeVector3(spotDirection.xyz);
        constants.lights[activeLightIndex].spotExponent = light.spotExponent;
        constants.lights[activeLightIndex].spotCosCutoff = cosf(MBERadFromDeg(light.spotCutoff));
        constants.lights[activeLightIndex].constantAttenuation = light.constantAttenuation;
        constants.lights[activeLightIndex].linearAttenuation = light.linearAttenuation;
        constants.lights[activeLightIndex].quadraticAttenuation = light.quadraticAttenuation;
        activeLightIndex += 1;
    }];

    [self.textureOrder enumerateObjectsUsingBlock:^(MBEEffectTexture *textureObj, NSUInteger index, BOOL *stop) {
        if (!textureObj.enabled) { return; }
        constants.textureModes[index] = textureObj.mode;
        [renderCommandEncoder setFragmentTexture:textureObj.texture atIndex:index];
    }];

    constants.ambientLightColor = self.ambientLightColor;
    constants.constantVertexColor = self.constantColor;
    constants.lightingMode = self.lightingMode;
    constants.colorMaterialEnabled = self.colorMaterialEnabled;
    constants.lightModelTwoSided = self.lightModelTwoSided;
    constants.useConstantColor = self.useConstantColor;
    constants.activeLightCount = activeLightIndex;

    [renderCommandEncoder setVertexBytes:&constants
                                  length:sizeof(MBEInstanceConstants)
                                 atIndex:MBEVertexBufferIndexInstanceConstants];
    [renderCommandEncoder setFragmentBytes:&constants
                                    length:sizeof(MBEInstanceConstants)
                                   atIndex:MBEFragmentBufferIndexInstanceConstants];

    [renderCommandEncoder popDebugGroup];
}

@end
