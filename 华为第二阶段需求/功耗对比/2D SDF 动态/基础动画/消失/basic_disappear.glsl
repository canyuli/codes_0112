
#version 330 core
in vec2 vUv;
out vec4 fragColor;

uniform sampler2D uSdf;
uniform float iTime;
uniform vec2 iResolution;

vec2 scaleAround(vec2 uv, vec2 pivot, float s){
    return (uv - pivot) / s + pivot;
}

// 正确的比例调整函数
vec2 adjustAspect(vec2 uv, vec2 resolution) {
    float aspect = resolution.x / resolution.y;
    vec2 scale = vec2(1.0);
    
    // 保持1:1比例
    if (aspect > 1.0) {
        // 宽屏：水平方向缩放，垂直方向不变（左右会有黑边）
        scale.y = 1.0 / aspect;
    } else {
        // 高屏：垂直方向缩放，水平方向不变（上下会有黑边）
        scale.x = aspect;
    }
    
    return (uv - 0.5) * scale + 0.5;
}

void main(){
    float scale = 0.5;
    vec3 fg = vec3(1.0);
    float preTime = 0.001;
        float aTime = 2.00;
    vec3 bg = vec3(0, 0, 0);
    if(iTime < aTime){
        float t = iTime / aTime; 
        t = smoothstep(0.0, 1.0, t); 
        scale = mix(0.5, 0.001, t);
    } else {
        fragColor = vec4(1.0);
        return;
    }


    // 调整UV以保持比例
    vec2 adjustedUv = adjustAspect(vUv, iResolution);
    vec2 tuv = scaleAround(adjustedUv, vec2(0.5), scale);
    
    // 检查是否在有效范围内
    if (tuv.x < 0.0 || tuv.x > 1.0 || tuv.y < 0.0 || tuv.y > 1.0) {
        fragColor = vec4(1.0);  // 超出范围显示背景色
        return;
    }

    float sd = texture(uSdf, tuv).r - 0.5;
    float w = fwidth(sd) * 1.25;
    float a = 1.0 - clamp(sd / w + 0.5, 0.0, 1.0);
    fragColor = vec4(mix(bg, fg, a), 1.0);
}
