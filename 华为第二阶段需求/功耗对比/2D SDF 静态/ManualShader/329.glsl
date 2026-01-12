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

float sdCapsule(in vec2 p, float cx, float cy, float half_length, float theta, float radius)
{
    p -= vec2(cx, cy);
    p = get_rotate_mat(-theta) * p;

    vec2 a = vec2(-half_length, 0.0);
    vec2 b = vec2( half_length, 0.0);

    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);

    return length(pa - ba * h) - radius;
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

    d = min(d, sdArc(uv, 0.000, 0.186, 1.581, 0.005, 0.671, 0.066));

    d = min(d, sdCapsule(uv,  0.668, -0.065, 0.099, 4.722, 0.234));
    d = min(d, sdCapsule(uv, -0.669, -0.064, 0.099, 4.699, 0.234));

    d = min(d, length(uv - vec2(0.179, -0.741)) - 0.178);

    d = max(d, -sdCapsule(uv,  0.669, -0.062, 0.104, 4.712, 0.103));
    d = max(d, -sdCapsule(uv, -0.669, -0.062, 0.104, 4.713, 0.103));

    d = min(d, sdArc(uv, 0.307, -0.410, 0.900, 2.266, 0.333, 0.063));

    d = max(d, -(length(uv - vec2(0.178, -0.741)) - 0.050));

    float w = fwidth(d);
    float alpha = smoothstep(0.0, w, -d);

    fragColor = vec4(mix(vec3(1.0), vec3(0.0), alpha), 1.0);
}
