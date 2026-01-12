#version 330 core
in vec2 vUv;
out vec4 fragColor;

uniform sampler2D uSdf;
uniform sampler2D uSdf2;
uniform float iTime;
uniform vec2 iResolution;

float sdfAlpha(sampler2D tex, vec2 uv){
    if(any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0))))
        return 0.0;
    float sd = texture(tex, uv).r - 0.5;
    float w = fwidth(sd) * 1.25;
    return clamp(sd / w + 0.5, 0.0, 1.0);
}

void main(){
    vec3 fg = vec3(1.0);
    vec3 bg = vec3(0.0);
    float aTime = 2.0;

    float aspect = iResolution.x / iResolution.y;
    vec2 uvScale = (aspect > 1.0) ? vec2(1.0, 1.0 / aspect) : vec2(aspect, 1.0);
    vec2 uv = (vUv - 0.5) * uvScale + 0.5;

    float tShrink = aTime * 0.5;
    float tGrow = aTime * 0.5;
    float tGap = 0.0;
    float t1 = tShrink;
    float t2 = t1 + tGap;
    float t3 = t2 + tGrow;

    float scale1, op1;
    if(iTime < t1){
        float u = smoothstep(0.0, 1.0, iTime / tShrink);
        scale1 = mix(0.5, 0.25, u);
        op1 = 1.0 - u;
    }else{
        scale1 = 0.25;
        op1 = 0.0;
    }

    float scale2, op2;
    if(iTime < t2){
        scale2 = 0.25;
        op2 = 0.0;
    }else if(iTime < t3){
        float v = smoothstep(0.0, 1.0, (iTime - t2) / tGrow);
        scale2 = mix(0.25, 0.5, v);
        op2 = v;
    }else{
        scale2 = 0.5;
        op2 = 1.0;
    }

    vec2 tuv1 = (uv - 0.5) / scale1 + 0.5;
    vec2 tuv2 = (uv - 0.5) / scale2 + 0.5;
    float a1 = sdfAlpha(uSdf, tuv1) * op1;
    float a2 = sdfAlpha(uSdf2, tuv2) * op2;
    float a = 1.0 - (1.0 - a1) * (1.0 - a2);
    fragColor = vec4(mix(fg, bg, a), 1.0);
}

