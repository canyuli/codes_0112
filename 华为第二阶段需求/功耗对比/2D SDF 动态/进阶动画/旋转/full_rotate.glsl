#version 330 core
out vec4 FragColor;
in vec2 vUV;

// 生成器一次性把常量/数组和颜色等注入到这里：
const int PARTS = 1;
const int uPartCount = PARTS;
uniform vec2 uResolution;
uniform float iTime;
#define uTime iTime
uniform sampler2D uSDF[PARTS];
const vec3 COL_BG = vec3(1.000, 1.000, 1.000);
const vec3 COL_FG = vec3(0.000, 0.000, 0.000);
const int   uCompositeMode = 0;
const float uLayer[PARTS]  = float[PARTS](0.0000);
const float uExpand[PARTS] = float[PARTS](0.0000);
const int   uMode[PARTS]   = int[PARTS](1);
const int   uInsideWhite[PARTS] = int[PARTS](1);
const float uFixedDeg[PARTS] = float[PARTS](0.0000);
const float uSpeedDeg[PARTS] = float[PARTS](180.0000);
const vec2  uPivot[PARTS]    = vec2[PARTS](vec2(0.5000,0.5000));


float readSDF(int i, vec2 uv){
    float g = texture(uSDF[i], uv).r;   // 0..1
    if (uInsideWhite[i] != 0) g = 1.0 - g;
    return g;
}

void aspectFitSquare(out vec2 uvFit, out float inSquare){
    float w = uResolution.x, h = uResolution.y;
    float s = min(w,h);
    vec2 o = 0.5*vec2(w,h) - 0.5*vec2(s,s);
    vec2 p = (gl_FragCoord.xy - o) / s; // [0,1]^2
    uvFit = p;
    inSquare = step(0.0,p.x)*step(p.x,1.0)*step(0.0,p.y)*step(p.y,1.0);
}
mat2 rot(float a){ float c=cos(a), s=sin(a); return mat2(c,-s,s,c); }
float radiansf(float d){ return d * 0.017453292519943295; }

float sdfFill(float s, float edge, float k){
    float w=max(fwidth(s)*k, 1.0/1024.0);
    return 1.0 - smoothstep(edge - w, edge + w, s);
}

float samplePart(int i, vec2 uv){
    // 旋转角的计算：mode=+1/-1/2（CW∞/CCW∞/旋到角）
    float ang = 0.0;
    int m = uMode[i];
    if (m == +1) {         // CW ∞
        ang = -radiansf(uSpeedDeg[i]) * uTime;
    } else if (m == -1) {  // CCW ∞
        ang =  radiansf(uSpeedDeg[i]) * uTime;
    } else if (m == 2) {   // 旋到固定角
        float tgt = -radiansf(uFixedDeg[i]);
        float spd = radiansf(abs(uSpeedDeg[i]));
        if (spd < 1e-6) ang = tgt;
        else ang = sign(tgt) * min(abs(tgt), spd * uTime);
    }

    vec2 p = uv - uPivot[i];
    p = rot(ang) * p + uPivot[i];

    // 采样 + 抗锯齿；边界平滑避免 0/1 夹带
    vec2 g = fwidth(p);
    float inRect = smoothstep(0.0,g.x,p.x)*smoothstep(0.0,g.x,1.0-p.x)
                 * smoothstep(0.0,g.y,p.y)*smoothstep(0.0,g.y,1.0-p.y);

    float s = readSDF(i, clamp(p,0.0,1.0));
    float aFill  = sdfFill(s, 0.5, 0.75);
    float aCover = sdfFill(s, 0.5 + uExpand[i], 0.75);
    return (uCompositeMode==0) ? aFill * inRect : max(aCover * inRect, 0.0);
}

void main(){
    vec2 uv; float inSquare; aspectFitSquare(uv, inSquare);
    if (inSquare < 0.5){ FragColor = vec4(COL_BG,1.0); return; }

    if (uCompositeMode == 0){
        // 透视混合（see-through）：逐层叠加 alpha
        vec3 col = COL_BG;
        for (int i=0;i<uPartCount;++i){
            float a = samplePart(i, uv);
            col = mix(col, COL_FG, a);
        }
        FragColor = vec4(col,1.0);
    } else {
        // 遮盖（cover）：用 uLayer 和 uExpand 来选“赢家”，着色仍用本体 aFill
        float bestLayer = -1e9;
        int   bestIdx   = -1;
        float bestFill  = 0.0;

        for (int i=0;i<uPartCount;++i){
            vec2 uvT = uv;
            // 重算 aFill/aCover（避免重复 samplePart 的逻辑分支）
            float ang = 0.0; int m = uMode[i];
            if (m==+1) ang = -radiansf(uSpeedDeg[i]) * uTime;
            else if (m==-1) ang =  radiansf(uSpeedDeg[i]) * uTime;
            else if (m==2){
                float tgt=radiansf(uFixedDeg[i]), spd=radiansf(abs(uSpeedDeg[i]));
                ang = (spd<1e-6)?tgt : sign(tgt)*min(abs(tgt), spd*uTime);
            }
            vec2 p = uvT - uPivot[i]; p = rot(ang)*p + uPivot[i];
            vec2 g=fwidth(p);
            float inRect = smoothstep(0.0,g.x,p.x)*smoothstep(0.0,g.x,1.0-p.x)
                         * smoothstep(0.0,g.y,p.y)*smoothstep(0.0,g.y,1.0-p.y);
            float s = readSDF(i, clamp(p,0.0,1.0));

            float aFill  = sdfFill(s, 0.5, 0.75) * inRect;
            float aCover = sdfFill(s, 0.5 + uExpand[i], 0.75) * inRect;

            if (aCover > 0.001){
                float L = uLayer[i];
                if (L > bestLayer || (L==bestLayer && i>bestIdx)){
                    bestLayer = L; bestIdx = i; bestFill = aFill;
                }
            }
        }
        vec3 col = mix(COL_BG, COL_FG, bestFill);
        FragColor = vec4(col,1.0);
    }
}
