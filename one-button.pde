/* Fotohokje
 *
 * one-button.pde
 */

int BUTTON_PIN = 10;
char KEY = " "; // space

void setup() {
  Serial.begin(9600);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  delay(4000);
}

void loop() {
  if (digitalRead(BUTTON_PIN) == HIGH) {
    delay(10);
  } else {
    Keyboard.print(KEY);
    delay(1000);
  }
  delay(10);
}
