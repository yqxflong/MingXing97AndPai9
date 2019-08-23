-- Name: BagDetailLayer
-- Func: 背包详细界面
-- Author: Johny


local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local BagDetailFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.ShopDetailFrame")



local BagDetailLayer = class("BagDetailLayer", cc.Layer)



BagDetailLayer.BT_USE				= 20
BagDetailLayer.BT_TRANS				= 21
BagDetailLayer.BT_ADD				= 22
BagDetailLayer.BT_MIN				= 23

-- 进入场景而且过渡动画结束时候触发。
function BagDetailLayer:onEnterTransitionFinish()
	cclog("function BagDetailLayer:onEnterTransitionFinish() ==> ")

    return self
end

-- 退出场景而且开始过渡动画时候触发。
function BagDetailLayer:onExitTransitionStart()
	cclog("function BagDetailLayer:onExitTransitionStart() ==> ")

    return self
end

function BagDetailLayer:ctor(scene, gameFrame)
	cclog("function BagDetailLayer:ctor(scene, gameFrame) ==> ")

	local this = self
	self._scene = scene
	
	self:registerScriptHandler(function(eventType)
		if eventType == "enterTransitionFinish" then	-- 进入场景而且过渡动画结束时候触发。
			self:onEnterTransitionFinish()
		elseif eventType == "exitTransitionStart" then	-- 退出场景而且开始过渡动画时候触发。
			self:onExitTransitionStart()
        elseif eventType == "exit" then
            if nil ~= self.m_listener then
                self:getEventDispatcher():removeEventListener(self.m_listener)
                self.m_listener = nil
            end

            if self._BagDetailFrame:isSocketServer() then
                self._BagDetailFrame:onCloseSocket()
            end
            if nil ~= self._BagDetailFrame._gameFrame then
                self._BagDetailFrame._gameFrame._shotFrame = nil
                self._BagDetailFrame._gameFrame = nil
            end
		end
	end)

	--按钮回调
	self._btcallback = function(ref, type)
        if type == ccui.TouchEventType.ended then
         	this:onButtonClickedEvent(ref:getTag(),ref)
        end
    end

    --网络回调
    local BagDetailCallBack = function(result,message)
		this:onBagDetailCallBack(result,message)
	end

	--网络处理
	self._BagDetailFrame = BagDetailFrame:create(self,BagDetailCallBack)
    self._BagDetailFrame._gameFrame = gameFrame
    if nil ~= gameFrame then
        gameFrame._shotFrame = self._BagDetailFrame
    end

    self._item = GlobalUserItem.useItem
    self._useNum = 1

    --通知监听
    local function eventListener(event)
        if self._item._index == yl.LARGE_TRUMPET then
            self._item._count = GlobalUserItem.nLargeTrumpetCount
        end
        self:onUpdateNum()
    end
    self.m_listener = cc.EventListenerCustom:create(yl.TRUMPET_COUNT_UPDATE_NOTIFY, eventListener)
    self:getEventDispatcher():addEventListenerWithFixedPriority(self.m_listener, 1)


    ------------------------------Layout---------------------------------------
    local csbNode = ExternalFun.loadCSB("shopnew/BagDetailLayer.csb", self)
    local img_bg = csbNode:getChildByName("img_bg")

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
        img_bg:addChild(sp)
        sp:setPosition(img_itembg:getPosition())
    end

    local lb_itemname = appdf.getNodeByName(img_bg, "lb_itemname")
    frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("text_public_".. self._item._index ..".png")
    if nil ~= sp then
        local sp = cc.Sprite:createWithSpriteFrame(frame)
        img_bg:addChild(sp)
        sp:setPosition(lb_itemname:getPosition())
    end
    lb_itemname:removeFromParent()
    
    local lb_itemcnt = appdf.getNodeByName(img_bg, "lb_itemcnt")
    lb_itemcnt:setString(tostring(self._item._count))
    self._txtNum1 = lb_itemcnt

	-- --数量
	-- local lb_cnt = appdf.getNodeByName(img_bg, "lb_cnt")
	-- lb_cnt:setString(tostring(self._item._count))
	-- self._txtNum2 = lb_cnt

	--赠送
	local btn_give = appdf.getNodeByName(img_bg, "btn_give")
	btn_give:setTag(BagDetailLayer.BT_TRANS)
	btn_give:addTouchEventListener(self._btcallback)

	--使用
	local btn_use = appdf.getNodeByName(img_bg, "btn_use")
	btn_use:setTag(BagDetailLayer.BT_USE)
	btn_use:addTouchEventListener(self._btcallback)

	--min
	local btn_min = appdf.getNodeByName(img_bg, "btn_min")
	btn_min:setTag(BagDetailLayer.BT_MIN)
	btn_min:addTouchEventListener(self._btcallback)

	--add
	local btn_add = appdf.getNodeByName(img_bg, "btn_add")
	btn_add:setTag(BagDetailLayer.BT_ADD)
	btn_add:addTouchEventListener(self._btcallback)

	--use cnt
	local lb_cnt = appdf.getNodeByName(img_bg, "lb_cnt")
	lb_cnt:setString("1")
	self._txtBuy = lb_cnt

	local area = ""
	if bit:_and(self._item._area,yl.PT_ISSUE_AREA_PLATFORM) then
		area = "大厅适用 "
	end
	if bit:_and(self._item._area,yl.PT_ISSUE_AREA_SERVER) then
		area = area.."房间适用 "
	end
	if bit:_and(self._item._area,yl.PT_ISSUE_AREA_GAME) then
		area = area.."游戏适用 "
	end
	local lb_usetips = appdf.getNodeByName(img_bg, "lb_usetips")
	lb_usetips:setString(area)

    --右侧剩余
	local lb_left = appdf.getNodeByName(img_bg, "lb_left")
	lb_left:setString(tostring(self._item._count))
	self._txtNum3 = lb_left

	--功能描述
	local lb_ps = appdf.getNodeByName(img_bg, "lb_ps")
	lb_ps:setString("功能："..self._item._info)	


    self:onUpdateNum()
