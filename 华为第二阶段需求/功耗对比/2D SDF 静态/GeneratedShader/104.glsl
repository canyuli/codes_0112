#if __VERSION__ < 300
#extension GL_OES_standard_derivatives : enable
#endif

# define PI 3.1415926

// ================== 库函数粘贴区 (Library Paste Area) ==================

// ▲▲▲▲▲ sdf_operations.glsl 内容开始 ▲▲▲▲▲
/*
================================================================================
SDF 基础操作集 (SDF Operations)
================================================================================
*/

/**
 * @brief SDF: 圆角
 */
float opRound(float dist, float r) {
    return dist - r;
}

/**
 * @brief SDF: 空心/描边
 */
float opOnion(float dist, float r) {
    return abs(dist) - r;
}

/*
================================================================================
SDF 布尔运算集 (SDF Boolean Operations)
================================================================================
*/

/**
 * @brief SDF: 并集 (Union)
 */
float opUnion(float d1, float d2) {
    return min(d1, d2);
}

/**
 * @brief SDF: 差集 (Subtraction)
 */
float opSubtraction(float d1, float d2) {
    return max(d1, -d2);
}

/**
 * @brief SDF: 交集 (Intersection)
 */
float opIntersection(float d1, float d2) {
    return max(d1, d2);
}


/*
================================================================================
SDF 平滑布尔运算 (SDF Smooth Boolean Operations)
================================================================================
*/

/**
 * @brief SDF: 平滑差集 (Smooth Subtraction)
 */
float opSmoothUnion(float d1, float d2, float k)
{
    float h = clamp(0.5 + 0.5 * (d1-d2)/k,0.0,1.0);
    return mix(d1,d2,h)-k*h*(1.0-h);
}

float opSmoothSubtraction(float d1, float d2, float k)
{
    float h = clamp(0.5 - 0.5 * (d1+d2)/k,0.0,1.0);
    return mix(d1,-d2,h)+k*h*(1.0-h);
}

float opSmoothIntersection(float d1, float d2, float k)
{
    float h = clamp(0.5 - 0.5 * (d2-d1)/k,0.0,1.0);
    return mix(d1,d2,h)-k*h*(1.0-h);
}
// ▲▲▲▲▲ sdf_operations.glsl 内容结束 ▲▲▲▲▲


// ▼▼▼▼▼ 在下方粘贴 primitives.glsl 的全部内容 ▼▼▼▼▼


/**
 * @brief 生成2D旋转矩阵
 */
mat2 get_rotate_mat(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat2(c, -s, s, c);
}

/*
================================================================================
SDF 2D基础图形库 (SDF 2D Primitives)
================================================================================
*/

/**
 * @brief SDF: 圆形
 * @param p 查询点
 * @param x,y 圆心坐标
 * @param r 半径
 */
float sdCircle(vec2 p, float x, float y, float r) {
    return length(p - vec2(x, y)) - r;
}

/**
 * @brief SDF: 圆角矩形
 * @param p 查询点
 * @param cx,cy 中心坐标
 * @param width,height 宽高
 * @param theta 旋转角度
 * @param round_param 圆角半径
 */
float sdRectangle(vec2 p, float cx, float cy, float width, float height, float theta, float round_param) {
    p -= vec2(cx, cy);
    p = get_rotate_mat(-theta) * p;
    vec2 d = abs(p) - vec2(width, height) / 2.0 + round_param;
    float sdf_rect = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
    return sdf_rect - round_param;
}


/**
 * @brief SDF: 等腰三角形 (由顶点定义)
 * @param p 查询点
 * @param cx,cy 顶点坐标
 * @param w 底边宽度
 * @param h 高度
 * @param theta 旋转角度
 * @param round_param 圆角半径
 */
