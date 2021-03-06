/**
 *  Source file for implementation of module sendAckC in which
 *  the node 1 send a request to node 2 until it receives a response.
 *  The reply message contains a reading from the Fake 
 Sensor.
 *
 *  @author Luca Pietro Borsani
 */

#include "sendAck.h"
#include "Timer.h"

module sendAckC @safe() {

  uses {
    interface Boot; 
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;
    interface AMPacket;
    interface PacketAcknowledgements;
	interface Read<uint16_t>;
  }

} implementation {
  bool locked;
  uint16_t counter=0;
  uint16_t rec_id;
  message_t packet;

  void sendReq();
  void sendResp();

  void sendReq() {
   
   my_msg_t* msg=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
  
   msg->msg_type = REQ;
   msg->counter = counter++;
   msg->value = 0;  // value is not necessary in REQ message
   
   call PacketAcknowledgements.requestAck(&packet);
   
   if ( call AMSend.send(2,&packet,sizeof(my_msg_t)) == SUCCESS) {
	   dbg("radio_send","[t=%s] Sent request to node 2. (counter=%u)\n", sim_time_string(), msg->counter);	   
	   locked = TRUE;
   } else {
      dbg_clear("radio_send","Packet could not be delivered.\n");
   }
 }        

  
  void sendResp() {
	call Read.read();
  }

  
  event void Boot.booted() {
	dbg("boot","[t=%s] The Application is now booted.\n", sim_time_string());
	call AMControl.start();	
  }

  event void AMControl.startDone(error_t err){
    
    if (err == SUCCESS) { 		
	  if (TOS_NODE_ID == 1) {
	    call MilliTimer.startPeriodic ( 1000 );
	  }
    
    } else {
	  call AMControl.start();
    }
  }
  
  event void AMControl.stopDone(error_t err){
  }


  event void MilliTimer.fired() {
    if (locked) {
      return;
    }
	sendReq();
  }
  

  event void AMSend.sendDone(message_t* buf,error_t err) {

	if(&packet== buf && err == SUCCESS){
	  locked = FALSE;
	  if ( call PacketAcknowledgements.wasAcked(buf)) {
	    dbg_clear("radio_ack","ACK received.\n");
		call MilliTimer.stop();
	  } else {
		dbg_clear("radio_ack","ACK not received.\n");
	  }
	}
  }

  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
	
   my_msg_t* msg = (my_msg_t*)payload;
   rec_id = msg->value;
   dbg("radio_rec","[t=%s] Message received with counter=%u.\n", sim_time_string(), msg->counter);  
   if (msg->msg_type == REQ) {
     counter = msg->counter;
     sendResp();
   } else {
     dbg("radio_rec", "Value received from node 2: %u\n", msg->value);
   }
   return buf;
  }
  
  event void Read.readDone(error_t result, uint16_t data) {

    my_msg_t* msg = (my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
  
    msg->msg_type = RESP;
    msg->value = data;
    msg->counter = counter;
    
    call PacketAcknowledgements.requestAck(&packet);
   
    if (call AMSend.send(1,&packet,sizeof(my_msg_t)) == SUCCESS) {
      dbg("radio_send","[t=%s] Sent response to node 1.\n", sim_time_string());
      dbg("radio_send","Value read from sensor: %u.\n", data);   
      locked = TRUE;	     
    }  
  
  }
}


