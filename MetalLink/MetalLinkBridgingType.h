//
//  MetalLinkBridgingType.h
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 9/15/22.
//



#ifndef MetalLinkBridgingType_h
#define MetalLinkBridgingType_h
#include <simd/simd.h>
// TODO: Make `uint` type a bridged name.


struct BasicModelConstants {
    simd_float4x4 modelMatrix;
    simd_float4 color;
    uint textureIndex;
    uint pickingId;
};

struct InstancedConstants {
    simd_float4x4 modelMatrix;
    simd_float4 textureDescriptorU;
    simd_float4 textureDescriptorV;
    
    uint instanceID;
    simd_float4 addedColor;
    uint parentIndex; // index of virtualparentconstants from cpu mtlbuffer
    uint bufferIndex; // index of self in cpu mtlbuffer
};

struct SceneConstants {
    float totalGameTime;
    simd_float4x4 viewMatrix;
    simd_float4x4 projectionMatrix;
    simd_float4x4 pointerMatrix;
};

struct VirtualParentConstants {
    // TODO: Use a flag and an index to do the parenting thing
    // Not sure if this will work, but might be able to do
    // parent multiplication on GPU with something like this
//    uint parentBufferIndex;
//    uint useParentBuffer;
    
    simd_float4x4 modelMatrix;
    uint bufferIndex; // index of self in cpu mtlbuffer
};

#endif /* MetalLinkBridgingType_h */