float sdIsoscelesTriangle(vec2 p, float cx, float cy, float w, float h, float theta, float round_param) {
    p -= vec2(cx, cy);
    p = get_rotate_mat(-theta) * p;
    p.x = abs(p.x);
    vec2 b = vec2(w/2.0,-h);
    vec2 qp1 = p - b*clamp( dot(p,b)/dot(b,b), 0.0, 1.0 );
    vec2 qp2 = p - b*vec2( clamp( p.x/b.x, 0.0, 1.0 ), 1.0 );
    float s = sign(b.y);
    vec2 d = min(vec2(length(qp1), s*(b.x*p.y-p.x*b.y)),
                 vec2(length(qp2), s*(b.y - p.y)));

	float dist = -d.x * sign(d.y);
    dist -= round_param;
    return dist;
}

/**
 * @brief SDF: 胶囊体
 * @param p 查询点
 * @param cx,cy 中心坐标
 * @param half_length 中心线半长
 * @param theta 旋转角度
 * @param radius 胶囊体半径
 */
  float sdJoint2DSphere( in vec2 p, float cx, float cy, float half_length, float a, float theta, float w)
{
    p -= vec2(cx, cy);
    p = get_rotate_mat(-theta) * p;
    float l = half_length;
    // Line_SDF
    float d_line = length(p - vec2(clamp(p.x, -l, l),0.0));

    float eps1 = 0.01;
    a = sign(a) * max(abs(a), eps1);

    // Arc_parameters
    vec2 sc = vec2(cos(a/2.0),sin(a/2.0));
    float ra = l/a;

    // Arc_recenter
    p.y -= ra;

    // Arc_reflect
    p.x = abs(p.x);
    vec2 q = p - 2.0*sc*max(0.0,dot(sc,p));

    // Arc_distance
    float u = abs(ra)-length(q);
    float d_arc = (q.x<0.0) ? length( q+vec2(0.0,ra) ) : abs(u);

    // From -1 to 1 Smoothly passing through a = 0
    float k = smoothstep(eps1*0.9, eps1*1.1, abs(a));

    // Blend line segment and arc
    float d = mix(d_line, d_arc, k);

    return d - w;
}

/**
 * @brief SDF: 圆弧
 * @param p 查询点
 * @param cx,cy 中心坐标
 * @param theta_shape 圆弧半角
 * @param theta_rotate 旋转角度
 * @param ra 主半径
 * @param rb 描边半径/厚度
 */
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

/**
 * @brief SDF: 等腰梯形
 * @param p 查询点
 * @param cx,cy 中心坐标
 * @param w_top 上底宽度
 * @param w_bottom 下底宽度
 * @param height 高度
 * @param theta 旋转角度
 * @param round_param 圆角半径
 */
float sdIsoscelesTrapezoid(vec2 p, float cx, float cy, float w_top, float w_bottom, float height, float theta, float round_param) {
    float r1 = w_top/2., r2 = w_bottom/2., h = height/2.;
    p -= vec2(cx, cy);
    p = get_rotate_mat(-theta) * p;
    p.x = abs(p.x);
    vec2 v_top_right = vec2(r1, h);
    vec2 slant_edge_vec = vec2(r2-r1, -2.0*h);
    vec2 ca = vec2(max(p.x-((p.y>0.)?r1:r2),0.), abs(p.y)-h);
    vec2 p_minus_v_top = p - v_top_right;
    vec2 cb = p_minus_v_top - slant_edge_vec*clamp(dot(p_minus_v_top,slant_edge_vec)/dot(slant_edge_vec,slant_edge_vec),0.,1.);
    float s = (cb.x < 0.0 && ca.y < 0.0) ? -1.0 : 1.0;
    return s * sqrt(min(dot(ca, ca), dot(cb, cb))) - round_param;
}

/**
 * @brief SDF: 五角星
 * @param p 查询点
 * @param cx,cy 中心坐标
 * @param r 外接圆半径
 * @param theta 旋转角度
 * @param w 夹角
 * @param round_param 圆角半径
 * @param k 夹角圆角
 */
