-- Name: GameViewLayer
-- Func: 天九游戏界面
-- Author: Johny

local cmd = appdf.req(appdf.GAME_SRC.."paijiu.src.models.CMD_Game")
local GameLogic = appdf.req(appdf.GAME_SRC.."paijiu.src.models.GameLogic")
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local PopupInfoHead = appdf.req("client.src.external.PopupInfoHead")
local CardLayer = appdf.req(appdf.GAME_SRC.."paijiu.src.views.layer.CardLayer")
local GameChatLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.game.GameChatLayer")
local AnimationMgr = appdf.req(appdf.EXTERNAL_SRC .. "AnimationMgr")


local GameViewLayer = class("GameViewLayer", cc.Layer)


--根据读取资源模式添加路径

local BT_EXIT   =    1
local BT_CHAT   =    2
local BT_VOICE  =    3
local BT_FINISHCOMCARD    =  4
local BT_SICE   =    5
local BT_READY  =    6
local BT_INVITE =    7

local BT_RATE_BASE  = 10
local BT_RATE_1 =   11
local BT_RATE_2 =   12
local BT_RATE_3 =   13
local BT_RATE_4 =   14
local BT_RATE_5 =   15


-----------------------------------------------
--庄家指示角度对应viewid
local BANKER_HINT_DIC = {}
BANKER_HINT_DIC[1] = 90
BANKER_HINT_DIC[2] = 0
BANKER_HINT_DIC[3] = -90
BANKER_HINT_DIC[4] = 180

----------------------倒计时---------------------------
--倒计时类型
local TIME_LIMIT_TYPE = {}
TIME_LIMIT_TYPE.SICE = 1
TIME_LIMIT_TYPE.ADDSCORE = 2
TIME_LIMIT_TYPE.FINISHCOM = 3
--倒计时时间
local DURING_TIMELIMIT = {5.0, 5.0, 30.0}
-------------------------------------------------
local pointChat = {cc.p(450, 680), cc.p(72, 500), cc.p(271, 170), cc.p(1261, 500)}

GameViewLayer.hasDestroyed = false


function GameViewLayer:destroy()
	cclog("GameViewLayer:destroy===>")
	self:onStopTime()
	GameViewLayer.hasDestroyed = true
end

function GameViewLayer:ctor(scene)
	self._scene = scene
	--var
	self.m_tabUserItem = {}  
	self.mGender = {}
	self.chatDetails = {}
	GameViewLayer.hasDestroyed = false

	--layout
	self:layoutUI()

	-- 语音动画
    AnimationMgr.loadAnimationFromFrame("record_play_ani_%d.png", 1, 3, cmd.VOICE_ANIMATION_KEY)
end

