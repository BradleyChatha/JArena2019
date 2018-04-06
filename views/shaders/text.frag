#version 330 core
in vec4 _vertColour;
in vec2 _vertUV; // UV are in pixels, so we have to map them.

out vec4 colour;

uniform sampler2D texture0;

void main()
{
    // Size of the texture.
    ivec2 texSize = textureSize(texture0, 0).xy;

    // Fixup the UV. They're specified from the top-left but OpenGL wants the bottom-left.
    vec2 finalUV = _vertUV;
    finalUV.y    = texSize.y - finalUV.y;

    // Convert pixels to NDC
    vec2 onePixel = vec2(1.0, 1.0) / vec2(texSize);
    vec2 texel = onePixel * finalUV;

    // Text pixels are stored in alphascale, where the R channel is their alpha value.
    colour = vec4(1.0, 1.0, 1.0, texture(texture0, texel).r) * _vertColour;
} 
