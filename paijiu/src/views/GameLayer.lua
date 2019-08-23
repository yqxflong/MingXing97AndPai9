-- Name: GameLayer
-- Func: 天9逻辑层
-- Author: Johny

appdf.req(appdf.CLIENT_SRC .. "plaza.views.layer.game.VoiceRecorderKit")
local cmd = appdf.req(appdf.GAME_SRC.."paijiu.src.models.CMD_Game")
local GameLogic = appdf.req(appdf.GAME_SRC.."paijiu.src.models.GameLogic")
local GameViewLayer = appdf.req(appdf.GAME_SRC.."paijiu.src.views.layer.GameViewLayer")
local QueryDialog = appdf.req("app.views.layer.other.QueryDialog")
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")




local GameModel = appdf.req(appdf.CLIENT_SRC.."gamemodel.GameModel")
local GameLayer = class("GameLayer", GameModel)



local VOICE_LAYER_NAME = "__voice_record_layer__"



--销毁回调
function GameLayer:onExit()
    self._gameView:destroy()
    self:dismissPopWait()
    GameLayer.super.onExit(self)
end

-- 初始化界面
function GameLayer:ctor(frameEngine,scene)
    GameLayer.super.ctor(self, frameEngine, scene)
    --bgm
    if GlobalUserItem.bVoiceAble then
        AudioEngine.playMusic(cmd.RES_PATH .. "sound/bgm.mp3", true)
    end 
end

--创建场景
function GameLayer:CreateView()
    return GameViewLayer:create(self):addTo(self)
end

-- 初始化游戏数据
function GameLayer:OnInitGameEngine()
    GameLayer.super.OnInitGameEngine(self)
    --各玩家状态
    self.cbPlayStatus = {0, 0, 0, 0}
    --各个玩家牌数据
    self.cbCardData = {}
    --庄家
    self.wBankerUser = yl.INVALID_CHAIR
    --是否已开始游戏
    self.m_bStartGame = false
    --得分记录
    self.mScoreRecordArr = {0, 0, 0, 0}
    --记录用户数据
    self.mUserItemArr = {}
    --玩家人数
    self.cbPlayerCount = 4
    --是否等待私房结束
    self.mIsWaitPriEnd = false
end


-- 椅子号转视图位置,注意椅子号从0~nChairCount-1,返回的视图位置从1~nChairCount
function GameModel:SwitchViewChairID(chair)
    local viewid = yl.INVALID_CHAIR
    local nChairCount = 4
    local nChairID = self:GetMeChairID()
    if chair ~= yl.INVALID_CHAIR and chair < nChairCount then
        viewid = math.mod(chair + math.floor(nChairCount * 3/2) - nChairID, nChairCount) + 1
    end
    return viewid
end

-- 重置游戏数据
function GameLayer:OnResetGameEngine()
    -- body
    GameLayer.super.OnResetGameEngine(self)
end

--获取gamekind
function GameLayer:getGameKind()
    return cmd.KIND_ID
end

--设置等待私房结果
function GameLayer:setWaitPriEnd(_iswait)
    self.mIsWaitPriEnd = true
    self._gameView:setWaitPriEnd(_iswait)
end


---------------------聊天-------------------------------------
function GameLayer:startVoiceRecord()
    cclog("function GameLayer:startVoiceRecord() ==>")
    local lay = VoiceRecorderKit.createRecorderLayer(self, self._gameFrame)
    if nil ~= lay then
        lay:setName(VOICE_LAYER_NAME)
        self:addChild(lay)
    end
end

function GameLayer:stopVoiceRecord()
    cclog("function GameLayer:stopVoiceRecord() ==>")
    local voiceLayer = self:getChildByName(VOICE_LAYER_NAME)
    if nil ~= voiceLayer then
        voiceLayer:removeRecorde()
    end
end

function GameLayer:cancelVoiceRecord()
    cclog("function GameLayer:cancelVoiceRecord() ==>")
    local voiceLayer = self:getChildByName(VOICE_LAYER_NAME)
    if nil ~= voiceLayer then
        voiceLayer:cancelVoiceRecord()
    end
end


