#if __VERSION__ < 300
#extension GL_OES_standard_derivatives : enable
#endif

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float d = 1000.0;

    {
        vec2 p = uv + vec2(0.002, 0.001);
        d = min(d, length(p) - 0.724);
    }
    {
        vec2 p = uv + vec2(0.001, 0.001);
        d = max(d, -(length(p) - 0.595));
    }
    {
        vec2 p = uv;
        d = min(d, length(p) - 0.332);
    }

    {
        vec2 p = uv - vec2(0.751, 0.002);
        float c = cos(3.149), s = sin(3.149);
        p = vec2(c*p.x - s*p.y, s*p.x + c*p.y);
        float l = 0.086;
        float d_line = length(p - vec2(clamp(p.x, -l, l), 0.0));
        float ra = l / 0.01;
        p.y -= ra;
        p.x = abs(p.x);
        vec2 sc = vec2(cos(0.005), sin(0.005));
        vec2 q = p - 2.0 * sc * max(0.0, dot(sc, p));
        float u = abs(ra) - length(q);
        float d_arc = (q.x < 0.0) ? length(q + vec2(0.0, ra)) : abs(u);
        d = min(d, mix(d_line, d_arc, 0.0) - 0.063);
    }

    {
        vec2 p = uv - vec2(0.002, -0.752);
        float c = cos(4.720), s = sin(4.720);
        p = vec2(c*p.x - s*p.y, s*p.x + c*p.y);
        float l = 0.084;
        float d_line = length(p - vec2(clamp(p.x, -l, l), 0.0));
        float ra = l / 0.01;
        p.y -= ra;
        p.x = abs(p.x);
        vec2 sc = vec2(cos(0.005), sin(0.005));
        vec2 q = p - 2.0 * sc * max(0.0, dot(sc, p));
        float u = abs(ra) - length(q);
        float d_arc = (q.x < 0.0) ? length(q + vec2(0.0, ra)) : abs(u);
        d = min(d, mix(d_line, d_arc, 0.0) - 0.063);
    }

    {
        vec2 p = uv - vec2(-0.001, 0.751);
        float c = cos(4.718), s = sin(4.718);
        p = vec2(c*p.x - s*p.y, s*p.x + c*p.y);
        float l = 0.086;
        float d_line = length(p - vec2(clamp(p.x, -l, l), 0.0));
        float ra = l / 0.01;
        p.y -= ra;
        p.x = abs(p.x);
        vec2 sc = vec2(cos(0.005), sin(0.005));
        vec2 q = p - 2.0 * sc * max(0.0, dot(sc, p));
        float u = abs(ra) - length(q);
        float d_arc = (q.x < 0.0) ? length(q + vec2(0.0, ra)) : abs(u);
        d = min(d, mix(d_line, d_arc, 0.0) - 0.063);
    }

    {
        vec2 p = uv - vec2(-0.752, -0.001);
        float c = cos(3.144), s = sin(3.144);
        p = vec2(c*p.x - s*p.y, s*p.x + c*p.y);
        float l = 0.084;
        float d_line = length(p - vec2(clamp(p.x, -l, l), 0.0));
        float ra = l / 0.01;
        p.y -= ra;
        p.x = abs(p.x);
        vec2 sc = vec2(cos(0.005), sin(0.005));
        vec2 q = p - 2.0 * sc * max(0.0, dot(sc, p));
        float u = abs(ra) - length(q);
        float d_arc = (q.x < 0.0) ? length(q + vec2(0.0, ra)) : abs(u);
        d = min(d, mix(d_line, d_arc, 0.0) - 0.064);
    }

    float w = fwidth(d);
    float a = smoothstep(0.0, w, -d);
    fragColor = vec4(vec3(1.0 - a), 1.0);
}
