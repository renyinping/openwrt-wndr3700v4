# OpenWRT-WNDR3700v4

### U-Boot 刷机方法

  1. 路由断电，按住reset键不放，通电并观察电源指示灯，等到由黄色闪烁变为绿色闪烁，松开reset键。
  2. tftp客户端上传img文件 `tftp -i 192.168.1.1 put openwrt-15.05.1-ar71xx-nand-wndr3700v4-ubi-factory.img` 。
  3. 等到系统正常启动后，路由断电，至少30秒后再通电（否则可能会没有5G的WiFi）。
 