#version 330 core

in vec3 vertexColor;
in vec2 vertexUV;
in vec3 fragmentPosition;
in vec3 fragmentNormal;

out vec4 finalColor;

uniform vec3 lightDirection;
uniform float lightIntensity;
uniform vec3 lightColor;
uniform vec3 viewPosition;
uniform float shininess;
uniform float specularStrength;
uniform vec3 ambientLightColor;

uniform vec3 diffuseColor;
uniform vec3 ambientColor;
uniform vec3 specularColor;

uniform int hasDiffuseTexture;
uniform sampler2D diffuseTexture;

void main()
{
    //normals and light direction
    vec3 normal = normalize(fragmentNormal);
    vec3 direction = normalize(-lightDirection);

    //ambient light
    vec3 ambient_light = ambientLightColor * ambientColor;

    //diffuse light
    float diffuse_amount = max(dot(normal, direction), 0.0);
    vec3 diffuse_light = lightColor * lightIntensity * diffuse_amount;

    //diffuse + ambient light
    vec3 base_color = diffuseColor;

    if (hasDiffuseTexture != 0) {
        base_color = texture(diffuseTexture, vertexUV).rgb;
    }
    
    vec3 lighting = ambient_light + diffuse_light;
    vec4 diffuse_color = vec4(base_color * lighting * diffuseColor, 1);

    //specular highlights
    vec3 frag_normal = normalize(fragmentNormal);
    vec3 view_direction = normalize(viewPosition - fragmentPosition);
    vec3 halfway_direction = normalize(direction + view_direction);

    float specular_strength = pow(max(dot(frag_normal, halfway_direction), 0.0), shininess);
    vec3 specular_color = lightColor * specular_strength * lightIntensity * specularStrength * specularColor;

    //diffuse + ambient + specular light
    finalColor = diffuse_color + vec4(specular_color,1);
}