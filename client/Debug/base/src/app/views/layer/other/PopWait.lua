--[[
	等候界面
		2016_04_27 C.P
	功能：阻断用户输入，防止不必要的情况
]]

--转圈等待时间5s
local DURING_WAIT = 5

local PopWait = class("PopWait", function(isTransparent)
	if isTransparent then
		return display.newLayer(cc.c4b(0, 0, 0, 0))
	else
	 	return display.newLayer(cc.c4b(0, 0, 0, 125))
	end    
end)

function PopWait:ctor(isTransparent)
	self:setContentSize(display.width,display.height)
	
	local function onTouch(eventType, x, y)
        return true
    end
	self:setTouchEnabled(true)
	self:registerScriptTouchHandler(onTouch)

	if not isTransparent then
		cc.Sprite:create("base_waitround.png")
			:addTo(self)
			:move(display.width/2,display.height/2 )	
			:runAction(cc.RepeatForever:create(cc.RotateBy:create(2 , 360)))
	end	

	--设定最大等待时间
	self:runAction(cc.Sequence:create(cc.DelayTime:create(DURING_WAIT), cc.CallFunc:create(function()
		   if self:getParent() and self:getParent().onLeaveSubGame then
		   	  self:getParent():onLeaveSubGame()
		   	  self:getParent():dismissPopWait()
		   	  showToast(self:getParent(), "~~~等待超时~~~", 2)
		   end
		end)))
end

--显示
function PopWait:show(parent,message)
	self:addTo(parent)
	return self
end

--显示状态
function PopWait:isShow()
	return not self._dismiss 
end

--取消显示
function PopWait:dismiss()
	if self._dismiss then
		return
	end
	self:stopAllActions()
	self._dismiss  = true
	self:runAction(cc.RemoveSelf:create())
end

return PopWait