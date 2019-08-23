-- Name: GameLayer
-- Func: 明星97逻辑层
-- Author: Johny

local module_pre = "game.mingxing97.src";
local ExternalFun =  appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local cmd = appdf.req(module_pre .. ".models.CMD_Game")
local GameLogic = appdf.req(module_pre .. ".models.GameLogic")
local GameViewLayer = appdf.req(module_pre .. ".views.layer.GameViewLayer")
--admin
local GameAdminLayer = appdf.req(module_pre .. ".views.admin.GameAdminLayer")
local GameAdminKCLayer = appdf.req(module_pre .. ".views.admin.GameAdminKCLayer")
local GameAdminKCRangeLayer = appdf.req(module_pre .. ".views.admin.GameAdminKCRangeLayer")
local GameAdminDajiangLayer = appdf.req(module_pre .. ".views.admin.GameAdminDajiangLayer")
local GameAdminWeightLayer = appdf.req(module_pre .. ".views.admin.GameAdminWeightLayer")

local GameModel = appdf.req(appdf.CLIENT_SRC.."gamemodel.GameModel")
local GameLayer = class("GameLayer", GameModel)

---------------------常量定义------------------


--销毁回调
function GameLayer:onExit()
    --清除广播监听
    G_unSchedule(self.mBroadMonitor)
    self.mBroadMonitor = nil
    --
    self:dismissPopWait()
    GameLayer.super.onExit(self)
    --
    ExternalFun.playPlazzBackgroudAudio()
end


function GameLayer:ctor( frameEngine,scene )
    GameLayer.super.ctor(self,frameEngine,scene)
    --
    AudioEngine.stopMusic()
    --var
    self.miChangeRadio = 1 --兑换比例(上分数*比例等金币)
    self.mlJackPot = 0     --奖池
    self.miUnitUpScore = 0 --单位上分
    self.szGameRoomName = ""  --房间名
    self.mlAllWinScore = 0 --本次spin全盘得分
    self.mlLineWinScore = 0 --本次spin线得分
    self.mNormalWinScore = 0 --本次spin全盘+线得分
    self.mlJackPotWinScore = 0 --本次jp赢钱
    self.mlExtraWinScore = 0 --本次额外赢钱
    self.mlGirlWinScore = 0 -- 本次美女赢分
    self.mcbGirlAwardCount = 0 --美女奖励剩余次数
    self.mlNumber7WinScore = 0 --数字7得分
    self.mBroadList = {} -- 广播列表
    self.mIsBroadCasting = false -- 是否广播中

    --广播监听器
    self.mBroadMonitor = nextTick_eachSecond(function()
    		if not self.mIsBroadCasting and #self.mBroadList > 0 then
    			self._gameView:onBroadCastPlay(self.mBroadList[1])
    			table.remove(self.mBroadList, 1)
    		end
    	end, 3.0)
end

--创建场景
function GameLayer:CreateView()
    return GameViewLayer:create(self):addTo(self)
end

-- 初始化游戏数据
function GameLayer:OnInitGameEngine()
    GameLayer.super.OnInitGameEngine(self)
end

-- 重置游戏数据
function GameLayer:OnResetGameEngine()
    GameLayer.super.OnResetGameEngine(self)
end

--获取gamekind
function GameLayer:getGameKind()
    return cmd.KIND_ID
end

-----------------------------------------------------------------------
--系统消息
function GameLayer:onSysMessage(pData)
	cclog("GameLayer:onSysMessage===>")
	local wType = pData:readword()
	local wLength = pData:readword()
	local strContent = pData:readstring()
	table.insert(self.mBroadList, strContent)
end

-----------------------------------------------------------------------
-- 场景消息
function GameLayer:onEventGameScene(cbGameStatus, pData)
	cclog("GameLayer:onEventGameScene===>" .. cbGameStatus)
	self.m_cbGameStatus = cbGameStatus

	if cbGameStatus == cmd.GS_TK_FREE then
		self:onStatusFree(pData)
	elseif cbGameStatus == cmd.GS_TK_PLAYING then
		self:onStatusPlay(pData)
	end
end

