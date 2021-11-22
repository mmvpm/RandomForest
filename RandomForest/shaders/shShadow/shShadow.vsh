attribute vec3 in_Position;                  // (x,y,z)

uniform vec2 u_pos;

const float len = 100000.0;

varying float tdis;
varying float ldis;

void main()
{
	vec2 pos = in_Position.xy;
	vec2 dis = pos - u_pos;
	float sdis = length(dis);
	if (in_Position.z > 1.0) {
		pos += dis / sdis * len;
		tdis = in_Position.z - 2.0;
		ldis = 1.0;
	} else {
		ldis = sdis / len;
		tdis = mix(0.5, in_Position.z, ldis);
	}
    vec4 object_space_pos = vec4( pos.x, pos.y, 0.0, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
}
