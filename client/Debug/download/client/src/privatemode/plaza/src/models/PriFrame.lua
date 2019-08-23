-- Name: PriFrame
-- Func: 私房网络处理
-- Author: Johny


local BaseFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.BaseFrame")
local PriFrame = class("PriFrame",BaseFrame)
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")

local cmd_private = appdf.req(PriRoom.MODULE.PRIHEADER .. "CMD_Private")
local define_private = appdf.req(PriRoom.MODULE.PRIHEADER .. "Define_Private")
local struct_private = appdf.req(PriRoom.MODULE.PRIHEADER .. "Struct_Private")

-- 登陆服务器CMD
local cmd_pri_login = cmd_private.login
-- 游戏服务器CMD
local cmd_pri_game = cmd_private.game

PriFrame.OP_CREATEROOM = cmd_pri_login.SUB_MB_QUERY_GAME_SERVER                 -- 创建房间
PriFrame.OP_SEARCHROOM = cmd_pri_login.SUB_MB_SEARCH_SERVER_TABLE               -- 查询房间
PriFrame.OP_ROOMPARAM = cmd_pri_login.SUB_MB_GET_PERSONAL_PARAMETER             -- 私人房配置
PriFrame.OP_QUERYLIST = cmd_pri_login.SUB_MB_QUERY_PERSONAL_ROOM_LIST           -- 房间创建列表
PriFrame.OP_QUERY_ROOMMANAGEMENT_LIST = cmd_pri_login.SUB_MB_PERSONAL_ROOM_OWNER   -- 房间管理列表
PriFrame.OP_DISSUMEROOM = cmd_pri_login.SUB_MB_DISSUME_SEARCH_SERVER_TABLE      -- 解散桌子
PriFrame.OP_EXCHANGEROOMCARD = cmd_pri_login.SUB_MB_ROOM_CARD_EXCHANGE_TO_SCORE -- 房卡兑换游戏币
PriFrame.OP_QUERYLOCKINFO = cmd_pri_login.SUB_MB_USER_QUERY_LOCK_INFO           -- 查询房间锁信息


function LOGINSERVER(code)
    return { m = cmd_pri_login.MDM_MB_PERSONAL_SERVICE, s = code }
end
function GAMESERVER(code)
    return { m = cmd_pri_game.MDM_GR_PERSONAL_TABLE, s = code }
end

--
function PriFrame:ctor(view,callbcak)
    cclog("function PriFrame:ctor(view,callbcak)==>")
    PriFrame.super.ctor(self,view,callbcak)
end

-- 创建房间
function PriFrame:onCreateRoom()
    cclog("function PriFrame:onCreateRoom()==>")
    --操作记录
    self._oprateCode = PriFrame.OP_CREATEROOM
    if not self:onCreateSocket(yl.LOGONSERVER,yl.LOGONPORT) and nil ~= self._callBack then
        self._callBack(LOGINSERVER(-1),"建立连接失败！")
    end
    -- 动作定义
    PriRoom:getInstance().m_nLoginAction = PriRoom.L_ACTION.ACT_CREATEROOM
end

-- 查询房间
function PriFrame:onSearchRoom( roomId )
    cclog("function PriFrame:onSearchRoom( roomId )==>" .. roomId)
    --操作记录
    self._oprateCode = PriFrame.OP_SEARCHROOM
    self._roomId = roomId or ""
    if not self:onCreateSocket(yl.LOGONSERVER,yl.LOGONPORT) and nil ~= self._callBack then
        self._callBack(LOGINSERVER(-1),"建立连接失败！")
    end
end

-- 私人房间配置
function PriFrame:onGetRoomParameter()
    cclog("function PriFrame:onGetRoomParameter()==>")
    --操作记录
    self._oprateCode = PriFrame.OP_ROOMPARAM
    if not self:onCreateSocket(yl.LOGONSERVER,yl.LOGONPORT) and nil ~= self._callBack then
        self._callBack(LOGINSERVER(-1),"建立连接失败！")
    end
end

-- 查询房间创建列表
function PriFrame:onQueryRoomList()
    cclog("function PriFrame:onQueryRoomList()==>")
    --操作记录
    self._oprateCode = PriFrame.OP_QUERYLIST
    if nil ~= self._gameFrame and self._gameFrame:isSocketServer() then
        self:sendQueryRoomList()
    else
        if not self:onCreateSocket(yl.LOGONSERVER,yl.LOGONPORT) and nil ~= self._callBack then
            self._callBack(LOGINSERVER(-1),"建立连接失败！")
        end
    end
end

--查询房间管理列表
function PriFrame:onQueryRoomManagementList()
    cclog("function PriFrame:onQueryRoomManagementList()==>")
    --操作记录
    self._oprateCode = PriFrame.OP_QUERY_ROOMMANAGEMENT_LIST
    if not self:onCreateSocket(yl.LOGONSERVER,yl.LOGONPORT) and nil ~= self._callBack then
        self._callBack(LOGINSERVER(-1),"建立连接失败！")
    end 
