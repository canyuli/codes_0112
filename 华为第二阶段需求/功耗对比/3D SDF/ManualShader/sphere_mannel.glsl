// ---------------- 1. Scene Toggles ----------------
const int   MAX_STEPS  = 100;
const float MAX_DIST   = 50.0;
const float SURF_DIST  = 1e-3;

// ---------------- 2. SDF Primitives (球体) ----------------

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

// ---------------- 3. Scene Mapping ----------------

float map(vec3 p) {
    float radius = 0.82;
    return sdSphere(p, radius);
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

// ---------------- 6. Shading (严格复刻 Code 1 的暗调风格) ----------------

// ---------------- 6. Shading (修正版) ----------------

vec3 shade(vec3 pos, vec3 n, vec3 v){
    vec3 lightPos = vec3(2.9, 25.2, -8.3);
    
    vec3 l = normalize(lightPos - pos);
    
    // 漫反射
    float ndl = max(dot(n,l), 0.0);
    vec3 h = normalize(l+v);
    
    // 高光
    float spec = pow(max(dot(n,h), 0.0), 64.0);
    
    // 保持原本的材质感
    vec3 base = vec3(0.05); 
    
    return base * (0.15 + 1.0 * ndl) + 0.4 * spec;
}

// ---------------- 7. Main (严格复刻 Code 1 相机与合成) ----------------

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    vec2 q = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // --- 摄像机 ---
    vec3 TARGET = vec3(0.0); 
    const float FOVY = radians(45.0);
    
    // 距离系数保持 2.5
    float dist = (1.2 / tan(0.5 * FOVY)) * 2.5; 

    // 方位角保持一致
    vec3 camDir = normalize(vec3(0.8, 0.6, -1.0)); 
    vec3 camPos = TARGET + camDir * dist;
    vec3 UP     = vec3(0.0, 1.0, 0.0);

    vec3 fw = normalize(TARGET - camPos);
    vec3 rt = normalize(cross(fw, UP));
    vec3 up = cross(rt, fw);
    
    vec3 rd = normalize(q.x * rt + q.y * up + (1.0 / tan(0.5 * FOVY)) * fw);

    // --- 渲染 ---
    float d = raymarch(camPos, rd);
    
    vec3 col;
    if(d < MAX_DIST) {
        vec3 pos = camPos + rd * d;
        vec3 n   = getNormal(pos);
        vec3 v   = normalize(camPos - pos);
        
        // [修正]: 这里需要乘一个灰色的基色 (0.8)，才能还原第一段代码的颜色
        vec3 baseColor = vec3(0.8, 0.8, 0.8);
        col = baseColor * shade(pos, n, v);
    } else {
        col = vec3(0.62, 0.78, 1.0); // 天空蓝
    }

    col = pow(col, vec3(0.4545)); 
    fragColor = vec4(col, 1.0);
}