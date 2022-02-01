import processing.video.*;

//
// PARAMETERS
//
int REFRESH_INTERVAL = 14000;   // in millisecs
float START_DISPLACEMENT = 800.0;
float SPEED = 1.0;
boolean INVERT_COLORS = true;


Capture video;
PVector[] vectorMap;
PImage source_img;
float source_x, source_y;
int index;
float amp;
int last_update;


void setup() {
  size(1024, 768);
  video = new Capture(this, width, height);
  video.start();
  while (!video.available()) {
    delay(100);
  }
  video.read();
  vectorMap = new PVector[video.pixels.length];
  updateDisplacementMap(vectorMap, video);
  source_img = video.copy();
  amp = START_DISPLACEMENT;
  last_update = millis();
}


void updateDisplacementMap(PVector[] vector_map, PImage map_img) {
  map_img.loadPixels();
  float x_off, y_off;
  for (int j=0; j<height; j++) {
    for (int i=0; i<width; i++) {
      index = i + width*j;
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
  if (video.available()) {
    video.read();
    if (millis() - last_update > REFRESH_INTERVAL) {
      // Update vectorMap
      updateDisplacementMap(vectorMap, video);
      last_update = millis();
      amp = START_DISPLACEMENT;
    }
  }
  
  loadPixels();
  index = 0;
  for (int j=0; j<height; j++) {
    for (int i=0; i<width; i++) {
      source_x = amp * vectorMap[index].x + float(i);
      source_y = amp * vectorMap[index].y + float(j);
      while (source_x < 0)
        source_x += width;
      while (source_x >= width)
        source_x -= width;
      while (source_y < 0)
        source_y += height;
      while (source_y >= height)
        source_y -= height;
      
      pixels[index] = video.pixels[width*floor(source_y) + floor(source_x)];
      
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
