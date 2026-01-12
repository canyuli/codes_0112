#version 330 core
out vec4 FragColor;

uniform vec2  uResolution;
uniform float iTime;
uniform sampler2D uSDF[1];

const vec3 COL_BG = vec3(1.0);
const vec3 COL_FG = vec3(0.0);

void main()
{
    vec2 frag = gl_FragCoord.xy;
    vec2 res  = uResolution;

    float side = min(res.x, res.y);
    vec2 uv = (frag - 0.5 * (res - side)) / side;

    if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) {
        FragColor = vec4(COL_BG, 1.0);
        return;
    }

    float ang = -3.141592653589793 * iTime;
    float c = cos(ang), s = sin(ang);

    vec2 p = uv - vec2(0.5);
    p = mat2(c, -s, s, c) * p + vec2(0.5);

    vec2 fw = fwidth(p);
    float inRect =
        smoothstep(0.0, fw.x, p.x) * smoothstep(0.0, fw.x, 1.0 - p.x) *
        smoothstep(0.0, fw.y, p.y) * smoothstep(0.0, fw.y, 1.0 - p.y);

    float sdf = 1.0 - texture(uSDF[0], clamp(p, 0.0, 1.0)).r;

    float w = max(fwidth(sdf) * 0.75, 1.0 / 1024.0);
    float a = (1.0 - smoothstep(0.5 - w, 0.5 + w, sdf)) * inRect;

    vec3 col = mix(COL_BG, COL_FG, a);
    FragColor = vec4(col, 1.0);
}
