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

struct PointLight
{
    vec3 position;
    vec3 color;
    float intensity;

    float constantAttenuation;
    float linearAttenuation;
    float quadraticAttenuation;
};

const int MAX_POINT_LIGHTS = 8;

uniform int pointLightCount;
uniform PointLight pointLights[MAX_POINT_LIGHTS];

void main()
{
    vec3 totalDiffuse = vec3(0.0); //total diffuse color
    vec3 totalSpecular = vec3(0.0); //total specular amount

    vec3 normal = normalize(fragmentNormal); //normal of the pixel being processed
    vec3 viewDirection = normalize(viewPosition - fragmentPosition); //view direction of camera to pixel

    for (int i = 0; i < MAX_POINT_LIGHTS; i++) //loop through all pointlights in the scene
    {
        if (i >= pointLightCount) //if the count reaches the limit then just disregard all other point lights
        {
            break;
        }

        PointLight light = pointLights[i]; //set the point light 

        vec3 toLight = light.position - fragmentPosition; //direction of fragment to light
        float distanceToLight = length(toLight); //magnitude of toLight
        vec3 lightDirection = normalize(toLight); //make unit vector

        float diffuseAmount = max(dot(normal, lightDirection), 0.0); //diffuse multiplier

        float attenuation = 1.0 / //calculate the light dropoff to that point
            (
                light.constantAttenuation +
                light.linearAttenuation * distanceToLight +
                light.quadraticAttenuation *
                    distanceToLight *
                    distanceToLight
            );

        //calculate the total diffuse 
        vec3 diffuse = light.color * light.intensity * diffuseAmount * attenuation;

        //the vector halfway between the light direction and the view direction
        vec3 halfwayDirection = normalize(lightDirection + viewDirection);

        //calculate the light hitting the camera given the reflection of the light into it
        float specularAmount = pow(max(dot(normal, halfwayDirection), 0.0),shininess);

        //total specular color
        vec3 specular =
            light.color *
            specularAmount *
            light.intensity *
            specularStrength *
            attenuation;

        //add to count
        totalDiffuse += diffuse;
        totalSpecular += specular;
    }
    //light direction
    vec3 direction = normalize(-lightDirection);

    //ambient light
    vec3 ambient_light = ambientLightColor * ambientColor; //multiplies global illumination color by the color of the material

    //diffuse light
    float diffuse_amount = max(dot(normal, direction), 0.0); //decimal of how much light is reflected off surface
    vec3 diffuse_light = lightColor * lightIntensity * diffuse_amount; //actual vector3 value of diffuse light

    //diffuse + ambient light
    vec3 base_color = diffuseColor; //set base color to the diffuse color
    if (hasDiffuseTexture != 0) {
        base_color = texture(diffuseTexture, vertexUV).rgb; //or just sample texture if given
    }
    
    vec3 lighting = ambient_light + diffuse_light + totalDiffuse; //add up the ambient and diffuse light
    vec4 diffuse_color = vec4(base_color * lighting, 1);

    //specular highlights
    vec3 frag_normal = normalize(fragmentNormal); //normal of frag
    vec3 view_direction = normalize(viewPosition - fragmentPosition); //frag to camera direction
    vec3 halfway_direction = normalize(direction + view_direction); //halfway between both directions

    float specular_strength = pow(max(dot(frag_normal, halfway_direction), 0.0), shininess);
    vec3 specular_color = lightColor * specular_strength * lightIntensity * specularStrength * specularColor;

    //diffuse + ambient + specular light
    finalColor = diffuse_color + vec4(totalSpecular * specular_color,1);
}