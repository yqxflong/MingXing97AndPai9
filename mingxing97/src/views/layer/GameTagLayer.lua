-- Name: GameTagLayer
-- Func: 图标层
-- Author: Johny

local AnimationMgr = appdf.req(appdf.EXTERNAL_SRC .. "AnimationMgr")
local module_pre = "game.mingxing97.src"
local GameLogic = appdf.req(module_pre .. ".models.GameLogic")
local cmd = appdf.req(module_pre .. ".models.CMD_Game")
local DisplayConfig = appdf.req(module_pre .. ".models.DisplayConfig")


local GameTagLayer = class("GameTagLayer",function(scene)
		local GameTagLayer =  cc.CSLoader:createNode(cmd.RES_PATH.."game/TagLayer.csb")
    return GameTagLayer
end)

---------------常量定义-------------------
--状态
GameTagLayer.ST_FREE = 0
GameTagLayer.ST_SPIN = 1
GameTagLayer.ST_WILLSTOP = 2
GameTagLayer.ST_STOPING = 3
GameTagLayer.ST_STOPPED = 4
GameTagLayer.ST_SHOWWIN = 5

---------------------------------------------------------------------------------------------------
function GameTagLayer:destroy()
	self._scene:stopSoundEffect()
	self:stopAllActions()
	G_unSchedule(self.mMonitor)
	self.mMonitor = nil
	if self.mNatureStopScheduler then
		G_unSchedule(self.mNatureStopScheduler)
		self.mNatureStopScheduler = nil
	end
end

function GameTagLayer:ctor(scene)
	self._scene = scene
	--老虎机状态
	self.mSlotsStatus = -1 
	--var
	self.mLightBlockArr = {}
	self.mClipBlockArr = {}
	--记录当前tag
	self.mTagArr = {}
	--记录当前tag位置索引
	self.mTagPosIdxArr = {}
	--当前spin结果
	self.mSpinRetArr = nil
	--所有tag，ready标识
	self.mTagRetReadyArr ={}
	--tag，ready的数量
	self.mTagReadyCnt = 0
	--本次spin结果
	self.mTagCurSpinRetArr = {}
	--记录8条线
	self.mLineArr = {}
	--当前赢线情况
	self.mcbWinLine = nil
	--各tag可停止记录
	self.mTagStopArr = {{}, {}, {}, {}, {}, {}, {} ,{} ,{}}
	--
	self:setTagStopAll(0)
	--各tag滚动速率
	self.mTagRollRateArr = {1, 1, 1, 1, 1, 1, 1, 1, 1}
	--当前位移一次时间
	self.mDuringMoveOnce = DisplayConfig.DURING_MOVEONCE
	--是否自动加速
	self.mIsAutoSpeed = false


	--layout
	for i = 1, DisplayConfig.CNT_ROLL do
		self.mTagArr[i] = {}
		self.mTagPosIdxArr[i] = {}
		self.mTagRetReadyArr[i] = {}
		--light
		self.mLightBlockArr[i] = self:getChildByName("img_light_" .. i)
		self.mLightBlockArr[i]:setVisible(false)
		--剪切层
		local stencil = display.newSprite("game/cliper/c_block_" .. i .. ".png")
		stencil:setAnchorPoint(cc.p(0.0, 0.0))
		self.mClipBlockArr[i] = cc.ClippingNode:create(stencil)
		self.mClipBlockArr[i]:move(cc.p(self:getChildByName("img_block_" .. i):getPosition()))
		self.mClipBlockArr[i]:addTo(self)
		self.mClipBlockArr[i]:setLocalZOrder(2)
		--随机摆放tag
		local tagIdxArr = GameLogic.randTagIdx_5()
		for j =1, DisplayConfig.CNT_TAG do
			local tagIdx = tagIdxArr[j]
			local spTag = display.newSprite("game/tag/" .. DisplayConfig.TAG_ARR[tagIdx])
			spTag:move(DisplayConfig.TAG_POS[i][j])
			spTag:addTo(self.mClipBlockArr[i])
			--所有tag
			self.mTagArr[i][j] = spTag
			--所有tag位置索引
			self.mTagPosIdxArr[i][j] = j
			--所有tag结果ready标识
			self.mTagRetReadyArr[i][j] = 0
		end
	end
	--箭头层
	self:getChildByName("img_arrow"):setLocalZOrder(DisplayConfig.ZORDER_TAG_ARROW)
	--存线
	for i = 1, DisplayConfig.CNT_LINE do
		self.mLineArr[i] = self:getChildByName("img_line_" .. i)
		self.mLineArr[i]:setLocalZOrder(3)
	end

	--tag7Ani
	AnimationMgr.loadAnimationFromFrame("game/tag7ani/%d.png", 1, 17, "tag7ani", AnimationMgr.LOCAL_RES)

	---------------------------------------------------------------------
	local function monitor_stoped()
		if self.mSlotsStatus == GameTagLayer.ST_WILLSTOP and self:isAllTagRetReady() then
			self:onSpinHasStoped()
		end
	end
	--监视器(逐帧)
	self.mMonitor = nextTick_eachSecond(function()
		monitor_stoped()
		self._scene:onMonitorZimu()
	end, 0.0)
	---------------------------------------------------------------------

	self.mSlotsStatus = GameTagLayer.ST_FREE
