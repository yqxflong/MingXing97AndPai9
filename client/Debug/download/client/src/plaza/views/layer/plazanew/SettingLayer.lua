-- Name: SettingLayer
-- Func: 设置界面
-- Author: Johny

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")
local ModifyFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.ModifyFrame")

local SettingLayer = class("SettingLayer", cc.Layer)

local BTN_CLOSE     = 1
local BTN_EXIT      = 2
local BTN_OK        = 3

function SettingLayer:ctor(scene)
	self._scene = scene

	--网络回调
    local modifyCallBack = function(result,message)
		self:onModifyCallBack(result,message)
	end
    --网络处理
	self._modifyFrame = ModifyFrame:create(self,modifyCallBack)

	--layoutui
	local btcallback = function(ref, type)
		if type == ccui.TouchEventType.ended then
			self:OnButtonClickedEvent(ref:getTag(),ref)
        end
	end

	local editHanlder = function(event,editbox)
		self:onEditEvent(event,editbox)
	end

	--layout
	local csbNode = ExternalFun.loadCSB("setting/GameSettingLayer.csb", self)

	--close
	local btn_close = appdf.getNodeByName(csbNode, "btn_close")
	btn_close:setTag(BTN_CLOSE)
	btn_close:addTouchEventListener(btcallback)

	--exit
	local btn_switch = appdf.getNodeByName(csbNode, "btn_switch")
	btn_switch:setTag(BTN_EXIT)
	btn_switch:addTouchEventListener(btcallback)

	--ok
	local btn_ok = appdf.getNodeByName(csbNode, "btn_ok")
	btn_ok:setTag(BTN_OK)
	btn_ok:addTouchEventListener(btcallback)

	--name
	local input_editname = appdf.getNodeByName(csbNode, "input_editname")
	self.edit_name = ccui.EditBox:create(input_editname:getContentSize(), "blank.png")
		:move(input_editname:getPosition())
		:setAnchorPoint(cc.p(0,0.5))
		:setFontSize(18)
		:setPlaceholderFontSize(18)
		:setMaxLength(31)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:addTo(input_editname:getParent())	
	self.edit_name:registerScriptEditBoxHandler(editHanlder)
	self.edit_name:setText(GlobalUserItem.szNickName)


	--oldpwd
	local input_oldpwd = appdf.getNodeByName(csbNode, "input_oldpwd")
	self.edit_oldpwd = ccui.EditBox:create(input_oldpwd:getContentSize(), "blank.png")
		:move(input_oldpwd:getPosition())
		:setAnchorPoint(cc.p(0,0.5))
		:setFontSize(18)
		:setPlaceholderFontSize(18)
		:setMaxLength(31)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
		:setPlaceHolder("旧密码")
		:addTo(input_oldpwd:getParent())

	--newpwd
	local input_newpwd = appdf.getNodeByName(csbNode, "input_newpwd")
	self.edit_newpwd = ccui.EditBox:create(input_newpwd:getContentSize(), "blank.png")
		:move(input_newpwd:getPosition())
		:setAnchorPoint(cc.p(0,0.5))
		:setFontSize(18)
		:setPlaceholderFontSize(18)
		:setMaxLength(31)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
		:setPlaceHolder("新密码")
		:addTo(input_newpwd:getParent())

	--okpwd
	local input_oknewpwd = appdf.getNodeByName(csbNode, "input_oknewpwd")
	self.edit_oknewpwd = ccui.EditBox:create(input_oknewpwd:getContentSize(), "blank.png")
		:move(input_oknewpwd:getPosition())
		:setAnchorPoint(cc.p(0,0.5))
		:setFontSize(18)
		:setPlaceholderFontSize(18)
		:setMaxLength(31)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
		:setPlaceHolder("确认新密码")
		:addTo(input_oknewpwd:getParent())

end

