-- ============================================================
-- 模块功能：基站定位示例
-- 使用 LuatOS 的 mobile 模块获取小区信息，通过 lbsLoc2 库请求经纬度
-- 定位流程：等待网络就绪 → 请求小区信息 → 调用 lbsLoc2 获取位置
-- ============================================================

-- LuaTools 需要 PROJECT 和 VERSION 这两个信息
PROJECT = "lbsLoc2demo"
VERSION = "1.0.0"

log.info("main", PROJECT, VERSION)

-- sys 库是 LuatOS 标配，提供任务管理、定时器等核心功能
sys = require("sys")

-- 引入基站定位库
local lbsLoc2 = require("lbsLoc2")

-- Air780E 的 AT 固件默认会为开机键防抖，导致部分用户刷机很麻烦
-- 在 EC618 平台上，如果支持 pm.PWK_MODE，关闭开机键防抖功能
if rtos.bsp() == "EC618" and pm and pm.PWK_MODE then
    pm.power(pm.PWK_MODE, false)
end

-- 主任务：基站定位循环
sys.taskInit(function()
    -- 等待网络 IP 就绪，超时时间 30 秒
    -- IP_READY 事件由系统网络层在获取到 IP 地址后触发
    sys.waitUntil("IP_READY", 30000)

    -- 循环进行基站定位（前提是设备支持 mobile 模块）
    -- 没有 mobile 库就无法进行基站定位，直接跳过
    while mobile do
        -- 请求小区信息，超时时间 15 秒
        -- 该调用会触发 CELL_INFO_UPDATE 事件
        mobile.reqCellInfo(15)

        -- 等待小区信息更新事件，超时时间 3 秒
        sys.waitUntil("CELL_INFO_UPDATE", 3000)

        -- 调用 lbsLoc2.request 获取经纬度
        -- 超时时间 5 秒，可选择性指定定位服务器地址
        -- 例如：lbsLoc2.request(5000, "bs.openluat.com")
        local lat, lng, t = lbsLoc2.request(5000)

        -- 打印定位结果，包含经纬度和详细信息
        -- t 包含定位的详细数据，如基站信息、定位精度等
        log.info("lbsLoc2", lat, lng, (json.encode(t or {})))

        -- 定位成功后暂停 60 秒，避免频繁请求
        sys.wait(60000)
    end
end)

-- 启动系统任务调度器
-- sys.run() 之后不能添加任何语句，因为它会阻塞执行
sys.run()