-- DS1307, DS3231 RTC clock driver module
local M = {}
-- Default value for i2c communication
local id = 0
--device address
local dev_addr = nil

local function decToBcd(val)
  return((((val/10) - ((val/10)%1)) *16) + (val%10))
end
 
local function bcdToDec(val)
  return((((val/16) - ((val/16)%1)) *10) + (val%16))
end

-- initialize i2c
local function setup(sda, scl, addr)
    if sda~=nil and scl~=nil and addr~=nil then
        if (i2c.setup(id, sda, scl, i2c.SLOW)) ~= 0 then
            print("RTC configured")
            dev_addr = addr
        else
            print("RTC config failed!")
            return nil
        end
    else
        print("Wrong RTC parameters!")
    end
end

--get time from RTC
local function getTime()
  i2c.start(id)
  i2c.address(id, dev_addr, i2c.TRANSMITTER)
  i2c.write(id, 0x00)
  i2c.stop(id)
  i2c.start(id)
  i2c.address(id, dev_addr, i2c.RECEIVER)
  local c=i2c.read(id, 7)
  i2c.stop(id)
  return bcdToDec(tonumber(string.byte(c, 1))),
  bcdToDec(tonumber(string.byte(c, 2))),
  bcdToDec(tonumber(string.byte(c, 3))),
  bcdToDec(tonumber(string.byte(c, 4))),
  bcdToDec(tonumber(string.byte(c, 5))),
  bcdToDec(tonumber(string.byte(c, 6))),
  bcdToDec(tonumber(string.byte(c, 7)))
end

local function getTimeFull()
    second, minute, hour, day, date, month, year = getTime()
    year = year+2000
    days = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}
    return string.format("%02d:%02d:%02d", hour, minute, second), days[day], string.format("%02d.%02d.%04d", date, month, year)
end

--set time to RTC
local function setTimeFull(hour, minute, second, day, date, month, year)
  i2c.start(id)
  i2c.address(id, dev_addr, i2c.TRANSMITTER)
  i2c.write(id, 0x00)
  i2c.write(id, decToBcd(second))
  i2c.write(id, decToBcd(minute))
  i2c.write(id, decToBcd(hour))
  i2c.write(id, decToBcd(day))
  i2c.write(id, decToBcd(date))
  i2c.write(id, decToBcd(month))
  i2c.write(id, decToBcd(year))
  i2c.stop(id)
end

local function setTime(...)
    --if arg[n] == 0 then return nil end
    --function f(...) for k,v in ipairs(arg) do print(k,v) end end
    for k,v in ipairs(arg) do
        
    end
end
-- Return module table
M = {
    setup = setup,
    setTimeFull = setTimeFull,
    getTime = getTime,
    getTimeFull = getTimeFull
}
return M
