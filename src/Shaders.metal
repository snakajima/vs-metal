//
//  debug.metal
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/20/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

vertex float4 basic_vertex(const device packed_float3* vertex_array [[ buffer(0) ]],
                           unsigned int vid [[ vertex_id ]]) {
  return float4(vertex_array[vid], 1.0);
}

/*
typedef struct {
  packed_float2 position;
  packed_float2 texcoord;
} Vertex;

typedef struct {
  float4 position [[position]];
  float2 texcoord;
} Varyings;

vertex Varyings vertexPassthrough(
                                  device Vertex* verticies [[ buffer(0) ]],
                                  unsigned int vid [[ vertex_id ]]
                                  ) {
  Varyings out;
  
  device Vertex& v = verticies[vid];
  
  out.position = float4(float2(v.position), 0.0, 1.0);
  
  out.texcoord = v.texcoord;
  
  return out;
}
*/

fragment half4 basic_fragment() {
  return half4(1.0);
}

