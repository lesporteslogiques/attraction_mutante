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
import controlP5.*;
ControlP5 cp5;
float param1, param2, param3, param4, param5;
boolean display_param = true;

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


//
// PARAMETERS
//
int REFRESH_INTERVAL = 14000;
float START_DISPLACEMENT = 0.0;
float SPEED = 0.4;
boolean INVERT_COLORS = false;


PVector[] vectorMap;
PImage source_img;
float source_x, source_y;
int index;
float amp;
int last_update;


void setup() {
  size(1024, 768);
  
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
  
  imgbb_api_key = get_api_key();
  upload_en_cours = loadImage("cloud_upload.png");
  
  vectorMap = new PVector[cam.pixels.length];
  updateDisplacementMap(vectorMap, cam);
  source_img = cam.copy();
  amp = START_DISPLACEMENT;
  last_update = millis();
  
  while (!cam.available()) {
    delay(100);
  }
  cam.read();
}


void updateDisplacementMap(PVector[] vector_map, PImage map_img) {
  map_img.loadPixels();
  float x_off, y_off;
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


void draw() {
  if (cam.available()) {
    cam.read();
    updateDisplacementMap(vectorMap, cam);
    if (millis() - last_update > REFRESH_INTERVAL) {
      source_img = cam.copy();
      source_img.loadPixels();
      last_update = millis();
      amp = START_DISPLACEMENT;
    }
  }
  
  loadPixels();
  index = 0;
  for (int j=0; j <cam.height; j++) {
    for (int i=0; i <cam.width; i++) {
      source_x = amp * vectorMap[index].x + i;
      source_y = amp * vectorMap[index].y + j;
      while (source_x < 0)
        source_x += cam.width;
      while (source_x >= cam.width)
        source_x -= cam.width;
      while (source_y < 0)
        source_y += cam.height;
      while (source_y >= cam.height)
        source_y -= cam.height;
      
      pixels[index] = source_img.pixels[cam.width*floor(source_y) + floor(source_x)];
      
      index++;
    }
  }
  updatePixels();
  if (INVERT_COLORS) filter(INVERT);
  
  amp += SPEED;
}

void mouseClicked() {
  saveFrame("pic-###.png");
}
