
#import <Foundation/Foundation.h>
#import <simd/simd.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct { float x, y, z; } MBEVector3;
typedef simd_float4 MBEVector4;
typedef simd_float3x3 MBEMatrix3;
typedef simd_float4x4 MBEMatrix4;

/*!
 @enum MBEEffectVertexAttribute
 @abstract Indices which indicate the ordering of vertex attributes in meshes and shaders
 */
typedef NS_ENUM(UInt32, MBEEffectVertexAttribute) {
    MBEEffectVertexAttributePosition,  // float3
    MBEEffectVertexAttributeNormal,    // float3
    MBEEffectVertexAttributeColor,     // float4
    MBEEffectVertexAttributeTexCoord0, // float2
    MBEEffectVertexAttributeTexCoord1, // float2
};

/*!
 @enum MBEEffectLightingMode
 @abstract Modes which determine in which stage lighting is calculated
 */
typedef NS_ENUM(UInt32, MBEEffectLightingMode) {
    MBEEffectLightingModePerVertex,
    MBEEffectLightingModePerFragment
};

typedef NS_ENUM(UInt32, MBEEffectTextureType) {
    MBEEffectTextureType2D = 1,
};

/*!
 @enum MBEEffectTextureMode
 @abstract Modes which determine how textures are applied.
 @constant MBEEffectTextureModeReplace The color sampled from the texture replaces any existing fragment color
 @constant MBEEffectTextureModeModulate The color sampled from the texture is multiplied by the existing fragment color
 @constant MBEEffectTextureModeDecal The color sampled from the texture is blended with the existing fragment color
           according to the sampled color's alpha value, and the resulting alpha is the existing color's alpha.
 */
typedef NS_ENUM(UInt32, MBEEffectTextureMode) {
    MBEEffectTextureModeReplace = 1,
    MBEEffectTextureModeModulate,
    MBEEffectTextureModeDecal,
};

/*!
 @enum MBEFogMode
 @abstract Modes that determine how the fog factor is determined
 @constant MBEFogModeExp The fog factor is calculated as the exp of the negative view-space distance
           scaled by the density
 @constant MBEFogModeExp2 The fog factor is calculated as the exp of the negative view-space distance squared
           scaled by the density squared
 @constant MBEFogModeLinear The fog factor is calculated by unlerping the view-space distance
           between the start and end distances
*/
typedef NS_ENUM(UInt32, MBEFogMode) {
    MBEFogModeExp = 1,
    MBEFogModeExp2,
    MBEFogModeLinear,
};

/*!
 @class MBEEffectTransform
 @abstract A collection of transform matrices used to move among coordinate spaces
 */
@interface MBEEffectTransform : NSObject
@property (nonatomic, assign) MBEMatrix4 modelViewMatrix;
@property (nonatomic, assign) MBEMatrix4 projectionMatrix;
@property (nonatomic, readonly) MBEMatrix3 normalMatrix;
@end

/*!
 @class MBEEffectLight
 @abstract A light source
 */
@interface MBEEffectLight : NSObject
/// Enables or disables the light. Default value is YES.
@property (nonatomic, assign) BOOL enabled;
/// The position (point and spot) or direction (directional) of the light.
/// Expressed in model space. Lighting is calculated in eye space, so this
/// vector is transformed by the light's model-view matrix before lighting
/// is performed. Default value is { 0.0, 0.0, 0.0, 1.0 }.
@property (nonatomic, assign) MBEVector4 position;
/// The ambient intensity of the light. Default value is { 0.0, 0.0, 0.0, 1.0 }.
@property (nonatomic, assign) MBEVector4 ambientColor;
/// The diffuse intensity of the light. Default value is { 1.0, 1.0, 1.0, 1.0 }.
@property (nonatomic, assign) MBEVector4 diffuseColor;
/// The specular intensity of the light. Default value is { 1.0, 1.0, 1.0, 1.0 }.
@property (nonatomic, assign) MBEVector4 specularColor;
/// The direction of the spot light. Expressed in model space. Lighting is
/// calculated in eye space, so this vector is transformed by the light's
/// model-view matrix before lighting is performed.
/// Default value is { 0.0, 0.0, -1.0 }.
@property (nonatomic, assign) MBEVector3 spotDirection;
/// The falloff exponent of the spot light. Default value is 0 (hard cutoff).
@property (nonatomic, assign) float spotExponent;
/// The cutoff angle of the spotlight, in degrees. Default value is 180, indicating a point light.
@property (nonatomic, assign) float spotCutoff;
/// The constant distance attenuation term of the light. Default value is 1.
@property (nonatomic, assign) float constantAttenuation;
/// The linear distance attenuation factor of the light. Default value is 0.
@property (nonatomic, assign) float linearAttenuation;
/// The quadratic distance attenuation factor of the light. Default value is 0.
@property (nonatomic, assign) float quadraticAttenuation;
/// A transform for moving lighting vectors from the light's model space
/// into camera space for lighting calculations.
@property (nonatomic, copy) MBEEffectTransform *transform;
@end

/*!
 @class MBEEffectMaterial
 @abstract A material description for surfaces
 */
@interface MBEEffectMaterial : NSObject
/// The ambient reflectance of the material. Default value is { 0.2, 0.2, 0.2, 1.0 }.
@property (nonatomic, assign) MBEVector4 ambientColor;
/// The diffuse reflectance of the material. Default value is { 0.8, 0.8, 0.8, 1.0 }.
@property (nonatomic, assign) MBEVector4 diffuseColor;
/// The specular reflectance of the material. Default value is { 0.0, 0.0, 0.0, 1.0 }.
@property (nonatomic, assign) MBEVector4 specularColor;
/// The emissive intensity of the material. Default value is { 0.0, 0.0, 0.0, 1.0 }.
@property (nonatomic, assign) MBEVector4 emissiveColor;
/// The shininess of the material, between 0 and 1. This is remapped to a specular exponent
/// between 1 and 1024. The default value is 0.
@property (nonatomic, assign) float shininess;
@end

