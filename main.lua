-- main file
--[[ timers used
6 - for DS18B20 measurement
5 - for DHT22 measurement
4 - for BPM180 measurement
3 - for data sending/receiving
2 - free
1 - free
0 - free
]]--
local conf = require("config")
-- start DS18B20 measuring and putting results into its global table
if conf.sens.ds_enable then
	local dstemp=require("myds3")
	ds_table={}
	local ds_delay=conf.sens.ds_wait*1000
	if ds_delay < 60000 or ds_delay > 3600000 then
		print("DS18B20 measuring timeout out of bounds, defaulting to 60s")
		ds_delay=60000
	else
		print("Starting measurement with DS18B20 every "..conf.sens.ds_wait.." second(s)")
	end

	tmr.wdclr()
	tmr.alarm(6, ds_delay,1,function()
		dstemp.readT(conf.misc.ds_pin,function(r)
    		for k,v in pairs(r) do
        		ds_table[k]=v
			end
		end)
	end)
end
-- start DHT22 measuring and putting results into its global table
if conf.sens.dht_enable then
	dht_table={}
	local dht_delay=conf.sens.dht_wait*1000
	if dht_delay < 60000 or dht_delay > 3600000 then
		print("DHT22 measuring timeout out of bounds, defaulting to 60s")
		dht_delay=60000
	else
		print("Starting measurement with DHT22 every "..conf.sens.dht_wait.." second(s)")
	end

	tmr.wdclr()
	tmr.alarm(5,dht_delay,1,function()
print("starting dht22 measuring")
		local status,temp,humi,temp_decimal,humi_decimal = dht.read(conf.sens.dht_pin)
		if( status == dht.OK ) then
			--print("DHT Temperature:"..temp.."; ".."Humidity:"..humi,"")
			dht_table = {temp,humi}
		elseif( status == dht.ERROR_CHECKSUM ) then
			print( "DHT Checksum error." );
		elseif( status == dht.ERROR_TIMEOUT ) then
			print( "DHT Time out." );
		end
	end)

end
-- start BMP180 measuring and putting results into its global table
if conf.sens.bmp_enable then
	bmp_table={}
	local bmp_delay=conf.sens.bmp_wait*1000
	if bmp_delay < 60000 or bmp_delay > 3600000 then
		print("BMP180 measuring timeout out of bounds, defaulting to 60s")
		bmp_delay=60000
	else
		print("Starting measurement with BMP180 every "..conf.sens.bmp_wait.." second(s)")
	end

	tmr.wdclr()
	tmr.alarm(4,bmp_delay,1,function()
print("starting bmp180 measuring")
        bmp085.init(conf.sens.bmp_sda,conf.sens.bmp_scl)
		local t=string.format("%.2f",bmp085.temperature()/10)
		local p=string.format("%.2f",bmp085.pressure(3)/100)
		local al=string.format("%.2f",(bmp085.pressure(3)-101325)*843/10000)
		bmp_table = {t,p,al}
	end)
end
-- connect to mqtt broker
if conf.mqtt.use then
	mq=require("message2")
	local client=mq.setup()
end
if conf.emon.use then
	emon=require("myemoncms")
end
-- start sending data for all sensors
local mdelay=conf.misc.delay*1000
if mdelay < 60000 or mdelay > 3600000 then
	print("Data sending period out of bounds, defaulting to 60s")
	mdelay=60000
else
	print("Starting sending data every "..conf.misc.delay.." second(s)")
end
-- get time
local ntp=require("myNtpTime")
local d=require("dns")
--get start time
d.resolveIP("pool.ntp.org",function(r)
    if r then
        ntp.sync(r,conf.misc.tz,function(tm)
            if tm then
                print("start time is:",tm)
            end
        end)
    end
end)
-- start ntp polling
tmr.wdclr()
tmr.alarm(2,conf.misc.ntpsleep*1000,1,function()
    d.resolveIP("pool.ntp.org",function(r)
        if r then
            ntp.sync(r,conf.misc.tz,function(tm)
                if tm then
                    --print(cjson.encode({time=tm}))
                    print("NTP time sync at",tm)
                end
            end)
        end
    end)
end)
-- start work
tmr.wdclr()
tmr.alarm(3,mdelay,1,function()
	-- send ds18b20 data
	if conf.sens.ds_enable then
		for a,b in pairs(ds_table) do
			local json=nil
			local val=string.format("%.2f",b)
			if conf.mqtt.use then -- send to mqtt broker
				local t=ntp.getTime(conf.misc.tz)
				json=cjson.encode({time=t, sensor=a, ds_temp=val})
				mq.msgSend(client, conf.mqtt.topic.."/sensors/ds18b20", json)
			end
			if conf.emon.use then -- send to emoncms
				json=cjson.encode({sensor=a, ds_temp=val})
				emon.send(json)
			end
		end
	end
	-- send dht22 data
	if conf.sens.dht_enable then
			local json=nil
			if conf.mqtt.use then -- send to mqtt broker
				local t=ntp.getTime(conf.misc.tz)
				json=cjson.encode({time=t, dht_temp=dht_table[1], humidity=dht_table[2]})
				mq.msgSend(client, conf.mqtt.topic.."/sensors/dht22", json)
			end
			if conf.emon.use then -- send to emoncms
				json=cjson.encode({dht_temp=dht_table[1], humidity=dht_table[2]})
				emon.send(json)
			end
	end
	-- send bmp180 data
	if conf.sens.bmp_enable then
			local json=nil
			local t=ntp.getTime(conf.misc.tz)
			if conf.mqtt.use then -- send to mqtt broker
				json=cjson.encode({time=t, bmp_temp=bmp_table[1], pressure=bmp_table[2], alt=bmp_table[3]})
				mq.msgSend(client, conf.mqtt.topic.."/sensors/bmp180", json)
			end
			if conf.emon.use then -- send to emoncms
				json=cjson.encode({bmp_temp=bmp_table[1], pressure=bmp_table[2], alt=bmp_table[3]})
				emon.send(json)
			end
	end
	collectgarbage("collect")
end)
