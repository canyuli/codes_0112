const float EPS_SURF   = 1e-4;
const int   SAMPLE_N   = 256;
const int   BISECT_ITR = 12;
const float TMAX       = 15.0;

mat3 rotX(float a){ float c=cos(a), s=sin(a); return mat3(1,0,0, 0,c,-s, 0,s,c); }
mat3 rotY(float a){ float c=cos(a), s=sin(a); return mat3(c,0,s, 0,1,0, -s,0,c); }
mat3 rotZ(float a){ float c=cos(a), s=sin(a); return mat3(c,-s,0, s,c,0, 0,0,1); }

const int NUM_SQ = 9;
void getSQ(int i, out float params[11])
{
    if (i == 0) {
        const float tmp[11] = float[11](
            9.6599e-01, 9.1807e-01, 1.9556e-01,
            1.9342e-01, 2.6606e-01, -7.4297e-09,
            -1.4257e-11, 1.2384e-10, -1.2079e+00,
            -7.8740e-03, -1.1811e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 1) {
        const float tmp[11] = float[11](
            1.0158e+00, 1.0211e+00, 3.3036e-01,
            3.2831e-01, 3.2792e-01, 1.5388e+00,
            1.1904e-02, 1.5708e+00, -1.1921e+00,
            2.6889e-03, 2.5386e-04
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 2) {
        const float tmp[11] = float[11](
            8.9332e-01, 9.2859e-01, 1.9657e-01,
            1.9341e-01, 1.6982e-01, 2.5968e-08,
            -7.5661e-03, 1.6050e-08, -1.1921e+00,
            -7.8740e-03, -5.1361e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 3) {
        const float tmp[11] = float[11](
            1.5946e-01, 9.8632e-01, 2.1376e-01,
            2.1470e-01, 2.4460e-01, 8.6328e-03,
            -5.6667e-05, 5.1474e-03, -1.1921e+00,
            1.4264e-03, 6.4063e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 4) {
        const float tmp[11] = float[11](
            9.9786e-01, 1.0015e+00, 4.0082e-01,
            4.0098e-01, 3.9387e-01, -2.0384e-02,
            -5.9159e-04, -1.1498e-02, -1.1921e+00,
            1.6391e-03, -4.7294e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 5) {
        const float tmp[11] = float[11](
            8.8558e-01, 9.2713e-01, 1.7789e-01,
            1.9076e-01, 1.1332e-01, -4.2158e-02,
            -1.1965e-02, -3.2030e-03, -1.2081e+00,
            8.3444e-03, 3.7726e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 6) {
        const float tmp[11] = float[11](
            1.0096e+00, 1.0148e+00, 2.6246e-01,
            2.6415e-01, 3.1856e-01, 1.5540e-02,
            -3.0059e-04, 1.3796e-02, -1.1921e+00,
            1.9566e-03, 4.2187e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 7) {
        const float tmp[11] = float[11](
            6.7277e-01, 1.0012e+00, 3.3468e-01,
            3.3460e-01, 1.0212e-01, -1.0425e+00,
            -8.1703e-04, -3.7230e-04, -1.1921e+00,
            1.7946e-03, 5.1014e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 8) {
        const float tmp[11] = float[11](
            8.3045e-01, 9.7274e-01, 8.7892e-02,
            8.7954e-02, 1.8998e-01, 3.1439e+00,
            -7.5865e-01, 1.5468e+00, -1.1991e+00,
            2.2327e-01, 3.8946e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else {
        for (int k = 0; k < 11; ++k) params[k] = 0.0;
    }
}
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

vec3 normalAt(vec3 p, const float prm[11], float t){
    float h = clamp(0.0005*(1.0+0.2*t), 5e-5, 2e-3);
    vec3 e = vec3(h,0,0);
    float gx = G_world(p+e.xyy, prm) - G_world(p-e.xyy, prm);
    float gy = G_world(p+e.yxy, prm) - G_world(p-e.yxy, prm);
    float gz = G_world(p+e.yyx, prm) - G_world(p-e.yyx, prm);
    return normalize(vec3(gx,gy,gz));
}

vec3 shade(vec3 pos, vec3 n, vec3 v){
    vec3 lightPos  = vec3(-2.0, 4.0, 3.0);
    
    vec3 l = normalize(lightPos - pos);
    float ndl = max(dot(n,l),0.0);
    vec3 h = normalize(l+v);
    
    float spec = pow(max(dot(n,h),0.0), 32.0);
    
    vec3 base = vec3(0.95);
    
    return base*(0.3 + 0.7*ndl) + 0.4*spec;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    vec3 sumPos = vec3(0.0);
    float validCount = 0.0;

    for(int i = 0; i < NUM_SQ; i++) {
        float prm[11]; 
        getSQ(i, prm);
        if(prm[2] > 0.001) { 
            vec3 t = vec3(prm[8], prm[9], prm[10]);
            sumPos += t;
            validCount += 1.0;
        }
    }
    vec3 center = (validCount > 0.0) ? (sumPos / validCount) : vec3(0.0);

    const float FOVY = radians(45.0);
    vec3 TARGET = center; 
    
    float dist = (1.2 / tan(0.5 * FOVY)) * 5.0; 

    vec3 camDir = normalize(vec3(0.0, 6.0, -1.0)); 
    
    vec3 camPos = TARGET + camDir * dist;
    vec3 UP     = vec3(0.0, 1.0, 0.0);

    vec3 fw = normalize(TARGET - camPos);
    vec3 rt = normalize(cross(fw, UP));
    vec3 up = cross(rt, fw);

    vec2 q = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec3 rd = normalize(q.x * rt + q.y * up + (1.0 / tan(0.5 * FOVY)) * fw);

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
        
        col = shade(pos, n, v);
    }else{
        float t = smoothstep(-0.5, 0.5, q.y);

        vec3 topColor = vec3(71.0/255.0, 170.0/255.0, 255.0/255.0);
        
        vec3 bottomColor = vec3(1.0);
        
        col = mix(bottomColor, topColor, t);
    }

    col = pow(col, vec3(0.4545)); 
    fragColor = vec4(col,1.0);
}