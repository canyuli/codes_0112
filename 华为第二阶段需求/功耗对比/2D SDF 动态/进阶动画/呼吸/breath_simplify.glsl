#version 330 core
out vec4 FragColor;

const int  PARTS = 6;

const vec3 COL_BG    = vec3(1.0);
const vec3 COL_FG    = vec3(0.0);
const vec3 COL_TRANS = vec3(0.5);

const int GroupScale[PARTS] = int[](0,1,2,3,4,5);
const int GroupColor[PARTS] = int[](0,1,2,3,4,5);

uniform sampler2D uSDF[PARTS];
uniform float uTime;
uniform vec2  uResolution;

const float gap      = 0.25;
const float stepDur  = 0.25;
const float scaleAmp = 0.10;

float maskSDF(sampler2D t, vec2 uv){
    float s = texture(t, uv).r;
    float w = fwidth(s) * 0.75;
    return smoothstep(0.5 - w, 0.5 + w, s);
}

void main(){
    vec2 frag = gl_FragCoord.xy;
    float side = min(uResolution.x, uResolution.y);
    vec2 uv = (frag - 0.5 * (uResolution - vec2(side))) / side;

    if(any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))){
        FragColor = vec4(COL_BG, 1.0);
        return;
    }

    float groups = float(PARTS);
    float halfCycle = groups * gap + 2.0 * stepDur;
    float cycle = 2.0 * halfCycle;
    float w = 6.2831853 * (uTime / cycle);

    vec3 color = COL_BG;

    for(int i=0;i<PARTS;++i){
        float kScale = 1.0;
        float grayW  = 0.0;

        float phaseS = 3.14159265 * ((float(GroupScale[i]) * gap + stepDur) / halfCycle);
        float phaseC = 3.14159265 * ((float(GroupColor[i]) * gap + stepDur) / halfCycle);

        float ks = 0.5 * (1.0 - cos(w - phaseS));
        float kc = 0.5 * (1.0 - cos(w - phaseC));

        kScale = 1.0 + scaleAmp * (2.0 * ks - 1.0);
        grayW  = kc;

        vec2 uvS = (uv - 0.5) / kScale + 0.5;
        if(any(lessThan(uvS, vec2(0.0))) || any(greaterThan(uvS, vec2(1.0))))
            continue;

        float m = maskSDF(uSDF[i], uvS);
        if(m > 0.001){
            vec3 c = mix(COL_FG, COL_TRANS, grayW);
            color = mix(color, c, m);
        }
    }

    FragColor = vec4(color, 1.0);
}
