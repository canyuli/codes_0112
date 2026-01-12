#version 330 core
out vec4 FragColor;

uniform vec2  iResolution;
uniform float iTime;

// ---- injected constants ----
const float uDurationSec = 3.0;
const float uThicknessPx = 24.0;
const vec3  uLineColor   = vec3(0.0);
const vec3  uBgColor     = vec3(1.0);

#define NUM_LINES    4
#define NUM_QUADS    3
#define NUM_SEGMENTS 7

uniform sampler2D uDummy; // 占位，避免某些驱动空 uniform 报错

// path data（完全保留）
const vec2 lineA[NUM_LINES] = vec2[](
    vec2(0.07,0.67), vec2(0.36,0.67),
    vec2(0.57,0.67), vec2(0.86,0.67)
);
const vec2 lineB[NUM_LINES] = vec2[](
    vec2(0.21,0.67), vec2(0.43,0.67),
    vec2(0.71,0.67), vec2(0.93,0.67)
);

const vec2 quadA[NUM_QUADS] = vec2[](
    vec2(0.21,0.67), vec2(0.43,0.67), vec2(0.71,0.67)
);
const vec2 quadB[NUM_QUADS] = vec2[](
    vec2(0.29,0.33), vec2(0.50,1.00), vec2(0.79,0.40)
);
const vec2 quadC[NUM_QUADS] = vec2[](
    vec2(0.36,0.67), vec2(0.57,0.67), vec2(0.86,0.67)
);

const int segType[NUM_SEGMENTS]  = int[](0,1,0,1,0,1,0);
const int segIndex[NUM_SEGMENTS] = int[](0,0,1,1,2,2,3);

const vec2 segBMin[NUM_SEGMENTS] = vec2[](
    vec2(0.071429,0.666667), vec2(0.214286,0.500000),
    vec2(0.357143,0.666667), vec2(0.428571,0.666667),
    vec2(0.571429,0.666667), vec2(0.714286,0.533333),
    vec2(0.857143,0.666667)
);
const vec2 segBMax[NUM_SEGMENTS] = vec2[](
    vec2(0.214286,0.666667), vec2(0.357143,0.666667),
    vec2(0.428571,0.666667), vec2(0.571429,0.833333),
    vec2(0.714286,0.666667), vec2(0.857143,0.666667),
    vec2(0.928571,0.666667)
);

const float segPrefix01[NUM_SEGMENTS+1] = float[](
    0.0, 0.095628, 0.346808, 0.394622,
    0.645802, 0.741430, 0.952186, 1.0
);

// ---- distance helpers ----
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
    return u*u*A + 2.0*u*t*B + t*t*C;
}

float sdQuadratic(vec2 p, vec2 A, vec2 B, vec2 C)
{
    float dMin = 1e9;
    vec2 prev = A;
    for (int i = 1; i <= 32; ++i) {
        float t = float(i) * (1.0 / 32.0);
        vec2 cur = evalQuad(A, B, C, t);
        dMin = min(dMin, sdSegment(p, prev, cur));
        prev = cur;
    }
    return dMin;
}

// ---- main ----
void main()
{
    vec2 frag = gl_FragCoord.xy;
    float s   = min(iResolution.x, iResolution.y);
    vec2 p    = (frag - 0.5 * iResolution) / s + vec2(0.5);

    if (any(lessThan(p, vec2(0.0))) || any(greaterThan(p, vec2(1.0)))) {
        FragColor = vec4(uBgColor, 1.0);
        return;
    }

    float g = fract(iTime / uDurationSec);

    int curS = 0;
    for (int i = 0; i < NUM_SEGMENTS; ++i) {
        if (g < segPrefix01[i+1]) { curS = i; break; }
    }

    float u = clamp((g - segPrefix01[curS]) /
                    max(segPrefix01[curS+1] - segPrefix01[curS], 1e-6),
                    0.0, 1.0);

    float marginUv = (uThicknessPx * 0.5 + 2.0) / s;
    vec2  margin   = vec2(marginUv);

    float dMin = 1e9;

    for (int sIdx = 0; sIdx < NUM_SEGMENTS; ++sIdx)
    {
        if (sIdx > curS) break;

        vec2 mn = segBMin[sIdx] - margin;
        vec2 mx = segBMax[sIdx] + margin;

        if (sdAABB(p, mn, mx) > dMin) continue;

        if (segType[sIdx] == 0) {
            vec2 A = lineA[segIndex[sIdx]];
            vec2 B = lineB[segIndex[sIdx]];
            if (sIdx == curS) B = mix(A, B, u);
            dMin = min(dMin, sdSegment(p, A, B));
        } else {
            vec2 A = quadA[segIndex[sIdx]];
            vec2 B = quadB[segIndex[sIdx]];
            vec2 C = quadC[segIndex[sIdx]];
            if (sIdx == curS) {
                vec2 A1 = mix(A, B, u);
                vec2 B1 = mix(B, C, u);
                vec2 A2 = mix(A1, B1, u);
                dMin = min(dMin, sdQuadratic(p, A, A1, A2));
            } else {
                dMin = min(dMin, sdQuadratic(p, A, B, C));
            }
        }
    }

    float dPx  = dMin * s;
    float aa   = fwidth(dPx);
    float a    = 1.0 - smoothstep(uThicknessPx*0.5 - aa,
                                  uThicknessPx*0.5 + aa, dPx);

    FragColor = vec4(mix(uBgColor, uLineColor, a), 1.0);
}