function GameViewLayer:layoutUI()
	local function btncallback(ref, tType)
        if tType == ccui.TouchEventType.ended then
            self:onButtonClickedEvent(ref:getTag(),ref)
        elseif tType == ccui.TouchEventType.began then
        	self:onButtonTouchBegan(ref:getTag(), ref)
        elseif tType == ccui.TouchEventType.canceled then
        	self:onButtonTouchCanceled(ref:getTag(), ref)
        end
    end

	--添加沙盒路径
    cc.FileUtils:getInstance():addSearchPath(cmd.RES_PATH)
	local csbNode = ExternalFun.loadCSB("game/GameScene.csb", self)

	--桌号
	self.mLbTitle = appdf.getNodeByName(csbNode, "lb_tablenum")
	self.mLbTitle:setString(PriRoom:getInstance().m_tabPriData.szServerID or "000000")

	--身份指示盘
	self.mPanelBanker = appdf.getNodeByName(csbNode, "img_centerword")

	--按钮
	--exit
	local btn_exit = appdf.getNodeByName(csbNode, "btn_exit")
	btn_exit:setTag(BT_EXIT)
	btn_exit:addTouchEventListener(btncallback)

	--chat
	local btn_chat = appdf.getNodeByName(csbNode, "btn_chat")
	btn_chat:setTag(BT_CHAT)
	btn_chat:addTouchEventListener(btncallback)

	--voice
	local btn_voice = appdf.getNodeByName(csbNode, "btn_voice")
	btn_voice:setTag(BT_VOICE)
	btn_voice:addTouchEventListener(btncallback)

	--finish comcard
	self.mBtnFinishComCard = appdf.getNodeByName(csbNode, "btn_comcard")
	self.mBtnFinishComCard:setTag(BT_FINISHCOMCARD)
	self.mBtnFinishComCard:addTouchEventListener(btncallback)
	self.mBtnFinishComCard:setVisible(false)

	--打色
	self.mBtnSice = appdf.getNodeByName(csbNode, "btn_sice")
	self.mBtnSice:setTag(BT_SICE)
	self.mBtnSice:addTouchEventListener(btncallback)
	self.mBtnSice:setVisible(false)

	--准备
	self.mBtnReady = appdf.getNodeByName(csbNode, "btn_ready")
	self.mBtnReady:setTag(BT_READY)
	self.mBtnReady:addTouchEventListener(btncallback)
	self.mBtnReady:setVisible(false)

	--邀请按钮
	self.mInviteBtn = appdf.getNodeByName(csbNode, "btn_wechat")
	self.mInviteBtn:setTag(BT_INVITE)
	self.mInviteBtn:addTouchEventListener(btncallback)

	--加倍
	self.mRateBtnArr = {}
	for i = 1,5 do
		self.mRateBtnArr[i] = appdf.getNodeByName(csbNode, "btn_rate" .. i)
		self.mRateBtnArr[i]:setVisible(false)
		self.mRateBtnArr[i]:setTag(BT_RATE_BASE + i)
		self.mRateBtnArr[i]:addTouchEventListener(btncallback)
	end

	--玩家
	self.mPlayerNodeArr = {}
	for i = 1, 4 do
		self.mPlayerNodeArr[i] = appdf.getNodeByName(csbNode, "node_player" .. i)
		self.mPlayerNodeArr[i]:setVisible(false)
	end

	--计时器
	self.mNodeClock = appdf.getNodeByName(csbNode, "node_time")
	self.mNodeClock:setVisible(false)
	local sp = display.newSprite("game/timeprogress.png")
	local pt = cc.ProgressTimer:create(sp)
	pt:move(cc.p(self.mNodeClock:getContentSize().width*0.5, self.mNodeClock:getContentSize().height*0.5))
	self.mNodeClock:addChild(pt)
	pt:setTag(100)
	pt:setType(0)
	pt:setReverseDirection(true)

	--ready
	self.mReadyArr = {}
	for i = 1,4 do
		self.mReadyArr[i] = appdf.getNodeByName(csbNode, "img_ready_" .. i)
		self.mReadyArr[i]:setVisible(false)
	end

	--wait addscore
	self.mWaitArr = {}
	for i = 1,4 do
		self.mWaitArr[i] = appdf.getNodeByName(csbNode, "img_wait_" .. i)
		self.mWaitArr[i]:setVisible(false)
	end

	--add score
	self.mAddScoreArr = {}
	for i = 1,4 do
		self.mAddScoreArr[i] = appdf.getNodeByName(csbNode, "img_addscorebg_" .. i)
		self.mAddScoreArr[i]:setVisible(false)
	end

	--牌层
	self.mCardLayer = CardLayer:create(self)
	self:addChild(self.mCardLayer)

	--init色子
	self.mShaziAni1 = ExternalFun.loadCSB("game/sezi/seziani.csb", self)
	self.mShaziAni2 = ExternalFun.loadCSB("game/sezi/seziani.csb", self)
	self.mShaziAni1:move(cc.p(yl.WIDTH * 0.48, yl.HEIGHT * 0.5))
	self.mShaziAni2:move(cc.p(yl.WIDTH * 0.52, yl.HEIGHT * 0.55))
	self.mShaziAni1_ani = ExternalFun.loadTimeLine("game/sezi/seziani.csb")
	self.mShaziAni2_ani = ExternalFun.loadTimeLine("game/sezi/seziani.csb")
	self.mShaziAni1:runAction(self.mShaziAni1_ani)
	self.mShaziAni2:runAction(self.mShaziAni2_ani)
	self:hideAllSiceChildren()

	--聊天框
    self._chatLayer = GameChatLayer:create(self._scene._gameFrame)
    self._chatLayer:addTo(self, 3)
	--聊天泡泡
	self.chatBubble = {}
	for i = 1 , cmd.GAME_PLAYER do
		if i == 2 or i == 3 then
			self.chatBubble[i] = display.newSprite(cmd.RES_PATH.."game/game_chat_lbg.png"	,{scale9 = true ,capInsets=cc.rect(40, 20, 80, 50)})
				:setAnchorPoint(cc.p(0,0.5))
				:move(pointChat[i])
				:setVisible(false)
				:addTo(self, 2)
		else
			self.chatBubble[i] = display.newSprite(cmd.RES_PATH.."game/game_chat_rbg.png",{scale9 = true ,capInsets=cc.rect(40, 20, 80, 50)})
				:setAnchorPoint(cc.p(1,0.5))
				:move(pointChat[i])
				:setVisible(false)
				:addTo(self, 2)
		end
	end
