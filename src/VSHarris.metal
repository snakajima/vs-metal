//
//  VSHarris.metal
//  vs-metal
//
//  Created by satoshi on 8/1/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void
derivative(texture2d<half, access::read>  inTexture  [[texture(0)]],
                texture2d<half, access::write> outTexture [[texture(1)]],
                const device float& strength [[ buffer(2) ]],
                uint2 gid [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }
    
    half n = inTexture.read(gid + uint2(0,-1)).r;
    half s = inTexture.read(gid + uint2(0,1)).r;
    half w = inTexture.read(gid + uint2(-1,0)).r;
    half e = inTexture.read(gid + uint2(1,0)).r;
    half nw = inTexture.read(gid + uint2(-1,-1)).r;
    half ne = inTexture.read(gid + uint2(1,-1)).r;
    half sw = inTexture.read(gid + uint2(-1,1)).r;
    half se = inTexture.read(gid + uint2(1,1)).r;
    half dy = strength * (- nw - n - ne + sw + s + se);
    half dx = strength * (- sw - w - nw + se + e + ne);
    half4 outColor = half4(dx * dx, dy * dy , (dx * dy) + 1.0 / 2.0, 1.0);
    outTexture.write(outColor, gid);
}

kernel void
harris_detector(texture2d<half, access::read>  inTexture  [[texture(0)]],
                texture2d<half, access::write> outTexture [[texture(1)]],
                const device float& sensitivity [[ buffer(2) ]],
                uint2 gid [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }

    half3 inColor = inTexture.read(gid).xyz;
    half sum = inColor.x + inColor.y;
    half z = (inColor.z * 2.0) - 1.0;
    half o = sensitivity * (inColor.x * inColor.y - z * z - 0.04 * sum * sum);
    outTexture.write(half4(o, o, o, 1.0), gid);
}

kernel void
local_non_max_suppression(texture2d<half, access::read>  inTexture  [[texture(0)]],
           texture2d<half, access::write> outTexture [[texture(1)]],
           const device float& threshold [[ buffer(2) ]],
           uint2 gid [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }
    
    half c = inTexture.read(gid).r;
    half n = inTexture.read(gid + uint2(0,-1)).r;
    half s = inTexture.read(gid + uint2(0,1)).r;
    half w = inTexture.read(gid + uint2(-1,0)).r;
    half e = inTexture.read(gid + uint2(1,0)).r;
    half nw = inTexture.read(gid + uint2(-1,-1)).r;
    half ne = inTexture.read(gid + uint2(1,-1)).r;
    half sw = inTexture.read(gid + uint2(-1,1)).r;
    half se = inTexture.read(gid + uint2(1,1)).r;

    // For tie-breaker
    half tb = 1.0 - step(c, n);
    tb *= (1.0 - step(c, nw));
    tb *= (1.0 - step(c, w));
    tb *= (1.0 - step(c, sw));
    
    half mv = max(max(max(max(c, s), se), e), ne);
    half o = c * step(mv, c) * tb;
    o = step(half(threshold), o);

    outTexture.write(half4(o, o, o, 1.0), gid);
}

kernel void
step(texture2d<half, access::read>  inTexture  [[texture(0)]],
                texture2d<half, access::write> outTexture [[texture(1)]],
                const device float& threshold [[ buffer(2) ]],
                uint2 gid [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }

    half inColor = inTexture.read(gid).r;
    half o = step(half(threshold), inColor);
    outTexture.write(half4(o, o, o, 1.0), gid);
}
