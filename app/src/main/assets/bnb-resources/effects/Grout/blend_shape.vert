#version 300 es

precision mediump sampler2DArray;

#define GLFX_TBN
#define GLFX_LIGHTING

layout( location = 0 ) in vec3 attrib_pos;
#ifdef GLFX_LIGHTING
layout( location = 1 ) in vec3 attrib_n;
#ifdef GLFX_TBN
layout( location = 2 ) in vec4 attrib_t;
#endif
#endif
layout( location = 3 ) in vec2 attrib_uv;
layout( location = 4 ) in uvec4 attrib_bones;
#ifndef GLFX_1_BONE
layout( location = 5 ) in vec4 attrib_weights;
#endif
#ifdef GLFX_MALI_VERTEX_ID_ATTRIB
layout( location = 6 ) in uint attrib_vertex_id;
#endif

layout(std140) uniform glfx_GLOBAL
{
    mat4 glfx_MVP;
    mat4 glfx_PROJ;
    mat4 glfx_MV;
    vec4 glfx_VIEW_Q;
};
layout(std140) uniform glfx_INSTANCES
{
    vec4 glfx_IDATA[48];
};
uniform uint glfx_CURRENT_I;
#define glfx_T_SPAWN (glfx_IDATA[glfx_CURRENT_I].x)
#define glfx_T_ANIM (glfx_IDATA[glfx_CURRENT_I].y)
#define glfx_ANIMKEY (glfx_IDATA[glfx_CURRENT_I].z)
#define glfx_IDX_OFFSET (glfx_IDATA[glfx_CURRENT_I].w)
layout(std140) uniform glfx_ACTION_UNITS
{
    vec4 glfx_AU[13];
};

uniform sampler2D glfx_BONES;

uniform sampler2DArray tex_blend_shapes;

out vec2 var_uv;
#ifdef GLFX_LIGHTING
#ifdef GLFX_TBN
out vec3 var_t;
out vec3 var_b;
#endif
out vec3 var_n;
out vec3 var_v;
#endif

mat3x4 get_bone( uint bone_idx, int y )
{
    int b = int(bone_idx)*3;
    mat3x4 m = mat3x4( 
        texelFetch( glfx_BONES, ivec2(b,y), 0 ),
        texelFetch( glfx_BONES, ivec2(b+1,y), 0 ),
        texelFetch( glfx_BONES, ivec2(b+2,y), 0 ) );
    return m;
}

mat3x4 get_transform()
{
    int y = int(glfx_ANIMKEY);
    mat3x4 m = get_bone( attrib_bones[0], y );
#ifndef GLFX_1_BONE
    if( attrib_weights[1] > 0. )
    {
        m = m*attrib_weights[0] + get_bone( attrib_bones[1], y )*attrib_weights[1];
        if( attrib_weights[2] > 0. )
        {
            m += get_bone( attrib_bones[2], y )*attrib_weights[2];
            if( attrib_weights[3] > 0. )
                m += get_bone( attrib_bones[3], y )*attrib_weights[3];
        }
    }
#endif
    return m;
}

mat3 shortest_arc_m3( vec3 from, vec3 to )
{
    vec3 a = cross( from, to );
    float c = dot( from, to );

    float t = 1./(1.+c);
    float tx = t*a.x;
    float ty = t*a.y;
    float tz = t*a.z;
    float txy = tx*a.y;
    float txz = tx*a.z;
    float tyz = ty*a.z;

    return mat3
    (
        c + tx*a.x, txy + a.z, txz - a.y,
        txy - a.z, c + ty*a.y, tyz + a.x,
        txz + a.y, tyz - a.x, c + tz*a.z
    );
}

void main()
{
    vec3 vpos = attrib_pos;
#ifdef GLFX_MALI_VERTEX_ID_ATTRIB
    int vertex_idx = int(attrib_vertex_id) - int(glfx_IDX_OFFSET);
#else
    int vertex_idx = gl_VertexID - int(glfx_IDX_OFFSET);
#endif
    ivec2 bs_p_uv = ivec2((vertex_idx&31)<<1,vertex_idx>>5);
#ifdef GLFX_LIGHTING
    vec3 vn = attrib_n;
    ivec2 bs_n_uv = ivec2(bs_p_uv.x+1,bs_p_uv.y);
#endif

    int au_size = textureSize( tex_blend_shapes, 0 ).z;
    for( int i = 0; i != au_size; ++i )
    {
        float bs_w = glfx_AU[i>>2][i&3];
        if( bs_w != 0. )
        {
            vec3 bs_p_delta = texelFetch( tex_blend_shapes, ivec3(bs_p_uv,i), 0 ).xyz*bs_w;
            vpos += bs_p_delta;
#ifdef GLFX_LIGHTING
            vec3 bs_n_delta = texelFetch( tex_blend_shapes, ivec3(bs_n_uv,i), 0 ).xyz*bs_w;
            vn += bs_n_delta;
#endif
        }
    }

    mat3x4 m = get_transform();
    vpos = vec4(vpos,1.)*m;


    gl_Position = glfx_MVP * vec4(vpos,1.);

    var_uv = attrib_uv;

#ifdef GLFX_LIGHTING
    vn = normalize(vn);
    var_n = mat3(glfx_MV)*(vn*mat3(m));
#ifdef GLFX_TBN
    vec3 vt = shortest_arc_m3(attrib_n,vn)*attrib_t.xyz;
    var_t = mat3(glfx_MV)*(vt*mat3(m));
    var_b = attrib_t.w*cross( var_n, var_t );
#endif
    var_v = (glfx_MV*vec4(vpos,1.)).xyz;
#endif
}