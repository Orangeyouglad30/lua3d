#version 330 core

layout (location = 0) in vec3 position;
layout (location = 1) in vec3 color;
layout (location = 2) in vec3 normal;
layout (location = 3) in vec2 uv;

out vec3 vertexColor;
out vec3 vertexNormal;
out vec2 vertexUV;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
    gl_Position = projection * view * model * vec4(position, 1.0);

    vertexColor = color;
    vertexNormal = mat3(model) * normal;
    vertexUV = uv;
}