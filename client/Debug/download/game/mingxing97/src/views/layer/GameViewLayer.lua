-- Name: GameViewLayer
-- Func: 明星97游戏界面
-- Author: Johny

local ExternalFun =  appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local module_pre = "game.mingxing97.src"
local cmd = appdf.req(module_pre .. ".models.CMD_Game")
local DisplayConfig = appdf.req(module_pre .. ".models.DisplayConfig")
local GameTagLayer = appdf.req(module_pre .. ".views.layer.GameTagLayer")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")


local GameViewLayer = class("GameViewLayer",function(scene)
		local gameViewLayer =  cc.CSLoader:createNode(device.writablePath .. cmd.RES_PATH.. "game/GameScene.csb")
    return gameViewLayer
end)

-------------------------常量定义--------------------------
local BTN_RETURN = 1
local BTN_CHECKAWARD = 2
local BTN_CHEAT = 4
local BTN_AUTO = 11
local BTN_AUTOSPEED = 12
local BTN_CANCELAUTO = 13
local BTN_START = 14
local BTN_STOP = 15
local BTN_BET = 16
local BTN_ADD = 17


--字幕候选图
local ARR_ZIMU = {}
ARR_ZIMU["bet"] = "game/zimu/z_bet.png"
ARR_ZIMU["gameover"] = "game/zimu/z_gameover.png"
ARR_ZIMU["start"] = "game/zimu/z_start.png"
ARR_ZIMU["win"] = "game/zimu/z_win.png"

--声音图
local ARR_SOUNDIMG = {"game/g_sound1.png", "game/g_sound3.png"}


--押分数组
local ARR_BETS = {80, 160, 240, 320, 400}

--线数
local CNT_LINE = 8



function GameViewLayer:onExit()
    --移除该子模块搜索路径
    GG_RemoveSearchPath(device.writablePath .. cmd.RES_PATH)
    --
    G_unSchedule(self.mTimeSchduler)
    self.mTimeSchduler = nil
    --
    self.mTagLayer:destroy()
    --
    ExternalFun.SAFE_RELEASE(self.mActShareLight)
	self.mActShareLight = nil
end

function GameViewLayer:ctor(scene)
	self._scene = scene
	ExternalFun.registerNodeEvent(self)
	--var
	self.mIsShowingAwardPanel = false
	self.mCurBet = 0     --当前押分
	self.mCurCredit = 0  --当前身上分
	self.mCurUserScore = GlobalUserItem.lUserScore --身上的金币
	self.mIsAutoMode = false -- 是否自动模式

	--添加沙盒路径
    cc.FileUtils:getInstance():addSearchPath(device.writablePath .. cmd.RES_PATH)
	self:layoutUI()

	--时间clock
	self.mTimeSchduler = nextTick_eachSecond(function()
		self.mLbDate:setString(os.date("%Y-%m-%d", os.time()))
		self.mLbTime:setString(os.date("%H:%M:%S", os.time()))
	end, 1.0)
end

