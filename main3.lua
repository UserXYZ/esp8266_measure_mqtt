-- main file V3
--[[ timers used
6 - for measurement
5 - for NTP
4 - for DST
3 - for display
]]--
local conf = require("config")
if conf.display.use then
    disp_data={}
end

function writeout(msg, out)
    print(msg)
    if conf.display.use then
	if package.loaded["display2"] == nil then
	    display = require("display2")
	end
	if out == 2 then -- stderr like, status display
	    display.disp_stat(msg)
	elseif out == 1 then -- stdout like, data display
	    display.disp_data(msg)
	else
	    return
	end
	package.loaded["display2"] = nil
	display = nil
	collectgarbage()
    end
end

-- get DST
local tz=0
local got_dst=false
local ntp=require("myNtpTime")
tmr.wdclr()
tmr.alarm(4,5000,tmr.ALARM_AUTO,function()
    local cnt=0
	local dst=require("getDST")
	local msg=print("Trying to get DST for "..conf.misc.zone)
	print(msg)
	if conf.display.use then
		display.disp_stat(msg)
	end
	dst.getDST(function (p)
		cnt=cnt+1
		if cnt == 5 then
			msg="Error getting DST, using default value of 0 (same as UTC)..."
			print(msg)
			if conf.display.use then
			    display.disp_stat(msg)
			end
			tz=0
			tmr.stop(4)
			tmr.unregister(4)
			cnt=nil
			got_dst=true
		end
		if type(p) == "string" then
		    print ("Error: "..p)
		else
		    tz=p
		    msg="Got DST: "..tz.."h. Time is now: "..ntp.getTime(tz)
		    print(msg)
		    if conf.display.use then
			    display.disp_stat(msg)
		    end
		    tmr.stop(4)
		    tmr.unregister(4)
		    cnt=nil
		    got_dst=true
		end
	end)
	dst=nil
	package.loaded["getDST"] = nil
	collectgarbage()
end)
-- get start time
local d=require("dns")
d.resolveIP("pool.ntp.org",function(r)
    if r then
        ntp.sync(r,tz,function(tm)
            if tm then
        	    local msg="Start time is: "..tm
        	    print(msg)
        	    if conf.display.use then
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
tmr.alarm(5,conf.misc.ntpsleep*1000,tmr.ALARM_AUTO,function()
	local d=require("dns")
	d.resolveIP("pool.ntp.org",function(r)
        if r then
		    ntp.sync(r,tz,function(tm)
		        if tm then
			        local msg="NTP time sync at: "..tm
			        print(msg)
			        if conf.display.use then
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
	if conf.display.use then
	    display.disp_stat(msg)
	end
end
tmr.wdclr()
tmr.alarm(6, delay,tmr.ALARM_AUTO,function()
-- start DS18B20 measuring and putting results into its global table
    if conf.sens.ds_enable then
	    local dstemp=require("myds3")
	    ds_table={}
	    if conf.misc.debug then print("Starting measurement with DS18B20") end
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
	    if conf.misc.debug then print("Starting measurement with DHT22") end
	    local status,temp,humi,temp_decimal,humi_decimal = dht.read(conf.sens.dht_pin)
	    if( status == dht.OK ) then
		    dht_table = {string.format("%.1f",temp),string.format("%.1f",humi)}
	    elseif( status == dht.ERROR_CHECKSUM ) then
		    print("DHT Checksum error.");
	    elseif( status == dht.ERROR_TIMEOUT ) then
		    print("DHT Time out.");
	    end
    end
-- start BMP180 measuring and putting results into its global table
    if conf.sens.bmp_enable then
	    if conf.misc.debug then print("Starting measurement with BMP180") end
	    bmp085.init(conf.sens.bmp_sda,conf.sens.bmp_scl)
	    local t=string.format("%.1f",bmp085.temperature()/10)
	    local p=string.format("%.1f",bmp085.pressure(3)/100)
	    local al=string.format("%.1f",(bmp085.pressure(3)-101325)*843/10000)
	    bmp_table = {t,p,al}
    end
-- start sending data for all sensors
    print("Sending data at:",ntp.getTime(tz))
--"T",tostring(25.8)..string.char(176).."C", "P", tostring(1002.3).."mBar"
-- stop display timer so it can read fresh data and clear display data table
    if conf.display.use then
        local running, mode = tmr.state(3)
        if running then
            tmr.stop(3)
            for i=1,#disp_data do disp_data[i]=nil end
            disp_data=nil
            disp_data={}
        end
    end
collectgarbage()
-- start sending data
	-- send ds18b20 data
	if conf.sens.ds_enable then
		for a,b in pairs(ds_table) do
			local json = nil
			local val = string.format("%.1f", b)
            if conf.display.use then
                table.insert(disp_data,{a, "T", tostring(val)..string.char(176).."C"})
            end
			if conf.mqtt.use then -- send to mqtt broker
				local t = ntp.getTime(tz)
				json = cjson.encode({time=t, sensor=a, ds_temp=val})
				mq.msgSend(client, conf.mqtt.topic.."/sensors/ds18b20", json)
			end
			if conf.emon.use then -- send to emoncms
				json = cjson.encode({sensor = a, ds_temp = val})
				emon.send(json)
			end
		end
		ds_table = nil
	end
	-- send dht22 data
	if conf.sens.dht_enable then
            if conf.display.use then
                table.insert(disp_data, {"DHT22", "T", tostring(dht_table[1])..string.char(176).."C", "Hum", tostring(dht_table[2]).."%"})
            end
			local json = nil
			if conf.mqtt.use then -- send to mqtt broker
				local t = ntp.getTime(tz)
				json = cjson.encode({time = t, dht_temp = dht_table[1], humidity = dht_table[2]})
				mq.msgSend(client, conf.mqtt.topic.."/sensors/dht22", json)
			end
			if conf.emon.use then -- send to emoncms
				json = cjson.encode({dht_temp = dht_table[1], humidity = dht_table[2]})
				emon.send(json)
			end
			dht_table = nil
	end
	-- send bmp180 data
	if conf.sens.bmp_enable then
            if conf.display.use then
                table.insert(disp_data, {"BMP180", "T", tostring(bmp_table[1])..string.char(176).."C", "P", tostring(bmp_table[2]).."mBar"})
            end
			local json = nil
			local t = ntp.getTime(tz)
			if conf.mqtt.use then -- send to mqtt broker
				json = cjson.encode({time = t, bmp_temp = bmp_table[1], pressure = bmp_table[2], alt = bmp_table[3]})
				mq.msgSend(client, conf.mqtt.topic.."/sensors/bmp180", json)
			end
			if conf.emon.use then -- send to emoncms
				json = cjson.encode({bmp_temp = bmp_table[1], pressure = bmp_table[2], alt = bmp_table[3]})
				emon.send(json)
			end
			bmp_table = nil
	end
-- clean all temporary data structures
	collectgarbage()
    tmr.start(3)
end) -- end timer
-- start timer for data display, if display is enabled
if conf.display.use then
    local num = 0
    local nrec = 1
    tmr.wdclr()
    tmr.alarm(3, conf.display.timeout*1000, tmr.ALARM_AUTO, function()
        for i in pairs(disp_data) do
            if disp_data[i] ~= nil then num = num + 1 end
        end
        if num > 0 then
            if nrec <= num then
                for i in pairs(disp_data[nrec]) do
                    display.disp_data(disp_data[nrec])
                end
                nrec = nrec + 1
                if nrec > num then nrec = 1 end
            end
        end
        num=0
    end)
end
