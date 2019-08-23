-- Name: GameAdminLayer
-- Func: 管理层
-- Author: Johny

local ExternalFun =  appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local module_pre = "game.mingxing97.src"
local cmd = appdf.req(module_pre .. ".models.CMD_Game")

local GameAdminLayer = class("GameAdminLayer",function(scene)
		local GameAdminLayer =  cc.CSLoader:createNode(cmd.RES_PATH.."admin/AdminLayer.csb")
    return GameAdminLayer
end)

local BTN_CLOSE = 1
local BTN_KUCUN = 2
--local BTN_DAJIANG = 3
local BTN_WEIGHT_HARD1 = 11 --非常困难
local BTN_WEIGHT_HARD2 = 12 -- 困难
local BTN_WEIGHT_HARD3 = 13 --普通
local BTN_WEIGHT_HARD4 = 14 --容易
local BTN_WEIGHT_HARD5 = 15 --非常容易
local BTN_KC_80   = 21 --80分
local BTN_KC_160  = 22 --160分
local BTN_KC_240  = 23 --240分
local BTN_KC_320  = 24 --320分
local BTN_KC_400  = 25 --400分
local BTN_DJ_HARD1 =31  --非常困难大奖
local BTN_DJ_HARD2 =32  --困难大奖
local BTN_DJ_HARD3 =33	--普通
local BTN_DJ_HARD4 =34  --容易大奖
local BTN_DJ_HARD5 =35  --非常容易大奖

function GameAdminLayer:ctor(scene)
	self._scene = scene

	local function btncallback(ref, tType)
        if tType == ccui.TouchEventType.ended then
            self:onButtonClickedEvent(ref:getTag(),ref)
        end
    end

	--btns
	local btn_close = appdf.getNodeByName(self, "btn_close")
	btn_close:setTag(BTN_CLOSE)
	btn_close:addTouchEventListener(btncallback)

	local btn_kucun = appdf.getNodeByName(self, "btn_kc")
	btn_kucun:setTag(BTN_KUCUN)
	btn_kucun:addTouchEventListener(btncallback)

	-- local btn_dajiang = appdf.getNodeByName(self, "btn_dj")
	-- btn_dajiang:setTag(BTN_DAJIANG)
	-- btn_dajiang:addTouchEventListener(btncallback)

	--大奖概率
	for i =1,5 do
		local btn_dajiang = appdf.getNodeByName(self,"btn_dj_"..i)
		btn_dajiang:setTag(BTN_DJ_HARD1 + i - 1)
		btn_dajiang:addTouchEventListener(btncallback)
	end

	--weight
	for i = 1, 5 do
		local btn_weight = appdf.getNodeByName(self, "btn_qz_" .. i)
		btn_weight:setTag(BTN_WEIGHT_HARD1 + i - 1)
		btn_weight:addTouchEventListener(btncallback)
	end

	--kc range
	for i = 1, 5 do
		local btn_kc_range = appdf.getNodeByName(self, "btn_kc_" .. i)
		btn_kc_range:setTag(BTN_KC_80 + i - 1)
		btn_kc_range:addTouchEventListener(btncallback)
	end
end

function GameAdminLayer:onButtonClickedEvent(tag, ref)
	if tag == BTN_CLOSE then
		self:removeFromParent()
	elseif tag == BTN_KUCUN then
		self._scene:onShowAdminKCLayer()
	elseif tag >= BTN_DJ_HARD1 and tag <= BTN_DJ_HARD5 then
		self._scene:onShowAdminDajiangLayer(tag - BTN_DJ_HARD1)
	elseif tag >= BTN_WEIGHT_HARD1 and tag <= BTN_WEIGHT_HARD5 then
		self._scene:onShowAdminWeightLayer(tag - BTN_WEIGHT_HARD1)
	elseif tag >= BTN_KC_80 and tag <= BTN_KC_400 then
		self._scene:onShowAdminKCRangeLayer(tag - BTN_KC_80)
	end
end

return GameAdminLayer