function GameViewLayer:layoutUI()
	local function btncallback(ref, tType)
		cclog("btncallback==>")
        if tType == ccui.TouchEventType.ended then
            self:onButtonClickedEvent(ref:getTag(),ref)
        elseif tType == ccui.TouchEventType.began then
        	self:onButtonTouchBeganEvent(ref:getTag(), ref)
        end
    end

	--bg
	self.mImgbg = appdf.getNodeByName(self, "img_bg")

	--return btn
	local btn_return = appdf.getNodeByName(self, "btn_return")
	btn_return:setTag(BTN_RETURN)
	btn_return:addTouchEventListener(btncallback)

	--作弊
	self.mBtnCheat = appdf.getNodeByName(self, "btn_zuobi")
	self.mBtnCheat:setTag(BTN_CHEAT)
	self.mBtnCheat:addTouchEventListener(btncallback)
	self.mBtnCheat:setVisible(G_CAN_CHEAT())

	--[2显示1]
	self.mBtnStop = appdf.getNodeByName(self, "btn_stop")--停止
	self.mBtnStop:setTag(BTN_STOP)
	self.mBtnStop:addTouchEventListener(btncallback)
	self.mBtnStop:setVisible(false)
	self.mBtnStop:setEnabled(false)
	self.mBtnStart = appdf.getNodeByName(self, "btn_start")--开始
	self.mBtnStart:setTag(BTN_START)
	self.mBtnStart:addTouchEventListener(btncallback)
	self.mBtnStart:setVisible(true)
    --[3显示1]
	self.mBtnCancelAuto = appdf.getNodeByName(self, "btn_cancel")--取消自动
	self.mBtnCancelAuto:setTag(BTN_CANCELAUTO)
	self.mBtnCancelAuto:addTouchEventListener(btncallback)
	self.mBtnCancelAuto:setVisible(false)
	self.mBtnAuto = appdf.getNodeByName(self, "btn_auto")--自动
	self.mBtnAuto:setTag(BTN_AUTO)
	self.mBtnAuto:addTouchEventListener(btncallback)
	self.mBtnAuto:setVisible(true)
	self.mBtnAutoSpeed = appdf.getNodeByName(self, "btn_speed")--自动加速
	self.mBtnAutoSpeed:setTag(BTN_AUTOSPEED)
	self.mBtnAutoSpeed:addTouchEventListener(btncallback)
	self.mBtnAutoSpeed:setVisible(false)

	self.mBtnAddScore = appdf.getNodeByName(self, "btn_add")--加分
	self.mBtnAddScore:setTag(BTN_ADD)
	self.mBtnAddScore:addTouchEventListener(btncallback)	
	self.mBtnBet = appdf.getNodeByName(self, "btn_bet")--押分
	self.mBtnBet:setTag(BTN_BET)
	self.mBtnBet:addTouchEventListener(btncallback)	

	self.mBtnCheckJP = appdf.getNodeByName(self, "btn_checkjp")--查看大奖
	self.mBtnCheckJP:setTag(BTN_CHECKAWARD)
	self.mBtnCheckJP:addTouchEventListener(btncallback)	

	--数字
	self.mLbBetCnt = appdf.getNodeByName(self, "lb_bet")--押分
	self.mLbBetCnt:setString("0")
	self.mLbCreditCnt = appdf.getNodeByName(self, "lb_credit")--身上分
	self.mLbCreditCnt:setString("0")
	self.mLbJpCnt = appdf.getNodeByName(self, "lb_jp")--大奖
	self.mLbWinCnt = appdf.getNodeByName(self, "lb_win")--赢钱
	self.mLbWinCnt:setString("0")

	--美女图奖励数字
	self.mLbSpecialCnt = appdf.getNodeByName(self, "lb_special_cnt")--剩余次数
	self.mLbSpecialCnt:setVisible(false)
	self.mSpSpecialTimes = appdf.getNodeByName(self, "sp_special_times")--奖励倍数x
	self.mSpSpecialTimes:setVisible(false)
	self.mLbSpecialTimes = appdf.getNodeByName(self, "lb_special_times")--奖励倍数
	self.mLbSpecialTimes:setVisible(false)


	--line score
	self.mLineScoreLabelArr = {}
	for i =1, CNT_LINE do
		self.mLineScoreLabelArr[i] = appdf.getNodeByName(self, "lb_scoreline_" .. i)
		self.mLineScoreLabelArr[i]:setString("0")
	end

	--字幕
	local node_zimu = appdf.getNodeByName(self, "node_zimu")
	self.mZimu = cc.Sprite:create(ARR_ZIMU["bet"])
	self.mZimu:addTo(node_zimu)

	--分享
	self.mShareLayer = appdf.getNodeByName(self, "node_moment")
	self.mShareLayer:setLocalZOrder(3)
	self.mShareLayer:setVisible(false)
	self:layoutExtraPanel()
	--大奖层
	self.mPanelAward = appdf.getNodeByName(self, "node_awardpanel")
	self.mPanelAward:setLocalZOrder(2)
	self.mPanelAward:setVisible(false)

	--个人信息
	self.mLbID = appdf.getNodeByName(self, "lb_id")
	self.mLbCoins = appdf.getNodeByName(self, "lb_coins")
	self.mLbDate = appdf.getNodeByName(self, "lb_date")
	self.mLbTime = appdf.getNodeByName(self, "lb_time")
	self.mLbName = appdf.getNodeByName(self, "lb_name")
	self.mRoomName = appdf.getNodeByName(self, "lb_roomname")
	local lb_gamename = appdf.getNodeByName(self, "lb_gamename")
	lb_gamename:setString(cmd.GAME_NAME)

	--tag层
	self.mTagLayer = GameTagLayer:create(self)
	self.mTagLayer:addTo(self)
	self.mTagLayer:setLocalZOrder(1)

	--广播
	self.mImgBroadCast = appdf.getNodeByName(self, "img_broadcast")
	self.mImgBroadCast:setVisible(false)
	self.mLbBroadCast = appdf.getNodeByName(self, "lb_broadcast")
	self.mNodeBCInit = appdf.getNodeByName(self, "node_bc_init")
