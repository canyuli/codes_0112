#version 330 core
out vec4 FragColor;

uniform vec2  uResolution;
uniform sampler2D uSDF[3];
uniform float iTime;
uniform bool  uSwitch;

const vec3  BG = vec3(1.0);
const vec3  FG = vec3(0.0);
const vec2  C1 = vec2(0.760, 0.315);
const float R  = 0.180;
const float D  = 0.3;
const float EPS = 1e-3;

float easeOutBack(float t){
    t -= 1.0;
    return 1.0 + t*t*(2.70158*t + 1.70158);
}

void main(){
    vec2 frag = gl_FragCoord.xy;
    float side = min(uResolution.x, uResolution.y);
    vec2 uv = (frag - 0.5*(uResolution - side)) / side;

    float t1 = clamp(iTime / D, 0.0, 1.0);
    float t2 = clamp((iTime - D) / D, 0.0, 1.0);

    float p1 = smoothstep(0.0, 1.0, t1);
    float p2 = smoothstep(0.0, 1.0, t2);

    float s0 = (p1 < 1.0)
        ? mix(1.0, 0.8, p1)
        : mix(0.8, 1.0, easeOutBack(p2));

    vec2 uv0 = (uv - 0.5) / s0 + 0.5;
    float sd = 0.5 - texture(uSDF[0], uv0).r;

    float shrink = mix(1.0, 0.6, p1);
    float grow   = mix(0.6, 1.0, easeOutBack(p2));

    float s2 = 0.0;
    float s3 = 0.0;

    if (p1 < 1.0) {
        if (uSwitch) s3 = shrink;
        else         s2 = shrink;
    } else {
        if (uSwitch) s2 = grow;
        else         s3 = grow;
    }

    vec2 uv2 = (uv - C1) / max(s2, EPS) + C1;
    vec2 uv3 = (uv - C1) / max(s3, EPS) + C1;

    float r = max(s2, s3);
    float c = length(uv - C1) - R * r;
    sd = max(sd, -sign(c) * 0.5);
    sd = min(sd, 0.5 - texture(uSDF[1], uv2).r);
    sd = min(sd, 0.5 - texture(uSDF[2], uv3).r);

    float w = fwidth(sd);
    float a = smoothstep(-w, w, -sd);
    FragColor = vec4(mix(BG, FG, a), 1.0);
}
