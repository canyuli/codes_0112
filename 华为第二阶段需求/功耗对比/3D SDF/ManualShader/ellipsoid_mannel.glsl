// ---------------- 1. Scene Toggles ----------------
const int   MAX_STEPS  = 100;
const float MAX_DIST   = 50.0;
const float SURF_DIST  = 1e-3;

// ---------------- 2. SDF Primitives (椭球体) ----------------

// 标准的椭球体 SDF 近似公式
float sdEllipsoid( vec3 p, vec3 r )
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

// ---------------- 3. Scene Mapping (修改了这里!) ----------------

float map(vec3 p) {
    // --- 定义椭球体形状 ---
    // [关键修改]：我交换了 X 和 Y 的半径值
    // 现在 r.x (宽度) 最大，所以它是横着的
    // r.x = 1.0 (长)
    // r.y = 0.5 (高)
    // r.z = 0.7 (深)
    vec3 radii = vec3(0.63, 0.32, 0.3);
    
    return sdEllipsoid(p, radii);
}

// ---------------- 4. Raymarching (光线步进) ----------------

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

// ---------------- 6. Shading (保持白色) ----------------

vec3 shade(vec3 pos, vec3 n, vec3 v){
    vec3 lightPos  = vec3(1.6, 2.2, -0.9);
    
    vec3 l = normalize(lightPos - pos);
    float ndl = max(dot(n,l), 0.0);
    vec3 h = normalize(l+v);
    
    float spec = pow(max(dot(n,h), 0.0), 64.0);
    
    // 保持白色
    vec3 base = vec3(0.95); 
    
    return base * (0.3 + 0.8 * ndl) + 0.4 * spec;
}

// ---------------- 7. Main (保持摄像机逻辑) ----------------

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    // ===== Camera (fixed 3/4 view) =====
    const float FOVY    = radians(45.0); 
    const float PADDING = 1.2;           
    const vec3  TARGET  = vec3(0.0);
    const vec3  UP      = vec3(0.0,1.0,0.0);

    float dist = PADDING / tan(0.5*FOVY);
    dist = dist * 2.0; 
    
    vec3 camPos = normalize(vec3(0.8, 0.6, -1.0)) * dist;

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
        col = shade(pos, n, v);
    } else {
        col = vec3(0.62, 0.78, 1.0); 
    }

    col = pow(col, vec3(0.4545)); 
    fragColor = vec4(col,1.0);
}