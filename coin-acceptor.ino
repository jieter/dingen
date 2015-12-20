#define actionTimeout 1000     

#define COIN 2
#define SSR 3

// seconds to turn the SSR
#define PULSE_TIME_2 60 * 60
#define PULSE_TIME_4 60 * 60 * 4

volatile unsigned long lastPulse = 0;
volatile unsigned int pulseCount = 0;
volatile unsigned long turning_off = 0;

void setup() {
    Serial.begin(115200);
   
    pinMode(SSR, OUTPUT);
    pinMode(COIN, INPUT);

    // Turn SSR on for 2 seconds
    digitalWrite(SSR, HIGH);
    delay(2000);
    digitalWrite(SSR, LOW); 

    attachInterrupt(0, pulse_isr, RISING);
   
    Serial.println("Coin Acceptor ready, insert coin...");
}

unsigned long last_printed = 0;
void print_time_left() {
    if (millis() - last_printed > 6000) {
        Serial.print("Time left: ");
        unsigned int time_left = (turning_off - millis()) / 1000;
        if (time_left > 60) {
            int hours = time_left / 3600;
            int minutes = (time_left % 3600) / 60;
            int seconds = time_left % 60;
            
            Serial.print(hours);
            Serial.print(":");
            if (minutes < 10) {
                Serial.print("0");
            }
            Serial.print(minutes);
            Serial.print(":");
            if (seconds < 10) {
                Serial.print("0");
            }
            Serial.println(seconds);
        } else {
            Serial.print(time_left);
            Serial.println("s");
        }
        last_printed = millis();
    }
}
void loop() {
    if (millis() - lastPulse > actionTimeout && pulseCount > 0) {
        Serial.print("Received pulses: ");
        Serial.println(pulseCount);

        unsigned long increaseAmount;
        if (pulseCount == 4) {
            increaseAmount = PULSE_TIME_4;
        } else {
            increaseAmount = PULSE_TIME_2;
        }
        
        if (turning_off == 0) {
            turning_off = millis();
            Serial.print("Turning on power for ");
        } else {
            Serial.print("adding some extra credit ");
        }
        
        Serial.print(increaseAmount);
        Serial.println("s");

        turning_off += increaseAmount * 1000;
                
        print_time_left();
        pulseCount = 0;
      
        // turn power on.
        digitalWrite(SSR, HIGH);
    }
   
    
    if (turning_off > 0 && millis() > turning_off) {
        Serial.println("Ran out of credit, turning off the power");
        digitalWrite(SSR, LOW);
        turning_off = 0;
        return;
    }
    if (turning_off > 0 && ((turning_off - millis()) / 1000) % 60 == 0) {
        print_time_left();
    }
}
 
void pulse_isr() {
    lastPulse = millis();
    pulseCount++;
}
 
