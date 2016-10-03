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
local tz = 0
local got_dst = false
local ntp = require("myNtpTime")
-- get time from ntp or rtc
function getTime()
    local rtc = nil
    if conf.misc.use_rtc then -- we chose to use rtc for all time readings
        if package.loaded["ds1307"] == nil then
	        rtc = require("ds1307")
	    end
	    -- if rtc.setup(conf.misc.rtc_sda, conf.misc.rtc_scl, conf.misc.rtc_addr) then -- rtc setup ok
		local s, m, h = rtc.getTime()
        t = string.format("%02d:%02d:%02d", h, m, s)
        if t then
		    package.loaded["ds1307"] = nil
		    collectgarbage()
	    else
	        t = ntp.getTime(tz)
	    end
    else -- we don't have/won't use rtc, use ntp query
	    t = ntp.getTime(tz)
    end
    return t
end
-- get DST
tmr.wdclr()
tmr.alarm(4, 5000, tmr.ALARM_AUTO, function()
    local cnt = 0
	local dst = require("getDST")
	printout("Trying to get DST for "..conf.misc.zone, 2)
	dst.getDST(function (p)
		cnt = cnt+1
		if cnt == 5 then
			printout("Error getting DST, using default value of 0 (same as UTC)...", 2)
			tz = 0
			tmr.stop(4)
			tmr.unregister(4)
			cnt = nil
			got_dst = true
		end
		if type(p) == "string" then
		    print ("Error: "..p)
		else
		    tz = p
		    printout("Got DST: "..tz.."h. Time is now: "..ntp.getTime(tz), 2)
		    tmr.stop(4)
		    tmr.unregister(4)
		    cnt = nil
		    got_dst = true
		end
        if conf.misc.use_rtc and got_dst then -- we want rtc
            local rtc = require("ds1307")
            if rtc.setup() then -- rtc setup ok
                local t = {}
                for i in string.gmatch(ntp.getTime(tz), "%d+") do table.insert(t, tonumber(i)) end
                rtc.setTime(t[1], t[2], t[3])
                package.loaded["ds1307"] = nil
                collectgarbage()
            end
        end
	-- clean a bit
        dst = nil
        package.loaded["getDST"] = nil
        collectgarbage()
	end)
end)
-- get start time
local d = require("dns")
d.resolveIP("pool.ntp.org",function(r)
    if r then
        ntp.sync(r, tz, function(tm)
            if tm then printout("Start time is: "..tm, 2) end
        end)
    end
end)
d = nil
package.loaded["dns"] = nil
collectgarbage()
-- start ntp polling
tmr.wdclr()
tmr.alarm(5, conf.misc.ntpsleep*1000, tmr.ALARM_AUTO, function()
	local d = require("dns")
	d.resolveIP("pool.ntp.org", function(r)
	    if r then
		    ntp.sync(r, tz, function(tm)
		        if tm then print("NTP time sync at: "..tm) end
		    end)
	    end
	end)
    d=nil
    package.loaded["dns"] = nil
    collectgarbage()
end)
-- connect to mqtt broker
if conf.mqtt.use then
	mq = require("message3")
	client = mq.setup()
end
if conf.emon.use then
	emon = require("myemoncms")
end
-- start measurement and data sending
local delay = conf.misc.delay*1000
if delay < 60000 or delay > 3600000 then
	print("Measurement timeout out of bounds, defaulting to 60s")
	delay = 60000
else
	printout("Starting measurement every "..conf.misc.delay.." second(s)", 2)
