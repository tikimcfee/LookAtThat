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
    
    // Lol indexing into float4
    uint uvIndex = vertexIn.uvTextureIndex;
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
                              address::clamp_to_border,
                              filter::linear);
    
    float4 color = atlas.sample(sampler, rasterizerData.textureCoordinate);
    
    return half4(color.r, color.g, color.b, color.a);
}
