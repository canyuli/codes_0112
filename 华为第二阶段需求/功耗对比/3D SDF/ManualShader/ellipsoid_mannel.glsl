// ---------------- 1. Scene Toggles ----------------
const int   MAX_STEPS  = 100;
const float MAX_DIST   = 50.0;
const float SURF_DIST  = 1e-3;

// ---------------- 2. SDF Primitives (椭球体) ----------------

float sdEllipsoid( vec3 p, vec3 r )
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

// ---------------- 3. Scene Mapping ----------------

float map(vec3 p) {
    // 你的椭球体参数 (保持不变)
    vec3 radii = vec3(0.81, 0.44, 0.36);
    return sdEllipsoid(p, radii);
}

// ---------------- 4. Raymarching ----------------

float raymarch(vec3 ro, vec3 rd) {
    float dO = 0.0;
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd * dO;
        float dS = map(p);
        dO += dS;
        if(dO > MAX_DIST || abs(dS) < SURF_DIST) break;
    }
    return dO;
}

// ---------------- 5. Normal Calculation ----------------

vec3 getNormal(vec3 p) {
    float d = map(p);
    vec2 e = vec2(.001, 0);
    vec3 n = d - vec3(
        map(p-e.xyy),
        map(p-e.yxy),
        map(p-e.yyx));
    return normalize(n);
}

// ---------------- 6. Shading (严格复刻 Code 1) ----------------

// 这一步完全照搬 Code 1 的逻辑：
// 它的漫反射底色非常暗 (0.05)，主要靠高光和 main 函数里的颜色乘法
vec3 shade(vec3 pos, vec3 n, vec3 v){
    vec3 lightPos  = vec3(1.6, 2.2, -0.9);
    
    vec3 l = normalize(lightPos - pos);
    float ndl = max(dot(n,l), 0.0);
    vec3 h = normalize(l+v);
    
    // Code 1 的高光系数
    float spec = pow(max(dot(n,h), 0.0), 64.0);
    
    // Code 1 内部写死的暗底色
    vec3 base = vec3(0.05); 
    
    // Code 1 的混合权重: 0.15 环境 + 1.0 漫反射
    return base * (0.15 + 1.0 * ndl) + 0.4 * spec;
}

// ---------------- 7. Main (严格复刻 Code 1 相机) ----------------

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    // ===== Camera =====
    const float FOVY    = radians(45.0); 
    const vec3  TARGET  = vec3(0.0);
    const vec3  UP      = vec3(0.0,1.0,0.0);

    // [修正点 1] 距离系数改为 2.5 (Code 1 是 2.5，你之前 Code 2 是 2.0)
    // 假设包围盒半径约为 1.2
    float dist = (1.2 / tan(0.5 * FOVY)) * 2.5; 
    
    // [修正点 2] 相机方向完全锁定为 Code 1 的方向
    vec3 camDir = normalize(vec3(0.8, 0.6, -1.0));
    vec3 camPos = TARGET + camDir * dist;

    vec3 fw = normalize(TARGET - camPos);
    vec3 rt = normalize(cross(fw, UP));
    vec3 up = cross(rt, fw);

    vec2 q = (fragCoord - 0.5*iResolution.xy) / iResolution.y;
    vec3 rd = normalize(q.x*rt + q.y*up + (1.0/tan(0.5*FOVY))*fw);

    // --- 渲染 ---
    float d = raymarch(camPos, rd);

    vec3 col;
    if(d < MAX_DIST){
        vec3 pos = camPos + rd * d;
        vec3 n   = getNormal(pos);
        vec3 v   = normalize(camPos - pos);
        
        // [修正点 3] 基色改为灰色 0.8 (Code 1 是 0.8，你之前 Code 2 是 0.95 白色)
        vec3 baseColor = vec3(0.8, 0.8, 0.8);
        col = baseColor * shade(pos, n, v);
    } else {
        col = vec3(0.62, 0.78, 1.0); // 天空蓝
    }

    col = pow(col, vec3(0.4545)); // Gamma Correction
    fragColor = vec4(col,1.0);
}