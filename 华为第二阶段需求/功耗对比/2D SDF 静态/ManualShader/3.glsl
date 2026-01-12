#if __VERSION__ < 300
#extension GL_OES_standard_derivatives : enable
#endif


mat2 get_rotate_mat(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat2(c, -s, s, c);
}

float opUnion(float d1, float d2) {
    return min(d1, d2);
}

float opSubtraction(float d1, float d2) {
    return max(d1, -d2);
}

float sdCircle(vec2 p, float x, float y, float r) {
    return length(p - vec2(x, y)) - r;
}

float sdArc(vec2 p, float cx, float cy, float theta_shape, float theta_rotate, float ra, float rb) {
    p -= vec2(cx, cy);
    p = get_rotate_mat(-theta_rotate) * p;
    vec2 sc = vec2(sin(theta_shape), cos(theta_shape));
    p.x = abs(p.x);
    float d = abs(length(p) - ra) - rb;
    if (sc.y * p.x > sc.x * p.y) {
        d = length(p - ra * sc) - rb;
    }
    return d;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float d = opUnion(
        opUnion(
            opUnion(
                opSubtraction(
                    sdCircle(uv, 0.000, -0.000, 0.921),
                    sdCircle(uv, -0.000, -0.000, 0.791)
                ),
                sdArc(uv, -0.001, -0.052, 1.115, 3.141, 0.459, 0.065)
            ),
            sdArc(uv, 0.301, 0.183, 1.554, 0.000, 0.160, 0.064)
        ),
        sdArc(uv, -0.301, 0.182, 1.546, 6.282, 0.160, 0.064)
    );
    float alpha = smoothstep(0.0, fwidth(d), -d);
    fragColor = vec4(mix(vec3(1.0), vec3(0.0), alpha), 1.0);
}

