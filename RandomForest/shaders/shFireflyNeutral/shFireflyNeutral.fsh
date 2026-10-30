// Retain the game's warm texture, lifting it slightly to distinguish regular fireflies from memories.
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
void main() {
    vec4 tex = texture2D(gm_BaseTexture, v_vTexcoord);
    vec3 colour = mix(tex.rgb, vec3(1.0), 0.2);
    gl_FragColor = vec4(colour * v_vColour.rgb, tex.a * v_vColour.a);
}
