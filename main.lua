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
conf = dofile("config.lua")
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
	bmp085.init(conf.sens.bmp_sda,conf.sens.bmp_scl)

	tmr.wdclr()
	tmr.alarm(4,bmp_delay,1,function()
		local t=string.format("%.2f",bmp085.temperature()/10)
		local p=string.format("%.2f",bmp085.pressure(3)/100)
		local al=string.format("%.2f",(p-101325)*843/10000)
		bmp_table = {t,p,al}
	end)
end
-- connect to mqtt broker
if conf.mqtt.use then
	local mq=require("message2")
	local mdelay=conf.mqtt.delay*1000
	if mdelay < 60000 or mdelay > 3600000 then
		print("MQTT delay out of bounds, defaulting to 60s")
		mdelay=60000
	else
		print("Starting sending MQTT data every "..conf.mqtt.delay.." second(s)")
	end
	local client=mq.setup()
end
-- start sending data for all sensors
tmr.wdclr()
tmr.alarm(3,mdelay,1,function()
	-- send ds18b20 data
	for a,b in pairs(ds_table) do
		local val=string.format("%.2f",b)
		local json=cjson.encode({sensor=a, temp=val})
		if conf.mqtt.use then -- send to mqtt broker
			mq.msgSend(client, conf.mqtt.topic.."/sensors/ds18b20", json)
		end
		if conf.emon.use then -- send to emoncms
			emon.send(json)
		end
	end
	-- send dht22 data
	for i=1,#dht_table do
		local json=cjson.encode({temp=dht_table[i], humidity=dht_table[i+1]})
		if conf.mqtt.use then -- send to mqtt broker
			mq.msgSend(client, conf.mqtt.topic.."/sensors/dht22", json)
		end
		if conf.emon.use then -- send to emoncms
			emon.send(json)
		end
		i=i+2
	end
	-- send bmp180 data
	for i=1,#bmp_table do
		local json=cjson.encode({temp=bmp_table[i], pressure=bmp_table[i+1], alt=bmp_table[i+2]})
		if conf.mqtt.use then -- send to mqtt broker
			mq.msgSend(client, conf.mqtt.topic.."/sensors/bmp180", json)
		end
		if conf.emon.use then -- send to emoncms
			emon.send(json)
		end
		i=i+3
	end
end)