end

--设置停止标记所有
function GameTagLayer:setTagStopAll(isStop)
	for i = 1, DisplayConfig.CNT_ROLL do
		for j = 1, DisplayConfig.CNT_TAG do
			self.mTagStopArr[i][j] = isStop
		end
	end
end

--设置一个格子停止标记
function GameTagLayer:setTagStopOneGrid(i)
	for j = 1, DisplayConfig.CNT_TAG do
		self.mTagStopArr[i][j] = 1
	end
end

--重置部分变量
function GameTagLayer:resetVar()
	--各tag滚动速率
	self.mTagRollRateArr = {1, 1, 1, 1, 1, 1, 1, 1, 1}
	--各tag可停止记录
	self:setTagStopAll(0)
	--tag，ready的数量
	self.mTagReadyCnt = 0
	--本次spin结果
	self.mTagCurSpinRetArr = nil
	for i =1, DisplayConfig.CNT_ROLL do
		for j = 1, DisplayConfig.CNT_TAG do
			--所有tag结果ready标识
			self.mTagRetReadyArr[i][j] = 0
		end
	end
	self.mcbWinLine = nil
	self._scene._scene:onResetWinScore()
end

--重置界面
function GameTagLayer:resetDisplay()
	--隐藏全盘闪烁
	for i =1, DisplayConfig.CNT_ROLL do
		self.mLightBlockArr[i]:stopAllActions()
		self.mLightBlockArr[i]:setVisible(false)
	end
	--隐藏线
	for i =1, DisplayConfig.CNT_LINE do
	    self.mLineArr[i]:setVisible(false)
	end
	--取消7动画
	for i = 1, DisplayConfig.CNT_ROLL do
		self.mTagArr[i][2]:stopAllActions()
	end	
end

--是否空闲状态
function GameTagLayer:isStatusFree()
	return self.mSlotsStatus == GameTagLayer.ST_FREE
end

--所有tag结果准备好
function GameTagLayer:isAllTagRetReady()
	return self.mTagReadyCnt >= DisplayConfig.CNT_ALLTAG
end

function GameTagLayer:rollAllTag()
	cclog("GameTagLayer:rollAllTag===>")
	for i = 1,DisplayConfig.CNT_ROLL do
		for j = 1, DisplayConfig.CNT_TAG do
			self:moveOneTag(i, j)
		end
	end
end

