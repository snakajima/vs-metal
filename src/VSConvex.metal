//
//  VSConvex.metal
//  vs-metal
//
//  Created by satoshi on 6/29/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void
blur(texture2d<half, access::read>  inTexture  [[texture(0)]],
                texture2d<half, access::write> outTexture [[texture(1)]],
                const device float& weight [[ buffer(2) ]],
                uint2                          gid         [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }

    half4 inColor = inTexture.read(uint2(gid.x, gid.y-1));
    half4 n = inTexture.read(uint2(gid.x, gid.y-1));
    half4 s = inTexture.read(uint2(gid.x, gid.y+1));
    half4 e = inTexture.read(uint2(gid.x+1, gid.y));
    half4 w = inTexture.read(uint2(gid.x-1, gid.y));
    half4 nw = inTexture.read(uint2(gid.x-1, gid.y-1));
    half4 ne = inTexture.read(uint2(gid.x+1, gid.y-1));
    half4 sw = inTexture.read(uint2(gid.x-1, gid.y+1));
    half4 se = inTexture.read(uint2(gid.x+1, gid.y+1));
    half4 outColor = (inColor + n + s + e + w + nw + ne + sw + se) / 9.0;
    outTexture.write(outColor, gid);
}

// NOTE: Identical to blur
kernel void
anti_alias(texture2d<half, access::read>  inTexture  [[texture(0)]],
                texture2d<half, access::write> outTexture [[texture(1)]],
                const device float& weight [[ buffer(2) ]],
                uint2                          gid         [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }

    half4 inColor = inTexture.read(uint2(gid.x, gid.y-1));
    half4 n = inTexture.read(uint2(gid.x, gid.y-1));
    half4 s = inTexture.read(uint2(gid.x, gid.y+1));
    half4 e = inTexture.read(uint2(gid.x+1, gid.y));
    half4 w = inTexture.read(uint2(gid.x-1, gid.y));
    half4 nw = inTexture.read(uint2(gid.x-1, gid.y-1));
    half4 ne = inTexture.read(uint2(gid.x+1, gid.y-1));
    half4 sw = inTexture.read(uint2(gid.x-1, gid.y+1));
    half4 se = inTexture.read(uint2(gid.x+1, gid.y+1));
    half4 outColor = (inColor + n + s + e + w + nw + ne + sw + se) / 9.0;
    outTexture.write(outColor, gid);
}


kernel void
sobel(texture2d<half, access::read>  inTexture  [[texture(0)]],
                texture2d<half, access::write> outTexture [[texture(1)]],
                const device float& weight [[ buffer(2) ]],
                uint2                          gid         [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }
    
    half n = inTexture.read(uint2(gid.x, gid.y-1)).r;
    half s = inTexture.read(uint2(gid.x, gid.y+1)).r;
    half e = inTexture.read(uint2(gid.x+1, gid.y)).r;
    half w = inTexture.read(uint2(gid.x-1, gid.y)).r;
    half nw = inTexture.read(uint2(gid.x-1, gid.y-1)).r;
    half ne = inTexture.read(uint2(gid.x+1, gid.y-1)).r;
    half sw = inTexture.read(uint2(gid.x-1, gid.y+1)).r;
    half se = inTexture.read(uint2(gid.x+1, gid.y+1)).r;
    half dx = weight * (n - s) + (nw + ne - se - sw);
    half dy = weight * (w - e) + (nw + sw - se - ne);
    outTexture.write(half4((dx + 1.0)/2.0, (dy + 1.0)/2.0, sqrt(dx*dy + dy*dy), 1.0), gid);
}

kernel void
canny_edge(texture2d<half, access::read>  inTexture  [[texture(0)]],
                texture2d<half, access::write> outTexture [[texture(1)]],
                const device float& threshold [[ buffer(2) ]],
                const device float& thin [[ buffer(3) ]],
                const device float4& color [[ buffer(4) ]],
                uint2                          gid         [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }

    half3 sobel = inTexture.read(gid).rgb;
    half d = sobel.z;
    half dx2 = sobel.x * sobel.x;
    half dy2 = sobel.y * sobel.y;
    half n = inTexture.read(uint2(gid.x, gid.y-1)).z;
    half s = inTexture.read(uint2(gid.x, gid.y+1)).z;
    half e = inTexture.read(uint2(gid.x+1, gid.y)).z;
    half w = inTexture.read(uint2(gid.x-1, gid.y)).z;
    d = (dx2 < dy2 && d < max(e,w) * thin) ? 0.0 : d;
    d = (dx2 > dy2 && d < max(n,s) * thin) ? 0.0 : d;
    d = (d < threshold) ? 0.0 : color.a;
    outTexture.write(half4(half3(color.rgb), d), gid);
}

kernel void
emboss(texture2d<half, access::read>  inTexture  [[texture(0)]],
                texture2d<half, access::write> outTexture [[texture(1)]],
                const device float& rotation [[ buffer(2) ]],
                uint2                          gid         [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }

    half3 sobel = inTexture.read(gid).rgb;
    half dx = sobel.x * 2.0 - 1.0;
    half dy = sobel.y * 2.0 - 1.0;
    half d = atan2(dy, dx);
    half v = sin(d + rotation) / 2.0 + 0.5;
    outTexture.write(half4(v, v, v, sobel.z), gid);
}

kernel void
mosaic(texture2d<half, access::read>  inTexture  [[texture(0)]],
       texture2d<half, access::write> outTexture [[texture(1)]],
       const device float& size [[ buffer(2) ]],
       uint2                          gid         [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }
    
    uint s = uint(size);
    uint2 gid2 = uint2(gid.x / s * s, gid.y / s * s);
    half4 outColor = inTexture.read(gid2);
    outTexture.write(outColor, gid);
}

