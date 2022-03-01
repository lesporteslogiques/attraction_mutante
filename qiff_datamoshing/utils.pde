SoundFile son_camera;

void buildUI() {
  son_camera = new SoundFile(this, "freesound-roachpowder-camera-shutter.wav");
  son_camera.play();             // Jouer un coup au démarrage pour test
  
  upload_en_cours = loadImage("cloud_upload.png");
  
  cp5 = new ControlP5(this);
  //cp5.addSlider("speed").setPosition(20, 50).setWidth(400).setValue(0.5).setRange(-10, 10);
  //cp5.addSlider("cam_factor").setPosition(20, 150).setWidth(400).setValue(0.5).setRange(0, 1);
  //cp5.addSlider("noise_factor").setPosition(20, 200).setWidth(400).setValue(0.5).setRange(0, 1);
  //cp5.addSlider("noise_detail").setPosition(20, 100).setWidth(400).setValue(0.5).setRange(0, 10);
  //cp5.addSlider("color_rot").setPosition(20, 250).setWidth(400).setValue(0).setRange(-PI, PI);
}

/*
void speed(float v) {
  speed = v;
  println("speed : " + speed);
}*/

/*
void noise_detail(float v) {
  noise_detail = v;
  println("noise_detail : " + noise_detail);
}*/

/*
void cam_factor(float v) {
  cam_factor = v;
  println("cam_factor : " + cam_factor);
}*/

/*
void noise_factor(float v) {
  noise_factor = v;
  println("noise_factor : " + noise_factor);
}*/

/*
void color_rot(float v) {
  color_rot = v;
  println("color_rot : " + color_rot);
}*/




boolean display_param = true;

void keyPressed() {
  if (key == ' ') display_param = !display_param;
  if (!display_param) cp5.hide();
  if (display_param) cp5.show();
  
  if (key == 'b')
    actionBouton();
}



String imgbb_api_key;

String get_api_key() {
  String[] lines = loadStrings("api.txt");
  return lines[0];
}



String imageBasename;
String imagefilename;

void actionBouton() {
  bascule_bouton = !bascule_bouton;
  son_camera.play();
  saveandupload = true;
}



boolean upload_pending = false;
PImage upload_en_cours;
float upload_started;

void uploadImage() {
  upload_pending = true;
  upload_started = millis();
  int status = 0;
  delay(1000);

  try {
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

    status = con.getResponseCode();
    BufferedReader in = new BufferedReader(new InputStreamReader(con.getInputStream()));
    String inputLine;
    StringBuilder content = new StringBuilder();
    while ((inputLine = in.readLine()) != null) {
      content.append(inputLine);
    }
    in.close();
    println(content.toString());
  }
  catch (IOException ex) {
    if (status == 200) {
      println("Uploading done");
    } else {
      println("Error uploading file");
    }
  }
  upload_pending = false;
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

void rotationBufferMogrify(int orientation, String imagefilename) {

  if (orientation == 1) {
    Process p = exec("/usr/bin/mogrify", "-rotate", "270", sketchPath(imagefilename));
    try {
      int result = p.waitFor();
      println("the process returned " + result);
    }
    catch (InterruptedException e) {
    }
  } else if (orientation == 2) {
    Process p = exec("/usr/bin/mogrify", "-rotate", "90", sketchPath(imagefilename));
    try {
      int result = p.waitFor();
      println("the process returned " + result);
    }
    catch (InterruptedException e) {
    }
  } else if (orientation == 3) {
    Process p = exec("/usr/bin/mogrify", "-rotate", "180", sketchPath(imagefilename));
    try {
      int result = p.waitFor();
      println("the process returned " + result);
    }
    catch (InterruptedException e) {
    }
  }
}
