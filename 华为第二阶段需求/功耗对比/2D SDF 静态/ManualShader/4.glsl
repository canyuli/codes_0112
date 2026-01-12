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

float sdIsoscelesTriangle(vec2 p, float cx, float cy, float w, float h, float theta, float round_param) {
    p -= vec2(cx, cy);
    p = get_rotate_mat(-theta) * p;
    p.x = abs(p.x);
    vec2 b = vec2(w/2.0, -h);
    vec2 qp1 = p - b*clamp(dot(p, b)/dot(b, b), 0.0, 1.0);
    vec2 qp2 = p - b*vec2(clamp(p.x/b.x, 0.0, 1.0), 1.0);
    float s = sign(b.y);
    vec2 d = min(vec2(length(qp1), s*(b.x*p.y-p.x*b.y)),
                 vec2(length(qp2), s*(b.y - p.y)));
    float dist = -d.x * sign(d.y);
    dist -= round_param;
    return dist;
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
    float d = opSubtraction(
        opSubtraction(
            opUnion(
                opUnion(
                    sdIsoscelesTriangle(uv, 0.397, 0.456, 0.642, 0.318, 1.571, 0.133),
                    sdIsoscelesTriangle(uv, 0.399, -0.454, 0.651, 0.322, 1.571, 0.131)
                ),
                opUnion(
                    sdJoint2DSphere(uv, -0.193, -0.229, 0.382, 0.000, 2.360, 0.067),
                    sdJoint2DSphere(uv, -0.217, 0.254, 0.347, 0.000, 3.925, 0.067)
                )
            ),
            sdIsoscelesTriangle(uv, 0.400, 0.456, 0.648, 0.328, 1.566, 0.001)
        ),
        sdIsoscelesTriangle(uv, 0.398, -0.454, 0.643, 0.320, 1.568, 0.003)
    );
    float alpha = smoothstep(0.0, fwidth(d), -d);
    fragColor = vec4(mix(vec3(1.0), vec3(0.0), alpha), 1.0);
}

