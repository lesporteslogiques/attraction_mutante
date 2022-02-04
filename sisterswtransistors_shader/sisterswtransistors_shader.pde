/*
 Effet inspiré du documentaire "Sisters with Transistors"
 Gweltaz Duval-Guennoc (gwel@ik.me)
 
 La Baleine, Quimper, Dour Ru, 20220201
 Processing 4.0b2 @ kirin / Debian Stretch 9.5
 Son "Camera Shutter" par Roachpowder : https://freesound.org/people/roachpowder/sounds/170229/
 Icone "cloud upload" par Github : https://github.com/github/octicons
 
 Entrées : webcam, micro, bouton (connexion USB-Série avec un arduino)
 
 Affichage/masquage de 5 paramètres normalisés en appuyant sur espace
 
 L'image est inversée dans un buffer graphique (cam_inverse)
 C'est ce buffer qu'il faut travailler!
 
 /!\ indiquer la clé d'API imgbb (ligne ~52) String imgbb_api_key = "************************";
 
 */

// Config *************************************
boolean UPLOAD_ON = true; // false pour annuler l'envoi des images sur le web
boolean ARDUINO_ON = false;  // true si le l'interface bouton (par arduino) est relié

// Paramètres *********************************
import controlP5.*;
ControlP5 cp5;
float param1, param2, param3, param4, param5;
boolean display_param = true;

// Pour l'entrée micro ************************
import processing.sound.*;
AudioIn micro;
Amplitude volume;
float niveau_sonore;
// Et jouer un son
SoundFile son_camera;

// Pour la connexion série avec arduino *******
import processing.serial.*;
Serial arduino;
boolean bascule_bouton = true;

// Pour la webcam *****************************
import processing.video.*;
Capture cam;
//PImage cam_inverse;
PGraphics cam_inverse;

// Pour l'upload ******************************
import java.io.*;
import java.net.HttpURLConnection;
import java.net.URLEncoder;
import java.net.URL;
import java.util.Base64;
String imgbb_api_key;
String imgbb_url = "https://api.imgbb.com/1/upload";
boolean upload_pending = false;
PImage upload_en_cours;
float upload_started;

// Pour la sauvegarde des fichiers *************
import java.util.Date;
import java.text.SimpleDateFormat;
String SKETCH_NAME = getClass().getSimpleName();


import java.util.Map;
import java.util.function.Function;


Group g;

PShader shader;
PShader postproc;
PGraphics pg;

HashMap<String, Function<Float, Float>> step_functions = new HashMap<>();
Function<Float, Float> gradient_step_function;

HashMap<String, color[]> gradients;
color[] gradient;
float icol = 0f;


void setup() {
  //size(800, 600, P3D);
  size(1280, 600, P3D);
  //fullScreen(P3D);
  
  imgbb_api_key = get_api_key();
  
  Sound.list();                  // Liste du hardware audio

  micro = new AudioIn(this, 0);  // Créer une entrée micro
  micro.start();                 // Démarrer l'écoute du micro
  volume = new Amplitude(this);  // Démarrer l'analyseur de volume
  volume.input(micro);           // Brancher l'entrée micro sur l'analyseur de volume

  son_camera = new SoundFile(this, "freesound-roachpowder-camera-shutter.wav");
  son_camera.play();             // Jouer un coup au démarrage pour test

  if (ARDUINO_ON) {
    printArray(Serial.list());     // Afficher sur la console la liste des ports série utilisés
    String nom_port = Serial.list()[1];  // Attention à choisir le bon port série!
    arduino = new Serial(this, nom_port, 9600);
    arduino.bufferUntil('\n');
  }

  String[] cameras = Capture.list();
  printArray(cameras);
  cam = new Capture(this, 640, 480);
  cam.start();
  cam_inverse = createGraphics(cam.width, cam.height);

  upload_en_cours = loadImage("cloud_upload.png");

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
    .setValue(5f)
    .setGroup(g)
    ;
  h += itemHeight + 2;

  cp5.addSlider("field")
    .setPosition(0, h)
    .setSize(sliderWidth, itemHeight)
    .setRange(0.0f, 10f)
    .setValue(8f)
    .setGroup(g)
    ;
  h += itemHeight + 2;

  cp5.addSlider("fieldres")
    .setPosition(0, h)
    .setSize(sliderWidth, itemHeight)
    .setRange(1f, 100f)
    .setValue(40.0f)
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
  // Captation de l'entrée micro *****************************************
  niveau_sonore = min(1.0, max(volume.analyze(), 0.1f*volume.analyze()+niveau_sonore-0.01f)); // volume.analyze() renvoie une valeur entre 0 et 1
  
  if (random(1f) < 0.001f)
    gradient(int(random(gradients.size())));
  
  int numcol = gradient.length;
  float frac = icol - floor(icol);
  color col = lerpColor(gradient[floor(icol)],
        gradient[floor(icol+1) % numcol],
        gradient_step_function.apply(frac));
  

  if (cam.available()) {
    cam.read();
    shader.set("video", cam);
  }

  shader.set("threshold", cp5.getController("threshold").getValue());
  shader.set("maskColor", red(col)/255f, green(col)/255f, blue(col)/255f);
  shader.set("diffuse", cp5.getController("diffuse").getValue());
  float vely = cp5.getController("vely").getValue() * niveau_sonore;
  vely = max(vely, 0.5);
  shader.set("vely", vely);
  float field = cp5.getController("field").getValue() * niveau_sonore;
  shader.set("field", field);
  float fieldres = cp5.getController("fieldres").getValue() * niveau_sonore;
  shader.set("fieldres", fieldres);
  postproc.set("threshold", cp5.getController("threshold").getValue());
  postproc.set("video", cam);

  updateShader();
  image(pg, 0, 0);
  
  shader(postproc);
  noStroke();
  rect(0, 0, width, height);

  resetShader();
  
  // Un délai est nécessaire pour éviter d'avoir l'icone d'upload dans l'image envoyé   
  if (upload_pending && (millis() - upload_started > 100) ) {
    if ((frameCount / 20) % 2 == 0)
      image(upload_en_cours, (width - upload_en_cours.width) / 2, (height - upload_en_cours.height) / 2);
  }

  icol += cp5.getController("color_freq").getValue();
  if (icol >= numcol)
    icol -= numcol;
}


void keyPressed() {
  if (key == ' ') display_param = !display_param;
  if (!display_param) cp5.hide();
  if (display_param) cp5.show();
  
  if (key == 'b')
    actionBouton();
}
