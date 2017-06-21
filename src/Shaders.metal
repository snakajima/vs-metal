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
    vector_float4 color;
} AAPLVertex;

typedef struct
{
    // The [[position]] attribute qualifier of this member indicates this value is the clip space
    //   position of the vertex when this structure is returned from the vertex function
    float4 clipSpacePosition [[position]];

    // Since this member does not have a special attribute qualifier, the rasterizer will
    //   interpolate its value with values of other vertices making up the triangle and
    //   pass that interpolated value to the fragment shader for each fragment in that triangle
    float4 color;
    float2 textureCoordinate;

} RasterizerData;

vertex RasterizerData basic_vertex(unsigned int vid [[ vertex_id ]],
             constant AAPLVertex *vertices [[buffer(0)]]) {
    RasterizerData out;

    // Initialize our output clip space position
    out.clipSpacePosition = float4(vertices[vid].position, 0.0, 1.0);
    out.color = vertices[vid].color;
    out.textureCoordinate = vertices[vid].textureCoordinate;

    return out;
    //return float4(vertex_array[vid], 1.0);
}

fragment float4 basic_fragment(RasterizerData in [[stage_in]],
                               texture2d<half> colorTexture [[ texture(0) ]]) {
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    
    // Sample the texture and return the color to colorSample
    const half4 colorSample = colorTexture.sample (textureSampler, in.textureCoordinate);
    return float4(colorSample);
    //return in.color;
    //return float4(in.textureCoordinate.x, in.textureCoordinate.y, 0.0, 1.0);
    //return half4(1.0, 1.0, 0.0, 1.0);
}

