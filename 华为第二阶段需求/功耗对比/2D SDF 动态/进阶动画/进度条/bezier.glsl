#version 330 core

// OpenGL 3.3 uniforms expected by the viewer
uniform vec2  iResolution;
uniform float iTime;

// Fragment output
out vec4 FragColor;

// ==== Path Grow Demo (Lines + Quadratic Bézier) ====
// 环境：OpenGL 3.3 Core (iResolution, iTime)

#define USE_ARCLENGTH_SPEED 1   // 1: 弧长匀速, 0: 每段等时

// -------------------------
// Helpers: coordinate mapping
// -------------------------
void normToPixel(in vec2 uv, out vec2 pix)
{
    // uv in [0,1]^2. Fit into the shorter screen side and center,
    // flip Y so SVG 的 +Y 向下 转成 屏幕坐标 +Y 向上。
    float s = min(iResolution.x, iResolution.y);
    vec2 center = 0.5 * iResolution;
    vec2 local  = (uv - vec2(0.5)) * s;
    pix = center + vec2(local.x, local.y);
}

void normToPixel3(in vec2 a, in vec2 b, in vec2 c,
                  out vec2 A, out vec2 B, out vec2 C)
{
    normToPixel(a, A);
    normToPixel(b, B);
    normToPixel(c, C);
}

vec2 pixelToNorm(vec2 pix)
{
    float s = min(iResolution.x, iResolution.y);
    vec2 center = 0.5 * iResolution;
    vec2 local  = (pix - center) / s;
    return local + vec2(0.5);
}

