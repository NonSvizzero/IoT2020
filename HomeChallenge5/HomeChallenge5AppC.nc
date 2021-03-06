#include "HomeChallenge5.h"
#include "printf.h"

/**
 * Implementation of Home Challenge #1 for IoT course 2019/2020 @ PoliMi.
 * The challenge consists in setting up 3 motes exchanges messages with each other,
 * each one sending at different frequencies (1, 3 and 5 Hz respectively) and incrementing
 * a local counter everytime a message is received.
 * Messages whose counter value is a multiple of 10 switch off all the leds, otherwise
 * they toggle a single LED based on the sender (led0 if sent from node 1 and so on).
 */

configuration HomeChallenge5AppC {}
implementation {
  components MainC, HomeChallenge5C as App;
  components SerialPrintfC;
  components new AMSenderC(AM_RADIO_MSG);
  components new AMReceiverC(AM_RADIO_MSG);
  components new TimerMilliC();
  components ActiveMessageC;
  components RandomC;
  
  App.Boot -> MainC.Boot;
  
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.MilliTimer -> TimerMilliC;
  App.Packet -> AMSenderC;
  App.Random -> RandomC;
}