end

-- 解散房间
function PriFrame:onDissumeRoom( roomId )
    cclog("function PriFrame:onDissumeRoom( roomId )==>")
    --操作记录
    self._oprateCode = PriFrame.OP_DISSUMEROOM
    self._roomId = roomId or ""
    if not self:onCreateSocket(yl.LOGONSERVER,yl.LOGONPORT) and nil ~= self._callBack then
        self._callBack(LOGINSERVER(-1),"建立连接失败！")
    end
end

-- 房卡兑换游戏币
function PriFrame:onExchangeScore( lCount )
    cclog("function PriFrame:onExchangeScore( lCount )==>")
    --操作记录
    self._oprateCode = PriFrame.OP_EXCHANGEROOMCARD
    self._lExchangeRoomCard = lCount
    if not self:onCreateSocket(yl.LOGONSERVER,yl.LOGONPORT) and nil ~= self._callBack then
        self._callBack(LOGINSERVER(-1),"建立连接失败！")
    end
end

-- 查询房间锁信息
function PriFrame:onQueryLockInfo()
    cclog("function PriFrame:onQueryLockInfo( lCount )==>")
    --操作记录
    self._oprateCode = PriFrame.OP_QUERYLOCKINFO
    if not self:onCreateSocket(yl.LOGONSERVER,yl.LOGONPORT) and nil ~= self._callBack then
        self._callBack(LOGINSERVER(-1),"建立连接失败！")
    end
end

--连接结果
function PriFrame:onConnectCompeleted()
    cclog("================== PriFrame:onConnectCompeleted ================== ==> " .. self._oprateCode)
    if self._oprateCode == PriFrame.OP_CREATEROOM then              -- 创建房间
        self:sendCreateRoom()
    elseif self._oprateCode == PriFrame.OP_SEARCHROOM then          -- 查询房间
        self:sendSearchRoom()
    elseif self._oprateCode == PriFrame.OP_ROOMPARAM then           -- 私人房配置
        self:sendQueryRoomParam()
    elseif self._oprateCode == PriFrame.OP_QUERYLIST then           -- 请求房间创建记录
        self:sendQueryRoomList()
    elseif self._oprateCode == PriFrame.OP_DISSUMEROOM then         -- 解散桌子
        self:sendDissumeRoom()
    elseif self._oprateCode == PriFrame.OP_EXCHANGEROOMCARD then    -- 房卡兑换游戏币
        self:sendExchangeScore()
    elseif self._oprateCode == PriFrame.OP_QUERY_ROOMMANAGEMENT_LIST then  --查询房间管理列表
        self:sendQueryRoomManagementList()
    elseif self._oprateCode == PriFrame.OP_QUERYLOCKINFO then  --查询房间锁信息
        self:sendQueryLockInfo()
    else
        self:onCloseSocket()
        if nil ~= self._callBack then
            self._callBack(LOGINSERVER(-1),"未知操作模式！")
        end 
        PriRoom:getInstance():dismissPopWait()
    end
end

--查询房间锁信息
function PriFrame:sendQueryLockInfo()
    cclog("PriFrame:sendQueryLockInfo===>")
    local buffer = ExternalFun.create_netdata(cmd_pri_login.CMD_MB_LockInfoQuery)
    buffer:setcmdinfo(cmd_pri_login.MDM_MB_PERSONAL_SERVICE,cmd_pri_login.SUB_MB_USER_QUERY_LOCK_INFO)
    buffer:pushdword(GlobalUserItem.dwUserID)
    if not self:sendSocketData(buffer) and nil ~= self._callBack then
        self._callBack(LOGINSERVER(-1),"发送查询房间锁信息失败！")
    end    
end

-- 发送创建房间
function PriFrame:sendCreateRoom()
    cclog("function PriFrame:sendCreateRoom()==>")
    local buffer = ExternalFun.create_netdata(cmd_pri_login.CMD_MB_QueryGameServer)
    buffer:setcmdinfo(cmd_pri_login.MDM_MB_PERSONAL_SERVICE,cmd_pri_login.SUB_MB_QUERY_GAME_SERVER)
    buffer:pushdword(GlobalUserItem.dwUserID)
    buffer:pushdword(GlobalUserItem.nCurGameKind)
    buffer:pushbyte(PriRoom:getInstance().m_tabRoomOption.cbIsJoinGame)
    if not self:sendSocketData(buffer) and nil ~= self._callBack then
        self._callBack(LOGINSERVER(-1),"发送创建房间失败！")
    end
end

