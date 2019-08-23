-- Name: ModifyPasswdLayer
-- Func: 密码修改界面
-- Author: Johny



local ModifyPasswdLayer = class("ModifyPasswdLayer", cc.Layer)
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local ModifyFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.ModifyFrame")

--按钮
local BT_EXIT = 101
local BT_SURE = 102
local BT_CANCEL = 103
--复选框
local CBT_LOGIN = 201
local CBT_BANK = 202

function ModifyPasswdLayer:ctor( scene )
	cclog("function ModifyPasswdLayer:ctor( scene ) ==>")

	ExternalFun.registerNodeEvent(self)
	self._scene = scene

	--加载csb资源
	local rootLayer, csbNode = ExternalFun.loadRootCSB("optionnew/ModifyPassLayer.csb", self)
	local img_bg = csbNode:getChildByName("img_bg")



	--hint
	self.mImg_loginpwd1 = appdf.getNodeByName(img_bg, "img_loginpwd1")
	self.mImg_loginpwd2 = appdf.getNodeByName(img_bg, "img_loginpwd2")
	self.mImg_bankpwd1 = appdf.getNodeByName(img_bg, "img_bankpwd1")
	self.mImg_bankpwd2 = appdf.getNodeByName(img_bg, "img_bankpwd2")
	
	local function btncallback(ref, type)
        if type == ccui.TouchEventType.ended then
         	self:onButtonClickedEvent(ref:getTag(),ref)
        end
    end     
    --返回按钮
    local btn = appdf.getNodeByName(img_bg, "btn_return")
    btn:setTag(BT_EXIT)
    btn:addTouchEventListener(btncallback)
    --确定按钮
    btn = appdf.getNodeByName(img_bg, "btn_okedit")
    btn:setTag(BT_SURE)
    btn:addTouchEventListener(btncallback)
    --取消按钮
    btn = appdf.getNodeByName(img_bg, "btn_canceledit")
    btn:setTag(BT_CANCEL)
    btn:addTouchEventListener(btncallback)

    local function checkEvent( sender,eventType )
		self:onCheckBoxClickEvent(sender, eventType);
	end
	--修改登录密码
	self.m_checkLogin = appdf.getNodeByName(img_bg, "check_pwd")
	self.m_checkLogin:setTag(CBT_LOGIN)
	self.m_checkLogin:addEventListener(checkEvent)
	self.m_checkLogin:setSelected(true)

	--当前选择的box
	self.m_nSelectBox = CBT_LOGIN

	--旧密码编辑
	local tmp = appdf.getNodeByName(img_bg, "img_input_1")
	local editbox = ccui.EditBox:create(cc.size(tmp:getContentSize().width - 10, tmp:getContentSize().height - 10),"blank.png")
		:setPosition(tmp:getPosition())
		:setFontName("fonts/yuanti_sc_light.ttf")
		:setPlaceholderFontName("fonts/yuanti_sc_light.ttf")
		:setFontSize(30)
		:setPlaceholderFontSize(30)
		:setPlaceholderFontColor(yl.G_COLOR_INPUT_PLACEHOLDER)
		:setFontColor(yl.G_COLOR_INPUT_FONT)
		:setMaxLength(26)
		:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:setPlaceHolder("请输入您的旧登录密码")
	img_bg:addChild(editbox)
	self.m_editOldPass = editbox
	--新密码编辑
	tmp = appdf.getNodeByName(img_bg, "img_input_2")
	editbox = ccui.EditBox:create(cc.size(tmp:getContentSize().width - 10, tmp:getContentSize().height - 10),"blank.png")
		:setPosition(tmp:getPosition())
		:setFontName("fonts/yuanti_sc_light.ttf")
		:setPlaceholderFontName("fonts/yuanti_sc_light.ttf")
		:setFontSize(30)
		:setPlaceholderFontSize(30)
		:setPlaceholderFontColor(yl.G_COLOR_INPUT_PLACEHOLDER)
		:setFontColor(yl.G_COLOR_INPUT_FONT)
		:setMaxLength(26)
		:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:setPlaceHolder("请输入您的新登录密码")
	img_bg:addChild(editbox)
	self.m_editNewPass = editbox
	--确认密码编辑
	tmp = appdf.getNodeByName(img_bg, "img_input_3")
	editbox = ccui.EditBox:create(cc.size(tmp:getContentSize().width - 10, tmp:getContentSize().height - 10),"blank.png")
		:setPosition(tmp:getPosition())
		:setFontName("fonts/yuanti_sc_light.ttf")
		:setPlaceholderFontName("fonts/yuanti_sc_light.ttf")
		:setFontSize(30)
		:setPlaceholderFontSize(30)
		:setPlaceholderFontColor(yl.G_COLOR_INPUT_PLACEHOLDER)
		:setFontColor(yl.G_COLOR_INPUT_FONT)
		:setMaxLength(26)
		:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:setPlaceHolder("请再次输入您的新登录密码")
	img_bg:addChild(editbox)
	self.m_editConfirmPass = editbox

	--网络回调
    local modifyCallBack = function(result,message)
		self:onModifyCallBack(result,message)
	end
    --网络处理
	self._modifyFrame = ModifyFrame:create(self,modifyCallBack)
