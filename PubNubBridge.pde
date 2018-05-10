/**
 *  PubNub Arduino Bridge
 *
 *  Passes Arduino Serial.println and Serial.print statements to PubNub and back
 */
 
String publish_key = "pub-c-2725239f-4145-4fef-81e3-ayylmao";
String subscribe_key = "sub-c-f6e9a4fc-1d08-11e8-84be-ayylmao";
String channel = "Default";             // PubNub channel
 
import processing.serial.*;
import java.util.Date;
import java.text.SimpleDateFormat;
 
Serial port;
PubNub pubnub;

char[] buffer;

String timestampToString(long timestamp) {
    SimpleDateFormat dateFormat = new SimpleDateFormat("MMM dd, yyyy hh:mm:ss a");
    return dateFormat.format(new Date(timestamp/10000));
}

void setup() {
    // Setup PubNub client
    PNConfiguration config = new PNConfiguration();
    config.setSubscribeKey(subscribe_key);
    config.setPublishKey(publish_key);
   
    pubnub = new PubNub(config);
    pubnub.addListener(new SubscribeCallback() {
        @Override
        public void status(PubNub pubnub, PNStatus status) {
            if (status.getCategory() == PNStatusCategory.PNUnexpectedDisconnectCategory) {
                println("Connection Status:\tDisconnected :(");
            }
            else if (status.getCategory() == PNStatusCategory.PNConnectedCategory) {
                println("Connection Status:\tConnected :)");
            }
            else if (status.getCategory() == PNStatusCategory.PNReconnectedCategory) {
                println("Connection Status:\tReconnected :)");
            }
            else if (status.getCategory() == PNStatusCategory.PNDecryptionErrorCategory) {
                println("Decryption Error:\tYour message was probably in plain text, when it's supposed to be encrypted.");
            }
        }
     
        @Override
        public void message(PubNub pubnub, PNMessageResult message) {
            JsonObject json = message.getMessage().getAsJsonObject();
            
            String text = "";
            if (json.get("text") != null) { text = json.get("text").getAsString(); }
            
            String uuid = "anonymous";
            if (json.get("uuid") != null) { uuid = json.get("uuid").getAsString(); }
            
            String sender = uuid;
            if (uuid.equals(pubnub.getInstanceId())) { sender = "me"; }
            
            println("Received Message:\n\tmessage:\t\"" + text + "\"\n\ttime:\t" + timestampToString(message.getTimetoken()) + "\n\tsender:\t" + sender);
            
            if (message.getChannel() != null) {
                print("\tchannel:\t");
                println(message.getChannel());
            }
            else {
                print("\tsubscription:\t");
                println(message.getSubscription());
            }
            
            if (!uuid.equals(pubnub.getInstanceId())) {
                // Write the message text to the Arduino serial port, ending with a newline char
                port.write(text.getBytes());
                port.write('\n');
            }
        }
     
        @Override
        public void presence(PubNub pubnub, PNPresenceEventResult presence) {
            // Not implemented
        }
    });
    ArrayList<String> channels = new ArrayList<String>();
    channels.add(channel);
    pubnub.subscribe().channels(channels).execute();
   
    // Setup Arduino
    printArray(Serial.list()); // List all the available serial ports
    port = new Serial(this, Serial.list()[4], 9600); // Open the port you are using at the rate you want
    
    // Everything else
    buffer = new char[0];
}
 
void draw() {
    if (port.available() > 0) {
        int value = port.read();
        
        // Reads data from the port until we find a character that is not a letter, number, or space
        if (Character.isLetterOrDigit(value) || ' ' == (char)value) {
            buffer = (char[])append(buffer, (char)value);
        } else {
            if (buffer.length > 0) {
                String text = new String(buffer);
                JsonObject message = new JsonObject();
                
                message.addProperty("text", text);
                message.addProperty("uuid", pubnub.getInstanceId());
                
                println("Sending Message:\n\tmessage:\t\"" + text + "\"");
                pubnub.publish().channel(channel).message(message).async(new PNCallback<PNPublishResult>() {
                    @Override
                    public void onResponse(PNPublishResult result, PNStatus status) {
                        if (!status.isError()) {
                            println("Message Sent:\n\ttime:\t" + timestampToString(result.getTimetoken()));
                        }
                        else {
                            println("Message Failed:\n\ttime: " + timestampToString(result.getTimetoken()));
                        }
                    }
                });
                buffer = new char[0];
            }
        }
    }
}
