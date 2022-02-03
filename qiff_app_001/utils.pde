SoundFile son_camera;

void buildUI() {
  son_camera = new SoundFile(this, "freesound-roachpowder-camera-shutter.wav");
  son_camera.play();             // Jouer un coup au démarrage pour test
  
  upload_en_cours = loadImage("cloud_upload.png");
  
  cp5 = new ControlP5(this);
  cp5.addSlider("slider1").setPosition(20, 50).setWidth(400).setValue(0.5).setRange(0, 1);
  cp5.addSlider("slider2").setPosition(20, 100).setWidth(400).setValue(0.5).setRange(0, 1);
  cp5.addSlider("slider3").setPosition(20, 150).setWidth(400).setValue(0.5).setRange(0, 1);
  cp5.addSlider("slider4").setPosition(20, 200).setWidth(400).setValue(0.5).setRange(0, 1);
  cp5.addSlider("slider5").setPosition(20, 250).setWidth(400).setValue(0.5).setRange(0, 1);
}



float param1, param2, param3, param4, param5;

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
  if (UPLOAD_ON) {
    if (!upload_pending) {
      println("Envoi de l'image");
      
      // Enregistrer l'image dans le dossier du sketch
      Date now = new Date();
      SimpleDateFormat formater = new SimpleDateFormat("yyyyMMdd_HHmmss");
      System.out.println(formater.format(now));
      imageBasename = SKETCH_NAME + "_" + formater.format(now);
      imagefilename = imageBasename + ".png";
      save(imagefilename);
      
      thread("uploadImage");
    }
  }
}



boolean upload_pending = false;
PImage upload_en_cours;
float upload_started;

void uploadImage() {
  upload_pending = true;
  upload_started = millis();
  int status = 0;

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
    //paramString += "image=" + URLEncoder.encode(Base64.getEncoder().encodeToString(allBytes), "UTF-8");

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