end

--按键监听
function BagDetailLayer:onButtonClickedEvent(tag,sender)

	cclog("function BagDetailLayer:onButtonClickedEvent(tag,sender) ==> ")

	if tag == BagDetailLayer.BT_ADD then
		if self._useNum < self._item._count then
			self._useNum = self._useNum+1
			self:onUpdateNum()
		end
	elseif tag == BagDetailLayer.BT_MIN then
		if self._useNum ~= 1 then
			self._useNum = self._useNum-1
			self:onUpdateNum()
		end
	elseif tag == BagDetailLayer.BT_USE then
        --判断是否是消耗大小喇叭
        if self._item._index == yl.LARGE_TRUMPET or self._item._index == yl.SMALL_TRUMPET then
            if self._item._index == yl.LARGE_TRUMPET and nil ~= self._scene.getTrumpetSendLayer then           
                self._scene:getTrumpetSendLayer()
            end
        else
            self._scene:showPopWait()        
            self._BagDetailFrame:onPropertyUse(self._item._index,self._useNum)
        end		
	elseif tag == BagDetailLayer.BT_TRANS then
		self:getParent():getParent():onChangeShowMode(yl.SCENE_BAGTRANS)
	end

end

function BagDetailLayer:onUpdateNum()

	cclog("function BagDetailLayer:onUpdateNum() ==> ")

	self._txtBuy:setString(string.formatNumberThousands(self._useNum,true,"/"))
	self._txtNum1:setString(""..self._item._count)
	-- self._txtNum2:setString(""..self._item._count)
	self._txtNum3:setString(""..self._item._count-self._useNum)

end

--操作结果
function BagDetailLayer:onBagDetailCallBack(result,message)

	cclog("function BagDetailLayer:onBagDetailCallBack  ==>")

	self._scene:dismissPopWait()
	if  message ~= nil and message ~= "" then
		showToast(self,message,2);
	end

	if result==2 then
		self._item._count = self._item._count-self._useNum
		self._useNum = 1
		self:onUpdateNum()

		if self._item._count < 1 then
			self._scene:onKeyBack()
		end
	end

end

return BagDetailLayer
