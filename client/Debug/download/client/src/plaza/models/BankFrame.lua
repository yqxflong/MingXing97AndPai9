
local BaseFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.BaseFrame")
local BankFrame = class("BankFrame",BaseFrame)
local logincmd = appdf.req(appdf.HEADER_SRC .. "CMD_LogonServer")
local game_cmd = appdf.req(appdf.HEADER_SRC .. "CMD_GameServer")
local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")

function BankFrame:ctor(view,callbcak)
	BankFrame.super.ctor(self,view,callbcak)
end

--银行刷新
BankFrame.OP_BANK_REFRESH = 0
--银行存款
BankFrame.OP_SAVE_SCORE = 1
--银行取款
BankFrame.OP_TAKE_SCORE = 2
--银行赠送
BankFrame.OP_SEND_SCORE = 3
--银行开通
BankFrame.OP_ENABLE_BANK = 4
--银行资料
BankFrame.OP_GET_BANKINFO = 5
--查询用户
BankFrame.OP_QUERY_USER = 6
-- 长连接开通银行
BankFrame.OP_ENABLE_BANK_GAME = 7
--查询交易记录
BankFrame.OP_GET_TRANSFERRECORD = 8

--连接结果
function BankFrame:onConnectCompeleted()
	cclog("function BankFrame:onConnectCompeleted oprateCode ==>"..self._oprateCode)

	if self._oprateCode == BankFrame.OP_SAVE_SCORE then			    --存入
		self:sendSaveScore()
	elseif self._oprateCode == BankFrame.OP_TAKE_SCORE then 		--取出
		self:sendTakeScore()
	elseif self._oprateCode == BankFrame.OP_SEND_SCORE then			--赠送
		self:sendTransferScore()
	elseif self._oprateCode == BankFrame.OP_GET_TRANSFERRECORD then --查询交易记录
		self:sendGetTransferRecord()
	else
		self:onCloseSocket()
		if nil ~= self._callBack then
			self._callBack(-1,"未知操作模式！")
		end		
	end

end

--网络信息(短连接)
function BankFrame:onSocketEvent(main,sub,pData)
	cclog("function BankFrame:onSocketEvent(main,sub,pData) ==>")

	local bCloseSocket = true
	if main == logincmd.MDM_GP_USER_SERVICE then --用户服务
		if sub == logincmd.SUB_GP_USER_INSURE_INFO then
			self:onSubGetBankInfo(pData)
		elseif sub == logincmd.SUB_GP_USER_INSURE_SUCCESS then
			self:onSubInsureSuccess(pData)
		elseif sub == logincmd.SUB_GP_USER_INSURE_FAILURE then
			self:onSubInsureFailue(pData)
		elseif sub == logincmd.SUB_GP_BANK_DETAIL_RESULT then
			self:onSubRecordResult(pData)
		else
			local message = string.format("未知命令码：%d-%d",main,sub)
			if nil ~= self._callBack then
				self._callBack(-1,message);
			end			
		end
	end

	if bCloseSocket then
		self:onCloseSocket()
	end		
end

--网络消息(长连接)
function BankFrame:onGameSocketEvent(main,sub,pData)
	cclog("function BankFrame:onGameSocketEvent(main,sub,pData) ==>")
end

--银行操作成功（短连接）
function BankFrame:onSubInsureSuccess(pData)
	cclog("function BankFrame:onSubInsureSuccess(pData) ==>")
	local dwUserID = pData:readdword()
	if dwUserID == GlobalUserItem.dwUserID then
		GlobalUserItem.lUserScore= GlobalUserItem:readScore(pData)
		GlobalUserItem.lUserInsure = GlobalUserItem:readScore(pData)
		if nil ~= self._callBack then
			self._callBack(1,"操作成功！")
		end

		--通知更新        
		local eventListener = cc.EventCustom:new(yl.RY_USERINFO_NOTIFY)
	    eventListener.obj = yl.RY_MSG_USERWEALTH
	    cc.Director:getInstance():getEventDispatcher():dispatchEvent(eventListener)
	end
