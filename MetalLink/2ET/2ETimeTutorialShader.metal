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

struct VertexIn {
    float3 position [[ attribute(0) ]]; // 'look at attributes[0] in descriptor
    float4 color    [[ attribute(1) ]];
};

struct RasterizerData {
    float4 position [[ position ]]; // position implies "don't interpolate this; it's a position"
    float4 color;                   // this is interpolated
};

struct ModelConstants {
    float4x4 modelMatrix;
};

struct SceneConstants {
    float4x4 viewMatrix;
    float4x4 pointerMatrix;
};

// recall buffer(x) is the Swift-defined buffer position for these vertices
vertex RasterizerData basic_vertex_function(const VertexIn vertexIn [[ stage_in ]],
                                            constant SceneConstants &sceneConstants [[ buffer(1) ]],
                                            constant ModelConstants &modelConstants [[ buffer(2) ]]) {
    RasterizerData rasterizerData;
    
    rasterizerData.position =
        sceneConstants.viewMatrix
        * sceneConstants.pointerMatrix
        * modelConstants.modelMatrix
        * float4(vertexIn.position, 1);
    
    rasterizerData.color = vertexIn.color;
    
    return rasterizerData;
}


fragment half4 basic_fragment_function(RasterizerData rasterizerData [[ stage_in ]]) {
    float4 color = rasterizerData.color;
    // Apparently there's an r/g/b/a property on float4?!
    return half4(color.r, color.g, color.b, color.a);
}
