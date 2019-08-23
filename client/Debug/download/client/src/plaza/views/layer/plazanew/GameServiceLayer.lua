-- Name: GameServiceLayer
-- Func: 客服界面
-- Author: Johny

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")


local GameServiceLayer = class("GameServiceLayer",function(scene)
		local GameServiceLayer =  cc.CSLoader:createNode("client/res/qrcode/QrLayer.csb")
    return GameServiceLayer
end)

function GameServiceLayer:ctor(scene)
	self._scene = scene

	ExternalFun.registerTouchEvent(self, true)

end

function GameServiceLayer:onTouchBegan(touch, event)
    return true
end

function GameServiceLayer:onTouchEnded(touch, event)
	self:removeFromParent()
end

return GameServiceLayer