--用户聊天
function GameLayer:onUserChat(chat, wChairId)
    self._gameView:userChat(self:SwitchViewChairID(wChairId), chat.szChatString)
end

--用户表情
function GameLayer:onUserExpression(expression, wChairId)
    self._gameView:userExpression(self:SwitchViewChairID(wChairId), expression.wItemIndex)
end

-- 语音播放开始
function GameLayer:onUserVoiceStart( useritem, filepath )
    local viewid = self:SwitchViewChairID(useritem.wChairID)
    self._gameView:onUserVoiceStart(viewid)
end

-- 语音播放结束
function GameLayer:onUserVoiceEnded( useritem, filepath )
    local viewid = self:SwitchViewChairID(useritem.wChairID)
    self._gameView:onUserVoiceEnded(viewid)
end
---------------------聊天-------------------------------------

function GameLayer:onGetSitUserNum()
    local num = 0
    for i = 1, cmd.GAME_PLAYER do
        if nil ~= self._gameView.m_tabUserItem[i] then
            num = num + 1
        end
    end

    return num
end

function GameLayer:getUserInfoByChairID(chairId)
    local viewId = self:SwitchViewChairID(chairId)
    return self._gameView.m_tabUserItem[viewId]
end


--离开房间
function GameLayer:onExitRoom()
    self._scene:onKeyBack()
end

--退出桌子
function GameLayer:onExitTable()
    local MeItem = self:GetMeUserItem()
    if MeItem and MeItem.cbUserStatus > yl.US_FREE then
        self:showPopWait()
        self:runAction(cc.Sequence:create(
            cc.CallFunc:create(
                function () 
                    self._gameFrame:StandUp(1)
                end
                ),
            cc.DelayTime:create(10),
            cc.CallFunc:create(
                function ()
                    cclog("delay leave")
                    self:onExitRoom()
                end
                )
            )
        )
        return
    end

   self:onExitRoom()
end

--开始游戏
function GameLayer:onStartGame()
    if true == self.m_bPriScoreLow then
        local msg = self.m_szScoreMsg or ""
        self.m_querydialog = QueryDialog:create(msg,function()
            self:onExitTable()
        end,nil,1)
        self.m_querydialog:setCanTouchOutside(false)
        self.m_querydialog:addTo(self)
    else
        self._gameView:onResetView()
        self._gameFrame:SendUserReady()
        self.m_bStartGame = true
    end
end

--更新房间信息
function GameLayer:onRefreshInfo()
    cclog("GameLayer:onRefreshInfo===>")
    self._gameView:onRefreshInfo()
end

function GameLayer:onSaveUserItem(userItem)
    --另存一份item
    local item = {}
    item.szNickName = userItem.szNickName
    item.dwGameID = userItem.dwGameID
    item.dwUserID = userItem.dwUserID
    item.dwCustomID = userItem.dwCustomID
    item.wFaceID = userItem.wFaceID
    self.mUserItemArr[userItem.wChairID] = item
    cclog("GameLayer:onSaveUserItem===>" .. userItem.wChairID .. "=" .. json.encode(item))
    dump(self.mUserItemArr, "self.mUserItemArr")
end

--------------------------------------------网络消息----------------------------------------------
--系统消息
function GameLayer:onSystemMessage( wType,szString )
    cclog("GameLayer:onSystemMessage===>")
    if self.m_bStartGame then
        local msg = szString or ""
        self.m_querydialog = QueryDialog:create(msg,function()
            self:onExitTable()
        end,nil,1)
        self.m_querydialog:setCanTouchOutside(false)
        self.m_querydialog:addTo(self)
    else
        self.m_bPriScoreLow = true
        self.m_szScoreMsg = szString
    end
end