end
--银行操作失败（短连接）
function BankFrame:onSubInsureFailue(pData)
	cclog("function BankFrame:onSubInsureFailue(pData) ==>")

	local lError = pData:readint()
	local szError = pData:readstring()
	if nil ~= self._callBack then
		self._callBack(-1,szError)
	end	
end

--获取到银行资料
function BankFrame:onSubGetBankInfo( pData )
	cclog("function BankFrame:onSubGetBankInfo( pData ) ==>")

	local cmdtable = ExternalFun.read_netdata(logincmd.CMD_GP_UserInsureInfo, pData)
	GlobalUserItem.lUserScore = cmdtable.lUserScore
	GlobalUserItem.lUserInsure = cmdtable.lUserInsure
	if nil ~= self._callBack then
		self._callBack(BankFrame.OP_GET_BANKINFO,cmdtable)
	end	
	--通知更新        
	local eventListener = cc.EventCustom:new(yl.RY_USERINFO_NOTIFY)
    eventListener.obj = yl.RY_MSG_USERWEALTH
    cc.Director:getInstance():getEventDispatcher():dispatchEvent(eventListener)
end

--获取明细结果
function BankFrame:onSubRecordResult(pData)
	cclog("function BankFrame:onSubRecordResult( pData ) ==>")
	local ret = {}
	local size_item = 161
	local cnt = pData:getlen() / size_item
	for i = 1, cnt do
		local cmdtable = ExternalFun.read_netdata(logincmd.CMD_GP_BankDetailResult, pData)
		dump(cmdtable, "cmdtable")
		table.insert(ret, cmdtable)
	end
	if nil ~= self._callBack then
		self._callBack(BankFrame.OP_GET_TRANSFERRECORD, ret)
	end	
end
----------------------------主动----------------------------------
--存入
function BankFrame:sendSaveScore()
	cclog("function BankFrame:sendSaveScore() ==>")

	local pData = CCmd_Data:create(78)
	pData:setcmdinfo(yl.MDM_GP_USER_SERVICE,yl.SUB_GP_USER_SAVE_SCORE)
	pData:pushdword(GlobalUserItem.dwUserID)
	pData:pushscore(self._lOperateScore)
	cclog("self._lOperateScore = "..self._lOperateScore)
	pData:pushstring(GlobalUserItem.szMachine,33)
	--发送失败
	if not self:sendSocketData(pData) and nil ~= self._callBack then
		self._callBack(-1,"发送存款失败！")
	end
end

--取出
function BankFrame:sendTakeScore()
	cclog("function BankFrame:sendTakeScore() ==>")

	local pData = CCmd_Data:create(210-66)
	pData:setcmdinfo(yl.MDM_GP_USER_SERVICE,yl.SUB_GP_USER_TAKE_SCORE)
	pData:pushdword(GlobalUserItem.dwUserID)
	pData:pushscore(self._lOperateScore)
	pData:pushstring(md5(self._szPassword),33)
	-- pData:pushstring(GlobalUserItem.szDynamicPass,33)
	pData:pushstring(GlobalUserItem.szMachine,33)
		--发送失败
	if not self:sendSocketData(pData) and nil ~= self._callBack then
		self._callBack(-1,"发送取款失败！")
	end
end

--发送转账，送游戏豆
function BankFrame:sendTransferScore()
	cclog("function BankFrame:sendpData() ==>")

	local pData = CCmd_Data:create(276)
	pData:setcmdinfo(yl.MDM_GP_USER_SERVICE, yl.SUB_GP_USER_TRANSFER_SCORE)
	pData:pushdword(GlobalUserItem.dwUserID)
	pData:pushscore(self._lOperateScore)
	pData:pushstring(md5(self._szPassword), 33)
	pData:pushdword(self._targetID)
	pData:pushstring("", 32)
	pData:pushstring(GlobalUserItem.szMachineID, 33)
	pData:pushstring("", 32)

	if not self:sendSocketData(pData) and nil ~= self._callBack then
		self._callBack(-1,"发送赠送失败！")
	end
