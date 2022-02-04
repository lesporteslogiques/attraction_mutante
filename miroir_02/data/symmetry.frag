#version 120

#ifdef GL_ES
precision lowp float;
#endif

uniform sampler2D u_tex0;
uniform vec2 u_resolution;
uniform float u_time;
uniform float u_volume;

// 2d rotation matrix
mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

vec2 rotateCoord(vec2 coord, float rotation){
    coord = coord - vec2(0.5);
    return coord * rotate2d(rotation) + vec2(0.5);
}

void main(){
  vec2 uv = gl_FragCoord.xy;
  uv = u_resolution - uv; // invert axis
  uv.xy /= u_resolution; //normalize uv
  /////////////////////////////// test 1
  //mirroring
  // uv.x = 1.0 - uv.x;
  // uv = uv * 2.0 - 1.0;
  // uv = abs(uv);
  // if (uv.x < uv.y){
  //   uv.xy = uv.yx;
  // }
  // uv = rotateCoord(uv, radians(225.));
  /////////////////////////////// test 2
  // vec2 rect = vec2(0.2, 0.2);
  // if ( 0.2 < uv.y && uv.y < 0.4){
  //   uv.x += 0.1;
  // }
  // if (0.6 < uv.y && uv.y < 0.8){
  //   uv.x += 0.1;
  // }
  // vec2 mod_rect = mod(uv, rect);
  // uv = mod_rect;
  /////////////////////////////// test 3
    if (uv.y > 0.5){
         uv.y = 1.0 - uv.y;
    }
    if(uv.x < 0.5){
        uv.x = 1.0 - uv.x;
    }
  /////////////////////////////// global
  vec3 outc = texture2D(u_tex0, uv).rgb;
  gl_FragColor = vec4(outc,1.0);
}
