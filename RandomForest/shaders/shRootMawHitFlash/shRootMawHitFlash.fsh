// Preserve the current silhouette and opacity using the original Hurt flash colour.
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
void main() {
    float alpha = texture2D(gm_BaseTexture, v_vTexcoord).a * v_vColour.a;
    gl_FragColor = vec4(vec3(219.0, 221.0, 236.0) / 255.0, alpha);
}
