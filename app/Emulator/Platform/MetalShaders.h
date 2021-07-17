#pragma once
#include <simd/simd.h>


typedef enum {
    VertexInputIndexVertices     = 0,
    VertexInputIndexViewportSize = 1,
} VertexInputIndex;


typedef enum {
    TextureIndexBaseColor = 0,
    TextureIndexForeColor = 1,
} TextureIndex;


typedef struct {
    vector_float2 position;
    vector_float2 textureCoordinate;
} Vertex;
