-- Name: GameRecordLayer
-- Func: 游戏记录
-- Author: Johny

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")

local GameRecordLayer = class("GameRecordLayer", cc.Layer)

local BTN_CLOSE     = 1

function GameRecordLayer:ctor(scene)
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
	local csbNode = ExternalFun.loadCSB("gamerecord/GameRecordLayer.csb", self)

	--close
	local btn_close = appdf.getNodeByName(csbNode, "btn_close")
	btn_close:setTag(BTN_CLOSE)
	btn_close:addTouchEventListener(btcallback)



end

--按键响应
function GameRecordLayer:OnButtonClickedEvent(tag,ref)
	if tag == BTN_CLOSE then
		self:removeFromParent()
	end
end

return GameRecordLayer