function GameLayer:onStatusFree(pData)
	cclog("GameLayer:onStatusFree===>")
	--
	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_StatusFree, pData)
	dump(cmd_data, "onStatusFree")
	self.miChangeRadio = cmd_data.iChangeRadio
	self.mlJackPot = cmd_data.lJackPot
	self._gameView:onRefreshJP()
	self.miUnitUpScore = cmd_data.iUnitUpScore
	self.szGameRoomName = cmd_data.szGameRoomName
	--
	self._gameView:onRefreshInfo()
	--
	self.mSlotsStatus = GameViewLayer.ST_FREE
end

function GameLayer:onStatusPlay(pData)
	cclog("GameLayer:onStatusPlay===>")
end

function GameLayer:onResetWinScore()
    self.mlAllWinScore = 0
    self.mlLineWinScore = 0
    self.mNormalWinScore = 0
    self.mlJackPotWinScore = 0
    self.mlExtraWinScore = 0
    self.mlGirlWinScore = 0
end
---------------------------------------------------------------------
-- 游戏消息
function GameLayer:onEventGameMessage(sub, pData)
	cclog("GameLayer:onEventGameMessage===>" .. sub)
	if sub == cmd.SUB_S_GAME_END then
		self:onSubSpinResult(pData)
	elseif sub == cmd.SUB_S_RECORD_LOTTERY then
		self:onSubAwardRecord(pData)
    elseif sub == cmd.SUB_S_WEIGHT_CONTROL then
        self:onSubWeightCheckResult(pData)   --权重
    elseif sub == cmd.SUB_S_STOCK_SECTION_CONTROL then
        self:onSubStockCheckResult(pData)    --库存
    elseif sub == cmd.SUB_S_LOTTERY_CONTROL then
        self:onSubLotteryCheckResult(pData)  --大奖
    elseif sub == cmd.SUB_S_STOCK_MEINV_CONTROL then
        self:onSubStockMeinvCheckResult(pData)  --综合 美女库存抽水
	end
end

--spin结果返回
function GameLayer:onSubSpinResult(pData)
	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_GameEnd, pData)
	cclog("GameLayer:onSpinResult===>" .. json.encode(cmd_data))
	self.mlJackPot = cmd_data.lJackPot--奖池累计
	self.mlAllWinScore = cmd_data.lAllWinScore --全盘赢分
	self.mlLineWinScore = cmd_data.lLineWinScore --线赢分
	self.mlGirlWinScore = cmd_data.lGirlWinScore --美女赢分
	self.mlNumber7WinScore = cmd_data.lNumber7WinScore -- 数字7得分
	self.mNormalWinScore = self.mlAllWinScore + self.mlLineWinScore + self.mlGirlWinScore + self.mlNumber7WinScore --总得分
	self.mlJackPotWinScore = cmd_data.lJackPotWinScore --jp赢分
	self.mlExtraWinScore = cmd_data.lExtraWinScore --额外
	self.mcbGirlAwardTimes = cmd_data.cbGirlAwardTimes --美女图案奖励倍数
	self.mcbGirlAwardCount = cmd_data.cbGirlAwardCount --美女图案奖励次数
	self._gameView:onSpinRet(cmd_data)
end

--大奖记录返回
function GameLayer:onSubAwardRecord(pData)
	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_RecordLottery, pData)
	cclog("GameLayer:onSpinResult===>" .. json.encode(cmd_data))
	self._gameView:onShowAwardPanel(cmd_data)
end

--权重配置查询返回
function GameLayer:onSubWeightCheckResult(pData)
    local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_WeightControl, pData)
    cclog("GameLayer:onSubWeightCheckResult===>" .. json.encode(cmd_data))
    if self.mAdminWeightLayer then
        self.mAdminWeightLayer:onRefresh(cmd_data)
    end
end

--库存配置查询返回
function GameLayer:onSubStockCheckResult(pData)
    local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_StockSectionControl, pData)
    cclog("GameLayer:onSubStockCheckResult===>" .. json.encode(cmd_data))
    if self.mAdminKCRangeLayer then
        self.mAdminKCRangeLayer:onRefresh(cmd_data)
    end
end

--大奖控制查询返回
function GameLayer:onSubLotteryCheckResult(pData)
    local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_LotteryControl, pData)
    cclog("GameLayer:onSubLotteryCheckResult===>" .. json.encode(cmd_data))
    if self.mAdminDajiangLayer then
        self.mAdminDajiangLayer:onRefresh(cmd_data)
    end
end

