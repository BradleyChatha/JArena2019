#version 330 core
in vec4 _vertColour;
in vec2 _vertUV; // UV are in pixels, so we have to map them.

out vec4 colour;

uniform sampler2D texture0;

void main()
{
    ivec2 texSize  = textureSize(texture0, 0).xy;
    vec2 onePixel  = vec2(1.0, 1.0) / vec2(texSize);
    vec2 texel     = onePixel * _vertUV;
    colour         = texture(texture0, texel) * _vertColour;
} 
