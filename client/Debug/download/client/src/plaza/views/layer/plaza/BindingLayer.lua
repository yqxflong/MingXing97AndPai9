-- Name: BindingLayer
-- Func: 账号绑定界面
-- Author: Johny


local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local ModifyFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.ModifyFrame")
local QueryDialog = require("app.views.layer.other.QueryDialog")
local NotifyMgr = appdf.req(appdf.EXTERNAL_SRC .. "NotifyMgr")



local BindingLayer = class("BindingLayer", cc.Layer)



BindingLayer.BT_BINDING			= 15
BindingLayer.BT_BINDINGREGISTER = 16

-- 进入场景而且过渡动画结束时候触发。
function BindingLayer:onEnterTransitionFinish()

	cclog("function BindingLayer:onEnterTransitionFinish() ==> ")

    return self
end

-- 退出场景而且开始过渡动画时候触发。
function BindingLayer:onExitTransitionStart()

	cclog("function BindingLayer:onExitTransitionStart() ==> ")

    return self
end

function BindingLayer:ctor(scene)

	cclog("function BindingLayer:ctor(scene) ==> ")

	local this = self

	self._scene = scene
	
	self:registerScriptHandler(function(eventType)
		if eventType == "enterTransitionFinish" then	-- 进入场景而且过渡动画结束时候触发。
			self:onEnterTransitionFinish()
		elseif eventType == "exitTransitionStart" then	-- 退出场景而且开始过渡动画时候触发。
			self:onExitTransitionStart()
        elseif eventType == "exit" then
            if self._modifyFrame:isSocketServer() then
                self._modifyFrame:onCloseSocket()
            end
		end
	end)

	--按钮回调
	self._btcallback = function(ref, type)
        if type == ccui.TouchEventType.ended then
         	this:onButtonClickedEvent(ref:getTag(),ref)
        end
    end

    --网络回调
    local modifyCallBack = function(result,message)
		this:onModifyCallBack(result,message)
	end
    --网络处理
	self._modifyFrame = ModifyFrame:create(self,modifyCallBack)

    local csbNode = ExternalFun.loadCSB("register/BindingLayer.csb", self)
    local img_bg = csbNode:getChildByName("img_bg")

    --返回
    local btn_return = img_bg:getChildByName("btn_return")
	btn_return:addTouchEventListener(function(ref, type)
       		 	if type == ccui.TouchEventType.ended then
					this._scene:onKeyBack()
				end
			end)

    --账号输入
    local img_acc_input = img_bg:getChildByName("img_acc_input")
	self.edit_Account = ccui.EditBox:create(img_acc_input:getContentSize(), "blank.png")
		:move(img_acc_input:getPosition())
		:setFontName("fonts/yuanti_sc_light.ttf")
		:setPlaceholderFontName("fonts/yuanti_sc_light.ttf")
		:setFontSize(24)
        :setPlaceholderFontColor(yl.G_COLOR_INPUT_PLACEHOLDER)
        :setFontColor(yl.G_COLOR_INPUT_FONT)
		:setMaxLength(32)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:addTo(img_bg)

	--密码输入	
    local img_pwd_input = img_bg:getChildByName("img_pwd_input")
	self.edit_Password = ccui.EditBox:create(img_pwd_input:getContentSize(), "blank.png")
		:move(img_pwd_input:getPosition())
		:setFontName("fonts/yuanti_sc_light.ttf")
		:setPlaceholderFontName("fonts/yuanti_sc_light.ttf")
		:setFontSize(24)
        :setPlaceholderFontColor(yl.G_COLOR_INPUT_PLACEHOLDER)
        :setFontColor(yl.G_COLOR_INPUT_FONT)
		:setMaxLength(32)
		:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:addTo(img_bg)

	--绑定按钮
    local btn_okbind = img_bg:getChildByName("btn_okbind")
	btn_okbind:setTag(BindingLayer.BT_BINDING)
	btn_okbind:addTouchEventListener(self._btcallback)

end

--按键监听
function BindingLayer:onButtonClickedEvent(tag,sender)
	cclog("function BindingLayer:onButtonClickedEvent(tag,sender) ==> ")

	if tag == BindingLayer.BT_BINDING then
        local szAccount = self.edit_Account:getText()
        local szPassword = self.edit_Password:getText()
        --输入检测
        if szAccount == nil then
            showToast(self,"游戏帐号必须为6~31个字符，请重新输入！",2,cc.c4b(250,0,0,255))
            return
        end
        if nil == szPassword then
            showToast(self,"密码必须大于6个字符，请重新输入！",2,cc.c4b(250,0,0,255))
            return 
        end
        local len = #szAccount
        if len < 6 or len > 31 then
            showToast(self,"游戏帐号必须为6~31个字符，请重新输入！",2,cc.c4b(250,0,0,255))
            return
        end

        len = #szPassword
        if  len<6 then
            showToast(self,"密码必须大于6个字符，请重新输入！",2,cc.c4b(250,0,0,255))
            return
        end
        self.szAccount = szAccount
        self.szPassword = szPassword

        local tips = "绑定帐号后该游客信息将与新帐号合并，游客帐号将会被注销，绑定成功之后需要重新登录,是否绑定帐号?"
        self._queryDialog = QueryDialog:create(tips, function(ok)
            if ok == true then                
                self:bindingAccount()
            end
            self._queryDialog = nil
        end):setCanTouchOutside(false)
            :addTo(self)
	elseif tag == BindingLayer.BT_BINDINGREGISTER then
        self._scene:onChangeShowMode(yl.SCENE_BINDINGREG)
    end
end

--操作结果
function BindingLayer:onModifyCallBack(result,message)
	cclog("function ======== BindingLayer::onModifyCallBack ========")

	self._scene:dismissPopWait()
	if  message ~= nil and message ~= "" then
		showToast(self,message,2);
	end

	if result == 2 then
        self._scene:showPopWait()
        GlobalUserItem.setBindingAccount()
        GlobalUserItem.szPassword = self.szPassword
        GlobalUserItem.szAccount = self.szAccount
        --保存数据
        GlobalUserItem.onSaveAccountConfig()

        self:runAction(cc.Sequence:create(cc.DelayTime:create(1.0), cc.CallFunc:create(function ()
            self._scene:dismissPopWait()
                  
            --重新登录
            GlobalUserItem.nCurRoomIndex = -1
            self:getParent():getParent():getApp():enterSceneEx(appdf.CLIENT_SRC.."plaza.views.LogonScene","FADE",1)
            GlobalUserItem.reSetData()
            --读取配置
            GlobalUserItem.LoadData()
            --断开好友服务器
            FriendMgr:getInstance():reSetAndDisconnect()
            --通知管理
            NotifyMgr:getInstance():clear()
            end)))
	end
end

function BindingLayer:bindingAccount()
	cclog("function BindingLayer:bindingAccount() ==> ")

    self._scene:showPopWait()
    cclog(self.szPassword)
    self._modifyFrame:onAccountBinding(self.szAccount, md5(self.szPassword))
end

return BindingLayer