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
    
    rasterizerData.position =
    sceneConstants.projectionMatrix     // camera
    * sceneConstants.viewMatrix     // viewport
    * constants.modelMatrix         // transforms
    * float4(vertexIn.position, 1); // current position
    
    rasterizerData.color = constants.color;
    rasterizerData.textureIndex = constants.textureIndex;
    rasterizerData.totalGameTime = sceneConstants.totalGameTime;
    rasterizerData.textureCoordinate = vertexIn.textureCoordinate;
    rasterizerData.textureUV = constants.textureUV;
    
    return rasterizerData;
}

// [[[ 5 M ]]]]
//fragment half4 instanced_fragment_function(RasterizerData rasterizerData [[ stage_in ]],
//                                           constant Material &material [[ buffer(1) ]],
//                                           texture2d<float, access::sample> atlas [[texture(5)]]) {
//    constexpr sampler sampler(coord::normalized,
//                              address::repeat,
//                              filter::linear);
//    float4 color = atlas.sample(sampler, rasterizerData.textureCoordinate);
//
//    // Apparently there's an r/g/b/a property on float4
//    return half4(color.r, color.g, color.b, color.a);
//}

// [[ W.M. Overflow Math ]]
fragment half4 instanced_fragment_function(RasterizerData rasterizerData [[ stage_in ]],
                                           constant Material &material [[ buffer(1) ]],
                                           texture2d<float, access::sample> atlas [[texture(5)]]) {
    constexpr sampler sampler(coord::normalized,
                              address::repeat,
                              filter::linear);
    
    // original coordinates, normalized with respect to subimage
    float2 rootTextureCoordinate = rasterizerData.textureCoordinate;

    // texture dimensions
    float2 textureSize = float2(atlas.get_width(), atlas.get_height());
    float4 instanceUV = rasterizerData.textureUV;

    // adjusted texture coordinates, normalized with respect to full texture
    rootTextureCoordinate = (rootTextureCoordinate * instanceUV.zw + instanceUV.xy) / textureSize;

    // sample color at modified coordinates
    
    float4 color = atlas.sample(sampler, rootTextureCoordinate);

    // Apparently there's an r/g/b/a property on float4
    return half4(color.r, color.g, color.b, color.a);
}

