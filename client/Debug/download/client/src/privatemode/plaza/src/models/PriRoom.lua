-- Name: PriRoom
-- Func: 私房逻辑
-- Author: Johny

PriRoom = PriRoom or class("PriRoom")
local private_define = appdf.req(appdf.CLIENT_SRC .. "privatemode.header.Define_Private")
local cmd_private = appdf.req(appdf.CLIENT_SRC .. "privatemode.header.CMD_Private")
local QueryDialog = appdf.req("app.views.layer.other.QueryDialog")

-- 私人房模块
local MODULE = private_define.tabModule
PriRoom.MODULE = MODULE
-- 私人房界面tag
local LAYTAG = private_define.tabLayTag
PriRoom.LAYTAG = LAYTAG
-- 游戏服务器登陆操作定义
local L_ACTION = private_define.tabLoginAction
PriRoom.L_ACTION = L_ACTION
-- 登陆服务器CMD
local cmd_pri_login = cmd_private.login
-- 游戏服务器CMD
local cmd_pri_game = cmd_private.game

local PriFrame = appdf.req(MODULE.PLAZAMODULE .."models.PriFrame")

-- roomID 输入界面
local NAME_ROOMID_INPUT = "___private_roomid_input_layername___"

local targetPlatform = cc.Application:getInstance():getTargetPlatform()
function PriRoom:ctor()
    cclog("function PriRoom:ctor()==>")
    -- 私人房游戏资源搜索路径
    self._gameSearchPath = ""
    
    --网络回调
    local privateCallBack = function(command, message, dataBuffer, notShow)
        if type(command) == "table" then
            if command.m == cmd_pri_login.MDM_MB_PERSONAL_SERVICE then
                return self:onPrivateLoginServerMessage(command.s, message, dataBuffer, notShow)
            elseif command.m == cmd_pri_game.MDM_GR_PERSONAL_TABLE then
                return self:onPrivateGameServerMessage(command.s, message, dataBuffer, notShow)
            end
        else
            self:popMessage(message, notShow)
            if -1 == command then
                self:dismissPopWait()
            end
        end
        
    end
    self._priFrame = PriFrame:create(self, privateCallBack)

    self:reSet()
end

-- 实现单例
PriRoom._instance = nil
function PriRoom:getInstance( )
    if nil == PriRoom._instance then
        cclog("new instance")
        PriRoom._instance = PriRoom:create()
    end
    return PriRoom._instance
end

function PriRoom:reSet()

    cclog("function PriRoom:reSet()==>")
    -- 私人房模式游戏列表
    self.m_tabPriModeGame = {}
    -- 私人房列表
    self.m_tabPriRoomList = {}
    -- 房间管理记录
    self.m_tabRoomManageRecord = {}
    -- 创建记录
    self.m_tabCreateRecord = {}
    -- 参与记录
    self.m_tabJoinRecord = {}
    -- 私人房数据  CMD_GR_PersonalTableTip
    self.m_tabPriData = {}
    -- 私人房属性 tagPersonalRoomOption
    self.m_tabRoomOption = {}
    -- 私人房费用配置 tagPersonalTableParameter
    self.m_tabFeeConfigList = {}
    -- 是否自己房主
    self.m_bIsMyRoomOwner = false
    -- 私人房桌子号( 进入/查到到的 )
    self.m_dwTableID = yl.INVALID_TABLE
    -- 选择的私人房配置信息
    self.m_tabSelectRoomConfig = {}

    -- 大厅场景
    self._scene = nil
    -- 网络消息处理层
    self._viewFrame = nil
    -- 私人房信息层
    self._priView = nil

    -- 游戏服务器登陆动作
    self.m_nLoginAction = L_ACTION.ACT_NULL
    self.cbIsJoinGame = 0
    -- 是否已经取消桌子/退出
    self.m_bCancelTable = false
    -- 是否收到结算消息
    self.m_bRoomEnd = false
end

-- 当前游戏是否开启私人房模式
function PriRoom:isCurrentGameOpenPri( nKindID )
    cclog("function PriRoom:isCurrentGameOpenPri( nKindID )==>")

    return (self.m_tabPriModeGame[nKindID] or false)
