import processing.video.*;
import processing.sound.*;

static int[] screen_size = {1024, 768};

AudioIn input;
Amplitude analyzer;

Capture cam;
PShader shader;
int scene;

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
  // Start listening to the microphone
  // Create an Audio input and grab the 1st channel
  input = new AudioIn(this, 0);
  // start the Audio Input
  input.start();
  // create a new Amplitude analyzer
  analyzer = new Amplitude(this);
  // Patch the input to an volume analyzer
  analyzer.input(input);
  //shader
  shader = loadShader("symmetry.frag");
  shader.set("u_resolution", float(width), float(height));
  noStroke();
}

void draw() {
  //capturing data
  if (cam.available() == true) {
    cam.read();
  }
  float volume = analyzer.analyze();

  //display + effects
  shader.set("u_time", millis() / 1000.0);
  shader.set("u_tex0", cam);
  shader.set("u_volume", volume);
  shader(shader);
  rect(0, 0, width, height);
}
