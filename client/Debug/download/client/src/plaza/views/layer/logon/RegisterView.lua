-- Name: RegisterView
-- Func: 注册界面
-- Author: Johny

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")

local RegisterView = class("RegisterView",function(scene)
    local  RegisterView = cc.CSLoader:createNode("login/RegisterView.csb")
    return RegisterView
end)

RegisterView.BT_CLOSE    = 1
RegisterView.BT_REGISTER = 2


function RegisterView:ctor()
	cclog("function RegisterView:ctor() ==>")

	local  btcallback = function(ref, type)
        if type == ccui.TouchEventType.ended then
         	self:onButtonClickedEvent(ref:getTag(),ref)
        end
    end

    local img_bg = appdf.getNodeByName(self, "img_bg")

    --close
    local btn_close = appdf.getNodeByName(self, "btn_close")
    btn_close:setTag(RegisterView.BT_CLOSE)
    btn_close:addTouchEventListener(btcallback)

	--账号输入
	local img_input_acc = img_bg:getChildByName("img_input_acc")
	self.edit_Account = ccui.EditBox:create(img_input_acc:getContentSize(), "blank.png")
		:move(img_input_acc:getPosition())
		:setAnchorPoint(cc.p(0,0.5))
		:setFontSize(24)
		:setPlaceholderFontSize(18)
		:setPlaceholderFontColor(yl.G_COLOR_INPUT_PLACEHOLDER)
		:setMaxLength(31)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:setPlaceHolder("6-31位字符")
		:addTo(img_bg)

	--密码输入	
	local img_input_pwd = img_bg:getChildByName("img_input_pwd")
	self.edit_Password = ccui.EditBox:create(img_input_pwd:getContentSize(), "blank.png")
		:move(img_input_pwd:getPosition())
		:setAnchorPoint(cc.p(0,0.5))
		:setFontSize(24)
		:setPlaceholderFontSize(18)
		:setPlaceholderFontColor(yl.G_COLOR_INPUT_PLACEHOLDER)
		:setMaxLength(26)
		:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:setPlaceHolder("6-26位英文字母，数字，下划线组合")
		:addTo(img_bg)


	--确认密码输入	
	local img_input_confirm = img_bg:getChildByName("img_input_confirm")
	self.edit_RePassword = ccui.EditBox:create(img_input_confirm:getContentSize(), "blank.png")
		:move(img_input_confirm:getPosition())
		:setAnchorPoint(cc.p(0,0.5))
		:setFontSize(24)
		:setPlaceholderFontSize(18)
		:setPlaceholderFontColor(yl.G_COLOR_INPUT_PLACEHOLDER)
		:setMaxLength(26)
		:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:setPlaceHolder("6-26位英文字母，数字，下划线组合")
		:addTo(img_bg)

	--注册按钮
	local btn_register = img_bg:getChildByName("btn_register")
		:setTag(RegisterView.BT_REGISTER)
		:addTouchEventListener(btcallback)
end


function RegisterView:onButtonClickedEvent(tag,ref)
	cclog("function RegisterView:onButtonClickedEvent(tag,ref) ==>")

	if tag == RegisterView.BT_CLOSE then
		self:removeFromParent()
	elseif tag == RegisterView.BT_REGISTER then
		-- 判断 非 数字、字母、下划线、中文 的帐号
		local szAccount = self.edit_Account:getText()
		local filter = string.find(szAccount, "^[a-zA-Z0-9_\128-\254]+$")
		if nil == filter then
			showToast(self, "帐号包含非法字符, 请重试!", 1)
			return
		end
		szAccount = string.gsub(szAccount, " ", "")
		local szPassword = string.gsub(self.edit_Password:getText(), " ", "")
		local szRePassword = string.gsub(self.edit_RePassword:getText(), " ", "")
		self:getParent():getParent():onRegister(szAccount,szPassword,szRePassword, true, "")
	end
end

function RegisterView:setAgreement(bAgree)
	cclog("function RegisterView:setAgreement(bAgree) ==>")

	self.cbt_Agreement:setSelected(bAgree)
end

return RegisterView