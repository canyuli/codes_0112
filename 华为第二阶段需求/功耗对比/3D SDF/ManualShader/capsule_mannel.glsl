// ---------------- 1. Constants & SDF Helpers ----------------

const int   MAX_STEPS = 100;
const float MAX_DIST  = 50.0;
const float SURF_DIST = 1e-3;

// 胶囊体 SDF (保持不变)
float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

// ---------------- 2. Scene Mapping (你的胶囊体) ----------------

float map(vec3 p) {
    // --- 你的参数设定 ---
    // 半径: 0.57, 高度: 2.8
    float radius = 0.4;
    float height = 1.85;
    vec3 posA = vec3(0.0, -height*0.5, 0.0); 
    vec3 posB = vec3(0.0,  height*0.5, 0.0);
    
    return sdCapsule(p, posA, posB, radius);
}

// ---------------- 3. Raymarching Core ----------------

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

vec3 getNormal(vec3 p) {
    float d = map(p);
    vec2 e = vec2(1e-3, 0); // 使用较小的 epsilon 以匹配第一段代码的精度
    vec3 n = d - vec3(
        map(p-e.xyy),
        map(p-e.yxy),
        map(p-e.yyx));
    return normalize(n);
}

// ---------------- 4. Lighting & Shading (完全移植自第一段代码) ----------------
// 为了保证和“辛博”要求的一致性，这里的算法与第一段完全相同

vec3 shade(vec3 pos, vec3 n, vec3 v){
    // 第一段代码中的固定光源位置
    vec3 lightPos  = vec3(1.6, 2.2, -0.9);
    
    vec3 l = normalize(lightPos - pos);
    float ndl = max(dot(n,l),0.0);
    vec3 h = normalize(l+v);
    
    // 高光系数 64.0，带来比较锐利、金属感的反光
    float spec = pow(max(dot(n,h),0.0), 64.0);
    
    vec3 base = vec3(0.05);
    // 漫反射权重 1.0，高光权重 0.4，环境光 0.15
    return base*(0.15 + 1.0*ndl) + 0.4*spec;
}

// ---------------- 5. Main Image (相机逻辑移植) ----------------

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // --- 相机设置 (与第一段代码保持一致) ---
    const float FOVY = radians(45.0);
    vec3 UP = vec3(0.0, 1.0, 0.0);
    vec3 TARGET = vec3(0.0, 0.0, 0.0); // 胶囊体中心
    
    // 计算相机距离
    // 原代码逻辑：dist = (bound / tan(0.5*fov)) * 2.5
    // 这里的 bound 大约是 height/2 + radius ≈ 2.0
    float boundRadius = 2.0; 
    float dist = (boundRadius / tan(0.5 * FOVY)) * 2.5;

    // --- 关键：相机方向向量 (完全一致) ---
    // 这是保证“视角一致”的核心
    vec3 camDir = normalize(vec3(0.8, 0.6, -1.0)); 
    vec3 camPos = TARGET + camDir * dist;

    // --- 构建 LookAt 矩阵 ---
    vec3 fw = normalize(TARGET - camPos);
    vec3 rt = normalize(cross(fw, UP));
    vec3 up = cross(rt, fw);

    // --- 屏幕坐标 ---
    vec2 q = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec3 rd = normalize(q.x * rt + q.y * up + (1.0 / tan(0.5 * FOVY)) * fw);

    // --- 渲染 ---
    float d = raymarch(camPos, rd);
    
    vec3 col;
    
    if(d < MAX_DIST) {
        vec3 pos = camPos + rd * d;
        vec3 n = getNormal(pos);
        vec3 v = normalize(camPos - pos); // 视线向量
        
        // 使用第一段代码定义的物体基色 (浅灰)
        vec3 baseColor = vec3(0.8, 0.8, 0.8);
        
        // 应用移植过来的 shade 函数
        col = baseColor * shade(pos, n, v);
    } else {
        // 使用第一段代码定义的背景色 (天空蓝)
        col = vec3(0.62, 0.78, 1.0);
    }

    // --- 后处理 (Gamma Correction) ---
    col = pow(col, vec3(0.4545)); // Gamma 2.2
    
    fragColor = vec4(col, 1.0);
}