-- 发送查询私人房
function PriFrame:sendSearchRoom()
    cclog("function PriFrame:sendSearchRoom()==>" .. self._roomId .. "=" .. GlobalUserItem.nCurGameKind)
    local buffer = ExternalFun.create_netdata(cmd_pri_login.CMD_MB_SerchServerTableEnter)
    buffer:setcmdinfo(cmd_pri_login.MDM_MB_PERSONAL_SERVICE,cmd_pri_login.SUB_MB_SEARCH_SERVER_TABLE)
    buffer:pushstring(self._roomId, define_private.ROOM_ID_LEN)
    buffer:pushdword(GlobalUserItem.nCurGameKind)
    if not self:sendSocketData(buffer) and nil ~= self._callBack then
        self._callBack(LOGINSERVER(-1),"发送查询房间失败！")
    end
end

-- 发送请求配置
function PriFrame:sendQueryRoomParam()
    cclog("function PriFrame:sendQueryRoomParam()==>")
    local buffer = ExternalFun.create_netdata(cmd_pri_login.CMD_MB_GetPersonalParameter)
    buffer:setcmdinfo(cmd_pri_login.MDM_MB_PERSONAL_SERVICE,cmd_pri_login.SUB_MB_GET_PERSONAL_PARAMETER)
    buffer:pushdword(GlobalUserItem.nCurGameKind)
    if not self:sendSocketData(buffer) and nil ~= self._callBack then
        self._callBack(LOGINSERVER(-1),"发送请求配置失败！")
    end
end

-- 发送查询房间创建列表
function PriFrame:sendQueryRoomList()
    cclog("function PriFrame:sendQueryRoomList()==>")
    local buffer = ExternalFun.create_netdata(cmd_pri_login.CMD_MB_QeuryPersonalRoomList)
    buffer:setcmdinfo(cmd_pri_login.MDM_MB_PERSONAL_SERVICE,cmd_pri_login.SUB_MB_QUERY_PERSONAL_ROOM_LIST)
    buffer:pushdword(GlobalUserItem.dwUserID)
    buffer:pushdword(GlobalUserItem.nCurGameKind)
    if not self:sendSocketData(buffer) and nil ~= self._callBack then
        self._callBack(LOGINSERVER(-1),"发送查询房间创建列表失败！")
    end
end

-- 发送房间管理列表
function PriFrame:sendQueryRoomManagementList()
    cclog("function PriFrame:sendQueryRoomManagementList()==>")
    local buffer = ExternalFun.create_netdata(cmd_pri_login.CMD_MB_QeuryRoomManagementList)
    buffer:setcmdinfo(cmd_pri_login.MDM_MB_PERSONAL_SERVICE,cmd_pri_login.SUB_MB_PERSONAL_ROOM_OWNER)
    buffer:pushdword(GlobalUserItem.dwUserID)
    buffer:pushdword(GlobalUserItem.nCurGameKind)
    if not self:sendSocketData(buffer) and nil ~= self._callBack then
        self._callBack(LOGINSERVER(-1),"发送查询房间管理列表失败！")
    end  
end

-- 发送解散房间
function PriFrame:sendDissumeRoom()
    cclog("function PriFrame:sendDissumeRoom()==>")
    local buffer = ExternalFun.create_netdata(cmd_pri_login.CMD_MB_SearchServerTable)
    buffer:setcmdinfo(cmd_pri_login.MDM_MB_PERSONAL_SERVICE,cmd_pri_login.SUB_MB_DISSUME_SEARCH_SERVER_TABLE)
    buffer:pushstring(self._roomId, define_private.ROOM_ID_LEN)
    if not self:sendSocketData(buffer) and nil ~= self._callBack then
        self._callBack(LOGINSERVER(-1),"发送解散房间失败！")
    end
end

-- 发送房卡兑换游戏币
function PriFrame:sendExchangeScore()
    cclog("function PriFrame:sendExchangeScore()==>")
    local buffer = ExternalFun.create_netdata(cmd_pri_login.CMD_GP_ExchangeScoreByRoomCard)
    buffer:setcmdinfo(cmd_pri_login.MDM_MB_PERSONAL_SERVICE,cmd_pri_login.SUB_MB_ROOM_CARD_EXCHANGE_TO_SCORE)
    buffer:pushdword(GlobalUserItem.dwUserID)
    buffer:pushscore(self._lExchangeRoomCard)
    buffer:pushstring(GlobalUserItem.szMachine,yl.LEN_MACHINE_ID)
    if not self:sendSocketData(buffer) and nil ~= self._callBack then
        self._callBack(LOGINSERVER(-1),"发送兑换游戏币失败！")
    end
end

-- 发送游戏服务器消息
function PriFrame:sendGameServerMsg( buffer )
    cclog("function PriFrame:sendGameServerMsg( buffer )==>")

    if nil ~= self._gameFrame and self._gameFrame:isSocketServer() then
        if not self._gameFrame:sendSocketData(buffer) then
            self._callBack(GAMESERVER(-1),"创建房间失败！")
        end
    end    
end

