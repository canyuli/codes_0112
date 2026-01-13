const float EPS_SURF   = 1e-4;
const int   SAMPLE_N   = 256;
const int   BISECT_ITR = 12;
const float TMAX       = 8.0;

mat3 rotX(float a){ float c=cos(a), s=sin(a); return mat3(1,0,0, 0,c,-s, 0,s,c); }
mat3 rotY(float a){ float c=cos(a), s=sin(a); return mat3(c,0,s, 0,1,0, -s,0,c); }
mat3 rotZ(float a){ float c=cos(a), s=sin(a); return mat3(c,-s,0, s,c,0, 0,0,1); }

const int NUM_SQ = 3;
void getSQ(int i, out float params[11])
{
    if (i == 0) {
        const float tmp[11] = float[11](
            9.4042e-01, 9.5016e-01, 2.6501e-01,
            1.9220e-01, 1.9167e-01, 1.0825e-11,
            8.0499e-11, 7.2356e-01, -1.1921e+00,
            7.8740e-03, 7.8740e-03
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 1) {
        const float tmp[11] = float[11](
            1.0514e+00, 9.8216e-01, 3.9288e-01,
            7.8532e-01, 3.4511e-01, 1.5708e+00,
            7.8860e-01, -3.1416e+00, -1.1921e+00,
            -4.0027e-02, -3.9621e-02
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 2) {
        const float tmp[11] = float[11](
            9.8010e-01, 1.0059e+00, 4.0750e-01,
            4.0948e-01, 8.0952e-01, 1.5710e+00,
            -6.9567e-01, 1.5706e+00, -1.1923e+00,
            9.7099e-03, 9.4510e-03
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
    vec3  ang=vec3(prm[5],prm[6],prm[7]); 
    vec3  t  = vec3(prm[8],prm[9],prm[10]);

    mat3 R = rotZ(ang.x) * rotY(ang.y) * rotX(ang.z);
    vec3 X = transpose(R) * (p - t);   
    return G_local(X, e1, e2, a);
}


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
    vec3 lightPos  = vec3(1.6, 2.2, -0.9);
    vec3 l = normalize(lightPos - pos);
    float ndl = max(dot(n,l),0.0);
    vec3 h = normalize(l+v);
    float spec = pow(max(dot(n,h),0.0), 64.0);
    vec3 base = vec3(0.05);
    return base*(0.15 + 1.0*ndl) + 0.4*spec;
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
    
    float dist = (1.2 / tan(0.5 * FOVY)) * 2.5; 

    vec3 camDir = normalize(vec3(0.8, 0.6, -1.0)); 
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
        vec3 baseColor = vec3(0.8, 0.8, 0.8);
        col = baseColor * shade(pos, n, v);
    }else{
        col = vec3(0.62, 0.78, 1.0);
    }

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col,1.0);
}