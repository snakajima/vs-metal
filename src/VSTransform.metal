//
//  VSTransform.metal
//  vs-metal
//
//  Created by satoshi on 6/29/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

constexpr sampler c_smp(coord::pixel, address::clamp_to_zero, filter::nearest);

kernel void
translate(texture2d<half, access::sample>  inTexture  [[texture(0)]],
                texture2d<half, access::write> outTexture [[texture(1)]],
                const device float& tx [[ buffer(2) ]],
                const device float& ty [[ buffer(3) ]],
                uint2 gid [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    float2 gid2 = float2(gid.x + tx, gid.y + ty);
    
    half4 inColor  = inTexture.sample(c_smp, gid2);
    outTexture.write(inColor, gid);
}

kernel void
transform(texture2d<half, access::sample>  inTexture  [[texture(0)]],
          texture2d<half, access::write> outTexture [[texture(1)]],
          const device float4& abcd [[ buffer(2) ]],
          const device float2& txty [[ buffer(3) ]],
          uint2 gid [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    float2 gid2 = float2(abcd.r * float(gid.x) + abcd.g * float(gid.y) + txty.x,
                         abcd.b * float(gid.x) + abcd.a * float(gid.y) + txty.y);
    
    half4 inColor  = inTexture.sample(c_smp, gid2);
    outTexture.write(inColor, gid);
}


