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
    
    rasterizerData.position =
    sceneConstants.projectionMatrix // camera
        * sceneConstants.viewMatrix     // viewport
        * modelConstants[instanceId].modelMatrix    // transforms
        * float4(vertexIn.position, 1); // current position
    
    rasterizerData.color = modelConstants[instanceId].color;
    
    return rasterizerData;
}

fragment half4 instanced_fragment_function(RasterizerData rasterizerData [[ stage_in ]],
                                           constant Material &material [[ buffer(1) ]]) {
    float4 color = rasterizerData.color;
    
    // Apparently there's an r/g/b/a property on float4
    return half4(color.r, color.g, color.b, color.a);
}
