#include "BluetoothSerial.h" //Header File for Serial Bluetooth, will be added by default into Arduino

BluetoothSerial ESP_BT; //Object for Bluetooth

int incoming;
int electrode1 = 34; //set ADC pin
int sample = 0;
String samples[4]; //temp data storage for sampled values prior to transmission
int j = 0;

void setup() {
  Serial.begin(9600); //Start Serial monitor in 9600
  ESP_BT.begin("ESP32_LED_Control"); //Name of your Bluetooth Signal
  //Serial.println("Bluetooth Device is Ready to Pair");

  //pinMode (LED_BUILTIN, OUTPUT);//Specify that LED pin is output
}

void loop() {

    //sampling/packing loop
  for(int i=0; i<4; i++){ //reads samples, change i if package size is altered
    sample = analogRead(electrode1);
    if (sample>999){
      samples[i] = String(sample);   
      }

    else if (sample>99 && sample<1000){
      samples[i] = String(sample) + 'A';
    }

    else if (sample<100 && sample>9){
      samples[i] = String(sample) + 'A' +'A';
    }

    else
      samples[i] = String(sample) + 'A' + 'A' + 'A';

    delay(10);
  }

    
  ESP_BT.print(samples[0]+samples[1]+samples[2]+samples[3]);
  Serial.println(samples[0]+samples[1]+samples[2]+samples[3]);
}
