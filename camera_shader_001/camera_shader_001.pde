/*
  Exemple d'utilisation d'un shader pour agrandir et miroirer les
  images issues de la webcam.
  Plus rapide que d'utiliser image(cam, 0, 0 width, height) 
 */


import processing.video.*;


PShader shader;
Capture cam;
float rect_w, margin;


void setup() {
  fullScreen(P3D);
  //size(640, 480, P3D);

  cam = new Capture(this, 320, 240);
  cam.start();

  // Permet de préserver le ratio correct lors de l'agrandissement
  float vr = float(height) / cam.height;
  rect_w = vr * cam.width;
  margin = (width-rect_w) * 0.5;

  shader = loadShader("shaders/camera_mirror.glsl");
  shader.set("u_resolution", rect_w, float(height));
  shader.set("u_wmargin", margin);
}

void draw() {
  if (cam.available() == true) {
    cam.read();
    shader.set("u_video", cam);
  }
  

  background(0);
  
  shader(shader);
  // Le résultat du shader sera appliqué sur le remplissage
  // de formes nouvellement dessinées
  rect(margin, 0, rect_w, height);
  
  resetShader();    // Désactive le shader, permet de redessiner normalement
}
