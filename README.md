# PFSS(POST FLIGHT STATUS SCREEN)
Status Screen for EdgeTx Receivers  
Supports 128x64 monochrome displays  
Tested and made for Radiomaster Boxer / Pocket  

## Description

This LUA-Script collects telemetry data on your receiver.  
Therefore telemetry IDs must be discovered in your model setup.

After arming**, it displays:
- Number of sattelites
- Home coordinates (at the time arming)
- Duration of flight (total time armed)
- Trip distance (km)
- Current speed / maximum speed (km/h)
- Current altitude / maximum altitude (m)***
- Current distance to home / maximum distance to home (km)
- Current battery voltage / minimum battery voltage (v)
- Current date and time

**To track data a minimum of 6 Sats is required.  
***When disarmed, altitude above sea-level.  
***Whem armed, altitude above home-coordinates.  
***Maximum altitude is always above home-coordinates.

When disarming, the following stats are written to /LOGS/PFSS_Log.csv
- Date;
- Time;
- Duration;
- Trip Distance;
- Maximum Speed;
- Maximum Altitude;
- Maximum Distance to Home;
- Minimum Battery Voltage;
First Row displays current flight mode and arming status (true/false).  
If flight mode = STAB; ACRO; HOR or AIR the script suggests the status "armed".  
If flight mode = !ERR*; 0; !FS; RTH; MANU; WAIT or anything else, the script suggests the status "disarmed".  

![Alt text](/PFSS.png?raw=true "ScreenshotBoxer")

## Getting Started

### Dependencies

All the max and min Values are calculated on your RC.
Therefore you must ensure, that the update intervall for telemetry data is not too long.
The update intervall relies on 3 sources:
- ExpressLRS Packet Rate (Higher = better, but reduces range)
- ExpressLRS Telem Ratio (Higher = better, but reduces packets send from RC to FC)
- 

### Installing

* Copy script to /SCRIPTS/TELEMETRY

### Executing program

* Go to Models Screen 12/12 (DISPLAY)
* Select Script and choose PFSS
* From main screen press "TELE" button and +PAGE/-PAGE to get to the PFSS Screen
* Thats it! 

## Help

* You will find the log file at /LOGS/PFSS_Log.csv

## Authors

Oliver:  
https://github.com/skydive4000

## Version History

* 0.2
    * Screen Update
    * Completely new variables
* 0.1
    * Initial Release

## License

This project is licensed under the [NAME HERE] License - see the LICENSE.md file for details