--综合 美女库存抽水查询返回
function GameLayer:onSubStockMeinvCheckResult(pData)
    local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_StockMeiNvControl, pData)
    cclog("GameLayer:onSubStockMeinvCheckResult===>" .. json.encode(cmd_data))
    if self.mAdminKCLayer then
        self.mAdminKCLayer:onRefresh(cmd_data)
    end
end

--*****************************    发送消息     *********************************--
--spin
function GameLayer:onSpin(bet)
	cclog("GameLayer:onSpin===>" .. bet)
    self:SendUserReady()
    --
	local cmd_data = CCmd_Data:create(8)
	cmd_data:pushscore(bet)
	self:SendData(cmd.SUB_C_ADD_SCORE, cmd_data)
end

--查询大奖记录
function GameLayer:onCheckAwardRecord()
	cclog("GameLayer:onCheckAwardRecord===>")
	local cmd_data = CCmd_Data:create(0)
	self:SendData(cmd.SUB_C_RECORD_LOTTERY, cmd_data)
end

--设置大奖
function GameLayer:onSendDajiangSetting(hardlevel, dataarr)

    local cmd_data = CCmd_Data:create(57)
    cmd_data:pushbyte(hardlevel)
    for i =1, #dataarr do
        cmd_data:pushint(tonumber(dataarr[i]))
    end
    self:SendData(cmd.SUB_C_LOTTERY_CONTROL, cmd_data)
end

--设置权重
function GameLayer:onSendWeightSetting(hardlevel, dataarr)

    local cmd_data = CCmd_Data:create(109)
    cmd_data:pushbyte(hardlevel)
    for i = 1,#dataarr do
        cmd_data:pushint(tonumber(dataarr[i]))
    end
    self:SendData(cmd.SUB_C_WEIGHT_CONTROL, cmd_data)
end

--设置库存控制
function GameLayer:onSendKcSetting(datatype, data)
    local cmd_data = CCmd_Data:create(9)
    cmd_data:pushbyte(datatype)
    cmd_data:pushscore(tonumber(data))
    self:SendData(cmd.SUB_C_STOCK_CONTROL, cmd_data)
end

--设置库存区间
function GameLayer:onSendKcqjSetting(hardlevel, dataarr)
    local cmd_data = CCmd_Data:create(17)
    cmd_data:pushbyte(hardlevel)
    for i = 1, #dataarr do
        cmd_data:pushint(tonumber(dataarr[i]))
    end
    self:SendData(cmd.SUB_C_STOCK_SECTION_CONTROL, cmd_data)
end

--设置美女概率
function GameLayer:onSendMeinvSetting(dataarr)
    local cmd_data = CCmd_Data:create(16)
    for i =1, #dataarr do
        cmd_data:pushint(tonumber(dataarr[i]))
    end
    self:SendData(cmd.SUB_C_MEINV_CONTROL, cmd_data)
end

--设置控制查询
function GameLayer:onSendControlSetting(datatype)
    cclog("GameLayer:onSendControlSetting==>" .. datatype)
    local cmd_data = CCmd_Data:create(1)
    cmd_data:pushbyte(datatype)
    self:SendData(cmd.SUB_C_QUERY_CONRTOL, cmd_data)
end

-----------------------------about  Admin-------------------------------------
function GameLayer:onShowAdminMainLayer()
	self.mAdminLayer = GameAdminLayer:create(self)
	self:addChild(self.mAdminLayer)
end

function GameLayer:onShowAdminKCLayer()
	self.mAdminKCLayer = GameAdminKCLayer:create(self)
	self:addChild(self.mAdminKCLayer)
end

function GameLayer:onShowAdminDajiangLayer(hardlevel)
	self.mAdminDajiangLayer = GameAdminDajiangLayer:create(self,hardlevel)
	self:addChild(self.mAdminDajiangLayer)
end

function GameLayer:onShowAdminKCRangeLayer(hardlevel)
    self.mAdminKCRangeLayer = GameAdminKCRangeLayer:create(self, hardlevel)
    self:addChild(self.mAdminKCRangeLayer)
end

function GameLayer:onShowAdminWeightLayer(hardlevel)
	self.mAdminWeightLayer = GameAdminWeightLayer:create(self, hardlevel)
	self:addChild(self.mAdminWeightLayer )
end

return GameLayer