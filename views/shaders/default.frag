#version 330 core
in vec4 _vertColour;
in vec2 _vertUV;

out vec4 colour;

uniform sampler2D texture0;

void main()
{
    colour = _vertColour;
    //colour = texture(texture0, _vertUV) * _vertColour;
} 