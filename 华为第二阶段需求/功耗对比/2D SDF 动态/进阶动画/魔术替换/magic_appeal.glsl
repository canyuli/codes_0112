#version 330 core
out vec4 FragColor;
in vec2 vUV;

uniform vec2  uResolution;
uniform sampler2D uSDF[2];
uniform float iTime;
uniform bool uSwitch;

// ======= 可改参数 =======
//INSERT HERE
const vec3 uBgColor      = vec3(1.00, 1.00, 1.00);
const vec3 uTexColor     = vec3(0.00, 0.00, 0.00);
const vec2 uCenter      = vec2(0.760, 0.315);
const float uRadius     = 0.180;
const float uDelay      = 0.0;
const float uDuration   = 0.3;

// —— 居中等比适配"正方形"（不含任何全局缩放） ——
void aspectFitSquare(out vec2 uvFit, out float inSquare){
    float w = uResolution.x, h = uResolution.y;
    float side = min(w, h); // 用 min 保持正方形
    vec2 origin = 0.5*vec2(w,h) - 0.5*vec2(side, side);
    vec2 frag   = gl_FragCoord.xy;
    uvFit = (frag - origin) / side; // [0,1]^2 覆盖窗口
    inSquare = step(0.0,uvFit.x)*step(uvFit.x,1.0)*step(0.0,uvFit.y)*step(uvFit.y,1.0);
}

# define PI 3.1415926
float opUnion(float d1, float d2) {
    return min(d1, d2);
}
float opSubtraction(float d1, float d2) {
    return max(d1, -d2);
}
float sdCircle(vec2 p, float x, float y, float r) {
    return length(p - vec2(x, y)) - r;
}
float easeOutBack(float t){
    float s = 1.70158;
    t = t - 1.0;
    return 1.0 + t*t*((s+1.0)*t + s);
}
void main() {
    // —— 居中正方形 —— 
    vec2 uv; float inSquare;
    aspectFitSquare(uv, inSquare);

    float delay = uDelay;
    float duration = uDuration;
    float bounceDur = uDuration;

    // 总周期
    float total = delay + duration + bounceDur;


    float phase1, phase2;
    if (iTime < delay) {
        phase1 = 0.0;
        phase2 = 0.0;
    } 
    else if (iTime < delay + duration) {
        float u = (iTime - delay) / duration;
        phase1 = smoothstep(0.0, 1.0, u);
        phase2 = 0.0;
    }
    else {
        float d = (iTime - delay - duration) / bounceDur;
        phase1 = 1.0;
        phase2 = smoothstep(0.0, 1.0, d);
    }


    vec2 center0 = vec2(0.5, 0.5);
    
    float scale = 1.0;
    if(uSwitch)
    {
        if(phase1 < 1.0){
            scale = mix(1.0, 1.1, phase1);
        } else {
            float bounce = easeOutBack(phase2);
            scale = mix(1.1, 1.0, bounce);
        }
    }
    else{
        if(phase1 < 1.0){
            scale = mix(1.0, 0.8, phase1);
        } else {
            float bounce = easeOutBack(phase2);
            scale = mix(0.8, 1.0, bounce);
        }
    }
    vec2 uv1 = (uv - center0) / max(scale , 1e-3) + center0;
    float sd0 = texture(uSDF[0], uv1).r - 0.5;
    sd0 = -sd0;

    float scale2;
    if (uSwitch){
        if(phase1 < 1.0){
            scale2 = mix(0.0, 1.1, phase1);
        } else {
            float bounce = easeOutBack(phase2);
            scale2 = mix(1.1, 1.0, bounce);
        }
    }
    else{
        scale2 = mix(1.0, 0.0, phase1);
    }
    vec2 uv2 = (uv - uCenter) / max(scale2, 1e-3) + uCenter;
    float sd1 = texture(uSDF[1], uv2).r - 0.5;
    sd1 = -sd1;
    float sd2 = sdCircle(uv, uCenter.x, uCenter.y, uRadius * scale2);
    if(sd2 > 0){
        sd2 = 0.5;
    }
    else if(sd2 < 0){
        sd2 = -0.5;
    }
    else{
        sd2 = 0;
    }

    float sd = opSubtraction(sd0, sd2);
    sd = opUnion(sd, sd1);

    float w = fwidth(sd);
    float a = smoothstep(-w, w, -sd);
    FragColor = vec4(mix(uBgColor, uTexColor, a),1.0);
}