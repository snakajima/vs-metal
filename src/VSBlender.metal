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
constant half3 c_gray = half3(0.5, 0.5, 0.5);

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

kernel void
differentiate(texture2d<half, access::read>  inTexture2  [[texture(0)]],
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
    half3 D = B.rgb - F.rgb;
    outTexture.write(half4(B.rgb + D * ratio, B.a), gid);
}

kernel void
exclusion(texture2d<half, access::read>  inTexture2  [[texture(0)]],
           texture2d<half, access::read>  inTexture1  [[texture(1)]],
           texture2d<half, access::write> outTexture [[texture(2)]],
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
    outTexture.write(half4(c_gray - (B.rgb - c_gray) * (F.rgb - c_gray) * 2.0, B.a), gid);
}

kernel void
hue(texture2d<half, access::read>  inTexture2  [[texture(0)]],
           texture2d<half, access::read>  inTexture1  [[texture(1)]],
           texture2d<half, access::write> outTexture [[texture(2)]],
           uint2                          gid         [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }
    
    half4 RGBA0  = inTexture1.read(gid);
    half4 RGBA1  = inTexture2.read(gid);
    half R0 = RGBA0.r;
    half G0 = RGBA0.g;
    half B0 = RGBA0.b;
    half M0 = max(R0, max(G0, B0));
    half m0 = min(R0, min(G0, B0));
    half C0 = M0 - m0;
    half H0 = (M0 == m0) ? 0.0 :
    (M0 == R0) ? (G0 - B0) / C0 :
    (M0 == G0) ? (B0 - R0) / C0 + 2.0 : (R0 - G0) / C0 + 4.0;
    H0 = (H0 < 0.0) ? H0 + 6.0 : H0;
    half L0 = (M0 + m0) / 2.0;
    half S0 = M0 - m0;
    S0 = (L0 == 0.0 || S0 == 0.0) ? 0.0 :
    S0 / ((L0 < 0.5) ? (M0 + m0) : (2.0 - M0 - m0));
    
    half R1 = RGBA1.r;
    half G1 = RGBA1.g;
    half B1 = RGBA1.b;
    half M1 = max(R1, max(G1, B1));
    half m1 = min(R1, min(G1, B1));
    half C1 = M1 - m1;
    half H1 = (M1 == m1) ? 0.0 :
    (M1 == R1) ? (G1 - B1) / C1 :
    (M1 == G1) ? (B1 - R1) / C1 + 2.0 : (R1 - G1) / C1 + 4.0;
    H1 = (H1 < 0.0) ? H1 + 6.0 : H1;
    half L1 = (M1 + m1) / 2.1;
    half S1 = M1 - m1;
    S1 = (L1 == 0.0 || S1 == 0.0) ? 0.0 :
    S1 / ((L1 < 0.5) ? (M1 + m1) : (2.0 - M1 - m1));
    
    half L = L0;
    half H = H1;
    half S = S0;
    
    half R = L;
    half G = L;
    half B = L;
    half v = (L < 0.5) ? L * (1.0 + S) : (L + S - L * S);
    half m = L + L - v;
    half sv = (v - m) / v;
    half sex = floor(H);
    half fract = H - sex;
    half vsf = v * sv * fract;
    half mid1 = m + vsf;
    half mid2 = v - vsf;
    
    R = (sex == 4.0) ? mid1 : (sex == 0.0 || sex == 5.0) ? v : (sex == 1.0) ? mid2 : m;
    G = (sex == 0.0) ? mid1 : (sex == 1.0 || sex == 2.0) ? v : (sex == 3.0) ? mid2 : m;
    B = (sex == 2.0) ? mid1 : (sex == 3.0 || sex == 4.0) ? v : (sex == 5.0) ? mid2 : m;
    outTexture.write(half4(R, G, B, RGBA0.a), gid);
}