float sdPentagram(in vec2 p, float cx, float cy, in float r, in float theta, in float w, in float round_param, in float k)
{
    p -= vec2(cx, cy);
    p = get_rotate_mat(-theta) * p;
    // these 5 lines can be precomputed for a given shape
    float n = 5.0;
    float m = n + w*(2.0-n);

    float an = 3.1415927/n;
    float en = 3.1415927/m;
    vec2 racs = r*vec2(cos(an), sin(an));
    vec2 ecs = vec2(cos(en), sin(en)); // ecs=vec2(0,1) and simplify, for regular polygon,

    // symmetry (optional)
    p.x = abs(p.x);

    // reduce to first sector
    float bn = mod(atan(p.x, p.y), 2.0*an) - an;
    float q = abs(sin(bn));
    p = length(p)*vec2(cos(bn), q + 0.5*pow(max(k - q, 0.0), 2.0)/k);

    // line sdf
    p -= racs;
    p += ecs*clamp(-dot(p, ecs), 0.0, racs.y/ecs.y);
    return length(p)*sign(p.x) - round_param;
}
/**
 * @brief SDF: 爱心
 * @param p 查询点
 * @param x,y 顶点坐标
 * @param size 外接圆半径
 * @param theta 旋转角度
 * @param round_param 圆角半径
 */
 float sdHeart(in vec2 p, float cx, float cy, float size, float theta, float round_param)
{
    p -= vec2(cx, cy);
    p = get_rotate_mat(-theta) * p;
    // 缩放坐标
    p /= size;
    p.x = abs(p.x);

    float d;
    if (p.y + p.x > 1.0)
        d = sqrt(dot(p - vec2(0.25, 0.75), p - vec2(0.25, 0.75))) - sqrt(2.0) / 4.0;
    else
        d = sqrt(min(dot(p - vec2(0.00, 1.00), p - vec2(0.00, 1.00)),
                     dot(p - 0.5 * max(p.x + p.y, 0.0), p - 0.5 * max(p.x + p.y, 0.0))))
            * sign(p.x - p.y);

    // 把结果缩放回来
    return d * size - round_param;
}

/**
 * @brief SDF: 正六边形
 * @param p 查询点
 * @param x,y 顶点坐标
 * @param size 外接圆半径
 * @param theta 旋转角度
 * @param round_param 圆角半径
 */
float sdHexagon( in vec2 p, float cx, float cy, in float R, float theta, float round_param )
{
    // 平移 + 旋转
    p -= vec2(cx, cy);
    p = get_rotate_mat(-theta) * p;
    const vec3 k = vec3(-0.866025404, 0.5, 0.577350269);
    float a = (-k.x) * R;
    p = abs(p);
    p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
    p -= vec2(clamp(p.x, -k.z * a, k.z * a), a);

    float d = length(p) * sign(p.y);
    return d -= round_param;
}

// ▲▲▲▲▲ primitives.glsl 内容结束 ▲▲▲▲▲


// ================== 主程序 (Main Program) ==================

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // 1. 设置坐标系
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float d = 1000.0;
    float primitive_dist;
    // 2. 计算SDF距离
    // INSERT HERE
    primitive_dist=sdArc(uv,-0.004,-0.639,0.784,0.004,1.308,0.063);
    d=opUnion(d, primitive_dist);
    primitive_dist=sdArc(uv,-0.001,-0.557,0.885,0.000,0.501,0.063);
    d=opUnion(d, primitive_dist);
    primitive_dist=sdArc(uv,0.000,-0.514,0.882,6.283,0.816,0.064);
    d=opUnion(d, primitive_dist);
    primitive_dist=sdCircle(uv, -0.000,-0.562,0.165);
    d=opUnion(d, primitive_dist);
    // 3. 抗锯齿上色（基于最终 d）
    vec3 bgColor   = vec3(1.0);
    vec3 fillColor = vec3(0.0);

    float w = fwidth(d);           // 屏幕空间边缘宽度估计
    float alpha = smoothstep(0.0, w, -d); // d=0 边界，d<0 内部

    vec3 color = mix(bgColor, fillColor, alpha);

    // 4. 输出颜色
    fragColor = vec4(color, 1.0);
}
