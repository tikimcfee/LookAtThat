//
//  File.metal
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/7/22.
//

#include <metal_stdlib>
using namespace metal;
#include <SceneKit/scn_metal>
#include "ShaderBridge.h"

struct DefaultSceneNodeBuffer {
    float4x4 modelTransform;
    float4x4 modelViewTransform;
    float4x4 normalTransform;
    float4x4 modelViewProjectionTransform;
};

typedef struct {
    float3 position [[ attribute(SCNVertexSemanticPosition) ]];
} DefaultSceneNodeVertexInput;

struct SimpleVertex
{
    float4 position [[position]];
};


vertex SimpleVertex MetalLinkDefaultSceneNodeVertexName(DefaultSceneNodeVertexInput in [[ stage_in ]],
                                                        constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                                                        constant DefaultSceneNodeBuffer& scn_node [[buffer(1)]])
{
    SimpleVertex vert;
    vert.position = scn_node.modelViewProjectionTransform * float4(in.position, 1.0);
    
    return vert;
}

fragment half4 MetalLinkDefaultSceneNodeFragmentName(SimpleVertex in [[stage_in]])
{
    half4 color;
    color = half4(0.03 ,0.15 ,0.32, 1.0);
    
    return color;
}