function SettingLayer:confirmPasswd()
	cclog("function SettingLayer:confirmPasswd() ==>")

	local oldpass = self.edit_oldpwd:getText()
	local newpass = self.edit_newpwd:getText()
	local confirm = self.edit_oknewpwd:getText()

	local oldlen = string.len(oldpass)
	if 0 == oldlen then
		return false, "原始密码不能为空"
	end

	if oldlen > 26 or oldlen < 6 then
		return false, "原始密码请输入6-26位字符"
	end
	
	if oldpass ~= GlobalUserItem.szPassword then
		return false, "您输入的原登录密码有误"
	end

	local newlen = ExternalFun.stringLen(newpass)
	if 0 == newlen then
		return false, "新密码不能为空!"
	end

	if newlen > 26 or newlen < 6 then
		return false, "新密码请输入6-26位字符"
	end

	--空格
	local b,e = string.find(newpass, " ")
	if b ~= e then
		return false, "新密码不能输入空格字符,请重新输入"
	end

	--新旧密码
	if oldpass == newpass then
		return false, "新密码与原始密码一致,请重新输入"
	end

	--密码确认
	if newpass ~= confirm then
		return false, "两次输入的密码不一致,请重新输入"
	end

	-- 与帐号不同
	if string.lower(newpass) == string.lower(GlobalUserItem.szAccount) then
		return false, "密码不能与帐号相同，请重新输入！"
	end

	return true
end

--按键响应
function SettingLayer:OnButtonClickedEvent(tag,ref)
	if tag == BTN_CLOSE then
		self:removeFromParent()
	elseif tag == BTN_EXIT then
		self._scene:ExitClient()
	elseif tag == BTN_OK then
		local var, tips = self:confirmPasswd()
		if false == var then
			showToast(self, tips, 2)
			return
		end
		local oldpass = self.edit_oldpwd:getText()
		local newpass = self.edit_newpwd:getText()
		if GlobalUserItem.bWeChat then
			showToast(self, "微信用户不能修改登录密码!", 2)
			return
		end
		self._modifyFrame:onModifyLogonPass(oldpass, newpass)
	end
end

--输入框监听
function SettingLayer:onEditEvent(event,editbox)
	cclog("function SettingLayer:onEditEvent(event,editbox) ==> ")
	if event == "changed" then

	elseif event == "return" then
		local szNickname = string.gsub(editbox:getText(), " ", "")
		--发送修改昵称
        --判断长度
		if ExternalFun.stringLen(szNickname) < 6 then
			showToast(self, "游戏昵称必须大于6位以上,请重新输入!", 2)
			editbox:setText(GlobalUserItem.szNickName)
			return
		end
		--判断emoji
		if ExternalFun.isContainEmoji(szNickname) then
			showToast(self, "昵称中包含非法字符,请重试", 2)
			editbox:setText(GlobalUserItem.szNickName)
			return
		end
		--判断是否有非法字符
		if true == ExternalFun.isContainBadWords(szNickname) then
			showToast(self, "昵称中包含敏感字符,请重试", 2)
			editbox:setText(GlobalUserItem.szNickName)
			return
		end
		if szNickname == GlobalUserItem.szNickName then
			return
		end
		self:showPopWait()
		self.szNickName = szNickname
		self._modifyFrame:onModifyUserInfo(GlobalUserItem.cbGender, szNickname, "")
	end
end

--操作结果
function SettingLayer:onModifyCallBack(result,message)
	cclog("function SettingLayer:onModifyCallBack(result,message) ==>")
	self:dismissPopWait()
	if  message ~= nil and message ~= "" then
		showToast(self,message,2)
	end

	if result == 1 and self.szNickName then
		GlobalUserItem.szNickname = self.szNickName
		self.szNickName = nil
		self._scene._name:setString(GlobalUserItem.szNickname)
	end

	if -1 ~= result and self.szNickName == nil then
		self.edit_oldpwd:setText("")
		self.edit_newpwd:setText("")
		self.edit_oknewpwd:setText("")
	end
end

--显示等待
function SettingLayer:showPopWait()
	cclog("function SettingLayer:showPopWait() ==>")
	self._scene:showPopWait()
end

--关闭等待
function SettingLayer:dismissPopWait()
	cclog("function SettingLayer:dismissPopWait() ==>")
	self._scene:dismissPopWait()
end


return SettingLayer
