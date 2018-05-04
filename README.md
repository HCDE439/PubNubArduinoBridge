# PubNub Arduino Bridge
A simple Processing sketch to bridge a serial port to PubNub

## Installation
- Download a ZIP of this project
- Open the sketch in Processing. It may prompt you to move it into a separate folder - that's alright
- Replace the publish_key and subscribe_key parameters with your own keys

## Notes
- You cannot open the Serial Console or upload your Arduino sketch to the Arduino while the Processing sketch is running
- You may need to modify the search param for finding a suitable serial port. Right now this sketch simply searches for the first "usbmodem". If you're using multiple Arduinos / XBees on macOS or Linux, you should change this to be more specific. If you're on Windows, your port will be something like "COM1"
- If Processing can't find 'PubNub' you may need to re-import the PubNub jar file. To do this,
-- Go to Sketch > Add File...
-- Add the `.jar` file from the "code" folder
