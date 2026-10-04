// Shifts whole pixels in a narrow ring without tinting the world or GUI.
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform vec2 surface_size;
uniform vec2 wave_center;
uniform float wave_radius;
void main() {
    vec2 pixel = v_vTexcoord * surface_size;
    vec2 delta = pixel - wave_center;
    float distance_to_center = length(delta);
    float band = 1.0 - smoothstep(0.5, 2.5, abs(distance_to_center - wave_radius));
    vec2 direction = delta / max(distance_to_center, 1.0);
    vec2 shift = floor(direction * band * 2.0 + 0.5);
    vec2 sample_uv = clamp((pixel + shift) / surface_size, vec2(0.0), vec2(1.0));
    gl_FragColor = v_vColour * texture2D(gm_BaseTexture, sample_uv);
}
