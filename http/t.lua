function setup(pin)
    local count = 0
    local rom
    --locat ret = 0
    local tbl = {}
    ow.setup(pin)
    repeat
        tmr.wdclr()
        count = count + 1
        ow.reset_search(pin)
        rom = ow.search(pin)
--print("count=",count,"type rom=",type(rom))
    until((rom ~= nil) or (count > 100))
    
    if (rom == nil) then
        --print("No more devices.")
        --ret = 1
        
    else
--print("count=",count)
        print("Device type, serial,crc: "..string.format("%02x-%02x%02x%02x%02x%02x%02x-%02x",rom:byte(1,8)))
        crc = ow.crc8(string.sub(rom,1,7))
--print("CRC="..string.format("%02x %02x",rom:byte(8),crc))
        if (crc == rom:byte(8)) then
            if ((rom:byte(1) == 0x10) or (rom:byte(1) == 0x28)) then
                --print("Device is a DS18x20 family device.")
                tbl[#tbl+1]=rom
                --ret = 0
            else
                --print("Device family is not recognized.")
                --ret = 2
                
            end
        else
            --print("CRC is not valid!")
            --ret = 3
            
        end
    end
    --return ret
    return tbl
end

format_addr = function(a)
    return ("%02x-%02x%02x%02x%02x%02x%02x"):format(
        a:byte(1),
        a:byte(7), a:byte(6), a:byte(5),
        a:byte(4), a:byte(3), a:byte(2)
      )
  end

function readT(pin,callback)
    --call setup, prepare all sensors
    local tbl = setup(pin)
print("tbl=",#tbl)
    local r = {}
    -- conversion command for all
    ow.reset(pin)
    ow.skip(pin)
    ow.write(pin, 0x44, 1)
    -- wait a bit
--    tmr.alarm(5, 100, 0, function()
    -- iterate over devices
--	local r = {}
        for i = 1, #tbl do
    	    tmr.wdclr()
        -- read rom command
print("trying to read")
    	    ow.reset(pin)
    	    ow.select(pin, tbl[i])
    	    ow.write(pin, 0xBE, 1)
        -- read data
    	    local x = ow.read_bytes(pin, 9)
for i=1,9 do print(string.format("%X",x:byte(i))) end
    	    if ow.crc8(x) == 0 then
        	local t = (x:byte(1) + x:byte(2) * 256)
print("t=",t)
          -- negatives?
        	if bit.isset(t, 15) then t = 1 - bit.bxor(t, 0xffff) end
          -- NB: temperature in Celsius * 10^4
        	    t = t * 625
          -- NB: due 850000 means bad pullup. ignore
          --if t ~= 850000 then
        	    if t <= 850000 then
        		r[format_addr(tbl[i])] = t/10000
print("r=",#r)
            --r[tbl[i]]=t
        	    end
        	    tbl[i] = nil
    		end
    	    end
	callback(r)
--    end)
    --return(r)
end

return function (connection, args)
--    collectgarbage()
    connection:send("HTTP/1.0 200 OK\r\nContent-Type: text/html\r\nCache-Control: private, no-store\r\n\r\n")
    connection:send("<html><head><body><title>T</title></head><body>OK</body></html>\n")
--    coroutine.yield()
    readT(4, function(r) for k,v in pairs(r) do print (k,string.format("%.3f",v)) end end)
    coroutine.yield()
end
