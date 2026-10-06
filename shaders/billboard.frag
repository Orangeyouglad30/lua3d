#version 330 core
in vec2 vertexUV;
out vec4 finalColor;
uniform sampler2D Texture;

void main() {
    vec4 textureColor = texture(Texture,vertexUV);
    if (textureColor.a < 0.1) discard;

    finalColor = textureColor;
}