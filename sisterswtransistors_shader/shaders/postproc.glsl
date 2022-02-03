#ifdef GL_ES
    precision highp float;
    precision highp int;
#endif


#define PROCESSING_COLOR_SHADER


uniform vec2 u_resolution;
uniform sampler2D video;
uniform float threshold;
//uniform sampler2D gradient;


void main() {
    vec2 position = gl_FragCoord.xy / u_resolution.xy;
    position = vec2(1.) - position;
    
    vec3 videoRgb = texture2D(video, position).rgb;
    bool inVideoMask = length(videoRgb) < threshold;
    
    if (inVideoMask) {
	    gl_FragColor = vec4(0., 0., 0., 0.8);
	} else {
	    gl_FragColor = vec4(0.);
	}
}