end

--发送请求交易记录
function BankFrame:sendGetTransferRecord()
	cclog("function BankFrame:sendGetTransferRecord() ==>")
	local pData = CCmd_Data:create(12)
	pData:setcmdinfo(yl.MDM_GP_USER_SERVICE, yl.SUB_GP_QUERY_BANK_DETAIL)
	pData:pushdword(GlobalUserItem.dwUserID)
	pData:pushdword(self._record_page)
	pData:pushdword(self._record_pagesize)

	if not self:sendSocketData(pData) and nil ~= self._callBack then
		self._callBack(-1,"请求交易记录失败")
	end
end

--存钱
function BankFrame:onSaveScore(lScore)
	cclog("function BankFrame:onSaveScore(lScore) ==>")

	--操作记录
	self._oprateCode = BankFrame.OP_SAVE_SCORE
	if nil ~= self._gameFrame and self._gameFrame:isSocketServer() then
		local buffer = ExternalFun.create_netdata(game_cmd.CMD_GR_C_SaveScoreRequest)
		buffer:setcmdinfo(game_cmd.MDM_GR_INSURE,game_cmd.SUB_GR_SAVE_SCORE_REQUEST)
		buffer:pushbyte(game_cmd.SUB_GR_SAVE_SCORE_REQUEST)
		buffer:pushscore(lScore)
		if not self._gameFrame:sendSocketData(buffer) then
			self._callBack(-1,"发送存款失败！")
		end
	else
		--参数记录
		self._lOperateScore = lScore
		if not self:onCreateSocket(yl.LOGONSERVER,yl.LOGONPORT) and nil ~= self._callBack then
			self._callBack(-1,"建立连接失败！")
		end
	end	
end

--取钱
function BankFrame:onTakeScore(lScore,szPassword)
	cclog("function BankFrame:onTakeScore(lScore,szPassword) ==>")

	--操作记录
	self._oprateCode = BankFrame.OP_TAKE_SCORE

	if nil ~= self._gameFrame and self._gameFrame:isSocketServer() then
		local buffer = ExternalFun.create_netdata(game_cmd.CMD_GR_C_TakeScoreRequest)
		buffer:setcmdinfo(game_cmd.MDM_GR_INSURE,game_cmd.SUB_GR_TAKE_SCORE_REQUEST)
		buffer:pushbyte(game_cmd.SUB_GR_TAKE_SCORE_REQUEST)
		buffer:pushscore(lScore)
		buffer:pushstring(md5(szPassword),yl.LEN_PASSWORD)
		if not self._gameFrame:sendSocketData(buffer) then
			self._callBack(-1,"发送取款失败！")
		end
	else
		--参数记录
		self._lOperateScore = lScore
		self._szPassword = szPassword
		if not self:onCreateSocket(yl.LOGONSERVER,yl.LOGONPORT) and nil ~= self._callBack then
			self._callBack(-1,"建立连接失败！")
		end
	end	
end

---转送游戏币
function BankFrame:onTransferCoin(lScore,szPassword, dwGameID)
	cclog("function BankFrame:onTransferCoin(lScore,target,szPassword,byID) ==>")

	--参数记录
	self._lOperateScore = lScore
	self._targetID = dwGameID
	self._szPassword = szPassword

	--操作记录
	self._oprateCode = BankFrame.OP_SEND_SCORE
	if not self:onCreateSocket(yl.LOGONSERVER,yl.LOGONPORT) and nil ~= self._callBack then
		self._callBack(-1,"建立连接失败！")
	end
end

--查询转账记录
function BankFrame:onGetTransferRecord(page, pagesize)
	cclog("function BankFrame:onGetTransferRecord() ==>")
	self._oprateCode = BankFrame.OP_GET_TRANSFERRECORD
	self._record_page = page
	self._record_pagesize = pagesize
	if not self:onCreateSocket(yl.LOGONSERVER,yl.LOGONPORT) and nil ~= self._callBack then
		self._callBack(-1,"建立连接失败！")
	end	
end

return BankFrame