// -------------------------
// Helpers: distance functions
// -------------------------
float sdSegment(vec2 p, vec2 a, vec2 b)
{
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

float sdAABB(vec2 p, vec2 mn, vec2 mx)
{
    vec2 d = max(max(mn - p, p - mx), 0.0);
    return length(d);
}

vec2 evalQuad(vec2 A, vec2 B, vec2 C, float t)
{
    float u = 1.0 - t;
    return u * u * A + 2.0 * u * t * B + t * t * C;
}

float sdQuadratic(vec2 p, vec2 A, vec2 B, vec2 C)
{
    // 采样逼近二次贝塞尔到点的距离
    const int N = 32;
    float dMin = 1e9;
    vec2 prev = A;
    for (int i = 1; i <= N; ++i) {
        float t = float(i) / float(N);
        vec2 cur = evalQuad(A, B, C, t);
        dMin = min(dMin, sdSegment(p, prev, cur));
        prev = cur;
    }
    return dMin;
}

void leftSubcurveQuad(vec2 A, vec2 B, vec2 C, float u,
                      out vec2 L0, out vec2 L1, out vec2 L2)
{
    // De Casteljau，把 [0,1] 上的贝塞尔截成左侧 [0,u]
    vec2 A1 = mix(A, B, u);
    vec2 B1 = mix(B, C, u);
    vec2 A2 = mix(A1, B1, u);
    L0 = A;
    L1 = A1;
    L2 = A2;
}

// -------------------------
// Path data injected by C++ generator
// -------------------------
/* ---- AUTO INJECT BEGIN ---- */
float uDurationSec   = 3.000;
float uThicknessPx   = 24.000;
vec3  uLineColor     = vec3(0.000, 0.000, 0.000);
vec3  uBgColor       = vec3(1.000, 1.000, 1.000);

#define NUM_LINES 4
#define NUM_QUADS 3
#define NUM_SEGMENTS 7

vec2 lineA[NUM_LINES] = vec2[NUM_LINES](
    vec2(0.07, 0.67),
    vec2(0.36, 0.67),
    vec2(0.57, 0.67),
    vec2(0.86, 0.67)
);
vec2 lineB[NUM_LINES] = vec2[NUM_LINES](
    vec2(0.21, 0.67),
    vec2(0.43, 0.67),
    vec2(0.71, 0.67),
    vec2(0.93, 0.67)
);

vec2 quadA[NUM_QUADS] = vec2[NUM_QUADS](
    vec2(0.21, 0.67),
    vec2(0.43, 0.67),
    vec2(0.71, 0.67)
);
vec2 quadB[NUM_QUADS] = vec2[NUM_QUADS](
    vec2(0.29, 0.33),
    vec2(0.50, 1.00),
    vec2(0.79, 0.40)
);
vec2 quadC[NUM_QUADS] = vec2[NUM_QUADS](
    vec2(0.36, 0.67),
    vec2(0.57, 0.67),
    vec2(0.86, 0.67)
);

const int segType[NUM_SEGMENTS] = int[NUM_SEGMENTS](0, 1, 0, 1, 0, 1, 0);
const int segIndex[NUM_SEGMENTS] = int[NUM_SEGMENTS](0, 0, 1, 1, 2, 2, 3);
vec2 segBMin[NUM_SEGMENTS] = vec2[NUM_SEGMENTS](
    vec2(0.071429, 0.666667),
    vec2(0.214286, 0.500000),
    vec2(0.357143, 0.666667),
    vec2(0.428571, 0.666667),
    vec2(0.571429, 0.666667),
    vec2(0.714286, 0.533333),
    vec2(0.857143, 0.666667)
);
vec2 segBMax[NUM_SEGMENTS] = vec2[NUM_SEGMENTS](
    vec2(0.214286, 0.666667),
    vec2(0.357143, 0.666667),
    vec2(0.428571, 0.666667),
    vec2(0.571429, 0.833333),
    vec2(0.714286, 0.666667),
    vec2(0.857143, 0.666667),
    vec2(0.928571, 0.666667)
);
const float segPrefix01[NUM_SEGMENTS+1] = float[NUM_SEGMENTS+1](0.000000, 0.095628, 0.346808, 0.394622, 0.645802, 0.741430, 0.952186, 1.000000);


// -------------------------
// Main rendering
// -------------------------
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    float s = min(iResolution.x, iResolution.y);
    vec2 p = pixelToNorm(fragCoord);   // 归一化空间（与你注入的 lineA/quadA 一致）
    
    // 给 bbox 剪枝留余量：线宽/2 + 2px(AA保险)
    float marginUv = (uThicknessPx * 0.5 + 2.0) / max(s, 1e-6);

    // 如果像素落在 letterbox 区域（uv 不在[0,1]），直接背景色返回
    if (p.x < 0.0 || p.x > 1.0 || p.y < 0.0 || p.y > 1.0) {
        fragColor = vec4(uBgColor, 1.0);
        return;
    }

    // 2) 用时间在整条路径的弧长上做进度映射
    float g = fract(iTime / uDurationSec);

    int   curS = 0;
    float u    = 0.0;

#if USE_ARCLENGTH_SPEED
    // g in [0,1)
    int lo = 0;
    int hi = NUM_SEGMENTS;

    // 固定次数二分：10 次可覆盖到 ~1024 段（2^10）
    for (int k = 0; k < 10; ++k) {
        int mid = (lo + hi) >> 1;
        if (g < segPrefix01[mid]) hi = mid;
        else lo = mid;
    }

    curS = clamp(lo, 0, NUM_SEGMENTS - 1);

    float denom = max(segPrefix01[curS + 1] - segPrefix01[curS], 1e-6);
    u = clamp((g - segPrefix01[curS]) / denom, 0.0, 1.0);
#else
    // 备用逻辑：每段等时
    float segf = g * float(NUM_SEGMENTS);
    curS = clamp(int(floor(segf)), 0, NUM_SEGMENTS - 1);
    u    = fract(segf);
#endif

    // 3) 渲染：已完成的段全长，当前段只画 0..u 的部分
    float dMin = 1e9;
    for (int s = 0; s < NUM_SEGMENTS; ++s) {
        bool isCur    = (s == curS);
        bool finished = (s < curS);

        if (!finished && !isCur) {
            // curS 之后的段还没开始画，直接 break
            break;
        }

        // --- AABB prune (uv space) ---
        vec2 mn = segBMin[s] - vec2(marginUv);
        vec2 mx = segBMax[s] + vec2(marginUv);
        float dBox = sdAABB(p, mn, mx);

        // dBox 是点到“扩过的 bbox”的距离下界；若已经比当前最优 dMin 大，就不可能更优
        if (dBox > dMin) {
            continue;
        }

        if (segType[s] == 0) {
#if NUM_LINES > 0
            vec2 A = lineA[segIndex[s]];
            vec2 B = lineB[segIndex[s]];
            if (isCur) {
                B = mix(A, B, u);
            }
            dMin = min(dMin, sdSegment(p, A, B));
#endif
        } else {
#if NUM_QUADS > 0
            vec2 A = quadA[segIndex[s]];
            vec2 B = quadB[segIndex[s]];
            vec2 C = quadC[segIndex[s]];
            if (isCur) {
                vec2 L0, L1, L2;
                leftSubcurveQuad(A, B, C, u, L0, L1, L2);
                dMin = min(dMin, sdQuadratic(p, L0, L1, L2));
            } else {
                dMin = min(dMin, sdQuadratic(p, A, B, C));
            }
#endif
        }
    }

    // 4) 距离 -> 线宽 & 颜色
    float dMinPx = dMin * s;

    float edge  = fwidth(dMinPx);
    float alpha = 1.0 - smoothstep(uThicknessPx * 0.5 - edge,
                                   uThicknessPx * 0.5 + edge, dMinPx);
    vec3 col = mix(uBgColor, uLineColor, alpha);
    fragColor = vec4(col, 1.0);
}

void main()
{
    mainImage(FragColor, gl_FragCoord.xy);
}
