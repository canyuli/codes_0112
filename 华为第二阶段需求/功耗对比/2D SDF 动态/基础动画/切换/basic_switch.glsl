
#version 330 core
in vec2 vUv;
out vec4 fragColor;

uniform sampler2D uSdf;
uniform sampler2D uSdf2;
uniform float iTime;
uniform vec2 iResolution;  // 添加分辨率uniform

vec2 scaleAround(vec2 uv, vec2 pivot, float s){
    return (uv - pivot) / s + pivot;
}

// 模式6模板中的比例调整函数也要一致
vec2 adjustAspect(vec2 uv, vec2 resolution) {
    float aspect = resolution.x / resolution.y;
    vec2 scale = vec2(1.0);
    
    if (aspect > 1.0) {
        scale.y = 1.0 / aspect;
    } else {
        scale.x = aspect;
    }
    
    return (uv - 0.5) * scale + 0.5;
}

float ease01(float x){ return smoothstep(0.0, 1.0, clamp(x, 0.0, 1.0)); }
float sdfAlpha(sampler2D tex, vec2 uv){
    if(uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) return 0.0;
    float sd = texture(tex, uv).r - 0.5;
    float w = fwidth(sd) * 1.25;
    float a = clamp(sd / w + 0.5, 0.0, 1.0);
    return a;
}

void main(){
    vec3 fg = vec3(1.0);
        float aTime = 2.00;
    vec3 bg = vec3(0, 0, 0);


    // 调整UV以保持比例
    vec2 adjustedUv = adjustAspect(vUv, iResolution);

    float tShrink = aTime/2.;
    float tGrow   = aTime/2.;
    float tGap    = 0.00;
    float t1 = tShrink;
    float t2 = t1 + tGap;
    float t3 = t2 + tGrow;

    float scale1, op1;
    if(iTime < t1){
        float u = ease01(iTime/tShrink);
        scale1 = mix(0.5, 0.25, u);
        op1    = 1.0 - u;
    }else{ scale1 = 0.25; op1 = 0.0; }

    float scale2, op2;
    if(iTime < t2){ scale2 = 0.25; op2 = 0.0; }
    else if(iTime < t3){
        float v = ease01((iTime - t2)/tGrow);
        scale2 = mix(0.25, 0.5, v);
        op2    = v;
    }else{ scale2 = 0.5; op2 = 1.0; }

    vec2 tuv1 = scaleAround(adjustedUv, vec2(0.5), scale1);
    vec2 tuv2 = scaleAround(adjustedUv, vec2(0.5), scale2);
    float a1 = sdfAlpha(uSdf, tuv1) * op1;
    float a2 = sdfAlpha(uSdf2, tuv2) * op2;
    float a = 1.0 - (1.0 - a1) * (1.0 - a2);
    fragColor = vec4(mix(fg, bg, a), 1.0);
}
