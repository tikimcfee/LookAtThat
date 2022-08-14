//
//  MetalLinkShared.metal
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/10/22.
//

#include <metal_stdlib>
using namespace metal;

struct SceneConstants {
    float totalGameTime;
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float4x4 pointerMatrix;
};

struct ModelConstants {
    float4x4 modelMatrix;
    float4 color;
    int textureIndex;
    float4 textureUV;
};

struct VertexIn {
    float3 position             [[ attribute(0) ]];
    float4 color                [[ attribute(1) ]];
    float2 textureCoordinate    [[ attribute(2) ]];
};

struct RasterizerData {
    float4 position [[ position ]]; // position implies "don't interpolate this; it's a position"
    float4 color;
    float2 textureCoordinate;
    int textureIndex [[ flat ]]; /* flat = do not interpolate */
    float4 textureUV; /* (left, top, width, height) */
    float totalGameTime;
};

struct Material {
    float4 color;
    bool useMaterialColor;
};