-- 场景信息
function GameLayer:onEventGameScene(cbGameStatus, dataBuffer)
    cclog("GameLayer:onEventGameScene===>" .. cbGameStatus)
    --初始化已有玩家   
    local tableId = self._gameFrame:GetTableID()
    for i = 1, cmd.GAME_PLAYER do
        local userItem = self._gameFrame:getTableUserItem(tableId, i-1)
        if nil ~= userItem then
            local wViewChairId = self:SwitchViewChairID(i-1)
            self._gameView:OnUpdateUser(wViewChairId, userItem)
            self:onSaveUserItem(userItem)
        end
    end
    self._gameView:onResetView()
    self.m_cbGameStatus = cbGameStatus

	if cbGameStatus == cmd.GS_TK_FREE	then				--空闲状态
        self:onSceneFree(dataBuffer)
	elseif cbGameStatus == cmd.GS_TK_SCORE	then			--下注状态
        self:onSceneScore(dataBuffer)
    elseif cbGameStatus == cmd.GS_TK_PLAYING  then            --游戏状态
        self:onScenePlaying(dataBuffer)
	end
    self:dismissPopWait()
end

--空闲场景
function GameLayer:onSceneFree(pData)
    local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_StatusFree, pData)
    cclog("GameLayer:onSceneFree==>" .. json.encode(cmd_data))
    self.cbPlayerCount = cmd_data.wPlayerCount or 4
    --恢复积分
    for i = 1, cmd.GAME_PLAYER do
        local viewId = self:SwitchViewChairID(i - 1)
        self.mScoreRecordArr[viewId] = cmd_data.lCollectScore[1][i]
    end
    --自动准备
    self:onStartGame()
end

--下注场景
function GameLayer:onSceneScore(pData)
    cclog("GameLayer:onSceneScore===>")
    local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_StatusScore, pData)
    self.wBankerUser = cmd_data.wBankerUser
    self.cbPlayerCount = cmd_data.wPlayerCount or 4
    --庄标志
    local viewId = self:SwitchViewChairID(self.wBankerUser)
    self._gameView:onShowZhuangFlag(viewId)
    --恢复基本信息
    for i = 1, cmd.GAME_PLAYER do
        local viewId = self:SwitchViewChairID(i - 1)
        --恢复积分
        self.mScoreRecordArr[viewId] = cmd_data.lCollectScore[1][i]

        --恢复状态
        self.cbPlayStatus[viewId] = cmd_data.cbPlayStatus[1][i]
    end
    --恢复下注
    self._gameView:onRestoreAddScoreDisplay(cmd_data)
    --恢复总积分
    self._gameView:onRefreshTotalScore()
end

--游戏场景
function GameLayer:onScenePlaying(pData)
    cclog("GameLayer:onScenePlaying===>")
    local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_StatusPlay, pData)
    dump(cmd_data, "CMD_S_StatusPlay")
    self.wBankerUser = cmd_data.wBankerUser
    self.cbPlayerCount = cmd_data.wPlayerCount or 4
    --庄标志
    local viewId = self:SwitchViewChairID(self.wBankerUser)
    self._gameView:onShowZhuangFlag(viewId)
    --恢复基本信息
    for i = 1, cmd.GAME_PLAYER do
        local viewId = self:SwitchViewChairID(i - 1)
        --恢复积分
        self.mScoreRecordArr[viewId] = cmd_data.lCollectScore[1][i]

        --恢复状态
        self.cbPlayStatus[viewId] = cmd_data.cbPlayStatus[1][i]

        --恢复下注积分
        self._gameView:onShowAddScore(viewId, cmd_data.lTableScore[1][i])
    end 
    --恢复总积分
    self._gameView:onRefreshTotalScore()
    --恢复手牌
    for i = 1, cmd.GAME_PLAYER do
        local viewId = self:SwitchViewChairID(i - 1)
        for j = 1, cmd.MAX_COUNT do
            if self.cbCardData[viewId] == nil then
               self.cbCardData[viewId] = {}
            end
            if viewId == cmd.MY_VIEWID then
               self.cbCardData[viewId][j] = cmd_data.cbHandCardData[1][j]
            else
                self.cbCardData[viewId][j] = 0
            end
        end
    end
    --恢复投色
    if cmd_data.SicePoint[1][1] == 0 then
        self._gameView:onShowThrowSice()
    else
        self._gameView:onSendCard(cmd_data.wStartUser, function()
                --恢复组牌状态
                for i =1, cmd.GAME_PLAYER do
                    if cmd_data.cbOpenCard[1][i] == 1 then
                        local viewId = self:SwitchViewChairID(i - 1)
                        self._gameView.mCardLayer:onFinishComCard(viewId)
                        if viewId == cmd.MY_VIEWID then
                           self._gameView:onStopTime()
                        end
                    end
                end
            end)
    end

