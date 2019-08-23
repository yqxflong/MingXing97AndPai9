-- Name: LogonView
-- Func: 登录界面布局
-- Author: Johny
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")


local LogonView = class("LogonView",function(scene)
    local  LogonView = cc.CSLoader:createNode("login/LogonView.csb")
    return LogonView
end)

--
LogonView.BT_WECHAT	  = 1
LogonView.BT_ACCLOGIN = 2
LogonView.BT_REGISTER = 3
LogonView.BT_FORGET   = 4
--
LogonView.CBT_RECORD  = 11


function LogonView:ctor(scene)
	cclog("function LogonView:ctor(serverConfig) ==>")
	self:setContentSize(yl.WIDTH,yl.HEIGHT)

	local  btcallback = function(ref, type)
        if type == ccui.TouchEventType.ended then
         	self:onButtonClickedEvent(ref:getTag(),ref)
        end
    end

    local editHanlder = function ( name, sender )
		self:onEditEvent(name, sender)
	end

	self._scene = scene

	--wechat
	local btn_wechat = appdf.getNodeByName(self, "btn_wechat")
	btn_wechat:setTag(LogonView.BT_WECHAT)
	btn_wechat:addTouchEventListener(btcallback)

	--account
	local btn_acclogin = appdf.getNodeByName(self, "btn_acclogin")
	btn_acclogin:setTag(LogonView.BT_ACCLOGIN)
	btn_acclogin:addTouchEventListener(btcallback)

	--register
	local btn_register = appdf.getNodeByName(self, "btn_register")
	btn_register:setTag(LogonView.BT_REGISTER)
	btn_register:addTouchEventListener(btcallback)

	--forget
	local btn_forget = appdf.getNodeByName(self, "btn_forget")
	btn_forget:setTag(LogonView.BT_FORGET)
	btn_forget:addTouchEventListener(btcallback)

	--editbox-acc
    local theiput = appdf.getNodeByName(self, "img_input_acc")
    self.edit_Account = ccui.EditBox:create(theiput:getContentSize(), "blank.png")
        :move(theiput:getPosition())
        :setAnchorPoint(cc.p(0,0.5))
        :setFontSize(24)
        :setPlaceholderFontSize(24)
        :setPlaceholderFontColor(yl.G_COLOR_INPUT_PLACEHOLDER)
        :setMaxLength(31)   --限制输入的长度
        :setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
        :addTo(theiput:getParent())


    --editbox-pwd
   	theiput = appdf.getNodeByName(self, "img_input_pwd")
    self.edit_Password = ccui.EditBox:create(theiput:getContentSize(), "blank.png")
        :move(theiput:getPosition())
        :setAnchorPoint(cc.p(0,0.5))
        :setFontSize(24)
        :setPlaceholderFontSize(24)
        :setPlaceholderFontColor(yl.G_COLOR_INPUT_PLACEHOLDER)
        :setMaxLength(31)   --限制输入的长度
        :setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
        :setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
        :addTo(theiput:getParent())


    --record
	self.cbt_Record = appdf.getNodeByName(self, "check_record")
	self.cbt_Record:setSelected(GlobalUserItem.bSavePassword)
	self.cbt_Record:setTag(LogonView.CBT_RECORD)
end

function LogonView:onReLoadUser()
	cclog("function LogonView:onReLoadUser() ==>")
	if GlobalUserItem.szAccount ~= nil and GlobalUserItem.szAccount ~= "" then
		self.edit_Account:setText(GlobalUserItem.szAccount)
	else
		self.edit_Account:setPlaceHolder("请输入您的游戏帐号")
	end

	if GlobalUserItem.szPassword ~= nil and GlobalUserItem.szPassword ~= "" then
		self.edit_Password:setText(GlobalUserItem.szPassword)
	else
		self.edit_Password:setPlaceHolder("请输入您的游戏密码")
	end
end

function LogonView:onEditEvent(name, editbox)
	cclog("function LogonView:onEditEvent(name, editbox) ==>")
	if "changed" == name then
		if editbox:getText() ~= GlobalUserItem.szAccount then
			self.edit_Password:setText("")
		end		
	end
end

function LogonView:onButtonClickedEvent(tag,ref)
	cclog("function LogonView:onButtonClickedEvent(tag,ref) ==>" .. tag)
	if tag == LogonView.BT_WECHAT then
		self:onLogon_Wechat()
	elseif tag == LogonView.BT_ACCLOGIN then
		self:onLogon_Acc()
	elseif tag == LogonView.BT_REGISTER then
		self:onRegister()
	elseif tag == LogonView.BT_FORGET then
		self:onForget()
	end
end

function LogonView:onLogon_Wechat()
	--平台判定
	local targetPlatform = cc.Application:getInstance():getTargetPlatform()
	if (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform) or (cc.PLATFORM_OS_ANDROID == targetPlatform) then
		self:getParent():getParent():thirdPartyLogin(yl.ThirdParty.WECHAT)
	end
end

function LogonView:onLogon_Acc()
	local szAccount = string.gsub(self.edit_Account:getText(), " ", "")
	local szPassword = string.gsub(self.edit_Password:getText(), " ", "")
	cclog("LogonView:onLogon_Acc====>" .. szAccount .. "=" .. szPassword)
	local bAuto = self.cbt_Record:isSelected()
	local bSave = self.cbt_Record:isSelected()
	self:getParent():getParent():onLogon(szAccount,szPassword,bSave, bAuto)
end

function LogonView:onRegister()
	self:getParent():getParent():onShowRegister()
end

function LogonView:onForget()
	
end

return LogonView