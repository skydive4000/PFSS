# PFSS
POST FLIGHT STATUS SCREEN
-------------------------

Status Screen for EdgeTx Receivers  
Supports 128x64 monochrome displays  
Tested and made for Radiomaster Boxer / Pocket  
Install: Copy script to /SCRIPTS/TELEMETRY

-----------
DESCRIPTION
-----------

This LUA-Script collects telemetry data on your receiver.  
Therefore telemetry IDs must be discovered in your model setup.

-----------

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

-----------

When disarming, the following stats are written to /LOGS/PFSS_Log.txt
- Date;
- Time;
- Duration;
- Trip Distance;
- Maximum Speed;
- Maximum Altitude;
- Maximum Distance to Home;
- Minimum Battery Voltage;

-----------

First Row displays current flight mode and arming status (true/false).  
If flight mode = STAB; ACRO; HOR or AIR the script suggests the status "armed".  
If flight mode = !ERR*; 0; !FS; RTH; MANU; WAIT or anything else, the script suggests the status "disarmed".  

![Alt text](/PFSS.png?raw=true "ScreenshotBoxer")
