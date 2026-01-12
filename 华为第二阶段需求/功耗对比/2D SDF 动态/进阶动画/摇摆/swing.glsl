#version 330 core
out vec4 FragColor;
in vec2 vUV;

// ======= 可改参数（由生成器注入） =======
const int PARTS = 1;
const int MAX_PARTS = PARTS;
uniform vec2 uResolution;
uniform float iTime;
#define uTime iTime
uniform sampler2D uSDF[PARTS];
const vec3 COL_BG = vec3(1.000, 1.000, 1.000);
const vec3 COL_FG = vec3(0.000, 0.000, 0.000);
const int uPartCount = PARTS;
const float uFreq = 1.500;
const float uDamp = 3.000;
const int   uSwings = 0;
const int   uCompositeMode = 1;
const float uLayer[PARTS] = float[PARTS](0.0000);
const float uExpand[PARTS] = float[PARTS](0.0000);
const int   uMode[PARTS] = int[PARTS](1);
const int   uInsideWhite[PARTS] = int[PARTS](1);
const float uTransAmp[PARTS] = float[PARTS](0.1000);
const float uRotAmp[PARTS] = float[PARTS](0.0000);
const vec2  uPivot[PARTS] = vec2[PARTS](vec2(0.5000,0.5000));
const int   uStartMode = 1;
const float uStartOffset[PARTS] = float[PARTS](0.0000);
const float uStartInterval = 0.200;
const int   uStartOrder[PARTS] = int[PARTS](0);


// 以下是主逻辑（来源于你的 runtime 片段着色器，已去除 CPU 侧 uniforms）
// —— 居中等比适配到正方形 ——
// 返回 uvFit ∈ [0,1]^2 以及 inSquare（是否在正方形内）
void aspectFitSquare(out vec2 uvFit, out float inSquare){
    float w = uResolution.x, h = uResolution.y;
    float side = min(w,h);
    vec2 origin = 0.5*vec2(w,h) - 0.5*vec2(side, side);
    vec2 frag   = gl_FragCoord.xy;
    vec2 p      = (frag - origin) / side;          // [0,1]^2
    uvFit = p;
    inSquare = step(0.0,p.x)*step(p.x,1.0)*step(0.0,p.y)*step(p.y,1.0);
}

// 统一的 SDF 抗锯齿 alpha
float sdfAlpha(float s, float edge, float wmul){
    float w = max(fwidth(s) * wmul, 1.0/1024.0);
    return 1.0 - smoothstep(edge - w, edge + w, s);
}

// 衰减包络 * 正弦
float swing_env(float t) {
    float w = 6.28318530718 * uFreq; // 2πf
    return exp(-uDamp * t) * sin(w * t);
}

// 三种启动模式：1=同时、2=每件偏移、3=依序间隔
float start_time_for(int idx) {
    if (uStartMode == 2) return uStartOffset[idx];
    if (uStartMode == 3) return uStartInterval * float(uStartOrder[idx]);
    return 0.0;
}

// 次数限制：uSwings<=0 → 无限摇摆；>0 → 摇 uSwings 次并在末尾回到原位
float clamp_by_swings(float t) {
    if (uSwings <= 0) return t;
    float Tmax = float(uSwings) / max(uFreq, 1e-4);
    return min(t, Tmax);
}

vec2 rotateAround(vec2 p, vec2 pivot, float ang) {
    float c = cos(ang), s = sin(ang);
    vec2 d = p - pivot;
    return pivot + mat2(c, -s, s, c) * d;
}

