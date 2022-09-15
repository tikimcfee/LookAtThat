//
//  MetalLinkShared.metal
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/10/22.
//

#include <metal_stdlib>
using namespace metal;

// MARK: - CPU Constants

struct SceneConstants {
    float totalGameTime;
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float4x4 pointerMatrix;
};

struct BasicModelConstants {
    float4x4 modelMatrix;
    float4 color;
    uint textureIndex;
};

struct ModelConstants {
    float4x4 modelMatrix;
    
    float4 textureDescriptorU;
    float4 textureDescriptorV;
    
    uint modelInstanceID;
    float4 addedColor;
    uint parentIndex; // index of virtualparentconstants from cpu mtlbuffer
    uint bufferIndex; // index of self in cpu mtlbuffer
};

struct VirtualParentConstants {
    float4x4 modelMatrix;
    uint bufferIndex; // index of self in cpu mtlbuffer
};

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
