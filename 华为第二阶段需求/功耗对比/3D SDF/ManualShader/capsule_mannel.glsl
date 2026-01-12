// ---------------- 1. SDF Primitives (核心几何体) ----------------

// 标准的胶囊体 SDF 函数 (保持不变)
float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

// ---------------- 2. Scene Mapping (场景定义) - [核心修改区域] ----------------

float map(vec3 p) {
    // --- 定义胶囊体参数 (在这里修改形状) ---
    
    // [修改点 1]: 半径变小 -> 更瘦
    float radius = 0.57;           // 原来是 0.5，现在改成了 0.25
    
    // [修改点 2]: 高度变大 -> 更长
    float height = 2.8;            // 原来是 1.0，现在改成了 3.0
    
    // 让胶囊体垂直竖立 (沿Y轴)
    // 端点坐标会自动根据上面的 height 计算
    vec3 posA = vec3(0.0, -height*0.5, 0.0); 
    vec3 posB = vec3(0.0,  height*0.5, 0.0);
    
    return sdCapsule(p, posA, posB, radius);
}

// ---------------- 3. Raymarching (光线追踪算法) (保持不变) ----------------

const int MAX_STEPS = 100;      
const float MAX_DIST = 50.0;    // 把最大距离稍微改大了一点，防止拉太远看不见
const float SURF_DIST = 1e-3;   

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

// ---------------- 4. Normal Calculation (法线计算) (保持不变) ----------------

vec3 getNormal(vec3 p) {
    float d = map(p);
    vec2 e = vec2(.001, 0); 
    vec3 n = d - vec3(
        map(p-e.xyy),
        map(p-e.yxy),
        map(p-e.yyx));
    return normalize(n);
}

// ---------------- 5. Shading (光照渲染) (保持不变) ----------------

vec3 getLight(vec3 p, vec3 rd) {
    vec3 lightPos = vec3(2.0, 5.0, -3.0); // 稍微抬高了一点光源
    vec3 l = normalize(lightPos - p);     
    vec3 n = getNormal(p);                
    float dif = clamp(dot(n, l), 0.0, 1.0);
    float amb = 0.5 + 0.5 * dot(n, vec3(0.0, 1.0, 0.0)); 
    vec3 r = reflect(-l, n);
    float spec = pow(max(dot(r, -rd), 0.0), 32.0); 
    vec3 col = vec3(0.8); 
    col = col * dif + col * amb * 0.2 + vec3(0.5) * spec;
    return col;
}

// ---------------- 6. Main (主入口 - 使用你的高级相机逻辑) ----------------

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // --- 1. 定义目标和中心 (简化掉 validCount) ---
    // 因为我们知道胶囊体就在 (0,0,0)，所以直接设为中心
    vec3 TARGET = vec3(0.0, 0.0, 0.0); 

    // --- 2. 计算距离 (控制"远一点") ---
    const float FOVY = radians(45.0);
    
    // 这里原本是 * 2.5，如果你觉得不够远，就把 2.5 改成 5.0 或 6.0
    // 1.2 是假设的物体包围球半径 (胶囊体高3.0，半径0.25，差不多这个范围)
    float zoomFactor = 6.0; 
    float dist = (1.2 / tan(0.5 * FOVY)) * zoomFactor; 

    // --- 3. 设置摄像机位置和方向 ---
    // 摄像机方向：从右上方看向中心 (保持你喜欢的角度)
    vec3 camDir = normalize(vec3(0.8, 0.6, -1.0)); 
    vec3 camPos = TARGET + camDir * dist; // 自动算出相机应该在哪
    vec3 UP     = vec3(0.0, 1.0, 0.0);

    // --- 4. 构建相机矩阵 (LookAt Matrix) ---
    vec3 fw = normalize(TARGET - camPos); // Forward: 相机看向目标
    vec3 rt = normalize(cross(fw, UP));   // Right: 右手边
    vec3 up = cross(rt, fw);              // Up: 头顶方向

    // --- 5. 生成光线 (Ray Direction) ---
    // 修正屏幕长宽比
    vec2 q = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    
    // 这里的 1.0 / tan(...) 是把视场角转换成焦距
    vec3 rd = normalize(q.x * rt + q.y * up + (1.0 / tan(0.5 * FOVY)) * fw);

    // --- 6. 执行渲染 (保持不变) ---
    float d = raymarch(camPos, rd); // 注意：这里传入的是算好的 camPos

    // 计算颜色
    vec3 col = vec3(0.62, 0.78, 1.0); 
    if(d < MAX_DIST) {
        vec3 p = camPos + rd * d; 
        col = getLight(p, rd);
    }
    
    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}