//
//  2ETimeTutorialShader.metal
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/6/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#include "../ShaderBridge.h"
#include "MetalLinkShared.metal"

// MARK: - Instances

// recall buffer(x) is the Swift-defined buffer position for these vertices
vertex RasterizerData instanced_vertex_function(const VertexIn vertexIn [[ stage_in ]],
                                                constant SceneConstants &sceneConstants [[ buffer(1) ]],
                                                constant ModelConstants *modelConstants [[ buffer(2) ]],
                                                uint instanceId [[ instance_id ]] ) {
    RasterizerData rasterizerData;
    ModelConstants constants = modelConstants[instanceId];
    
    rasterizerData.totalGameTime = sceneConstants.totalGameTime;
    rasterizerData.vertexPosition = vertexIn.position;
    
    rasterizerData.position =
        sceneConstants.projectionMatrix // camera
        * sceneConstants.viewMatrix     // viewport
        * constants.modelMatrix         // transforms
        * float4(vertexIn.position, 1); // current position
    
    
    uint uvIndex = vertexIn.uvTextureIndex;
    // Keeping for one commit for posterity: YOU CAN INDEX INTO FLOAT4!?
//    float u = uvIndex == 0 ? constants.textureDescriptorU.x
//    : uvIndex == 1 ? constants.textureDescriptorU.y
//    : uvIndex == 2 ? constants.textureDescriptorU.z
//    : uvIndex == 3 ? constants.textureDescriptorU.w : 0;
//
//    float v = uvIndex == 0 ? constants.textureDescriptorV.x
//    : uvIndex == 1 ? constants.textureDescriptorV.y
//    : uvIndex == 2 ? constants.textureDescriptorV.z
//    : uvIndex == 3 ? constants.textureDescriptorV.w : 0;
    float u = constants.textureDescriptorU[uvIndex];
    float v = constants.textureDescriptorV[uvIndex];
    
    rasterizerData.textureCoordinate = float2(u, v);
    
    return rasterizerData;
}

// [[[ 5 M ]]]]
fragment half4 instanced_fragment_function(RasterizerData rasterizerData [[ stage_in ]],
                                           texture2d<float, access::sample> atlas [[texture(5)]])
{
    constexpr sampler sampler(coord::normalized,
                              address::clamp_to_zero,
                              filter::linear);
    
    float4 color = atlas.sample(sampler, rasterizerData.textureCoordinate);
    
    return half4(color.r, color.g, color.b, color.a);
}
