-- Name: GameRulesLayer
-- Func: 游戏规则
-- Author: Johny

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")

local GameRulesLayer = class("GameRulesLayer", cc.Layer)

local BTN_CLOSE     = 1

function GameRulesLayer:ctor(scene)
	self._scene = scene

	local btcallback = function(ref, type)
		if type == ccui.TouchEventType.ended then
			self:OnButtonClickedEvent(ref:getTag(),ref)
        end
	end

	local slidercallback = function (ref, type)
		if type == 0 then
		   self:OnSliderEvent(ref:getTag(), ref)
		end
	end

	--layout
	local csbNode = ExternalFun.loadCSB("gamerules/GameRulesLayer.csb", self)
	local img_bg2 = appdf.getNodeByName(csbNode, "img_bg2")

	--close
	local btn_close = appdf.getNodeByName(csbNode, "btn_close")
	btn_close:setTag(BTN_CLOSE)
	btn_close:addTouchEventListener(btcallback)

	--scrollview
	local sp = display.newSprite("gamerules/rules_content.png")
	local size_sp = sp:getContentSize()
	sp:setAnchorPoint(cc.p(0.0, 0.0))
	local sv = ccui.ScrollView:create()
	sv:setContentSize(cc.size(size_sp.width, 520))
	sv:setInnerContainerSize(size_sp)
	sv:move(cc.p(50, 20))
	sv:addTo(img_bg2)
	sv:addChild(sp)

end

--按键响应
function GameRulesLayer:OnButtonClickedEvent(tag,ref)
	if tag == BTN_CLOSE then
		self:removeFromParent()
	end
end

return GameRulesLayer
