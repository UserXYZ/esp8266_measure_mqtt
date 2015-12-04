-- main file V2
--[[ timers used
6 - for measurement
5 - for NTP
]]--
local conf = require("config")
--get start time
local ntp=require("myNtpTime")
local d=require("dns")
d.resolveIP("pool.ntp.org",function(r)
    if r then
        ntp.sync(r,conf.misc.tz,function(tm)
            if tm then
                print("Start time is:",tm)
                collectgarbage()
            end
        end)
    end
end)
-- start ntp polling
tmr.wdclr()
tmr.alarm(5,conf.misc.ntpsleep*1000,1,function()
    d.resolveIP("pool.ntp.org",function(r)
        if r then
            ntp.sync(r,conf.misc.tz,function(tm)
                if tm then
                    print("NTP time sync at:",tm)
                    collectgarbage()
                end
            end)
        end
    end)
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
end
-- start DHT22 measuring and putting results into its global table
if conf.sens.dht_enable then
	print("Starting measurement with DHT22")
	local status,temp,humi,temp_decimal,humi_decimal = dht.read(conf.sens.dht_pin)
	if( status == dht.OK ) then
		dht_table = {temp,humi}
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
local t=ntp.getTime(conf.misc.tz)
print("Sending data at:",t)
t=nil
collectgarbage()

--print("main2-1:",node.heap())

-- start work
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
		ds_table=nil
		dstemp=nil
		t=nil
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
			dht_table=nil
			t=nil
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
			bmp_table=nil
			t=nil
	end
-- clean all temporary data structures
	json=nil
	collectgarbage()
    collectgarbage()

--print("main2-2:",node.heap())

end) -- end timer