end

function GameViewLayer:hideAllSiceChildren()
	for k,v in ipairs(self.mShaziAni1:getChildren()) do
		v:setVisible(false)
	end
	for k,v in ipairs(self.mShaziAni2:getChildren()) do
		v:setVisible(false)
	end
end

--显示加倍按钮
function GameViewLayer:showRateButton(_show)
	for i = 1,5 do
		self.mRateBtnArr[i]:setVisible(_show)
	end
end


--设置等待私房结果
function GameViewLayer:setWaitPriEnd(_iswait)
	GameViewLayer.hasDestroyed = _iswait
end

----------------------按钮回调事件------------------------------------
function GameViewLayer:onButtonClickedEvent(tag, ref)
	--防止销毁后还响应事件
	if GameViewLayer.hasDestroyed then return end
	--
	if tag == BT_EXIT then
		self._scene:onQueryExitGame()
	elseif tag == BT_CHAT then    --聊天
		self._chatLayer:showGameChat(true)
	elseif tag == BT_VOICE then   --语音
		self._scene:stopVoiceRecord()
	elseif tag == BT_FINISHCOMCARD then --完成组牌
		self:onStopTime()
		self._scene:onOpenCard()
	elseif tag == BT_SICE then     --打色
		--停止倒计时
		self:onStopTime()
		self:onStopThrowSice()
	elseif tag == BT_READY then    --准备
		self._scene:onStartGame()
		self.mBtnReady:setVisible(false)
	elseif tag >= BT_RATE_1 and tag <= BT_RATE_5 then --加倍
		--停止倒计时
		self:onStopTime()
		self._scene:onAddScore(tag - BT_RATE_BASE)
		self:showRateButton(false)
	elseif tag == BT_INVITE then --邀请
		self._scene:onInviteWeChat()
	end
end

function GameViewLayer:onButtonTouchBegan(tag, ref)
	if tag == BT_SICE then
		--玩家数量固定为4人
		local playercnt = 4
		self.mSiceArr, self.mSiceChairId = GameLogic.throwSice(self._scene:GetMeChairID(), playercnt)
		--通知服务器投色结果
		self._scene:onSiceResult(self.mSiceArr, self.mSiceChairId)
		self:onThrowSice(false)
	elseif tag == BT_VOICE then
		self._scene:startVoiceRecord()
	end
end

function GameViewLayer:onButtonTouchCanceled(tag, ref)
	if tag == BT_SICE then
	   self:onStopThrowSice()
	elseif tag == BT_VOICE then
		self._scene:stopVoiceRecord()
	end
