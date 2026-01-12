#version 330 core
out vec4 FragColor;
in vec2 vUV;

// ======= 可改参数 =======
//INSERT HERE
const int  PARTS  = 6;
const vec3 COL_BG     = vec3(1.00, 1.00, 1.00);
const vec3 COL_FG     = vec3(0.00, 0.00, 0.00);
const vec3 COL_TRANS  = vec3(0.50, 0.50, 0.50);
const int GroupScale[PARTS] = int[](0,1,2,3,4,5);
const int GroupColor[PARTS] = int[](0,1,2,3,4,5);
uniform sampler2D uSDF[PARTS];
const float gap     = 0.25;
const float stepDur = 0.25;
const float scaleAmp = 0.10;


uniform float uTime;
uniform vec2  uResolution;
// —— 居中等比适配“正方形”（不含任何全局缩放） ——
void aspectFitSquare(out vec2 uvFit, out float inSquare){
    float w = uResolution.x, h = uResolution.y;
    float side = min(w, h); // 用 max 而不是 min → 覆盖
    vec2 origin = 0.5*vec2(w,h) - 0.5*vec2(side, side);
    vec2 frag   = gl_FragCoord.xy;
    uvFit = (frag - origin) / side; // [0,1]^2 覆盖窗口
    inSquare = step(0.0,uvFit.x)*step(uvFit.x,1.0)*step(0.0,uvFit.y)*step(uvFit.y,1.0);
}

// SDF 遮罩：阈值=0.5，带 fwidth 抗锯齿；返回“内部（s<0.5）”填充
float maskSDF(sampler2D tex, vec2 uv){
    float s = texture(tex, uv).r;
    float w = fwidth(s) * 0.75;
    return smoothstep(0.5 - w, 0.5 + w, s); // s<0.5 为内侧
}

// —— 统计有效组数（基于固定 PARTS） ——
// （你取消了 uPartCount，这里就按 PARTS 遍历）
int effectiveGroupCount_scale(){
    int mx = -1;
    for(int i=0;i<PARTS;++i){ if(GroupScale[i] >= 0) mx = max(mx, GroupScale[i]); }
    return (mx >= 0) ? (mx + 1) : 0;
}
int effectiveGroupCount_color(){
    int mx = -1;
    for(int i=0;i<PARTS;++i){ if(GroupColor[i] >= 0) mx = max(mx, GroupColor[i]); }
    return (mx >= 0) ? (mx + 1) : 0;
}
int effectiveGroupCount(){
    int a = effectiveGroupCount_scale();
    int b = effectiveGroupCount_color();
    return (a > b) ? a : b;
}

// —— 统一时间基准（缩放/灰度共用周期） ——
void computeTime(in float gap_, in float stepDur_,
                 out float cycle, out float halfCycle)
{
    int numGroups = effectiveGroupCount();
    float groups  = float(max(1, numGroups));        // 至少 1，避免除零
    halfCycle = groups * gap_ + 2.0 * stepDur_;      // 正向
    cycle     = 2.0 * halfCycle;                     // 往返
}

// —— 余弦往返（0→1→0），用“组中心”映射相位偏移，保证“组号小的先动” ——
float phaseShiftForGroup_Cos(int g, float halfCycle_){
    float center = float(g) * gap + stepDur;         // ∈ [0, halfCycle]
    return 3.14159265358979323846 * (center / max(halfCycle_, 1e-6)); // φ ∈ [0, π]
}
float cosPingPong01(float timeSec, float cycle_, float phi){
    // w = 2π * t/T；返回 0..1..0 的余弦往返
    float w = 6.28318530717958647692 * (timeSec / max(cycle_, 1e-6));
    return 0.5 * (1.0 - cos(w - phi));
}

// 对 [0,1]^2 的 uv 进行中心等比缩放
vec2 scaleAroundCenter(vec2 uv, float s){
    return (uv - 0.5) / s + 0.5;
}

void main(){
    // —— 居中正方形 —— 
    vec2 uv; float inSquare;
    aspectFitSquare(uv, inSquare);
    //if(inSquare < 0.5){ FragColor = vec4(COL_BG, 1.0); return; }

    // —— 统一周期 —— 
    float cycle, halfCycle;
    computeTime(gap, stepDur, cycle, halfCycle);

    // —— 合成 —— 
    vec3 finalCol = COL_BG;

    for(int i=0;i<PARTS;++i){
        // ========== 缩放（由 GroupScale 决定时序） ==========
        float scale = 1.0;
        float kS = 0.5; // 默认居中（scale=1）
        int gs = GroupScale[i];
        if (gs >= 0) {
            float phiS = phaseShiftForGroup_Cos(gs, halfCycle);
            kS  = cosPingPong01(uTime, cycle, phiS);        // 0..1..0
            scale = 1.0 + scaleAmp * (2.0*kS - 1.0);        // [1-a, 1+a]
        }

        // 对该纹理的 UV 单独缩放，并判断是否仍在方形内
        vec2 uvS = scaleAroundCenter(uv, scale);
        float inUV = step(0.0, uvS.x)*step(uvS.x,1.0)*step(0.0,uvS.y)*step(uvS.y,1.0);
        if (inUV < 0.5) {
            continue;
        }

        // ========== 灰度（由 GroupColor 决定时序；最大=灰，最小=黑） ==========
        float wGray = 0.0; // 默认不参与灰度动画 → 固定黑
        int gc = GroupColor[i];
        if (gc >= 0) {
            float phiC = phaseShiftForGroup_Cos(gc, halfCycle);
            float kC   = cosPingPong01(uTime, cycle, phiC);  // 0..1..0
            wGray = kC;  // 直接用作灰度权重：0=黑，1=灰
        }

        // SDF 取样与合成
        float inside = maskSDF(uSDF[i], uvS);
        if (inside > 0.001){
            vec3 c = mix(COL_FG, COL_TRANS, wGray);
            finalCol = mix(finalCol, c, inside);    // 维持“后者覆盖前者”的策略
        }
    }

    FragColor = vec4(finalCol, 1.0);
}