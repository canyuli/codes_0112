#version 330 core
out vec4 fragColor;

uniform float iTime;
uniform int   uTexCount;
uniform vec2  uResolution;
uniform sampler2D uSDF[4];

const vec3  BG = vec3(1.0);
const vec3  FG = vec3(0.0);

const float kDigitScale   = 1.0;
const float digitDuration = 0.3;
const float cooldown      = 0.5;
const float waveStrength  = 0.8;
const float staggerRatio  = 0.2;
const float PI = 3.14159265;

void main()
{
    if (uTexCount <= 0) {
        fragColor = vec4(BG, 1.0);
        return;
    }

    vec2 uv = gl_FragCoord.xy / uResolution;

    float invCount = 1.0 / float(uTexCount);
    float xDiv     = uv.x * float(uTexCount);
    int   idx      = int(clamp(floor(xDiv), 0.0, float(uTexCount - 1)));

    vec2 localUV = vec2(fract(xDiv), uv.y);

    float screenAspect = uResolution.x / uResolution.y;
    float cellAspect   = screenAspect * invCount;

    vec2  texSize   = vec2(textureSize(uSDF[idx], 0));
    float texAspect = texSize.x / texSize.y;

    vec2 scale = (texAspect > cellAspect)
               ? vec2(1.0, cellAspect / texAspect)
               : vec2(texAspect / cellAspect, 1.0);

    scale *= kDigitScale;
    vec2 halfRange = 0.5 * scale;

    float stagger       = digitDuration * staggerRatio;
    float activeSpan    = digitDuration + (float(uTexCount) - 1.0) * stagger;
    float cycleDuration = activeSpan + cooldown;
    float tInCycle      = mod(iTime, cycleDuration);

    float startT = float(idx) * stagger;
    float tNorm  = (tInCycle - startT) / digitDuration;

    float active = step(0.0, tNorm) * step(tNorm, 1.0);
    float wave   = -waveStrength * halfRange.y * sin(PI * clamp(tNorm, 0.0, 1.0)) * active;

    localUV.y = clamp(localUV.y + wave,
                      0.5 - halfRange.y,
                      0.5 + halfRange.y);

    vec2 uvTex = (localUV - 0.5) / scale + 0.5;

    if (any(lessThan(uvTex, vec2(0.0))) ||
        any(greaterThan(uvTex, vec2(1.0)))) {
        fragColor = vec4(BG, 1.0);
        return;
    }

    float s = texture(uSDF[idx], uvTex).r;
    float w = fwidth(s) * 0.75;
    float a = smoothstep(0.5 - w, 0.5 + w, s);

    fragColor = vec4(mix(BG, FG, a), 1.0);
}
