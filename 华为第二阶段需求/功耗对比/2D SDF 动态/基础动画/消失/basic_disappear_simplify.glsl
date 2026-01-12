#version 330 core
in vec2 vUv;
out vec4 fragColor;

uniform sampler2D uSdf;
uniform float iTime;
uniform vec2 iResolution;

void main(){
    vec3 fg = vec3(1.0);
    vec3 bg = vec3(0.0);
    float aTime = 2.0;

    if(iTime >= aTime){
        fragColor = vec4(1.0);
        return;
    }

    float t = smoothstep(0.0, 1.0, iTime / aTime);
    float scale = mix(0.5, 0.001, t);

    float aspect = iResolution.x / iResolution.y;
    vec2 uvScale = (aspect > 1.0) ? vec2(1.0, 1.0 / aspect) : vec2(aspect, 1.0);
    vec2 uv = (vUv - 0.5) * uvScale + 0.5;
    vec2 tuv = (uv - 0.5) / scale + 0.5;

    if(any(lessThan(tuv, vec2(0.0))) || any(greaterThan(tuv, vec2(1.0)))){
        fragColor = vec4(1.0);
        return;
    }

    float sd = texture(uSdf, tuv).r - 0.5;
    float w = fwidth(sd) * 1.25;
    float a = 1.0 - clamp(sd / w + 0.5, 0.0, 1.0);
    fragColor = vec4(mix(bg, fg, a), 1.0);
}

