#version 330 core

in vec3 vertexColor;
in vec3 vertexNormal;
in vec2 vertexUV;

out vec4 finalColor;

uniform vec3 lightDirection;
uniform vec3 lightColor;
uniform float lightIntensity;
uniform vec3 lightAmbient;

uniform sampler2D diffuseTexture;

void main()
{
    vec3 normal = normalize(vertexNormal);
    vec3 direction = normalize(lightDirection);

    float diffuse_amount = max(dot(normal, direction), 0.0);

    vec3 ambient_light = lightAmbient;
    vec3 diffuse_light = lightColor * lightIntensity * diffuse_amount;

    vec3 base_color = texture(diffuseTexture,vertexUV).rgb;

    vec3 lighting = ambient_light + diffuse_light;

    finalColor = vec4(base_color * lighting, 1);
}