function GameTagLayer:moveOneTag(i, j)
	local function roll()
		self:moveOneTag(i, j)
	end

	local curPosIdx = self.mTagPosIdxArr[i][j]--1~5
	cclog("GameTagLayer:moveOneTag===>i: " .. i .. "=j: " .. j .. "=curPosIdx: " .. curPosIdx)
	local spCurTag = self.mTagArr[i][j]
	--
	if curPosIdx >=1 and curPosIdx <= DisplayConfig.CNT_POS - 1 then--1~4
		local nextPosIdx = curPosIdx - 1
		if nextPosIdx < 1 then nextPosIdx = DisplayConfig.CNT_POS end
		cclog("nextPosIdx: " .. nextPosIdx)
		--
		if self.mTagRetReadyArr[i][j] == 1 and j == curPosIdx then--各个tag回到初始位置
			self.mTagReadyCnt = self.mTagReadyCnt + 1
			cclog("self.mTagReadyCnt=" .. self.mTagReadyCnt)
		else--正常移动
			local during = DisplayConfig.DURING_MOVEONCE * self.mTagRollRateArr[i]
			local nextPos = DisplayConfig.TAG_POS[i][nextPosIdx]
			local actMove = cc.MoveTo:create(during, nextPos)
			local callFunc = cc.CallFunc:create(roll)
			spCurTag:runAction(cc.Sequence:create(actMove, callFunc))
		end
	else--5
		cclog("setPosIdx: " .. DisplayConfig.CNT_POS - 1)
		spCurTag:move(DisplayConfig.TAG_POS[i][DisplayConfig.CNT_POS - 1])
		local during = DisplayConfig.DURING_MOVEONCE
		--查看是否停止(每个格子1号位先赋值结果)
		if self.mTagStopArr[i][j] == 1 then
			if j == 1 then
				--减速
				self.mTagRollRateArr[i] = DisplayConfig.TAG_ROLLSTOP_RATE
				--标记改图标以就绪
				self.mTagRetReadyArr[i][j] = 1
				spCurTag:setTexture("game/tag/" .. DisplayConfig.TAG_ARR[self.mTagCurSpinRetArr[i][j] + 1])
			elseif self.mTagRetReadyArr[i][1] == 1 then
				--标记改图标以就绪
				self.mTagRetReadyArr[i][j] = 1
				--检查美女图
				if self.mcbGirlPicIndex > 1 and j == 2 then
					spCurTag:setTexture("game/sptag/sptag" .. self.mcbGirlPicIndex .. "_" .. i .. ".png")
					spCurTag:setLocalZOrder(DisplayConfig.ZORDER_TAG_MEINV)
					self:setTagStopAll(1)--美女图需要同时停
				else
					spCurTag:setTexture("game/tag/" .. DisplayConfig.TAG_ARR[self.mTagCurSpinRetArr[i][j] + 1])
				end
			end
		else
			spCurTag:setTexture("game/tag/" .. DisplayConfig.TAG_ARR[GameLogic.randTagIdx()])
		end
		--此tag到达终点位置
		if self.mTagRetReadyArr[i][j] == 1 and j == curPosIdx then
			self.mTagReadyCnt = self.mTagReadyCnt + 1
			cclog("self.mTagReadyCnt=" .. self.mTagReadyCnt)
		else
			during = during * self.mTagRollRateArr[i]
			local callFunc = cc.CallFunc:create(roll)
			spCurTag:runAction(cc.Sequence:create(cc.DelayTime:create(during), callFunc))
		end
	end


	--end
	self.mTagPosIdxArr[i][j] = curPosIdx - 1
	if self.mTagPosIdxArr[i][j] < 1 then self.mTagPosIdxArr[i][j] = DisplayConfig.CNT_POS end
end

---------------------被动----------------------------------------
function GameTagLayer:onSpin()
	cclog("GameTagLayer:onSpin(===>")
	self:resetVar()
	self.mSlotsStatus = GameTagLayer.ST_SPIN
	self:rollAllTag()
	self:runAction(cc.Sequence:create(cc.DelayTime:create(DisplayConfig.DURING_ROLLNORMAL), cc.CallFunc:create(function()
		if self.mIsAutoSpeed then
			self:onSpeedStop()
		else
		   self:onNatureStop()
		end
	end)))
	--美女图次数减1
	if self._scene._scene.mcbGirlAwardCount > 0 then
	   self._scene._scene.mcbGirlAwardCount = self._scene._scene.mcbGirlAwardCount - 1
	   self._scene:onShowBonusSpinInfo()
	end
	--播放音效
	self._scene:playSoundEffect("sound/s_rolling.mp3")
end

--自然停止
function GameTagLayer:onNatureStop()
	cclog("GameTagLayer:onNatureStop===>")
	if self.mSlotsStatus == GameTagLayer.ST_SPIN then
		self.mSlotsStatus = GameTagLayer.ST_WILLSTOP
		local order = 1
		--自然停止处理，如果未回结果，则持续监测
		self.mNatureStopScheduler = nextTick_eachSecond(function()
			   if self.mTagCurSpinRetArr then
				   self:setTagStopOneGrid(DisplayConfig.TAG_NATURESTOP_ORDER[order])
				   order = order + 1
				   if order >= DisplayConfig.CNT_ROLL + 1 then
				   	  G_unSchedule(self.mNatureStopScheduler)
				   	  self.mNatureStopScheduler = nil
				   end
				end
			end, DisplayConfig.INTERVAL_TAG_NATURESTOP)
	end	
end

--加速停止
function GameTagLayer:onSpeedStop()
	cclog("GameTagLayer:onSpeedStop===>")
	if self.mSlotsStatus == GameTagLayer.ST_SPIN then
		self.mSlotsStatus = GameTagLayer.ST_WILLSTOP
		--自然停止处理，如果未回结果，则持续监测
		self.mSpeedStopScheduler = nextTick_eachSecond(function()
			   if self.mTagCurSpinRetArr then
			   	  self:setTagStopAll(1)
			   	  G_unSchedule(self.mSpeedStopScheduler)
			   	  self.mSpeedStopScheduler = nil
			   end
			end, DisplayConfig.INTERVAL_TAG_SPEEDSTOP)
	end	
