# PFSS
POST FLIGHT STATUS SCREEN

Status Screen for EdgeTx Receivers  
Supports 128x64 monochrome displays  
Tested and made for Radiomaster Boxer / Pocket  

I wrote this script, because DJI O3 / O4 does not record  
the post flight status screen displayed by the flight controller. ;)  
(The record ends too soon)

## Description

This LUA-Script collects telemetry data on your receiver.  

After arming**, the following Data is updated:
- Date and time (at the time arming)
- Arming status
- Flight Mode
- Number of Sats
- Status (NO TELEMETRY / LESS THAN 6 SATS)
- Home coordinates (at the time arming)
- Duration of flight (total time armed)
- Distance travelled (Trip) (km)
- Maximum speed (km/h)
- Maximum altitude above home (m)
- Maximum distance to home (km)
- Mnimum battery voltage (v)

**To track data a minimum of 6 Sats is required.   

When disarming, the following stats are written to /LOGS/PFSS_Log.csv
- Date;
- Time;
- Duration;
- Trip Distance;
- Maximum Speed;
- Maximum Altitude;
- Maximum Distance to Home;
- Minimum Battery Voltage;

If flight mode = STAB; ACRO; HOR or AIR the script suggests the status "armed".  
If flight mode = !ERR*; 0; !FS; RTH; MANU; WAIT or anything else, the script suggests the status "disarmed".  

![Alt text](/PFSS.png?raw=true "ScreenshotBoxer")

## Getting Started

### Dependencies

All the max and min Values are calculated on your RC. 
Therefore you should ensure, that the telemetry data is updated frequently.

The update intervall relies on 3 sources:
- ExpressLRS Packet Rate (Higher = better, but reduces range)
- ExpressLRS Telem Ratio (Higher = better, but reduces packets send from RC to FC)
- Disabling not needed telemetry data via Betaflight

Example:
With a Packet Pate of 100 Hz and a Telem Ratio of 1:16, the telem intervall is roughly 6 times per second.  
If you disable some of the not needed telem data, the GPS Position is updated about 3 times per second.  
The resulting values for TRIP/maxSpeed/maxAltitude/maxDistHome are nearly exactly the same as via the OSD Post Flight Stats.

See also:
- https://www.expresslrs.org/info/telem-bandwidth/#  
- https://www.expresslrs.org/quick-start/pre-1stflight/#bench-test

### Installing

* Copy script to /SCRIPTS/TELEMETRY
* Go to Models screen 11/12 (TELEMETRY) and discover telemetry IDs.
* Go to Models Screen 12/12 (DISPLAY)
* Select Script and choose PFSS

### Executing program

* From main screen press "TELE" button and +PAGE/-PAGE to get to the PFSS Screen
* Thats it!
* All of the max/min values are automatically reset on arming.

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

No License.
