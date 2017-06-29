//
//  VSSource.metal
//  vs-metal
//
//  Created by satoshi on 6/29/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void
color(texture2d<half, access::write> outTexture [[texture(0)]],
      const device float4& color [[ buffer(1) ]],
     uint2                          gid         [[thread_position_in_grid]])
{
    outTexture.write(half4(color), gid);
}

kernel void
colors(texture2d<half, access::write> outTexture [[texture(0)]],
      const device float4& color1 [[ buffer(1) ]],
      const device float4& color2 [[ buffer(2) ]],
      const device float& ratio [[ buffer(3) ]],
      uint2                          gid         [[thread_position_in_grid]])
{
    outTexture.write(half4(mix(color1, color2, ratio)), gid);
}


