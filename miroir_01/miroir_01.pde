import processing.video.*;
import processing.sound.*;

static int[] screen_size = {1024, 768};

AudioIn input;
Amplitude analyzer;
float volume_threshold = 0.2;
float extra_time = 0.0;

Capture cam;
PShader shader;

void settings() {
  size(screen_size[0], screen_size[1], P2D);
}

void setup() {
  //capture cam setup
  cam = new Capture(this, "pipeline:autovideosrc");
  String[] cameras = Capture.list();
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
    cam = new Capture(this, 640, 360, cameras[0]);
    cam.start();
  }  
  //mic setup
  input = new AudioIn(this, 0);
  input.start();
  analyzer = new Amplitude(this);
  analyzer.input(input);
  //shader
  shader = loadShader("kaleido.frag");
  shader.set("u_resolution", float(width), float(height));
  noStroke();
}

void draw() {
  //data capture
  if (cam.available()) {
    cam.read();
  }
  float volume = analyzer.analyze();
  volume = max(volume, volume_threshold) - volume_threshold;
  float timer = millis() / 1000.0;
  extra_time += volume * 10.0;
  timer += extra_time;
  //display + effect
  shader.set("u_time", timer);
  shader.set("u_tex0", cam);
  shader(shader);
  rect(0, 0, width, height);
}

void keyPressed(){
  if (key == CODED) {
    if (keyCode == UP) {
      volume_threshold = min(1.0, volume_threshold + 0.01);
    } else if (keyCode == DOWN) {
      volume_threshold = max(0.0, volume_threshold - 0.01);;
    } 
  }
  print("seuil = " + volume_threshold + " ; ");
}