end

-- 游戏消息
function GameLayer:onEventGameMessage(sub,dataBuffer)
    cclog("GameLayer:onEventGameMessage===>" .. sub)
	if sub == cmd.SUB_S_GAME_START then
        self.m_cbGameStatus = cmd.GS_TK_CALL 
		self:onSubGameStart(dataBuffer)
	elseif sub == cmd.SUB_S_ADD_SCORE then 
        self.m_cbGameStatus = cmd.GS_TK_SCORE
		self:onSubAddScore(dataBuffer)
    elseif sub == cmd.SUB_S_PLAY_SICE then
        self.m_cbGameStatus = cmd.GS_TK_PLAYING
        self:onSubPlaySice(dataBuffer)
    elseif sub == cmd.SUB_S_STOP_SICE then
        self:onSubStopSice(dataBuffer)
	elseif sub == cmd.SUB_S_SEND_CARD then 
        self.m_cbGameStatus = cmd.GS_TK_PLAYING
		self:onSubSendCard(dataBuffer)
	elseif sub == cmd.SUB_S_OPEN_CARD then 
        self.m_cbGameStatus = cmd.GS_TK_PLAYING
		self:onSubOpenCard(dataBuffer)
	elseif sub == cmd.SUB_S_PLAYER_EXIT then 
        self.m_cbGameStatus = cmd.GS_TK_PLAYING
		self:onSubPlayerExit(dataBuffer)
	elseif sub == cmd.SUB_S_GAME_END then 
        self.m_cbGameStatus = cmd.GS_TK_PLAYING
		self:onSubGameEnd(dataBuffer)
	else
		cclog("unknow gamemessage sub is"..sub)
	end
end

--游戏开始
function GameLayer:onSubGameStart(pData)
    PriRoom:getInstance().m_tabPriData.dwPlayCount = PriRoom:getInstance().m_tabPriData.dwPlayCount + 1
    self:onRefreshInfo()
    --
    local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_GameStart, pData)
    self.wBankerUser = cmd_data.wBankerUser
    local viewId = self:SwitchViewChairID(self.wBankerUser)
    self._gameView:onGameStart(viewId)
end

--用户下注
function GameLayer:onSubAddScore(pData)
    self:PlaySound(cmd.RES_PATH.."sound/ADD_SCORE.WAV")
    local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_AddScore, pData)
    local viewId = self:SwitchViewChairID(cmd_data.wAddScoreUser)
    self._gameView:onAddScore(viewId, cmd_data.lAddScoreCount)
end

--庄家投色
function GameLayer:onSubPlaySice(pData)
    cclog("GameLayer:onSubPlaySice===>")
    local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_PlaySice, pData)
    self._gameView.mSiceArr = {cmd_data.wSicePoint[1][1], cmd_data.wSicePoint[1][2]}
    self._gameView.mSiceChairId = cmd_data.wStartUser
    self._gameView:onThrowSice(true) 
end

--投色停止
function GameLayer:onSubStopSice()
    cclog("GameLayer:onSubStopSice===>")
    self._gameView:onForcedStopSice()
end

--发牌消息
function GameLayer:onSubSendCard(pData)
    local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_SendCard, pData)
    for i = 1, cmd.GAME_PLAYER do
        local viewId = self:SwitchViewChairID(i - 1)
        for j = 1, cmd.MAX_COUNT do
            if self.cbCardData[viewId] == nil then
               self.cbCardData[viewId] = {}
            end
            if viewId == cmd.MY_VIEWID then
               self.cbCardData[viewId][j] = cmd_data.cbCardData[1][j]
            else
                self.cbCardData[viewId][j] = 0
            end
        end
    end
    --投色
    self._gameView:onShowThrowSice()
end

