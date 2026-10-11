#version 330 core

layout (location = 0) in vec3 position;
layout (location = 1) in vec3 color;
layout (location = 2) in vec3 normal;
layout (location = 3) in vec2 uv;

out vec3 vertexColor;
out vec2 vertexUV;
out vec3 fragmentPosition;
out vec3 fragmentNormal;
out float fragmentViewDepth;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform mat3 normalMatrix;

void main()
{
    vec4 worldPosition = model * vec4(position,1.0);
    vec4 viewPosition = view * worldPosition;

    gl_Position = projection * viewPosition;

    vertexColor = color;
    vertexUV = uv;
    fragmentPosition = worldPosition.xyz;
    fragmentNormal = normalMatrix * normal;
    fragmentViewDepth = -viewPosition.z;
}