const int   MAX_STEPS   = 150;
const float MAX_DIST    = 50.0;
const float SURF_DIST   = 1e-3;

float sdSuperquadric(vec3 p, vec3 r, vec2 e) {
    p = abs(p);
    float p1 = pow(pow(p.x / r.x, 2.0 / e.y) + pow(p.y / r.y, 2.0 / e.y), e.y / e.x);
    float p2 = pow(p1 + pow(p.z / r.z, 2.0 / e.x), e.x / 2.0);
    return (p2 - 1.0) * min(min(r.x, r.y), r.z) * 0.5;
}

float map(vec3 p) {
    vec3 radii = vec3(0.77, 0.38, 0.36);
    float d1 = sdSuperquadric(p, radii, vec2(1.0, 1.0));
    float d2 = sdSuperquadric(p, radii * 0.6, vec2(0.2, 0.2));
    return min(d1,d2);
}

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
    vec2 e = vec2(.001, 0);
    vec3 n = d - vec3(
        map(p-e.xyy),
        map(p-e.yxy),
        map(p-e.yyx));
    return normalize(n);
}

vec3 shade(vec3 pos, vec3 n, vec3 v){
    vec3 lightPos  = vec3(1.6, 2.2, -0.9);
    
    vec3 l = normalize(lightPos - pos);
    float ndl = max(dot(n,l), 0.0);
    vec3 h = normalize(l+v);
    
    float spec = pow(max(dot(n,h), 0.0), 64.0);
    
    vec3 base = vec3(0.05); 
    
    return base * (0.15 + 1.0 * ndl) + 0.4 * spec;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    const float FOVY     = radians(45.0); 
    const vec3  TARGET   = vec3(0.0);
    const vec3  UP       = vec3(0.0,1.0,0.0);

    float dist = (1.2 / tan(0.5 * FOVY)) * 2.5; 

    vec3 camDir = normalize(vec3(0.8, 0.6, -1.0));
    vec3 camPos = TARGET + camDir * dist;

    vec3 fw = normalize(TARGET - camPos);
    vec3 rt = normalize(cross(fw, UP));
    vec3 up = cross(rt, fw);

    vec2 q = (fragCoord - 0.5*iResolution.xy) / iResolution.y;
    vec3 rd = normalize(q.x*rt + q.y*up + (1.0/tan(0.5*FOVY))*fw);
    float d = raymarch(camPos, rd);

    vec3 col;
    if(d < MAX_DIST){
        vec3 pos = camPos + rd * d;
        vec3 n   = getNormal(pos);
        vec3 v   = normalize(camPos - pos);
        
        vec3 baseColor = vec3(0.8, 0.8, 0.8);
        col = baseColor * shade(pos, n, v);
    } else {
        col = vec3(0.62, 0.78, 1.0);
    }

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col,1.0);
}