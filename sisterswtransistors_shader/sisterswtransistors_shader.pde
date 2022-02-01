// Gweltaz Duval-Guennoc 30-07-2021

import java.util.Map;
import java.util.function.Function;

import processing.video.*;
//import processing.serial.*;

import controlP5.*;

ControlP5 cp5;
Group g;

Capture video;

PShader shader;
PShader postproc;
PGraphics pg;
PImage maskImage;

HashMap<String, Function<Float, Float>> step_functions = new HashMap<>();
Function<Float, Float> gradient_step_function;

HashMap<String, color[]> gradients;
color[] gradient;
float icol = 0f;


void setup() {
  //size(800, 600, P3D);
  fullScreen(P3D, 1);
  surface.setResizable(true);

  video = new Capture(this, width, height);
  video.start();

  pg = createGraphics(width, height, P3D);
  pg.beginDraw();
  pg.background(0);
  pg.endDraw();

  shader = loadShader("shaders/gwt.glsl");
  shader.set("u_resolution", float(width), float(height));
  shader.set("scene", pg);

  postproc = loadShader("shaders/postproc.glsl");
  postproc.set("u_resolution", float(pg.width), float(pg.height));

  step_functions.put("sin", num -> sin(num*PI));
  step_functions.put("step", num -> (float) round(num));
  step_functions.put("smooth", num -> smoothstep(num));

  gradients = buildGradients();

  cp5 = new ControlP5(this);

  int groupWidth = 170;
  int itemHeight = 16;
  int sliderWidth = 130;
  g = cp5.addGroup("params")
    .setWidth(groupWidth)
    .setPosition(width-groupWidth-4, 14)
    .setBackgroundColor(color(0, 0, 128, 50))
    ;

  int h = 0;
  cp5.addSlider("threshold")
    .setPosition(0, h)
    .setSize(sliderWidth, itemHeight)
    .setRange(0f, 3f)
    .setValue(0.5f)
    .setGroup(g)
    ;
  h += itemHeight + 2;

  cp5.addScrollableList("gradient")
    .setPosition(0, h)
    .setBarHeight(itemHeight)
    .onEnter(toFront)
    .onLeave(close)
    .addItems(gradients.keySet().toArray(new String[0]))
    .setValue(0)
    .setGroup(g)
    .close()
    ;
  h += itemHeight + 2;

  cp5.addScrollableList("gradient_step")
    .setPosition(0, h)
    .setBarHeight(itemHeight)
    .onEnter(toFront)
    .onLeave(close)
    .addItems(step_functions.keySet().toArray(new String[0]))
    .setValue(2)
    .setGroup(g)
    .close()
    ;
  h += itemHeight + 2;

  cp5.addSlider("color_freq")
    .setPosition(0, h)
    .setSize(sliderWidth, itemHeight)
    .setRange(0f, 0.1f)
    .setValue(0.02f)
    .setGroup(g)
    ;
  h += itemHeight + 2;

  cp5.addSlider("diffuse")
    .setPosition(0, h)
    .setSize(sliderWidth, itemHeight)
    .setRange(0.0f, 10.0f)
    .setValue(0f)
    .setGroup(g)
    ;
  h += itemHeight + 2;

  cp5.addSlider("vely")
    .setPosition(0, h)
    .setSize(sliderWidth, itemHeight)
    .setRange(0.01f, 5f)
    .setValue(1f)
    .setGroup(g)
    ;
  h += itemHeight + 2;

  cp5.addSlider("field")
    .setPosition(0, h)
    .setSize(sliderWidth, itemHeight)
    .setRange(0.0f, 10f)
    .setValue(0.1f)
    .setGroup(g)
    ;
  h += itemHeight + 2;

  cp5.addSlider("fieldres")
    .setPosition(0, h)
    .setSize(sliderWidth, itemHeight)
    .setRange(1f, 100f)
    .setValue(5.0f)
    .setGroup(g)
    ;
  h += itemHeight + 2;

  g.setBackgroundHeight(h);
}


void updateShader() {
  pg.beginDraw();
  pg.noStroke();
  pg.shader(shader);
  pg.rect(0, 0, pg.width, pg.height);
  pg.endDraw();
}


void draw() {
  int numcol = gradient.length;
  float frac = icol - floor(icol);
  color col = lerpColor(gradient[floor(icol)],
        gradient[floor(icol+1) % numcol],
        gradient_step_function.apply(frac));
  
  if (mousePressed && !insideGroup(g)) {
    float x = map(mouseX, 0, width, 0, cp5.getController("fieldres").getValue());
    float y = map(mouseY, 0, height, cp5.getController("fieldres").getValue(), 0);
    shader.set("mouse", x, y);
    shader.set("click", true);
  } else {
    shader.set("click", false);
  }

  if (video.available()) {
    video.read();
    shader.set("video", video);
  }

  shader.set("threshold", cp5.getController("threshold").getValue());
  shader.set("maskColor", red(col)/255f, green(col)/255f, blue(col)/255f);
  shader.set("diffuse", cp5.getController("diffuse").getValue());
  shader.set("vely", cp5.getController("vely").getValue());
  shader.set("field", cp5.getController("field").getValue());
  shader.set("fieldres", cp5.getController("fieldres").getValue());
  postproc.set("threshold", cp5.getController("threshold").getValue());
  postproc.set("video", video);

  updateShader();
  image(pg, 0, 0);
  
  shader(postproc);
  noStroke();
  rect(0, 0, width, height);

  resetShader();

  icol += cp5.getController("color_freq").getValue();
  if (icol >= numcol)
    icol -= numcol;
}


void keyPressed() {
  if (key == 'c') {
    pg.beginDraw();
    pg.clear();
    pg.endDraw();
  } else if (key == 's') {
    String filename = "frames/gwt###.png";
    saveFrame(filename);
    println(filename + " saved");
  }
}


boolean insideGroup(Group group) {
  float x = group.getPosition()[0];
  float y = group.getPosition()[1];
  boolean isInside = false;
  if (group.isOpen()) {
    if (mouseX >= x
      && mouseX <= x + group.getWidth()
      && mouseY >= y
      && mouseY <= y + group.getBackgroundHeight())
      isInside = true;
  }
  isInside |= group.isMouseOver();

  return isInside;
}
