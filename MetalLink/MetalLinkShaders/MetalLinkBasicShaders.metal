//
//  MetalLinkBasicShaders.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/10/22.
//

#include <metal_stdlib>
//using namespace metal;



#include "../ShaderBridge.h"
#include "MetalLinkShared.metal"

// recall buffer(x) is the Swift-defined buffer position for these vertices
vertex RasterizerData basic_vertex_function(const VertexIn vertexIn [[ stage_in ]],
                                            constant SceneConstants &sceneConstants [[ buffer(1) ]],
                                            constant ModelConstants &modelConstants [[ buffer(2) ]]) {
    RasterizerData rasterizerData;
    
    rasterizerData.position =
    
    sceneConstants.projectionMatrix // camera
    * sceneConstants.viewMatrix     // viewport
    * modelConstants.modelMatrix    // transforms
    * float4(vertexIn.position, 1); // current position
    
    rasterizerData.totalGameTime = sceneConstants.totalGameTime;
    
    rasterizerData.color = vertexIn.color;
    rasterizerData.textureCoordinate = vertexIn.textureCoordinate;
    
    return rasterizerData;
}


fragment half4 basic_fragment_function(RasterizerData rasterizerData [[ stage_in ]],
                                       constant Material &material [[ buffer(1) ]],
                                       texture2d<half> colorTexture [[ texture(0) ]]) { // 0 for per-node, 5 for atlas per this commit. Also set atlas in RootNode
    float2 texCoord = rasterizerData.textureCoordinate;
//    float time = rasterizerData.totalGameTime;
    
    // Sample the texture to obtain a color
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    const half4 color = colorTexture.sample(textureSampler, texCoord);
    
    // Apparently there's an r/g/b/a property on float4
    return half4(color.r, color.g, color.b, color.a);
}
