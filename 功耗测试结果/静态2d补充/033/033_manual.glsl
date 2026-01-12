#if __VERSION__ < 300
#extension GL_OES_standard_derivatives : enable
#endif

#define PI 3.1415926

float sdIsoscelesTrapezoid_fast(vec2 p, float wt, float wb, float h, float r)
{
    float r1 = wt * 0.5;
    float r2 = wb * 0.5;
    float hh = h * 0.5;

    p.x = abs(p.x);

    vec2 ca = vec2(max(p.x - ((p.y > 0.0) ? r1 : r2), 0.0),
                   abs(p.y) - hh);

    vec2 v = vec2(r2 - r1, -2.0 * hh);
    vec2 pb = p - vec2(r1, hh);
    vec2 cb = pb - v * clamp(dot(pb, v) / dot(v, v), 0.0, 1.0);

    float s = (cb.x < 0.0 && ca.y < 0.0) ? -1.0 : 1.0;
    return s * sqrt(min(dot(ca, ca), dot(cb, cb))) - r;
}

float sdJointLineCapsule(vec2 p, float l, float r)
{
    p.x = abs(p.x);
    return length(vec2(p.x - clamp(p.x, 0.0, l), p.y)) - r;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    float d = 1e4;
    vec2 p;

    p = uv - vec2(-0.001, -0.005);
    d = min(d, sdIsoscelesTrapezoid_fast(p, 0.812, 1.098, 1.026, 0.160));

    p = uv - vec2(0.001, -0.517);
    d = max(d, -sdJointLineCapsule(p, 0.549, 0.189));

    d = min(d, length(uv - vec2(0.519, -0.522)) - 0.084);

    float w = fwidth(d);
    float a = smoothstep(0.0, w, -d);

    fragColor = vec4(mix(vec3(1.0), vec3(0.0), a), 1.0);
}
