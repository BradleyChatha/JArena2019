#version 330 core
layout(location = 0) in vec2 vertPos;
layout(location = 1) in vec2 vertUV;
layout(location = 2) in vec4 vertColour;

out vec4 _vertColour;
out vec2 _vertUV;

void main()
{
    _vertColour = vertColour;
    _vertUV     = vertUV;

    gl_Position = vec4(vertPos, 0.0, 1.0);
}
