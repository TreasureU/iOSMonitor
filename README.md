# iOSMonitor
FPS Monitor;Memory Monitor;Debug Log on screen;
iPhone and iPad Universal;Landspace and Portrait Universal

## 功能：
* FPS监控
* 内存监控
* Debug四级输出到屏幕（normal、success、warning、error）

## FPS监控：
展示当前屏幕的刷新频率，为了及时得到最新的刷新频率，提供三种的刷新频率监控等级，建议使用medium。<br>
刷新频率展示时会根据当前的数值显示为不同的颜色 >=55 为绿色,(45，55) 为黄色，<=45 为红色。<br>
FPS浮层支持随意拖动，拖动到边界时会自动回弹。<br>
  
## 内存监控：
单击FPS浮层，会使浮层界面变大，从而进一步展示内存使用情况。【再次单击可以复原】<br>
展示以下数值：【设备所有内存、设备全部已使用内存、设备全部未使用内存、应用使用内存】<br>

## Debug四级输出：
支持 CJFDebugNormalLog【正常输出，白色】、CJFDebugErrorLog【错误输出，红色】、CJFDebugWarningLog【警告输出，黄色】、CJFDebugSuccessLog【成功输出，蓝色】<br>
输出宏使用方式与NSLog一致<br>
双击FPS浮层，可以展示Debug输出框【再次双击可以隐藏】<br>
Debug输出框有四个按钮：<br>
* 增大按钮：增加输出框高度
* 减少按钮：减小输出框高度
* 清除按钮：清除输出框信息
* 锁定/解锁按钮：锁定后可以使输出框不再捕获点击和手势事件，否则将被输出框截获。
输出信息自动滚动，但是当偏移量大于一定值时，不再自动滚动。<br>


## 界面适配：
适配iPad和iPhone设备<br>
适配横竖屏以及转换情况<br>


## 使用帮助：
将Monitor文件夹下的8个文件引入工程即可。<br>