// 对第 idx 个部件应用位移/旋转；uMode: ±1=Y, ±2=X, ±3=Rot（负号=反向）
void apply_part_transform(int idx, inout vec2 uv) {
    float t = uTime - start_time_for(idx);
    if (t < 0.0) return;                 // 还没到开始时刻
    t = clamp_by_swings(t);
    float off;
    if (uSwings == 0) {
        // 无限摇摆：用一个周期内的正弦（无阻尼），随时编译都能看到明显摆动
        float T  = 1.0 / max(uFreq, 1e-4);
        float tl = mod(t, T);
        off = sin(6.28318530718 * uFreq * tl);
    } else {
        // 有次数：保持原语义（阻尼 + 到 Tmax 后回到原位）
        float Tmax = float(uSwings) / max(uFreq, 1e-4);
        float tc   = min(t, Tmax);
        off = exp(-uDamp * tc) * sin(6.28318530718 * uFreq * tc);
    }

    int m = abs(uMode[idx]);
    float sgn = (uMode[idx] < 0) ? -1.0 : 1.0;

    if (m == 1 && uTransAmp[idx] > 0.0) {
        uv.y += sgn * uTransAmp[idx] * off;
    } else if (m == 2 && uTransAmp[idx] > 0.0) {
        uv.x += sgn * uTransAmp[idx] * off;
    } else if (m == 3 && uRotAmp[idx] > 0.0) {
        float ang = sgn * uRotAmp[idx] * off;
        uv = rotateAround(uv, uPivot[idx], ang);
    }
}

float readSDF(int i, vec2 uv){
    float g = texture(uSDF[i], uv).r;   // 0..1
    // uInsideWhite[i] 由生成器注入为 0/1 的整型数组
    if (uInsideWhite[i] != 0) g = 1.0 - g; 
    return g;
}

void main(){
    // —— 居中正方形 ——
    vec2 uv; float inSquare;
    aspectFitSquare(uv, inSquare);
    if(inSquare < 0.5){ FragColor = vec4(COL_BG, 1.0); return; }

    // 透视模式：逐个 alpha 混合；遮盖模式：选层级最高者
    if (uCompositeMode == 0){
        // ===== 透视（see-through）=====
        vec3 finalCol = COL_BG;

        for(int i=0;i<uPartCount;++i){
            vec2 uvT = uv;

            apply_part_transform(i, uvT);

            // 仍在方形内
            float inUV = step(0.0, uvT.x)*step(uvT.x,1.0)*step(0.0,uvT.y)*step(uvT.y,1.0);
            if (inUV < 0.5) continue;

            float sVal  = readSDF(i, uvT);
            float aFill = sdfAlpha(sVal, 0.5, 0.75);
            if (aFill > 0.001){
                finalCol = mix(finalCol, COL_FG, aFill);
            }
        }

        FragColor = vec4(finalCol, 1.0);
        return;
    } else {
        // ===== 遮盖（cover）=====
        float bestLayer = -1e9;
        int   bestIndex = -1;        // 同层“后者优先”
        float bestFill  = 0.0;       // 赢家用于着色的“本体 alpha”
        float bestCover = 0.0;       // 赢家用于选择的“包络 alpha”（含 expand）

        for(int i=0;i<uPartCount;++i){
            vec2 uvT = uv;

            apply_part_transform(i, uvT);

            float inUV = step(0.0, uvT.x)*step(uvT.x,1.0)*step(0.0,uvT.y)*step(uvT.y,1.0);
            if (inUV < 0.5) continue;

            float sVal     = readSDF(i, uvT);
            // 填充本体：阈值固定 0.5（不受 expand 影响 -> 不会加粗）
            float aFill    = sdfAlpha(sVal, 0.5, 0.75);
            // 包络遮挡：阈值 0.5 + expand（>0 外扩；<0 内缩）
            float aCover   = sdfAlpha(sVal, 0.5 + uExpand[i], 0.75);

            // 只要包络有命中，就参与“谁来遮挡/压住下层”的竞争
            if (aCover > 0.001){
                float L = uLayer[i];
                if (L > bestLayer || (L == bestLayer && i > bestIndex)){
                    bestLayer = L;
                    bestIndex = i;
                    bestFill  = aFill;   // 最终着色用“本体 alpha”
                    bestCover = aCover;  // 只用于选择赢家
                }
            }
        }

        // 输出：赢家用“本体 alpha”着色（黑色）；
        // 但由于赢家是按“包络 alpha”选出的，
        // 因此在 aCover > aFill 的环带区域，不会画黑色，显示为白色背景，
        // 同时下层完全被遮蔽——这就形成了“白色包络边”。
        vec3 finalCol = mix(COL_BG, COL_FG, bestFill);
        FragColor = vec4(finalCol, 1.0);
        return;
    }
}