end

--布局额外奖励界面
function GameViewLayer:layoutExtraPanel()
	local btn_close = self.mShareLayer:getChildByName("btn_close")
	btn_close:addTouchEventListener(function (ref, tType)
		if tType == ccui.TouchEventType.ended then
		   self:onHideShareLayerInfo(true)
		end
	end)
	local btn_moment = self.mShareLayer:getChildByName("btn_moment")
	btn_moment:addTouchEventListener(function (ref, tType)
		if tType == ccui.TouchEventType.ended then
		    local target = yl.ThirdParty.WECHAT_CIRCLE
			local function sharecall( isok )
			    if type(isok) == "string" and isok == "true" then
			    	cclog("GameViewLayer:layoutExtraPanel===>award:100")
			    	self:onHideShareLayerInfo(true)
			    end
			end
            -- 截图分享
            local framesize = cc.Director:getInstance():getOpenGLView():getFrameSize()
            local area = cc.rect(0, 0, framesize.width, framesize.height)
            local imagename = "grade_share_" .. os.time() .. ".jpg"
            captureScreenWithArea(area, imagename, function(ok, savepath)
                if ok then
                	--分享截图
                	local url = "none"
					local strContent = string.format(DisplayConfig.CONTENT_SHARE, self._scene.mlExtraWinScore)
					cclog("GameViewLayer:layoutExtraPanel===>" .. strContent)
                    MultiPlatform:getInstance():shareToTarget(target, sharecall, G_GAME_NAME, strContent, url, savepath, "true")    
                end
            end)
		end
	end)
	--载入分享动画
	self.mActShareLight = ExternalFun.loadTimeLine("game/node_shareaward.csb" )
	ExternalFun.SAFE_RETAIN(self.mActShareLight)	
end

--隐藏分享层信息
function GameViewLayer:onHideShareLayerInfo(isHide)
	appdf.getNodeByName(self.mShareLayer, "btn_close"):setVisible(not isHide)
	appdf.getNodeByName(self.mShareLayer, "img_title"):setVisible(not isHide)
	appdf.getNodeByName(self.mShareLayer, "btn_moment"):setVisible(not isHide)
end

function GameViewLayer:onButtonTouchBeganEvent(tag, ref)
	if tag == BTN_ADD then
	   self:onAdd()
	   local function addtick()
	      self.mAddTick = nextTick_eachSecond(handler(self, self.onAdd), DisplayConfig.INTERVAL_ADD)
	      self.mAddDelayTick = nil
	   end
	   self.mAddDelayTick = nextTick_frameCount(addtick, DisplayConfig.DELAY_ADD)  
	end
end

function GameViewLayer:onButtonClickedEvent(tag, ref)
	if tag == BTN_STOP then
		self:onStop()
	elseif tag == BTN_START then
		self:onStart()
	elseif tag == BTN_AUTO then
		self:onAuto()
	elseif tag == BTN_AUTOSPEED then
		self:onAutoSpeed()
	elseif tag == BTN_CANCELAUTO then
		self:onCancelAuto()
	elseif tag == BTN_BET then
		self:onBet()
	elseif tag == BTN_ADD then
		self:onStopAdd()
	elseif tag == BTN_RETURN then
		self:onRequestQuit()
	elseif tag == BTN_CHECKAWARD then
		self:onRequestAwardPanel()
	elseif tag == BTN_CHEAT then
		self:onCheat()
	end
