--@NEW
-- Name: RoomIdInputLayer
-- Func: 私房输入房号界面
-- Author: Johny


local RoomIdInputLayer = class("RoomIdInputLayer", cc.Layer)
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")

local BTN_CLOSE  =  1
local BTN_JOIN   =  2
local BTN_DEL    =  3

function RoomIdInputLayer:ctor()
    cclog("function RoomIdInputLayer:ctor()==>")
    -- 注册触摸事件
    ExternalFun.registerTouchEvent(self, true)

    -- 加载csb资源
    local rootLayer, csbNode = ExternalFun.loadRootCSB("joinroom/JoinKeyPadLayer.csb", self)

    --
    self.m_spBg = csbNode:getChildByName("img_bg")
    local bg = self.m_spBg
    self.m_spBg:setScale(0.001)

    -- 房间ID
    self.m_atlasRoomId = appdf.getNodeByName(bg, "lb_input")
    self.m_atlasRoomId:setString("")

    local function btncallback(ref, tType)
        if tType == ccui.TouchEventType.ended then
            self:onNumButtonClickedEvent(ref:getTag(),ref)
        end
    end
    -- 数字按钮
    for i = 1, 10 do
        local tag = i - 1
        local btn = appdf.getNodeByName(bg, "btn_" .. tag)
        btn:setTag(tag)
        btn:addTouchEventListener(btncallback)
    end

    local function callback(ref, tType)
        if tType == ccui.TouchEventType.ended then
            self:onButtonClickedEvent(ref:getTag(),ref)
        end
    end

    --关闭
    local btn = appdf.getNodeByName(bg, "btn_close")
    btn:setTag(BTN_CLOSE)
    btn:addTouchEventListener(callback)

    -- 删除按钮
    btn = appdf.getNodeByName(bg, "btn_delete")
    btn:setTag(BTN_DEL)
    btn:addTouchEventListener(callback)

    -- 加入按钮
    btn = appdf.getNodeByName(bg, "btn_join")
    btn:setTag(BTN_JOIN)
    btn:addTouchEventListener(callback)

    -- 加载动画
    local scale = cc.ScaleTo:create(0.2, 1.0)
    self.m_actShowAct = scale
    ExternalFun.SAFE_RETAIN(self.m_actShowAct)

    local scale1 = cc.ScaleTo:create(0.2, 0.0001)
    local call1 = cc.CallFunc:create(function( )
        self:removeFromParent()
    end)
    self.m_actHideAct = cc.Sequence:create(scale1, call1)
    ExternalFun.SAFE_RETAIN(self.m_actHideAct)

    self:showLayer(true)
end

function RoomIdInputLayer:showLayer(_show)
    self.m_spBg:stopAllActions()
    if _show then
        self.m_spBg:runAction(self.m_actShowAct)  
    else
        self.m_spBg:runAction(self.m_actHideAct)  
    end
end

function RoomIdInputLayer:onExit()
    cclog("function RoomIdInputLayer:onExit()")
    ExternalFun.SAFE_RELEASE(self.m_actShowAct)
    self.m_actShowAct = nil
    ExternalFun.SAFE_RELEASE(self.m_actHideAct)
    self.m_actHideAct = nil
end

function RoomIdInputLayer:onTouchBegan(touch, event)
    cclog("function RoomIdInputLayer:onTouchBegan(touch, event)")
    return self:isVisible()
end

function RoomIdInputLayer:onTouchEnded(touch, event)
    cclog("function RoomIdInputLayer:onTouchEnded(touch, event)")
end

function RoomIdInputLayer:onNumButtonClickedEvent( tag, sender )
    cclog("function RoomIdInputLayer:onNumButtonClickedEvent( tag, sender )")
    local roomid = self.m_atlasRoomId:getString()
    if string.len(roomid) < 6 then
        roomid = roomid .. tag
        self.m_atlasRoomId:setString(roomid)
    end
end

function RoomIdInputLayer:onButtonClickedEvent( tag, sender )
    cclog("function RoomIdInputLayer:onButtonClickedEvent( tag, sender )")
    local roomid = self.m_atlasRoomId:getString()
    if BTN_JOIN == tag then     
        PriRoom:getInstance():showPopWait()
        PriRoom:getInstance():getNetFrame():onSearchRoom(roomid)
    elseif BTN_DEL == tag then
        local len = string.len(roomid)
        if len > 0 then
            roomid = string.sub(roomid, 1, len - 1)
        end
        self.m_atlasRoomId:setString(roomid)    
    elseif BTN_CLOSE == tag then
        self:showLayer(false)
    end
end

---------------------------登录完成回调------------------------------------
function RoomIdInputLayer:onLoginPriRoomFinish()
    cclog("function RoomIdInputLayer:onLoginPriRoomFinish===>")
    self.m_atlasRoomId:setString("")
    GlobalUserItem.szCopyRoomId = ""
    self:showLayer(false)
end

return RoomIdInputLayer