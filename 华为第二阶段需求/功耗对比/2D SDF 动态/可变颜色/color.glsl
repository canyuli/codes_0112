
#version 330 core
out vec4 FragColor;
in vec2 TexCoord;


    const int NUM_PARTS = 4;
    const int NUM_GROUPS = 4;
    const float gap = 0.100;
    const float stepDur = 0.050;
    const vec3 COL_BG = vec3(1, 1, 1);
    const vec3 COL_FG = vec3(0, 0, 0);
    const vec3 COL_TRANS = vec3(0.784314, 0.784314, 0.784314);
    int groupID[NUM_PARTS] = int[NUM_PARTS](0, 1, 2, 3);


uniform sampler2D uSDF[NUM_PARTS];
uniform float uTime;
uniform vec2  uResolution;

// 居中等比缩放，返回 uv 与是否在正方形内
void aspectFitSquare(out vec2 uvFit, out float inSquare){
    float w = uResolution.x, h = uResolution.y;
    float s = min(w,h);
    vec2 origin = 0.5*vec2(w,h) - 0.5*vec2(s,s);
    vec2 frag = gl_FragCoord.xy;
    vec2 p = (frag - origin) / s;
    uvFit = p;
    inSquare = step(0.0,p.x)*step(p.x,1.0)*step(0.0,p.y)*step(p.y,1.0);
}

// SDF 遮罩，带抗锯齿
float maskSDF(sampler2D tex, vec2 uv){
    float s = texture(tex, uv).r;
    float w = fwidth(s)*0.75;
    return smoothstep(0.5-w, 0.5+w, s);
}

// 单个部分的颜色
vec3 colorForPartByGroup(int idx, float localTime, bool forward){
    int g = groupID[idx];
    if(g < 0) return COL_FG; // 固定黑

    float center = float(g)*gap + stepDur;
    float k = smoothstep(center - stepDur, center + stepDur, localTime);
    if(!forward) k = 1.0 - k;

    return mix(COL_FG, COL_TRANS, k);
}

void main(){
    // 时间循环
    float halfCycle = float(NUM_GROUPS)*gap + 2.0*stepDur;
    float cycle     = 2.0 * halfCycle;
    float t         = mod(uTime, cycle);
    bool  forward   = (t < halfCycle);
    float localTime = forward ? t : (t - halfCycle);

    // 居中采样，外部区域为背景
    vec2 uv; float inSquare;
    aspectFitSquare(uv, inSquare);
    if(inSquare < 0.5){ FragColor = vec4(COL_BG,1.0); return; }

    // 合成
    vec3 finalCol = COL_BG;
    for(int i=0;i<NUM_PARTS;++i){
        float inside = maskSDF(uSDF[i], uv);
        if(inside > 0.001){
            vec3 c = colorForPartByGroup(i, localTime, forward);
            finalCol = mix(finalCol, c, inside);
        }
    }
    FragColor = vec4(finalCol, 1.0);
}
