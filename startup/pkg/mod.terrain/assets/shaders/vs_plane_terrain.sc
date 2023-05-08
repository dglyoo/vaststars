
$input 	a_position a_texcoord0 a_texcoord1 a_texcoord2
$output v_texcoord v_normal v_tangent v_posWS v_idx

#include <bgfx_shader.sh>
#include "common/transform.sh"

void main()
{
    mat4 wm = u_model[0];
	highp vec4 posWS = transformWS(wm, mediump vec4(a_position, 1.0));
	gl_Position = mul(u_viewProj, posWS);
	v_texcoord = vec4(a_texcoord0.xy, a_texcoord1.xy);
	v_idx = a_texcoord2.xy;
	v_normal	= mul(wm, mediump vec4(0.0, 1.0, 0.0, 0.0)).xyz;
	v_tangent	= mul(wm, mediump vec4(1.0, 0.0, 0.0, 0.0)).xyz;
	v_posWS = posWS;
	v_posWS.w = mul(u_view, v_posWS).z;
}