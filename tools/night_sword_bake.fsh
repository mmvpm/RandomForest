// Native offline colour substitution. Geometry and alpha remain source-exact.
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform sampler2D u_lookup;
uniform float u_count;
void main() {
    vec4 pixel = texture2D(gm_BaseTexture, v_vTexcoord);
    vec3 rgb = pixel.rgb;
    if (pixel.a > 0.0) {
        for (int i = 0; i < 256; ++i) {
            if (float(i) >= u_count) break;
            float x = (float(i) + 0.5) / 256.0;
            vec3 source = texture2D(u_lookup, vec2(x, 0.25)).rgb;
            vec3 delta = abs(pixel.rgb - source);
            if (max(delta.r, max(delta.g, delta.b)) < 0.0015) {
                rgb = texture2D(u_lookup, vec2(x, 0.75)).rgb;
                break;
            }
        }
    }
    gl_FragColor = vec4(rgb, pixel.a) * v_vColour;
}
