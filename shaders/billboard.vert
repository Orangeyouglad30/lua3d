#version 330 core
layout (location = 0) in vec2 quadPosition;
layout (location = 1) in vec2 uv;

out vec2 vertexUV;

uniform mat4 view;
uniform mat4 projection;
uniform vec3 billboardPosition;
uniform vec3 cameraRight;
uniform vec3 cameraUp;
uniform float billboardSize;

void main() {
    vec3 worldPosition = billboardPosition + cameraRight * quadPosition.x * billboardSize + cameraUp * quadPosition.y * billboardSize;
    gl_Position = projection * view * vec4(worldPosition,1.0);
    vertexUV = uv;
}