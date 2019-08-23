--@NEW
-- Name: PriRoomListLayer
-- Func: 有私房模式的列表 or  好友界面
-- Author: Johny

local PriRoomListLayer = class("PriRoomListLayer", cc.Layer)


local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local PopupInfoHead = appdf.req(appdf.EXTERNAL_SRC .. "PopupInfoHead")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")
local chat_cmd = appdf.req(appdf.HEADER_SRC.."CMD_ChatServer")
local ClipText = appdf.req(appdf.EXTERNAL_SRC .. "ClipText")
local NotifyMgr = appdf.req(appdf.EXTERNAL_SRC .. "NotifyMgr")
local FriendChatList = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.friend.FriendChatList")

-------------------------------常量定义-----------------------------------
--@Type
PriRoomListLayer.TYPE_PRIROOM   =  1001
PriRoomListLayer.TYPE_FRIEND    =  1002


--@邀请文字
local INVITE_BOOK_TITLE    = "好友分享"
local INVITE_BOOK_TEXT     = "亲爱的好友，我最近玩了一款超好玩的游戏，玩法超级多，内容超级精彩，快来加入我，和我一起精彩游戏吧！下载地址："
local INVITE_WECHAT_TITLE  = "有人@你一起玩游戏！"
local INVITE_WECHAT_TEXT   = "你的好友正在玩游戏！玩法超多超精彩！快来打败他！"


--@按钮-私房
local BTN_NORMAL_ROOMLIST   = 101               -- 普通房间列表
local BTN_JOIN_PRIROOM      = 102               -- 加入房间
local BTN_CREATE_PRIROOM    = 103               -- 创建房间
local BTN_MY_ROOM           = 104               -- 我的房间
--标签
local BTN_FRIEND_LIST       = 201
local BTN_FRIEND_ADD        = 202
local BTN_FRIEND_NOTICE     = 203
--@按钮-friend
local BTN_FRIEND_ADD_SEARCH        = 301
local BTN_FRIEND_ADD_INVITEBOOK    = 302
local BTN_FRIEND_ADD_INVITEWECHAT  = 303






function PriRoomListLayer:onEnterTransitionFinish()
    cclog("PriRoomListLayer:onEnterTransitionFinish")

    --判断好友系统网络状态
    if false == FriendMgr:getInstance():isConnected() then
        FriendMgr:getInstance():reSetAndLogin()
    end
    self:initFriendListener()

    --激活通知
    NotifyMgr:getInstance():resumeNotify(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_USER_CHAT_NOTIFY, "friend_chat")
    NotifyMgr:getInstance():resumeNotify(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_APPLYFOR_NOTIFY, "friend_apply")
    NotifyMgr:getInstance():resumeNotify(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_RESPOND_NOTIFY, "friend_response")
    NotifyMgr:getInstance():resumeNotify(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_INVITE_GAME_NOTIFY, "friend_invite")
    NotifyMgr:getInstance():resumeNotify(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_USER_SHARE_NOTIFY, "friend_share")
    NotifyMgr:getInstance():resumeNotify(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_INVITE_PERSONAL_NOTIFY, "pri_friend_invite")
    --处理通知
    NotifyMgr:getInstance():excuteSleepNotfiy()

    --消息红点
    self:updateNoticeHint()
end

-- 退出场景而且开始过渡动画时候触发。
function PriRoomListLayer:onExitTransitionStart()
    cclog("function PriRoomListLayer:onExitTransitionStart() ==>")

    --暂停通知
    NotifyMgr:getInstance():pauseNotify(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_USER_CHAT_NOTIFY, "friend_chat")
    NotifyMgr:getInstance():pauseNotify(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_APPLYFOR_NOTIFY, "friend_apply")
    NotifyMgr:getInstance():pauseNotify(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_RESPOND_NOTIFY, "friend_response")
    NotifyMgr:getInstance():pauseNotify(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_INVITE_GAME_NOTIFY, "friend_invite")
    NotifyMgr:getInstance():pauseNotify(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_USER_SHARE_NOTIFY, "friend_share")
    NotifyMgr:getInstance():pauseNotify(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_INVITE_PERSONAL_NOTIFYpri_friend_invite, "pri_friend_invite")


    FriendMgr:getInstance():setViewLayer(nil)

    self:removeFriendListener()

    return self
end
----------------------------------Notice----------------------------
function PriRoomListLayer:initFriendListener()
    cclog("function PriRoomListLayer:initFriendListener() ==>")

    self.m_listener = cc.EventListenerCustom:create(yl.RY_FRIEND_NOTIFY,handler(self, self.onFriendInfo))
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(self.m_listener, self)

    local function eventCustomListener(event)
        if nil ~= event.filename and 0 == event.code then
            if type(event.filename) == "string" and cc.FileUtils:getInstance():isFileExist(event.filenam) then
                cclog("刷新图片")
                if nil ~= self.m_chatListManager and nil ~= self.m_chatListManager.messageNotify then
                    self.m_chatListManager:messageNotify()
                end
            end
        end
    end
    self.m_downListener = cc.EventListenerCustom:create(yl.RY_IMAGE_DOWNLOAD_NOTIFY, eventCustomListener)
    self:getEventDispatcher():addEventListenerWithFixedPriority(self.m_downListener, 1)
