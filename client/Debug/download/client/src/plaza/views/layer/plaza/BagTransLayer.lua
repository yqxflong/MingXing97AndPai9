-- Name: BagTransLayer
-- Func: 背包赠送界面
-- Author: Johny

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local BagTransFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.ShopDetailFrame")


local BagTransLayer = class("BagTransLayer", cc.Layer)


BagTransLayer.CBT_USERID			= 10
BagTransLayer.CBT_NICKNAME			= 11

BagTransLayer.BT_TRANS				= 21
BagTransLayer.BT_ADD				= 22
BagTransLayer.BT_MIN				= 23

-- 进入场景而且过渡动画结束时候触发。
function BagTransLayer:onEnterTransitionFinish()
	cclog("function BagTransLayer:onEnterTransitionFinish() ==> ")
    return self
end

-- 退出场景而且开始过渡动画时候触发。
function BagTransLayer:onExitTransitionStart()
	cclog("function BagTransLayer:onExitTransitionStart() ==> ")
    return self
end

function BagTransLayer:ctor(scene, gameFrame)

	cclog("function function BagTransLayer:ctor(scene, gameFrame) ==> ")

	local this = self

	self._scene = scene
	
	self:registerScriptHandler(function(eventType)
		if eventType == "enterTransitionFinish" then	-- 进入场景而且过渡动画结束时候触发。
			self:onEnterTransitionFinish()
		elseif eventType == "exitTransitionStart" then	-- 退出场景而且开始过渡动画时候触发。
			self:onExitTransitionStart()
        elseif eventType == "exit" then
            if self._BagTransFrame:isSocketServer() then
                self._BagTransFrame:onCloseSocket()
            end
            if nil ~= self._BagTransFrame._gameFrame then
                self._BagTransFrame._gameFrame._shotFrame = nil
                self._BagTransFrame._gameFrame = nil
            end
		end
	end)

	--按钮回调
	self._btcallback = function(ref, type)
        if type == ccui.TouchEventType.ended then
         	this:onButtonClickedEvent(ref:getTag(),ref)
        end
    end

    local cbtlistener = function (sender,eventType)
    	this:onSelectedEvent(sender:getTag(),sender,eventType)
    end

    --网络回调
    local BagTransCallBack = function(result,message)
		this:onBagTransCallBack(result,message)
	end

	--网络处理
	self._BagTransFrame = BagTransFrame:create(self,BagTransCallBack)
    self._BagTransFrame._gameFrame = gameFrame
    if nil ~= gameFrame then
        gameFrame._shotFrame = self._BagTransFrame
    end

    self._item = GlobalUserItem.useItem
    self._transNum = 1
    self._type = yl.PRESEND_GAMEID


    ---------------------------------layout-----------------------------
    local csbNode = ExternalFun.loadCSB("shopnew/BagTransLayer.csb", self)
    local img_bg = csbNode:getChildByName("img_bg")
    self.mImg_bg2 = img_bg:getChildByName("img_bg2")

    --return
    local btn_return = appdf.getNodeByName(img_bg, "btn_return")
    btn_return:addTouchEventListener(function(ref, type)
       		 	if type == ccui.TouchEventType.ended then
					this._scene:onKeyBack()
				end
			end)

    --item
    local img_itembg = appdf.getNodeByName(img_bg, "img_itembg")
    local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("icon_public_".. self._item._index ..".png")
    if nil ~= frame then
        local sp = cc.Sprite:createWithSpriteFrame(frame)
        sp:setPosition(img_itembg:getPosition())
        img_bg:addChild(sp)
    end
    local lb_itemname = appdf.getNodeByName(img_bg, "lb_itemname")
    frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("text_public_".. self._item._index ..".png")
    if nil ~= frame then
        local sp = cc.Sprite:createWithSpriteFrame(frame)
        sp:setPosition(lb_itemname:getPosition())
        img_bg:addChild(sp)
    end
    lb_itemname:removeFromParent()
    local lb_itemcnt = appdf.getNodeByName(img_bg, "lb_itemcnt")
    lb_itemcnt:setString(tostring(self._item._count))
	self._txtNum1 = lb_itemcnt

    --依据ID
    local check_byid = appdf.getNodeByName(img_bg, "check_byid")
	check_byid:setSelected(true)
	check_byid:setTag(BagTransLayer.CBT_USERID)
	check_byid:addEventListener(cbtlistener)
	--依据昵称
	local check_byname = appdf.getNodeByName(img_bg, "check_byname")
	check_byname:setSelected(false)
	check_byname:setTag(BagTransLayer.CBT_NICKNAME)
	check_byname:addEventListener(cbtlistener)

	--give
	local btn_give = appdf.getNodeByName(img_bg, "btn_give")
	btn_give:setTag(BagTransLayer.BT_TRANS)
	btn_give:addTouchEventListener(self._btcallback)

	--接收玩家
	local img_replayerbg = appdf.getNodeByName(img_bg, "img_replayerbg")
	self.edit_trans = ccui.EditBox:create(img_replayerbg:getContentSize(), "blank.png")
		:move(img_replayerbg:getPosition())
		:setAnchorPoint(cc.p(0,0.5))
		:setFontColor(cc.c3b(0,0,0))
		:setFontName("fonts/yuanti_sc_light.ttf")
		:setPlaceholderFontName("fonts/yuanti_sc_light.ttf")
		:setFontSize(24)
		:setMaxLength(32)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:addTo(self.mImg_bg2)

	--赠送数量
	local btn_min = appdf.getNodeByName(img_bg, "btn_min")
	btn_min:setTag(BagTransLayer.BT_MIN)
	btn_min:addTouchEventListener(self._btcallback)
	local btn_add = appdf.getNodeByName(img_bg, "btn_add")
	btn_add:setTag(BagTransLayer.BT_ADD)
	btn_add:addTouchEventListener(self._btcallback)
	local lb_cnt = appdf.getNodeByName(img_bg, "lb_cnt")
	lb_cnt:setString("1")
	self._txtBuy = lb_cnt

    --右侧剩余
    local lb_left = appdf.getNodeByName(img_bg, "lb_left")
    lb_left:setString(tostring(self._item._count))
	self._txtNum3 = lb_left

	--功能描述
	local lb_ps = appdf.getNodeByName(img_bg, "lb_ps")
	lb_ps:setString("功能："..self._item._info)

    self:onUpdateNum()