end
tmr.wdclr()
tmr.alarm(6, delay, tmr.ALARM_AUTO, function()
-- start DS18B20 measuring and putting results into its global table
    if conf.sens.ds_enable then
	    local dstemp = require("myds3")
	    ds_table = {}
	    if conf.misc.debug then print("Starting measurement with DS18B20") end
	    dstemp.readT(conf.misc.ds_pin, function(r)
    	    for k, v in pairs(r) do
       		    ds_table[k] = v
		    end
	    end)
	    dstemp = nil
	    package.loaded["myds3"] = nil
	    collectgarbage()
    end
-- start DHT22 measuring and putting results into its global table
    if conf.sens.dht_enable then
	    if conf.misc.debug then print("Starting measurement with DHT22") end
	    local status, temp, humi, temp_decimal, humi_decimal = dht.read(conf.sens.dht_pin)
	    if( status == dht.OK ) then
		    dht_table = {string.format("%.1f",temp), string.format("%.1f",humi)}
	    elseif( status == dht.ERROR_CHECKSUM ) then
		    print("DHT Checksum error.");
	    elseif( status == dht.ERROR_TIMEOUT ) then
		    print("DHT Time out.");
	    end
    end
-- start BMP180 measuring and putting results into its global table
    if conf.sens.bmp_enable then
	    if conf.misc.debug then print("Starting measurement with BMP180") end
	    bmp085.init(conf.sens.bmp_sda, conf.sens.bmp_scl)
	    local t = string.format("%.1f", bmp085.temperature()/10)
	    local p = string.format("%.1f", bmp085.pressure(3)/100)
	    local al = string.format("%.1f", (bmp085.pressure(3)-101325)*843/10000)
	    bmp_table = {t, p, al}
    end
-- start BME280 measuring and putting results into its global table
    if conf.sens.bme_enable then
	    if conf.misc.debug then print("Starting measurement with BME280") end
	    local i = bme280.init(conf.sens.bme_sda, conf.sens.bme_scl)
	    if i == 2 then -- sensor found, it is BME280
		    local H, T, P, D = nil
		    H, T = bme280.humi()
		    local h, t = string.format("%.1f", H/1000), string.format("%.1f", T/100)
		    P, T = bme280.baro()
		    local p = string.format("%.1f", P/1000)
		    -- local al = string.format("%.1f", (P-101325)*843/10000) -- calculated as for bmp180
		    D = bme280.dewpoint(H, T)
		    local d = string.format("%.1f", D/100)
		    -- bme_table = {h, t, p, al, d} -- humidity, temperature, pressure, altitude, dewpoint
		    bme_table = {h, t, p, d} -- humidity, temperature, pressure, dewpoint
	    else
		    print("BME280 not found.")
	    end
    end
-- start sending data for all sensors
    -- print("Sending data at:", ntp.getTime(tz))
    print("Sending data at:", getTime())
-- stop display timer so it can read fresh data and clear display data table
    if conf.display.use then
        local running, mode = tmr.state(3)
        if running then
            tmr.stop(3)
            for i = 1, #disp_data do disp_data[i] = nil end
            disp_data = nil
            disp_data = {}
        end
    end
collectgarbage()
-- start sending data
	-- send ds18b20 data
	if conf.sens.ds_enable then
		for a, b in pairs(ds_table) do
			local json = nil
			local val = string.format("%.1f", b)
            if conf.display.use then
                table.insert(disp_data, {a, "T", tostring(val)..string.char(176).."C"})
            end
			if conf.mqtt.use then -- send to mqtt broker
				-- local t = ntp.getTime(tz)
				local t = getTime()
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
				-- local t = ntp.getTime(tz)
				local t = getTime()
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
			-- local t = ntp.getTime(tz)
			local t = getTime()
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
	-- send bme280 data
	if conf.sens.bme_enable then
            if conf.display.use then
                table.insert(disp_data, {"BME280", "T", tostring(bme_table[2])..string.char(176).."C", "P", tostring(bme_table[3]).."mBar"})
            end
			local json = nil
			-- local t = ntp.getTime(tz)
			local t = getTime()
			if conf.mqtt.use then -- send to mqtt broker
				json = cjson.encode({time = t, humi = bme_table[1], temp = bme_table[2], pressure = bme_table[3], dew = bme_table[4]})
				mq.msgSend(client, conf.mqtt.topic.."/sensors/bme280", json)
			end
			if conf.emon.use then -- send to emoncms
				json = cjson.encode({humi = bme_table[1], temp = bme_table[2], pressure = bme_table[2], dew = bme_table[3]})
				emon.send(json)
			end
			bme_table = nil
	end
-- clean all temporary data structures
	collectgarbage()
    if conf.display.use then tmr.start(3) end -- start display timer if needed
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
		    printout(disp_data[nrec], 1)
                end
                nrec = nrec + 1
                if nrec > num then nrec = 1 end
            end
        end
        num=0
    end)
end
