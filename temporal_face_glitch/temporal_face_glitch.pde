/*
  Gweltaz DG
  2022-02-01
  
*/

import gab.opencv.*;
import java.awt.Rectangle;
import processing.video.*;


OpenCV opencv;
Rectangle[] faces;
Capture cam;

final int NUM_RECORDS = 16;
final int SEGMENT_MAX_FRAMES = 30;
final int NFRAMES_BEFORE_REC = 12;
ArrayList<PImage[]> recorded_segments = new ArrayList<>();

PImage[] playing_segment;
PImage[] record = new PImage[SEGMENT_MAX_FRAMES];
int num_frame = 0;

int delay = NFRAMES_BEFORE_REC;


void setup() {
  //size(640, 480);
  fullScreen();

  cam = new Capture(this, 640, 480);
  cam.start();
  
  opencv = new OpenCV(this, cam.width, cam.height);
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);

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
    // Face detected on camera !
    if (delay <= 0) {
    
      if (playing_segment != null && num_frame < playing_segment.length) {
        set(0, 0, playing_segment[num_frame]);
      } else {
        set(0, 0, cam);
      }
      
      if (num_frame < SEGMENT_MAX_FRAMES) {
        record[num_frame] = cam.copy();
        num_frame += 1;
        //fill(255, 0, 0);
        //noStroke();
        //circle(width-40, 40, 16);
      } else {
        // Glitch randomly
        if (!recorded_segments.isEmpty() && random(1) < 0.05) {
          println("glitch");
          int n = int(random(recorded_segments.size()));
          PImage[] seg = recorded_segments.get(n);
          int f = int(random(seg.length));
          set(0, 0, seg[f]);
        }
      }
    } else {
      set(0, 0, cam);
      delay -= 1;
    }
  }
  else {
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
      println(recorded_segments.size());
    }
    
    set(0, 0, cam);
  }
}

void mouseClicked() {
  
}
