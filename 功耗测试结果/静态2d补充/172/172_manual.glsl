#if __VERSION__ < 300
#extension GL_OES_standard_derivatives : enable
#endif

#define PI 3.1415926

mat2 get_rotate_mat(float theta)
{
    float c = cos(theta);
    float s = sin(theta);
    return mat2(c, -s, s, c);
}

float sdJoint2DSphere(vec2 p, float cx, float cy, float half_length, float a, float theta, float w)
{
    p -= vec2(cx, cy);
    p = get_rotate_mat(-theta) * p;

    float l = half_length;
    float d_line = length(p - vec2(clamp(p.x, -l, l), 0.0));

    float eps1 = 0.01;
    a = sign(a) * max(abs(a), eps1);

    vec2 sc = vec2(cos(a * 0.5), sin(a * 0.5));
    float ra = l / a;

    p.y -= ra;
    p.x = abs(p.x);

    vec2 q = p - 2.0 * sc * max(0.0, dot(sc, p));

    float u = abs(ra) - length(q);
    float d_arc = (q.x < 0.0) ? length(q + vec2(0.0, ra)) : abs(u);

    float k = smoothstep(eps1 * 0.9, eps1 * 1.1, abs(a));
    float d = mix(d_line, d_arc, k);

    return d - w;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float d = 1000.0;

    d = min(d, length(uv) - 0.920);

    d = max(d, -(length(uv - vec2(-0.001, -0.413)) - 0.186));
    d = max(d, -(length(uv - vec2( 0.001,  0.413)) - 0.186));
    d = max(d, -(length(uv - vec2(-0.413,  0.001)) - 0.186));
    d = max(d, -(length(uv - vec2( 0.413, -0.001)) - 0.186));

    d = min(d, sdJoint2DSphere(uv, 0.385, -0.850, 0.398, 0.000, 3.155, 0.066));

    float w = fwidth(d);
    float alpha = smoothstep(0.0, w, -d);

    fragColor = vec4(mix(vec3(1.0), vec3(0.0), alpha), 1.0);
}
