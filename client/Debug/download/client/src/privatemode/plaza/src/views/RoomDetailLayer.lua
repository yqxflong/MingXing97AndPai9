-- Name: RoomDetailLayer
-- Func:  私房详细信息
-- Author: Johny



local RoomDetailLayer = class("RoomDetailLayer", cc.Layer)
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local ClipText = appdf.req(appdf.EXTERNAL_SRC .. "ClipText")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")


--------------------------常量定义----------------------
local TAG_BTN_CLOSE       = 101
local TAG_SHARE_GRADE     = 102           -- 战绩分享
local TAG_JOIN_GAME       = 103           -- 加入游戏
local TAG_DISSUME_GAME    = 104           -- 解散房间
local TAG_INVITE_FRIEND   = 105           -- 邀请好友

local tabPosition = 
{
    {cc.p(150, 210)},
    {cc.p(150, 210), cc.p(150, 180)},
    {cc.p(150, 210), cc.p(150, 180), cc.p(150, 150)},
    {cc.p(150, 210), cc.p(150, 180), cc.p(150, 150), cc.p(150, 120)},
    {cc.p(150, 210), cc.p(150, 180), cc.p(150, 150), cc.p(150, 120), cc.p(420, 210)},
    {cc.p(150, 210), cc.p(150, 180), cc.p(150, 150), cc.p(150, 120), cc.p(420, 210), cc.p(420, 180)},
    {cc.p(150, 210), cc.p(150, 180), cc.p(150, 150), cc.p(150, 120), cc.p(420, 210), cc.p(420, 180), cc.p(420, 150)},
    {cc.p(150, 210), cc.p(150, 180), cc.p(150, 150), cc.p(150, 120), cc.p(420, 210), cc.p(420, 180), cc.p(420, 150), cc.p(420, 120)},
}

-- 详情战绩 是否结束
function RoomDetailLayer:ctor( tabDetail )
    cclog("function RoomDetailLayer:ctor( tabDetail ) ==>")
    self.m_tabDetail = tabDetail
    local onGame = tabDetail.onGame or false

    -- 加载csb资源
    local rootLayer, csbNode = ExternalFun.loadRootCSB("roomnew/RoomInfoLayer.csb", self)

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

    --close
    local panel_mask = csbNode:getChildByName("panel_mask")
    panel_mask:setTag(TAG_BTN_CLOSE)
    panel_mask:addTouchEventListener(touchFunC)



    -- 房间ID
    self.m_txtRoomId = image_bg:getChildByName("lb_roomid_0")
    local szRoomId = tabDetail.szRoomID or ""
    self.m_txtRoomId:setString(szRoomId)

    local gradList = tabDetail.PersonalUserScoreInfo[1]
    local count = #gradList
    count = (count > 7) and 7 or count
    local posList = tabPosition[count]
    -- 房间战绩列表
    if onGame then
        local clipGrad = ClipText:createClipText(cc.size(373, 28), "该房间正在游戏中,暂无战绩!", "fonts/yuanti_sc_light.ttf", 24)
        clipGrad:setAnchorPoint(cc.p(0, 0.5))
        local pos = posList[1]
        clipGrad:setPosition(pos)
        image_bg:addChild(clipGrad)
    else
        for i = 1, count do
            local v = gradList[i]        
            if 0 == v.dwUserID then
                if 1 == i then
                    local clipGrad = ClipText:createClipText(cc.size(373, 28), "该房间无战绩, 房间已解散", "fonts/yuanti_sc_light.ttf", 24)
                    clipGrad:setAnchorPoint(cc.p(0, 0.5))
                    local pos = posList[i] or cc.p(0,0)
                    clipGrad:setPosition(pos)
                    image_bg:addChild(clipGrad)
                else

                end
                break
            end
            local str = v.szUserNicname
            local clipGrad = ClipText:createClipText(cc.size(150, 28), str, "fonts/yuanti_sc_light.ttf", 24)
            clipGrad:setAnchorPoint(cc.p(0, 0.5))
            local pos = posList[i] or cc.p(0,0)
            clipGrad:setPosition(pos)
            image_bg:addChild(clipGrad)

            str = "+" .. v.lScore
            if v.lScore < 0 then
                str = "" .. v.lScore
            end
            clipGrad = ClipText:createClipText(cc.size(100, 28), str, "fonts/yuanti_sc_light.ttf", 24)
            clipGrad:setAnchorPoint(cc.p(0, 0.5))
            local pos = posList[i] or cc.p(0,0)
            pos = cc.p(pos.x + 155, pos.y)
            clipGrad:setPosition(pos)
            image_bg:addChild(clipGrad)
        end
    end
    
    -- -- 按钮列表
    -- if onGame then
    --     -- 加入游戏
    --     local btn = image_bg:getChildByName("btn_join")
    --     btn:setTag(TAG_JOIN_GAME)
    --     btn:addTouchEventListener( touchFunC )
    --     btn:setVisible(true)

    --     -- 解散房间
    --     btn = image_bg:getChildByName("btn_giveup")
    --     btn:setTag(TAG_DISSUME_GAME)
    --     btn:addTouchEventListener( touchFunC )
    --     btn:setVisible(true)

    --     -- 邀请好友
    --     btn = image_bg:getChildByName("btn_invite")
    --     btn:setTag(TAG_INVITE_FRIEND)
    --     btn:addTouchEventListener( touchFunC )
    --     btn:setVisible(true)
    -- else
        -- 分享战绩
        local btn = image_bg:getChildByName("btn_sharescore")
        btn:setTag(TAG_SHARE_GRADE) 
        btn:addTouchEventListener( touchFunC )  
        btn:setVisible(true)    
    -- end

    -- 加载动画
    image_bg:runAction(cc.ScaleTo:create(0.2, 1.0))
