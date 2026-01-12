#version 330 core
out vec4 FragColor;

uniform vec2  uResolution;
uniform float iTime;
uniform sampler2D uSDF[1];

const vec3 COL_BG = vec3(1.0);
const vec3 COL_FG = vec3(0.0);

const float uFreq  = 1.5;
const float uDamp  = 3.0;
const int   uSwings = 0;

const int   uMode = 1;          // 1=Y,2=X,3=Rot
const int   uInsideWhite = 1;
const float uTransAmp = 0.1;
const float uRotAmp   = 0.0;
const vec2  uPivot    = vec2(0.5);

const int   uCompositeMode = 1;
const float uLayer = 0.0;
const float uExpand = 0.0;

float sdfAlpha(float s, float edge){
    float w = max(fwidth(s) * 0.75, 1.0 / 1024.0);
    return 1.0 - smoothstep(edge - w, edge + w, s);
}

void main(){
    vec2 frag = gl_FragCoord.xy;
    float side = min(uResolution.x, uResolution.y);
    vec2 uv = (frag - 0.5 * (uResolution - vec2(side))) / side;

    if(any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))){
        FragColor = vec4(COL_BG, 1.0);
        return;
    }

    float t = iTime;
    float off;

    if(uSwings == 0){
        off = sin(6.2831853 * uFreq * t);
    }else{
        float Tmax = float(uSwings) / max(uFreq, 1e-4);
        float tc = min(t, Tmax);
        off = exp(-uDamp * tc) * sin(6.2831853 * uFreq * tc);
    }

    if(uMode == 1){
        uv.y += uTransAmp * off;
    }else if(uMode == 2){
        uv.x += uTransAmp * off;
    }else if(uMode == 3 && uRotAmp > 0.0){
        float a = uRotAmp * off;
        float c = cos(a), s = sin(a);
        uv = uPivot + mat2(c,-s,s,c) * (uv - uPivot);
    }

    if(any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))){
        FragColor = vec4(COL_BG, 1.0);
        return;
    }

    float sdf = texture(uSDF[0], uv).r;
    if(uInsideWhite != 0) sdf = 1.0 - sdf;

    if(uCompositeMode == 0){
        float a = sdfAlpha(sdf, 0.5);
        FragColor = vec4(mix(COL_BG, COL_FG, a), 1.0);
    }else{
        float aFill  = sdfAlpha(sdf, 0.5);
        float aCover = sdfAlpha(sdf, 0.5 + uExpand);
        FragColor = vec4(mix(COL_BG, COL_FG, aCover > 0.001 ? aFill : 0.0), 1.0);
    }
}