-- 发送进入私人房
function PriFrame:sendEnterPrivateGame()
    cclog("function PriFrame:sendEnterPrivateGame()==>")
    if nil ~= self._gameFrame and self._gameFrame:isSocketServer() then
        local c = yl.INVALID_TABLE,yl.INVALID_CHAIR
        -- 找座椅
        local chaircount = self._gameFrame._wChairCount
        for i = 1, chaircount  do
            local sc = i - 1
            if nil == self._gameFrame:getTableUserItem(PriRoom:getInstance().m_dwTableID, sc) then
                c = sc
                break
            end
        end
        cclog( "PriFrame:sendEnterPrivateGame ==> private enter " .. PriRoom:getInstance().m_dwTableID .. " ## " .. c)

        self._gameFrame:SitDown(PriRoom:getInstance().m_dwTableID, c)
        self._gameFrame:SendGameOption()
    end
end

-- 强制解散游戏
function PriFrame:sendDissumeGame( tableId )
    cclog("function PriFrame:sendDissumeGame( tableId )==>")

    tableId = tableId or 0
    if nil ~= self._gameFrame and self._gameFrame:isSocketServer() then
        local buffer = ExternalFun.create_netdata(cmd_pri_game.CMD_GR_HostDissumeGame)
        buffer:setcmdinfo(cmd_pri_game.MDM_GR_PERSONAL_TABLE,cmd_pri_game.SUB_GR_HOSTL_DISSUME_TABLE)
        buffer:pushdword(GlobalUserItem.dwUserID)
        buffer:pushdword(tableId)
        if not self._gameFrame:sendSocketData(buffer) then
            self._callBack(GAMESERVER(-1),"发送解散游戏失败！")
        end
    end
end

--  请求解散游戏
function PriFrame:sendRequestDissumeGame()
    cclog("function PriFrame:sendRequestDissumeGame()==>")
    if nil ~= self._gameFrame and self._gameFrame:isSocketServer() then
        cclog("game socket sendRequestDissumeGame")
        local buffer = ExternalFun.create_netdata(cmd_pri_game.CMD_GR_CancelRequest)
        buffer:setcmdinfo(cmd_pri_game.MDM_GR_PERSONAL_TABLE,cmd_pri_game.SUB_GR_CANCEL_REQUEST)
        buffer:pushdword(GlobalUserItem.dwUserID)
        buffer:pushdword(self._gameFrame:GetTableID())
        buffer:pushdword(self._gameFrame:GetChairID())
        if not self._gameFrame:sendSocketData(buffer) then
            self._callBack(GAMESERVER(-1),"请求解散游戏失败！")
        end
    end
end

-- 回复请求
function PriFrame:sendRequestReply( cbAgree )
    cclog("function PriFrame:sendRequestReply( cbAgree )==>")
    if nil ~= self._gameFrame and self._gameFrame:isSocketServer() then
        local buffer = ExternalFun.create_netdata(cmd_pri_game.CMD_GR_RequestReply)
        buffer:setcmdinfo(cmd_pri_game.MDM_GR_PERSONAL_TABLE,cmd_pri_game.SUB_GR_REQUEST_REPLY)
        buffer:pushdword(GlobalUserItem.dwUserID)
        buffer:pushdword(self._gameFrame:GetTableID())
        buffer:pushbyte(cbAgree)
        if not self._gameFrame:sendSocketData(buffer) then
            self._callBack(GAMESERVER(-1),"回复请求失败！")
        end
    end
end

--网络信息(短连接)
function PriFrame:onSocketEvent( main,sub,pData )
    cclog("PriFrame:onSocketEvent ==> " .. main .. "##" .. sub)
    local needClose = true
    local dissmissPop = true
    if cmd_pri_login.MDM_MB_PERSONAL_SERVICE == main then--200
        if cmd_pri_login.SUB_MB_SEARCH_RESULT == sub then                           -- 房间搜索结果--207
            self:onSubSearchRoomResult(pData)
        elseif cmd_pri_login.SUB_MB_DISSUME_SEARCH_RESULT == sub then               -- 解散搜索结果--214
            self:onSubDissumeSearchReasult(pData)
        elseif cmd_pri_login.SUB_MB_QUERY_PERSONAL_ROOM_LIST_RESULT == sub then     -- 房间创建列表-211
            self:onSubPrivateRoomList(pData)
        elseif cmd_pri_login.SUB_MB_PERSONAL_PARAMETER == sub then                  -- 私人房间属性--209
            cclog("PriFrame:onSocketEvent==>" .. json.encode(PriRoom:getInstance().m_tabRoomOption))
            needClose = false
            PriRoom:getInstance().m_tabRoomOption = ExternalFun.read_netdata( struct_private.tagPersonalRoomOption, pData )
        elseif cmd_pri_login.SUB_MB_PERSONAL_FEE_PARAMETER == sub then              -- 私人房费用配置--212
            self:onSubFeeParameter(pData)
        elseif cmd_pri_login.SUB_MB_QUERY_GAME_SERVER_RESULT == sub then            -- 创建结果-205
            dissmissPop = self:onSubGameServerResult(pData)
        elseif cmd_pri_login.SUB_GP_EXCHANGE_ROOM_CARD_RESULT == sub then           -- 房卡兑换游戏币结果--222
            self:onSubExchangeRoomCardResult(pData)
        elseif cmd_pri_login.SUB_MB_PERSONAL_ROOM_OWNER_RESULT == sub then      --房间管理列表结果-224
            self:onSubRoomManagementList(pData)
        elseif cmd_pri_login.SUB_MB_LOCK_INFO_RESULT == sub then                --查询房间信息锁结果--226
            self:onSubQueryLockInfoResult(pData)
        end
    end

    if needClose then        
        self:onCloseSocket()
        if dissmissPop then
            PriRoom:getInstance():dismissPopWait()
        end
    end    
