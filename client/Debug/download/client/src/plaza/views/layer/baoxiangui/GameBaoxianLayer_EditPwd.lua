-- Name: GameBaoxianLayer_EditPwd
-- Func: 保险柜-密码
-- Author: Johny

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local ModifyFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.ModifyFrame")

local GameBaoxianLayer_EditPwd = class("GameBaoxianLayer_EditPwd", cc.Layer)

local BTN_OK = 1

function GameBaoxianLayer_EditPwd:ctor(scene)
	self._scene = scene

	self:layoutUI()

	--网络回调
    local modifyCallBack = function(result,message)
    	if self.onModifyCallBack then
			self:onModifyCallBack(result,message)
		end
	end
    --网络处理
	self._modifyFrame = ModifyFrame:create(self,modifyCallBack)
end

function GameBaoxianLayer_EditPwd:layoutUI()
	local btcallback = function(ref, type)
		if type == ccui.TouchEventType.ended then
			self:OnButtonClickedEvent(ref:getTag(),ref)
        end
	end

	local csbNode = ExternalFun.loadCSB("baoxian/layer_editpwd.csb", self)

	--oldpwd
	local img_input_oldpwd = appdf.getNodeByName(csbNode, "img_input_oldpwd")
	self.edit_oldpwd = ccui.EditBox:create(img_input_oldpwd:getContentSize(), "blank.png")
		:move(img_input_oldpwd:getPosition())
		:setAnchorPoint(cc.p(0,0.5))
		:setFontSize(18)
		:setPlaceholderFontSize(18)
		:setMaxLength(31)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
		:setPlaceHolder("旧密码")
		:addTo(csbNode)

	--newpwd
	local img_input_newpwd = appdf.getNodeByName(csbNode, "img_input_newpwd")
	self.edit_newpwd = ccui.EditBox:create(img_input_newpwd:getContentSize(), "blank.png")
		:move(img_input_newpwd:getPosition())
		:setAnchorPoint(cc.p(0,0.5))
		:setFontSize(18)
		:setPlaceholderFontSize(18)
		:setMaxLength(31)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
		:setPlaceHolder("新密码")
		:addTo(csbNode)	

	--surepwd
	local img_input_surepwd = appdf.getNodeByName(csbNode, "img_input_surepwd")
	self.edit_surepwd = ccui.EditBox:create(img_input_surepwd:getContentSize(), "blank.png")
		:move(img_input_surepwd:getPosition())
		:setAnchorPoint(cc.p(0,0.5))
		:setFontSize(18)
		:setPlaceholderFontSize(18)
		:setMaxLength(31)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
		:setPlaceHolder("确认新密码")
		:addTo(csbNode)	

	--btn
	local btn_ok = appdf.getNodeByName(csbNode, "btn_ok")
	btn_ok:setTag(BTN_OK)
	btn_ok:addTouchEventListener(btcallback)
end

function GameBaoxianLayer_EditPwd:confirmPasswd()
	cclog("function GameBaoxianLayer_EditPwd:confirmPasswd() ==>")

	local oldpass = self.edit_oldpwd:getText()
	local newpass = self.edit_newpwd:getText()
	local confirm = self.edit_surepwd:getText()

	local oldlen = string.len(oldpass)
	if 0 == oldlen then
		return false, "原始密码不能为空"
	end

	if oldlen > 26 or oldlen < 6 then
		return false, "原始密码请输入6-26位字符"
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
function GameBaoxianLayer_EditPwd:OnButtonClickedEvent(tag,ref)
	if tag == BTN_OK then
		local var, tips = self:confirmPasswd()
		if false == var then
			showToast(self._scene, tips, 2)
			return
		end
		local oldpass = self.edit_oldpwd:getText()
		local newpass = self.edit_newpwd:getText()
		-- 银行不同登陆
		if string.lower(newpass) == string.lower(GlobalUserItem.szPassword) then
			showToast(self._scene, "银行密码不能与登录密码一致!", 2)
			return
		end
		self._modifyFrame:onModifyBankPass(oldpass, newpass)
	end
end

function GameBaoxianLayer_EditPwd:onModifyCallBack( result, tips )
	cclog("function GameBaoxianLayer_EditPwd:onModifyCallBack( result, tips ) ==>")

	if type(tips) == "string" and "" ~= tips then
		showToast(self._scene, tips, 2)
	end
	
	if -1 ~= result then
		self.edit_oldpwd:setText("")
		self.edit_newpwd:setText("")
		self.edit_surepwd:setText("")
	end
end

return GameBaoxianLayer_EditPwd