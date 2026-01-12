// ---------------- 1. Scene Toggles ----------------
const int   MAX_STEPS  = 100;
const float MAX_DIST   = 50.0;
const float SURF_DIST  = 1e-3;

// ---------------- 2. SDF Primitives ----------------

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

// ---------------- 3. Scene Mapping ----------------

float map(vec3 p) {
    float radius = 0.8;
    // 球体位于中心 (0,0,0)
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

// ---------------- 6. Shading (这里修改了颜色) ----------------

vec3 shade(vec3 pos, vec3 n, vec3 v){
    vec3 lightPos  = vec3(1.6, 2.2, -0.9);
    vec3 l = normalize(lightPos - pos);
    
    // 漫反射系数
    float ndl = max(dot(n,l), 0.0);
    vec3 h = normalize(l+v);
    
    // 高光系数
    float spec = pow(max(dot(n,h), 0.0), 64.0);
    
    // [关键修改]: 原来是 0.05 (黑)，现在改成 0.95 (白)
    vec3 base = vec3(0.95); 
    
    // 计算最终颜色：(基础色 * 亮度) + 高光
    // 我稍微调亮了环境光 (0.15 -> 0.3) 让阴影部分不那么死黑
    return base * (0.3 + 0.8 * ndl) + 0.4 * spec;
}

// ---------------- 7. Main ----------------

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    vec2 q = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // --- 摄像机逻辑 ---
    vec3 TARGET = vec3(0.0); 
    const float FOVY = radians(45.0);
    float dist = (1.2 / tan(0.5 * FOVY)) * 2.5; 

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
        
        // 直接使用 shade 计算出的白色
        col = shade(pos, n, v);
    } else {
        col = vec3(0.62, 0.78, 1.0); // 背景天蓝色
    }

    col = pow(col, vec3(0.4545)); 
    fragColor = vec4(col, 1.0);
}