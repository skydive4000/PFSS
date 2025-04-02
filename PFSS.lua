--[[#############################################################################

POST FLIGHT STATUS SCREEN (128x64 displays)
Copyright (C) by skydive4000  
https://github.com/skydive4000/PFSS

"POST FLIGHT STATUS SCREEN v0.2"

Install:
copy to /SCRIPTS/TELEMETRY

To Do:
Get RSSI from RemoteControl

################################################################################]]

-- FUNCTIONS
--- GET TELEMETRY ID
local function getTelemetryId(name)    
	field = getFieldInfo(name)
	if field then
		return field.id
	else
		return-1
	end
end

--- ROUND
local function rnd(v,d)
	if d then
		return math.floor((v*10^d)+(1/2))/(10^d)
	else
		return math.floor(v+(1/2))
	end
end

--- CALCULATE DISTANCE
local function calc_Distance(LatPos, LonPos, LatHome, LonHome)
	local d2r = math.pi/180
	local d_lon = (LonPos - LonHome) * d2r 
	local d_lat = (LatPos - LatHome) * d2r 
	local a = math.pow(math.sin(d_lat/2), 2) + math.cos(LatHome*d2r) * math.cos(LatPos*d2r) * math.pow(math.sin(d_lon/2), 2)
	local c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
	local dist = (6371000 * c) / 1000
	return rnd(dist,5)
end

--- RETURN TRUE, IF FILE EXISTS
function file_exists(name)
   local f = io.open(name, "r")
   return f ~= nil and io.close(f)
end


-- DECLARING VARIABLES

local DistHome["current"] = 0
local DistHome["max"] = 0

local log_filename = "/LOGS/PFSS_Log.csv"
local maxDistHome = 0
local maxAltitude = 0
local maxAltitudeID = 0
local maxSpeed = 0
local maxSpeedID = 0
local StartAltitude = 0
local BatMinimum = 99
local BatNow = 0
local BatID = 0
local minBatID = 0
local FlightMode = 0
local FlightModeID = 0
local DateTime = getDateTime()
local Timer = 0
local Time = 0
local LastTime = 0
local Armed = false
local Arming = false
local ArmingTime = 0
local gpsLAT = 0
local gpsLON = 0
local gpsLAT_H = 0
local gpsLON_H = 0
local gpsPrevLAT = 0
local gpsPrevLON = 0
local gpsSATS = 0
local gpsALT = 0
local gpsSpeed = 0
local gpssatId = 0
local gpsspeedId = 0
local gpsaltId = 0
local gpsDtH = 0
local gpsTotalDist = 0
local update = true
local reset = false
local coordinates_prev = 0
local coordinates_current = 0


-- INIT
local function init()  				
	gpsId = getTelemetryId("GPS")
	gpssatId = getTelemetryId("Sats")
	gpsspeedId = getTelemetryId("GSpd")
	maxSpeedID = getTelemetryId("GSpd+")
	BatID = getTelemetryId("RxBt") > -1 and getTelemetryId("RxBt") or getTelemetryId("BtRx")
    minBatID = getTelemetryId("RxBt-") > -1 and getTelemetryId("RxBt-") or getTelemetryId("BtRx-")
	FlightModeID = getTelemetryId("FM")
	gpsaltId = getTelemetryId("Alt")
	maxAltitudeID = getTelemetryId("Alt+")
	--if "ALT" can't be read, try to read "GAlt"
	if (gpsaltId == -1) then 
        gpsaltId = getTelemetryId("GAlt") 
        maxAltitudeID = getTelemetryId("GAlt+") 
    end
	--if Stats can't be read, try to read Tmp2 (number of satellites SBUS/FRSKY)
	if (gpssatId == -1) then 
        gpssatId = getTelemetryId("Tmp2")
        maxAltitudeID = getTelemetryId("Tmp2+")
    end
    -- WRITE HEADER, IF LOG FILE IS CREATED
	if file_exists(log_filename)==false then
	    file = io.open(log_filename, "a")
	    io.write(file, "DATE;TIME;DURATION;TRIP;MAXSPEED;MAXALTITUDE;MAXDISTHOME;MINBAT")
        io.write(file, "\n")
        io.close(file)
	end
end


-- BACKGROUND
local function background()	
	-- GET DATA
    LastTime = Time
	Time = getTime()
	FlightMode = getValue(FlightModeID)
	gpsLatLon = getValue(gpsId)
	BatNow = getValue(BatID)
	gpsSATS = getValue(gpssatId)
	if string.len(gpsSATS) > 2 then		
		gpsSATS = string.sub (gpsSATS, 3,6)		
	else
		gpsSATS = string.sub (gpsSATS, 0,3)		
	end	    
    
    -- UPDATE ARMING STATUS
    if (FlightMode == "AIR" or FlightMode == "STAB" or FlightMode == "ACRO" or FlightMode == "HOR") and not Armed and not Arming then
        Arming = true
        ArmingTime = getTime()
    end
    if Arming then
        if getTime() - ArmingTime > 100 then
            Armed = true
            ArmingTime = 0
            gpsDtH = 0
		    gpsTotalDist = 0
		    gpsLAT_H = 0
		    gpsLON_H = 0
	        maxDistHome = 0
	        maxAltitude = 0
	        maxSpeed = 0
	        StartAltitude = 0
	        Timer = 0
	        BatMinimum = 99
	        DateTime = getDateTime()
	        local test = resetGlobalTimer()
		    reset = true
            Arming = false
        end
    end
    if not (FlightMode == "AIR" or FlightMode == "STAB" or FlightMode == "ACRO" or FlightMode == "HOR") then
        if Armed then
        -- WRITE DATA TO LOG FILE
            file = io.open(log_filename, "a")
            io.write(file, string.sub(100+DateTime["day"],2).."."..string.sub(100+DateTime["mon"],2).."."..string.sub(DateTime["year"],3))
            io.write(file, ";")
            io.write(file, string.sub(100+DateTime["hour"],2)..":"..string.sub(100+DateTime["min"],2))
            io.write(file, ";")
            io.write(file, string.sub(100 + math.floor((Timer/100)/60),2)..":"..string.sub(100+math.floor(math.fmod((Timer/100),60)),2))
            io.write(file, ";")
            io.write(file, gpsTotalDist)
            io.write(file, ";")
            io.write(file, maxSpeed)
            io.write(file, ";")
            io.write(file, maxAltitude)
            io.write(file, ";")
            io.write(file, maxDistHome)
            io.write(file, ";")
            io.write(file, BatMinimum)
            io.write(file, "\n")
            io.close(file)
        end
        Armed = false
    end

    -- CHECK SATS AND UPDATE DISTANCE DATA
   	if (tonumber(gpsSATS) >= 6) then
	    if (type(gpsLatLon) == "table") then 			
		    gpsLAT = rnd(gpsLatLon["lat"],6)
		    gpsLON = rnd(gpsLatLon["lon"],6)		
		    gpsSpeed = rnd(getValue(gpsspeedId), 1)
		    gpsALT = rnd(getValue(gpsaltId),0)		
		    maxSpeed = rnd(getValue(maxSpeedID),0)
            maxAltitude = rnd(getValue(maxAltitudeID),0)
            BatMinimum = rnd(getValue(minBatID),2)
		    if Armed then
     		   Timer = Timer + (Time - LastTime)
		    end
		    
		    -- SET START POSITION
		    if (reset == true) then
			    gpsLAT_H = rnd(gpsLatLon["lat"],6)
			    gpsLON_H = rnd(gpsLatLon["lon"],6)	
			    reset = false
		    end		

		    update = true	
	    else
	        -- NO TELEMETRY (GPS) DATA
		    update = false
	    end
	
	-- CALCULATE DISTANCE HOME / TRIP
		if (gpsLAT ~= gpsPrevLAT) and (gpsLON ~=  gpsPrevLON) then
			if (gpsLAT_H ~= 0) and  (gpsLON_H ~= 0) then 

				-- DISTANCE HOME
				gpsDtH = rnd(calc_Distance(gpsLAT, gpsLON, gpsLAT_H, gpsLON_H),3)
				if (gpsDtH > maxDistHome) and gpsDtH ~= nil then
				    maxDistHome = gpsDtH
				end				
				gpsDtH = string.format("%.3f",gpsDtH)
				
				-- DISTANCE TRIP
				if (gpsPrevLAT ~= 0) and  (gpsPrevLON ~= 0) and (gpsLAT ~= 0) and  (gpsLON ~= 0)then	
					gpsTotalDist =  rnd(tonumber(gpsTotalDist) + calc_Distance(gpsLAT,gpsLON,gpsPrevLAT,gpsPrevLON),5) -- changed from 2 to 5
					gpsTotalDist = string.format("%.3f",gpsTotalDist)					
				end
			end
			gpsPrevLAT = gpsLAT
			gpsPrevLON = gpsLON	
		end
	end
end


-- MAIN
local function run(event)  
	lcd.clear()  
	background() 
	
	-- DRAW SCREEN
	lcd.drawText(2,1,"Flight Mode: " ,SMLSIZE)
	lcd.drawFilledRectangle(1,0, 126, 8, GREY_DEFAULT)
	lcd.drawText(60,1,FlightMode ,SMLSIZE + INVERS)
	lcd.drawText(90,1,tostring(Armed) ,SMLSIZE + INVERS)
	lcd.drawText(2,9, "Sats:", SMLSIZE)	
	lcd.drawText(30,9, gpsSATS, SMLSIZE)
	lcd.drawText(60,9, "Armed:", SMLSIZE)
	lcd.drawText(90,9, string.sub(100 + math.floor((Timer/100)/60),2)..":"..string.sub(100+math.floor(math.fmod((Timer/100),60)),2), SMLSIZE)
	lcd.drawText(2,23, "Trip:", SMLSIZE)
	lcd.drawText(30,23, gpsTotalDist, SMLSIZE)
	lcd.drawText(2,16, "Home:", SMLSIZE)
	lcd.drawText(30,16, string.format("%.5f", gpsLAT_H) .. " / " .. string.format("%.5f", gpsLON_H), SMLSIZE)
	lcd.drawText(2,30, "Speed:", SMLSIZE)
	lcd.drawText(30,30, gpsSpeed,SMLSIZE)
	lcd.drawText(62,30, "max:", SMLSIZE)
	lcd.drawText(90,30, maxSpeed,SMLSIZE)
	lcd.drawText(2,37, "Alt:", SMLSIZE)
	lcd.drawText(30,37, gpsALT,SMLSIZE)
	lcd.drawText(62,37, "max:", SMLSIZE)
	lcd.drawText(90,37, maxAltitude,SMLSIZE)
	lcd.drawText(2,44, "DtH:", SMLSIZE)
	lcd.drawText(30,44, gpsDtH, SMLSIZE)
	lcd.drawText(62,44, "max:", SMLSIZE)
	lcd.drawText(90,44, maxDistHome, SMLSIZE)
	lcd.drawText(2,51, "Bat:", SMLSIZE)
	lcd.drawText(30,51, string.format("%.2f",BatNow), SMLSIZE)
	lcd.drawText(62,51, "min:", SMLSIZE)
	lcd.drawText(90,51, string.format("%.2f",BatMinimum), SMLSIZE)
	lcd.drawText(27,58, string.sub(100+DateTime["day"],2).."."..string.sub(100+DateTime["mon"],2).."."..string.sub(DateTime["year"],3).." - "..string.sub(100+DateTime["hour"],2)..":"..string.sub(100+DateTime["min"],2), SMLSIZE)

    -- BLINK IF LOW SATS
	if (tonumber(gpsSATS) < 6) then
		lcd.drawText(60,23, "< 6 SATS!", SMLSIZE + INVERS + BLINK)
	end
		
	-- BLINK IF NO TELEMETRY
	if update == false then
		lcd.drawText(60,23, "NO TELEMETRY!", SMLSIZE + INVERS + BLINK)		
	end	
end
 
return {init=init, run=run, background=background}
