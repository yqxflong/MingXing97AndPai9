-- Name: GameBaoxianLayer_SendCoin
-- Func: 保险柜-银行
-- Author: Johny

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local BankFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.BankFrame")

local GameBaoxianLayer_SendCoin = class("GameBaoxianLayer_SendCoin", cc.Layer)

local BTN_OK = 1

function GameBaoxianLayer_SendCoin:ctor(scene)
	self._scene = scene
	self:layoutUI()
	--网络回调
    local  bankCallBack = function(result,message)
    	if self.onBankCallBack then
			self:onBankCallBack(result,message)
		end
	end
	--网络处理
	self._bankFrame = BankFrame:create(self, bankCallBack)
end

function GameBaoxianLayer_SendCoin:layoutUI()
	local btcallback = function(ref, type)
		if type == ccui.TouchEventType.ended then
			self:OnButtonClickedEvent(ref:getTag(),ref)
        end
	end

	local editHanlder = function(event,editbox)
		self:onEditEvent(event,editbox)
	end

	local csbNode = ExternalFun.loadCSB("baoxian/layer_sendcoin.csb", self)

	--sendid
	local img_input_id = appdf.getNodeByName(csbNode, "img_input_id")
	self.edit_id = ccui.EditBox:create(img_input_id:getContentSize(), "blank.png")
		:move(img_input_id:getPosition())
		:setAnchorPoint(cc.p(0,0.5))
		:setFontSize(18)
		:setPlaceholderFontSize(18)
		:setMaxLength(31)
		:setInputMode(cc.EDITBOX_INPUT_MODE_NUMERIC)
		:setPlaceHolder("赠送id")
		:addTo(csbNode)

	--sendcoin
	local img_input_sendcoin = appdf.getNodeByName(csbNode, "img_input_sendcoin")
	self.edit_opcoin = ccui.EditBox:create(img_input_sendcoin:getContentSize(), "blank.png")
		:move(img_input_sendcoin:getPosition())
		:setAnchorPoint(cc.p(0,0.5))
		:setFontSize(18)
		:setPlaceholderFontSize(18)
		:setMaxLength(31)
		:setInputMode(cc.EDITBOX_INPUT_MODE_NUMERIC)
		:setPlaceHolder("赠送金币")
		:addTo(csbNode)	
	self.edit_opcoin:registerScriptEditBoxHandler(editHanlder)

	--pwd
	local img_input_pwd = appdf.getNodeByName(csbNode, "img_input_pwd")
	self.edit_pwd = ccui.EditBox:create(img_input_pwd:getContentSize(), "blank.png")
		:move(img_input_pwd:getPosition())
		:setAnchorPoint(cc.p(0,0.5))
		:setFontSize(18)
		:setPlaceholderFontSize(18)
		:setMaxLength(31)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
		:setPlaceHolder("保险柜密码")
		:addTo(csbNode)	

	--btn
	local btn_oksend = appdf.getNodeByName(csbNode, "btn_oksend")
	btn_oksend:setTag(BTN_OK)
	btn_oksend:addTouchEventListener(btcallback)

	--bignum
	self.mLbBig = appdf.getNodeByName(csbNode, "lb_big_num")
	self.mLbBig:setString("")
end

--按键响应
function GameBaoxianLayer_SendCoin:OnButtonClickedEvent(tag,ref)
	if tag == BTN_OK then
		local strID = string.gsub(self.edit_id:getText(), " ", "")
		local szScore = string.gsub(self.edit_opcoin:getText(), "([^0-9])","")
		local strPwd = string.gsub(self.edit_pwd:getText(), " ", "")

		strID = string.gsub(strID, "[.]", "")
		if #strID < 1 then
			showToast(self,"请输入正确的赠送ID！",2)
			return
		end	
		local lSendID = tonumber(strID)

	    szScore = string.gsub(szScore, "[.]", "")
		if #szScore < 1 then 
			showToast(self,"请输入操作金额！",2)
			return
		end

		local lOperateScore = tonumber(szScore)
		if lOperateScore < 1 then
			showToast(self,"请输入正确金额！",2)
			return
		end

	    if lOperateScore > GlobalUserItem.lUserScore then
	        showToast(self,"您所携带金币的数目余额不足,请重新输入金币数量!",2)
	        return
	    end	

	    if strPwd == "" then
	    	showToast(self, "保险柜密码不能为空!", 2)
	    	return
	    end

		self._scene:showPopWait()
		self._bankFrame:onTransferCoin(lOperateScore, strPwd, lSendID)    
	end
end

--输入框监听
function GameBaoxianLayer_SendCoin:onEditEvent(event,editbox)
	cclog("function GameBaoxianLayer_SendCoin:onEditEvent(event,editbox) ==> ")

	if event == "changed" then

	elseif event == "return" then
		local src = editbox:getText()
		local num = tonumber(src)
		if num and num >= 0 then
			self.mLbBig:setString(ExternalFun.numberTransiform(num))
		end
	end
end


--操作结果
function GameBaoxianLayer_SendCoin:onBankCallBack(result,message)
	cclog("function GameBaoxianLayer_SendCoin:onBankCallBack(result,message) ==> ")

	self._scene:dismissPopWait()
	if  message ~= nil and message ~= "" then
		showToast(self._scene,message,2)
	end
    --存取成功
	if result == 1 then
		self.edit_id:setText("")
		self.edit_opcoin:setText("")
		self.mLbBig:setString("")
		self.edit_pwd:setText("")
		--更新大厅
		self._scene._scene._coin:setString("" .. GlobalUserItem.lUserScore)
	end
end


return GameBaoxianLayer_SendCoin