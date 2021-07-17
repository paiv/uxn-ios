#include <metal_stdlib>
#include "MetalShaders.h"

using namespace metal;


struct RasterizerData {
    float4 position [[position]];
    float2 textureCoordinate;
};


vertex RasterizerData
vertexShader(uint vertexId [[vertex_id]],
             constant Vertex* vertexArray [[buffer(VertexInputIndexVertices)]],
             constant vector_uint2* viewportSizePointer [[buffer(VertexInputIndexViewportSize)]]) {
    float2 pixelSpacePosition = vertexArray[vertexId].position.xy;
    float2 viewportSize = float2(*viewportSizePointer);
    
    RasterizerData out;
    out.position = vector_float4(0, 0, 0, 1);
    out.position.xy = pixelSpacePosition / (viewportSize / 2);
    out.textureCoordinate = vertexArray[vertexId].textureCoordinate;
    return out;
}


fragment float4
samplingShader(RasterizerData in [[stage_in]],
               texture2d<half> bgTexture [[texture(TextureIndexBaseColor)]],
               texture2d<half> fgTexture [[texture(TextureIndexForeColor)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    const half4 bg = bgTexture.sample(textureSampler, in.textureCoordinate);
    const half4 fg = fgTexture.sample(textureSampler, in.textureCoordinate);
    const half4 colorSample = mix(bg, fg, fg.a);
    return float4(colorSample);
}
