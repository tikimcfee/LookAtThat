//
//  RootShaders.metal
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/11/22.
//

#include <metal_stdlib>
using namespace metal;

// MARK: - I/O Types

// Note; this matches the layout of rootVertexDescriptor in MetalRenderer.swift
struct VertexIn {
    float3 position  [[attribute(0)]];
    float3 normal    [[attribute(1)]];
    float2 texCoords [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 eyeNormal; // the surface normal in camera (“eye”) coordinates
    float4 eyePosition;
    float2 texCoords; // passed through; already in appropriate coordinate space
};

// MARK: - Uniforms

struct Uniforms {
    float4x4 modelViewMatrix;
    float4x4 projectionMatrix;
};

// MARK: - Vertex

vertex VertexOut vertex_main(VertexIn vertexIn [[stage_in]],
                             constant Uniforms &uniforms [[buffer(1)]])
{
    VertexOut vertexOut;
    vertexOut.texCoords = vertexIn.texCoords;
    
    // Move vertex to clip space
    vertexOut.position =
        uniforms.projectionMatrix
        * uniforms.modelViewMatrix
        * float4(vertexIn.position, 1);
    
    // Only move to model space to leave in 'eye' space
    vertexOut.eyePosition =
        uniforms.modelViewMatrix
        * float4(vertexIn.position, 1);
    
    // Leave in eye space to calculate normals (lighting, reflections)
    vertexOut.eyeNormal =
        uniforms.modelViewMatrix
        * float4(vertexIn.normal, 0);
    
    return vertexOut;
}

// MARK: - Fragments

fragment float4 fragment_main(VertexOut fragmentIn [[stage_in]]) {
    return float4(1, 0, 0, 1); // rgba 'red'
}