end

--请求作弊
function GameViewLayer:onCheat()
	self._scene:onShowAdminMainLayer()
end

--请求退出游戏
function GameViewLayer:onRequestQuit()
	self._scene:onQueryExitGame()
end

--请求大奖记录
function GameViewLayer:onRequestAwardPanel()
	if self.mIsShowingAwardPanel then
		self:onHideAwardPanel()
	else
		self._scene:showPopWait()
		self._scene:onCheckAwardRecord()
	end
	self.mIsShowingAwardPanel = not self.mIsShowingAwardPanel
end

--显示大奖记录，需要等服务器返回
function GameViewLayer:onShowAwardPanel(cmd_data)
	self._scene:dismissPopWait()
	--准备数据
	local record = cmd_data.BigAwardRecord[1]
	for i = 1, #record do
		self.mPanelAward:getChildByName("lb_" .. i):setString("" .. record[i])
	end
	--展示
	self.mPanelAward:setVisible(true)
	for i = BTN_AUTO, BTN_ADD do
		self.mImgbg:getChildByTag(i):setEnabled(false)
	end
end

--关闭大奖记录
function GameViewLayer:onHideAwardPanel()
	self.mPanelAward:setVisible(false)
	for i = BTN_AUTO, BTN_ADD do
		self.mImgbg:getChildByTag(i):setEnabled(true)
	end
end

--刷新信息
function GameViewLayer:onRefreshInfo()
    local testen = cc.Label:createWithSystemFont("A","Arial", 24)
    self._enSize = testen:getContentSize().width
    local testcn = cc.Label:createWithSystemFont("游","Arial", 24)
    self._cnSize = testcn:getContentSize().width
    --
	self.mLbID:setString("ID:" .. GlobalUserItem.dwGameID)
	self.mLbName:setString("昵称:" .. string.stringEllipsis(GlobalUserItem.szNickName, self._enSize, self._cnSize, 220))
	self.mRoomName:setString(self._scene.szGameRoomName)
	self:onRefreshMoneyInfo()
end
--刷新与钱相关的信息
function GameViewLayer:onRefreshMoneyInfo()
	self.mLbCoins:setString("金币:" .. self.mCurUserScore)
	self.mLbCreditCnt:setString("" .. self.mCurCredit)
	self.mLbWinCnt:setString("" .. self._scene.mNormalWinScore)
end
--刷新jp奖池
function GameViewLayer:onRefreshJP()
	self.mLbJpCnt:setString("" .. self._scene.mlJackPot)
end

--押分
function GameViewLayer:onBet()
	cclog("GameViewLayer:onBet===>")
	if self.mCurBet >= 400 then
	   self.mCurBet = 80
	elseif self.mCurCredit >= 80 then
		self.mCurBet = self.mCurBet + 80
	else
		--押分失败
		showToast(self, "分数不够，请上分！", 2)
	end
	self.mLbBetCnt:setString(self.mCurBet)
	--分配到分数线上
	for i = 1, CNT_LINE do 
		self.mLineScoreLabelArr[i]:setString("" .. self.mCurBet / CNT_LINE)
	end
end

--上分
function GameViewLayer:onAdd()
	cclog("GameViewLayer:onAdd===>")
	if self.mCurUserScore <= 0 then return end
	local costCoins = self._scene.miUnitUpScore * self._scene.miChangeRadio
	if costCoins <= self.mCurUserScore then
		self.mCurCredit = self.mCurCredit + self._scene.miUnitUpScore
		self.mCurUserScore = self.mCurUserScore - costCoins
	else
		local add = self.mCurUserScore / self._scene.miUnitUpScore
		local addRest = self.mCurUserScore % self._scene.miUnitUpScore
		cclog("GameViewLayer:onAdd==>add: " .. add .. "=addRest: " .. addRest)
		self.mCurCredit = self.mCurCredit + add
		self.mCurUserScore = addRest
	end
	self:onRefreshMoneyInfo()
	self:playSoundEffect("sound/s_addscore.mp3")