end

function PriRoomListLayer:removeFriendListener()
    cclog("function PriRoomListLayer:removeFriendListener() ==>")

    if nil ~= self.m_listener then
        cc.Director:getInstance():getEventDispatcher():removeEventListener(self.m_listener)
        self.m_listener = nil
    end

    if nil ~= self.m_downListener then
        self:getEventDispatcher():removeEventListener(self.m_downListener)
        self.m_downListener = nil
    end
end
----------------------------------Notice----------------------------

function PriRoomListLayer:ctor(scene, type)
    cclog("function PriRoomListLayer:ctor( scene )==>")

    self:registerScriptHandler(function(eventType)
        if eventType == "enterTransitionFinish" then  -- 进入场景而且过渡动画结束时候触发。
            self:onEnterTransitionFinish()
        elseif eventType == "exitTransitionStart" then  -- 退出场景而且开始过渡动画时候触发。
            self:onExitTransitionStart()
        end
    end)


    ExternalFun.registerNodeEvent(self)
    GlobalUserItem.nCurRoomIndex = -1
    FriendMgr:getInstance():setViewLayer(self)


    if type == nil then type = PriRoomListLayer.TYPE_PRIROOM end
    self._type = type
    self._scene = scene
    self._inviteList = {}
    self:layoutUI()
    self:defaultFriendSetting()

     -- 请求私人房配置
    if self._type == PriRoomListLayer.TYPE_PRIROOM then
        self._scene:showPopWait()
        PriRoom:getInstance():getNetFrame():onGetRoomParameter()
    end
end

function PriRoomListLayer:createFriendList()
    self.mFriendList = FriendMgr:getInstance():getFriendList()
    local list_bg_size = self.img_list:getContentSize()
    local tableView = cc.TableView:create(cc.size(list_bg_size.width, list_bg_size.height));
    tableView:setName("friendlist")
    tableView:setColor(cc.c3b(158, 200, 200))
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    tableView:setPosition(0,0);
    self.mFriendListTable = tableView

    tableView:setDelegate()
    self.img_list:addChild(tableView)

    -- tableView:registerScriptHandler(handler(self,self.tableCellTouched),cc.TABLECELL_TOUCHED)
    tableView:registerScriptHandler(handler(self,self.cellSizeForTable),cc.TABLECELL_SIZE_FOR_INDEX)
    tableView:registerScriptHandler(handler(self,self.tableCellAtIndex),cc.TABLECELL_SIZE_AT_INDEX)
    tableView:registerScriptHandler(handler(self,self.numberOfCellsInTableView),cc.NUMBER_OF_CELLS_IN_TABLEVIEW);
end

function PriRoomListLayer:createFriendSearch()
    local touchFunC = function(ref, tType)
        if tType == ccui.TouchEventType.ended then
            self:onButtonClickedEvent(ref:getTag(), ref)            
        end
    end
    local btn_search = self.panel_add:getChildByName("btn_search")
    btn_search:addTouchEventListener(touchFunC)
    btn_search:setTag(BTN_FRIEND_ADD_SEARCH)

    local btn_book = self.panel_add:getChildByName("btn_book")
    btn_book:addTouchEventListener(touchFunC)
    btn_book:setTag(BTN_FRIEND_ADD_INVITEBOOK)

    local btn_wechat = self.panel_add:getChildByName("btn_wechat")
    btn_wechat:addTouchEventListener(touchFunC)
    btn_wechat:setTag(BTN_FRIEND_ADD_INVITEWECHAT)

    --editbox
    local img_input = appdf.getNodeByName(self.panel_add,"img_input");
    if not appdf.getNodeByName(self.panel_add,"EditBoxSearchIput") then
        local EditID = cc.EditBox:create(img_input:getContentSize(), "");
        EditID:setFontSize(20);
        EditID:setPlaceholderFontSize(20)
        EditID:setFontColor(yl.G_COLOR_INPUT_PLACEHOLDER);
        EditID:setPlaceHolder("请填写对方的游戏ID号:");
        EditID:setFontName("fonts/yuanti_sc_light.ttf")
        EditID:setPlaceholderFontName("fonts/yuanti_sc_light.ttf")
        EditID:setPlaceholderFontColor(yl.G_COLOR_INPUT_PLACEHOLDER);
        EditID:setMaxLength(32);
        EditID:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE);
        EditID:setInputMode(cc.EDITBOX_INPUT_MODE_NUMERIC)
        EditID:setPosition(img_input:getPosition());
        EditID:setName("EditBoxSearchIput");
        self.panel_add:addChild(EditID);
        self.m_editId = EditID
     end
