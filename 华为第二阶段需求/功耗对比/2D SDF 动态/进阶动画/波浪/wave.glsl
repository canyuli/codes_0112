#version 330 core
in vec2 vUv;
out vec4 fragColor;

uniform float iTime;
uniform int   uTexCount;
uniform vec2  uResolution;

// ======= 可改参数 =======
//INSERT HERE
const vec3 uBgColor      = vec3(1.00, 1.00, 1.00);
const vec3 uTexColor     = vec3(0.00, 0.00, 0.00);
const float kDigitScale   = 1.000;
const float digitDuration = 0.300;
const float cooldown      = 0.500;
const float waveStrength  = 0.800;
const int PARTS        = 4;

uniform sampler2D uSDF[PARTS];
const float staggerRatio  = 0.20;

float maskSDF(sampler2D tex, vec2 uv){
    float s = texture(tex, uv).r;
    float w = fwidth(s) * 0.75;
    return smoothstep(0.5 - w, 0.5 + w, s);
}

void main(){
    vec2 uv = gl_FragCoord.xy / uResolution.xy;
    if (uTexCount <= 0) { fragColor = vec4(uBgColor, 1.0); return; }

    float cellWidth = 1.0 / float(uTexCount);
    float xDiv      = uv.x / cellWidth;
    int   index     = int(clamp(floor(xDiv), 0.0, float(uTexCount-1)));

    vec2 inContent = vec2(fract(xDiv), uv.y);
    vec2 localUV   = inContent;

    float screenAspect = uResolution.x / uResolution.y;
    float cellAspect   = screenAspect / float(uTexCount);

    vec2  texSize   = vec2(textureSize(uSDF[index], 0));
    float texAspect = texSize.x / texSize.y;

    vec2 scale = vec2(1.0);
    if (texAspect > cellAspect) scale.y = cellAspect / texAspect;
    else                        scale.x = texAspect / cellAspect;

    scale *= kDigitScale;
    vec2 halfRange = 0.5 * scale;

    float stagger       = digitDuration * staggerRatio;
    float activeSpan    = digitDuration + (float(uTexCount)-1.0) * stagger;
    float cycleDuration = activeSpan + cooldown;
    float tInCycle      = mod(iTime, cycleDuration);

    if (tInCycle <= activeSpan) {
        float startT = float(index) * stagger;
        float endT   = startT + digitDuration;
        if (tInCycle >= startT && tInCycle < endT) {
            float t    = (tInCycle - startT) / digitDuration;
            float amp  = waveStrength * halfRange.y;
            float wave = -amp * sin(3.14159265 * t);
            localUV.y  = clamp(localUV.y + wave, 0.5 - halfRange.y, 0.5 + halfRange.y);
        }
    }
    localUV.y = clamp(localUV.y, 0.5 - halfRange.y, 0.5 + halfRange.y);

    vec2 uvInTex = (localUV - 0.5) / scale + 0.5;
    if (uvInTex.x < 0.0 || uvInTex.x > 1.0 || uvInTex.y < 0.0 || uvInTex.y > 1.0) {
        fragColor = vec4(uBgColor, 1.0);
        return;
    }

    float inside = maskSDF(uSDF[index], uvInTex);
    if (inside > 0.001) {
        fragColor = vec4(mix(uBgColor, uTexColor, inside), 1.0);
    } else {
        fragColor = vec4(uBgColor, 1.0);
    }
}