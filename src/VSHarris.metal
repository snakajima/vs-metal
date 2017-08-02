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
                const device float& strength [[ buffer(3) ]],
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
    half dy = - nw - n - ne + sw + s + se;
    half dx = - sw - w - nw + se + e + ne;
    half4 outColor = half4(dx * dx, dy * dy , (dx * dy) + 1.0 / 2.0, 1.0);
    outTexture.write(outColor, gid);
}

