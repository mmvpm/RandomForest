varying vec2 pos;
varying vec4 color;
varying vec2 v_vTexcoord;

uniform vec2 u_pos;
uniform float power;
uniform float radius;

void main()
{
	vec2 vector = pos - u_pos;
	float dist = length(vector);
	float str = 1.0 / (sqrt(dist * dist + radius * radius) - radius + 1.0 - power);
	vec3 col = str * color.rgb;
	
	vec4 frag = texture2D(gm_BaseTexture, v_vTexcoord);
    gl_FragColor = vec4(col, 1.0) * frag;
}
