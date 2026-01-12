#if __VERSION__ < 300
#extension GL_OES_standard_derivatives : enable
#endif

#define PI 3.1415926

float sdRectR(vec2 p, vec2 b, float r)
{
    vec2 d = abs(p) - b + r;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}

vec2 rot(vec2 p, float c, float s)
{
    return vec2(c*p.x - s*p.y, s*p.x + c*p.y);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    float d = 1000.0;
    vec2 p;

    {
        p = rot(uv - vec2(0.408, 0.409), -0.70710678, 0.70710678);
        d = min(d, sdRectR(p, vec2(0.3775, 0.3795), 0.241));
    }
    {
        p = rot(uv - vec2(-0.468, -0.468), 0.0, 1.0);
        d = min(d, sdRectR(p, vec2(0.378, 0.378), 0.236));
    }
    {
        p = rot(uv - vec2(0.408, -0.468), 0.0, 1.0);
        d = min(d, sdRectR(p, vec2(0.378, 0.3785), 0.238));
    }
    {
        p = rot(uv - vec2(-0.468, 0.408), -0.00159265, 0.9999987);
        d = min(d, sdRectR(p, vec2(0.3785, 0.378), 0.238));
    }

    {
        p = rot(uv - vec2(0.409, 0.408), -0.70710678, 0.70710678);
        d = max(d, -sdRectR(p, vec2(0.2465, 0.2475), 0.096));
    }
    {
        p = rot(uv - vec2(-0.468, 0.408), 0.0, 1.0);
        d = max(d, -sdRectR(p, vec2(0.247, 0.247), 0.096));
    }
    {
        p = rot(uv - vec2(-0.468, -0.468), -1.0, 0.0);
        d = max(d, -sdRectR(p, vec2(0.247, 0.247), 0.096));
    }
    {
        p = rot(uv - vec2(0.408, -0.468), -1.0, 0.0);
        d = max(d, -sdRectR(p, vec2(0.247, 0.247), 0.096));
    }

    float w = fwidth(d);
    float a = smoothstep(0.0, w, -d);

    fragColor = vec4(mix(vec3(1.0), vec3(0.0), a), 1.0);
}
