//
//  MetalLinkBasicShaders.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/10/22.
//

#include <metal_stdlib>
using namespace metal;

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
    
    rasterizerData.color = vertexIn.color;
    rasterizerData.textureCoordinate = vertexIn.textureCoordinate;
    
    return rasterizerData;
}

fragment half4 basic_fragment_function(RasterizerData rasterizerData [[ stage_in ]],
                                       constant Material &material [[ buffer(1) ]]) {
    float4 color = material.useMaterialColor
    ? material.color
    : rasterizerData.color;
    
    // Apparently there's an r/g/b/a property on float4
    return half4(color.r, color.g, color.b, color.a);
}
