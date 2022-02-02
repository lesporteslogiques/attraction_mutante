#ifdef GL_ES
    precision highp float;
    precision highp int;
#endif


#define PROCESSING_COLOR_SHADER


uniform vec2 u_resolution;
uniform float u_wmargin;
uniform sampler2D u_video;



void main() {
    
    vec2 position = (gl_FragCoord.xy - vec2(u_wmargin, 0)) / u_resolution.xy;
    position = vec2(1.) - position;
    
    vec3 sceneRgb = texture2D(u_video, position).rgb;
    
	gl_FragColor = vec4(sceneRgb, 1.);
}
