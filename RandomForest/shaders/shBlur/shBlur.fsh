//
// Simple passthrough fragment shader
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec3 size; // width,height,radius
uniform int kSize; // kernel size
uniform float std;
uniform vec4 b_color;
uniform float b_part;

const float PI_2 = 6.28318530718;

float gauss(vec2 rad) {
	vec2 rad2 = rad * rad;
	float norm2 = rad2.x + rad2.y;
	return exp(-norm2 / (2.0 * std * std)) / (std * sqrt(PI_2));
}

void main() {
    vec2 dir = size.z / size.xy;
    vec4 color = vec4(0.0);
	
	vec2 startDir = -0.5 * dir * float(kSize - 1);
	float sum = 0.0;
	for (int i = 0; i < kSize; i++) {
		for (int j = 0; j < kSize; j++) {
			vec2 vector = startDir + dir * vec2(float(i), float(j));
			float w = gauss(vector);
			sum += w;
			color += w * texture2D(gm_BaseTexture, v_vTexcoord + vector);
		}
	}
 	color /= sum;
	color = (1.0 - b_part) * color + b_part * b_color;
    gl_FragColor = color * v_vColour;
}
