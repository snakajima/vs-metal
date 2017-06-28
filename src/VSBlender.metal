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
alpha(texture2d<half, access::read>  inTexture2  [[texture(0)]],
                texture2d<half, access::read>  inTexture1  [[texture(1)]],
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

kernel void
mixer(texture2d<half, access::read>  inTexture3  [[texture(0)]],
      texture2d<half, access::read>  inTexture2  [[texture(1)]],
      texture2d<half, access::read>  inTexture1  [[texture(2)]],
      texture2d<half, access::write> outTexture [[texture(3)]],
      const device float& ratio [[ buffer(4) ]],
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
    half4 color3  = inTexture3.read(gid);
    outTexture.write(mix(color1, color2, color3.a), gid);
}

kernel void
multiply(texture2d<half, access::read>  inTexture2  [[texture(0)]],
                texture2d<half, access::read>  inTexture1  [[texture(1)]],
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
    outTexture.write(half4(color1.rgb * color2.rgb, color1.a), gid);
}

constant half3 c_white = half3(1.0, 1.0, 1.0);

kernel void
screen(texture2d<half, access::read>  inTexture2  [[texture(0)]],
                texture2d<half, access::read>  inTexture1  [[texture(1)]],
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
    outTexture.write(half4(c_white - (c_white - color1.rgb) * (c_white - color2.rgb), color1.a), gid);
}

kernel void
lighten(texture2d<half, access::read>  inTexture2  [[texture(0)]],
                texture2d<half, access::read>  inTexture1  [[texture(1)]],
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
    outTexture.write(half4(max(color1.rgb, color2.rgb), color1.a), gid);
}

kernel void
darken(texture2d<half, access::read>  inTexture2  [[texture(0)]],
                texture2d<half, access::read>  inTexture1  [[texture(1)]],
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
    outTexture.write(half4(min(color1.rgb, color2.rgb), color1.a), gid);
}

kernel void
overlay(texture2d<half, access::read>  inTexture2  [[texture(0)]],
                texture2d<half, access::read>  inTexture1  [[texture(1)]],
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
    
    half4 B  = inTexture1.read(gid);
    half4 F  = inTexture2.read(gid);
    half r = (B.r < 0.5) ? (2.0 * F.r * B.r) : (1.0 - (1.0-2.0*(B.r-0.5))*(1.0-F.r));
    half g = (B.g < 0.5) ? (2.0 * F.g * B.g) : (1.0 - (1.0-2.0*(B.g-0.5))*(1.0-F.g));
    half b = (B.b < 0.5) ? (2.0 * F.b * B.b) : (1.0 - (1.0-2.0*(B.b-0.5))*(1.0-F.b));
    outTexture.write(half4(r, g, b, B.a), gid);
}

kernel void
colordodge(texture2d<half, access::read>  inTexture2  [[texture(0)]],
                texture2d<half, access::read>  inTexture1  [[texture(1)]],
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
    outTexture.write(half4(color1.rgb / (c_white - color2.rgb), color1.a), gid);
}

kernel void
colorburn(texture2d<half, access::read>  inTexture2  [[texture(0)]],
                texture2d<half, access::read>  inTexture1  [[texture(1)]],
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
    outTexture.write(half4(c_white - (c_white - color1.rgb) / color2.rgb, color1.a), gid);
}

kernel void
hardlight(texture2d<half, access::read>  inTexture2  [[texture(0)]],
                texture2d<half, access::read>  inTexture1  [[texture(1)]],
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
    
    half4 F  = inTexture1.read(gid);
    half4 B  = inTexture2.read(gid);
    half r = (B.r < 0.5) ? (2.0 * F.r * B.r) : (1.0 - (1.0-2.0*(B.r-0.5))*(1.0-F.r));
    half g = (B.g < 0.5) ? (2.0 * F.g * B.g) : (1.0 - (1.0-2.0*(B.g-0.5))*(1.0-F.g));
    half b = (B.b < 0.5) ? (2.0 * F.b * B.b) : (1.0 - (1.0-2.0*(B.b-0.5))*(1.0-F.b));
    outTexture.write(half4(r, g, b, B.a), gid);
}

kernel void
softlight(texture2d<half, access::read>  inTexture2  [[texture(0)]],
                texture2d<half, access::read>  inTexture1  [[texture(1)]],
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
    
    half4 A  = inTexture1.read(gid);
    half4 B  = inTexture2.read(gid);
    half r = (B.r < 0.5) ? A.r * (B.r + 0.5) : 1.0 - (1.0 - A.r) * (1.0 - (B.r - 0.5));
    half b = (B.b < 0.5) ? A.b * (B.b + 0.5) : 1.0 - (1.0 - A.b) * (1.0 - (B.b - 0.5));
    half g = (B.g < 0.5) ? A.g * (B.g + 0.5) : 1.0 - (1.0 - A.g) * (1.0 - (B.g - 0.5));
    outTexture.write(half4(r, g, b, B.a), gid);
}

kernel void
difference(texture2d<half, access::read>  inTexture2  [[texture(0)]],
                texture2d<half, access::read>  inTexture1  [[texture(1)]],
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
    outTexture.write(half4(abs(color2.rgb - color1.rgb), color2.a), gid);
}
