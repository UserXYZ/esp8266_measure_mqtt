local M = {}
local disp=nil
--[[
local function setup()
    local cs  = 8 -- GPIO15, pull-down 10k to GND
    local dc  = 1 -- GPIO5
    local res = 0 -- GPIO16
    spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, 8, 8)
    disp = u8g.pcd8544_84x48_hw_spi(cs, dc, res)
end
]]--
local function setup(sda, scl, addr)
    if sda~=nil and scl~=nil and addr~=nil then
        if i2c.setup(0, sda, scl, i2c.SLOW) ~= 0 then
            disp = u8g.ssd1306_128x64_i2c(addr)
        else
            return nil
        end
    else
        print("Wrong display parameters!")
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
    disp:begin()
    disp:firstPage()
    disp:setDefaultForegroundColor()
    disp:setFont(u8g.font_helvR10)
    disp:setFontPosTop()
    disp:setFontRefHeightExtendedText()

    local m_w=nil -- message width in current font, in pixels
    if msg~=nil then
        m_w=disp:getStrWidth(msg)
    else
        return
    end
    local d_w=disp:getWidth() -- display width in pixels
    local d_txt={}
    -- split message into pieces on spaces
    if m_w>d_w then
        local i=1
        local j=1    
        while j<=string.len(msg) do
            local temp=string.sub(msg,i,j)
            local t_w=disp:getStrWidth(temp)
            if t_w>=d_w then
                temp=string.sub(temp,1,-2)
                for s=string.len(temp),1,-1 do
                    if string.sub(temp,s,s)==' ' then
                        temp=string.sub(temp,1,s-1)
                        j=s+i
                        break
                    end
                end
                table.insert(d_txt,temp)
                temp=nil
                i=j
            else
                j=j+1
            end
            if j>string.len(msg) then
                table.insert(d_txt,temp)
            end
        end
    else
        for i=1,#d_txt do d_txt[i]=nil end
        d_txt[1]=msg
    end
    -- draw all messages from d_txt
    repeat
        local y=16
        disp:drawStr(0,0,"Status messages")
        disp:drawLine(0,15,127,15)
        for i=1,#d_txt do
            disp:drawStr(0,y,d_txt[i])
            y=y+disp:getFontLineSpacing()
        end
    until disp:nextPage() == false
    tmr.delay(100000)
    tmr.wdclr()
    d_txt=nil
    collectgarbage()
end
-- display data from sensors
local function disp_data(data)
    disp:firstPage()
    disp:setFont(u8g.font_helvR10)
    disp:setFontRefHeightExtendedText()
    disp:setFontPosTop()
    disp:setDefaultForegroundColor()
    repeat
        disp:setFont(u8g.font_helvR10)
        disp:setFontPosTop()
        disp:drawStr(0, 0, "Sensor: "..data[1])
        disp:drawLine(0,15,127,15)
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
