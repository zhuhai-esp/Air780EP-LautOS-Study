
-- ============================================================
-- 模块功能：u8g2时钟显示, 
-- 注意：需要对应的Lua固件支持u8g2库，如果不支持，可以使用I2C版本
-- 屏幕分辨率：128x64，I2C地址：0x3C
-- ============================================================
PROJECT = "u8g2_clock"
VERSION = "1.0.1"

log.info("main", PROJECT, VERSION)

_G.sys = require("sys")
local lbsLoc2 = require("lbsLoc2")

wdt.init(9000)
sys.timerLoopStart(wdt.feed, 3000)

local sw_i2c_scl = 30
local sw_i2c_sda = 29

u8g2.begin({ic = "ssd1306", direction = 0, mode = "i2c_sw", i2c_scl = sw_i2c_scl, i2c_sda = sw_i2c_sda})

-- 备用时间（系统时间无效时使用）
local fb_year, fb_month, fb_day = 2026, 7, 8
local fb_hour, fb_min, fb_sec = 0, 0, 0

local location_text = "00.0000-000.0000"
local last_sec = -1
local show_date = true -- true: 显示日期, false: 显示星期
local sec_count = 0

local weekdays = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}

local function format_location(lat, lng)
    lat = tonumber(lat)
    lng = tonumber(lng)
    if not lat or not lng then
        return location_text
    end
    local lat_sign = ""
    if lat < 0 then lat_sign = "-"; lat = -lat end
    local lng_sign = ""
    if lng < 0 then lng_sign = "-"; lng = -lng end
    local lat_deg = math.floor(lat)
    local lat_frac = math.floor((lat - lat_deg) * 10000 + 0.5)
    local lng_deg = math.floor(lng)
    local lng_frac = math.floor((lng - lng_deg) * 10000 + 0.5)
    return string.format("%s%02d.%04d-%s%03d.%04d", lat_sign, lat_deg, lat_frac, lng_sign, lng_deg, lng_frac)
end

local function update_location_row(new_text)
    if new_text and #new_text > 0 then
        location_text = new_text
    end
end

-- 定位任务：每10秒尝试更新一次定位信息（如果有mobile/lbsLoc2支持）
sys.taskInit(function()
    while true do
        if mobile then
            mobile.reqCellInfo(15)
            sys.waitUntil("CELL_INFO_UPDATE", 3000)
            local lat, lng, t = lbsLoc2.request(5000)
            if lat and lng then
                update_location_row(format_location(lat, lng))
            end
        end
        sys.wait(10000)
    end
end)

-- 显示更新任务：每秒刷新时间，每10秒切换日期/星期
sys.taskInit(function()
    while true do
        local year, month, day, hour, minute, second

        local t = os.date("*t")
        if t and t.year and t.year > 2000 then
            year, month, day = t.year, t.month, t.day
            hour, minute, second = t.hour, t.min, t.sec
        else
            fb_sec = fb_sec + 1
            if fb_sec >= 60 then fb_sec = 0; fb_min = fb_min + 1 end
            if fb_min >= 60 then fb_min = 0; fb_hour = fb_hour + 1 end
            if fb_hour >= 24 then fb_hour = 0 end
            year, month, day = fb_year, fb_month, fb_day
            hour, minute, second = fb_hour, fb_min, fb_sec
        end

        -- 每秒更新
        if second ~= last_sec then
            last_sec = second
            sec_count = sec_count + 1

            -- 每10秒切换一次日期/星期
            if (sec_count % 10) == 0 then
                show_date = not show_date
            end

            -- 准备要显示的第一行文本
            local first_line = ""
            if show_date then
                first_line = string.format("%04d-%02d-%02d", year, month, day)
            else
                local w = os.date("%w")
                w = tonumber(w) or 0
                first_line = weekdays[w + 1] or ""
            end

            local colon = ((second % 2) == 0) and ":" or " "
            local time_line = string.format("%02d%s%02d%s%02d", hour, colon, minute, colon, second)

            -- 绘制到屏幕
            u8g2.ClearBuffer()
            u8g2.SetFont(u8g2.font_opposansm16)
            u8g2.DrawButtonUTF8(first_line, 64, 12, u8g2.BTN_HCENTER, 0, 0, 0)
            u8g2.SetFont(u8g2.font_opposansm24)
            u8g2.DrawButtonUTF8(time_line, 64, 42, u8g2.BTN_HCENTER, 0, 0, 0)
            u8g2.SetFont(u8g2.font_opposansm12)
            u8g2.DrawButtonUTF8(location_text, 64, 62, u8g2.BTN_HCENTER, 0, 0, 0)
            u8g2.SendBuffer()
        end

        sys.wait(100)
    end
end)

sys.run()
