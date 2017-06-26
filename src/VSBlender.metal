//
//  VSBlender.metal
//  vs-metal
//
//  Created by satoshi on 6/25/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void
alpha(texture2d<half, access::read>  inTexture1  [[texture(0)]],
                texture2d<half, access::read>  inTexture2  [[texture(1)]],
                texture2d<half, access::write> outTexture [[texture(2)]],
                const device float& ratio [[ buffer(3) ]],
                uint2                          gid         [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }
    
    half4 color1  = inTexture1.read(gid);
    half4 color2  = inTexture2.read(gid);
    outTexture.write(half4(mix(color1.rgb, color2.rgb, half(ratio) * color2.a), color1.a), gid);
}

