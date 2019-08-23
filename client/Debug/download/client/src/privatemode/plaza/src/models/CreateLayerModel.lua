-- Name: CreateLayerModel
-- Func: 私房创建基类
-- Author: Johny


local CreateLayerModel = class("CreateLayerModel", cc.Layer)
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local cmd_private = appdf.req(appdf.CLIENT_SRC .. "privatemode.header.CMD_Private")

function CreateLayerModel:ctor(scene)
    cclog("function CreateLayerModel:ctor(scene)==>")
    ExternalFun.registerNodeEvent(self)
    self._scene = scene
    self._cmd_pri_login = cmd_private.login
    self._cmd_pri_game = cmd_private.game
end

-- 刷新界面
function CreateLayerModel:onRefreshInfo()
    cclog("function CreateLayerModel:onRefreshInfo() --> base refresh")
end

-- 获取邀请分享内容
function CreateLayerModel:getInviteShareMsg( roomDetailInfo )
    cclog("function CreateLayerModel:getInviteShareMsg( roomDetailInfo ) ==> base get invite")
    return {title = "", content = ""}
end

------
-- 网络消息
-------- 
-- 私人房登陆完成
function CreateLayerModel:onLoginPriRoomFinish()
    cclog("function CreateLayerModel:onLoginPriRoomFinish() -->")

    cclog("base login finish")
    return false
end

return CreateLayerModel