#version 330 core

in vec3 vertexColor;
in vec2 vertexUV;
in vec3 fragmentPosition;
in vec3 fragmentNormal;

out vec4 finalColor;

uniform vec3 lightDirection;
uniform vec3 lightColor;
uniform float lightIntensity;
uniform vec3 lightAmbient;
uniform vec3 viewPosition;
uniform float shininess;
uniform float specularStrength;

uniform sampler2D diffuseTexture;

void main()
{
    //normals and light direction
    vec3 normal = normalize(fragmentNormal);
    vec3 direction = normalize(-lightDirection);

    //ambient light
    vec3 ambient_light = lightAmbient;

    //diffuse light
    float diffuse_amount = max(dot(normal, direction), 0.0);
    vec3 diffuse_light = lightColor * lightIntensity * diffuse_amount;

    //diffuse + ambient light
    vec3 base_color = texture(diffuseTexture,vertexUV).rgb;
    vec3 lighting = ambient_light + diffuse_light;
    vec4 diffuseColor = vec4(base_color * lighting, 1);

    //specular highlights
    vec3 frag_normal = normalize(fragmentNormal);
    vec3 view_direction = normalize(viewPosition - fragmentPosition);
    vec3 halfway_direction = normalize(direction + view_direction);

    float specular_strength = pow(max(dot(frag_normal, halfway_direction), 0.0), shininess);
    vec3 specular_color = lightColor * specular_strength * lightIntensity * specularStrength;

    //diffuse + ambient + specular light
    finalColor = diffuseColor + vec4(specular_color,1);
}