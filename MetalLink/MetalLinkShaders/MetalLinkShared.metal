//
//  MetalLinkShared.metal
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/10/22.
//

#include <metal_stdlib>
using namespace metal;

// MARK: - GPU Constants

struct VertexIn {
    float3 position             [[ attribute(0) ]];
    uint uvTextureIndex         [[ attribute(1) ]];
};

struct RasterizerData {
    float totalGameTime;
    
    float4 position [[ position ]];
    float3 vertexPosition [[ flat ]];
    float2 textureCoordinate;
    
    uint modelInstanceID [[ flat ]];
    float4 addedColor;
};

struct Material {
    float4 color;
    bool useMaterialColor;
};

struct PickingTextureFragmentOut {
    float4 mainColor     [[ color(0) ]];
    uint pickingID       [[ color(1) ]];
};

struct BasicPickingTextureFragmentOut {
    float4 mainColor     [[ color(0) ]];
    uint pickingID       [[ color(2) ]];
};