/*!
 @class MBEEffectTexture
 @abstract A texture map
 */
@interface MBEEffectTexture : NSObject
/// Determines whether the texture is enabled. Default value is NO. Ignored if `texture` is nil.
@property (nonatomic, assign) BOOL enabled;
/// The texture resource to sample. Default value is nil.
@property (nonatomic, nullable, strong) id<MTLTexture> texture;
/// The type of the texture. Must be MBEEffectTextureType2D.
@property (nonatomic, assign) MBEEffectTextureType type;
/// The mode of the texture. Determines how the sampled color affects the final fragment color.
@property (nonatomic, assign) MBEEffectTextureMode mode;
@end

/*!
 @class MBEEffectFog
 @abstract A collection of parameters affecting the calculation of fog
 */
@interface MBEEffectFog : NSObject
/// Determines whether fog calculation occurs. Default value is NO.
@property (nonatomic, assign) BOOL enabled;
/// The calculation mode of the fog factor. Default value is MBEFogModeExp.
@property (nonatomic, assign) MBEFogMode mode;
/// The fog color. Default value is { 0.0, 0.0, 0.0, 0.0 }.
@property (nonatomic, assign) MBEVector4 color;
/// The fog density. Default value is 1.
@property (nonatomic, assign) float density;
/// The start distance of the fog in view space. Ignored unless the mode is MBEFogModeLinear. Default value is 0.
@property (nonatomic, assign) float start;
/// The end distance of the fog in view space. Ignored unless the mode is MBEFogModeLinear. Default value is 1.
@property (nonatomic, assign) float end;
@end

/*!
 @class MBEBaseEffect
 @abstract An effect that implements features of the OpenGL ES fixed-function pipeline with Metal shaders.
 */
@interface MBEBaseEffect : NSObject

- (instancetype)initWithDevice:(id<MTLDevice>)device;

- (instancetype)initWithDevice:(id<MTLDevice>)device vertexDescriptor:(MTLVertexDescriptor *)vertexDescriptor;

/// The default, preferred vertex descriptor of meshes rendered by an effect.
@property (class, nonatomic, readonly) MTLVertexDescriptor *defaultVertexDescriptor;

/// A Metal device used to allocate resources internally.
@property (nonatomic, strong) id<MTLDevice> device;

/// The vertex descriptor of meshes rendered by this effect.
@property (nonatomic, readonly) MTLVertexDescriptor *vertexDescriptor;

/// The color pixel format of the first color attachment. Default value is MTLPixelFormatBGRA8Unorm_sRGB.
@property (nonatomic, assign) MTLPixelFormat colorPixelFormat;

/// The pixel format of the depth attachment. Default value is MTLPixelFormatDepth32Float.
@property (nonatomic, assign) MTLPixelFormat depthPixelFormat;

/// If NO, colors specified in the material are ignored by lighting calculations. Default value is YES.
@property (nonatomic, assign) BOOL colorMaterialEnabled;

/// Determines whether lighting is evaluated for back-facing primitives (using a flipped normal). Default is NO.
@property (nonatomic, assign) BOOL lightModelTwoSided;

/// The model-view and projection transforms used to draw meshes
@property (nonatomic, readonly) MBEEffectTransform *transform;

/// A light source. Enabled by default.
@property (nonatomic, readonly) MBEEffectLight *light0;

/// A light source. Disabled by default.
@property (nonatomic, readonly) MBEEffectLight *light1;

/// A light source. Disabled by default.
@property (nonatomic, readonly) MBEEffectLight *light2;

/// The lighting mode of the effect. The default mode is MBELightingModePerVertex.
@property (nonatomic, assign) MBEEffectLightingMode lightingMode;

/// The global ambient light intensity of the scene. Default value is { 0.2, 0.2, 0.2, 1.0 }.
@property (nonatomic, assign) MBEVector4 ambientLightColor;

/// The material state of the effect. Can be updated between calls to `prepareToDraw:`.
@property (nonatomic, readonly) MBEEffectMaterial *material;

/// The texture properties for the first texture stage. Disabled by default.
@property (nonatomic, readonly) MBEEffectTexture *texture0;

/// The texture properties for the second texture stage. Disabled by default.
@property (nonatomic, readonly) MBEEffectTexture *texture1;

/// The order in which texture stages are evaluated. Must only contain `texture0` and `texture`.
/// Default order is [ texture0, texture1 ].
@property (nonatomic, nullable, copy) NSArray<MBEEffectTexture*> *textureOrder;

/// Whether to use the constant color in the absence of per-vertex colors. Default is YES.
@property (nonatomic, assign) BOOL useConstantColor;

/// The constant vertex color to use in the absence of per-vertex colors. Default is { 1.0, 1.0, 1.0, 1.0 }.
@property (nonatomic, assign) MBEVector4 constantColor;

/// The fog properties of the effect. Disabled by default.
@property (nonatomic, readonly) MBEEffectFog *fog;

/// A label used to identify the effect. Default value is @"MBEBaseEffect".
@property (nonatomic, nullable, copy) NSString *label;

/// Update values and bind resources in preparation of drawing a mesh with the effect.
- (void)prepareToDraw:(id<MTLRenderCommandEncoder>)renderCommandEncoder NS_SWIFT_NAME(prepareToDraw(in:));

@end

NS_ASSUME_NONNULL_END
