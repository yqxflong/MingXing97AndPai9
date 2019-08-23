-- Name: RoomCreateResult
-- Func: 创建私房结果界面
-- Author: Johny


local RoomCreateResult = class("RoomCreateResult", cc.Layer)
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")

----------------------常量定义--------------------------
local BT_JOIN   = 101
local BT_INVITE = 102
local BTN_CLOSE = 103

function RoomCreateResult:ctor( scene )
    cclog("function RoomCreateResult:ctor( scene ) ==>")
    self.scene = scene
    -- 加载csb资源
    local rootLayer, csbNode = ExternalFun.loadRootCSB("roomrecord/CreateRoomResult.csb", self)

    local touchFunC = function(ref, tType)
        if tType == ccui.TouchEventType.ended then
            self:onButtonClickedEvent(ref:getTag(), ref)            
        end
    end


    -- 底板
    local image_bg = csbNode:getChildByName("img_bg")
    image_bg:setTouchEnabled(true)
    image_bg:setSwallowTouches(true)
    image_bg:setScale(0.00001)
    self.m_imageBg = image_bg

    -- close
    local btn_close = image_bg:getChildByName("btn_close")
    btn_close:setTag(BTN_CLOSE)
    btn_close:addTouchEventListener( touchFunC )

    -- 创建结果
    local tips = image_bg:getChildByName("txt_tips")
    tips:setString("房间 " .. PriRoom:getInstance().m_tabPriData.szServerID .. " 创建成功, 是否进入游戏?")

    -- 加入游戏
    local btn = image_bg:getChildByName("btn_join")
    btn:setTag(BT_JOIN)
    btn:addTouchEventListener( touchFunC )

    -- 邀请好友
    btn = image_bg:getChildByName("btn_invite")
    btn:setTag(BT_INVITE)
    btn:addTouchEventListener( touchFunC )

    -- 加载动画
    image_bg:runAction(cc.ScaleTo:create(0.2, 1.0))
end

function RoomCreateResult:onButtonClickedEvent( tag, sender )
    cclog("function RoomCreateResult:onButtonClickedEvent( tag, sender ) ==>")

    if BTN_CLOSE == tag then
        local scale1 = cc.ScaleTo:create(0.2, 0.0001)
        local call1 = cc.CallFunc:create(function()
            self:removeFromParent()
        end)
        self.m_imageBg:runAction(cc.Sequence:create(scale1, call1))
    elseif BT_JOIN == tag then
        local scale1 = cc.ScaleTo:create(0.2, 0.0001)
        local call1 = cc.CallFunc:create(function()
            PriRoom:getInstance():showPopWait()
            PriRoom:getInstance():getNetFrame():onSearchRoom(PriRoom:getInstance().m_tabPriData.szServerID)
            self:removeFromParent()
        end)
        self.m_imageBg:runAction(cc.Sequence:create(scale1, call1))        
    elseif BT_INVITE == tag then
        local target = yl.ThirdParty.WECHAT
        local url = "none"
        local function sharecall( isok )
            if type(isok) == "string" and isok == "true" then
                --showToast(self, "分享成功", 2)
            end
        end
        local m_tabDetail = {} 
        m_tabDetail.szRoomID = PriRoom:getInstance().m_tabPriData.szServerID
        m_tabDetail.dwPlayTurnCount = PriRoom:getInstance().m_tabPriData.dwDrawCountLimit
        local msgTab = PriRoom:getInstance():getInviteShareMsg(m_tabDetail)
        cclog("RoomCreateResult:onButtonClickedEvent===>" .. msgTab.content)
        MultiPlatform:getInstance():shareToTarget(target, sharecall, msgTab.title, msgTab.content, url)
    end
end

return RoomCreateResult