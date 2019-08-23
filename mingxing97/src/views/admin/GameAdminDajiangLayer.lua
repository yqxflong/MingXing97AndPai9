-- Name: GameAdminDajiangLayer
-- Func: 大奖
-- Author: Johny

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .."ExternalFun")
local module_pre= "game.mingxing97.src"
local cmd = appdf.req(module_pre ..".models.CMD_Game")


local GameAdminDajiangLayer= class("GameAdminDajiangLayer",function(scene, hardlevel)
        local GameAdminDajiangLayer= cc.CSLoader:createNode(cmd.RES_PATH.."admin/DajiangLayer.csb")
        return GameAdminDajiangLayer
        end)


local BTN_CLOSE=1
local BTN_SET=11



function GameAdminDajiangLayer:ctor(scene,hardlevel)
    self._scene = scene
    self._hardLevel = hardlevel


    local function btncallback(ref, tType)
        if tType == ccui.TouchEventType.ended then
            self:onButtonClickedEvent(ref:getTag(),ref)
        end
    end

    local cbtlistener = function (sender,eventType)
        self:onSelectedEvent(sender,eventType)
    end

    --关闭按钮
    local btn_close= appdf.getNodeByName(self,"btn_close")
    btn_close:setTag(BTN_CLOSE)
    btn_close:addTouchEventListener(btncallback)

    --Editbox
    for i =1,14 do
        local theiput = appdf.getNodeByName(self,"base_input_"..i)
        local theEditBox = ccui.EditBox:create(theiput:getContentSize(), "blank.png")
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

    local btn_set = appdf.getNodeByName(self,"btn_dj_sz")
    btn_set:setTag(BTN_SET)
    btn_set:addTouchEventListener(btncallback)

    self._scene:onSendControlSetting(hardlevel + 18)
end

function GameAdminDajiangLayer:onButtonClickedEvent(tag,ref)
    if tag==BTN_CLOSE then
        self._scene.mAdminDajiangLayer = nil
        self:removeFromParent()
    elseif tag == BTN_SET then
        local arr = {}
        for i = 1,14 do
            local theEditBox = appdf.getNodeByName(self,"input_"..i)
            table.insert(arr, theEditBox:getText())
        end
        self._scene:onSendDajiangSetting(self._hardLevel, arr)
    end
end

function GameAdminDajiangLayer:onRefresh(cmd_data)
if cmd_data.cbControlType ~= self._hardLevel then return end
    for i =1, 14 do
        local theEditBox = appdf.getNodeByName(self,"input_" .. i)
        theEditBox:setText("" .. cmd_data.ProbabilityLottery[1][i])
    end
end



return GameAdminDajiangLayer