end

function RoomDetailLayer:onButtonClickedEvent( tag, sender)
    cclog("function RoomDetailLayer:onButtonClickedEvent( tag, sender) ==>")
    if TAG_SHARE_GRADE == tag then        
        PriRoom:getInstance():getPlazaScene():popTargetShare(function(target, bMyFriend)
            bMyFriend = bMyFriend or false
            local function sharecall( isok )
                if type(isok) == "string" and isok == "true" then
                    showToast(self, "分享成功", 2)
                end
            end
            local url = GlobalUserItem.szWXSpreaderURL or yl.HTTP_URL
            -- 截图分享
            local framesize = cc.Director:getInstance():getOpenGLView():getFrameSize()
            local area = cc.rect(0, 0, framesize.width, framesize.height)
            local imagename = "grade_share.jpg"
            if bMyFriend then
                imagename = "grade_share_" .. os.time() .. ".jpg"
            end
            ExternalFun.popupTouchFilter(0, false)
            captureScreenWithArea(area, imagename, function(ok, savepath)
                ExternalFun.dismissTouchFilter()
                if ok then
                    if bMyFriend then
                        PriRoom:getInstance():getTagLayer(PriRoom.LAYTAG.LAYER_FRIENDLIST, function( frienddata )
                            PriRoom:getInstance():imageShareToFriend(frienddata, savepath, "分享我的约战房战绩")
                        end)
                    elseif nil ~= target then
                        MultiPlatform:getInstance():shareToTarget(target, sharecall, "我的约战房战绩", "分享我的约战房战绩", url, savepath, "true")
                    end            
                end
            end)
        end)
    -- elseif TAG_JOIN_GAME == tag then
    --     PriRoom:getInstance():showPopWait()
    --     PriRoom:getInstance():getNetFrame():onSearchRoom(self.m_txtRoomId:getString())
    -- elseif TAG_DISSUME_GAME == tag then
    --     PriRoom:getInstance():showPopWait()
    --     PriRoom:getInstance():getNetFrame():onDissumeRoom(self.m_txtRoomId:getString())
    -- elseif TAG_INVITE_FRIEND == tag then
    --     PriRoom:getInstance():getPlazaScene():popTargetShare(function(target, bMyFriend)
    --         bMyFriend = bMyFriend or false
    --         local function sharecall( isok )
    --             if type(isok) == "string" and isok == "true" then
    --                 showToast(self, "分享成功", 2)
    --             end
    --         end
    --         local msgTab = PriRoom:getInstance():getInviteShareMsg(self.m_tabDetail)
    --         local url = GlobalUserItem.szWXSpreaderURL or yl.HTTP_URL
    --         if bMyFriend then
    --             PriRoom:getInstance():getTagLayer(PriRoom.LAYTAG.LAYER_FRIENDLIST, function( frienddata )
    --                 local serverid = tonumber(self.m_tabDetail.szRoomID) or 0
    --                 dump(msgTab, "desciption", 6)
    --                 PriRoom:getInstance():priInviteFriend(frienddata, GlobalUserItem.nCurGameKind, serverid, yl.INVALID_TABLE, msgTab.friendContent)
    --             end)
    --         elseif nil ~= target then
    --             MultiPlatform:getInstance():shareToTarget(target, sharecall, msgTab.title, msgTab.content, url, "")
    --         end
    --     end)
    elseif TAG_BTN_CLOSE == tag then
        self:hide()
    end
end

function RoomDetailLayer:hide()
    cclog("function RoomDetailLayer:hide() ==>")
    local scale1 = cc.ScaleTo:create(0.2, 0.0001)
    local call1 = cc.CallFunc:create(function()
        self:removeFromParent()
    end)
    self.m_imageBg:runAction(cc.Sequence:create(scale1, call1))
end

return RoomDetailLayer