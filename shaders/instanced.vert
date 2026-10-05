#version 330 core

layout (location = 0) in vec3 position;
layout (location = 1) in vec3 color;
layout (location = 2) in vec3 normal;
layout (location = 3) in vec2 uv;

layout (location = 4) in mat4 instance_model;

out vec3 vertexColor;
out vec2 vertexUV;
out vec3 fragmentPosition;
out vec3 fragmentNormal;

uniform mat4 view;
uniform mat4 projection;

void main()
{
    vec4 world_position =
        instance_model * vec4(position, 1.0);

    gl_Position =
        projection * view * world_position;

    vertexColor = color;
    vertexUV = uv;
    fragmentPosition = world_position.xyz;

    fragmentNormal =
        mat3(transpose(inverse(instance_model))) * normal;
}