end

-- 获取私人房
function PriRoom:getPriRoomByServerID( dwServerID )
    cclog("function PriRoom:getPriRoomByServerID( dwServerID )==>" .. dwServerID)

    local currentGameRoomList = self.m_tabPriRoomList[GlobalUserItem.nCurGameKind]
    if nil == currentGameRoomList then
        cclog("PriRoom:getPriRoomByServerID==currentGameRoomList is Null")
        return nil
    end

    for k,v in pairs(currentGameRoomList) do
        if v.wServerID == dwServerID and v.wServerType == yl.GAME_GENRE_PERSONAL then
            return v
        end
    end

    cclog("PriRoom:getPriRoomByServerID==priRoomServer is Null")
    return nil
end

-- 登陆私人房
function PriRoom:onLoginRoom( dwServerID, bLockEnter )
    cclog("function PriRoom:onLoginRoom( dwServerID, bLockEnter )==>" .. dwServerID)
    local pServer = self:getPriRoomByServerID(dwServerID)
    if nil == pServer then
        cclog("PriRoom:onLoginRoom==pServer Null")
        showToast(self._scene, "房间未找到, 请重试!", 2)
        return false
    end

    -- 登陆房间
    if nil ~= self._priFrame and nil ~= self._priFrame._gameFrame then
        cclog("PriRoom:onLoginRoom==loginRoom")
        bLockEnter = bLockEnter or false
        -- 锁表进入
        if bLockEnter then
            -- 动作定义
            PriRoom:getInstance().m_nLoginAction = PriRoom.L_ACTION.ACT_SEARCHROOM
        end
        self:showPopWait()
        GlobalUserItem.bPrivateRoom = pServer.wServerType == yl.GAME_GENRE_PERSONAL
        GlobalUserItem.nCurRoomIndex = pServer._nRoomIndex
        self._scene:onStartGame()
        self.m_bCancelTable = false
        return true
    end
    return false
end

-- 
function PriRoom:onEnterPlaza( scene, gameFrame )
    cclog("function PriRoom:onEnterPlaza( scene, gameFrame )==>")
    self._scene = scene
    self._priFrame._gameFrame = gameFrame
end

function PriRoom:onExitPlaza()
    cclog("function PriRoom:onExitPlaza()==>")
    if nil ~= self._priFrame._gameFrame then
        self._priFrame._gameFrame = nil
    end

    cc.Director:getInstance():getTextureCache():removeUnusedTextures()
    cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()
    self:exitRoom()
end

function PriRoom:onEnterPlazaFinish()
    cclog("function PriRoom:onEnterPlazaFinish()==>")
    -- 判断锁表
    if GlobalUserItem.dwLockServerID ~= 0 then
        GlobalUserItem.nCurGameKind = GlobalUserItem.dwLockKindID
        -- 更新逻辑
        if not self._scene:updateGame(GlobalUserItem.dwLockKindID)
            and not self._scene:loadGameList(GlobalUserItem.dwLockKindID) then
            -- 
            local entergame = self._scene:getGameInfo(GlobalUserItem.dwLockKindID)
            if nil ~= entergame then
                self._scene:updateEnterGameInfo(entergame)
                --启动游戏
                cclog("PriRoom:onEnterPlazaFinish ==> lock pri game")
                return true, false, self:onLoginRoom(GlobalUserItem.dwLockServerID, true)
            end            
        end
        cclog("PriRoom:onEnterPlazaFinish ==> lock and update game")
        return true, true, false
    end
    cclog("PriRoom:onEnterPlazaFinish ==> not lock game")
    return false, false, false
end

