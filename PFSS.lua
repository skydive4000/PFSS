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
local DistHome = {}
	DistHome.current = 0
	DistHome.max = 0
	DistHome.total = 0 -- < not needed ?
local Speed = {}
	Speed.current = 0
	Speed.currentID = getTelemetryId("GSpd")
	Speed.max = 0
	Speed.maxID = getTelemetryId("GSpd+")
local Altitude = {}
	Altitude.current = 0
	Altitude.currentID = getTelemetryId("Alt") -- MAYBE IF "Alt" does not work, try GAlt or Tmp2
	Altitude.max = 0
	Altitude.maxID = getTelemetryId("Alt+")
	Altitude.home = 0
local Battery = {}
	Battery.current = 0
	Battery.currentID = getTelemetryId("RxBt") > -1 and getTelemetryId("RxBt") or getTelemetryId("BtRx")
	Battery.min = 99
	Battery.minID = getTelemetryId("RxBt-") > -1 and getTelemetryId("RxBt-") or getTelemetryId("BtRx-")
local Flightmode = {}
	Flightmode.current = 0
	Flightmode.currentID = getTelemetryId("FM")
local Sats = {}
	Sats.current = 0
	Sats.currentID = getTelemetryId("Sats")
local GPS = {}
	GPS.Data = false
	GPS.LatLon = 0
	GPS.Lat = 0
	GPS.Lon = 0
	GPS.PrevLat = 0
	GPS.PrevLon = 0
	GPS.LatHome = 0
	GPS.LonHome = 0
	GPS.ID = getTelemetryId("GPS")
local LinkQuality = 0
local log_filename = "/LOGS/PFSS_Log.csv"
local DateTime = getDateTime()
local Timer = 0
local Time = 0
local LastTime = 0
local Armed = false
local Arming = false
local ArmingTime = 0
local TotalDist = 0
local update = true
local reset = false

