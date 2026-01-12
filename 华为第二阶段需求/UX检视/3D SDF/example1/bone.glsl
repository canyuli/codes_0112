// ---------------- scene toggles ----------------
const float EPS_SURF   = 1e-4;
const int   SAMPLE_N   = 256;
const int   BISECT_ITR = 12;
const float TMAX       = 15.0; // 稍微调大了最大距离

// ---------------- helpers ----------------
mat3 rotX(float a){ float c=cos(a), s=sin(a); return mat3(1,0,0, 0,c,-s, 0,s,c); }
mat3 rotY(float a){ float c=cos(a), s=sin(a); return mat3(c,0,s, 0,1,0, -s,0,c); }
mat3 rotZ(float a){ float c=cos(a), s=sin(a); return mat3(c,-s,0, s,c,0, 0,0,1); }

// ---------------- params (你的原始骨头数据) ----------------
const int NUM_SQ = 9;
void getSQ(int i, out float params[11])
{
    if (i == 0) {
        const float tmp[11] = float[11](
            1.9880e-02, 1.2844e+00, 5.2008e-01,
            8.1490e-02, 3.1386e-01, -1.9663e-04,
            2.4917e-02, 1.2116e-03, -1.1451e+00,
            9.3522e-03, 1.4242e-02
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 1) {
        const float tmp[11] = float[11](
            2.9779e-01, 7.8671e-01, 1.4754e-01,
            1.6946e-01, 7.2975e-01, 1.5833e+00,
            -7.3674e-01, 1.5448e+00, -1.3119e+00,
            2.5380e-02, -1.4716e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 2) {
        const float tmp[11] = float[11](
            2.9773e-01, 7.8775e-01, 1.4740e-01,
            1.6953e-01, 7.2923e-01, 1.5583e+00,
            -7.3525e-01, 1.5968e+00, -1.3124e+00,
            -6.8557e-03, 1.6583e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 3) {
        const float tmp[11] = float[11](
            2.4099e-01, 8.0981e-01, 1.4916e-01,
            1.6923e-01, 8.4045e-01, 1.5641e+00,
            7.4804e-01, 1.5464e+00, -1.1977e+00,
            -5.7311e-03, -1.4621e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 4) {
        const float tmp[11] = float[11](
            2.9635e-01, 7.8877e-01, 1.4733e-01,
            1.6930e-01, 7.5546e-01, 1.5827e+00,
            7.3833e-01, 1.5970e+00, -1.2864e+00,
            2.5519e-02, 1.6553e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 5) {
        const float tmp[11] = float[11](
            8.7447e-01, 1.0364e+00, 2.6851e-01,
            2.6106e-01, 2.7171e-01, 3.1417e+00,
            -3.0640e+00, 1.5707e+00, -1.7868e+00,
            9.3435e-03, -1.6290e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 6) {
        const float tmp[11] = float[11](
            9.0330e-01, 8.4082e-01, 2.3286e-01,
            2.5246e-01, 2.4558e-01, 1.1300e-04,
            3.3377e-01, -4.3819e-05, -5.7483e-01,
            9.3491e-03, 1.6422e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 7) {
        const float tmp[11] = float[11](
            9.3967e-01, 8.6065e-01, 2.5854e-01,
            2.7342e-01, 2.6380e-01, 1.5793e-05,
            -6.1517e-01, 1.6238e-05, -1.7880e+00,
            9.3463e-03, 1.7849e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 8) {
        const float tmp[11] = float[11](
            9.0338e-01, 8.4093e-01, 2.3287e-01,
            2.5246e-01, 2.4557e-01, -1.9507e-05,
            -3.3396e-01, 1.0748e-04, -5.7484e-01,
            9.3430e-03, -1.4554e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else {
        for (int k = 0; k < 11; ++k) params[k] = 0.0;
    }
}

// ---------------- implicit: G(p) = F(p)-1 ----------------
float G_local(vec3 X, float e1, float e2, vec3 a){
    e1 = max(e1,1e-6);
    e2 = max(e2,1e-6);
    float invE1 = 1.0/e1, invE2 = 1.0/e2;

    vec3 q = abs(X) / max(a, vec3(1e-6));
    q = clamp(q, 1e-12, 3.0);

    float x = pow(q.x, 2.0*invE2);
    float y = pow(q.y, 2.0*invE2);
    float z = pow(q.z, 2.0*invE1);

    float base = min(x + y, 1e6);
    float xy   = pow(base, e2*invE1);

    return xy + z - 1.0;
}
float G_world(vec3 p, const float prm[11]){
    float e1=prm[0], e2=prm[1];
    vec3  a = vec3(prm[2],prm[3],prm[4]);
    vec3  ang=vec3(prm[5],prm[6],prm[7]); // z,y,x
    vec3  t  = vec3(prm[8],prm[9],prm[10]);

    mat3 R = rotZ(ang.x) * rotY(ang.y) * rotX(ang.z);
    vec3 X = transpose(R) * (p - t);      // world -> local
    return G_local(X, e1, e2, a);
}

// ---------------- ray-sphere bound per object ----------------
bool raySphere(vec3 ro, vec3 rd, vec3 c, float r, out float t0, out float t1){
    vec3 oc = ro - c;
    float b = dot(oc, rd);
    float c2= dot(oc, oc) - r*r;
    float D = b*b - c2;
    if(D < 0.0) return false;
    float s = sqrt(D);
    t0 = -b - s; t1 = -b + s;
    return t1 >= 0.0;
}

// ---------------- root finder (二分查找) ----------------
bool intersectSuper(vec3 ro, vec3 rd, const float prm[11], out float tHit){
    vec3 center = vec3(prm[8],prm[9],prm[10]);
    float rBound = max(prm[2], max(prm[3], prm[4])) * 1.05 * sqrt(3.0);

    float t0, t1;
    if(!raySphere(ro, rd, center, rBound, t0, t1)) return false;
    t0 = max(0.0, t0);
    t1 = min(t1, TMAX);
    if(t0 >= t1) return false;

    float prevT = t0;
    float prevG = G_world(ro + rd*t0, prm);
    bool found = false;
    float ta = t0, tb = t1;

    for(int i=1;i<=SAMPLE_N;i++){
        float t = mix(t0, t1, float(i)/float(SAMPLE_N));
        float Gt = G_world(ro + rd*t, prm);
        if(Gt == 0.0){ ta=tb=t; found=true; break; }
        if(prevG > 0.0 && Gt < 0.0){ ta = prevT; tb = t; found=true; break; }
        prevT = t; prevG = Gt;
    }
    if(!found) return false;

    float aT = ta, bT = tb;
    float Ga = G_world(ro + rd*aT, prm);
    float Gb = G_world(ro + rd*bT, prm);
    if(Ga*Gb > 0.0){
        float dt = (tb-ta)*0.1 + 1e-3;
        aT = max(t0, tb - dt); bT = min(t1, tb + dt);
        Ga = G_world(ro + rd*aT, prm);
        Gb = G_world(ro + rd*bT, prm);
        if(Ga*Gb > 0.0) return false;
    }
    for(int k=0;k<BISECT_ITR;k++){
        float m = 0.5*(aT+bT);
        float Gm = G_world(ro + rd*m, prm);
        if(abs(Gm) < 1e-6 || abs(bT-aT) < EPS_SURF){ aT=bT=m; break; }
        if(Ga*Gm <= 0.0){ bT=m; Gb=Gm; } else { aT=m; Ga=Gm; }
    }
    tHit = 0.5*(aT+bT);
    return tHit>=0.0 && tHit<=TMAX;
}

// ---------------- normal via finite difference ----------------
vec3 normalAt(vec3 p, const float prm[11], float t){
    float h = clamp(0.0005*(1.0+0.2*t), 5e-5, 2e-3);
    vec3 e = vec3(h,0,0);
    float gx = G_world(p+e.xyy, prm) - G_world(p-e.xyy, prm);
    float gy = G_world(p+e.yxy, prm) - G_world(p-e.yxy, prm);
    float gz = G_world(p+e.yyx, prm) - G_world(p-e.yyx, prm);
    return normalize(vec3(gx,gy,gz));
}

// ---------------- shading (白色！) ----------------
vec3 shade(vec3 pos, vec3 n, vec3 v){
    // 左上方光源
    vec3 lightPos  = vec3(-2.0, 4.0, 3.0);
    
    vec3 l = normalize(lightPos - pos);
    float ndl = max(dot(n,l),0.0);
    vec3 h = normalize(l+v);
    
    // 高光柔和一点
    float spec = pow(max(dot(n,h),0.0), 32.0);
    
    // [关键修改]：白色材质
    vec3 base = vec3(0.95);
    
    // 漫反射+环境光+高光
    return base*(0.3 + 0.7*ndl) + 0.4*spec;
}

// ---------------- main ----------------
void mainImage(out vec4 fragColor, in vec2 fragCoord){
    // 1. 计算所有 SQ 的几何中心，以便相机对焦
    vec3 sumPos = vec3(0.0);
    float validCount = 0.0;

    for(int i = 0; i < NUM_SQ; i++) {
        float prm[11]; 
        getSQ(i, prm);
        if(prm[2] > 0.001) { // 忽略空物体
            vec3 t = vec3(prm[8], prm[9], prm[10]);
            sumPos += t;
            validCount += 1.0;
        }
    }
    vec3 center = (validCount > 0.0) ? (sumPos / validCount) : vec3(0.0);

    // 2. 相机设置
    const float FOVY = radians(45.0);
    vec3 TARGET = center; 
    
    // 距离拉远一点，因为骨头可能比较长
    float dist = (1.2 / tan(0.5 * FOVY)) * 5.0; 

    // [关键修改]：斜向视角 (参考 image_ad306b 的角度)
    vec3 camDir = normalize(vec3(0.5, 0.6, 0.9)); 
    vec3 camPos = TARGET + camDir * dist;
    vec3 UP     = vec3(0.0, 1.0, 0.0);

    vec3 fw = normalize(TARGET - camPos);
    vec3 rt = normalize(cross(fw, UP));
    vec3 up = cross(rt, fw);

    vec2 q = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec3 rd = normalize(q.x * rt + q.y * up + (1.0 / tan(0.5 * FOVY)) * fw);

    // 3. 渲染循环 (遍历所有 SQ 找最近的)
    float bestT = 1e9;
    int   bestI = -1;

    for(int i=0;i<NUM_SQ;i++){
        float prm[11]; getSQ(i,prm);
        float tHit;
        if(intersectSuper(camPos, rd, prm, tHit)){
            if(tHit < bestT){ bestT = tHit; bestI = i; }
        }
    }

    vec3 col;
    if(bestI >= 0){
        float prm[11]; getSQ(bestI, prm);
        vec3 pos = camPos + rd*bestT;
        vec3 n   = normalAt(pos, prm, bestT);
        vec3 v   = normalize(camPos - pos);
        
        // 使用白色 Shading
        col = shade(pos, n, v);
    }else{
        float t = smoothstep(-0.5, 0.5, q.y);

        vec3 topColor = vec3(71.0/255.0, 170.0/255.0, 255.0/255.0);
        // 底部白色
        vec3 bottomColor = vec3(1.0);
        
        // 根据 t 在底部和顶部颜色之间进行插值
        col = mix(bottomColor, topColor, t);
    }

    col = pow(col, vec3(0.4545)); // Gamma Correction
    fragColor = vec4(col,1.0);
}