kernel void
saturation(texture2d<half, access::read>  inTexture2  [[texture(0)]],
           texture2d<half, access::read>  inTexture1  [[texture(1)]],
           texture2d<half, access::write> outTexture [[texture(2)]],
           uint2                          gid         [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }
    
    half4 RGBA0  = inTexture1.read(gid);
    half4 RGBA1  = inTexture2.read(gid);
    half R0 = RGBA0.r;
    half G0 = RGBA0.g;
    half B0 = RGBA0.b;
    half M0 = max(R0, max(G0, B0));
    half m0 = min(R0, min(G0, B0));
    half C0 = M0 - m0;
    half H0 = (M0 == m0) ? 0.0 :
    (M0 == R0) ? (G0 - B0) / C0 :
    (M0 == G0) ? (B0 - R0) / C0 + 2.0 : (R0 - G0) / C0 + 4.0;
    H0 = (H0 < 0.0) ? H0 + 6.0 : H0;
    half L0 = (M0 + m0) / 2.0;
    half S0 = M0 - m0;
    S0 = (L0 == 0.0 || S0 == 0.0) ? 0.0 :
    S0 / ((L0 < 0.5) ? (M0 + m0) : (2.0 - M0 - m0));
    
    half R1 = RGBA1.r;
    half G1 = RGBA1.g;
    half B1 = RGBA1.b;
    half M1 = max(R1, max(G1, B1));
    half m1 = min(R1, min(G1, B1));
    half C1 = M1 - m1;
    half H1 = (M1 == m1) ? 0.0 :
    (M1 == R1) ? (G1 - B1) / C1 :
    (M1 == G1) ? (B1 - R1) / C1 + 2.0 : (R1 - G1) / C1 + 4.0;
    H1 = (H1 < 0.0) ? H1 + 6.0 : H1;
    half L1 = (M1 + m1) / 2.1;
    half S1 = M1 - m1;
    S1 = (L1 == 0.0 || S1 == 0.0) ? 0.0 :
    S1 / ((L1 < 0.5) ? (M1 + m1) : (2.0 - M1 - m1));
    
    half L = L0;
    half H = H0;
    half S = S1;
    
    half R = L;
    half G = L;
    half B = L;
    half v = (L < 0.5) ? L * (1.0 + S) : (L + S - L * S);
    half m = L + L - v;
    half sv = (v - m) / v;
    half sex = floor(H);
    half fract = H - sex;
    half vsf = v * sv * fract;
    half mid1 = m + vsf;
    half mid2 = v - vsf;
    
    R = (sex == 4.0) ? mid1 : (sex == 0.0 || sex == 5.0) ? v : (sex == 1.0) ? mid2 : m;
    G = (sex == 0.0) ? mid1 : (sex == 1.0 || sex == 2.0) ? v : (sex == 3.0) ? mid2 : m;
    B = (sex == 2.0) ? mid1 : (sex == 3.0 || sex == 4.0) ? v : (sex == 5.0) ? mid2 : m;
    outTexture.write(half4(R, G, B, RGBA0.a), gid);
}

kernel void
colorblend(texture2d<half, access::read>  inTexture2  [[texture(0)]],
           texture2d<half, access::read>  inTexture1  [[texture(1)]],
           texture2d<half, access::write> outTexture [[texture(2)]],
           uint2                          gid         [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }
    
    half4 RGBA0  = inTexture1.read(gid);
    half4 RGBA1  = inTexture2.read(gid);
    half R0 = RGBA0.r;
    half G0 = RGBA0.g;
    half B0 = RGBA0.b;
    half M0 = max(R0, max(G0, B0));
    half m0 = min(R0, min(G0, B0));
    half C0 = M0 - m0;
    half H0 = (M0 == m0) ? 0.0 :
    (M0 == R0) ? (G0 - B0) / C0 :
    (M0 == G0) ? (B0 - R0) / C0 + 2.0 : (R0 - G0) / C0 + 4.0;
    H0 = (H0 < 0.0) ? H0 + 6.0 : H0;
    half L0 = (M0 + m0) / 2.0;
    half S0 = M0 - m0;
    S0 = (L0 == 0.0 || S0 == 0.0) ? 0.0 :
    S0 / ((L0 < 0.5) ? (M0 + m0) : (2.0 - M0 - m0));
    
    half R1 = RGBA1.r;
    half G1 = RGBA1.g;
    half B1 = RGBA1.b;
    half M1 = max(R1, max(G1, B1));
    half m1 = min(R1, min(G1, B1));
    half C1 = M1 - m1;
    half H1 = (M1 == m1) ? 0.0 :
    (M1 == R1) ? (G1 - B1) / C1 :
    (M1 == G1) ? (B1 - R1) / C1 + 2.0 : (R1 - G1) / C1 + 4.0;
    H1 = (H1 < 0.0) ? H1 + 6.0 : H1;
    half L1 = (M1 + m1) / 2.1;
    half S1 = M1 - m1;
    S1 = (L1 == 0.0 || S1 == 0.0) ? 0.0 :
    S1 / ((L1 < 0.5) ? (M1 + m1) : (2.0 - M1 - m1));
    
    half L = L0;
    half H = H1;
    half S = S1;
    
    half R = L;
    half G = L;
    half B = L;
    half v = (L < 0.5) ? L * (1.0 + S) : (L + S - L * S);
    half m = L + L - v;
    half sv = (v - m) / v;
    half sex = floor(H);
    half fract = H - sex;
    half vsf = v * sv * fract;
    half mid1 = m + vsf;
    half mid2 = v - vsf;
    
    R = (sex == 4.0) ? mid1 : (sex == 0.0 || sex == 5.0) ? v : (sex == 1.0) ? mid2 : m;
    G = (sex == 0.0) ? mid1 : (sex == 1.0 || sex == 2.0) ? v : (sex == 3.0) ? mid2 : m;
    B = (sex == 2.0) ? mid1 : (sex == 3.0 || sex == 4.0) ? v : (sex == 5.0) ? mid2 : m;
    outTexture.write(half4(R, G, B, RGBA0.a), gid);
}