end

--查询房间信息锁结果
function PriFrame:onSubQueryLockInfoResult(pData)
    cclog("function PriFrame:onSubQueryLockInfoResult( pData )==>")
    local cmd_table = ExternalFun.read_netdata(cmd_pri_login.CMD_MB_QueryLockInfoResult, pData)
    PriRoom:getInstance():onSubQueryLockInfoResult(cmd_table)
end

-- 房间搜索结果
function PriFrame:onSubSearchRoomResult( pData )
    cclog("function PriFrame:onSubSearchRoomResult( pData )==>")

    local cmd_table = ExternalFun.read_netdata(cmd_pri_login.CMD_MB_SearchResult, pData)
    dump(cmd_table, "CMD_MB_SearchResult", 6)
    if 0 == cmd_table.dwServerID then
        if nil ~= self._callBack then
            self._callBack(LOGINSERVER(cmd_pri_login.SUB_MB_SEARCH_RESULT), "该房间ID不存在, 请重新输入!")
        end
        return
    end
    -- 信息记录
    PriRoom:getInstance().m_dwTableID = cmd_table.dwTableID

    -- 动作定义
    PriRoom:getInstance().m_nLoginAction = PriRoom.L_ACTION.ACT_SEARCHROOM
    -- 发送登陆
    PriRoom:getInstance():onLoginRoom(cmd_table.dwServerID)
end

-- 解散搜索结果
function PriFrame:onSubDissumeSearchReasult( pData )
    cclog("function PriFrame:onSubDissumeSearchReasult( pData )==>")

    local cmd_table = ExternalFun.read_netdata(cmd_pri_login.CMD_MB_DissumeSearchResult, pData)
    dump(cmd_table, "CMD_MB_DissumeSearchResult", 6)

    -- 信息记录
    PriRoom:getInstance().m_dwTableID = cmd_table.dwTableID
    -- 动作定义
    PriRoom:getInstance().m_nLoginAction = PriRoom.L_ACTION.ACT_DISSUMEROOM
    -- 发送登陆
    PriRoom:getInstance():onLoginRoom(cmd_table.dwServerID)
end

-- 房间管理列表
function PriFrame:onSubRoomManagementList(pData)
    cclog("function PriFrame:onSubRoomManagementList( pData )==>" .. pData:getlen())
    PriRoom:getInstance().m_tabRoomManageRecord = {}

    local cmd_table = ExternalFun.read_netdata(cmd_pri_login.CMD_MB_PersonalRoomForOwner, pData)
    dump(cmd_table, "onSubRoomManagementList")
    local listinfo = cmd_table.PersonalRoomForOwner[1]

    for i = 1, define_private.MAX_CREATE_PERSONAL_ROOM do
        local info = listinfo[i]
        if info.szRoomID ~= "" then
            table.insert(PriRoom:getInstance().m_tabRoomManageRecord, info)
        else
            break
        end
    end

    if nil ~= self._callBack then
        self._callBack(LOGINSERVER(cmd_pri_login.SUB_MB_PERSONAL_ROOM_OWNER_RESULT))
    end
end

-- 房间创建列表
function PriFrame:onSubPrivateRoomList( pData )
    cclog("function PriFrame:onSubPrivateRoomList( pData )==>")

    PriRoom:getInstance().m_tabCreateRecord = {}

    local cmd_table = ExternalFun.read_netdata(cmd_pri_login.CMD_MB_PersonalRoomInfoList, pData)
    local listinfo = cmd_table.PersonalRoomInfo[1]
    cclog("function PriFrame:onSubPrivateRoomList( pData )==>" .. json.encode(listinfo))
    for i = 1, define_private.MAX_CREATE_SHOW_ROOM do
        local info = listinfo[i]
        if info.szRoomID ~= "" then
            info.lScore = info.lTaxCount--self:getMyReword(info.PersonalUserScoreInfo[1])
            -- 时间戳
            local tt = info.sysDissumeTime
            info.sortTimeStmp = os.time({day=tt.wDay, month=tt.wMonth, year=tt.wYear, hour=tt.wHour, min=tt.wMinute, sec=tt.wSecond})
            tt = info.sysCreateTime
            info.createTimeStmp = os.time({day=tt.wDay, month=tt.wMonth, year=tt.wYear, hour=tt.wHour, min=tt.wMinute, sec=tt.wSecond})
            table.insert(PriRoom:getInstance().m_tabCreateRecord, info)
        else
            break
        end
    end
    --排序创建房间数据
    table.sort( PriRoom:getInstance().m_tabCreateRecord, function(a, b)
        if a.cbIsDisssumRoom ~= b.cbIsDisssumRoom then
            return a.cbIsDisssumRoom > b.cbIsDisssumRoom
        elseif a.cbIsDisssumRoom == 0 and a.cbIsDisssumRoom == b.cbIsDisssumRoom then
            return a.createTimeStmp < b.createTimeStmp
        else
            return a.sortTimeStmp < b.sortTimeStmp
        end        
    end )
    if nil ~= self._callBack then
        self._callBack(LOGINSERVER(cmd_pri_login.SUB_MB_QUERY_PERSONAL_ROOM_LIST_RESULT))
    end