end

--私房布局
function PriRoomListLayer:layoutUI_priroom(csbNode, touchFunC)
    --金币房间
    local btn = csbNode:getChildByName("btn_gold")
    btn:setTag(BTN_NORMAL_ROOMLIST)
    btn:setVisible(true)
    btn:addTouchEventListener(touchFunC)


    -- 加入房间
    btn = csbNode:getChildByName("btn_join")
    btn:setTag(BTN_JOIN_PRIROOM)
    btn:setVisible(true)
    btn:addTouchEventListener(touchFunC)

    -- 创建房间
    btn = csbNode:getChildByName("btn_create")
    btn:setTag(BTN_CREATE_PRIROOM)
    btn:setVisible(true)
    btn:addTouchEventListener(touchFunC)   

    --我的房间
    btn = csbNode:getChildByName("btn_myroom")
    btn:setTag(BTN_MY_ROOM)
    btn:setVisible(true)
    btn:addTouchEventListener(touchFunC) 
end

--好友布局
function PriRoomListLayer:layoutUI_friend(csbNode, touchFunC)
    local img_bg = csbNode:getChildByName("img_bg")

    --friend list
    self.btn_list = img_bg:getChildByName("btn_list")
    self.btn_list:setTag(BTN_FRIEND_LIST)
    self.btn_list:addTouchEventListener(touchFunC)

    --friend add
    self.btn_add = img_bg:getChildByName("btn_add")
    self.btn_add:setTag(BTN_FRIEND_ADD)
    self.btn_add:addTouchEventListener(touchFunC)

    -- friend notice
    self.btn_notice = img_bg:getChildByName("btn_notice")
    self.btn_notice:setTag(BTN_FRIEND_NOTICE)
    self.btn_notice:addTouchEventListener(touchFunC)

    --通知提示红点
    self.notice_hint = self.btn_notice:getChildByName("img_redhint")
    self.notice_hintNum = self.notice_hint:getChildByName("lb_redhint")

    --panel
    self.img_list = img_bg:getChildByName("img_list")
    self.panel_add = img_bg:getChildByName("panel_add")

    self:createFriendList()
    self:createFriendSearch()
end

function PriRoomListLayer:layoutUI()
    local touchFunC = function(ref, tType)
        if tType == ccui.TouchEventType.ended then
            self:onButtonClickedEvent(ref:getTag(), ref)            
        end
    end

    -- 加载csb资源
    local rootLayer, csbNode = ExternalFun.loadRootCSB("roomnew/PriRoomListLayer.csb", self)
    if self._type == PriRoomListLayer.TYPE_PRIROOM then
        self:layoutUI_priroom(csbNode, touchFunC)
    else
        local img_mm = csbNode:getChildByName("img_mm")
        img_mm:setVisible(true)
    end

    --加载好友资源
    self:layoutUI_friend(csbNode, touchFunC)
end

--默认标签设置
function PriRoomListLayer:defaultFriendSetting()
    self.m_chatListManager = nil
    self.m_bIsChatLayer = false
    self.m_nSelect = BTN_FRIEND_LIST
    self:showFriendlist(true)
    self:showAddFriend(false)
end

function PriRoomListLayer:showFriendlist(_show)
    self.btn_list:setEnabled(not _show)
    self.img_list:setVisible(_show)
    self.mFriendListTable:reloadData()
end

function PriRoomListLayer:refreshFriendList()
    self.mFriendListTable:reloadData()
end

function PriRoomListLayer:showAddFriend(_show)
    self.btn_add:setEnabled(not _show)
    self.panel_add:setVisible(_show)
end

--显示下一个消息通知
function PriRoomListLayer:showNextNotice()
    cclog("PriRoomListLayer:showNextNotice===>")
    local notifyTab = FriendMgr:getInstance():getUnReadNotify()
    dump(notifyTab,"==========当前数据==========")
    if #notifyTab < 1 then return end
    local curTab = notifyTab[1]
    local layer, csbNode = ExternalFun.loadRootCSB("roomnew/FriendRequest.csb", self)
    local img_bg = csbNode:getChildByName("img_bg")

    --title
    local title = img_bg:getChildByName("lb_title")
    title:setString(curTab.notify.szNickName .. title:getString())


    local function agreeOrReject(bb)
        local sendTab = {}
        sendTab.dwUserID = GlobalUserItem.dwUserID
        sendTab.dwRequestID = curTab.notify.dwRequestID
        sendTab.bAccepted = bb
        FriendMgr:getInstance():sendRespondFriend(sendTab, curTab.notifyId)    
        csbNode:removeFromParent(true) 
    end

    --reject
    local btn_reject = img_bg:getChildByName("btn_reject")
    btn_reject:addTouchEventListener(function(ref, tType)
        if tType == ccui.TouchEventType.ended then
            agreeOrReject(false)
        end
    end)

    --agree
    local btn_agree = img_bg:getChildByName("btn_agree")
    btn_agree:addTouchEventListener(function(ref, tType)
        if tType == ccui.TouchEventType.ended then
            agreeOrReject(true)
        end
    end)