--用户摊牌
function GameLayer:onSubOpenCard(pData)
    cclog("GameLayer:onSubOpenCard===>")
    self:PlaySound(cmd.RES_PATH.."sound/OPEN_CARD.wav")
    local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_Open_Card, pData)
    local viewId = self:SwitchViewChairID(cmd_data.wChairID)
    cclog("GameLayer:onSubOpenCard===>" .. viewId)
    self._gameView.mCardLayer:onFinishComCard(viewId)
end

--用户强退
function GameLayer:onSubPlayerExit(pData)
    local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_Open_Card, pData)
end


--游戏结束
function GameLayer:onSubGameEnd(pData)
    self:PlaySound(cmd.RES_PATH.."sound/GAME_END.WAV")
    local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_GameEnd, pData)
    cclog("GameLayer:onSubGameEnd===>" .. json.encode(cmd_data))
    --先清空手牌
    self.cbCardData = {}

    for i =1, cmd.GAME_PLAYER do
        local viewId = self:SwitchViewChairID(i -1)
        --刷新总得分
        self.mScoreRecordArr[viewId] = self.mScoreRecordArr[viewId] + cmd_data.lGameScore[1][i]
        --刷新牌
        for j = 1, cmd.MAX_COUNT do
            if self.cbCardData[viewId] == nil then
               self.cbCardData[viewId] = {}
            end
            self.cbCardData[viewId][j] = cmd_data.cbOpenCard[i][j]
        end 
    end

    --显示结算
    self._gameView:onGameConclude(cmd_data)
end

--********************   发送消息     *********************--
function GameLayer:onAddScore(lScore)
    cclog("GameLayer:onAddScore===>" .. lScore)
    local buffer = ExternalFun.create_netdata(cmd.CMD_C_AddScore)
    buffer:setcmdinfo(yl.MDM_GF_GAME, cmd.SUB_C_ADD_SCORE)
    buffer:pushscore(lScore)
    return self._gameFrame:sendSocketData(buffer)
end

function GameLayer:onOpenCard()
    cclog("GameLayer:onOpenCard===>" .. json.encode(self.cbCardData))
    local myCardArr = self.cbCardData[cmd.MY_VIEWID]
    local buffer = CCmd_Data:create(4)
    buffer:setcmdinfo(yl.MDM_GF_GAME, cmd.SUB_C_OPEN_CARD)
    buffer:pushbyte(myCardArr[1])
    buffer:pushbyte(myCardArr[2])
    buffer:pushbyte(myCardArr[3])
    buffer:pushbyte(myCardArr[4])
    return self._gameFrame:sendSocketData(buffer)
end

--投色结果
function GameLayer:onSiceResult(siceArr, wStartUser)
    cclog("GameLayer:onSiceResult===>" .. wStartUser)
    local buffer = CCmd_Data:create(6)
    buffer:setcmdinfo(yl.MDM_GF_GAME, cmd.SUB_C_PLAY_SICE)
    buffer:pushword(wStartUser)
    buffer:pushword(siceArr[1])
    buffer:pushword(siceArr[2])
    return self._gameFrame:sendSocketData(buffer)
end

--停止投色
function GameLayer:onStopSice()
    cclog("GameLayer:onStopSice===>")
    local buffer = CCmd_Data:create(0)
    buffer:setcmdinfo(yl.MDM_GF_GAME, cmd.SUB_C_STOP_SICE)
    return self._gameFrame:sendSocketData(buffer)
end

--邀请微信
function GameLayer:onInviteWeChat()
    local target = yl.ThirdParty.WECHAT
    local url = GlobalUserItem.szWXSpreaderURL or yl.HTTP_URL
    local function sharecall( isok )
        if type(isok) == "string" and isok == "true" then
            --showToast(self, "分享成功", 2)
        end
    end
    local shareTxt = "房号" .. PriRoom:getInstance().m_tabPriData.szServerID .. 
                    "，局数" .. PriRoom:getInstance().m_tabPriData.dwDrawCountLimit .. 
                    "，人数" .. PriRoom:getInstance():getChairCount() ..
                    "。天九, 一起来玩吧！"
    cclog("GameLayer:onInviteWeChat===>" .. shareTxt)
    MultiPlatform:getInstance():shareToTarget(target, sharecall, G_GAME_NAME, shareTxt, url)
end

return GameLayer