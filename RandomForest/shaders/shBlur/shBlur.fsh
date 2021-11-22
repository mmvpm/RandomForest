//
// Simple passthrough fragment shader
//
varying vec2 v_vTexcoord;

uniform vec3 size; // width,height,radius
uniform int kSize; // kernel size
uniform vec2 direction;
uniform float std;
uniform vec3 b_color;
uniform float b_part;

void main() {
    vec2 dir = direction * (size.z / size.xy);
	vec4 color = vec4(0.0);
	
	float sum = 0.0;
	for (int i = -kSize; i <= kSize; i++) {
		vec2 vector = float(i) * dir;
		float w = exp(-float(i*i)/(std*std));
		sum += w;
		color += w * texture2D(gm_BaseTexture, v_vTexcoord + vector);
	}
 	color /= sum;
	color = vec4((1.0 - b_part) * color.rgb + b_part * b_color, color.a);
    gl_FragColor = color;
}