end

--显示好友详细界面
function PriRoomListLayer:showFriendDetailView(uid)
    cclog("PriRoomListLayer:showFriendDetailView==>uid: " .. uid)
    local userInfoTab = FriendMgr:getInstance():getFriendByID(uid)

    local layer, csbNode = ExternalFun.loadRootCSB("roomnew/FriendDetail.csb", self)
    self.mFriendDetailView = csbNode
    local img_bg = appdf.getNodeByName(csbNode, "img_bg")
    local img_bg2 = img_bg:getChildByName("img_bg2")
    local img_bg3 = img_bg2:getChildByName("img_bg3")
    
    ----
    local touchFunC = function(ref, tType)
        if tType == ccui.TouchEventType.ended then
            local uid = ref:getTag()
            local senderName = ref:getName()
            ---
            if senderName  == "btn_delete" then
                FriendMgr:getInstance():sendDeleteFriend(uid, 0)
            elseif senderName == "btn_give" then
                local param = {}
                param.sendid = userInfoTab.dwGameID
                self._scene:onChangeShowMode(yl.SCENE_BEANGIVE, param)
            end          
            self.mFriendDetailView:removeFromParent()
        end
    end


    --close
    local btn_close = appdf.getNodeByName(csbNode, "btn_close")
    btn_close:addTouchEventListener(touchFunC)

    -- 头像
    local img_frame = img_bg2:getChildByName("img_frame")
    local head = PopupInfoHead:createClipHead(userInfoTab, 80)
    if nil ~= head then
        head:setPosition(img_frame:getPosition())
        :addTo(img_bg2)
        :setName("head")
    end

    -- sign
    local sign = (userInfoTab.szSign == "") and "此人很懒，没有签名" or userInfoTab.szSign
    local lb_sign = img_bg2:getChildByName("lb_sign")
    lb_sign:setString(sign)

    --info
    local lb_name = img_bg3:getChildByName("lb_name")
    lb_name:setString(userInfoTab.szNickName)
    local lb_id = img_bg3:getChildByName("lb_id")
    lb_id:setString(userInfoTab.dwGameID)
    local lb_vip = img_bg3:getChildByName("lb_vip")
    lb_vip:setString(userInfoTab.cbMemberOrder)


    --coin
    local score = userInfoTab.lScore or userInfoTab.lUserScore
    score = score or 0
    str = ExternalFun.numberThousands(score)
    if string.len(str) > 11 then
        str = string.sub(str, 1, 11) .. "..."
    end
    local lb_coin = img_bg3:getChildByName("lb_coin")
    lb_coin:setString(str)

    --bean
    local beans = userInfoTab.dBeans or userInfoTab.dUserBeans
    beans = beans or 0
    str = string.format("%.2f", beans)
    if string.len(str) > 11 then
        str = string.sub(str, 1, 11) .. "..."
    end
    local lb_bean = img_bg3:getChildByName("lb_bean")
    lb_bean:setString(str)

    --yuanbao
    local ingot = userInfoTab.lIngot or userInfoTab.lUserIngot
    ingot = ingot or 0
    str = ExternalFun.numberThousands(ingot)
    if string.len(str) > 11 then
        str = string.sub(str, 1, 11) .. "..."
    end
    local lb_yuanbao = img_bg3:getChildByName("lb_yuanbao")
    lb_yuanbao:setString(str)

    --btn
    local btn_delete = img_bg2:getChildByName("btn_delete")
    btn_delete:setTag(uid)
    :addTouchEventListener(touchFunC)
    local btn_give = img_bg2:getChildByName("btn_give")
    btn_give:setTag(uid)
    :addTouchEventListener(touchFunC)
end

