const float EPS_SURF   = 1e-4;
const int   SAMPLE_N   = 128;
const int   BISECT_ITR = 12;
const float TMAX       = 30.0;

const float AA_LEVEL = 2.0; 

mat3 rotX(float a){ float c=cos(a), s=sin(a); return mat3(1,0,0, 0,c,-s, 0,s,c); }
mat3 rotY(float a){ float c=cos(a), s=sin(a); return mat3(c,0,s, 0,1,0, -s,0,c); }
mat3 rotZ(float a){ float c=cos(a), s=sin(a); return mat3(c,-s,0, s,c,0, 0,0,1); }

float safe_pow(float b, float e) {
    if (b < 1e-12) return 0.0;
    return pow(b, e);
}

const int NUM_SQ = 6;
void getSQ(int i, out float params[11])
{

    if (i == 1) {
        const float tmp[11] = float[11](
            9.2051e-01, 9.897e-01, 4.8628e-01,
            4.7758e-01, 5.8163e-01, 1.5754e+00,
            1.1868e+00, 1.7509e+00, -1.4480e+00,
            2.8356e-02, 1.8098e-02
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 2) {
        const float tmp[11] = float[11](
            9.6842e-01, 9.0919e-01, 5.0124e-01,
            5.0653e-01, 5.0499e-01, -1.5692e+00,
            -1.0267e+00, 1.0211e-03, -1.5196e+00,
            1.1168e-02, 1.1163e-02
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 3) {
        const float tmp[11] = float[11](
            5.7956e-01, 5.1827e-03, 3.1237e-01,
            1.1178e-01, 1.1122e-01, 3.1409e+00,
            1.6846e-03, 1.5701e+00, -6.9470e-01,
            1.0396e-02, 1.0369e-02
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 4) {
        const float tmp[11] = float[11](
            9.7364e-01, 7.5797e-01, 1.5425e-01,
            1.2695e-01, 1.3488e-01, -2.6122e-03,
            3.3390e-01, -3.0299e-02, -5.2002e-01,
            1.0252e-02, -5.8239e-02
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 5) {
        const float tmp[11] = float[11](
            9.3838e-01, 7.1898e-01, 1.5780e-01,
            1.2498e-01, 1.3856e-01, -3.7787e-03,
            -4.9300e-01, -3.7979e-03, -5.2343e-01,
            1.0120e-02, 7.1472e-02
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else {
        for (int k = 0; k < 11; ++k) params[k] = 0.0;
    }
}

float G_local(vec3 X, float e1, float e2, vec3 a){
    e1 = max(e1, 0.01); 
    e2 = max(e2, 0.01);
    
    float invE1 = 1.0/e1, invE2 = 1.0/e2;

    vec3 q = abs(X) / max(a, vec3(1e-6));

    float x = pow(q.x, 2.0*invE2);
    float y = pow(q.y, 2.0*invE2);
    float z = pow(q.z, 2.0*invE1);

    float base = x + y;
    float xy   = pow(base, e2*invE1);

    return xy + z - 1.0;
}

vec3 getRawGradient(vec3 p, const float prm[11]) {
    float e1 = max(prm[0], 0.01);
    float e2 = max(prm[1], 0.01);
    vec3 scale = vec3(prm[2], prm[3], prm[4]);
    vec3 ang = vec3(prm[5], prm[6], prm[7]);
    vec3 center = vec3(prm[8], prm[9], prm[10]);

    mat3 R = rotZ(ang.x) * rotY(ang.y) * rotX(ang.z);
    mat3 RT = transpose(R); 
    vec3 localP = RT * (p - center);
    vec3 signP = sign(localP);
    vec3 q = abs(localP) / max(scale, vec3(1e-6));

    float r_e2 = 2.0/e2;
    float r_e1 = 2.0/e1;

    float x_term = safe_pow(q.x, r_e2 - 1.0);
    float y_term = safe_pow(q.y, r_e2 - 1.0);
    float z_term = safe_pow(q.z, r_e1 - 1.0);

    float base_xy = safe_pow(q.x, r_e2) + safe_pow(q.y, r_e2);
    float pre_xy  = safe_pow(base_xy, e2/e1 - 1.0);

    vec3 localGrad;
    localGrad.x = pre_xy * x_term * signP.x / scale.x;
    localGrad.y = pre_xy * y_term * signP.y / scale.y;
    localGrad.z = z_term * signP.z / scale.z;

    return R * localGrad; 
}

vec3 normalAt(vec3 p, const float prm[11], float t) {
    vec3 g = getRawGradient(p, prm);
    if(dot(g,g) < 1e-12) return vec3(0,1,0);
    return normalize(g);
}

bool intersectAABB(vec3 ro, vec3 rd, vec3 boxSize, out float tNear, out float tFar) {
    vec3 m = 1.0 / rd; 
    vec3 n = m * ro;   
    vec3 k = abs(m) * boxSize;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;

    tNear = max(max(t1.x, t1.y), t1.z);
    tFar  = min(min(t2.x, t2.y), t2.z);

    return tNear <= tFar && tFar > 0.0;
}

bool intersectSuper(vec3 ro, vec3 rd, const float prm[11], out float tHit){
    float e1 = max(prm[0], 0.01);
    float e2 = max(prm[1], 0.01);
    vec3 scale = vec3(prm[2], prm[3], prm[4]);
    vec3 ang = vec3(prm[5], prm[6], prm[7]);
    vec3 center = vec3(prm[8], prm[9], prm[10]);

    mat3 R = rotZ(ang.x) * rotY(ang.y) * rotX(ang.z);
    mat3 invR = transpose(R); 
    vec3 roLocal = invR * (ro - center);
    vec3 rdLocal = invR * rd;

    float tNear, tFar;
    if(!intersectAABB(roLocal, rdLocal, scale * 1.01, tNear, tFar)) return false;

    tNear = max(0.0, tNear);
    tFar = min(tFar, TMAX);
    if(tNear >= tFar) return false;

    float t = tNear;
    float prevT = tNear;
    float prevG = G_local(roLocal + rdLocal * tNear, e1, e2, scale);
    
    if(prevG < 0.0) { tHit = tNear; return true; }

    bool foundBracket = false;
    for(int i = 0; i < SAMPLE_N; i++) {
        t = mix(tNear, tFar, float(i+1) / float(SAMPLE_N));
        
        float curG = G_local(roLocal + rdLocal * t, e1, e2, scale);

        if(curG < 0.0) {
            foundBracket = true;
            break; 
        }
        prevT = t;
        prevG = curG;
    }

    if(!foundBracket) return false;

    float tLow = prevT, tHigh = t;
    for(int k = 0; k < BISECT_ITR; k++) {
        float tMid = (tLow + tHigh) * 0.5;
        float val = G_local(roLocal + rdLocal * tMid, e1, e2, scale);
        if(val > 0.0) tLow = tMid; else tHigh = tMid;
    }

    tHit = tLow; 
    return true;
}

vec3 shade(vec3 pos, vec3 n, vec3 v){
    vec3 lightPos  = vec3(-2.0, 4.0, 3.0);
    vec3 l = normalize(lightPos - pos);
    float ndl = max(dot(n,l),0.0);
    vec3 h = normalize(l+v);
    
    float spec = pow(max(dot(n,h),0.0), 32.0);
    vec3 base = vec3(0.95);
    
    return base*(0.4 + 0.6*ndl) + 0.4*spec;
}

vec3 render(vec2 fragCoord, vec3 camPos, vec3 rt, vec3 up, vec3 fw, float FOVY) {
    vec2 q = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec3 rd = normalize(q.x * rt + q.y * up + (1.0 / tan(0.5 * FOVY)) * fw);

    float bestT = 1e9;
    int   bestI = -1;

    for(int i=0; i<NUM_SQ; i++){
        float prm[11]; getSQ(i,prm);
        if(prm[2] < 0.001) continue; 

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
        col = shade(pos, n, v);
    }else{
        float t = smoothstep(-0.5, 0.5, q.y);
        vec3 topColor = vec3(71.0/255.0, 170.0/255.0, 255.0/255.0);
        vec3 bottomColor = vec3(1.0);
        col = mix(bottomColor, topColor, t);
    }
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    vec3 sumPos = vec3(0.0);
    float validCount = 0.0;
    for(int i = 0; i < NUM_SQ; i++) {
        float prm[11]; getSQ(i, prm);
        if(prm[2] > 0.001) {
            vec3 t = vec3(prm[8], prm[9], prm[10]);
            sumPos += t; validCount += 1.0;
        }
    }
    vec3 center = (validCount > 0.0) ? (sumPos / validCount) : vec3(0.0);

    const float FOVY = radians(45.0);
    vec3 TARGET = center; 
    float dist = (1.2 / tan(0.5 * FOVY)) * 9.0; 

    vec3 camDir = normalize(vec3(0.7, 50.0, 1.0)); 
    vec3 camPos = TARGET + camDir * dist;
    vec3 UP     = vec3(0.0, 1.0, 0.0);

    vec3 fw = normalize(TARGET - camPos);
    vec3 rt = normalize(cross(fw, UP));
    vec3 up = cross(rt, fw);

    vec3 totalColor = vec3(0.0);
    
    for(float x = 0.0; x < AA_LEVEL; x++) {
        for(float y = 0.0; y < AA_LEVEL; y++) {
            vec2 offset = vec2(x, y) / AA_LEVEL - (0.5 / AA_LEVEL);
            
            totalColor += render(fragCoord + offset, camPos, rt, up, fw, FOVY);
        }
    }
    
    vec3 finalColor = totalColor / (AA_LEVEL * AA_LEVEL);

    finalColor = pow(finalColor, vec3(0.4545));
    fragColor = vec4(finalColor, 1.0);
}