-- INIT
local function init()  				
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
    -- CHECK CONNECTION
	LinkQuality = getRSSI()
	if LinkQuality > 0 then
		Connected = true
	else
		Connected = false
	end
	LastTime = Time
	Time = getTime()
	
	-- IF CONNECTED, GATHER INFORMATION
	if Connected then
		Flightmode.current = getValue(Flightmode.currentID)
		GPS.LatLon = getValue(GPS.ID)
		Battery.current = getValue(Battery.currentID)
		Battery.min = getValue(Battery.minID)
		Sats.current = getValue(Sats.currentID)
		--Speed.max = rnd(getValue(Speed.maxID),0)					
		--Altitude.max = rnd(getValue(Altitude.maxID),0)
		if string.len(Sats.current) > 2 then		
			Sats.current = string.sub (Sats.current, 3,6)		
		else
			Sats.current = string.sub (Sats.current, 0,3)		
		end	    
	
		-- IF GPS DATA AVAILABLE, GATHER GPS DATA
		if (tonumber(Sats.current) >= 6) then
			if (type(GPS.LatLon) == "table") then 			
				GPS.Lat = rnd(GPS.LatLon["lat"],6)
				GPS.Lon = rnd(GPS.LatLon["lon"],6)		
				Speed.current = rnd(getValue(Speed.currentID), 1)
				Altitude.current = rnd(getValue(Altitude.currentID),0)

				-- SET START POSITION
				if (reset == true) then
					GPS.LatHome = GPS.Lat
					GPS.LonHome = GPS.Lon
					reset = false
				end		

				GPS.Data = true	
			else
				-- NO TELEMETRY (GPS) DATA
				GPS.Data = false
			end
		end

		-- UPDATE ARMING STATUS
		if (Flightmode.current == "AIR" or Flightmode.current == "STAB" or Flightmode.current == "ACRO" or Flightmode.current == "HOR") and not Armed and not Arming then
			Arming = true
			-- local resetTimer = resetGlobalTimer()
			ArmingTime = getTime()
			--local resetAltitude = resetSensor(Altitude.maxID)
		end

		if Arming then
			if getTime() - ArmingTime > 100 then
				-- local resetTimer = resetGlobalTimer()
				-- local resetAltitude = resetSensor(Altitude.maxID)
				Armed = true
				ArmingTime = 0
				Timer = 0		
				TotalDist = 0
				DistHome.current = 0
				DistHome.max = 0
				Altitude.max = 0
				Speed.max = 0
				GPS.LatHome = 0
				GPS.LonHome = 0
				Battery.min = 99
				DateTime = getDateTime()
				reset = true
				Arming = false
			end
		end
		if not (Flightmode.current == "AIR" or Flightmode.current == "STAB" or Flightmode.current == "ACRO" or Flightmode.current == "HOR") then
			if Armed then
			-- WRITE DATA TO LOG FILE
				file = io.open(log_filename, "a")
				io.write(file, string.sub(100+DateTime["day"],2).."."..string.sub(100+DateTime["mon"],2).."."..string.sub(DateTime["year"],3))
				io.write(file, ";")
				io.write(file, string.sub(100+DateTime["hour"],2)..":"..string.sub(100+DateTime["min"],2))
				io.write(file, ";")
				io.write(file, string.sub(100 + math.floor((Timer/100)/60),2)..":"..string.sub(100+math.floor(math.fmod((Timer/100),60)),2))
				io.write(file, ";")
				io.write(file, TotalDist)
				io.write(file, ";")
				io.write(file, Speed.max)
				io.write(file, ";")
				io.write(file, Altitude.max)
				io.write(file, ";")
				io.write(file, DistHome.max)
				io.write(file, ";")
				io.write(file, Battery.min)
				io.write(file, "\n")
				io.close(file)
			end
			Armed = false
		end

		-- UPDATE TIMER, IF ARMED
		if Armed then
			Timer = Timer + (Time - LastTime)
		end
		
		-- CALCULATE DISTANCE HOME / TRIP
		if (GPS.Lat ~= GPS.PrevLat) and (GPS.Lon ~= GPS.PrevLon) then
			if (GPS.LatHome ~= 0) and  (GPS.LonHome ~= 0) then 
				-- SPEED / ALTITUDE
				if Armed then
					if Speed.current > Speed.max then Speed.max = Speed.current end
					if Altitude.current > Altitude.max then Altitude.max = Altitude.current end
				end
				-- DISTANCE HOME
				DistHome.current = rnd(calc_Distance(GPS.Lat, GPS.Lon, GPS.LatHome, GPS.LonHome),3)
				if (DistHome.current > DistHome.max) and DistHome.current ~= nil then
					DistHome.max = DistHome.current
				end				
				DistHome.current = string.format("%.3f",DistHome.current)
				
				-- DISTANCE TRIP
				if (GPS.PrevLat ~= 0) and  (GPS.PrevLon ~= 0) and (GPS.Lat ~= 0) and  (GPS.Lon ~= 0)then	
					TotalDist =  rnd(tonumber(TotalDist) + calc_Distance(GPS.Lat,GPS.Lon,GPS.PrevLat,GPS.PrevLon),5) 
					TotalDist = string.format("%.3f",TotalDist)					
				end
			end
			GPS.PrevLat = GPS.Lat
			GPS.PrevLon = GPS.Lon
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
	lcd.drawText(60,1,Flightmode.current ,SMLSIZE + INVERS)
	lcd.drawText(90,1,tostring(Armed) ,SMLSIZE + INVERS)
	lcd.drawText(2,9, "Sats:", SMLSIZE)	
	lcd.drawText(30,9, Sats.current, SMLSIZE)
	lcd.drawText(60,9, "Armed:", SMLSIZE)
	lcd.drawText(90,9, string.sub(100 + math.floor((Timer/100)/60),2)..":"..string.sub(100+math.floor(math.fmod((Timer/100),60)),2), SMLSIZE)
	lcd.drawText(2,23, "Trip:", SMLSIZE)
	lcd.drawText(30,23, TotalDist, SMLSIZE)
	lcd.drawText(2,16, "Home:", SMLSIZE)
	lcd.drawText(30,16, string.format("%.5f", GPS.LatHome) .. " / " .. string.format("%.5f", GPS.LonHome), SMLSIZE)
	lcd.drawText(2,30, "Speed:", SMLSIZE)
	lcd.drawText(30,30, Speed.current,SMLSIZE)
	lcd.drawText(62,30, "max:", SMLSIZE)
	lcd.drawText(90,30, Speed.max,SMLSIZE)
	lcd.drawText(2,37, "Alt:", SMLSIZE)
	lcd.drawText(30,37, Altitude.current,SMLSIZE)
	lcd.drawText(62,37, "max:", SMLSIZE)
	lcd.drawText(90,37, Altitude.max,SMLSIZE)
	lcd.drawText(2,44, "DtH:", SMLSIZE)
	lcd.drawText(30,44, DistHome.current, SMLSIZE)
	lcd.drawText(62,44, "max:", SMLSIZE)
	lcd.drawText(90,44, DistHome.max, SMLSIZE)
	lcd.drawText(2,51, "Bat:", SMLSIZE)
	lcd.drawText(30,51, string.format("%.2f",Battery.current), SMLSIZE)
	lcd.drawText(62,51, "min:", SMLSIZE)
	lcd.drawText(90,51, string.format("%.2f",Battery.min), SMLSIZE)
	lcd.drawText(27,58, string.sub(100+DateTime["day"],2).."."..string.sub(100+DateTime["mon"],2).."."..string.sub(DateTime["year"],3).." - "..string.sub(100+DateTime["hour"],2)..":"..string.sub(100+DateTime["min"],2), SMLSIZE)

    -- BLINK IF LOW SATS
	if (tonumber(Sats.current) < 6) then
		lcd.drawText(60,23, "< 6 SATS!", SMLSIZE + INVERS + BLINK)
	end
		
	-- BLINK IF NO TELEMETRY
	if Connected == false then
		lcd.drawText(60,23, "NO TELEMETRY!", SMLSIZE + INVERS + BLINK)		
	end	
end
 
return {init=init, run=run, background=background}
