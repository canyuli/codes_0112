#version 330 core
out vec4 FragColor;
in vec2 vUV;

uniform vec2  uResolution;
uniform sampler2D uSDF[2];
uniform float iTime;
uniform bool  uSwitch;

const vec3  uBgColor  = vec3(1.0);
const vec3  uTexColor = vec3(0.0);
const vec2  uCenter   = vec2(0.760, 0.315);
const float uRadius   = 0.180;
const float uDelay    = 0.0;
const float uDuration = 0.3;

float easeOutBack(float t) {
    t -= 1.0;
    return 1.0 + t * t * (2.70158 * t + 1.70158);
}

void main() {
    vec2 frag = gl_FragCoord.xy;
    float side = min(uResolution.x, uResolution.y);
    vec2 uv = (frag - 0.5 * (uResolution - side)) / side;

    float t1 = clamp((iTime - uDelay) / uDuration, 0.0, 1.0);
    float t2 = clamp((iTime - uDelay - uDuration) / uDuration, 0.0, 1.0);

    float phase1 = smoothstep(0.0, 1.0, t1);
    float phase2 = smoothstep(0.0, 1.0, t2);

    float bounce = easeOutBack(phase2);

    float scale0 = uSwitch
        ? mix(1.0, 1.1, phase1)
        : mix(1.0, 0.8, phase1);

    scale0 = mix(scale0, 1.0, bounce);

    float scale1 = uSwitch
        ? mix(0.0, 1.1, phase1)
        : mix(1.0, 0.0, phase1);

    scale1 = mix(scale1, 1.0, bounce * float(uSwitch));

    vec2 c0 = vec2(0.5);
    vec2 uv0 = (uv - c0) / max(scale0, 1e-3) + c0;
    vec2 uv1 = (uv - uCenter) / max(scale1, 1e-3) + uCenter;

    float sd0 = 0.5 - texture(uSDF[0], uv0).r;
    float sd1 = 0.5 - texture(uSDF[1], uv1).r;

    float sdCircle = length(uv - uCenter) - uRadius * scale1;
    float sdMask = sign(sdCircle) * 0.5;

    float sd = min(max(sd0, -sdMask), sd1);

    float w = fwidth(sd);
    float a = smoothstep(-w, w, -sd);

    FragColor = vec4(mix(uBgColor, uTexColor, a), 1.0);
}
