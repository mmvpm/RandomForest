varying float tdis;
varying float ldis;

void main()
{
	float str = (1.0 - abs(tdis - 0.5) * 2.0 / ldis) * 5.0;
    gl_FragColor = vec4(str);
}
