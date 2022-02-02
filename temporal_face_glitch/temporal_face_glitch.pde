/*
  Gweltaz DG
 2022-02-01
 
 */

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


import gab.opencv.*;
import java.awt.Rectangle;
import processing.video.*;


OpenCV opencv;
Rectangle[] faces;

PShader shader;


final int NUM_RECORDS = 16;
final int SEGMENT_MAX_FRAMES = 30;
final int NFRAMES_BEFORE_REC = 12;
ArrayList<PImage[]> recorded_segments = new ArrayList<>();

PImage[] playing_segment;
PImage[] record = new PImage[SEGMENT_MAX_FRAMES];
int num_frame = 0;

int delay = NFRAMES_BEFORE_REC;
float rect_w;
float margin;

boolean DEBUG = true;
color led_color;


void setup() {
  fullScreen(P3D);
  //size(640, 480, P3D);

  cam = new Capture(this, 640, 480);
  cam.start();

  opencv = new OpenCV(this, cam.width, cam.height);
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);

  float vr = float(height) / cam.height;
  rect_w = vr * cam.width;
  margin = (width-rect_w) * 0.5;

  shader = loadShader("shaders/camera_mirror.glsl");
  shader.set("u_resolution", rect_w, float(height));
  shader.set("u_wmargin", margin);

  textSize(24);
  noStroke();

  println(opencv.version());
  System.out.println("Maximum memory (Mo) " + Runtime.getRuntime().maxMemory()/1000000);
}

void draw() {
  if (cam.available() == true) {
    cam.read();
    opencv.loadImage(cam);
    opencv.blur(1);
    faces = opencv.detect();
  }

  if (faces != null && faces.length > 0) {
    led_color = color(0, 255, 0, 255);
    // Face detected on camera !
    if (delay <= 0) {

      if (playing_segment != null && num_frame < playing_segment.length) {
        //set(0, 0, playing_segment[num_frame]);
        shader.set("scene", playing_segment[num_frame]);
      } else {
        //set(0, 0, cam);
        shader.set("scene", cam);
      }

      if (num_frame < SEGMENT_MAX_FRAMES) {
        record[num_frame] = cam.copy();
        num_frame += 1;
        led_color = color(255, 0, 0, 255);
      } else {
        // Glitch randomly
        if (!recorded_segments.isEmpty() && random(1) < 0.05) {
          println("glitch");
          int n = int(random(recorded_segments.size()));
          PImage[] seg = recorded_segments.get(n);
          int f = int(random(seg.length));
          //set(0, 0, seg[f]);
          shader.set("scene", seg[f]);
        }
      }
    } else {
      //set(0, 0, cam);
      shader.set("scene", cam);
      delay -= 1;
    }
  } else {
    led_color = color(0, 0, 0, 0);
    // Reset pre-rec delay
    delay = NFRAMES_BEFORE_REC;

    if (num_frame > 0) {
      // Store recording
      PImage[] face_recording = new PImage[num_frame];
      for (int i=0; i<num_frame; i++)
        face_recording[i] = record[i];

      if (recorded_segments.size() >= NUM_RECORDS)
        recorded_segments.remove(0);

      recorded_segments.add(face_recording);

      int n = int(random(recorded_segments.size()));
      playing_segment = recorded_segments.get(n);

      num_frame = 0;
    }
    //set(0, 0, cam);
    shader.set("scene", cam);
  }

  background(0);
  shader(shader);
  rect(margin, 0, rect_w, height);
  resetShader();

  if (DEBUG) {
    fill(led_color);
    //noStroke();
    circle(width-20, 20, 32);
    fill(255);
    text(recorded_segments.size(), width-25, 55);
  }
}

void mouseClicked() {
}