end

------------------------逻辑层命令---------------------------------------
--更新用户状态
function GameViewLayer:OnUpdateUser(viewId, userItem)
	cclog("GameViewLayer:OnUpdateUser===>" .. viewId)
	local node_player = self.mPlayerNodeArr[viewId]
	if not userItem then 
		cclog("GameViewLayer:OnUpdateUser===>no useritem!!!")
		self.m_tabUserItem[viewId] = nil
		node_player:setVisible(false)
	return end
	self._scene:onSaveUserItem(userItem)
	self.m_tabUserItem[viewId] = userItem
	dump(self.m_tabUserItem, "self.m_tabUserItem")
	node_player:setVisible(true)
	--记录性别
	self.mGender[viewId] = userItem.cbGender
	--name
	node_player:getChildByName("lb_name"):setString(userItem.szNickName)
	--head
	local img_headbg = node_player:getChildByName("img_headbg")
	local head = img_headbg:getChildByName("head")
	if not head then
		head = PopupInfoHead:createNormal(userItem, 85)
		head:setPosition(img_headbg:getContentSize().width*0.5, img_headbg:getContentSize().height*0.5)
		head:enableHeadFrame(false)
		head:setName("head")
		img_headbg:addChild(head)
	else
		head:updateHead()
	end
	--准备
	self.mReadyArr[viewId]:setVisible(userItem.cbUserStatus == yl.US_READY)
	--查看是否可以邀请
	self:onCheckShowInviteBtn()
end

--重置界面
function GameViewLayer:onResetView()
	self.mCardLayer:onResetView()
	--
	for i = 1, cmd.GAME_PLAYER do
		local node_player = self.mPlayerNodeArr[i]
		node_player:getChildByName("img_win"):setVisible(false)
		node_player:getChildByName("img_lose"):setVisible(false)
		node_player:getChildByName("img_equal"):setVisible(false)
		node_player:getChildByName("img_zhuang"):setVisible(false)
		node_player:getChildByName("lb_addscore"):setVisible(false)
		node_player:getChildByName("lb_addscore"):setPosition(node_player:getChildByName("node_addscore_1"):getPosition())
	end
	--
	for i = 1,4 do
		self.mAddScoreArr[i]:setVisible(false)
	end
	--
	self:onStopTime()
end

function GameViewLayer:onRefreshInfo()
	cclog("GameViewLayer:onRefreshInfo===>" .. json.encode(PriRoom:getInstance().m_tabPriData))
	local strJu = string.format("(%d局/%d局)", PriRoom:getInstance().m_tabPriData.dwPlayCount, PriRoom:getInstance().m_tabPriData.dwDrawCountLimit)
	self.mLbTitle:setString("房间号：" .. PriRoom:getInstance().m_tabPriData.szServerID .. strJu)
	--查看是否可以邀请
	self:onCheckShowInviteBtn()
end

--显示庄家标识
function GameViewLayer:onShowZhuangFlag(viewIdBanker)
	local node_player = self.mPlayerNodeArr[viewIdBanker]
	node_player:getChildByName("img_zhuang"):setVisible(true)
end

--显示下注按钮
function GameViewLayer:onShowAddScoreBtn(viewIdBanker)
	if cmd.MY_VIEWID ~= viewIdBanker then
		self:showRateButton(true)
		--倒计时
		self:onShowTime(TIME_LIMIT_TYPE.ADDSCORE, function()
			   --直接下注1分
			   	self._scene:onAddScore(1)
				self:showRateButton(false)
			end)
	end
end

--转盘转动
function GameViewLayer:onRoPanel(viewIdBanker)
	self.mPanelBanker:setRotation(BANKER_HINT_DIC[viewIdBanker])
end

--显示等待加分
function GameViewLayer:onShowWaitAddScore(i, viewIdBanker)
	if i ~= viewIdBanker and self.m_tabUserItem[i] then
	   self.mWaitArr[i]:setVisible(true)
	end
