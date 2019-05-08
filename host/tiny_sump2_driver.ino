// Simple Arduino sketch to drive the FPGA inputs with pseudorandom patterns.
// Make sure to use a 3.3 V Arduino to avoid damaging the FPGA.

// Connect Arduino pins 4,5,6,7 to TinyFPGA pins 19,20,21,22
const int data_pins[] = {4,5,6,7};
// Connect Arduino pins 8,9 to TinyFPGA pins 23,24
const int strobe_pins[] = {8,9};

void setup() {
  for (int i = 0; i < 4; i++) {
    pinMode(data_pins[i], OUTPUT);
  }
  for (int i = 0; i < 2; i++) {
    pinMode(strobe_pins[i], OUTPUT);
  }

}

void loop() {
  // Every millisecond...
  delay(1);
  // Randomly with equal probability, either...
  if (random(2)) {
    // Set a random data pin to a random value.
    digitalWrite(data_pins[random(4)], random(2));
  } else {
    // Strobe either the high or low bits.
    int stb = random(2);
    digitalWrite(strobe_pins[stb], 1);
    delayMicroseconds(2);
    digitalWrite(strobe_pins[stb], 0);
  }
}
