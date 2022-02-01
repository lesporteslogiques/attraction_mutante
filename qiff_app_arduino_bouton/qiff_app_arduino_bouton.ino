/*
 * Envoi d'un message série pour donner l'état d'un bouton
 * La Baleine, Quimper, Dour Ru, 20220201 / pierre@lesporteslogiques.net
 * Processing 4.0b2 / Arduino 1.8.5 @ kirin / Debian Stretch 9.5
 * + lib. OneButton v2.0.4 de Matthias Hertel https://github.com/mathertel/OneButton
 */

#include <OneButton.h>
#define BROCHE_BOUTON           2

OneButton bouton(BROCHE_BOUTON, false, false);

void setup() {
  pinMode(13, OUTPUT);      // sets the digital pin as output
  bouton.attachClick(clicBouton);
  Serial.begin(9600);
}

void loop() {
  bouton.tick(); // surveiller le bouton
  delay(10);
}

void clicBouton() {
  // Vérification visuelle, la LED change d'état quand on clique le bouton
  static int m = LOW;
  m = !m; 
  digitalWrite(13, m);
  // Envoyer le message sur le port série
  Serial.println("1");
}

