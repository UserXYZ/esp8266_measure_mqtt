-- main file V3
--[[ timers used
6 - for measurement and data sending
5 - for NTP
4 - for DST, stops on acquiring DST
3 - for data display, if enabled
]]--
local conf = require("config")

if conf.misc.use_display then
    display = require("display")
    -- if display output is enabled,store all sensor names and values in the array
    darr = {}
end
-- get DST
local tz=0
local cnt=0
tmr.wdclr()
tmr.alarm(4,5000,1,function()
	local dst=require("getDST")
	local msg=print("Trying to get DST for "..conf.misc.zone)
	print(msg)
	if conf.misc.use_display then
		display.disp_stat(msg)
	end
	dst.getDST(function (p)
			cnt=cnt+1
			if cnt == 5 then
				tmr.stop(4)
				msg="Error getting DST, using default value of 0 (same as UTC)..."
				print(msg)
				if conf.misc.use_display then
				    display.disp_stat(msg)
				end
				cnt=nil
				tz=0
			end
		    if type(p) == "string" then
			    print ("Error: "..p)
		    elseif type(p) == "number" then
			    tz=p
			    msg="Got DST: "..tz.."h"
			    print(msg)
			    if conf.misc.use_display then
				    display.disp_stat(msg)
			    end
			    cnt=nil
			    tmr.stop(4)
		    else
			    msg="Error getting DST, using default value of 0 (same as UTC)..."
			    print(msg)
			    if conf.misc.use_display then
				    display.disp_stat(msg)
			    end
			    tz=0
		    end
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
            if tm then
        	    local msg="Start time is: "..tm
        	    print(msg)
        	    if conf.misc.use_display then
		            display.disp_stat(msg)
		    end
    	    end
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
		        if tm then
			        local msg="NTP time sync at: "..tm
			        print(msg)
			        if conf.misc.use_display then
			            display.disp_stat(msg)
			        end
		        end
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
	local msg="Starting measurement every "..conf.misc.delay.." second(s)"
	print(msg)
	if conf.misc.use_display then
	    display.disp_stat(msg)
	end
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
		print("DHT Checksum error.");
	elseif( status == dht.ERROR_TIMEOUT ) then
		print("DHT Time out.");
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
-- start sending data
	-- send ds18b20 data
	if conf.sens.ds_enable then
		if conf.misc.use_display then
		    ds_disp={}
		end
		for a,b in pairs(ds_table) do
			local json=nil
			local val=string.format("%.2f",b)
			-- add for display
			ds_disp[a]=val
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
		if conf.misc.use_display then
			darr["DS18B20"]=ds_disp
			ds_disp=nil
		end
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
			if conf.misc.use_display then
				darr["DHT22"]=dht_table
				dht_disp=nil
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
			if conf.misc.use_display then
				darr["BMP180"]=bmp_table
			end
			bmp_table=nil
	end
-- clean all temporary data structures
	collectgarbage()
end) -- end timer
-- send to display if enabled
--[[
tmr.wdclr()
tmr.alarm(3, 1000,1,function()
-- display
end
]]--
