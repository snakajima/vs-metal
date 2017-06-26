//
//  VSFilters.metal
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/22/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// Rec 709 LUMA values for grayscale image conversion
//constant half3 kRec709Luma = half3(0.2126, 0.7152, 0.0722);

// Grayscale compute kernel
kernel void
mono(texture2d<half, access::read>  inTexture  [[texture(0)]],
                texture2d<half, access::write> outTexture [[texture(1)]],
                const device float3& weight [[ buffer(2) ]],
                const device float4& color [[ buffer(3) ]],
                uint2                          gid         [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }
    
    half4 inColor  = inTexture.read(gid);
    half  gray     = dot(inColor.rgb, half3(weight));
    outTexture.write(half4(gray, gray, gray, inColor.a) * half4(color), gid);
}

kernel void
toone(texture2d<half, access::read>  inTexture  [[texture(0)]],
                texture2d<half, access::write> outTexture [[texture(1)]],
                const device float& levels [[ buffer(2) ]],
                const device float3& weight [[ buffer(3) ]],
                uint2                          gid         [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }

    half3 w = half3(weight / (weight.r + weight.g + weight.b));
    half4 inColor  = inTexture.read(gid);
    half y = dot(inColor.rgb, w);
    half z = floor(y * levels + 0.5) / levels;
    outTexture.write(half4(inColor.rgb * (z / y), inColor.a), gid);
}

