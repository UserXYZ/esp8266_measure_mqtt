local M = {}

function setup()
    local sda = 5 -- GPIO14
    local scl = 6 -- GPIO12
    local sla = 0x3c
    
    i2c.setup(0, sda, scl, i2c.SLOW)
    disp = u8g.ssd1306_128x64_i2c(sla)
end    

local function cls()
    disp:begin()
    disp:firstPage()
    repeat
    until disp:nextPage() == false
    tmr.delay(100000)
    tmr.wdclr()
end

local function disp_stat(msg)
    disp:begin()
    disp:firstPage()
    disp:setDefaultForegroundColor()
    disp:setFont(u8g.font_helvR10)
    disp:setFontPosTop()
    disp:setFontRefHeightExtendedText()

    local m_w=nil
    if msg~=nil then
        m_w=disp:getStrWidth(msg)
    else
        return
    end
    local d_w=disp:getWidth()
    local d_txt={}
   
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