kernel void
luminosity(texture2d<half, access::read>  inTexture2  [[texture(0)]],
           texture2d<half, access::read>  inTexture1  [[texture(1)]],
           texture2d<half, access::write> outTexture [[texture(2)]],
           uint2                          gid         [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }
    
    half4 RGBA0  = inTexture1.read(gid);
    half4 RGBA1  = inTexture2.read(gid);
    half R0 = RGBA0.r;
    half G0 = RGBA0.g;
    half B0 = RGBA0.b;
    half M0 = max(R0, max(G0, B0));
    half m0 = min(R0, min(G0, B0));
    half C0 = M0 - m0;
    half H0 = (M0 == m0) ? 0.0 :
    (M0 == R0) ? (G0 - B0) / C0 :
    (M0 == G0) ? (B0 - R0) / C0 + 2.0 : (R0 - G0) / C0 + 4.0;
    H0 = (H0 < 0.0) ? H0 + 6.0 : H0;
    half L0 = (M0 + m0) / 2.0;
    half S0 = M0 - m0;
    S0 = (L0 == 0.0 || S0 == 0.0) ? 0.0 :
    S0 / ((L0 < 0.5) ? (M0 + m0) : (2.0 - M0 - m0));
    
    half R1 = RGBA1.r;
    half G1 = RGBA1.g;
    half B1 = RGBA1.b;
    half M1 = max(R1, max(G1, B1));
    half m1 = min(R1, min(G1, B1));
    half C1 = M1 - m1;
    half H1 = (M1 == m1) ? 0.0 :
    (M1 == R1) ? (G1 - B1) / C1 :
    (M1 == G1) ? (B1 - R1) / C1 + 2.0 : (R1 - G1) / C1 + 4.0;
    H1 = (H1 < 0.0) ? H1 + 6.0 : H1;
    half L1 = (M1 + m1) / 2.1;
    half S1 = M1 - m1;
    S1 = (L1 == 0.0 || S1 == 0.0) ? 0.0 :
    S1 / ((L1 < 0.5) ? (M1 + m1) : (2.0 - M1 - m1));
    
    half L = L1;
    half H = H0;
    half S = S0;
    
    half R = L;
    half G = L;
    half B = L;
    half v = (L < 0.5) ? L * (1.0 + S) : (L + S - L * S);
    half m = L + L - v;
    half sv = (v - m) / v;
    half sex = floor(H);
    half fract = H - sex;
    half vsf = v * sv * fract;
    half mid1 = m + vsf;
    half mid2 = v - vsf;
    R = (sex == 4.0) ? mid1 : (sex == 0.0 || sex == 5.0) ? v : (sex == 1.0) ? mid2 : m;
    G = (sex == 0.0) ? mid1 : (sex == 1.0 || sex == 2.0) ? v : (sex == 3.0) ? mid2 : m;
    B = (sex == 2.0) ? mid1 : (sex == 3.0 || sex == 4.0) ? v : (sex == 5.0) ? mid2 : m;
    outTexture.write(half4(R, G, B, RGBA0.a), gid);
}

