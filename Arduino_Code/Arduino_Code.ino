const int PIR_PIN = 2;          // PIR sensor pin (interrupt source)
const int SOUND_PINS[4] = {A0, A1, A2, A3}; // Sound sensor pins
const int Sound_Power_Pin = 6;
const int ALERT_PIN = 3;       // Output pin to signal alert
const int INTRUDER_ALERT_PIN = 4; 
const int MODE_PIN = 5;
const int SAMPLE_WINDOW = 50;  // Sampling window for sound sensors (ms)
const int THRESHOLD_DB = 50;   // dB level threshold
bool motionDetected = false;
volatile bool Mode_select = false;

void detectMotion() {
    motionDetected = true;  // Interrupt routine sets flag
}

void setup() {
    pinMode(PIR_PIN, INPUT);
    pinMode(ALERT_PIN, OUTPUT);
    pinMode(Sound_Power_Pin, OUTPUT);
    pinMode(INTRUDER_ALERT_PIN, OUTPUT);
    pinMode(MODE_PIN, INPUT);
    digitalWrite(INTRUDER_ALERT_PIN, LOW);
    digitalWrite(ALERT_PIN, LOW);
    digitalWrite(Sound_Power_Pin, LOW);
    Serial.begin(9600);
    attachInterrupt(digitalPinToInterrupt(PIR_PIN), detectMotion, RISING);
    
}

void loop() {
    if (!motionDetected) 
        return;
    motionDetected = false;
    int pinState = digitalRead(MODE_PIN);
    if(pinState == LOW){
        handleSoundAnalysis();
    }
    else{
        IntruderSystem();
    }

}

void handleSoundAnalysis() {
    digitalWrite(Sound_Power_Pin, HIGH);
    delay(100);
    Serial.println("Motion detected! Starting sound analysis...");
    unsigned long startTime = millis();
    bool alertTriggered = false;

    while (millis() - startTime < 6000) {
        for (int i = 0; i < 4; i++) {
            int dbLevel = readSoundSensor(SOUND_PINS[i]);
            Serial.print("Sensor "); Serial.print(i);
            Serial.print(": "); Serial.print(dbLevel);
            Serial.println(" dB");

            if (dbLevel >= THRESHOLD_DB) {
                alertTriggered = true;
                break;
            }else {
                alertTriggered = false;
            }
        }
        delay(10);
    
        if (alertTriggered) {
            Serial.println("Threshold exceeded! Activating alert...");
            digitalWrite(ALERT_PIN, HIGH);
            delay(5000);
            digitalWrite(ALERT_PIN, LOW);
            
        } else {
            Serial.println("No threshold exceedance. Returning to check.");
        }
    }
    digitalWrite(Sound_Power_Pin, LOW);
}

int readSoundSensor(int pin) {
    unsigned long startMillis = millis();
    int signalMax = 0, signalMin = 1024;
    
    while (millis() - startMillis < SAMPLE_WINDOW) {
        int sample = analogRead(pin);
        if (sample < 1024) {
            signalMax = max(signalMax, sample);
            signalMin = min(signalMin, sample);
        }
    }
    int peakToPeak = signalMax - signalMin;
    return map(peakToPeak, 20, 900, 49, 90); // Convert to dB
}

int IntruderSystem(){
    digitalWrite(INTRUDER_ALERT_PIN, HIGH);  // Generate a tone
    delay(4000);             // Keep the tone for 4 seconds
    digitalWrite(INTRUDER_ALERT_PIN, LOW);    // Stop the tone
    delay(20);  
    return;
}
