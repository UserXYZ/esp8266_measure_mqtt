local M = {}
local disp = nil
local conf = require("config")

local function setup()
    if string.lower(conf.display.conn) == "i2c" then
        if i2c.setup(0,conf.display.i2c_sda, conf.display.i2c_scl, i2c.SLOW) ~= 0 then
            if conf.display.type == "sh1106" then
                disp = u8g.sh1106_128x64_i2c(conf.display.i2c_addr)
            elseif conf.display.type == "ssd1306" then
                disp = u8g.ssd1306_128x64_i2c(conf.display.i2c_addr)
            else -- display type not known
                return nil
            end
            return true
        else -- i2c setup failed
            return nil
        end
    --elseif string.lower(conf.display.conn) ~= "spi" then
    --    spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, 8, 8)
    --    disp = u8g.pcd8544_84x48_hw_spi(conf.display.spi_cs, dc, res)
    --    display.setup(conf.display.spi_miso, conf.display.spi_mosi, conf.display.spi_cs, conf.display.spi_clk)
    else -- not i2c nor spi display connection
        print("Wrong type of display selected")
        return nil
    end
end
-- clear screen
local function cls()
    disp:begin()
    disp:firstPage()
    repeat
    until disp:nextPage() == false
    tmr.delay(100000)
    tmr.wdclr()
end
-- display status messages
local function disp_stat(msg)
    tmr.wdclr()
    disp:begin()
    disp:firstPage()
    disp:setDefaultForegroundColor()
    disp:setFont(u8g.font_helvR10)
    disp:setFontPosTop()
    disp:setFontRefHeightExtendedText()

    local m_w = nil -- message width in current font, in pixels
    if msg ~= nil then
        m_w = disp:getStrWidth(msg)
    else
        return
    end
    local d_w = disp:getWidth() -- display width in pixels
    local d_txt = {}
    -- split message into pieces on spaces
    if m_w > d_w then
        local i = 1
        local j = 1
        while j <= string.len(msg) do
            local temp = string.sub(msg, i, j)
            local t_w = disp:getStrWidth(temp)
            if t_w >= d_w then
                temp = string.sub(temp, 1, -2)
                for s = string.len(temp), 1, -1 do
                    if string.sub(temp, s, s) == ' ' then
                        temp = string.sub(temp, 1, s-1)
                        j = s+i
                        break
                    end
                end
                table.insert(d_txt,temp)
                temp = nil
                i = j
            else
                j = j+1
            end
            if j > string.len(msg) then
                table.insert(d_txt, temp)
            end
        end
    else
        for i = 1, #d_txt do d_txt[i] = nil end
        d_txt[1] = msg
    end
    -- draw all messages from d_txt
    repeat
        local y = 16
        disp:drawStr(0, 0, "Status messages")
        disp:drawLine(0, 15, 127, 15)
        for i = 1, #d_txt do
            disp:drawStr(0, y, d_txt[i])
            y = y + disp:getFontLineSpacing()
        end
    until disp:nextPage() == false
    tmr.delay(100000)
    tmr.wdclr()
    d_txt = nil
    collectgarbage()
end
-- display data from sensors
local function disp_data(data)
    tmr.wdclr()
    disp:firstPage()
    disp:setFont(u8g.font_helvR10)
    disp:setFontRefHeightExtendedText()
    disp:setFontPosTop()
    disp:setDefaultForegroundColor()
    repeat
        disp:setFont(u8g.font_helvR10)
        disp:setFontPosTop()
        disp:drawStr(0, 0, "Sensor: "..data[1])
        disp:drawLine(0, 15, 127, 15)
        -- select font and one or two row display
        if #data == 3 then
            -- only one sensor, use larger font
            disp:setFont(u8g.font_helvR18)
            disp:drawStr(0, 50, data[2]..": "..data[3])
        elseif #data == 5 then
            -- two sensors, use smaler font, draw in two rows
            disp:setFont(u8g.font_helvR14)
            disp:drawStr(0, 37, data[2]..": "..data[3])
            disp:drawStr(0, 60, data[4]..": "..data[5])
        else
            print ("Wrong number of sensors for display!")
        end
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
