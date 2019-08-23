-- Name: roomrecordLayer
-- Func: 我的房间
-- Author: Johny

local ClassName = "roomrecordLayer"
local roomrecordLayer = class(ClassName, cc.Layer)
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local ClipText = appdf.req(appdf.EXTERNAL_SRC .. "ClipText")
local RoomDetailLayer = appdf.req(PriRoom.MODULE.PLAZAMODULE .. "views.RoomDetailLayer")
local cmd_private = appdf.req(PriRoom.MODULE.PRIHEADER .. "CMD_Private")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")
local PopupInfoHead = appdf.req(appdf.EXTERNAL_SRC .. "PopupInfoHead")

local ROOMDETAIL_NAME = "__pri_room_detail_layer_name__"


function roomrecordLayer:createTableView(content)
    -- 列表
    local m_tableView = cc.TableView:create(content:getContentSize())
    m_tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    m_tableView:setPosition(content:getPosition())
    m_tableView:setDelegate()
    m_tableView:registerScriptHandler(handler(self, self.cellSizeForTable), cc.TABLECELL_SIZE_FOR_INDEX)
    m_tableView:registerScriptHandler(handler(self, self.tableCellAtIndex), cc.TABLECELL_SIZE_AT_INDEX)
    m_tableView:registerScriptHandler(handler(self, self.numberOfCellsInTableView), cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    content:getParent():addChild(m_tableView)
    self.m_tableView = m_tableView
end

function roomrecordLayer:ctor( scene )
    cclog("function roomrecordLayer:ctor( scene ) ==>")

    ExternalFun.registerNodeEvent(self)

    self.scene = scene
    -- 加载csb资源
    local rootLayer, csbNode = ExternalFun.loadRootCSB("roomrecord/RecordLayer.csb", self)
    local img_bg = csbNode:getChildByName("img_bg")

    local cbtlistener = function (sender,eventType)
        self:onSelectedEvent(sender:getTag(),sender,eventType)
    end

    --close
    local btn_close = img_bg:getChildByName("btn_close")
    btn_close:addTouchEventListener(function(ref, tType)
           if tType == ccui.TouchEventType.ended then
               self:removeFromParent()
           end
    end)

    -- 切换按钮
    self.m_checkSwitch = img_bg:getChildByName("check_switchrec")
    self.m_checkSwitch:setSelected(true)
    self.m_checkSwitch:addEventListener(cbtlistener)

    -- content
    self.mContent = img_bg:getChildByName("lay_content")
    self:createTableView(self.mContent)

    --注册回调
    FriendMgr:getInstance():registerRoomManagementPlayerStatusCallBack(ClassName, handler(self, self.onCallBackRoomManagementPlayerStatus))
end

function roomrecordLayer:onSelectedEvent( tag,sender,eventType )
    cclog("function roomrecordLayer:onSelectedEvent( tag,sender,eventType ) ==>")
    local sel = sender:isSelected()
    if not sel then
        --请求房间创建列表
        PriRoom:getInstance():showPopWait()
        PriRoom:getInstance():getNetFrame():onQueryRoomList()
    end
    self.m_tableView:reloadData()
end

function roomrecordLayer:onEnterTransitionFinish()
    cclog("function roomrecordLayer:onEnterTransitionFinish()==>")
    -- 请求房间管理列表
    PriRoom:getInstance():showPopWait()
    PriRoom:getInstance():getNetFrame():onQueryRoomManagementList()
end

function roomrecordLayer:onExit()
    cclog("roomrecordLayer:onExit()==>")
    -- 清除缓存
    PriRoom:getInstance().m_tabJoinRecord = {}
    PriRoom:getInstance().m_tabCreateRecord = {}
    PriRoom:getInstance().m_tabRoomManageRecord = {}

    --解注册回调
    FriendMgr:getInstance():unregisterRoomManagementPlayerStatusCallBack(ClassName, handler(self, self.onCallBackRoomManagementPlayerStatus))
end

function roomrecordLayer:onReloadRecordList()
    cclog("function roomrecordLayer:onReloadRecordList()==>")
    self.m_tableView:reloadData()
end

function roomrecordLayer:cellSizeForTable( view, idx )
    if self.m_checkSwitch:isSelected() then
        return 1240, 140
    else
        return 1240, 140
    end
end

function roomrecordLayer:numberOfCellsInTableView( view )
    cclog("function roomrecordLayer:numberOfCellsInTableView( view )==>")
    if self.m_checkSwitch:isSelected() then
        return #(PriRoom:getInstance().m_tabRoomManageRecord)
    else
        return #(PriRoom:getInstance().m_tabCreateRecord)
    end
end

function roomrecordLayer:tableCellAtIndex( view, idx )
    cclog("function roomrecordLayer:tableCellAtIndex( view, idx )==>")
    local cell = view:dequeueCell()
    if not cell then        
        cell = cc.TableViewCell:new()
    else
        cell:removeAllChildren()
    end

    if self.m_checkSwitch:isSelected() then
        local tabData = PriRoom:getInstance().m_tabRoomManageRecord[idx + 1]
        local item = self:manageRecordItem(tabData)
        item:setPosition(view:getViewSize().width * 0.5 - 50, 25)
        cell:addChild(item)
    else
        local tabData = PriRoom:getInstance().m_tabCreateRecord[idx + 1]
        local item = self:createRecordItem(tabData)
        item:setPosition(view:getViewSize().width * 0.5 - 50, 0)
        cell:addChild(item)
    end

    return cell
end

--房间管理
function roomrecordLayer:manageRecordItem(tabData)
    cclog("function roomrecordLayer:manageRecordItem( tabData )==>" .. json.encode(tabData))
    local function invite()
        local target = yl.ThirdParty.WECHAT
        local url = "none"
        local function sharecall( isok )
            if type(isok) == "string" and isok == "true" then
                --showToast(self, "分享成功", 2)
            end
        end
        local msgTab = PriRoom:getInstance():getInviteShareMsg(tabData)
        cclog("RoomCreateResult:onButtonClickedEvent===>" .. msgTab.content)
        MultiPlatform:getInstance():shareToTarget(target, sharecall, msgTab.title, msgTab.content, url)
    end
    local function dismiss()
        PriRoom:getInstance():showPopWait()
        PriRoom:getInstance():getNetFrame():onDissumeRoom(tabData.szRoomID)
    end
    local function getRules()
        local cmd_rules = tabData.cbGameRule[1]
        local str_rules = ""
        if GlobalUserItem.nCurGameKind == yl.KINDID_HONGZHONG then
           str_rules = string.format("创建消耗：%d  人数：%d  码数：%d  局数：%d",cmd_rules[1],cmd_rules[2],cmd_rules[3],cmd_rules[4])
        elseif GlobalUserItem.nCurGameKind == yl.KINDID_LAND then
            str_rules = string.format("创建消耗：%d  底分：%d  局数：%d",cmd_rules[1],cmd_rules[2],cmd_rules[3])
        elseif GlobalUserItem.nCurGameKind == yl.KINDID_NIUNIU then
            local mode = yl.getOxnewModeByID(tostring(cmd_rules[3]))
            str_rules = string.format("创建消耗：%d  人数：%d  局数：%d  坐庄模式：%s",cmd_rules[1],cmd_rules[2],cmd_rules[4], mode)
        elseif GlobalUserItem.nCurGameKind == yl.KINDID_ZHAJINHUA then
            str_rules = string.format("创建消耗：%d  人数：%d  局数：%d", cmd_rules[1], cmd_rules[2], cmd_rules[3])
        elseif GlobalUserItem.nCurGameKind == yl.KINDID_LONGCHENG then
            local cost = cmd_rules[6]
            local playercnt = cmd_rules[2]
            local macnt = cmd_rules[11]
            local maxplaycnt = cmd_rules[4]
            local diaoyuType = cmd_rules[12] == 1 and "159钓鱼" or "跟庄钓鱼"
            local isMenQing = cmd_rules[13] == 1 and "是" or "否"
            local maxDefen = cmd_rules[14] == 1 and "6子封顶" or "无限翻"
            str_rules = string.format("创建消耗：%d  人数：%d  码数：%d  局数：%d  钓鱼类型：%s  门清：%s  最大得分：%s", 
                cost, playercnt, macnt, maxplaycnt, diaoyuType, isMenQing, maxDefen)
        end
        return str_rules
    end
    --layout
    local item = ccui.Widget:create()
    item:setContentSize(cc.size(1130, 140))
    --
    local csbNode = ExternalFun.loadCSB("roomrecord/RecordRoomManageCell.csb", item)
    csbNode:setPosition(cc.p(0.0, 30.0))
    local lb_rules = csbNode:getChildByName("lb_rules")
    local lb_roomid = csbNode:getChildByName("lb_roomid")
    lb_roomid:setString(tabData.szRoomID)
    lb_rules:setString(getRules())
    --btn invite
    local btn_invite = csbNode:getChildByName("btn_invite")
    btn_invite:addTouchEventListener(function(ref, tType)
            if tType == ccui.TouchEventType.ended then
               invite()
            end
        end)
    --btn dismiss
    local btn_dismiss = csbNode:getChildByName("btn_dismiss")
    btn_dismiss:addTouchEventListener(function (ref, tType)
            if tType == ccui.TouchEventType.ended then
               dismiss()
            end
        end)

    --players
    local uinfos = tabData.PersonalRoomUserInfo[1]
    for i = 1,#uinfos do
        --限制玩家数显示
        if i > 5 then
        break end
        --
        local uinfo = uinfos[i]
        if uinfo.dwUserID > 0 then
           local at = csbNode:getChildByName("at_" .. i)
           local lb_name = csbNode:getChildByName("lb_name_" .. i)
           lb_name:setString(uinfo.szNickName)
           lb_name:setVisible(true)
           local useritem = {}
           useritem.dwUserID = uinfo.dwUserID
           useritem.dwCustomID = uinfo.dwCustomID
           useritem.wFaceID = uinfo.wFaceID
           local head = PopupInfoHead:createNormal(useritem, 60)
           head:addTo(at)
           at:setVisible(true)
        else
            break
        end
    end


    
    return item
end

-- 创建记录
function roomrecordLayer:createRecordItem( tabData )
    cclog("function roomrecordLayer:createRecordItem( tabData )==>" .. json.encode(tabData))
    --layout
    local item = ccui.Widget:create()
    item:setContentSize(cc.size(1130, 140))
    
    local csbNode = ExternalFun.loadCSB("roomrecord/RecordRoomCreateCell.csb", item)
    csbNode:setPosition(cc.p(0.0, 50.0))
    local lb_rules = csbNode:getChildByName("lb_rules")
    local lb_roomid = csbNode:getChildByName("lb_roomid")
    lb_roomid:setString(tabData.szRoomID)
    --创建时间
    local tabTime = tabData.sysCreateTime
    local strTime1 = string.format("%d-%02d-%02d %02d:%02d:%02d", tabTime.wYear, tabTime.wMonth, tabTime.wDay, tabTime.wHour, tabTime.wMinute, tabTime.wSecond)
    --解散时间
    local strTime2 = ""
    --消耗
    local feeType = "房卡"
    if tabData.cbCardOrBean == 0 then
        feeType = "游戏豆"
    end
    if tabData.cbIsDisssumRoom == 1 then
        tabTime = tabData.sysDissumeTime
        strTime2 = string.format("%d-%02d-%02d %02d:%02d:%02d", tabTime.wYear, tabTime.wMonth, tabTime.wDay, tabTime.wHour, tabTime.wMinute, tabTime.wSecond)
    end    
    --rules
    local rules = string.format("创建时间：%s    解散时间：%s    创建消耗：%d%s    奖励：%d游戏币", strTime1, strTime2, tabData.lFeeCardOrBeanCount, feeType, tabData.lScore)
    lb_rules:setString(rules)
    --players
    local uinfos = tabData.PersonalUserScoreInfo[1]
    for i = 1,#uinfos do
        --限制玩家数显示
        if i > 5 then
        break end
        --
        local uinfo = uinfos[i]
        if uinfo.dwUserID > 0 then
            local at = csbNode:getChildByName("at_" .. i)
            local lb_name = csbNode:getChildByName("lb_name_" .. i)
            local lb_score = csbNode:getChildByName("lb_score_" .. i)
            --name
            lb_name:setString(uinfo.szUserNicname)
            lb_name:setVisible(true)
            --head
            local useritem = {}
            useritem.dwUserID = uinfo.dwUserID
            useritem.dwCustomID = uinfo.dwCustomID
            useritem.wFaceID = uinfo.wFaceID
            local head = PopupInfoHead:createNormal(useritem, 60)
            head:addTo(at)
            at:setVisible(true)
            --score
            local score = uinfo.lScore
            if score >= 0 then
                lb_score:setString("+" .. score)
                lb_score:setTextColor(cc.c4b(0, 255, 0, 255))
            else
                lb_score:setString(score)
                lb_score:setTextColor(cc.c4b(255, 255, 255, 255))
            end
            lb_score:setVisible(true)
        else
            break
        end
    end

    return item
end


-----------------------------------来自聊天服务器回调-----------------------------
--房间管理列表玩家状态回调(增加被动解散房间回调)
function roomrecordLayer:onCallBackRoomManagementPlayerStatus(type, cmd_table)
    cclog("function roomrecordLayer:onCallBackRoomManagementPlayerStatus(cmd_table)==>")
    -- doAssert(json.encode(cmd_table))
    --更新玩家状态
    local function updatePlayerStatus()
        local tabData = nil
        for i = 1, #PriRoom:getInstance().m_tabRoomManageRecord do
            tabData = PriRoom:getInstance().m_tabRoomManageRecord[i]
            if tabData.szRoomID == cmd_table.szRoomID then
            break end
        end
        if tabData ~= nil then
            for i = 1, #tabData.PersonalRoomUserInfo[1] do
               if cmd_table.cbGameStatus > 0 then
                  if tabData.PersonalRoomUserInfo[1][i].dwUserID == cmd_table.dwUserID then --此人已存在
                  break end
                  if tabData.PersonalRoomUserInfo[1][i].dwUserID == 0 then
                      --添加一个人
                      tabData.PersonalRoomUserInfo[1][i].dwUserID = cmd_table.dwUserID
                      tabData.PersonalRoomUserInfo[1][i].szNickName = cmd_table.szNickName
                      tabData.PersonalRoomUserInfo[1][i].wFaceID = cmd_table.wFaceID
                      tabData.PersonalRoomUserInfo[1][i].dwCustomID = cmd_table.dwCustomID
                  break end
               else
                  if tabData.PersonalRoomUserInfo[1][i].dwUserID == cmd_table.dwUserID then
                      --移除这个人
                      tabData.PersonalRoomUserInfo[1][i].dwUserID = 0
                  break end
               end
            end
            self:onReloadRecordList()
        else
           doAssert("[roomrecordLayer]can not find roomid: " .. cmd_table.szRoomID)
        end
    end
    --被动解散
    local function dismissRoom()
        local szRoomID = cmd_table.szRoomID
        --更新房间管理记录
        for i = 1, #PriRoom:getInstance().m_tabRoomManageRecord do
            if szRoomID == PriRoom:getInstance().m_tabRoomManageRecord[i].szRoomID then
                table.remove(PriRoom:getInstance().m_tabRoomManageRecord, i)
                break
            end
        end
        self:onReloadRecordList()
    end
    if type == 1 then
        updatePlayerStatus()
    else
        dismissRoom()
    end
    
end


return roomrecordLayer