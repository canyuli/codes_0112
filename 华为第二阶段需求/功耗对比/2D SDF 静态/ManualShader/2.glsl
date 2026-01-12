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

float sdJoint2DSphere(in vec2 p, float cx, float cy, float half_length, float a, float theta, float w) {
    p -= vec2(cx, cy);
    p = get_rotate_mat(-theta) * p;
    float l = half_length;
    float d_line = length(p - vec2(clamp(p.x, -l, l), 0.0));
    float eps1 = 0.01;
    a = sign(a) * max(abs(a), eps1);
    vec2 sc = vec2(cos(a/2.0), sin(a/2.0));
    float ra = l/a;
    p.y -= ra;
    p.x = abs(p.x);
    vec2 q = p - 2.0*sc*max(0.0, dot(sc, p));
    float u = abs(ra) - length(q);
    float d_arc = (q.x < 0.0) ? length(q + vec2(0.0, ra)) : abs(u);
    float k = smoothstep(eps1*0.9, eps1*1.1, abs(a));
    float d = mix(d_line, d_arc, k);
    return d - w;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float d = opUnion(
        opUnion(
            opUnion(
                opSubtraction(
                    sdCircle(uv, -0.000, 0.000, 0.921),
                    sdCircle(uv, -0.000, 0.000, 0.791)
                ),
                sdJoint2DSphere(uv, -0.005, 0.017, 0.446, 0.000, 4.713, 0.067)
            ),
            sdJoint2DSphere(uv, -0.244, 0.245, 0.297, 0.000, 2.360, 0.065)
        ),
        sdJoint2DSphere(uv, 0.229, 0.245, 0.295, 0.000, 3.928, 0.065)
    );
    float alpha = smoothstep(0.0, fwidth(d), -d);
    fragColor = vec4(mix(vec3(1.0), vec3(0.0), alpha), 1.0);
}

