#ifdef GL_ES
    precision highp float;
    precision highp int;
#endif


#define PROCESSING_COLOR_SHADER


//#define PI 3.141592653589793
//#define TWOPI 2.0 * PI


uniform vec2 u_resolution;
uniform vec2 mouse;
uniform bool click;
uniform sampler2D video;
uniform sampler2D scene;
uniform float threshold;
uniform vec3 maskColor;
uniform float diffuse;
uniform float vely;
uniform float field;
uniform float fieldres;


// From Lewis Lepton
// https://github.com/lewislepton/shadertutorialseries/blob/master/030_whiteNoise/030_whiteNoise.frag
float random(vec2 coord)
{
    return fract(sin(dot(coord.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}


float noise(vec2 coord) {
    vec2 i = floor(coord);
    vec2 f = fract(coord);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    // Smooth Interpolation

    // Cubic Hermine Curve.  Same as SmoothStep()
    vec2 u = f*f*(3.0-2.0*f);
    // u = smoothstep(0.,1.,f);

    // Mix 4 coorners percentages
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}


void main() {
    vec2 position = gl_FragCoord.xy / u_resolution;
    position = vec2(1.) - position;
    vec2 pixel = 1.0/u_resolution;
    vec3 color = vec3(0.);
    
    vec3 videoRgb = texture2D(video, position).rgb;
    bool inVideoMask = length(videoRgb) < threshold && all(greaterThan(videoRgb, vec3(0)));
   
    if (inVideoMask) {
        color = maskColor.rgb;
    } else {
        position = vec2(1.) - position;
        float dx = -vely;
        float dy = 0;
        if (diffuse > 0.) {
            dy = (random(position) - 0.5) * diffuse;
        }
        if (field > 0.) {
            dy += (noise(position*fieldres + mouse) - 0.5) * field;
            dx += (noise(position) - 0.5) * field;
        }
        color = texture2D(scene, position + pixel * vec2(dx, dy)).rgb;
    }
    
    gl_FragColor = vec4(color, 1.);
}