end

--游戏开始
function GameViewLayer:onGameStart(viewIdBanker)
	--身份盘转向庄家
	self:onRoPanel(viewIdBanker)
	--自己不是庄家显示加倍
	self:onShowAddScoreBtn(viewIdBanker)
	--显示庄家标识
	self:onShowZhuangFlag(viewIdBanker)

	--显示等待加分
	for i = 1, 4 do
		self:onShowWaitAddScore(i, viewIdBanker)
	end
end

--恢复下注显示
function GameViewLayer:onRestoreAddScoreDisplay(cmd_data)
	cclog("GameViewLayer:onRestoreAddScoreDisplay===>")
	for i = 1, cmd.GAME_PLAYER do
		local viewId = self._scene:SwitchViewChairID(i)
		local score = cmd_data.lTableScore[1][i]
		if score == 0 then
			if viewId == cmd.MY_VIEWID then
				self:onShowAddScoreBtn(self._scene.wBankerUser)
				self:onShowWaitAddScore(viewId, self._scene.wBankerUser)
			else
				self:onShowWaitAddScore(viewId, self._scene.wBankerUser)
			end
		else
		    self:onAddScore(viewId, score)
		end
	end
	--恢复身份盘
	local viewId = self._scene:SwitchViewChairID(self._scene.wBankerUser)
	self:onRoPanel(viewId)
end

--用户下注
function GameViewLayer:onAddScore(viewId, score)
	cclog("GameViewLayer:onAddScore===>" .. viewId .. "=" .. score)
	self.mWaitArr[viewId]:setVisible(false)
	self:onShowAddScore(viewId, score)
end

--显示下注积分
function GameViewLayer:onShowAddScore(viewId, score)
	cclog("GameViewLayer:onShowAddScore==>" .. score)
	if score > 0 then
		self.mAddScoreArr[viewId]:getChildByName("lb_num"):setString(score)
		self.mAddScoreArr[viewId]:setVisible(true)
	end
end

--显示投色按钮
function GameViewLayer:onShowThrowSice()
	cclog("GameViewLayer:onShowThrowSice===>")
	local viewId = self._scene:SwitchViewChairID(self._scene.wBankerUser)
	if viewId == cmd.MY_VIEWID then
		self.mBtnSice:setVisible(true)
	end
end

--投色
function GameViewLayer:onThrowSice(_isWait)
	cclog("GameViewLayer:onThrowSice===>")
	local time = 5.0
	--播放筛子动画
	self.mShaziAni1:getChildByName("sp_shadow"):setVisible(true)
	self.mShaziAni1:getChildByName("sp_sezi_" .. self.mSiceArr[1]):setVisible(true)
	self.mShaziAni2:getChildByName("sp_shadow"):setVisible(true)
	self.mShaziAni2:getChildByName("sp_sezi_" .. self.mSiceArr[2]):setVisible(true)
	self.mShaziAni1_ani:play("throwing", true)
	self.mShaziAni2_ani:play("throwing", true)
	if not _isWait then
		--倒计时停止投色
		self:onShowTime(TIME_LIMIT_TYPE.SICE, handler(self, self.onStopThrowSice))
	end
end

--被动停止投色
function GameViewLayer:onForcedStopSice()
	--播停止动画，开始发牌
	self.mShaziAni1_ani:play("stop", false)
	self.mShaziAni2_ani:play("stop", false)
	--延迟几秒开始播停止几点
	local func1 = cc.CallFunc:create(function()
		   self:hideAllSiceChildren()
		   self:onSendCard(self.mSiceChairId)
		end)
	local delay1 = cc.DelayTime:create(1.0)
	local seq1 = cc.Sequence:create(delay1, func1)
	self:runAction(seq1)
end

--停止投色(主动停止)
function GameViewLayer:onStopThrowSice()
	cclog("GameViewLayer:onStopThrowSice===>")
	if not self.mBtnSice:isVisible() then return end
	--通知服务器停止投色
	self._scene:onStopSice()
	self.mBtnSice:setVisible(false)
