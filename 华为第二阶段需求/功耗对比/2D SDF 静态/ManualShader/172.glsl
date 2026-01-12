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

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float d = 1000.0;

    d = min(d, length(uv) - 0.920);

    d = max(d, -(length(uv - vec2(-0.001, -0.413)) - 0.186));
    d = max(d, -(length(uv - vec2( 0.001,  0.413)) - 0.186));
    d = max(d, -(length(uv - vec2(-0.413,  0.001)) - 0.186));
    d = max(d, -(length(uv - vec2( 0.413, -0.001)) - 0.186));

    d = min(d, sdCapsule(uv, 0.385, -0.850, 0.398, 3.155, 0.066));

    float w = fwidth(d);
    float alpha = smoothstep(0.0, w, -d);

    fragColor = vec4(mix(vec3(1.0), vec3(0.0), alpha), 1.0);
}
