-- Name: GameBaoxianLayer
-- Func: 保险柜
-- Author: Johny

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")

--sublayer
local GameBaoxianLayer_Bank = appdf.req(appdf.CLIENT_SRC .. "plaza.views.layer.baoxiangui.GameBaoxianLayer_Bank")
local GameBaoxianLayer_SendCoin = appdf.req(appdf.CLIENT_SRC .. "plaza.views.layer.baoxiangui.GameBaoxianLayer_SendCoin")
local GameBaoxianLayer_EditPwd = appdf.req(appdf.CLIENT_SRC .. "plaza.views.layer.baoxiangui.GameBaoxianLayer_EditPwd")
local GameBaoxianLayer_Record = appdf.req(appdf.CLIENT_SRC .. "plaza.views.layer.baoxiangui.GameBaoxianLayer_Record")

local GameBaoxianLayer = class("GameBaoxianLayer", cc.Layer)

local BTN_CLOSE     = 1
local CBT_BANK      = 11
local CBT_SENDCOIN  = 12
local CBT_EDITPWD   = 13
local CBT_RECORD    = 14

function GameBaoxianLayer:ctor(scene)
	self._scene = scene

    ----layoutUI---------
	local btcallback = function(ref, type)
		if type == ccui.TouchEventType.ended then
			self:OnButtonClickedEvent(ref:getTag(),ref)
        end
	end

	local cbtlistener = function (sender,eventType)
    	self:onSelectedEvent(sender:getTag(),sender,eventType)
    end

	--layout
	local csbNode = ExternalFun.loadCSB("baoxian/GameBaoXianLayer.csb", self)
	self.mImg_bg = appdf.getNodeByName(csbNode, "img_bg")

	--btn
	local btn_close = appdf.getNodeByName(csbNode, "btn_close")
	btn_close:setTag(BTN_CLOSE)
	btn_close:addTouchEventListener(btcallback)

	--cbt
	self._select = CBT_BANK
	local cbt_bank = appdf.getNodeByName(csbNode, "cbt_bank")
	cbt_bank:setTag(CBT_BANK)
	cbt_bank:addEventListener(cbtlistener)
	cbt_bank:setSelected(true)

	local cbt_sendcoin = appdf.getNodeByName(csbNode, "cbt_sendcoin")
	cbt_sendcoin:setTag(CBT_SENDCOIN)
	cbt_sendcoin:addEventListener(cbtlistener)

	local cbt_editpwd = appdf.getNodeByName(csbNode, "cbt_editpwd")
	cbt_editpwd:setTag(CBT_EDITPWD)
	cbt_editpwd:addEventListener(cbtlistener)

	local cbt_record = appdf.getNodeByName(csbNode, "cbt_record")
	cbt_record:setTag(CBT_RECORD)
	cbt_record:addEventListener(cbtlistener)

	self.content = appdf.getNodeByName(csbNode, "content")
	self.mBankLayer = GameBaoxianLayer_Bank:create(self)
	self.mBankLayer:addTo(self.content)
end

--显示等待
function GameBaoxianLayer:showPopWait()
	cclog("function GameBaoxianLayer:showPopWait() ==> ")
	self._scene:showPopWait()
end

--关闭等待
function GameBaoxianLayer:dismissPopWait()
	cclog("function GameBaoxianLayer:dismissPopWait() ==> ")
	self._scene:dismissPopWait()
end


--按键响应
function GameBaoxianLayer:OnButtonClickedEvent(tag,ref)
	if tag == BTN_CLOSE then
		self:removeFromParent()
	end
end


function GameBaoxianLayer:onSelectedEvent(tag,sender,eventType)
	cclog("function GameBaoxianLayer:onSelectedEvent(tag,sender,eventType)  ==>")
	if self._select == tag then
		self.mImg_bg:getChildByTag(tag):setSelected(true)
	return end

	self._select = tag

	for i = CBT_BANK, CBT_RECORD do
		if i ~= tag  then
		   self.mImg_bg:getChildByTag(i):setSelected(false)
		end
	end

	self:onShowSubLayer(tag)
end

function GameBaoxianLayer:onShowSubLayer(tag)
	self.content:removeAllChildren()
	self.mBankLayer = nil
	self.mSendCoinLayer = nil
	self.mEditLayer = nil
	self.mRecordLayer = nil
	if tag == CBT_BANK then
		self.mBankLayer = GameBaoxianLayer_Bank:create(self)
		self.mBankLayer:addTo(self.content)
	elseif tag == CBT_SENDCOIN then
		self.mSendCoinLayer = GameBaoxianLayer_SendCoin:create(self)
		self.mSendCoinLayer:addTo(self.content)
	elseif tag == CBT_EDITPWD then
		self.mEidtLayer = GameBaoxianLayer_EditPwd:create(self)
		self.mEidtLayer:addTo(self.content)
	elseif tag == CBT_RECORD then
		self.mRecordLayer = GameBaoxianLayer_Record:create(self)
		self.mRecordLayer:addTo(self.content)
	end
end


return GameBaoxianLayer