end

function PriFrame:getMyReword( list )

    cclog("function PriFrame:getMyReword( list )==>")

    if type(list) ~= "table" then
        return 0
    end
    for k,v in pairs(list) do
        if v["dwUserID"] == GlobalUserItem.dwUserID then
            return (tonumber(v.lScore) or 0)
        end
    end
    return 0
end

-- 私人房费用配置
function PriFrame:onSubFeeParameter( pData )
    cclog("function PriFrame:onSubFeeParameter( pData )==>")

    PriRoom:getInstance().m_tabFeeConfigList = {}
    local len = pData:getlen()
    local count = math.floor(len/define_private.LEN_PERSONAL_TABLE_PARAMETER)
    for idx = 1, count do
        local param = ExternalFun.read_netdata( struct_private.tagPersonalTableParameter, pData )
        table.insert(PriRoom:getInstance().m_tabFeeConfigList, param)
    end
    table.sort( PriRoom:getInstance().m_tabFeeConfigList, function(a, b)
        return a.dwDrawCountLimit < b.dwDrawCountLimit
    end )
    dump(PriRoom:getInstance().m_tabFeeConfigList, "SUB_MB_PERSONAL_FEE_PARAMETER", 6)
    if nil ~= self._callBack then
        self._callBack(LOGINSERVER(cmd_pri_login.SUB_MB_PERSONAL_FEE_PARAMETER))
    end
end

-- 创建结果
function PriFrame:onSubGameServerResult( pData )
    cclog("function PriFrame:onSubGameServerResult( pData )==>")

    local cmd_table = ExternalFun.read_netdata( cmd_pri_login.CMD_MB_QueryGameServerResult, pData )
    dump(cmd_table, "CMD_MB_QueryGameServerResult", 6)
    local tips = cmd_table.szErrDescrybe

    if false == cmd_table.bCanCreateRoom then
        if nil ~= self._callBack and type(tips) == "string" then
            self._callBack(LOGINSERVER(-1), tips)
        end
        return true
    end
    if 0 == cmd_table.dwServerID and true == cmd_table.bCanCreateRoom then
        if nil ~= self._callBack and type(tips) == "string" then
            self._callBack(LOGINSERVER(-1), tips)
        end
        return true
    end    
    -- 发送登陆
    PriRoom:getInstance():onLoginRoom(cmd_table.dwServerID)
    return false
end

-- 房卡兑换游戏币结果
function PriFrame:onSubExchangeRoomCardResult( pData )
    cclog("function PriFrame:onSubExchangeRoomCardResult( pData )==>")

    local cmd_table = ExternalFun.read_netdata( cmd_pri_login.CMD_GP_ExchangeRoomCardResult, pData )
    dump(cmd_table, "CMD_GP_ExchangeRoomCardResult", 6)
    if true == cmd_table.bSuccessed then
        -- 个人财富
        GlobalUserItem.lUserScore = cmd_table.lCurrScore
        GlobalUserItem.lRoomCard = cmd_table.lRoomCard
        -- 通知更新        
        local eventListener = cc.EventCustom:new(yl.RY_USERINFO_NOTIFY)
        eventListener.obj = yl.RY_MSG_USERWEALTH
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(eventListener)
    end

    if nil ~= self._callBack then
        self._callBack(LOGINSERVER(cmd_pri_login.CMD_GP_ExchangeRoomCardResult), cmd_table.szNotifyContent)
    end
end