--更新消息红点提示
function PriRoomListLayer:updateNoticeHint()
    local notifyTab = FriendMgr:getInstance():getUnReadNotify()
    cclog("PriRoomListLayer:updateNoticeHint===>" .. #notifyTab)
    if #notifyTab < 1 then
        self.btn_notice:setVisible(false)
        self.notice_hint:setVisible(false)
        self.notice_hintNum:setString("0")
    else
        self.btn_notice:setVisible(true)
        self.notice_hint:setVisible(true)
        self.notice_hintNum:setString(#notifyTab)
    end
end

function PriRoomListLayer:searchFriend()
    if nil == self.m_editId then
        showToast(self, "输入不能为空", 2)
    end

    local content = tonumber(self.m_editId:getText())

    if nil == content then
        showToast(self, "请输入合法的ID", 2)
        return
    end

    if string.len(content)<1 then
        showToast(self, "输入不能为空", 2)
        return
    else
        FriendMgr:getInstance():sendSearchFriend(content)                
    end   
end

function PriRoomListLayer:inviteBook()
    local function sharecall( isok )
        if type(isok) == "string" and isok == "true" then
            showToast(self, "分享完成", 2)
        end
    end
    local url = GlobalUserItem.szSpreaderURL or yl.HTTP_URL
    local msg = INVITE_BOOK_TEXT .. url
    MultiPlatform:getInstance():shareToTarget(yl.ThirdParty.SMS, sharecall, INVITE_BOOK_TITLE, msg)
end

function PriRoomListLayer:inviteWeChat()
    local function sharecall( isok )
        if type(isok) == "string" and isok == "true" then
            showToast(self, "分享完成", 2)
        end
    end
    local url = GlobalUserItem.szWXSpreaderURL or yl.HTTP_URL
    MultiPlatform:getInstance():shareToTarget(yl.ThirdParty.WECHAT, sharecall, INVITE_WECHAT_TITLE, INVITE_WECHAT_TEXT, url, "")
end

function PriRoomListLayer:rejectAddFriend()
    local sendTab = {}
    sendTab.dwUserID = GlobalUserItem.dwUserID
    sendTab.dwRequestID = curTab.notify.dwRequestID
    sendTab.bAccepted = false

    FriendMgr:getInstance():sendRespondFriend(sendTab,curTab.notifyId)  
end

function PriRoomListLayer:agreeAddFriend()
    local sendTab = {}
    sendTab.dwUserID = GlobalUserItem.dwUserID
    sendTab.dwRequestID = curTab.notify.dwRequestID
    sendTab.bAccepted = true

    FriendMgr:getInstance():sendRespondFriend(sendTab,curTab.notifyId)
end

function PriRoomListLayer:deleteFriend()
    local eventListener = cc.EventCustom:new(yl.RY_FRIEND_NOTIFY)
    eventListener.obj = yl.RY_MSG_FRIENDDEL
    cc.Director:getInstance():getEventDispatcher():dispatchEvent(eventListener)
end

function PriRoomListLayer:chatFriend(uid)
    cclog("PriRoomListLayer:chatFriend===>" .. uid)
    --标记在聊天界面
    self.m_bIsChatLayer = true
    local chatuser = FriendMgr:getInstance():getFriendByID(uid)
    if nil == chatuser then
        return
    end

    --聊天
    local runScene = cc.Director:getInstance():getRunningScene()
    if runScene then
        local layer, FriendChatLayer = ExternalFun.loadRootCSB("roomnew/FriendChatLayer.csb", runScene)
        --加載好友列表与聊天列表
        self.m_chatListManager = FriendChatList:create(FriendChatLayer, chatuser.dwUserID, self)
    end
end


--获取好友界面聊天按钮
function PriRoomListLayer:getFriendListCell(userid)
    cclog("function PriRoomListLayer:getFriendListCell(userid) ==>")

    if nil == userid or -1 == userid then
        return nil
    end

    local container = self.mFriendListTable:getContainer()
    if nil ~= container then
        local cell = container:getChildByTag(userid)
        if nil ~= cell then
            return cell:getChildByName("friendCell")
        end
    end
    return nil
end

--获取好友界面好友红点显示node
function PriRoomListLayer:getChatFriendCellNotifyNode(dwUserID, ingoreSelf)
    cclog("function PriRoomListLayer:getChatFriendCellNotifyNode(dwUserID, ingoreSelf) ==>")

    --当前聊天对象
    if dwUserID == self.m_dwCurrentUserId then
        return nil
    end
    if nil ~= self.m_chatListManager and nil ~= self.m_chatListManager.getNotifyNode then
        return self.m_chatListManager:getNotifyNode(dwUserID)
    end
    return nil
end

--聊天
function PriRoomListLayer:setIsChatLayer(var)
    cclog("function PriRoomListLayer:setIsChatLayer(var) ==>")
    self.m_bIsChatLayer = var
end

--聊天
function PriRoomListLayer:setCurrentChatUser(dwUserID)
    cclog("function PriRoomListLayer:setCurrentChatUser(dwUserID) ==>")
    cclog("set current user ==> " .. dwUserID)
    --关闭通知
    local friendcell = self:getFriendListCell(dwUserID)
    if nil ~= friendcell then
        local chatbtn = friendcell:getChildByName("btn_chat")
        NotifyMgr:getInstance():hideNotify(chatbtn, true)
    end
    self.m_dwCurrentUserId = dwUserID
end

-----------------------------button 回调---------------------------------
function PriRoomListLayer:onButtonClickedEvent( tag, sender )
    if BTN_NORMAL_ROOMLIST == tag then   --房间列表
        -- 重置搜索路径
        PriRoom:getInstance():exitRoom()
        self._scene:onChangeShowMode(yl.SCENE_ROOMLIST)
    elseif BTN_JOIN_PRIROOM == tag then  -- 加入房间
        PriRoom:getInstance():getTagLayer(PriRoom.LAYTAG.LAYER_ROOMID)
    elseif BTN_CREATE_PRIROOM == tag then -- 创建房间
        self._scene:onChangeShowMode(PriRoom.LAYTAG.LAYER_CREATEPRIROOME)   
    elseif BTN_MY_ROOM == tag then -- 我的房间
        self._scene:onChangeShowMode(PriRoom.LAYTAG.LAYER_MYROOMRECORD)    
    elseif BTN_FRIEND_LIST == tag then --标签，列表
        NotifyMgr:getInstance():hideNotify(sender)
        self.m_nSelect = BTN_FRIEND_LIST
        self:showFriendlist(true)
        self:showAddFriend(false)
    elseif BTN_FRIEND_ADD == tag then  --标签，添加
        self.m_nSelect = BTN_FRIEND_ADD
        self:showFriendlist(false)
        self:showAddFriend(true)
    elseif BTN_FRIEND_NOTICE == tag then  --标签，通知
        self:showNextNotice()
    elseif BTN_FRIEND_ADD_SEARCH == tag then
        --搜索好友
        self:searchFriend()
    elseif BTN_FRIEND_ADD_INVITEBOOK == tag then
        --联系人邀请
        self:inviteBook()
    elseif BTN_FRIEND_ADD_INVITEWECHAT == tag then
        --微信邀请
        self:inviteWeChat()
    end
end


function PriRoomListLayer:onFriendHeadEvent(tag, sender)
    local uid = tag
    cclog("PriRoomListLayer:onFriendHeadEvent===>uid: " .. uid)
    self:showFriendDetailView(uid)
end

function PriRoomListLayer:onChatEvent(tag, sender)
    local uid = tag
    cclog("PriRoomListLayer:onChatEvent===>uid: " .. uid)
    self:chatFriend(uid)
end

function PriRoomListLayer:onCheckBoxEvent(sender, eventType)
    local uid = sender:getTag()
    cclog("PriRoomListLayer:onCheckBoxEvent===>uid: " .. uid)
    if eventType == ccui.CheckBoxEventType.selected then
       FriendMgr:getInstance():insertInviteList(uid)
    else
       FriendMgr:getInstance():removeInviteList(uid)
    end
end

----------------------------------------tableview------------------------------------------
function PriRoomListLayer:cellSizeForTable(table,idx)
    return 520, 95
end

function PriRoomListLayer:tableCellAtIndex(table, idx)
    cclog("function PriRoomListLayer:tableCellAtIndex(table, idx) ==>")
    local cell = table:dequeueCell()
    local userInfoTab = self.mFriendList[#self.mFriendList - idx]
    local uid = userInfoTab.dwUserID


    if nil == cell then
        local touchFunC = function(ref, tType)
            if tType == ccui.TouchEventType.ended then
                self:onChatEvent(ref:getTag(), ref)            
            end
        end
        local touchFunC2 = function(ref, tType)
            if tType == ccui.TouchEventType.ended then
                self:onFriendHeadEvent(ref:getTag(), ref)            
            end
        end
        cell = cc.TableViewCell:create();
        local friendCell = ExternalFun.loadCSB("roomnew/FriendListItem.csb")
        local frame = friendCell:getChildByName("img_frame")
        --裁切头像
        local head = PopupInfoHead:createClipHead(userInfoTab, 70)
        if nil ~= head then
            head:setPosition(frame:getPosition())
            :addTo(friendCell)
            :setName("head")
        end
        local btn_head = friendCell:getChildByName("btn_head")
        btn_head:setTag(uid)
        btn_head:addTouchEventListener(touchFunC2)

        --聊天
        local btn_chat = friendCell:getChildByName("btn_chat")
        btn_chat:setTag(uid)
        btn_chat:addTouchEventListener(touchFunC)

        --控件控制
        local btn_checkBox = friendCell:getChildByName("btn_check")
        local lb_invite = friendCell:getChildByName("lb_invite")
        if self._type == PriRoomListLayer.TYPE_PRIROOM then
            btn_checkBox:setTag(uid)
            btn_checkBox:addEventListener(handler(self, self.onCheckBoxEvent))
        else
            btn_checkBox:setVisible(false)
            lb_invite:setVisible(false)
        end

        friendCell:setName("friendCell")
        cell:addChild(friendCell)
    end

    ---------------更新cell
    friendCell = cell:getChildByName("friendCell")
    local head = appdf.getNodeByName(friendCell,"head")
    local nickName = appdf.getNodeByName(friendCell,"lb_name")        
    local level = appdf.getNodeByName(friendCell,"lb_level")
    --数值
    level:setString("LV: " .. userInfoTab.wGrowLevel) 
    nickName:setString(userInfoTab.szNickName)

    --头像
    head:updateHead(userInfoTab)

    --按钮
    local btn_chat = friendCell:getChildByName("btn_chat")
    btn_chat:setTag(uid)
    local btn_checkBox = friendCell:getChildByName("btn_check")
    btn_checkBox:setTag(uid)

    --check btn
    local hasSelected = FriendMgr:getInstance():isFriendInInviteList(uid)
    btn_checkBox:setSelected(hasSelected)

    --在线状态
    local lb_online = friendCell:getChildByName("lb_online")
    local lb_offline = friendCell:getChildByName("lb_offline")
    if userInfoTab.cbMainStatus == chat_cmd.FRIEND_US_OFFLINE then 
        --离线
        lb_online:setVisible(false)
        lb_offline:setVisible(true)
    else
        --在线
        lb_online:setVisible(true)
        lb_offline:setVisible(false)
    end

    cell:setTag(userInfoTab.dwUserID)
    return cell
end

function PriRoomListLayer:numberOfCellsInTableView(table)
   return #self.mFriendList
end


---------------------------好友回调------------------------------------
--接收搜索结果
function PriRoomListLayer:onSearchResult(userTab)
    cclog("function PriRoomListLayer:onSearchResult(userTab) ==>")

    local FriendAddLayer = appdf.getNodeByName(self,"panel_add");
    local ListUserSearch = appdf.getNodeByName(FriendAddLayer,"list_add");
    local ListUserSearchSize  = ListUserSearch:getContentSize();
    if #userTab ==0 then
        local tipLab = cc.Label:createWithTTF("查询不到用户哦！","fonts/yuanti_sc_light.ttf",30);
        tipLab:setPosition(cc.p(ListUserSearchSize.width/2,ListUserSearchSize.height/2));
        ListUserSearch:addChild(tipLab);
        tipLab:setTextColor(cc.c4b(41, 82, 146, 255));
        local function removeTipLab()
            tipLab:removeFromParent();
        end 
        tipLab:runAction(cc.Sequence:create(cc.DelayTime:create(2),cc.CallFunc:create(removeTipLab)));
    else
        if nil ~= self.m_editId then
            self.m_editId:setText("")
        end
        ListUserSearch:removeAllItems();


        for i=1,#userTab do   
            local userInfoTab = userTab[i]
            local userItem2 = ccui.Layout:create()
            local userItem = ExternalFun.loadCSB("roomnew/FriendListItem.csb")
            userItem2:setContentSize(userItem:getContentSize())
            userItem2:addChild(userItem)
            

            --控件控制
            local btn_chat = userItem:getChildByName("btn_chat")
            btn_chat:setVisible(false)
            local lb_chat = userItem:getChildByName("lb_chat")
            lb_chat:setVisible(false);
            local btn_check = userItem:getChildByName("btn_check")
            btn_check:setVisible(false)
            local lb_invite = userItem:getChildByName("lb_invite")
            lb_invite:setVisible(false)
            local btn_add = userItem:getChildByName("btn_addfriend")
            btn_add:setVisible(false)
            local lb_online = userItem:getChildByName("lb_online")
            lb_online:setVisible(false)
            local lb_offline = userItem:getChildByName("lb_offline")
            lb_offline:setVisible(false)

            --在线状态
            if userInfoTab.cbMainStatus == chat_cmd.FRIEND_US_OFFLINE then 
                --离线
                lb_online:setVisible(false)
                lb_offline:setVisible(true)
            else
                --在线
                lb_online:setVisible(true)
                lb_offline:setVisible(false)
            end


            --头像
            local img_frame = userItem:getChildByName("img_frame")
            local head = PopupInfoHead:createClipHead(userInfoTab, 70)
            head:setPosition(img_frame:getPosition())
            userItem:addChild(head)
            head:setIsGamePop(false)

            --name
            local lb_name = userItem:getChildByName("lb_name")
            lb_name:setString(userInfoTab.szNickName)

            local lb_lv = userItem:getChildByName("lb_level")
            lb_lv:setString("LV: " .. userInfoTab.cbMemberOrder)

  
            local friendTab = FriendMgr:getInstance():getFriendList();
            --查询好友列表是否存在该用户
            local userIsExit = false;
            for i=1,#friendTab do
                local curUser = friendTab[i];
                if curUser.dwUserID == userInfoTab.dwUserID then
                    --好友列表存在该好友
                    userIsExit = true
                    break
                end               
            end
            --判断是否是自己
            local isMe = userInfoTab.dwUserID == GlobalUserItem.dwUserID

            local actionBtn = nil
            if true == isMe then
                btn_add:setVisible(false)
            elseif userIsExit then
                btn_add:setVisible(true)
                btn_add:setEnabled(false)
            else
                btn_add:setVisible(true)
                btn_add:setTag(i + 1000)
                btn_add:addTouchEventListener(function(ref, tType)
                    if tType == ccui.TouchEventType.ended then
                        local addFriendTab = {}    
                        addFriendTab.dwUserID = GlobalUserItem.dwUserID;
                        addFriendTab.dwFriendID = userTab[ref:getTag()-1000].dwUserID
                        addFriendTab.cbGroupID = 0;
                        local function sendResult(isAction)
                            ref:setEnabled(false)
                        end
                        --添加好友
                        FriendMgr:getInstance():sendAddFriend(addFriendTab,sendResult)
                    end
                end)
            end
            
            ListUserSearch:pushBackCustomItem(userItem2); 
        end     
    end
end


--更新好友列表
function PriRoomListLayer:onFriendInfo( event )
    cclog("function PriRoomListLayer:onFriendInfo( event ) ==>")

    local msgWhat = event.obj

    if nil ~= msgWhat and yl.RY_MSG_FRIENDDEL == msgWhat then
        --删除好友
        self:refreshFriendList()
    end
end

--接收更新消息通知
function PriRoomListLayer:onUpdateNotifyList()
    self:updateNoticeHint()
end

--接收通知
function PriRoomListLayer:onNotify(msg)
    cclog("function PriRoomListLayer:onNotify(msg) ==>" .. json.encode(msg))

    local bHandled = false
    if msg.main == chat_cmd.MDM_GC_USER then
        if msg.sub == chat_cmd.SUB_GC_USER_CHAT_NOTIFY 
            or msg.sub == chat_cmd.SUB_GC_INVITE_GAME_NOTIFY
            or msg.sub == chat_cmd.SUB_GC_USER_SHARE_NOTIFY
            or msg.sub == chat_cmd.SUB_GC_INVITE_PERSONAL_NOTIFY then
            --dump(msg, "|", 6)
            --确保不在好友列表界面
            if self.m_nSelect ~= BTN_FRIEND_LIST then
                NotifyMgr:getInstance():showNotify(self.btn_list, msg, cc.p(3, 123))
            end 
            
            --单独解析 dwSenderID 为发送者id
            if type(msg.param) == "table" then
                local sendUser = msg.param.dwSenderID
                if nil == sendUser then
                    return false
                end
                if false == self.m_bIsChatLayer then
                    --不在聊天界面
                    bHandled = false
                else
                    --是否当前聊天对象
                    bHandled = (sendUser == self.m_dwCurrentUserId)
                end
                if false == bHandled then
                    local friendcell = self:getFriendListCell(sendUser)
                    if nil ~= friendcell then
                        local chatbtn = friendcell:getChildByName("btn_chat")
                        NotifyMgr:getInstance():showNotify(chatbtn, msg)
                    end
                end

                --聊天界面
                if true == self.m_bIsChatLayer then
                    --非当前聊天对象
                    local node = self:getChatFriendCellNotifyNode(sendUser)
                    if nil ~= node then
                        NotifyMgr:getInstance():showNotify(node, msg)
                    end
                end                
            end                   
        end        
    end
    return bHandled
end

--新消息通知
function PriRoomListLayer:onMessageNotify(notify)
    cclog("function PriRoomListLayer:onMessageNotify(notify) ==>")

    if nil ~= self.m_chatListManager and nil ~= self.m_chatListManager.messageNotify then
        self.m_chatListManager:messageNotify(notify)
    end
end


--刷新指定好友游戏状态
function PriRoomListLayer:onRefreshFriendState(userInfo, isGameState)
    cclog("function PriRoomListLayer:onRefreshFriendState==>")
    isGameState = isGameState or false
    --刷新好友列表
    local friendCell = self:getFriendListCell(userInfo.dwUserID)
    if nil ~= friendCell then
        local lb_online = friendCell:getChildByName("lb_online")
        local lb_offline = friendCell:getChildByName("lb_offline")
        if userInfo.cbMainStatus == chat_cmd.FRIEND_US_OFFLINE then 
            --离线
            lb_online:setVisible(false)
            lb_offline:setVisible(true)
        else
            --在线
            lb_online:setVisible(true)
            lb_offline:setVisible(false)
        end
    end

    if false == isGameState then
        --刷新聊天列表
        if nil ~= self.m_chatListManager and nil ~= self.m_chatListManager.refreshFriendState then
            return self.m_chatListManager:refreshFriendState(userInfo)
        end
    end    
end

return PriRoomListLayer