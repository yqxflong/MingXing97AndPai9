-- Name: GameBaoxianLayer_Bank
-- Func: 保险柜-银行
-- Author: Johny

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local BankFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.BankFrame")

local GameBaoxianLayer_Bank = class("GameBaoxianLayer_Bank", cc.Layer)

local BTN_SAVE = 1
local BTN_LOAD = 2

function GameBaoxianLayer_Bank:ctor(scene)
	self._scene = scene
	self:layoutUI()
	self:loadInfo()
	--网络回调
    local  bankCallBack = function(result,message)
    	if self.onBankCallBack then
			self:onBankCallBack(result,message)
		end
	end

	--网络处理
	self._bankFrame = BankFrame:create(self, bankCallBack)
end

function GameBaoxianLayer_Bank:loadInfo()
	self.mLbID:setString("" .. GlobalUserItem.dwGameID)
	self.mLbName:setString(GlobalUserItem.szNickName)
	self.mLbCash:setString("" .. GlobalUserItem.lUserScore)
	self.mLbDebit:setString("" .. GlobalUserItem.lUserInsure)
end

function GameBaoxianLayer_Bank:layoutUI()
	local btcallback = function(ref, type)
		if type == ccui.TouchEventType.ended then
			self:OnButtonClickedEvent(ref:getTag(),ref)
        end
	end

	local csbNode = ExternalFun.loadCSB("baoxian/layer_bank.csb", self)

	--opcoin
	local img_input_opcoin = appdf.getNodeByName(csbNode, "img_input_opcoin")
	self.edit_opcoin = ccui.EditBox:create(img_input_opcoin:getContentSize(), "blank.png")
		:move(img_input_opcoin:getPosition())
		:setAnchorPoint(cc.p(0,0.5))
		:setFontSize(18)
		:setPlaceholderFontSize(18)
		:setMaxLength(31)
		:setInputMode(cc.EDITBOX_INPUT_MODE_NUMERIC)
		:setPlaceHolder("金币数量")
		:addTo(csbNode)

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

	--id
	self.mLbID = appdf.getNodeByName(csbNode, "lb_id_value")

	--name
	self.mLbName = appdf.getNodeByName(csbNode, "lb_name_value")

	--cash
	self.mLbCash = appdf.getNodeByName(csbNode, "lb_cash_value")

	--debit
	self.mLbDebit = appdf.getNodeByName(csbNode, "lb_debit_value")

	--btn
	local btn_save = appdf.getNodeByName(csbNode, "btn_save")
	btn_save:setTag(BTN_SAVE)
	btn_save:addTouchEventListener(btcallback)

	local btn_load = appdf.getNodeByName(csbNode, "btn_load")
	btn_load:setTag(BTN_LOAD)
	btn_load:addTouchEventListener(btcallback)
end

---------------------主动--------------------------
--存款
function GameBaoxianLayer_Bank:onSaveScore(coin)
	cclog("function GameBaoxianLayer_Bank:onSaveScore() ==> ")

	--参数判断
	local szScore =  string.gsub(coin, "([^0-9])","")	
    szScore = string.gsub(szScore, "[.]", "")
	if #szScore < 1 then 
		showToast(self,"请输入操作金额！",2)
		return
	end
	
	local lOperateScore = tonumber(szScore)
	
	if lOperateScore<1 then
		showToast(self,"请输入正确金额！",2)
		return
	end

    if lOperateScore > GlobalUserItem.lUserScore then
        showToast(self,"您所携带金币的数目余额不足,请重新输入金币数量!",2)
        return
    end

	self._scene:showPopWait()
	self._bankFrame:onSaveScore(lOperateScore)
end

--取款操作
function GameBaoxianLayer_Bank:onTakeScore(coin, szPass)
	cclog("function GameBaoxianLayer_Bank:onTakeScore() ==> ")

	--参数判断
	local szScore =  string.gsub(coin, "([^0-9])","")
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

    if lOperateScore > GlobalUserItem.lUserInsure then
        showToast(self,"您保险柜金币的数目余额不足,请重新输入金币数量！",2)
        return
    end

	if #szPass < 1 then 
		showToast(self,"请输入保险柜密码！",2)
		return
	end
	if #szPass <6 then
		showToast(self,"密码必须大于6个字符，请重新输入！",2)
		return
	end

	self._scene:showPopWait()
	self._bankFrame:onTakeScore(lOperateScore, szPass)
end

--按键响应
function GameBaoxianLayer_Bank:OnButtonClickedEvent(tag,ref)
	if tag == BTN_SAVE then
		self:onSaveScore(self.edit_opcoin:getText())
	elseif tag == BTN_LOAD then
		self:onTakeScore(self.edit_opcoin:getText(), self.edit_pwd:getText())
	end
end

function GameBaoxianLayer_Bank:onRefreshInfo()
	self.edit_opcoin:setText("")
	self.edit_pwd:setText("")
	self:loadInfo()
end

--操作结果
function GameBaoxianLayer_Bank:onBankCallBack(result,message)
	cclog("function GameBaoxianLayer_Bank:onBankCallBack(result,message) ==> ")

	self._scene:dismissPopWait()
	if  message ~= nil and message ~= "" then
		showToast(self._scene,message,2)
	end
    --存取成功
	if result == 1 then
		self:onRefreshInfo()
		--更新大厅
		self._scene._scene._coin:setString("" .. GlobalUserItem.lUserScore)
	end
end


return GameBaoxianLayer_Bank