## Air780E 说明

### 官方文档
- Air780E 说明：https://docs.openluat.com/air780e/
- AT 固件说明：https://docs.openluat.com/air780e/at/app/
- LuatOS 固件：https://docs.openluat.com/air780e/luatos/firmware/

### 改 USB 供电

设备原生几乎都不支持 USB 5V 供电，但可以使用 12V 供电，电路上通过 5430 芯片的方案降压到 5V，再通过 CFJ3F 丝印的芯片相关电路把 5V 降压到 3.85V 左右，直接供给 Air780E 的 VBAT 电源引脚。

因此只需要把 USB 的 +5V 飞线连接到 5430 的 5V 输出端的滤波电容上，就可以实现 USB 供电，如果怕电流倒灌 USB，串联一个肖特基二极管即可。

### 设备版本

Air780E 有多种硬件版本，以下分别列出对应图片：

#### 版本 1：4G-Air780E-TYPE_C_V03 (2026-04-15)
<img src="../images/4G-Air780E-TYPE_C_V03 2026-04-15.jpg" width="400" alt="4G-Air780E-TYPE_C_V03">

#### 版本 2：新版 4G Air780E 双路 V02 (2025-09-20)
<img src="../images/新版4G Air780E 双路 V02 2025-09-20.jpg" width="400" alt="新版4G Air780E 双路 V02">

#### 版本 3：4G-Air780E-USB-V00 (2026-04-14)
<img src="../images/4G-Air780E-USB-V00 2026-04-14.jpg" width="400" alt="4G-Air780E-USB-V00">

### 设备 IO 信息

所有版本的 IO 连接都一致：

| 外设 | GPIO | 说明 |
| --- | --- | --- |
| 绿色 LED | GPIO27 | 高电平点亮 |
| 红色 LED | GPIO26 | 高电平点亮 |
| CCP1 | IO25 | 机器控制引脚1，高低电平都有输出 |
| CCP2 | IO29 | 机器控制引脚2，高低电平都有输出 |

### 扩展 I2C OLED 屏接线

| OLED | Air780E |
| --- | --- |
| VCC | 3.3V |
| GND | GND |
| SCL | IO30 |
| SDA | IO31 |

### 示例工程

- `BoardIOTest/`：GPIO 测试示例，控制 LED 灯闪烁，用于验证硬件 IO 功能正常。