--网络消息(长连接)
function PriFrame:onGameSocketEvent( main,sub,pData )
    cclog("function PriFrame:onGameSocketEvent( main,sub,pData )==>" .. main .. "=sub: " .. sub)
    if cmd_pri_game.MDM_GR_PERSONAL_TABLE == main then --210
        if cmd_pri_game.SUB_GR_CREATE_SUCCESS == sub then               -- 创建成功 --2
            self:onSubCreateSuccess(pData)
        elseif cmd_pri_game.SUB_GR_CREATE_FAILURE == sub then           -- 创建失败 --3
            self:onSubCreateFailure(pData)
        elseif cmd_pri_game.SUB_GR_CANCEL_TABLE == sub then             -- 解散桌子
            self:onSubTableCancel(pData)
        elseif cmd_pri_game.SUB_GR_CANCEL_REQUEST == sub then           -- 请求解散
            self:onSubCancelRequest(pData)
        elseif cmd_pri_game.SUB_GR_REQUEST_REPLY == sub then            -- 请求答复
            self:onSubRequestReply(pData)
        elseif cmd_pri_game.SUB_GR_REQUEST_RESULT == sub then           -- 请求结果
            self:onSubReplyResult(pData)
        elseif cmd_pri_game.SUB_GR_WAIT_OVER_TIME == sub then           -- 超时等待
            self:onSubWaitOverTime(pData)
        elseif cmd_pri_game.SUB_GR_PERSONAL_TABLE_TIP == sub then       -- 提示信息/游戏信息
            self:onSubTableTip(pData)
        elseif cmd_pri_game.SUB_GR_PERSONAL_TABLE_END == sub then       -- 结束
            self:onSubTableEnd(pData)
        elseif cmd_pri_game.SUB_GR_CANCEL_TABLE_RESULT == sub then      -- 私人房解散结果
            self:onSubCancelTableResult(pData)
        elseif cmd_pri_game.SUB_GR_CURRECE_ROOMCARD_AND_BEAN == sub then -- 强制解散桌子后的游戏豆和房卡数量
            self:onSubCancelTableScoreInfo(pData)
        elseif cmd_pri_game.SUB_GR_CHANGE_CHAIR_COUNT == sub then       -- 改变椅子数量
            self:onSubChangeChairCount(pData)
        elseif cmd_pri_game.SUB_GF_PERSONAL_MESSAGE == sub then         -- 私人房消息
            local cmd_table = ExternalFun.read_netdata(cmd_pri_game.Personal_Room_Message, pData)
            if nil ~= self._callBack then
                self._callBack(GAMESERVER(-1), cmd_table.szMessage)
            end
            if self._gameFrame:isSocketServer() then
                self._gameFrame:onCloseSocket()
                GlobalUserItem.nCurRoomIndex = -1
            end
        end
    end
end

-- 创建成功
function PriFrame:onSubCreateSuccess( pData )
    cclog("function PriFrame:onSubCreateSuccess( pData )==>")
    local cmd_table = ExternalFun.read_netdata(cmd_pri_game.CMD_GR_CreateSuccess, pData)
    -- 更新私人房数据
    PriRoom:getInstance().m_tabPriData.dwDrawTimeLimit = cmd_table.dwDrawTimeLimit
    PriRoom:getInstance().m_tabPriData.dwDrawCountLimit = cmd_table.dwDrawCountLimit
    PriRoom:getInstance().m_tabPriData.szServerID = cmd_table.szServerID
    -- 个人财富
    GlobalUserItem.dUserBeans = cmd_table.dBeans
    GlobalUserItem.lRoomCard = cmd_table.lRoomCard
    -- 通知更新        
    local eventListener = cc.EventCustom:new(yl.RY_USERINFO_NOTIFY)
    eventListener.obj = yl.RY_MSG_USERWEALTH
    cc.Director:getInstance():getEventDispatcher():dispatchEvent(eventListener)
    -- 
    if nil ~= self._callBack then
        self._callBack(GAMESERVER(cmd_pri_game.SUB_GR_CREATE_SUCCESS))
    end
    if 0 == PriRoom:getInstance().m_tabRoomOption.cbIsJoinGame then
        if self._gameFrame:isSocketServer() then
            self._gameFrame:onCloseSocket()
        end
    else
        PriRoom:getInstance().m_nLoginAction = PriRoom.L_ACTION.ACT_SEARCHROOM
    end
end

-- 创建失败
function PriFrame:onSubCreateFailure( pData )
    cclog("function PriFrame:onSubCreateFailure( pData )==>")

    local cmd_table = ExternalFun.read_netdata(cmd_pri_game.CMD_GR_CreateFailure, pData)
    if nil ~= self._callBack then
        self._callBack(GAMESERVER(-1), cmd_table.szDescribeString)
    end
end

-- 解散桌子
function PriFrame:onSubTableCancel( pData )
    cclog("function PriFrame:onSubTableCancel( pData )==>")
    local cmd_table = ExternalFun.read_netdata(cmd_pri_game.CMD_GR_CancelTable, pData)
    dump(cmd_table, "CMD_GR_CancelTable", 6)

    if nil ~= self._callBack then
        self._callBack(GAMESERVER(cmd_pri_game.SUB_GR_CANCEL_TABLE), cmd_table)
    end
end