end

function ModifyPasswdLayer:onButtonClickedEvent( tag, ref )
	cclog("function ModifyPasswdLayer:onButtonClickedEvent( tag, ref ) ==>")

	if BT_EXIT == tag then
		self._scene:onKeyBack()
	elseif BT_SURE == tag then
		local var, tips = self:confirmPasswd()
		if false == var then
			showToast(self, tips, 2)
			return
		end
		local oldpass = self.m_editOldPass:getText()
		local newpass = self.m_editNewPass:getText()
		if CBT_LOGIN == self.m_nSelectBox then
			if GlobalUserItem.bVistor then
				showToast(self, "游客不能修改登录密码!", 2)
				return
			end
			if GlobalUserItem.bWeChat then
				showToast(self, "游客不能修改登录密码!", 2)
				return
			end
			self._modifyFrame:onModifyLogonPass(oldpass, newpass)
		elseif CBT_BANK == self.m_nSelectBox then
			-- 银行不同登陆
			if string.lower(newpass) == string.lower(GlobalUserItem.szPassword) then
				showToast(self, "银行密码不能与登录密码一致!", 2)
				return
			end
			self._modifyFrame:onModifyBankPass(oldpass, newpass)
		end
	elseif BT_CANCEL == tag then
		self:clearEdit()
	end
end

function ModifyPasswdLayer:onCheckBoxClickEvent(sender, eventType)
	cclog("function ModifyPasswdLayer:onCheckBoxClickEvent(sender, eventType) ==>")

	if nil == sender then
		return
	end

	local oldstr = ""
	local newstr = ""
	local oldTips = ""
	local newTips = ""
	local confirmTips = ""
	if sender:isSelected() then
		self.m_nSelectBox = CBT_LOGIN
		self.mImg_loginpwd1:setVisible(true)	
		self.mImg_loginpwd2:setVisible(true)
		self.mImg_bankpwd1:setVisible(false)
		self.mImg_bankpwd2:setVisible(false)
		oldTips = "输入您的旧登录密码"
		newTips = "输入您的新登录密码"
		confirmTips = "请再次输入您的新登录密码"
	else
		self.m_nSelectBox = CBT_BANK
		self.mImg_loginpwd1:setVisible(false)	
		self.mImg_loginpwd2:setVisible(false)
		self.mImg_bankpwd1:setVisible(true)
		self.mImg_bankpwd2:setVisible(true)
		oldTips = "输入您的旧银行密码"
		newTips = "输入您的新银行密码"
		confirmTips = "请再次输入您的新银行密码"
	end

	--刷新界面
	self.m_editOldPass:setPlaceHolder(oldTips)
	self.m_editNewPass:setPlaceHolder(newTips)
	self.m_editConfirmPass:setPlaceHolder(confirmTips)
	self:clearEdit()
end

function ModifyPasswdLayer:onModifyCallBack( result, tips )
	cclog("function ModifyPasswdLayer:onModifyCallBack( result, tips ) ==>")

	if type(tips) == "string" and "" ~= tips then
		showToast(self, tips, 2)
	end
	
	if -1 ~= result then
		self:clearEdit()
	end
end

function ModifyPasswdLayer:clearEdit(  )

	cclog("function ModifyPasswdLayer:clearEdit(  ) ==>")

	self.m_editOldPass:setText("")
	self.m_editNewPass:setText("")
	self.m_editConfirmPass:setText("")
end

function ModifyPasswdLayer:confirmPasswd()

	cclog("function ModifyPasswdLayer:confirmPasswd() ==>")

	local oldpass = self.m_editOldPass:getText()
	local newpass = self.m_editNewPass:getText()
	local confirm = self.m_editConfirmPass:getText()

	local oldlen = string.len(oldpass)
	if 0 == oldlen then
		return false, "原始密码不能为空"
	end

	if oldlen > 26 or oldlen < 6 then
		return false, "原始密码请输入6-26位字符"
	end
	
	local md5old =  md5(oldpass)
	if self.m_nSelectBox == CBT_LOGIN then
		if oldpass ~= GlobalUserItem.szPassword then
			return false, "您输入的原登录密码有误"
		end
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

	-- 首位为字母
	--[[if 1 ~= string.find(newpass, "%a") then
		return false, "密码首位必须为字母，请重新输入！"
	end]]

	-- 与帐号不同
	if string.lower(newpass) == string.lower(GlobalUserItem.szAccount) then
		return false, "密码不能与帐号相同，请重新输入！"
	end

	return true
end

function ModifyPasswdLayer:onExit()
	cclog("function ModifyPasswdLayer:onExit() ==>")
	if self._modifyFrame:isSocketServer() then
		self._modifyFrame:onCloseSocket()
	end
end

return ModifyPasswdLayer