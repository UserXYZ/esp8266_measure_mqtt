local M = {}

function setup()
    local sda = 5 -- GPIO14
    local scl = 6 -- GPIO12
    local sla = 0x3c
    
    i2c.setup(0, sda, scl, i2c.SLOW)
    disp = u8g.ssd1306_128x64_i2c(sla)
end    

local function cls()
    disp:firstPage()
    repeat
    until disp:nextPage() == false
    tmr.delay(100000)
    tmr.wdclr()
end

local function disp_stat(msg)
    disp:firstPage()
    disp:setFont(u8g.font_helvR10)
    disp:setFontRefHeightExtendedText()
    disp:setFontPosTop()
    disp:setDefaultForegroundColor()
    repeat
        disp:drawStr(0,0,"Status messages")
        disp:drawLine(0,15,127,15)
        disp:drawStr(0,16,tostring(msg))
    until disp:nextPage() == false
    tmr.delay(100000)
    tmr.wdclr()
end

local function disp_data(sensor, data)
    disp:firstPage()
    disp:setFont(u8g.font_helvR10)
    disp:setFontRefHeightExtendedText()
    disp:setFontPosTop()
    disp:setDefaultForegroundColor()
    repeat
        disp:setFont(u8g.font_helvR10)
        disp:setFontPosTop()
        disp:drawStr(0, 0, "Sensor: "..sensor)
        disp:drawLine(0,15,127,15)
        if #data == 2 then
            -- only one sensor, use larger font
            disp:setFont(u8g.font_helvR18)
            disp:drawStr(0, 50, data[1]..": "..data[2])
        elseif #data == 4 then
            -- two sensors, use smaler font, draw in two rows
            disp:setFont(u8g.font_helvR14)
            disp:drawStr(0, 37, data[1]..": "..data[2])
            disp:drawStr(0, 60, data[3]..": "..data[4])
        else
            print ("Wrong number of sensors for display!")
        end
--[[
        disp:setFont(u8g.font_helvR14)
        --disp:setFont(u8g.font_profont29)
        disp:setFontPosTop()
        disp:drawStr(0, 22, "T: ".."23.5"..string.char(176).."C")
        disp:drawStr(0, 44, "P: ".."1005.9mBar")
        arr={"T",tostring(25.8)..string.char(176).."C", "P", tostring(1002.3).."mBar"}
]]--
    until disp:nextPage() == false
    tmr.delay(100000)
    tmr.wdclr()
end

-- Return module table
M = {
    setup = setup,
    cls = cls,
    disp_data = disp_data,
    disp_stat = disp_stat
}
return M
