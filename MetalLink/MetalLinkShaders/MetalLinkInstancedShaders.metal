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


float4x4 rotate(float3 axis, float angleRadians) {
    float x = axis.x, y = axis.y, z = axis.z;
    float c = cos(angleRadians);
    float s = sin(angleRadians);
    float t = 1 - c;
    return float4x4(float4( t * x * x + c,     t * x * y + z * s, t * x * z - y * s, 0),
                    float4( t * x * y - z * s, t * y * y + c,     t * y * z + x * s, 0),
                    float4( t * x * z + y * s, t * y * z - x * s,     t * z * z + c, 0),
                    float4(                 0,                 0,                 0, 1));
}


float4x4 rotateAboutX(float angleRadians) {
    constexpr float3 X_AXIS = float3(1, 0, 0);
    return rotate(X_AXIS, angleRadians);
}

float4x4 rotateAboutY(float angleRadians) {
    constexpr float3 X_AXIS = float3(0, 1, 0);
    return rotate(X_AXIS, angleRadians);
}

float4x4 rotateAboutZ(float angleRadians) {
    constexpr float3 X_AXIS = float3(0, 0, 1);
    return rotate(X_AXIS, angleRadians);
}


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
    
    float4x4 finalModel = constants.modelMatrix;
    
//    float4x4 finalModel = constants.modelMatrix
//    * rotateAboutX(cos(sceneConstants.totalGameTime))
//    * rotateAboutY(sin(sceneConstants.totalGameTime));
    
    rasterizerData.position =
    sceneConstants.projectionMatrix // camera
    * sceneConstants.viewMatrix     // viewport
    * finalModel                    // transforms
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
