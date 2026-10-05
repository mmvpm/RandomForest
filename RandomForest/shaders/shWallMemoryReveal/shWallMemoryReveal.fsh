// Reveals all letters together through fixed pixel grain, preserving baked alpha levels.
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform vec2 cache_size;
uniform float reveal_progress;
uniform float reveal_seed;
void main() {
    vec2 pixel = floor(v_vTexcoord * cache_size);
    float noise = fract(sin(dot(pixel, vec2(12.9898, 78.233)) + reveal_seed) * 43758.5453);
    vec4 text = texture2D(gm_BaseTexture, v_vTexcoord);
    text.a *= step(noise, reveal_progress);
    gl_FragColor = v_vColour * text;
}