end

--强制组牌完成
function GameViewLayer:onForcedFinishCom()
	self._scene:onOpenCard()
end

--发牌
function GameViewLayer:onSendCard(chairId, finish)
	cclog("GameViewLayer:onSendCard===>")
	self.mCardLayer:onSendCard(chairId, self._scene.cbCardData, function()
		   --进入组牌环节
		   self:onShowFinishComCardBtn(true)
		   self.mCardLayer:onEnterComCard(true)
		   --组牌时限
		   self:onShowTime(TIME_LIMIT_TYPE.FINISHCOM, function()
		   	   self:onForcedFinishCom()
		   	end)
		   --
		   if finish then
		   	  finish()
		   end
		end)
end

--隐藏组牌完成按键
function GameViewLayer:onShowFinishComCardBtn(_show)
	self.mBtnFinishComCard:setVisible(_show)
end

--刷新总积分
function GameViewLayer:onRefreshTotalScore()
	for i = 1, cmd.GAME_PLAYER do
		local node_player = self.mPlayerNodeArr[i]
		local theScore = self._scene.mScoreRecordArr[i]
		if theScore > 0 then
			node_player:getChildByName("lb_coins"):setString("+" .. theScore)
		else
			node_player:getChildByName("lb_coins"):setString("" .. theScore)
		end
	end
end

--最后结算
function GameViewLayer:onGameConclude(cmd_data)
	cclog("GameViewLayer:onGameConclude===>")
	--
	self:onRefreshTotalScore()
	--
	for i = 1, cmd.GAME_PLAYER do
		local viewId = self._scene:SwitchViewChairID(i - 1)
		local node_player = self.mPlayerNodeArr[viewId]

		--显示本局得分
		local addScore = cmd_data.lGameScore[1][i]
		local lb_addscore = node_player:getChildByName("lb_addscore")
		if addScore >= 0 then
			lb_addscore:setString("+" .. addScore)
		else
			lb_addscore:setString("" .. addScore)
		end
		lb_addscore:setVisible(true)
		local moveTo = cc.MoveTo:create(1.0, cc.p(node_player:getChildByName("node_addscore_2"):getPosition()))
		lb_addscore:runAction(moveTo)

		--显示输赢
		if addScore > 0 then
		    node_player:getChildByName("img_win"):setVisible(true)
		elseif addScore == 0 then
			node_player:getChildByName("img_equal"):setVisible(true)
		else
			node_player:getChildByName("img_lose"):setVisible(true)
		end

		--处理牌
		self.mCardLayer:onShowAllCardsAndType()
	end
	
	--显示准备
	self.mBtnReady:setVisible(true)
end


--显示倒计时
function GameViewLayer:onShowTime(tp, finish)
	cclog("GameViewLayer:onShowTime===>")
	local during = DURING_TIMELIMIT[tp]
	self.mNodeClock:getChildByName("lb_num"):setString("" .. during)
	self.mNodeClock:getChildByTag(100):setPercentage(100)
	self.mNodeClock:setVisible(true)
	local interval = 1
	self.mTick = nextTick_eachSecond(function()
		self.mNodeClock:getChildByName("lb_num"):setString("" .. during - interval)
		self.mNodeClock:getChildByTag(100):setPercentage(((during - interval)/during)*100)
		interval = interval + 1
		if interval > during then
		   finish()
		   self:onStopTime()
		end
	end, 1.0)
end

--停止倒计时
function GameViewLayer:onStopTime()
	cclog("GameViewLayer:onStopTime===>")
	if self.mTick then
		G_unSchedule(self.mTick)
		self.mTick = nil
	end
	self.mNodeClock:setVisible(false)
end


