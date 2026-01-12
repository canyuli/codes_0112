#version 330 core
out vec4 FragColor;

uniform sampler2D uSDF[4];
uniform float uTime;
uniform vec2  uResolution;

const int NUM_PARTS = 4;
const int NUM_GROUPS = 4;
const float gap = 0.1;
const float stepDur = 0.05;
const vec3 COL_BG = vec3(1.0);
const vec3 COL_FG = vec3(0.0);
const vec3 COL_TRANS = vec3(0.784314);
const int groupID[NUM_PARTS] = int[](0, 1, 2, 3);

void main(){
    vec2 frag = gl_FragCoord.xy;
    float side = min(uResolution.x, uResolution.y);
    vec2 origin = 0.5 * (uResolution - vec2(side));
    vec2 uv = (frag - origin) / side;

    if(any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))){
        FragColor = vec4(COL_BG, 1.0);
        return;
    }

    float halfCycle = float(NUM_GROUPS) * gap + 2.0 * stepDur;
    float cycle = 2.0 * halfCycle;
    float t = mod(uTime, cycle);
    bool forward = (t < halfCycle);
    float localTime = forward ? t : (t - halfCycle);

    vec3 color = COL_BG;

    for(int i = 0; i < NUM_PARTS; ++i){
        float s = texture(uSDF[i], uv).r;
        float w = fwidth(s) * 0.75;
        float inside = smoothstep(0.5 - w, 0.5 + w, s);

        if(inside > 0.001){
            int g = groupID[i];
            vec3 c = COL_FG;

            if(g >= 0){
                float center = float(g) * gap + stepDur;
                float k = smoothstep(center - stepDur, center + stepDur, localTime);
                if(!forward) k = 1.0 - k;
                c = mix(COL_FG, COL_TRANS, k);
            }

            color = mix(color, c, inside);
        }
    }

    FragColor = vec4(color, 1.0);
}

