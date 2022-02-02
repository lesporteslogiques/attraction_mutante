
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
