#ifdef GL_ES
    precision highp float;
    precision highp int;
#endif


#define PROCESSING_COLOR_SHADER


uniform vec2 u_resolution;
uniform float u_wmargin;
uniform sampler2D u_camera;
uniform sampler2D u_displacement;
uniform float u_amp;
uniform float u_noise_detail;
uniform float u_noise_factor;
uniform float u_cam_factor;
uniform float u_color_rot;


float random(vec2 coord)
{
    return fract(sin(dot(coord.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(in vec2 coord) {
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


mat4 rotation3d(vec3 axis, float angle) {
  axis = normalize(axis);
  float s = sin(angle);
  float c = cos(angle);
  float oc = 1.0 - c;

  return mat4(
    oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
    oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
    oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
    0.0,                                0.0,                                0.0,                                1.0
  );
}

vec3 rotate(vec3 v, vec3 axis, float angle) {
	return (rotation3d(axis, angle) * vec4(v, 1.0)).xyz;
}


void main() {
    
    vec2 position = (gl_FragCoord.xy - vec2(u_wmargin, 0)) / u_resolution.xy;
    position = vec2(1.) - position;
    vec2 rnd_displacement = vec2(noise(position), noise(u_noise_detail * position.yx)) - vec2(0.5);
    vec2 pos_displacement = texture2D(u_displacement, position).rg - vec2(0.5);
    vec2 mix_displacement = u_cam_factor * pos_displacement + u_noise_factor * rnd_displacement;
    vec2 new_position = position + 0.01 * u_amp * mix_displacement;
    vec3 videoRGB = texture2D(u_camera, fract(new_position)).rgb;
    videoRGB = rotate(videoRGB, vec3(1, 1, 1), u_color_rot);
    
	gl_FragColor = vec4(videoRGB, 1.);
}
