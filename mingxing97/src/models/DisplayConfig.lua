-- Name: DisplayConfig
-- Func: 界面参数
-- Author: Johny

local DisplayConfig = {}

--tag file
DisplayConfig.TAG_ARR = {"tag_0.png", "tag_1.png", "tag_2.png", "tag_3.png", "tag_4.png", "tag_5.png", "tag_6.png", "tag_7.png", "tag_8.png"}

--[[tag pos
	1,2,3为block中位置
	4为block上外中心位置
	5为block下外中心位置
]]
DisplayConfig.TAG_POS = {} 
DisplayConfig.TAG_POS[1] = {cc.p(103.5, -16.5), cc.p(103.5, 86.5), cc.p(103.5, 189.5), cc.p(103.5, 300.5), cc.p(103.5, -124.5)}
DisplayConfig.TAG_POS[2] = {cc.p(111, -15), cc.p(111, 86.5), cc.p(111, 191), cc.p(111, 302), cc.p(111, -123)}
DisplayConfig.TAG_POS[3] = {cc.p(104, -15), cc.p(104, 86.5), cc.p(104, 191), cc.p(104, 302), cc.p(104, -123)}
DisplayConfig.TAG_POS[4] = {cc.p(104, -17.5), cc.p(104, 85.5), cc.p(104, 188.5), cc.p(104, 299.5), cc.p(104, -125.5)}
DisplayConfig.TAG_POS[5] = {cc.p(113, -17.5), cc.p(113, 85.5), cc.p(113, 188.5), cc.p(113, 299.5), cc.p(113, -125.5)}
DisplayConfig.TAG_POS[6] = {cc.p(103.5, -17.5), cc.p(103.5, 85.5), cc.p(103.5, 188.5), cc.p(103.5, 299.5), cc.p(103.5, -125.5)}
DisplayConfig.TAG_POS[7] = {cc.p(102.5, -17), cc.p(102.5, 86), cc.p(102.5, 189), cc.p(102.5, 300), cc.p(102.5, -125)}
DisplayConfig.TAG_POS[8] = {cc.p(111, -17), cc.p(111, 86), cc.p(111, 189), cc.p(111, 300), cc.p(111, -125)}
DisplayConfig.TAG_POS[9] = {cc.p(104, -16.5), cc.p(104, 86.5), cc.p(104, 189.5), cc.p(104, 300.5), cc.p(104, -124.5)}

--备用tag数量
DisplayConfig.CNT_TAG = 5

--备用位置数量
DisplayConfig.CNT_POS = 5

--roll数量
DisplayConfig.CNT_ROLL = 9

--全部tag个数（包括占位的）
DisplayConfig.CNT_ALLTAG = DisplayConfig.CNT_TAG * DisplayConfig.CNT_ROLL

--线数量
DisplayConfig.CNT_LINE = 8

--位移一次时间
DisplayConfig.DURING_MOVEONCE = 0.05

--自动速率（以时间为基数）
DisplayConfig.RATE_AUTO   =  0.8

--自然roll一圈时间
DisplayConfig.DURING_ROLLNORMAL = 1.0

--自然停监测时间间隔
DisplayConfig.INTERVAL_TAG_NATURESTOP = 0.25

--自然停顺序
DisplayConfig.TAG_NATURESTOP_ORDER = {4, 5, 6, 7, 8, 9, 1, 2, 3}

--下分滚动间隔时间
DisplayConfig.INTERVAL_ADDSCORE = 0.02

--滚动停止减速速率（以时间为基数）
DisplayConfig.TAG_ROLLSTOP_RATE = 3.5

--字幕切换间隔
DisplayConfig.INTERVAL_ZIMU_SWITCH = 1.0

--持续上分间隔时间
DisplayConfig.INTERVAL_ADD        = 0.1

--延迟持续上分时间
DisplayConfig.DELAY_ADD           = 1.0

--全盘闪烁一次时间
DisplayConfig.DURING_ALLPANEL_BLINK = 1.0

--加速停监测时间间隔
DisplayConfig.INTERVAL_TAG_SPEEDSTOP = 0.2


----------------------------ZOrder-----------------------------------
--箭头层层级
DisplayConfig.ZORDER_TAG_ARROW = 2
--美女图标层级
DisplayConfig.ZORDER_TAG_MEINV = 1


----------------------------Txt------------------------------------
--分享文字
DisplayConfig.CONTENT_SHARE = "我中了%d额外奖励，快来玩吧！"


---------------------------broadcast-------------------------------
DisplayConfig.DURING_BC_ONCE   = 10.0

return DisplayConfig