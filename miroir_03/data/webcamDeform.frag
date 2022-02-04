#version 120

#ifdef GL_ES
precision lowp float;
#endif

uniform sampler2D u_tex0;
uniform vec2 u_resolution;
uniform float u_time;
uniform float u_amplitude;

float power = 0.2;
float speed = 4.0;
float freq = 5.0;

//effect using polar coord (round shape)
vec2 wave(vec2 p, float amplitude, float speed){
    float theta  = atan(p.y, p.x);
    float radius = length(p);
    //radius = pow(radius, sin(radius + u_time) * 0.5 + 1.0); //test
    power += u_amplitude; //sound reaction
    float exposant = power * sin(radius * freq - speed * u_time) * 0.5 + 1.0; // "-speed" -> wave from center || "+speed" -> wave to center
    radius = pow(radius, exposant); //pow function : https://thebookofshaders.com/glossary/?search=pow // test with y = pow(x, 1.0 * sin(x * 5.0 - u_time) * 0.5 + 1.0);
    p = vec2(cos(theta), sin(theta)) * radius; //polar coord
    return 0.5 * (p + 1.0); //remap uv from (-1., 1.) to (0., 1.)
}

void main(){
  vec2 centered_uv = 2.0 * gl_FragCoord.xy/u_resolution.xy - 1.0; //chging origin_base(0,0) to screen center -> screen space in range (-1.0, 1.0)
  vec2 uv; //new uv
  float d = length(centered_uv); //distance au centre de l'écran
  if (d < 1.0){ // reduce wave repetition to reduce motion sickness || at radius == 1 there is no deformation
    uv = wave(centered_uv, power, speed);
  }
  else  {
    uv = gl_FragCoord.xy/u_resolution.xy;
  }
  uv = vec2(1.0) - uv; //mirror mode
  vec4 outc = texture2D(u_tex0, uv);
  gl_FragColor = outc;
}
