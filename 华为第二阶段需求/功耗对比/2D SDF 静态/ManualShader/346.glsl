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

    d = min(d, sdCapsule(uv, 0.000,  0.283, 0.217, 4.712, 0.335));
    d = min(d, sdArc           (uv, 0.000,  0.064, 1.568, 3.142, 0.563, 0.065));
    d = max(d, -sdCapsule(uv, 0.000,  0.286, 0.222, 1.571, 0.205));
    d = min(d, sdCapsule(uv, 0.000, -0.641, 0.131, 4.712, 0.061));

    float w = fwidth(d);
    float alpha = smoothstep(0.0, w, -d);

    fragColor = vec4(mix(vec3(1.0), vec3(0.0), alpha), 1.0);
}
