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

-- initialize RTC
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
-- translate day number to text date or vice versa
local function getDay(day)
    local days = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}
    if type(day) == "number" and day<8 and day>0 then
        return days[day]
    elseif type(day) == "string" then
        for k,v in ipairs(days) do
            if string.lower(v) == string.tolower(day) then
                return k
            else
                return nil
            end
        end
    else
        return nil
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
-- return full date and time in human readable form
local function getTimeFull()
    local second, minute, hour, day, date, month, year = getTime()
    year = year+2000
    return string.format("%02d:%02d:%02d", hour, minute, second), getDay(day), string.format("%02d.%02d.%04d", date, month, year)
end
--set time to RTC
local function setTimeFull(hour, minute, second, day, date, month, year)
    if type(day) == string then
        day = getDay(day)
    end
    if string.len(tostring(year)) == 4 then
        year = year-2000
    end
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
--[[
local function setTimeDate(...)
    -- should accept any number of arguments and differentiate on separator
    -- if given aa:bb or aa:bb:cc, treat as time
    -- if given aa.bb.cc od aa.bb.cccc or aa/bb/cc or aa/bb/cccc treat as date
    -- combination of both should also work
    --if arg[n] == 0 then return nil end
    --function f(...) for k,v in ipairs(arg) do print(k,v) end end
    
    s = "hello world from Lua"
    for w in string.gmatch(s, "%a+") do
        print(w)
    end
    
end
]]--
local function setTime(h, m, ...)
    local second, minute, hour, day, date, month, year = getTime()
    if #arg == 0 then -- only hour and minute given
        hour = h
        minute = m
    elseif #arg == 1 then -- hour, minute, seconds given
        hour = h
        minute = m
        second = arg[1]
    else
        print("Wrong time format")
        return nil
    end
    setTimeFull(hour, minute, second, day, date, month, year)
end

local function setDate(d, m, y)
    local second, minute, hour, day, date, month, year = getTime()
    if string.len(tostring(y)) == 2 then
        y = y+2000
    end
    setTimeFull(second, minute, hour, day, d, m, y)
end
-- Return module table
M = {
    setup = setup,
    setTimeFull = setTimeFull,
    getTime = getTime,
    getTimeFull = getTimeFull, 
    setDate = setDate, 
    setTime = setTime
}
return M
