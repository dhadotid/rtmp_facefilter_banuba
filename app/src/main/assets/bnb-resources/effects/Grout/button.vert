#version 300 es

precision highp sampler2DArray;

layout( location = 0 ) in vec3 attrib_pos;
layout( location = 3 ) in vec2 attrib_uv;

layout(std140) uniform glfx_GLOBAL
{
	mat4 glfx_MVP;
	mat4 glfx_PROJ;
	mat4 glfx_MV;
};
layout(std140) uniform glfx_INSTANCES
{
	vec4 glfx_IDATA[48];
};
uniform uint glfx_CURRENT_I;
#define glfx_T_SPAWN (glfx_IDATA[glfx_CURRENT_I].x)
#define glfx_T_ANIM (glfx_IDATA[glfx_CURRENT_I].y)
#define glfx_ANIMKEY (glfx_IDATA[glfx_CURRENT_I].z)

// out vec3 var_uvw;
out vec2 var_uv;

uniform sampler2DArray animation;
void main()
{
	gl_Position = vec4(attrib_pos, 1.);

	var_uv = attrib_uv;
}
