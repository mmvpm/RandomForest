varying vec2 pos;
varying vec4 color;
varying vec2 v_vTexcoord;

uniform vec2 u_pos;
uniform float power;
uniform float radius;
uniform float u_dir;
uniform float u_fov;
uniform int u_count;
uniform float u_step;

#define PI 3.1415926538
void main() {
	vec2 vector = pos - u_pos;
	float dist = length(vector);
	float str = 1.0 / (sqrt(dist * dist + radius * radius) - radius + 1.0 - power);
	float dir = radians(u_dir);
	float st = radians(u_step);
	float hfov = radians(u_fov) * 0.5;
	
	float factor = 0.0;
	for (int i = 0; i < 100; i++) {
		if (i >= u_count) {
			break;
		}
		dir = mod(dir, 2.0 * PI);
		if (hfov < PI) {
			float rad = atan(-vector.y, vector.x);
			float adis = abs(mod(rad + 2.0 * PI, 2.0 * PI) - dir);
			adis = min(adis, 2.0 * PI - adis);
			factor += clamp((1.0 - adis / hfov) * 5.0, 0.0, 1.0);
		} else {
			factor += 1.0;
		}
		dir += st;
	}
	str *= factor;
	
	vec3 col = str * color.rgb;
	vec4 frag = texture2D(gm_BaseTexture, v_vTexcoord);
    gl_FragColor = vec4(col, 1.0) * frag;
}
