//adaptation of novogrammer shader -> https://www.shadertoy.com/view/ltGGRW
#version 120

#ifdef GL_ES
precision lowp float;
#endif

uniform sampler2D u_tex0;
uniform vec2 u_resolution;
uniform float u_time;

// 2d rotation matrix
mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}
vec2 rotateCoord(vec2 coord, float rotation){
    return coord * rotate2d(rotation);
}
//
vec2 hexGrid(vec2 coord,float size){
    vec2 rect = vec2(size * 3.0, sqrt(3) * size); // from https://www.redblobgames.com/grids/hexagons/
    vec2 rep = mod(coord, rect); // we subdivide the space into a grid of rect
    //then we check which is the nearest to the different grid points
    vec2 p[5];
    p[0] = rep;
    p[1] = vec2(rep.x - rect.x, rep.y);
    p[2] = vec2(rep.x, rep.y - rect.y);
    p[3] = rep - rect;
    p[4] = rep - rect * 0.5;
    int shortestIndex = 0;
    float shortestLength = length(p[0]);
    for(int i=1 ; i<5 ; ++i)
    {
        float l = length(p[i]);
            if(l < shortestLength)
            {
                shortestLength = l;
                shortestIndex = i;
            }
    }
   return p[shortestIndex];
}
//
vec2 calcCoord(vec2 coord){
    float dist = length(coord); //distance btw coord and center
    float angle = atan(coord.y,coord.x); //angle btw coord and center
    const float rad60 = radians(60.0); //convert 60° to rad, which is the angle of the 6 iso. triangles inside a hexagone
    //
    angle = mod(angle, rad60 * 2.0); //draw the first 3 faces in 120° angle -> for now, all the possible angles are btw 0° and 120°
    if(angle > rad60){
        angle = rad60 * 2.0 - angle; //draw the last 3 faces at the opposite with angle btw 120° and 60°
    }
    //
    return vec2(cos(angle),sin(angle)) * dist; //return new coord with polar coordinate
}
//color adjust from https://alaingalvan.tumblr.com/post/79864187609/glsl-color-correction-shaders
vec3 brightnessContrast(vec3 value, float brightness, float contrast){
    return (value - 0.5) * contrast + 0.5 + brightness;
}
// from https://timseverien.com/posts/2020-06-19-colour-correction-with-webgl/
vec3 adjustExposure(vec3 color, float value) {
  return (1.0 + value) * color;
}
// from  https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
vec3 adjustSaturation(vec3 color, float value) {
  const vec3 luminosityFactor = vec3(0.2126, 0.7152, 0.0722);
  vec3 grayscale = vec3(dot(color, luminosityFactor));
  return mix(grayscale, color, 1.0 + value);
}
//
void main(){
  vec2 uv = gl_FragCoord.xy;
  //kaleidoscope
  float size = 200.0 + sin(u_time * 0.01) * 100.0; //dist btw hexagone center and one of the 6 hexagone points
  float rotation = u_time * 0.01;
  vec2 center = u_resolution * 0.5;
  //comment/uncomment to see the different steps;
  vec2 texCoord = uv;
  //texCoord = uv - center; //for later rotation along a centered z axis
  //texCoord = rotateCoord(uv - center, rotation); // to rotate around Z axis -> not needed, only for extra effect
  //texCoord = hexGrid(uv, size) + center; //with "+ center" the coord(0,0) is the webcam center
  //texCoord = calcCoord(uv - center); //one hexagonal kaléidoscope centered
  //texCoord = calcCoord(hexGrid((uv), size))+ center; //kaléidoscope simple
  texCoord = rotateCoord(calcCoord(hexGrid(rotateCoord((uv - center), rotation) + center, size)), -rotation) + center; //kaleidoscope with interaction
  vec4 outc = texture2D(u_tex0, texCoord/u_resolution);
  //color adjust
  outc.rgb = brightnessContrast(outc.rgb, -0.1, 1.1);
  outc.rgb = adjustSaturation(outc.rgb, 0.25);
  gl_FragColor = outc;
}
