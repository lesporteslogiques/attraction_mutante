/*************************************************
 * Author: Gweltaz
 * Created: 2019-11
 * Last modified: 2019-12-19
 * Description: Background is fixed, displacement
 *              follows video
 **************************************************/


// Config *************************************
boolean UPLOAD_ON = true; // false pour annuler l'envoi des images sur le web

// Paramètres *********************************
/*
 import controlP5.*;
 ControlP5 cp5;
 float param1, param2, param3, param4, param5;
 boolean display_param = true;
 */

// Pour l'entrée micro ************************
import processing.sound.*;
AudioIn micro;
Amplitude volume;
boolean lissage = false;
float facteur_de_lissage = 0.25;
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


//
// PARAMETERS
//
int REFRESH_INTERVAL = 24000;
float START_DISPLACEMENT = 0.0;
float SPEED = 0.4;
boolean INVERT_COLORS = false;

PShader shader;
float rect_w, margin;

PVector[] vectorMap;
PImage displacement;
float source_x, source_y;
float amp;
int last_update;


void setup() {
  fullScreen(P3D);
  //size(1024, 768);

  Sound.list();                  // Liste du hardware audio

  micro = new AudioIn(this, 0);  // Créer une entrée micro
  micro.start();                 // Démarrer l'écoute du micro
  volume = new Amplitude(this);  // Démarrer l'analyseur de volume
  volume.input(micro);           // Brancher l'entrée micro sur l'analyseur de volume

  son_camera = new SoundFile(this, "freesound-roachpowder-camera-shutter.wav");

  printArray(Serial.list());     // Afficher sur la console la liste des ports série utilisés
  String nom_port = Serial.list()[1];  // Attention à choisir le bon port série!
  //arduino = new Serial(this, nom_port, 9600);
  //arduino.bufferUntil('\n');

  String[] cameras = Capture.list();
  printArray(cameras);
  cam = new Capture(this, 640, 480, cameras[0]);
  cam.start();

  // Permet de préserver le ratio correct lors de l'agrandissement
  float vr = float(height) / cam.height;
  rect_w = vr * cam.width;
  margin = (width-rect_w) * 0.5;


  shader = loadShader("shaders/camera_mirror.glsl");
  shader.set("u_resolution", rect_w, float(height));
  shader.set("u_wmargin", margin);


  imgbb_api_key = get_api_key();
  upload_en_cours = loadImage("cloud_upload.png");

  //vectorMap = new PVector[cam.pixels.length];
  //updateDisplacementMap(vectorMap, cam);
  //displacement = createImage(cam.width, cam.height, RGB);


  /*
  while (!cam.available()) {
   delay(100);
   }
   cam.read();*/
  shader.set("u_displacement", cam);
  shader.set("u_amp", 1f);
  amp = START_DISPLACEMENT;
  last_update = millis();
}

/*
void updateDisplacementMap(PVector[] vector_map, PImage map_img) {
 map_img.loadPixels();
 float x_off, y_off;
 int index;
 for (int j=0; j<cam.height; j++) {
 for (int i=0; i<cam.width; i++) {
 index = i + cam.width*j;
 color displacementPix = map_img.pixels[index];
 // Use red channel for horizontal displacement
 // and green channel for vertical displacement
 x_off = -0.5 + (displacementPix >> 16 & 0xFF) / 255.0;
 y_off = -0.5 + (displacementPix >> 8 & 0xFF) / 255.0;
 vector_map[index] = new PVector(x_off, y_off);
 }
 }
 }
 */


void draw() {
  if (cam.available()) {
    cam.read();
    shader.set("u_camera", cam);
    //cam.loadPixels();
    //updateDisplacementMap(vectorMap, cam);
    /*
    if (millis() - last_update > REFRESH_INTERVAL) {
     last_update = millis();
     amp = START_DISPLACEMENT;
     shader.set("u_displacement", cam);
     }*/
  }

  cam.loadPixels();
  cam.updatePixels();
  //buffer_img.loadPixels();
  int index = 0;
  for (int j = 0; j < cam.height; j++) {
    for (int i = 0; i < cam.width; i++) {
      /*source_x = amp * vectorMap[index].x + i;
       source_y = amp * vectorMap[index].y + j;
       while (source_x < 0)
       source_x += cam.width;
       while (source_x >= cam.width)
       source_x -= cam.width;
       while (source_y < 0)
       source_y += cam.height;
       while (source_y >= cam.height)
       source_y -= cam.height;*/

      //buffer_img.pixels[index] = cam.pixels[cam.width*floor(source_y) + floor(source_x)];
      index++;
    }
  }
  amp += SPEED;
  shader.set("u_amp", amp);

  background(0);
  //shader.set("u_video", buffer_img);
  shader(shader);
  // Le résultat du shader sera appliqué sur le remplissage
  // de formes nouvellement dessinées
  rect(margin, 0, rect_w, height);
  resetShader();    // Désactive le shader, permet de redessiner normalement

  // Un délai est nécessaire pour éviter d'avoir l'icone d'upload dans l'image envoyé   
  if (upload_pending && (millis() - upload_started > 100) ) {
    if ((frameCount / 20) % 2 == 0)
      image(upload_en_cours, (width - upload_en_cours.width) / 2, (height - upload_en_cours.height) / 2);
  }
}

void mouseClicked() {
  amp = START_DISPLACEMENT;
  shader.set("u_displacement", cam);
}
