#if __VERSION__ < 300
#extension GL_OES_standard_derivatives : enable
#endif

#define PI 3.1415926

float sdRect(vec2 p, vec2 b, float r)
{
    vec2 d = abs(p) - b + r;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}

float sdCapsule(vec2 p, float h, float r)
{
    p.x = abs(p.x);
    p.x -= clamp(p.x, 0.0, h);
    return length(p) - r;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    float d = 1e4;
    vec2 p;

    p = uv - vec2(-0.133, 0.0);
    p = vec2(p.y, -p.x);
    d = min(d, sdRect(p, vec2(0.531, 0.829), 0.242));

    p = uv - vec2(-0.136, 0.0);
    p = vec2(p.y, -p.x);
    d = max(d, -sdRect(p, vec2(0.394, 0.700), 0.082));

    p = uv - vec2(-0.310, 0.0);
    p = vec2(p.y, -p.x);
    d = min(d, sdRect(p, vec2(0.3185, 0.451), -0.160));

    p = uv - vec2(0.876, 0.0);
    p = vec2(p.y, -p.x);
    d = min(d, sdCapsule(p, 0.165, 0.084));

    float w = fwidth(d);
    float a = smoothstep(0.0, w, -d);
    vec3 col = mix(vec3(1.0), vec3(0.0), a);

    fragColor = vec4(col, 1.0);
}
