const int   MAX_STEPS  = 100;
const float MAX_DIST   = 50.0;
const float SURF_DIST  = 1e-3;

float sdEllipsoid( vec3 p, vec3 r )
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

float map(vec3 p) {
    vec3 radii = vec3(0.81, 0.44, 0.36);
    return sdEllipsoid(p, radii);
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
    const float FOVY    = radians(45.0); 
    const vec3  TARGET  = vec3(0.0);
    const vec3  UP      = vec3(0.0,1.0,0.0);

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