-------------------------聊天------------------------------------
-- 语音开始
function GameViewLayer:onUserVoiceStart( viewId )
	--取消上次
	if self.chatDetails[viewId] then
		self.chatDetails[viewId]:stopAllActions()
		self.chatDetails[viewId]:removeFromParent()
		self.chatDetails[viewId] = nil
	end
     -- 语音动画
    local param = AnimationMgr.getAnimationParam()
    param.m_fDelay = 0.1
    param.m_strName = cmd.VOICE_ANIMATION_KEY
    local animate = AnimationMgr.getAnimate(param)
    self.m_actVoiceAni = cc.RepeatForever:create(animate)

    self.chatDetails[viewId] = display.newSprite("#blank.png")
		:setAnchorPoint(cc.p(0.5, 0.5))
		:addTo(self, 3)
	if viewId ==2 or viewId == 3 then
		self.chatDetails[viewId]:setRotation(180)
		self.chatDetails[viewId]:move(pointChat[viewId].x + 45 , pointChat[viewId].y + 9)
			:setAnchorPoint( cc.p(0, 0.5) )
	else
		self.chatDetails[viewId]:move(pointChat[viewId].x - 24 , pointChat[viewId].y + 9)
			:setAnchorPoint(cc.p(1, 0.5))
	end
	self.chatDetails[viewId]:runAction(self.m_actVoiceAni)

    --改变气泡大小
	self.chatBubble[viewId]:setContentSize(90,100)
		:setVisible(true)
end

-- 语音结束
function GameViewLayer:onUserVoiceEnded( viewId )
	if self.chatDetails[viewId] then
	    self.chatDetails[viewId]:removeFromParent()
	    self.chatDetails[viewId] = nil
	    self.chatBubble[viewId]:setVisible(false)
	end
end

--用户聊天
function GameViewLayer:userChat(viewId, chatString)
	if chatString and #chatString > 0 then
		self._chatLayer:showGameChat(false)
		--取消上次
		if self.chatDetails[viewId] then
			self.chatDetails[viewId]:stopAllActions()
			self.chatDetails[viewId]:removeFromParent()
			self.chatDetails[viewId] = nil
		end

		--创建label
		local limWidth = 24*12
		local labCountLength = cc.Label:createWithSystemFont(chatString,"Arial", 24)  
		if labCountLength:getContentSize().width > limWidth then
			self.chatDetails[viewId] = cc.Label:createWithSystemFont(chatString,"Arial", 24, cc.size(limWidth, 0))
		else
			self.chatDetails[viewId] = cc.Label:createWithSystemFont(chatString,"Arial", 24)
		end
		if viewId ==2 or viewId == 3 then
			self.chatDetails[viewId]:move(pointChat[viewId].x + 24 , pointChat[viewId].y + 9)
				:setAnchorPoint( cc.p(0, 0.5) )
		else
			self.chatDetails[viewId]:move(pointChat[viewId].x - 24 , pointChat[viewId].y + 9)
				:setAnchorPoint(cc.p(1, 0.5))
		end
		self.chatDetails[viewId]:addTo(self, 2)

	    --改变气泡大小
		self.chatBubble[viewId]:setContentSize(self.chatDetails[viewId]:getContentSize().width+48, self.chatDetails[viewId]:getContentSize().height + 40)
			:setVisible(true)
		--动作
	    self.chatDetails[viewId]:runAction(cc.Sequence:create(
	    	cc.DelayTime:create(3),
	    	cc.CallFunc:create(function(ref)
	    		self.chatDetails[viewId]:removeFromParent()
				self.chatDetails[viewId] = nil
				self.chatBubble[viewId]:setVisible(false)
	    	end)))
    end
end

--查看是否可以显示邀请
function GameViewLayer:onCheckShowInviteBtn()
	cclog("GameViewLayer:onCheckShowInviteBtn===>" .. self._scene.cbPlayerCount)
	if self._scene:onGetSitUserNum() < self._scene.cbPlayerCount then
		self.mInviteBtn:setVisible(true)
	else
		self.mInviteBtn:setVisible(false)
	end
end



return GameViewLayer