end

--停止上分
function GameViewLayer:onStopAdd()
	if self.mAddTick then
		G_unSchedule(self.mAddTick)
		self.mAddTick = nil
	elseif self.mAddDelayTick then
		G_unSchedule(self.mAddDelayTick)
		self.mAddDelayTick = nil
	end
end

function GameViewLayer:onSpinRet(cmd_data)
	self.mTagLayer:onSpinRet(cmd_data)

end

function GameViewLayer:onStop()
	if self.mTagLayer:onStop() then
	   self.mBtnStop:setEnabled(false)
	end
end

function GameViewLayer:canStart()
	if self.mCurBet == 0 then
		showToast(self, "请先押分！", 2.0)
	    return false
    end
	if self.mCurCredit < self.mCurBet then
		showToast(self, "分数不足，请上分！", 2.0)
		return false
	end

	return true
end

function GameViewLayer:onStart()
	if not self:canStart() then return end
	self.mTagLayer:onSpin()
	self._scene:onSpin(self.mCurBet)
	--按钮状态
	self:onBtnStatusDuringSpin()
	--扣钱
	self.mCurCredit = self.mCurCredit - self.mCurBet
	self:onRefreshMoneyInfo()
	--zimu
	self:onChangeZimu()
	--如果额外奖励显示，则隐藏
	if self.mShareLayer:isVisible() then
	   self:stopAllActions()
	   self.mShareLayer:setVisible(false)
	end

	return true
end

--[[
	自动三合一按钮：
	1.自动
	2.自动加速
	3.取消自动
]]
function GameViewLayer:onAutoSpeed()
	self.mBtnAutoSpeed:setVisible(false)
	self.mBtnCancelAuto:setVisible(true)
	self.mTagLayer:onAutoSpeedMode(true)
end

function GameViewLayer:onAuto()
	if self.mTagLayer:isStatusFree() then
		self:onStart()
	end
	if self:canStart() then
		self.mIsAutoMode = true
		self.mTagLayer:onAutoMode(true)
		self.mBtnAuto:setVisible(false)
		self.mBtnAutoSpeed:setVisible(true)
		self.mBtnStop:setEnabled(false)
	end
end

function GameViewLayer:onCancelAuto()
   self.mIsAutoMode = false
   self.mTagLayer:onAutoMode(false)
   self.mTagLayer:onAutoSpeedMode(false)
   self.mBtnAuto:setVisible(true)
   self.mBtnCancelAuto:setVisible(false)
end


--设置spin时按钮状态
function GameViewLayer:onBtnStatusDuringSpin()
	self.mBtnStart:setVisible(false)
	self.mBtnStop:setVisible(true)
	self.mBtnStop:setEnabled(true)
	self.mBtnAddScore:setEnabled(false)
	self.mBtnBet:setEnabled(false)
	self.mBtnCheckJP:setEnabled(false)
end


--恢复按钮状态
function GameViewLayer:onResetBtn()
	self.mBtnStop:setVisible(false)
	self.mBtnStart:setVisible(true)
	self.mBtnAddScore:setEnabled(true)
	self.mBtnBet:setEnabled(true)
	self.mBtnCheckJP:setEnabled(true)
	--如果美女次数未用完不可押分
	if self._scene.mcbGirlAwardCount > 0 then
	   self.mBtnBet:setEnabled(false)
	end
end

--显示美女图奖励次数和倍数
function GameViewLayer:onShowBonusSpinInfo()
	if self._scene.mcbGirlAwardCount > 0 then
		self.mLbSpecialCnt:setString("" .. self._scene.mcbGirlAwardCount):setVisible(true)
		self.mLbSpecialTimes:setString("" .. self._scene.mcbGirlAwardTimes):setVisible(true)
		self.mSpSpecialTimes:setVisible(true)
	else
		self.mLbSpecialCnt:setVisible(false)
		self.mLbSpecialTimes:setVisible(false)
		self.mSpSpecialTimes:setVisible(false)
	end
end

--播放下分音效
local _is_play_unscore = false
function GameViewLayer:onPlayUnScoreSound(_play)
	if _play and not _is_play_unscore then
		self:playBgm("sound/s_unscore.mp3", true)
	elseif not _play then
		self:stopBgm()
	end
