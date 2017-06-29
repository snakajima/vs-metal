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

kernel void
invert(texture2d<half, access::read>  inTexture  [[texture(0)]],
                texture2d<half, access::write> outTexture [[texture(1)]],
                uint2                          gid         [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }

    half4 inColor  = inTexture.read(gid);
    outTexture.write(half4(1.0 - inColor.rgb, inColor.a), gid);
}

kernel void
boolean(texture2d<half, access::read>  inTexture  [[texture(0)]],
      texture2d<half, access::write> outTexture [[texture(1)]],
      const device float2& range [[ buffer(2) ]],
      const device float3& weight [[ buffer(3) ]],
      const device float4& color1 [[ buffer(4) ]],
      const device float4& color2 [[ buffer(5) ]],
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
    half d = dot(inColor.rgb, w);
    half4 outColor = (range.x < d && d < range.y) ? half4(color2) : half4(color1);
    outTexture.write(outColor, gid);
}

kernel void
gradient_map(texture2d<half, access::read>  inTexture  [[texture(0)]],
     texture2d<half, access::write> outTexture [[texture(1)]],
     const device float3& weight [[ buffer(2) ]],
     const device float4& color1 [[ buffer(3) ]],
     const device float4& color2 [[ buffer(4) ]],
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
    half d = dot(inColor.rgb, w);
    outTexture.write(mix(half4(color1), half4(color2), d), gid);
}

kernel void
halftone(texture2d<half, access::read>  inTexture  [[texture(0)]],
            texture2d<half, access::write> outTexture [[texture(1)]],
            const device float3& weight [[ buffer(2) ]],
            const device float4& color1 [[ buffer(3) ]],
            const device float4& color2 [[ buffer(4) ]],
            const device float& radius [[ buffer(5) ]],
            const device float& scale [[ buffer(6) ]],
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
    half v = (1.0 - dot(inColor.rgb, w)) * scale;
    half2 rem = (half2(gid % uint(radius * 2)) - radius) / radius;
    half d = sqrt(dot(rem, rem));
    outTexture.write((v > d) ? half4(color1) : half4(color2), gid);
}

kernel void
tint(texture2d<half, access::read>  inTexture  [[texture(0)]],
     texture2d<half, access::write> outTexture [[texture(1)]],
     const device float& ratio [[ buffer(2) ]],
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
    outTexture.write(mix(inColor, half4(color), half4(ratio)), gid);
}

kernel void
enhancer(texture2d<half, access::read>  inTexture  [[texture(0)]],
     texture2d<half, access::write> outTexture [[texture(1)]],
     const device float2& red [[ buffer(2) ]],
     const device float2& green [[ buffer(3) ]],
     const device float2& blue [[ buffer(4) ]],
     uint2                          gid         [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }
    
    half4 inColor  = inTexture.read(gid);
    half3 outColor = inColor.rgb - half3(red.x, green.x, blue.x);
    outColor /= half3(red.y-red.x, green.y-green.x, blue.y-blue.x);
    outTexture.write(half4(outColor, inColor.a), gid);
}

kernel void
hue_filter(texture2d<half, access::read>  inTexture  [[texture(0)]],
         texture2d<half, access::write> outTexture [[texture(1)]],
         const device float2& hue [[ buffer(2) ]],
         const device float2& chroma [[ buffer(3) ]],
         uint2                          gid         [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }
    
    half4 inColor  = inTexture.read(gid);
    float R = inColor.r;
    float G = inColor.g;
    float B = inColor.b;
    float M = max(inColor.r, max(inColor.g, inColor.b));
    float m = min(inColor.r, min(inColor.g, inColor.b));
    float C = M - m;
    float hue0 = (M == m) ? 0.0 :
    (M == R) ? (G - B) / C :
    (M == G) ? (B - R) / C + 2.0 : (R - G) / C + 4.0;
    hue0 = (hue0 < 0.0) ? hue0 + 6.0 : hue0;
    hue0 = hue0 * 60.0;
    hue0 = (hue.x < hue0) ? hue0 : hue0 + 360.0;
    float high = (hue.x < hue.y) ? hue.y : hue.y + 360.0;
    half a = (hue0 < high && chroma.x <= C && C <= chroma.y) ? 1.0 : 0.0;
    //outTexture.write(half4(C, C, C, 1.0), gid);
    outTexture.write(half4(inColor.rgb, a), gid);
}

#define M_PI 3.14159265

kernel void
lighter(texture2d<half, access::read>  inTexture  [[texture(0)]],
                texture2d<half, access::write> outTexture [[texture(1)]],
                const device float& ratio [[ buffer(2) ]],
                uint2                          gid         [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }
    
    half4 inColor  = inTexture.read(gid);
    inColor.rgb = sin(clamp(inColor.rgb * half(ratio), half(0.0), half(1.0)) * M_PI/2.0);
    outTexture.write(half4(inColor), gid);
}

kernel void
hueshift(texture2d<half, access::read>  inTexture  [[texture(0)]],
                texture2d<half, access::write> outTexture [[texture(1)]],
                const device float& shift [[ buffer(2) ]],
                uint2                          gid         [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }
    
    half4 RGBA0  = inTexture.read(gid);
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

    half L = L0;
    half H = H0 + shift / 60.0;
    half S = S0;
    H = (H < 6.0) ? H : H - 6.0;

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
contrast(texture2d<half, access::read>  inTexture  [[texture(0)]],
     texture2d<half, access::write> outTexture [[texture(1)]],
     const device float& enhance [[ buffer(2) ]],
     uint2                          gid         [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }
    
    half4 inColor  = inTexture.read(gid);
    half3 RGB = inColor.rgb - half3(0.5);
    RGB = sin(clamp(RGB * M_PI * half(enhance), half(-M_PI/2.0), half(M_PI/2.0))) / 0.5 + half3(0.5, 0.5, 0.5);
    outTexture.write(half4(RGB, inColor.a), gid);
}

kernel void
saturate(texture2d<half, access::read>  inTexture  [[texture(0)]],
     texture2d<half, access::write> outTexture [[texture(1)]],
     const device float& ratio [[ buffer(2) ]],
     const device float3& weight [[ buffer(3) ]],
     uint2                gid [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }
    
    half4 inColor  = inTexture.read(gid);
    half d = dot(inColor.rgb, half3(weight));
    outTexture.write(half4(mix(inColor.rgb, half3(d), -half(ratio)), inColor.a), gid);
}



