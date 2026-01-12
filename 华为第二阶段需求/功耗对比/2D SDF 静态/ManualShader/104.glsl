#if __VERSION__ < 300
#extension GL_OES_standard_derivatives : enable
#endif

#define PI 3.1415926

float sdArc_exact(vec2 p, float cx, float cy, float theta_shape, float theta_rotate, float ra, float rb)
{
    p -= vec2(cx, cy);

    float c = cos(-theta_rotate);
    float s = sin(-theta_rotate);
    p = vec2(c*p.x - s*p.y, s*p.x + c*p.y);

    vec2 sc = vec2(sin(theta_shape), cos(theta_shape));
    p.x = abs(p.x);

    float d = abs(length(p) - ra) - rb;
    if (sc.y * p.x > sc.x * p.y)
        d = length(p - ra * sc) - rb;

    return d;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float d = 1000.0;

    d = min(d, sdArc_exact(uv, -0.004, -0.639, 0.784, 0.004, 1.308, 0.063));
    d = min(d, sdArc_exact(uv, -0.001, -0.557, 0.885, 0.000, 0.501, 0.063));
    d = min(d, sdArc_exact(uv,  0.000, -0.514, 0.882, 6.283, 0.816, 0.064));

    d = min(d, length(uv - vec2(0.0, -0.562)) - 0.165);

    float w = fwidth(d);
    float alpha = smoothstep(0.0, w, -d);

    fragColor = vec4(mix(vec3(1.0), vec3(0.0), alpha), 1.0);
}
