//
//  debug.metal
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/20/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

typedef struct {
    vector_float2 position;
    vector_float2 textureCoordinate;
} VSVertex;

typedef struct {
    // The [[position]] attribute qualifier of this member indicates this value is the clip space
    //   position of the vertex when this structure is returned from the vertex function
    float4 clipSpacePosition [[position]];

    // Since this member does not have a special attribute qualifier, the rasterizer will
    //   interpolate its value with values of other vertices making up the triangle and
    //   pass that interpolated value to the fragment shader for each fragment in that triangle
    float2 textureCoordinate;

} RasterizerData;

vertex RasterizerData basic_vertex(unsigned int vid [[ vertex_id ]],
             constant VSVertex *vertices [[buffer(0)]]) {
    RasterizerData out;

    out.clipSpacePosition = float4(vertices[vid].position, 0.0, 1.0);
    out.textureCoordinate = vertices[vid].textureCoordinate;

    return out;
}

fragment float4 basic_fragment(RasterizerData in [[stage_in]],
                               texture2d<half> colorTexture [[ texture(0) ]]) {
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    
    const half4 colorSample = colorTexture.sample (textureSampler, in.textureCoordinate);
    return float4(colorSample);
}