function PriRoom:onLoginPriRoomFinish()
    cclog("function PriRoom:onLoginPriRoomFinish()==>")
    local bHandled = false
    if nil ~= self._viewFrame and nil ~= self._viewFrame.onLoginPriRoomFinish then
        bHandled = self._viewFrame:onLoginPriRoomFinish()
    end
    -- 清理锁表
    GlobalUserItem.dwLockServerID = 0
    GlobalUserItem.dwLockKindID = 0

    if not bHandled then
        local meUser = self:getMeUserItem()
        if nil == meUser then
            return
        end
        if (meUser.cbUserStatus == yl.US_FREE or meUser.cbUserStatus == yl.US_NULL) then
            -- 搜索登陆
            if self.m_nLoginAction == L_ACTION.ACT_SEARCHROOM then
                self:showPopWait()
                -- 进入游戏
                self:getNetFrame():sendEnterPrivateGame()
            -- 解散登陆
            elseif PriRoom:getInstance().m_nLoginAction == PriRoom.L_ACTION.ACT_DISSUMEROOM then
                self:showPopWait()
                -- 发送解散    
                self:getNetFrame():sendDissumeGame(self.m_dwTableID)
            else
                self._priFrame._gameFrame:onCloseSocket()
                self._priFrame:onCloseSocket()
                GlobalUserItem.nCurRoomIndex = -1
                -- 退出游戏房间
                self._scene:onKeyBack()
            end
        elseif meUser.cbUserStatus == yl.US_PLAYING or meUser.cbUserStatus == yl.US_READY or meUser.cbUserStatus == yl.US_SIT then
            -- 搜索登陆
            if PriRoom:getInstance().m_nLoginAction == PriRoom.L_ACTION.ACT_SEARCHROOM
                or PriRoom:getInstance().m_nLoginAction == PriRoom.L_ACTION.ACT_ENTERTABLE then
                self:showPopWait()
                -- 切换游戏场景
                self._scene:onEnterTable()
                -- 发送配置
                self._priFrame._gameFrame:SendGameOption()
            -- 解散登陆
            elseif PriRoom:getInstance().m_nLoginAction == PriRoom.L_ACTION.ACT_DISSUMEROOM then
                self:showPopWait()
                -- 发送解散    
                self:getNetFrame():sendDissumeGame(self.m_dwTableID)
            end
        end
    end    
end

-- 用户状态变更( 进入、离开、准备 等)
function PriRoom:onEventUserState(viewid, useritem, bLeave)
    cclog("function PriRoom:onEventUserState(viewid, useritem, bLeave)==>")
    bLeave = bLeave or false
    if self.m_bCancelTable then
        return
    end
    if nil ~= self._priView and nil ~= self._priView.onRefreshInviteBtn then
        self._priView:onRefreshInviteBtn()
    end
end

function PriRoom:popMessage(message, notShow)
    cclog("function PriRoom:popMessage(message, notShow)==>")
    notShow = notShow or false
    if type(message) == "string" and "" ~= message then
        if notShow or nil == self._viewFrame then
            cclog(message)
        elseif nil ~= self._viewFrame then
            showToast(self._scene, message, 2)
        end
    end
end

function PriRoom:onPrivateLoginServerMessage(result, message, dataBuffer, notShow)
    cclog("function PriRoom:onPrivateLoginServerMessage(result, message, dataBuffer, notShow)==>")
    self:popMessage(message, notShow)

    if cmd_pri_login.SUB_MB_QUERY_PERSONAL_ROOM_LIST_RESULT == result 
        or cmd_pri_login.SUB_MB_PERSONAL_ROOM_OWNER_RESULT == result then
        -- 刷新列表
        if nil ~= self._viewFrame and nil ~= self._viewFrame.onReloadRecordList then
            self._viewFrame:onReloadRecordList()
        end
    elseif cmd_pri_login.SUB_MB_PERSONAL_FEE_PARAMETER == result then
        cclog("PriRoom fee list call back")
    end
    self:dismissPopWait()
end

