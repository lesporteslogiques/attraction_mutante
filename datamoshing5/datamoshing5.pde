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

// Pour l'entrée micro ************************
import processing.sound.*;
AudioIn micro;
Amplitude volume;
boolean lissage = false;
float facteur_de_lissage = 0.25;
float niveau_sonore;

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
String imgbb_url = "https://api.imgbb.com/1/upload";

// Pour la sauvegarde des fichiers *************
import java.util.Date;
import java.text.SimpleDateFormat;
String SKETCH_NAME = getClass().getSimpleName();


//
// PARAMETERS
//
int REFRESH_INTERVAL = 24000;
float START_DISPLACEMENT = 0.0;
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


  /*
  while (!cam.available()) {
   delay(100);
   }
   cam.read();*/
  shader.set("u_displacement", cam);
  shader.set("u_amp", 1f);
  amp = START_DISPLACEMENT;
  last_update = millis();

  buildUI();
}


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
  
  amp += speed;
  
  shader.set("u_amp", amp);
  shader.set("u_noise_detail", noise_detail);
  shader.set("u_cam_factor", cam_factor);
  shader.set("u_noise_factor", noise_factor);

  background(0);
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
