-- prepare files
local compileAndRemoveIfNeeded = function(f)
   if file.open(f) then
      file.close()
      print('Compiling:', f)
      node.compile(f)
      file.remove(f)
      collectgarbage()
   end
end
-- main()
local serverFiles = {'message2.lua', 'myds3.lua', 'base64dec.lua', 'bmp085.lua', 'myNetTime.lua', 'httpserver.lua', 'httpserver-basicauth.lua', 'config.lua', 'httpserver-request.lua', 'httpserver-static.lua', 'httpserver-header.lua', 'httpserver-error.lua'}
for i, f in ipairs(serverFiles) do
    compileAndRemoveIfNeeded(f)
end

compileAndRemoveIfNeeded = nil
serverFiles = nil
collectgarbage()
-- start configuration
conf = dofile("config.lc")
local wifiConfig = {}
wifiConfig.mode = wifi.STATION
wifiConfig.stationPointConfig = {}
wifiConfig.stationPointConfig.ssid = conf.wlan.ssid
wifiConfig.stationPointConfig.pwd =  conf.wlan.pwd

wifi.setmode(wifiConfig.mode)
print('set (mode='..wifi.getmode()..')')
print('MAC: ',wifi.sta.getmac())
print('chip: ',node.chipid())
print('heap: ',node.heap())

wifi.sta.config(wifiConfig.stationPointConfig.ssid, wifiConfig.stationPointConfig.pwd)
wifiConfig = nil
collectgarbage()

local joinCounter = 0
local joinMaxAttempts = 20
tmr.alarm(1, 5000, 1, function()
   local ip = wifi.sta.getip()
   if ip == nil and joinCounter < joinMaxAttempts then
      print('Connecting to WiFi Access Point ...')
      joinCounter = joinCounter +1
   else
      if joinCounter == joinMaxAttempts then
         print('Failed to connect to WiFi Access Point.')
      else
         print('Got IP: ',ip)
         -- Uncomment to automatically start the server in port 80
         --dofile("httpserver.lc")(8008)
      end
      tmr.stop(1)
      joinCounter = nil
      joinMaxAttempts = nil
      collectgarbage()
   end
end)
--[[ timer used
6 - for DS18B20 measurement
5 - for DHT22 measurement
4 - for BPM180 measurement
3 - for MQTT data sending/receiving
2 - free
1 - free
0 - free
--[[
-- start DS18B20 measuring and putting results into its global table
if conf.sens_ds then
	local dstemp=require("myds3")
	ds_tab={}
	local ds_delay=conf.sens.ds_wait*1000
	if ds_delay < 2000 or ds_delay > 3600000 then
		print("DS18B20 measuring timeout out of bounds, defaulting to 60s")
		ds_delay=60000
	else
		print("Starting measurement with DS18B20 every "..conf.sens.ds_wait.." second(s)")
	end

	tmr.wdclr()
	tmr.alarm(6, ds_delay,1,function()
		dstemp.readT(conf.misc.ds_pin,function(r)
    		for k,v in pairs(r) do
        		ds_tab[k]=v
			end
		end)
	end)
end
-- start DHT22 measuring and putting results into its global table
if conf.sens_dht then

end
-- start DHT22 measuring and putting results into its global table
if conf.sens_dht then
	dht_tab={}
	local dht_delay=conf.sens.dht_wait*1000
	if dht_delay < 2000 or dht_delay > 3600000 then
		print("DHT22 measuring timeout out of bounds, defaulting to 60s")
		dht_delay=60000
	else
		print("Starting measurement with DHT22 every "..conf.sens.dht_wait.." second(s)")
	end

	tmr.wdclr()
	tmr.alarm(5,dht_delay,1,function()
		local status,temp,humi,temp_decimal,humi_decimal = dht.read(conf.sens.dht_pin)
		if( status == dht.OK ) then
			print("DHT Temperature:"..temp.."; ".."Humidity:"..humi,"")
		elseif( status == dht.ERROR_CHECKSUM ) then
			print( "DHT Checksum error." );
		elseif( status == dht.ERROR_TIMEOUT ) then
			print( "DHT Time out." );
		end
	end)

end
-- start BMP180 measuring and putting results into its global table
if conf.sens_bmp then
	bmp_tab={}
	local bmp_delay=conf.sens.bmp_wait*1000
	if bmp_delay < 2000 or bmp_delay > 3600000 then
		print("BMP180 measuring timeout out of bounds, defaulting to 60s")
		bmp_delay=60000
	else
		print("Starting measurement with BMP180 every "..conf.sens.bmp_wait.." second(s)")
	end
	bmp085.init(conf.sens.bmp_sda,conf.sens.bmp_scl)

	tmr.wdclr()
	tmr.alarm(4,bmp_delay,1,function()
		local t=string.format("%.2f",bmp085.temperature()/10)
		local p=string.format("%.2f",bmp085.pressure(3)/100)
		local al=string.format("%.2f",(p-101325)*843/10000)
		bmp_tab = {t,p,al}
end

-- start sending mqtt data
local mq=require("message2")
local mdelay=conf.mqtt.delay*1000
if mdelay < 5000 or mdelay > 3600000 then
	print("MQTT delay out of bounds, defaulting to 60s")
	mdelay=60000
else
	print("Starting sending MQTT data every "..conf.mqtt.delay.." second(s)")
end
local client=mq.setup()
-- start sending mqtt data for all sensors
tmr.wdclr()
tmr.alarm(3,mdelay,1,function()
	for a,b in pairs(ds_tab) do
		local val=string.format("%.2f",b)
		f.msgSend(client, conf.mqtt.topic.."/sensors/ds", cjson.encode({sensor=a, temp=val}))
	end
	for i=1,#bmp_tab do
		f.msgSend(client, conf.mqtt.topic.."/sensors/bmp180",cjson.encode({temp=bmp_tab[i], pressure=bmp_tab[i+1], alt=bmp_tab[i+2]}))
		i=i+3
	end
end)

collectgarbage("collect")
]]--
