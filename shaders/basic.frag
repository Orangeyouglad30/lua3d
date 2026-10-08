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

struct SpotLight
{
    vec3 position;
    vec3 color;
    vec3 direction;
    float intensity;
    float maxAngle;
    float constantAttenuation;
    float linearAttenuation;
    float quadraticAttenuation;
};

const int MAX_SPOT_LIGHTS = 8;
const int MAX_POINT_LIGHTS = 8;

uniform int spotLightCount;
uniform SpotLight spotLights[MAX_SPOT_LIGHTS];

uniform int pointLightCount;
uniform PointLight pointLights[MAX_POINT_LIGHTS];

vec3 safe_normalize(vec3 value)
{
    float lengthValue = length(value);

    if (lengthValue <= 0.0001) {
        return vec3(0.0);
    }

    return value / lengthValue;
}

float calculate_specular(vec3 normal, vec3 lightDirection, vec3 viewDirection)
{
    vec3 halfwaySum = lightDirection + viewDirection;
    float halfwayLength = length(halfwaySum);

    if (halfwayLength <= 0.0001) {
        return 0.0;
    }

    vec3 halfwayDirection = halfwaySum / halfwayLength;

    return pow(
        max(dot(normal, halfwayDirection), 0.0),
        shininess
    );
}

void main()
{
    vec3 normal = safe_normalize(fragmentNormal);
    vec3 viewDirection = safe_normalize(viewPosition - fragmentPosition);

    vec3 totalDiffuse = vec3(0.0);
    vec3 totalSpecular = vec3(0.0);

    for (int i = 0; i < MAX_POINT_LIGHTS; i++)
    {
        if (i >= pointLightCount) {
            break;
        }

        PointLight light = pointLights[i];

        vec3 toLight = light.position - fragmentPosition;
        float distanceToLight = length(toLight);
        vec3 pointDirection = safe_normalize(toLight);

        float diffuseAmount = max(dot(normal, pointDirection), 0.0);

        float attenuation = 1.0 /
        (
            light.constantAttenuation +
            light.linearAttenuation * distanceToLight +
            light.quadraticAttenuation *
            distanceToLight *
            distanceToLight
        );

        vec3 diffuse =
            light.color *
            light.intensity *
            diffuseAmount *
            attenuation;

        float specularAmount =
            calculate_specular(
                normal,
                pointDirection,
                viewDirection
            );

        vec3 specular =
            light.color *
            specularAmount *
            light.intensity *
            specularStrength *
            attenuation;

        totalDiffuse += diffuse;
        totalSpecular += specular;
    }

    for (int i = 0; i < MAX_SPOT_LIGHTS; i++)
    {
        if (i >= spotLightCount) {
            break;
        }

        SpotLight light = spotLights[i];

        vec3 toLight = light.position - fragmentPosition;
        float distanceToLight = length(toLight);
        vec3 spotDirection = safe_normalize(toLight);

        vec3 toFragment =
            safe_normalize(fragmentPosition - light.position);

        vec3 normalizedLightDirection =
            safe_normalize(light.direction);

        float angleCos =
            dot(toFragment, normalizedLightDirection);

        float cutoffCos = cos(light.maxAngle);

        if (angleCos <= cutoffCos) {
            continue;
        }

        float diffuseAmount =
            max(dot(normal, spotDirection), 0.0);

        float attenuation = 1.0 /
        (
            light.constantAttenuation +
            light.linearAttenuation * distanceToLight +
            light.quadraticAttenuation *
            distanceToLight *
            distanceToLight
        );

        vec3 diffuse =
            light.color *
            light.intensity *
            diffuseAmount *
            attenuation;

        float specularAmount =
            calculate_specular(
                normal,
                spotDirection,
                viewDirection
            );

        vec3 specular =
            light.color *
            specularAmount *
            light.intensity *
            specularStrength *
            attenuation;

        totalDiffuse += diffuse;
        totalSpecular += specular;
    }

    vec3 globalDirection =
        safe_normalize(-lightDirection);

    float globalDiffuseAmount =
        max(dot(normal, globalDirection), 0.0);

    vec3 ambientLight =
        ambientLightColor *
        ambientColor;

    vec3 globalDiffuse =
        lightColor *
        lightIntensity *
        globalDiffuseAmount;

    float globalSpecularAmount =
        calculate_specular(
            normal,
            globalDirection,
            viewDirection
        );

    vec3 globalSpecular =
        lightColor *
        globalSpecularAmount *
        lightIntensity *
        specularStrength *
        specularColor;

    vec3 baseColor = diffuseColor;

    if (hasDiffuseTexture != 0) {
        baseColor = texture(diffuseTexture, vertexUV).rgb;
    }

    vec3 lighting =
        ambientLight +
        globalDiffuse +
        totalDiffuse;

    vec3 finalRgb =
        baseColor * lighting +
        globalSpecular +
        totalSpecular * specularColor;

    finalColor = vec4(finalRgb,1.0);//vec4(totalDiffuse,1.0) + 0.00001 * vec4(finalRgb, 1.0);
}