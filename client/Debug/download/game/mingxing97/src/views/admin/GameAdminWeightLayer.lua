-- Name: GameAdminWeightLayer
-- Func: 权重
-- Author: Johny


local ExternalFun =  appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local module_pre = "game.mingxing97.src"
local cmd = appdf.req(module_pre .. ".models.CMD_Game")


local GameAdminWeightLayer = class("GameAdminWeightLayer",function(scene)
    local  GameAdminWeightLayer = cc.CSLoader:createNode(cmd.RES_PATH.."admin/QuanzhongLayer.csb")
    return GameAdminWeightLayer
end)

local BTN_CLOSE=1
local BTN_SET=11

function GameAdminWeightLayer:ctor(scene, hardlevel)
    self._scene = scene
    self._hardLevel = hardlevel

    local function btncallback(ref,tTye)
        if tTye == ccui.TouchEventType.ended then
             self:onButtonClickedEvent(ref:getTag(),ref)
        end
    end


    local  btn_close = appdf.getNodeByName(self,"btn_close")
    btn_close:setTag(BTN_CLOSE)
    btn_close:addTouchEventListener(btncallback)

    local btn_set = appdf.getNodeByName(self,"btn_qz1")
    btn_set:setTag(BTN_SET)
    btn_set:addTouchEventListener(btncallback)

    for i =1,27 do
        local theiput = appdf.getNodeByName(self,"base_input_"..i)
        local theEditBox = ccui.EditBox:create(theiput:getContentSize(),"blank.png")
        :move(theiput:getPosition())
        :setAnchorPoint(cc.p(0.5,0.5))
        :setFontSize(24)
        :setPlaceholderFontSize(24)
        :setPlaceholderFontColor(yl.G_COLOR_INPUT_PLACEHOLDER)
        :setFontColor(yl.G_COLOR_INPUT_FONT)
        :setMaxLength(31)   --限制输入的长度
        :setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
        :addTo(theiput:getParent())
        :setName("input_"..i)
    end

    --查询库存
    self._scene:onSendControlSetting(hardlevel + 8)

end

function GameAdminWeightLayer:onButtonClickedEvent(tag,ref )
     if tag==BTN_CLOSE then
        self._scene.mAdminWeightLayer = nil
        self:removeFromParent()
    elseif tag==BTN_SET then
        local arr ={}
        for i = 1, 27 do
            local theEditBox = appdf.getNodeByName(self,"input_"..i)
            table.insert(arr,theEditBox:getText())
        end
        self._scene:onSendWeightSetting(self._hardLevel,arr)
    end
end

function GameAdminWeightLayer:onRefresh(cmd_data)
    if cmd_data.cbControlType ~= self._hardLevel then return end
    for i =1, 27 do
        local theEditBox = appdf.getNodeByName(self,"input_" .. i)
        theEditBox:setText("" .. cmd_data.iReelWeight[1][i])
    end
end

return GameAdminWeightLayer