-- 请求解散
function PriFrame:onSubCancelRequest( pData )
    cclog("function PriFrame:onSubCancelRequest( pData )==>")
    local cmd_table = ExternalFun.read_netdata(cmd_pri_game.CMD_GR_CancelRequest, pData)
    -- 自己不处理
    if cmd_table.dwUserID == GlobalUserItem.dwUserID then
        cclog("自己请求解散")
        return
    end
    if nil ~= self._callBack then
        self._callBack(GAMESERVER(cmd_pri_game.SUB_GR_CANCEL_REQUEST), cmd_table)
    end
end

-- 请求答复
function PriFrame:onSubRequestReply( pData )
    cclog("function PriFrame:onSubRequestReply( pData )==>")
    local cmd_table = ExternalFun.read_netdata(cmd_pri_game.CMD_GR_RequestReply, pData)
    if nil ~= self._callBack then
        self._callBack(GAMESERVER(cmd_pri_game.SUB_GR_REQUEST_REPLY), cmd_table)
    end
end

-- 请求结果
function PriFrame:onSubReplyResult( pData )
    cclog("function PriFrame:onSubReplyResult( pData )==>")
    local cmd_table = ExternalFun.read_netdata(cmd_pri_game.CMD_GR_RequestResult, pData)
    if nil ~= self._callBack then
        self._callBack(GAMESERVER(cmd_pri_game.SUB_GR_REQUEST_RESULT), cmd_table)
    end
end

-- 超时等待
function PriFrame:onSubWaitOverTime( pData )
    cclog("function PriFrame:onSubWaitOverTime( pData )==>")
    local cmd_table = ExternalFun.read_netdata(cmd_pri_game.CMD_GR_WaitOverTime, pData)
    if nil ~= self._callBack then
        self._callBack(GAMESERVER(cmd_pri_game.SUB_GR_WAIT_OVER_TIME), cmd_table)
    end
end

-- 提示信息
function PriFrame:onSubTableTip( pData )
    cclog("function PriFrame:onSubTableTip( pData )==>")
    local cmd_table = ExternalFun.read_netdata(cmd_pri_game.CMD_GR_PersonalTableTip, pData)
    PriRoom:getInstance().m_tabPriData = cmd_table
    PriRoom:getInstance().m_bIsMyRoomOwner = (cmd_table.dwTableOwnerUserID == GlobalUserItem.dwUserID)
    if nil ~= self._callBack then
        self._callBack(GAMESERVER(cmd_pri_game.SUB_GR_PERSONAL_TABLE_TIP), cmd_table)
    end
    dump(PriRoom:getInstance().m_tabPriData, "PriRoom:getInstance().m_tabPriData", 6)
end

-- 结束消息
function PriFrame:onSubTableEnd( pData )
    cclog("function PriFrame:onSubTableEnd( pData )==>")

    local cmd_table = ExternalFun.read_netdata(cmd_pri_game.CMD_GR_PersonalTableEnd, pData)
    if nil ~= self._callBack then
        self._callBack(GAMESERVER(cmd_pri_game.SUB_GR_PERSONAL_TABLE_END), cmd_table, pData)
    end
end

-- 私人房解散结果
function PriFrame:onSubCancelTableResult( pData )
    cclog("function PriFrame:onSubCancelTableResult( pData )==>")
    local cmd_table = ExternalFun.read_netdata(cmd_pri_game.CMD_GR_DissumeTable, pData)
    if nil ~= self._callBack then
        self._callBack(GAMESERVER(cmd_pri_game.SUB_GR_CANCEL_TABLE_RESULT), cmd_table)
    end
    if self._gameFrame:isSocketServer() then
        self._gameFrame:onCloseSocket()
    end
end

-- 解散后财富信息
function PriFrame:onSubCancelTableScoreInfo( pData )
    cclog("function PriFrame:onSubCancelTableScoreInfo( pData )==>")
    local cmd_table = ExternalFun.read_netdata(cmd_pri_game.CMD_GR_CurrenceRoomCardAndBeans, pData)
    -- 个人财富
    GlobalUserItem.dUserBeans = cmd_table.dbBeans
    GlobalUserItem.lRoomCard = cmd_table.lRoomCard
    -- 通知更新        
    local eventListener = cc.EventCustom:new(yl.RY_USERINFO_NOTIFY)
    eventListener.obj = yl.RY_MSG_USERWEALTH
    cc.Director:getInstance():getEventDispatcher():dispatchEvent(eventListener)

    if nil ~= self._callBack then
        self._callBack(GAMESERVER(cmd_pri_game.SUB_GR_CURRECE_ROOMCARD_AND_BEAN), cmd_table)
    end
end

-- 改变椅子数量
function PriFrame:onSubChangeChairCount( pData )
    cclog("function PriFrame:onSubChangeChairCount( pData )==>")
    local cmd_table = ExternalFun.read_netdata(cmd_pri_game.CMD_GR_ChangeChairCount, pData)
    if nil ~= cmd_table.dwChairCount then
        self._gameFrame._wChairCount = cmd_table.dwChairCount
    end
end


return PriFrame