-- Name: PriGameLayer
-- Func: 私房顶层
-- Author: Johny


local PrivateLayerModel = appdf.req(PriRoom.MODULE.PLAZAMODULE .."models.PrivateLayerModel")
local PriGameLayer = class("PriGameLayer", PrivateLayerModel)
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local PopupInfoHead = appdf.req(appdf.EXTERNAL_SRC .. "PopupInfoHead")
local ClipText = appdf.req(appdf.EXTERNAL_SRC .. "ClipText")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")

--
local BTN_DISMISS = 101
local BTN_INVITE = 102
local BTN_SHARE = 103
local BTN_QUIT = 104
local BTN_ZANLI = 105


--根据读取资源模式添加路径
local RES_PATH = device.writablePath .. "download/game/paijiu/privatemode/res/"


function PriGameLayer:ctor( gameLayer )
    PriGameLayer.super.ctor(self, gameLayer)
    --添加沙盒路径
    cc.FileUtils:getInstance():addSearchPath(RES_PATH)
end

------
-- 继承/覆盖
------
-- 刷新界面
function PriGameLayer:onRefreshInfo()
   cclog("PriGameLayer:onRefreshInfo===>")
   self._gameLayer:onRefreshInfo()
end

function PriGameLayer:onRefreshInviteBtn()
  
end

-- 私人房游戏结束
function PriGameLayer:onPriGameEnd( cmd_table )
	cclog("PriGameLayer:onPriGameEnd===>" .. json.encode(cmd_table))
    local function priEnd()
        local csbNode = ExternalFun.loadCSB("room/GameEndLayer.csb", self)

        --离开游戏
        local btn_exit = appdf.getNodeByName(csbNode, "btn_exit")
        btn_exit:addTouchEventListener(function (ref, tType)
                if tType == ccui.TouchEventType.ended then
                    GlobalUserItem.bWaitQuit = false
                    self._gameLayer:onExitRoom()
                end  
            end)
        -- 玩家成绩
        dump(self._gameLayer.mUserItemArr, "self._gameLayer.mUserItemArr")
        local scoreList = cmd_table.lScore[1]
        for i = 1, 4 do
            local useritem = self._gameLayer.mUserItemArr[i - 1]
            if useritem then
                local score = scoreList[i] or 0
                local node_player = appdf.getNodeByName(csbNode, "node_player" .. i)
                node_player:setVisible(true)
                node_player:getChildByName("lb_name"):setString(useritem.szNickName)
                node_player:getChildByName("lb_id"):setString(useritem.dwGameID)
                if score >= 0 then
                    node_player:getChildByName("lb_score"):setString("+" .. score)
                    node_player:getChildByName("lb_score"):setTextColor(cc.c4b(0, 0, 255, 255))
                else
                    node_player:getChildByName("lb_score"):setString("" .. score)
                    node_player:getChildByName("lb_score"):setTextColor(cc.c4b(255, 0, 0, 255))
                end
                -- 头像
                local img_headbg = node_player:getChildByName("img_headbg")
                local head = PopupInfoHead:createNormal(useritem, 70)
                head:setPosition(cc.p(img_headbg:getContentSize().width* 0.5, img_headbg:getContentSize().height*0.5))
                img_headbg:addChild(head)
            end
        end
    end
    self:runAction(cc.Sequence:create(cc.DelayTime:create(2.0), cc.CallFunc:create(priEnd)))
    self._gameLayer:setWaitPriEnd(true)
end

function PriGameLayer:onExit()
    --移除该子模块搜索路径
    GG_RemoveSearchPath(RES_PATH)
end

return PriGameLayer