end

function BagTransLayer:onSelectedEvent(tag,sender,eventType)
	cclog("function BagTransLayer:onSelectedEvent(tag,sender,eventType) ==> ")

	local wType = 0
	if tag == BagTransLayer.CBT_USERID then
		wType = yl.PRESEND_GAMEID
	elseif tag == BagTransLayer.CBT_NICKNAME then
		wType = yl.PRESEND_NICKNAME
	end

	if self._type == wType then
		self.mImg_bg2:getChildByTag(tag):setSelected(true)
		return
	end

	self._type = wType

	for i=BagTransLayer.CBT_USERID,BagTransLayer.CBT_NICKNAME do
		if i ~= tag then
			self.mImg_bg2:getChildByTag(i):setSelected(false)
		end
	end

	self.edit_trans:setText("");

end

--按键监听
function BagTransLayer:onButtonClickedEvent(tag,sender)
	cclog("function BagTransLayer:onButtonClickedEvent(tag,sender) ==> ")

	if tag == BagTransLayer.BT_ADD then
		if self._transNum < self._item._count then
			self._transNum = self._transNum+1
			self:onUpdateNum()
		end
	elseif tag == BagTransLayer.BT_MIN then
		if self._transNum ~= 1 then
			self._transNum = self._transNum-1
			self:onUpdateNum()
		end
	elseif tag == BagTransLayer.BT_TRANS then
		local szTarget = string.gsub(self.edit_trans:getText(), " ", "")
		if #szTarget < 1 then 
			showToast(self,"请输入赠送用户昵称或ID！",2)
			return
		end
		local gameid = 0
		if self._type == yl.PRESEND_GAMEID then
			gameid = tonumber(szTarget)
			szTarget = ""
			if gameid == 0 or gameid == nil then
				showToast(self,"请输入正确的ID！",2)
				return
			end
		end

		self._scene:showPopWait()
		self._BagTransFrame:onPropertyTrans(self._item._index,self._type,gameid,szTarget,self._transNum)
	end

end

function BagTransLayer:onUpdateNum()

	cclog("function BagTransLayer:onUpdateNum() ==> ")

	self._txtBuy:setString(string.formatNumberThousands(self._transNum,true,"/"))
	self._txtNum1:setString(""..self._item._count)
	self._txtNum3:setString(""..self._item._count-self._transNum)

end

--操作结果
function BagTransLayer:onBagTransCallBack(result,message)

	cclog("========function BagTransLayer:onBagTransCallBack ========")

	self._scene:dismissPopWait()
	if  message ~= nil and message ~= "" then
		showToast(self,message,2);
	end

	if result==2 then
		self._item._count = self._item._count-self._transNum
		self._transNum = 1
		self:onUpdateNum()

		if self._item._count < 1 then
			self._scene:onKeyBack()
		end
	end

end

return BagTransLayer
