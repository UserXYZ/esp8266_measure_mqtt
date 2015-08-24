local M

-- String module
--local string = string
-- One wire module
--local ow = ow
-- Timer module
--local tmr = tmr

-- extra overloads
--local bit = bit
--local print = print
--local type = type

-- code begin

local function setup(pin)
    local count = 0
    local rom
    --locat ret = 0
    tbl = {}
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
        --print("Device type, serial,crc: "..string.format("%02x-%02x%02x%02x%02x%02x%02x-%02x",rom:byte(1,8)))
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
end

local format_addr = function(a)
    return ("%02x-%02x%02x%02x%02x%02x%02x"):format(
        a:byte(1),
        a:byte(7), a:byte(6), a:byte(5),
        a:byte(4), a:byte(3), a:byte(2)
      )
  end

local function readT(pin, callback)
    local ow = require("ow")
    --call setup, prepare all sensors
    setup(pin)

    -- conversion command for all
    ow.reset(pin)
    ow.skip(pin)
    ow.write(pin, 0x44, 1)
    -- wait a bit
    tmr.alarm(0, 100, 0, function()
    -- iterate over devices
      local r = {}
      for i = 1, #tbl do
        tmr.wdclr()
        -- read rom command
        ow.reset(pin)
        ow.select(pin, tbl[i])
        ow.write(pin, 0xBE, 1)
        -- read data
        local x = ow.read_bytes(pin, 9)
        if ow.crc8(x) == 0 then
          local t = (x:byte(1) + x:byte(2) * 256)
          -- negatives?
          if bit.isset(t, 15) then t = 1 - bit.bxor(t, 0xffff) end
          -- NB: temperature in Celsius * 10^4
          t = t * 625
          -- NB: due 850000 means bad pullup. ignore
          --if t ~= 850000 then
          if t <= 850000 then
            r[format_addr(tbl[i])] = t/10000
            --r[tbl[i]]=t
          end
          tbl[i] = nil
        end
      end
      callback(r)
    end)
end

--[[
-- working implementation, only for one sensor per pin
function readT2(pin)
        ow.setup(pin)
        -- force first measurement
        --ow.reset(pin)
        --ow.skip(pin)
        --ow.write(pin, 0x44,1)  
        -- read scratchpad
        ow.reset(pin)
        ow.skip(pin)
        ow.write(pin, 0xBE, 1)

        data = nil
        data = ""
        for i = 1, 2 do
            data = data .. string.char(ow.read(pin))
        end
        t = (data:byte(1) + data:byte(2) * 256) / 16
        if (t>100) then
            t=t-4096
        end
        
        ow.reset(pin)
        ow.skip(pin)
        ow.write(pin, 0x44,1)  

        return t          
end
--]]

-- Return module table
  -- expose
  M = {
    readT = readT,
  }
return M