end

--手动停止
function GameTagLayer:onStop()
	cclog("GameTagLayer:onStop===>")
	if self.mTagCurSpinRetArr then
		if self.mNatureStopScheduler then
			G_unSchedule(self.mNatureStopScheduler)
			self.mNatureStopScheduler = nil
		end
		self:setTagStopAll(1)
		self.mSlotsStatus = GameTagLayer.ST_WILLSTOP
		return true
	end
	return false
end

function GameTagLayer:onSpinRet(cmd_data)
	self.mTagCurSpinRetArr = cmd_data.cbHandReelData
	self.mcbWinLine = cmd_data.cbWinLine[1]
	self.mcbGirlPicIndex = cmd_data.cbGirlPicIndex --美女图倍数(1标识没有,2,3,4)
	--及时更新jp池
	self._scene:onRefreshJP()
end

--滚动彻底停止
function GameTagLayer:onSpinHasStoped()
	cclog("GameTagLayer:onSpinHasStoped===>")
    --停止滚动音效
	self._scene:stopSoundEffect()
	--
	self.mSlotsStatus = GameTagLayer.ST_STOPPED
	self:onBlink()
	self:onHandleWin()
	self._scene.mBtnStop:setEnabled(false)
end

--blink(线和特效)
function GameTagLayer:onBlink()
	cclog("GameTagLayer:onBlink===>")
	if self._scene._scene.mlGirlWinScore > 0 then--美女得分
		--播放音效
		self._scene:playSoundEffect("sound/s_girlscore.mp3")
	elseif self._scene._scene.mlAllWinScore > 0 then--全盘得分
		for i =1, DisplayConfig.CNT_ROLL do
			self.mLightBlockArr[i]:setVisible(true)
			local act1 = cc.FadeIn:create(DisplayConfig.DURING_ALLPANEL_BLINK * 0.5)
			local act2 = cc.FadeOut:create(DisplayConfig.DURING_ALLPANEL_BLINK * 0.5)
			local actSeq = cc.Sequence:create(act1, act2)
			self.mLightBlockArr[i]:runAction(cc.RepeatForever:create(actSeq))
		end
	else--线得分
		for i =1, DisplayConfig.CNT_LINE do
			local isShow = self.mcbWinLine[i]
			self.mLineArr[i]:setVisible(isShow)
		end
	end

	--2个7以上得分(找出9个格子中在1,2,3号位出现的7)
	--效果持续到下分结束
	if self._scene._scene.mlNumber7WinScore > 0 then
		for i = 1, DisplayConfig.CNT_ROLL do
			local param = AnimationMgr.getAnimationParam()
		    param.m_fDelay = 0.1
		    param.m_strName = "tag7ani"
		    local animate = AnimationMgr.getAnimate(param, false)
			if self.mTagCurSpinRetArr[i][2] == 0 then
				self.mTagArr[i][2]:runAction(cc.RepeatForever:create(animate))
			end
		end
	end
	--额外得分
	if self._scene._scene.mlExtraWinScore > 0 then
		self._scene:onShowExtraPanel(self._scene._scene.mlExtraWinScore)
	end
	--美女图奖励
	self._scene:onShowBonusSpinInfo()

	--检查播放音效
	if self._scene._scene.mNormalWinScore > 0 then
	   self._scene:playSoundEffect("sound/s_winscore.mp3")
	end

end

--处理赢钱
function GameTagLayer:onHandleWin()
	self._scene:onRefreshMoneyInfo()
	nextTick_frameCount(function()
		--动画下分
		if self._scene then
			self._scene:onHandleAddWinScore()
		end
	end, 1.0)
	if self._scene._scene.mNormalWinScore <= 0 then
	   self._scene:onChangeZimu("gameover")
	else
		self._scene:onChangeZimu("win")
	end
end

--结束加分
function GameTagLayer:onFinishAddScore()
	cclog("GameTagLayer:onFinishAddScore")
	--隐藏赢钱相关特效
	self:resetDisplay()
	--
	self.mSlotsStatus = GameTagLayer.ST_FREE
end

--进入自动模式
function GameTagLayer:onAutoMode(isAuto)
	if isAuto then
		self.mDuringMoveOnce = DisplayConfig.DURING_MOVEONCE * DisplayConfig.RATE_AUTO
	else
		self.mDuringMoveOnce = DisplayConfig.DURING_MOVEONCE
		self.mIsAutoSpeed = false
	end
end

--进入自动加速模式
function GameTagLayer:onAutoSpeedMode(isAutoSpeed)
	self.mIsAutoSpeed = isAutoSpeed
end

return GameTagLayer