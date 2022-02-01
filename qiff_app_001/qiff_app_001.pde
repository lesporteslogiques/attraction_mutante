/*
 Squelette de code pour les applications du QIFF
 La Baleine, Quimper, Dour Ru, 20220201 / pierre@lesporteslogiques.net
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
String imgbb_api_key = "************************";
String imgbb_url = "https://api.imgbb.com/1/upload";
boolean upload_pending = false;
PImage upload_en_cours;
float upload_started;

// Pour la sauvegarde des fichiers *************
import java.util.Date;
import java.text.SimpleDateFormat;
String SKETCH_NAME = getClass().getSimpleName();

// Divers **************************************
color remplissage = color(125, 255, 125);


public void setup() {
  size(1280, 600);
  background(remplissage);

  Sound.list();                  // Liste du hardware audio

  micro = new AudioIn(this, 0);  // Créer une entrée micro
  micro.start();                 // Démarrer l'écoute du micro
  volume = new Amplitude(this);  // Démarrer l'analyseur de volume
  volume.input(micro);           // Brancher l'entrée micro sur l'analyseur de volume

  son_camera = new SoundFile(this, "freesound-roachpowder-camera-shutter.wav");
  son_camera.play();             // Jouer un coup au démarrage pour test

  printArray(Serial.list());     // Afficher sur la console la liste des ports série utilisés
  String nom_port = Serial.list()[1];  // Attention à choisir le bon port série!
  arduino = new Serial(this, nom_port, 9600);
  arduino.bufferUntil('\n');

  String[] cameras = Capture.list();
  printArray(cameras);
  cam = new Capture(this, 640, 480, cameras[0]);
  //cam = new Capture(this, 640, 480, "USB Camera-B4.09.24.1", 30); // PS Eye
  cam.start();
  cam_inverse = createGraphics(cam.width, cam.height);

  upload_en_cours = loadImage("cloud_upload.png");

  cp5 = new ControlP5(this);
  cp5.addSlider("slider1").setPosition(20, 50).setWidth(400).setValue(0.5).setRange(0, 1);
  cp5.addSlider("slider2").setPosition(20, 100).setWidth(400).setValue(0.5).setRange(0, 1);
  cp5.addSlider("slider3").setPosition(20, 150).setWidth(400).setValue(0.5).setRange(0, 1);
  cp5.addSlider("slider4").setPosition(20, 200).setWidth(400).setValue(0.5).setRange(0, 1);
  cp5.addSlider("slider5").setPosition(20, 250).setWidth(400).setValue(0.5).setRange(0, 1);
}

public void draw() {

  // Définir la couleur de fond selon l'état du bouton *******************
  if (bascule_bouton) remplissage = color(125, 255, 125);
  else remplissage = color(125, 213, 255);

  // Captation de l'entrée micro *****************************************
  if (lissage) niveau_sonore = (volume.analyze() - niveau_sonore) * facteur_de_lissage;
  else niveau_sonore = volume.analyze(); // volume.analyze() renvoie une valeur entre 0 et 1

  // Visualisation du niveau d'amplitude sonore **************************
  fill(remplissage);
  noStroke();
  rect(0, 0, width/2, height/2);

  if (frameCount%width == 0) {
    rect(0, height/2, width, height/2);
  }

  fill(255, 0, 150);
  stroke(255, 0, 150);
  text("niveau sonore : " + niveau_sonore, 20, 20);
  float diametre = map(niveau_sonore, 0, 1, 1, 500);
  ellipse(530, height * 0.25, diametre, diametre);
  ellipse(frameCount%width, height - niveau_sonore * 300, 2, 2);

  // Affichage webcam ****************************************************
  if (cam.available() == true) {

    cam.read(); // Charger en mémoire la nouvelle image de la webcam
    cam_inverse.beginDraw();
    // Inverser l'image de la webcam
    cam_inverse.pushMatrix();
    //translate(cam.width, 0);
    cam_inverse.translate(cam_inverse.width, 0);
    cam_inverse.scale(-1, 1);
    cam_inverse.image(cam, 0, 0);
    cam_inverse.popMatrix();
    cam_inverse.endDraw();
    image(cam_inverse, width/2, 0); // Afficher le buffer d'image inversée
  }
  
  // Un délai est nécessaire pour éviter d'avoir l'icone d'upload dans l'image envoyé   
  if (upload_pending && (millis() - upload_started > 100) ) {
    if ((frameCount / 16) % 2 == 0)
      image(upload_en_cours, (width - upload_en_cours.width) / 2, (height - upload_en_cours.height) / 2);
  }
}


void serialEvent (Serial myPort) {
  try {
    while (myPort.available() > 0) {
      String inBuffer = myPort.readStringUntil('\n');
      if (inBuffer != null) {
        try {
          int val = 0;
          String s = inBuffer.replace("\n", "");
          val = Integer.parseInt(s.trim());
          if (val == 1) actionBouton();
          println("valeur transmise par le port série : " + val);
        }
        catch (NumberFormatException npe) {
          // Not an integer so forget it
        }
      }
    }
  }
  catch (Exception e) {
  }
}

void actionBouton() {
  bascule_bouton = !bascule_bouton;
  son_camera.play();
  if (UPLOAD_ON) {
    if (!upload_pending) {
      println("Envoi de l'image");
      thread("uploadImage");
    }
  }
}



void uploadImage() throws IOException {
  upload_pending = true;
  upload_started = millis();

  // Enregistrer l'image dans le dossier du sketch
  Date now = new Date();
  SimpleDateFormat formater = new SimpleDateFormat("yyyyMMdd_HHmmss");
  System.out.println(formater.format(now));
  String imageBasename = SKETCH_NAME + "_" + formater.format(now);
  String imagefilename = imageBasename + ".png";
  save(imagefilename);  // Save image to disk first

  URL url = new URL(imgbb_url);
  HttpURLConnection con = (HttpURLConnection) url.openConnection();
  con.setDoOutput(true);
  con.setRequestMethod("POST");
  //con.setRequestProperty("Content-Type", "application/json");

  File imgFile = sketchFile(imagefilename);
  long fileSize = imgFile.length();
  byte[] allBytes = new byte[(int) fileSize];
  FileInputStream fis = new FileInputStream(imgFile);
  BufferedInputStream reader = new BufferedInputStream(fis);
  reader.read(allBytes);
  reader.close();

  String paramString = "key=" + imgbb_api_key + "&";
  paramString += "name=" + URLEncoder.encode(imageBasename, "UTF-8") + "&";
  paramString += "image=" + URLEncoder.encode(Base64.getEncoder().encodeToString(allBytes), "UTF-8");

  DataOutputStream out = new DataOutputStream(con.getOutputStream());
  out.writeBytes(paramString);
  out.flush();
  out.close();

  int status = con.getResponseCode();
  BufferedReader in = new BufferedReader(new InputStreamReader(con.getInputStream()));
  String inputLine;
  StringBuilder content = new StringBuilder();
  while ((inputLine = in.readLine()) != null) {
    content.append(inputLine);
  }
  in.close();
  println(content.toString());

  if (status == 200) {
    println("Uploading done");
  } else {
    println("Error uploading file");
  }
  upload_pending = false;
}

void slider1(float v) {
  param1 = v;
  println("param1 : " + param1);
}

void slider2(float v) {
  param2 = v;
  println("param2 : " + param2);
}

void slider3(float v) {
  param3 = v;
  println("param3 : " + param3);
}

void slider4(float v) {
  param4 = v;
  println("param4 : " + param4);
}

void slider5(float v) {
  param5 = v;
  println("param5 : " + param5);
}

void keyPressed() {
  if (key == ' ') display_param = !display_param;
  if (!display_param) cp5.hide();
  if (display_param) cp5.show();
}