end

--下分
function GameViewLayer:onHandleAddWinScore()
	if self._scene.mlJackPotWinScore > 0 then
		cclog("GameViewLayer:onHandleAddWinScore=jp=>" .. self._scene.mlJackPotWinScore)
		local act = nil
		local callFunc = cc.CallFunc:create(function()
			   if self._scene.mlJackPotWinScore > 0 then
				   self.mCurCredit = self.mCurCredit + 10
				   self.mLbCreditCnt:setString("" .. self.mCurCredit)
				   self._scene.mlJackPotWinScore = self._scene.mlJackPotWinScore - 10
				   self._scene.mlJackPot = self._scene.mlJackPot - 10
				   self:onRefreshJP()
				else
					self:stopAction(act)
					act = nil
					self:onHandleAddWinScore()
				end
			end)
		act = cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(DisplayConfig.INTERVAL_ADDSCORE), callFunc))
		self:runAction(act)
		--
		self:onPlayUnScoreSound(true)
	elseif self._scene.mNormalWinScore > 0 then
		cclog("GameViewLayer:onHandleAddWinScore=win=>" .. self._scene.mNormalWinScore)
		local act = nil
		local callFunc = cc.CallFunc:create(function()
			   if self._scene.mNormalWinScore > 0 then
				   self.mCurCredit = self.mCurCredit + 10
				   self.mLbCreditCnt:setString("" .. self.mCurCredit)
				   self._scene.mNormalWinScore = self._scene.mNormalWinScore - 10
				   self.mLbWinCnt:setString("" .. self._scene.mNormalWinScore)
				else
					self:stopAction(act)
					act = nil
					self:onHandleAddWinScore()
				end
			end)
		act = cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(DisplayConfig.INTERVAL_ADDSCORE), callFunc))
		self:runAction(act)
		--
		self:onPlayUnScoreSound(true)
	elseif self._scene.mlExtraWinScore > 0 then
		cclog("GameViewLayer:onHandleAddWinScore=extra=>" .. self._scene.mlExtraWinScore)
		local act = nil
		local callFunc = cc.CallFunc:create(function()
			   if self._scene.mlExtraWinScore > 0 and self.mShareLayer:isVisible() then
				   self.mCurCredit = self.mCurCredit + 10
				   self.mLbCreditCnt:setString("" .. self.mCurCredit)
				   self._scene.mlExtraWinScore = self._scene.mlExtraWinScore - 10
				   self:onSettingExtralScore(self._scene.mlExtraWinScore)
				else
					self:stopAction(act)
					act = nil
					--把剩余额外奖励加上
					self.mCurCredit = self.mCurCredit + self._scene.mlExtraWinScore
					self._scene.mlExtraWinScore = 0
					self.mLbCreditCnt:setString("" .. self.mCurCredit)
					--
					self:onHandleAddWinScore()
				end
			end)
		act = cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(DisplayConfig.INTERVAL_ADDSCORE), callFunc))
		self:runAction(act)
		--
		self:onPlayUnScoreSound(true)
	else
		self:onPlayUnScoreSound(false)
		self:onFinishAddScore()
	end
end

--结束加分
function GameViewLayer:onFinishAddScore()
	cclog("GameViewLayer:onFinishAddScore===>")
	self.mTagLayer:onFinishAddScore()
	self:onCheckAuto()
	--下分结束，隐藏额外奖励
	if self.mShareLayer:isVisible() then
	   self.mShareLayer:stopAllActions()
	   self.mShareLayer:setVisible(false)
	end
end

--检查是否自动
function GameViewLayer:onCheckAuto()
	if self.mIsAutoMode then
		if not self:onStart() then
		   self.mIsAutoMode = false
		   self.mBtnAuto:setVisible(true)
		   self.mBtnAutoSpeed:setVisible(false)
		   self.mBtnCancelAuto:setVisible(false)
		   self:onResetBtn()
		else
			self.mBtnStop:setEnabled(false)
		end
	else
		self:onResetBtn()
	end
end

