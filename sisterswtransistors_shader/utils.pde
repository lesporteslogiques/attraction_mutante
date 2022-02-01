CallbackListener toFront = new CallbackListener() {
  public void controlEvent(CallbackEvent theEvent) {
    theEvent.getController().getParent().bringToFront();
    theEvent.getController().bringToFront();
    ((ScrollableList)theEvent.getController()).open();
  }
};

CallbackListener close = new CallbackListener() {
  public void controlEvent(CallbackEvent theEvent) {
    ((ScrollableList)theEvent.getController()).close();
  }
};


void gradient(int n) {
  String gradient_name = (String) cp5.get(ScrollableList.class, "gradient").getItem(n).get("name");
  gradient = gradients.get(gradient_name);
  icol = 0;
}


void gradient_step(int n) {
  String function_name = (String) cp5.get(ScrollableList.class, "gradient_step").getItem(n).get("name");
  gradient_step_function = step_functions.get(function_name);
}


float smoothstep(float x) {
  x = constrain(x, 0f, 1f);
  return x * x * (3 - 2 * x);
}


HashMap<String, color[]> buildGradients() {
  color[] rainbow = {#ff0000, #ffff00, #00ff00, #00ffff, #0000ff, #ff00ff};
  color[] bw = {#000000, #ffffff};
  color[] sunset = {#2D4059, #EA5455, #F07B3F, #FFD460};
  color[] pastel = {#F38181, #FCE38A, #EAFFD0, #95E1D3};
  color[] winter = {#E3FDFD, #CBF1F5, #A6E3E9, #71C9CE};
  color[] candy = {#00B8A9, #F8F3D4, #F6416C, #FFDE7D};
  
  HashMap<String, color[]> gradients = new HashMap<>();
  gradients.put("rainbow", rainbow);
  gradients.put("b&w", bw);
  gradients.put("sunset", sunset);
  gradients.put("pastel", pastel);
  gradients.put("winter", winter);
  gradients.put("candy", candy);

  return gradients;
}
