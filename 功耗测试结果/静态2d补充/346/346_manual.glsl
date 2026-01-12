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

float sdArc(vec2 p, float cx, float cy, float theta_shape, float theta_rotate, float ra, float rb)
{
    p -= vec2(cx, cy);
    p = get_rotate_mat(-theta_rotate) * p;

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

    d = min(d, sdJoint2DSphere(uv, 0.000,  0.283, 0.217, 0.000, 4.712, 0.335));
    d = min(d, sdArc           (uv, 0.000,  0.064, 1.568, 3.142, 0.563, 0.065));
    d = max(d, -sdJoint2DSphere(uv, 0.000,  0.286, 0.222, 0.000, 1.571, 0.205));
    d = min(d, sdJoint2DSphere(uv, 0.000, -0.641, 0.131, 0.000, 4.712, 0.061));

    float w = fwidth(d);
    float alpha = smoothstep(0.0, w, -d);

    fragColor = vec4(mix(vec3(1.0), vec3(0.0), alpha), 1.0);
}
