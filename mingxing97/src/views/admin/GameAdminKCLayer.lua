-- Name: GameAdminKCLayer
-- Func: 库存
-- Author: Johny

local ExternalFun =  appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local module_pre = "game.mingxing97.src"
local cmd = appdf.req(module_pre .. ".models.CMD_Game")

local GameAdminKCLayer = class("GameAdminKCLayer",function(scene)
		local GameAdminKCLayer =  cc.CSLoader:createNode(cmd.RES_PATH.."admin/KucunLayer.csb")
    return GameAdminKCLayer
end)

local BTN_CLOSE = 1
-- local BTN_QUERY_80 = 11
-- local BTN_QUERY_160 = 12
-- local BTN_QUERY_240 = 13
-- local BTN_QUERY_320 = 14
-- local BTN_QUERY_400 = 15
local BTN_SET_80  = 21
local BTN_SET_160 = 22
local BTN_SET_240 = 23
local BTN_SET_320 = 24
local BTN_SET_400 = 25
local BTN_CHOUSHUI_PER = 31 --抽水千分
local BTN_CHOUSHUI_NUM = 32 --抽水数值
local BTN_MEINV = 41        --美女

function GameAdminKCLayer:ctor(scene)
	self._scene = scene

	local function btncallback(ref, tType)
        if tType == ccui.TouchEventType.ended then
            self:onButtonClickedEvent(ref:getTag(),ref)
        end
    end

	--[[btn]]--
	local btn_close = appdf.getNodeByName(self, "btn_close")
	btn_close:setTag(BTN_CLOSE)
	btn_close:addTouchEventListener(btncallback)

	--query
	-- for i = 1, 5 do
	-- 	local theQuery = appdf.getNodeByName(self, "btn_cx_" .. i)
	-- 	theQuery:setTag(BTN_QUERY_80 + i - 1)
	-- 	theQuery:addTouchEventListener(btncallback)
	-- end

	--setting
	for i = 1, 5 do
		local theSet = appdf.getNodeByName(self, "btn_sz_" .. i)
		theSet:setTag(BTN_SET_80 + i - 1)
		theSet:addTouchEventListener(btncallback)
	end

	--抽水
	local btn_cs_per = appdf.getNodeByName(self, "btn_sz_6")
	btn_cs_per:setTag(BTN_CHOUSHUI_PER)
	btn_cs_per:addTouchEventListener(btncallback)

	local btn_cs_num = appdf.getNodeByName(self, "btn_sz_7")
	btn_cs_num:setTag(BTN_CHOUSHUI_NUM)
	btn_cs_num:addTouchEventListener(btncallback)

	--美女
	local btn_meinv = appdf.getNodeByName(self, "btn_sz_8")
	btn_meinv:setTag(BTN_MEINV)
	btn_meinv:addTouchEventListener(btncallback)

	--[[editbox]]--
	for i = 1, 11 do
		local theinput = appdf.getNodeByName(self, "base_input_" .. i)
		local theEditBox = ccui.EditBox:create(theinput:getContentSize(), "blank.png")
		:move(theinput:getPosition())
		:setAnchorPoint(cc.p(0.5,0.5))
		:setFontSize(24)
		:setPlaceholderFontSize(24)
		:setPlaceholderFontColor(yl.G_COLOR_INPUT_PLACEHOLDER)
		:setFontColor(yl.G_COLOR_INPUT_FONT)
		:setMaxLength(31)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:addTo(theinput:getParent())
		:setName("input_" .. i)
	end

	--查询库存
	self._scene:onSendControlSetting(23)
end


function GameAdminKCLayer:onButtonClickedEvent(tag, ref)
	if tag == BTN_CLOSE then
		self._scene.mAdminKCLayer = nil
		self:removeFromParent()
	--elseif tag >= BTN_QUERY_80 and tag <= BTN_QUERY_400 then

	elseif tag >= BTN_SET_80 and tag <= BTN_SET_400 then
		local theEditBox = appdf.getNodeByName(self,"input_".. tag - BTN_SET_80 + 1)
		self._scene:onSendKcSetting(tag - BTN_SET_80, theEditBox:getText())
	elseif tag == BTN_CHOUSHUI_PER then
		local theEditBox = appdf.getNodeByName(self,"input_6")
		self._scene:onSendKcSetting(5, theEditBox:getText())

	elseif tag == BTN_CHOUSHUI_NUM then
		local theEditBox = appdf.getNodeByName(self,"input_7")
		self._scene:onSendKcSetting(6, theEditBox:getText())

	elseif tag == BTN_MEINV then
		local arr = {}
		for i =8, 11 do
			local theEditBox = appdf.getNodeByName(self,"input_"..i)
			table.insert(arr,theEditBox:getText())
		end
		self._scene:onSendMeinvSetting(arr)
	end
end


function GameAdminKCLayer:onRefresh(cmd_data)
    --if cmd_data.cbControlType ~= self._hardLevel then return end
    cclog("GameAdminKCLayer:onRefresh")
    for i =1, 5 do
        local theEditBox = appdf.getNodeByName(self,"input_" .. i)
        theEditBox:setText("" .. cmd_data.lStockScore[1][i])
    end
	for i=1,4 do
		local theEditBox =appdf.getNodeByName(self,"input_".. i + 7)
		theEditBox:setText("" .. cmd_data.iGirlOutProbability[1][i])
	end
	local theEditBox =appdf.getNodeByName(self,"input_6")
	theEditBox:setText("" .. cmd_data.lStorageDeduct)

	local theEditBox =appdf.getNodeByName(self,"input_7")
	theEditBox:setText("" .. cmd_data.lStockWin)
end
return GameAdminKCLayer