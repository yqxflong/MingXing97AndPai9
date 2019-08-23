-- Name: GameAdminKCRangeLayer
-- Func: 库存区间
-- Author: Johny

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC.."ExternalFun")
local module_pre = "game.mingxing97.src"
local  cmd = appdf.req(module_pre..".models.CMD_Game")


local GameAdminKCRangeLayer = class("GameAdminKCRangeLayer",function(scene)
        local GameAdminKCRangeLayer =  cc.CSLoader:createNode(cmd.RES_PATH.."admin/KucqjLayer.csb")
    return GameAdminKCRangeLayer
end)

local BTN_CLOSE=1
local BTN_SET=11

function GameAdminKCRangeLayer:ctor(scene, hardlevel)
    self._scene = scene
    self._hardLevel = hardlevel

    local function btncallback(ref,tType)
        if tType ==ccui.TouchEventType.ended then
            self:onButtonClickedEvent(ref:getTag(),ref)
        end
    end

    local btn_close = appdf.getNodeByName(self,"btn_close")
    btn_close:setTag(BTN_CLOSE)
    btn_close:addTouchEventListener(btncallback)

    local btn_set = appdf.getNodeByName(self,"btn_sz_1")
    btn_set:setTag(BTN_SET)
    btn_set:addTouchEventListener(btncallback)

    for i = 1, 4 do
        local theinput = appdf.getNodeByName(self,"base_input_"..i)
        local theEditBox = ccui.EditBox:create(theinput:getContentSize(),"blank.png")
        :move(theinput:getPosition())
        :setAnchorPoint(cc.p(0.5,0.5))
        :setFontSize(24)  --编辑框的大小
        :setPlaceholderFontSize(24)  --默认字体大小
        :setPlaceholderFontColor(yl.G_COLOR_INPUT_PLACEHOLDER)
        :setFontColor(yl.G_COLOR_INPUT_FONT)
        :setMaxLength(31)
        :setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
        :addTo(theinput:getParent())
        :setName("input_"..i)
    end

    self._scene:onSendControlSetting(hardlevel + 13)
end




function GameAdminKCRangeLayer:onButtonClickedEvent(tag,ref)
    if tag==BTN_CLOSE then
        self._scene.mAdminKCRangeLayer = nil
        self:removeFromParent()
    elseif tag==BTN_SET then
        local arr ={}
        for i = 1, 4 do
            local theEditBox = appdf.getNodeByName(self,"input_"..i)
            table.insert(arr,theEditBox:getText())
        end
        self._scene:onSendKcqjSetting(self._hardLevel,arr)
    end
end

function GameAdminKCRangeLayer:onRefresh(cmd_data)
    if cmd_data.cbControlType ~= self._hardLevel then return end
    for i =1, 4 do
        local theEditBox = appdf.getNodeByName(self,"input_" .. i)
        theEditBox:setText("" .. cmd_data.iStockScoreSection[1][i])
    end
end

return GameAdminKCRangeLayer