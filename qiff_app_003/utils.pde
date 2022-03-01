
String get_api_key() {
  String[] lines = loadStrings("api.txt");
  return lines[0];
}

boolean api_key_exists() {
  File f = sketchFile("api.txt");
  // String filePath = f.getPath();
  boolean exist = f.isFile();
  if (exist) return true;
  else return false;
}



void actionBouton() {
  println("action bouton");
  bascule_bouton = !bascule_bouton;
  son_camera.play();
  
  // Pivoter l'image
  PGraphics ir = rotationBuffer(1);
  
  // Enregistrer l'image dans le dossier du sketch
  Date now = new Date();
  SimpleDateFormat formater = new SimpleDateFormat("yyyyMMdd_HHmmss");
  System.out.println(formater.format(now));
  imageBasename = SKETCH_NAME + "_" + formater.format(now);
  imagefilename = imageBasename + ".png";
  ir.save(imagefilename);
  
  
  if (UPLOAD_ON) {
    if (!upload_pending) {
      println("Envoi de l'image");
      thread("uploadImage");
    }
  }
}


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


/*
   image originale : [v]
 orientation 1, renvoie [>]
 orientation 2, renvoie [<]
 orientation 3 : renvoie [^]
 */
PGraphics rotationBuffer(int orientation) {
  PGraphics ir;
  if (orientation == 1) {
    ir = createGraphics(height, width);
    ir.beginDraw();
    ir.translate(0, width);
    ir.rotate(radians(270));
    ir.image(g, 0, 0);
    ir.endDraw();
  } else if (orientation == 2) {
    ir = createGraphics(height, width);
    ir.beginDraw();
    ir.translate(height, 0);
    ir.rotate(radians(90));
    ir.image(g, 0, 0);
    ir.endDraw();
  } else if (orientation == 3) {
    ir = createGraphics(width, height);
    ir.beginDraw();
    ir.translate(width, height);
    ir.rotate(radians(180));
    ir.image(g, 0, 0);
    ir.endDraw();
  } else {
    ir = createGraphics(width, height);
  }
  return ir;
}