--显示额外得分界面
function GameViewLayer:onShowExtraPanel(extrascore)
	--播放音效
	self:playSoundEffect("sound/s_extra.mp3")
	--显示额外信息
	self:onHideShareLayerInfo(false)
	--显示额外奖励
	self:onSettingExtralScore(extrascore)
	self.mShareLayer:setVisible(true)
	self.mActShareLight:gotoFrameAndPlay(0,true)
	self.mShareLayer:stopAllActions()
	self.mShareLayer:runAction(self.mActShareLight)
end

--设置额外得分
function GameViewLayer:onSettingExtralScore(extrascore)
	local base = 100000
	local theRest = extrascore
	for i = 1, 6 do
		local num = math.modf(theRest / base)
		self.mShareLayer:getChildByName("atlas_num_" .. i):setString(string.format("%1d", num))
		theRest = theRest % base
		base = base / 10
	end
end

--更换字幕
function GameViewLayer:onChangeZimu(key)
	if self.mCurZimuKey == key then return end
	self.mCurZimuKey = key
	if key and ARR_ZIMU[key] then
		cclog("GameViewLayer:onChangeZimu===>" .. key)
		if key == "bet" then
			local function setBet()
				self.mZimu:setTexture(ARR_ZIMU["bet"])
			end
			local function setStart()
				self.mZimu:setTexture(ARR_ZIMU["start"])
			end
			local actSeq = cc.Sequence:create(cc.CallFunc:create(setBet), cc.DelayTime:create(DisplayConfig.INTERVAL_ZIMU_SWITCH), cc.CallFunc:create(setStart), cc.DelayTime:create(DisplayConfig.INTERVAL_ZIMU_SWITCH))
			self.mZimuAct = cc.RepeatForever:create(actSeq)
			self:runAction(self.mZimuAct)
		else
			if self.mZimuAct then
			   self:stopAction(self.mZimuAct)
			   self.mZimuAct = nil
			end
			self.mZimu:setTexture(ARR_ZIMU[key])
			self.mZimu:setVisible(true)
		end
	else
		if self.mZimuAct then
		   self:stopAction(self.mZimuAct)
		   self.mZimuAct = nil
		end
		self.mZimu:setVisible(false)
	end
end

--字幕监视器(逐帧)
local interval_monitorzimu = 0
function GameViewLayer:onMonitorZimu()
	interval_monitorzimu = interval_monitorzimu + 1
	if interval_monitorzimu >= 30 then
		interval_monitorzimu = 0
		if self.mCurCredit <= 0 or self.mCurBet <= 0 or (self.mBtnStart:isVisible() and self.mBtnStart:isEnabled()) then
		   self:onChangeZimu("bet")
		end
	end
end


--播放广播
function GameViewLayer:onBroadCastPlay(str)
	self._scene.mIsBroadCasting = true
	self.mLbBroadCast:setString(str)
	self.mLbBroadCast:move(self.mNodeBCInit:getPosition())
	self.mImgBroadCast:setVisible(true)
	--
	local actMove = cc.MoveTo:create(DisplayConfig.DURING_BC_ONCE, cc.p(- self.mLbBroadCast:getContentSize().width, self.mNodeBCInit:getPositionY()))
	self.mLbBroadCast:runAction(cc.Sequence:create(actMove, cc.CallFunc:create(function()
		self.mImgBroadCast:setVisible(false)
		self._scene.mIsBroadCasting = false
	end)))
end

--播放音效
function GameViewLayer:playSoundEffect(path, isloop)
	cclog("GameViewLayer:playSoundEffect===>" .. path)
    if GlobalUserItem.bSoundAble == true then
        AudioEngine.playEffect(path, isloop)
    end	
end

--停止播放音效
function GameViewLayer:stopSoundEffect()
	cclog("GameViewLayer:stopSoundEffect===>" .. debug.traceback())
	AudioEngine.stopAllEffects()
end

--播放背景音乐
function GameViewLayer:playBgm(path, isLoop)
	AudioEngine.playMusic(path, isLoop)
end

--停止播放背景音乐
function GameViewLayer:stopBgm()
	AudioEngine.stopMusic()
end

return GameViewLayer