--接收私房数据
function PriRoom:onPrivateGameServerMessage(result, message, dataBuffer, notShow)
    cclog("function PriRoom:onPrivateGameServerMessage(result, message, dataBuffer, notShow)==>" .. result)
    self:popMessage(message, notShow)
    self:dismissPopWait()

    if cmd_pri_game.SUB_GR_CREATE_SUCCESS == result then -- 私房创建成功
        if 0 == PriRoom:getInstance().m_tabRoomOption.cbIsJoinGame then
            -- 非必须加入
            self:onShowCreateResult(self._scene)
        end
    elseif cmd_pri_game.SUB_GR_CANCEL_TABLE == result then
        cclog("PriRoom  SUB_GR_CANCEL_TABLE")
        GlobalUserItem.bWaitQuit = true
        self.m_bCancelTable = true
        -- 解散桌子
        local curTag = nil
        if nil ~= self._scene and nil ~= self._scene._sceneRecord then
            curTag = self._scene._sceneRecord[#self._scene._sceneRecord]
        end
        if curTag == yl.SCENE_GAME and not self.m_bRoomEnd then
            local query = QueryDialog:create(message.szDescribeString, function(ok)
                    GlobalUserItem.bWaitQuit = false
                    if nil ~= self._viewFrame and nil ~= self._viewFrame.onExitRoom then
                        self._viewFrame:onExitRoom()
                    end
                end)
                :setCanTouchOutside(false)
                :addTo(self._viewFrame)
            local zorder = 0
            if nil ~= self._viewFrame.priGameLayerZorder then
                zorder = self._viewFrame:priGameLayerZorder() - 1
            end
            query:setLocalZOrder(zorder)
        else
            showToast(self._scene, message.szDescribeString, 2)
        end
        self.m_bRoomEnd = false   
    elseif cmd_pri_game.SUB_GR_CANCEL_REQUEST == result then
        -- 请求解散
        -- message = game.CMD_GR_CancelRequest
        local useritem = self._priFrame._gameFrame._UserList[message.dwUserID]
        if nil == useritem then
            return
        end
        local curTag = nil
        if nil ~= self._scene and nil ~= self._scene._sceneRecord then
            curTag = self._scene._sceneRecord[#self._scene._sceneRecord]
        end
        if nil ~= self.m_queryQuit and nil ~= self.m_queryQuit:getParent() then
            self.m_queryQuit:removeFromParent()
        end
        if curTag == yl.SCENE_GAME then
            self.m_queryQuit = QueryDialog:create(useritem.szNickName .. "请求解散房间, 是否同意?", function(ok)
                    if ok then
                        self:getNetFrame():sendRequestReply(1)
                    else
                        self:getNetFrame():sendRequestReply(0)
                    end
                    self.m_queryQuit = nil
                end)
            :setCanTouchOutside(false)
            :addTo(self._viewFrame)
        else

        end        
    elseif cmd_pri_game.SUB_GR_REQUEST_REPLY == result then
        -- 请求答复
        -- message = game.CMD_GR_RequestReply
        local useritem = self._priFrame._gameFrame._UserList[message.dwUserID]
        if nil == useritem then
            return
        end
        local bHandled = false
        if nil ~= self._viewFrame and nil ~= self._viewFrame.onCancellApply then
            bHandled = self._viewFrame:onCancellApply(useritem, message)
        end
        if not bHandled then
            local tips = "同意解散"
            if 0 == message.cbAgree then
                tips = "不同意解散"
            end
            local curTag = nil
            if nil ~= self._scene and nil ~= self._scene._sceneRecord then
                curTag = self._scene._sceneRecord[#self._scene._sceneRecord]
            end
            if curTag == yl.SCENE_GAME then
                showToast(self._scene, useritem.szNickName .. tips, 2)
            end            
        end
    elseif cmd_pri_game.SUB_GR_REQUEST_RESULT == result then
        -- 请求结果
        -- message = game.CMD_GR_RequestResult
        if 0 == message.cbResult then
            local curTag = nil
            if nil ~= self._scene and nil ~= self._scene._sceneRecord then
                curTag = self._scene._sceneRecord[#self._scene._sceneRecord]
            end
            if curTag == yl.SCENE_GAME then
                showToast(self._scene, "解散房间请求未通过", 2)
            end            
            return
        end
        self.m_bCancelTable = true
        local bHandled = false
        if nil ~= self._viewFrame and nil ~= self._viewFrame.onCancelResult then
            bHandled = self._viewFrame:onCancelResult(message)
        end
        if not bHandled then
            
        end
    elseif cmd_pri_game.SUB_GR_WAIT_OVER_TIME == result then
        -- 超时提示
        -- message = game.CMD_GR_WaitOverTime
        local useritem = self._priFrame._gameFrame._UserList[message.dwUserID]
        if nil == useritem then
            return
        end
        local curTag = nil
        if nil ~= self._scene and nil ~= self._scene._sceneRecord then
            curTag = self._scene._sceneRecord[#self._scene._sceneRecord]
        end
        if curTag == yl.SCENE_GAME then
            local query = QueryDialog:create(useritem.szNickName .. "断线等待超时, 是否继续等待?", function(ok)
                    if ok then
                        self:getNetFrame():sendRequestReply(0)
                    else
                        self:getNetFrame():sendRequestReply(1)
                    end
                    --self:showPopWait()
                end)
                :setCanTouchOutside(false)
                :addTo(self._viewFrame)
        end
    elseif cmd_pri_game.SUB_GR_PERSONAL_TABLE_TIP == result then
        -- 游戏信息
        if nil ~= self._priView and nil ~= self._priView.onRefreshInfo then
            self._priView:onRefreshInfo()
        end
    elseif cmd_pri_game.SUB_GR_PERSONAL_TABLE_END == result then --私房结束
        GlobalUserItem.bWaitQuit = true
        -- 屏蔽重连功能
        GlobalUserItem.bAutoConnect = false
        -- 结束消息
        if nil ~= self._priView and nil ~= self._priView.onPriGameEnd then
            self._priView:onPriGameEnd(message, dataBuffer)
        end
        self.m_bRoomEnd = true
    elseif cmd_pri_game.SUB_GR_CANCEL_TABLE_RESULT == result then  --解散结果
        -- 解散结果
        if 1 == message.cbIsDissumSuccess then
            showToast(self._scene, "解散成功", 2)
        end
        --更新房间管理记录
        for i = 1, #self.m_tabRoomManageRecord do
            if message.szRoomID == self.m_tabRoomManageRecord[i].szRoomID then
                table.remove(self.m_tabRoomManageRecord, i)
                break
            end
        end

        --刷新列表
        if nil ~= self._viewFrame and nil ~= self._viewFrame.onReloadRecordList then
            self._viewFrame:onReloadRecordList()
        end
    elseif cmd_pri_game.SUB_GF_PERSONAL_MESSAGE == result then
    elseif cmd_pri_game.SUB_GR_CURRECE_ROOMCARD_AND_BEAN == result then
        -- 解散后游戏信息
        if nil ~= self._viewFrame and nil ~= self._viewFrame.onRefreshInfo then
            self._viewFrame:onRefreshInfo()
        end
    end
end

-- 网络管理
function PriRoom:getNetFrame()
    cclog("function PriRoom:getNetFrame()==>")
    return self._priFrame
end

-- 设置网络消息处理层
function PriRoom:setViewFrame(viewFrame)
    cclog("function PriRoom:setViewFrame(viewFrame)==>")
    self._viewFrame = viewFrame
end

-- 获取自己数据
function PriRoom:getMeUserItem()
    cclog("function PriRoom:getMeUserItem()==>")
    return self._priFrame._gameFrame:GetMeUserItem()
end

-- 获取游戏玩家数(椅子数)
function PriRoom:getChairCount()
    cclog("function PriRoom:getChairCount()==>")
    return self._priFrame._gameFrame:GetChairCount()
end

-- 获取大厅场景
function PriRoom:getPlazaScene()
    cclog("function PriRoom:getPlazaScene()==>")
    return self._scene
end

-- 进入游戏房间
function PriRoom:enterRoom( scene )

    cclog("function PriRoom:enterRoom( scene )==>")

    local entergame = scene:getEnterGameInfo()
    local bPirMode = PriRoom:getInstance():isCurrentGameOpenPri(GlobalUserItem.nCurGameKind)
    if nil ~= entergame and true == bPirMode and "" == self._gameSearchPath then
        local modulestr = string.gsub(entergame._KindName, "%.", "/")
        self._gameSearchPath = device.writablePath .. "download/game/" .. modulestr .. "privatemode/res/"
        cc.FileUtils:getInstance():addSearchPath(self._gameSearchPath)
    end    
end

function PriRoom:exitRoom( )
    cclog("function PriRoom:exitRoom( )==>")
    --重置搜索路径
    local oldPaths = cc.FileUtils:getInstance():getSearchPaths()
    local newPaths = {}
    for k,v in pairs(oldPaths) do
        if tostring(v) ~= tostring(self._gameSearchPath) then
            table.insert(newPaths, v)
        end
    end
    cc.FileUtils:getInstance():setSearchPaths(newPaths)
    self._gameSearchPath = ""
    self:setViewFrame(nil)
end

-- 进入游戏界面
function PriRoom:enterGame( gameLayer, scene )
    cclog("function PriRoom:enterGame( gameLayer, scene )==>")

    self:enterRoom(scene)
    local entergame = scene:getEnterGameInfo()
    if nil ~= entergame then
        local modulestr = string.gsub(entergame._KindName, "%.", "/")
        local gameFile = "download/game/" .. modulestr .. "privatemode/src/PriGameLayer.lua"
        cclog("PriRoom:enterGame===gameFile： " .. gameFile)
        if cc.FileUtils:getInstance():isFileExist(gameFile) then
            local lay = appdf.req(gameFile):create( gameLayer )
            if nil ~= lay then
                gameLayer._gameView:addChild(lay, gameLayer:priGameLayerZorder())
                gameLayer._gameView._priView = lay
                self._priView = lay
            end
            -- 绑定回调
            self:setViewFrame(gameLayer)
        end
    end
    self.m_bRoomEnd = false
end

-- 退出游戏界面
function PriRoom:exitGame()
    cclog("function PriRoom:exitGame()==>")
    self._priView = nil
end

function PriRoom:showPopWait()
    cclog("function PriRoom:showPopWait()==>")
    self._scene:showPopWait()
end

function PriRoom:dismissPopWait()
    cclog("function PriRoom:dismissPopWait()==>")
    self._scene:dismissPopWait()
end

-- 请求退出游戏
function PriRoom:queryQuitGame( cbGameStatus )
    cclog("function PriRoom:queryQuitGame( cbGameStatus )==>")
    if self.m_bCancelTable then
        cclog("PriRoom:queryQuitGame 已经取消!")
        return
    end

    local tip = "约战房在游戏中退出需其他玩家同意, 是否申请解散房间?"
    QueryDialog:create(tip, function(ok)
            if ok == true then    
                self:getNetFrame():sendRequestDissumeGame()
            end
        end)
    :setCanTouchOutside(false)
    :addTo(self._viewFrame)
end

-- 请求解散房间
function PriRoom:queryDismissRoom()
    cclog("function PriRoom:queryDismissRoom()==>")
    if self.m_bCancelTable then
        cclog("PriRoom:queryQuitGame 已经取消!")
        return
    end
    local tip = "约战房在游戏中退出需其他玩家同意, 是否申请解散房间?"
    QueryDialog:create(tip, function(ok)
            if ok == true then 
                --self:showPopWait()   
                self:getNetFrame():sendRequestDissumeGame()
            end
        end)
    :setCanTouchOutside(false)
    :addTo(self._viewFrame)
end

-- 获取邀请分享内容
function PriRoom:getInviteShareMsg( roomDetailInfo )
    cclog("function PriRoom:getInviteShareMsg( roomDetailInfo )==>")
    local entergame = self._scene:getEnterGameInfo()
    if nil ~= entergame then
        local modulestr = string.gsub(entergame._KindName, "%.", "/")
        local gameFile =  "download/game/" .. modulestr .. "privatemode/src/PriRoomCreateLayer.lua"
        if cc.FileUtils:getInstance():isFileExist(gameFile) then
            return appdf.req(gameFile):getInviteShareMsg( roomDetailInfo )
        end
    end
    return {title = "", content = ""}
end

-- 私人房邀请好友
function PriRoom:priInviteFriend(frienddata, gameKind, wServerNumber, tableId, inviteMsg)
    cclog("function PriRoom:priInviteFriend(frienddata, gameKind, wServerNumber, tableId, inviteMsg)==>")
    if nil == frienddata or nil == self._scene.inviteFriend then
        return
    end
    if not gameKind then
        gameKind = GlobalUserItem.nCurGameKind
    else
        gameKind = tonumber(gameKind)
    end
    local id = frienddata.dwUserID
    if nil == id then
        return
    end
    local tab = {}
    tab.dwInvitedUserID = id
    tab.wKindID = gameKind
    tab.wServerNumber = wServerNumber or 0
    tab.wTableID = tableId or 0
    tab.szInviteMsg = inviteMsg or ""
    if FriendMgr:getInstance():sendInvitePrivateGame(tab) then
        local runScene = cc.Director:getInstance():getRunningScene()
        if nil ~= runScene then
            showToast(runScene, "邀请消息已发送!", 1)
        end
    end
end

-- 分享图片给好友
function PriRoom:imageShareToFriend( frienddata, imagepath, sharemsg )
    cclog("function PriRoom:imageShareToFriend( frienddata, imagepath, sharemsg )==>")
    if nil == frienddata or nil == self._scene.imageShareToFriend then
        return
    end
    local id = frienddata.dwUserID
    if nil == id then
        return
    end
    self._scene:imageShareToFriend(id, imagepath, sharemsg)
end

--创建私房
function PriRoom:onCreateRoom(scene)
    cclog("PriRoom:onCreateRoom===>")
    self:showPopWait()
    self._priFrame:onQueryLockInfo()
    self.mQueryLockEndFunc = function()
        --启动创建房间
        local strFolder = yl.getSubGameFolder(tostring(GlobalUserItem.nCurGameKind))
        local modulestr = strFolder
        local roomCreateFile = "download/game/" .. modulestr .. "/privatemode/src/PriRoomCreateLayer.lua"
        cclog("PriRoom:onCreateRoom==roomCreateFile: " .. roomCreateFile)
        if cc.FileUtils:getInstance():isFileExist(roomCreateFile) then
            local lay = appdf.req(roomCreateFile):create( scene )
            -- 绑定回调
            self:setViewFrame(lay)
            scene:addChild(lay)
        else
            doAssert("Can not find: " .. roomCreateFile)
        end
        self:dismissPopWait()
    end
end

--加入私房
function PriRoom:onJoinRoom(scene)
    cclog("PriRoom:onJoinRoom===>")
    self:showPopWait()
    self._priFrame:onQueryLockInfo()
    self.mQueryLockEndFunc = function ()
        local lay = appdf.req(appdf.CLIENT_SRC .. "privatemode/plaza/src/views/RoomIdInputLayer.lua"):create()
        self:setViewFrame(lay)
        scene:addChild(lay)
        self:dismissPopWait()
    end
end

--我的房间
function PriRoom:onMyRoom(scene)
    cclog("PriRoom:onMyRoom===>")
    -- 记录界面
    local lay = appdf.req(MODULE.PLAZAMODULE .. "views.RoomRecordLayer"):create( scene )
    -- 绑定回调
    self:setViewFrame(lay)
    scene:addChild(lay)
end

--房间创建结果
function PriRoom:onShowCreateResult(scene)
    cclog("PriRoom:onShowCreateResult===>")
    -- 创建结果
    local roomResLayer = appdf.req(MODULE.PLAZAMODULE .. "views.RoomCreateResult"):create(scene)
    scene:addChild(roomResLayer)
end

--查询房间信息锁结果
function PriRoom:onSubQueryLockInfoResult(pData)
    cclog("PriFrame:onSubQueryLockInfoResult===>")
    if pData.wKind > 0 and pData.wServerID > 0 then
        GlobalUserItem.dwLockKindID = pData.wKind
        GlobalUserItem.dwLockServerID = pData.wServerID
        self:onLoginRoom(GlobalUserItem.dwLockServerID, true)
    else
        if self.mQueryLockEndFunc then
           self.mQueryLockEndFunc()
        end
    end
    self.mQueryLockEndFunc = nil
end