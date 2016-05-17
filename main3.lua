-- main file V3
--[[ timers used
6 - for measurement
5 - for NTP
]]--
local conf = require("config")
-- get DST
local tz=nil
tmr.wdclr()
tmr.alarm(4,5000,1,function()
    local dst=require("getDST")
    print("Trying to get DST for "..conf.misc.zone)
	dst.getDST(function (p)
--        while not p do
		    if type(p) == "string" then
			    print ("Error: "..p)
		    elseif type(p) == "number" then
--print(p)
			    tz=p
                print("Got DST: "..tz.."h")
                tmr.stop(4)
		    else
			    print("Error getting DST, using default value of 0 (same as UTC)...")
			    tz=0
		    end
--	    end
    end)
    dst=nil
    package.loaded["getDST"] = nil
    collectgarbage()
end)
-- get start time
local ntp=require("myNtpTime")
local d=require("dns")
d.resolveIP("pool.ntp.org",function(r)
    if r then
        ntp.sync(r,tz,function(tm)
            if tm then print("Start time is:",tm) end
        end)
    end
end)
d=nil
package.loaded["dns"] = nil
collectgarbage()
-- start ntp polling
tmr.wdclr()
tmr.alarm(5,conf.misc.ntpsleep*1000,1,function()
	local d=require("dns")
	d.resolveIP("pool.ntp.org",function(r)
        if r then
            ntp.sync(r,tz,function(tm)
                if tm then print("NTP time sync at:",tm) end
            end)
        end
    end)
    d=nil
    package.loaded["dns"] = nil
    collectgarbage()
end)
-- connect to mqtt broker
if conf.mqtt.use then
	mq=require("message3")
	client=mq.setup()
end
if conf.emon.use then
	emon=require("myemoncms")
end
-- start measurement and data sending
local delay=conf.misc.delay*1000
if delay < 60000 or delay > 3600000 then
	print("Measurement timeout out of bounds, defaulting to 60s")
	delay=60000
else
	print("Starting measurement every "..conf.misc.delay.." second(s)")
end
tmr.wdclr()
tmr.alarm(6, delay,1,function()
-- start DS18B20 measuring and putting results into its global table
if conf.sens.ds_enable then
	local dstemp=require("myds3")
	ds_table={}
	print("Starting measurement with DS18B20")
	dstemp.readT(conf.misc.ds_pin,function(r)
    	for k,v in pairs(r) do
       		ds_table[k]=v
		end
	end)
	dstemp=nil
	package.loaded["myds3"] = nil
	collectgarbage()
end
-- start DHT22 measuring and putting results into its global table
if conf.sens.dht_enable then
	print("Starting measurement with DHT22")
	local status,temp,humi,temp_decimal,humi_decimal = dht.read(conf.sens.dht_pin)
	if( status == dht.OK ) then
		dht_table = {string.format("%.2f",temp),string.format("%.2f",humi)}
	elseif( status == dht.ERROR_CHECKSUM ) then
		print( "DHT Checksum error." );
	elseif( status == dht.ERROR_TIMEOUT ) then
		print( "DHT Time out." );
	end
end
-- start BMP180 measuring and putting results into its global table
if conf.sens.bmp_enable then
	print("Starting measurement with BMP180")
	bmp085.init(conf.sens.bmp_sda,conf.sens.bmp_scl)
	local t=string.format("%.2f",bmp085.temperature()/10)
	local p=string.format("%.2f",bmp085.pressure(3)/100)
	local al=string.format("%.2f",(bmp085.pressure(3)-101325)*843/10000)
	bmp_table = {t,p,al}
end
-- start sending data for all sensors
print("Sending data at:",ntp.getTime(tz))
collectgarbage()
--print("main2-1:",node.heap())
-- start sending data
	-- send ds18b20 data
	if conf.sens.ds_enable then
		for a,b in pairs(ds_table) do
			local json=nil
			local val=string.format("%.2f",b)
			if conf.mqtt.use then -- send to mqtt broker
				local t=ntp.getTime(tz)
				json=cjson.encode({time=t, sensor=a, ds_temp=val})
				mq.msgSend(client, conf.mqtt.topic.."/sensors/ds18b20", json)
			end
			if conf.emon.use then -- send to emoncms
				json=cjson.encode({sensor=a, ds_temp=val})
				emon.send(json)
			end
		end
		ds_table=nil
	end
	-- send dht22 data
	if conf.sens.dht_enable then
			local json=nil
			if conf.mqtt.use then -- send to mqtt broker
				local t=ntp.getTime(tz)
				json=cjson.encode({time=t, dht_temp=dht_table[1], humidity=dht_table[2]})
				mq.msgSend(client, conf.mqtt.topic.."/sensors/dht22", json)
			end
			if conf.emon.use then -- send to emoncms
				json=cjson.encode({dht_temp=dht_table[1], humidity=dht_table[2]})
				emon.send(json)
			end
			dht_table=nil
	end
	-- send bmp180 data
	if conf.sens.bmp_enable then
			local json=nil
			local t=ntp.getTime(tz)
			if conf.mqtt.use then -- send to mqtt broker
				json=cjson.encode({time=t, bmp_temp=bmp_table[1], pressure=bmp_table[2], alt=bmp_table[3]})
				mq.msgSend(client, conf.mqtt.topic.."/sensors/bmp180", json)
			end
			if conf.emon.use then -- send to emoncms
				json=cjson.encode({bmp_temp=bmp_table[1], pressure=bmp_table[2], alt=bmp_table[3]})
				emon.send(json)
			end
			bmp_table=nil
	end
-- clean all temporary data structures
	collectgarbage()
    collectgarbage()
--print("main2-2:",node.heap())
end) -- end timer
