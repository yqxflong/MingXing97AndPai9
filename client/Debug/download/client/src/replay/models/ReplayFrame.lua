-- Name: ReplayFrame
-- Func: 回放网络通讯代理
-- Author: Johny


local BaseFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.BaseFrame")
local ReplayFrame = class("ReplayFrame",BaseFrame)
local logincmd = appdf.req(appdf.HEADER_SRC .. "CMD_LogonServer")
local game_cmd = appdf.req(appdf.HEADER_SRC .. "CMD_GameServer")
local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")
local ReplayManager = appdf.req(appdf.CLIENT_SRC .. "replay.ReplayManager")

----------------------------常量定义---------------------------
ReplayFrame.OP_TOTALRECORD_RESULT = 1
ReplayFrame.OP_SUBRECORD_RESULT   = 2
ReplayFrame.OP_ONETIME_RESULT     = 3



function ReplayFrame:ctor(view,callbcak)
	ReplayFrame.super.ctor(self,view,callbcak)
	self:resetMember()
	self._manager = ReplayManager:getInstance()
end

function ReplayFrame:destroy()
	if self:isSocketServer() then
        self:onCloseSocket()
    end
    self:resetMember()
end

function ReplayFrame:resetMember()
	self.mReplayPkgCnt = nil
	self:resetReplayData()
	self._oprateCode = -1
	self._op_subrecord_result_param = {}
	self._op_onetime_result_param = {}
end

--里面有retain的ref需要单独清空
function ReplayFrame:resetReplayData()
	if self.mReplayData ~= nil then
	   self.mReplayData:release()
	end
	self.mReplayData = nil
end

--连接结果
function ReplayFrame:onConnectCompeleted()
	cclog("function ReplayFrame:onConnectCompeleted")
	if self._oprateCode == ReplayFrame.OP_TOTALRECORD_RESULT then
		self:sendTotalGameRecordRequest()
	elseif self._oprateCode == ReplayFrame.OP_SUBRECORD_RESULT then
		self:sendOneRecordDetailRequest(self._op_subrecord_result_param[1])
		self._op_subrecord_result_param = {}
	elseif self._oprateCode == ReplayFrame.OP_ONETIME_RESULT then
		self:sendOneTimeOperationRequest(self._op_onetime_result_param[1], self._op_onetime_result_param[2])
		self._op_onetime_result_param = {}
	else
		self:onCloseSocket()
		if nil ~= self._callBack then
			self._callBack(-1,"未知操作模式！")
		end		
	end
	self._oprateCode = -1
end

--请求建立网络连接
function ReplayFrame:requestConnect()
	if not self:onCreateSocket(yl.LOGONSERVER,yl.LOGONPORT) and nil ~= self._callBack then
		self._callBack(-1,"建立连接失败！")
	end
end

--请求获取总记录
function ReplayFrame:sendTotalGameRecordRequest()
	cclog("ReplayFrame:sendTotalGameRecordRequest==userid: " .. GlobalUserItem.dwUserID)
	local info = CCmd_Data:create(8)
	info:setcmdinfo(yl.MDM_GP_USER_SERVICE,yl.SUB_GP_GAME_RECORD_TOTAL)
	info:pushdword(GlobalUserItem.dwUserID)
	info:pushdword(0)

	self._manager.mTotalRecord = {}
	if not self:sendSocketData(info) and nil ~= self._callBack then
		self._callBack(-1,"请求获取回放总记录失败！")
	end
end

function ReplayFrame:onSendTotalGameRecordRequest()
	if self:isSocketServer() then
		self:sendTotalGameRecordRequest()
	else
		self._oprateCode = ReplayFrame.OP_TOTALRECORD_RESULT
		self:requestConnect()
	end	
end

--请求一轮记录
function ReplayFrame:sendOneRecordDetailRequest(recordid)
	cclog("ReplayFrame:sendOneRecordDetailRequest")
	local info = CCmd_Data:create(4)
	info:setcmdinfo(yl.MDM_GP_USER_SERVICE, yl.SUB_GP_GAME_RECORD_CHILD)
	info:pushdword(recordid)


	self._manager.mCurRecordId = recordid
	self._manager.mSubRecord = {}
	if not self:sendSocketData(info) and nil ~= self._callBack then
		self._manager.mCurRecordId = nil
		self._callBack(-1,"请求一轮回放记录失败！")
	end
end

function ReplayFrame:onSendOneRecordDetailRequest(recordid)
	if self:isSocketServer() then
		self:sendOneRecordDetailRequest(recordid)
	else
		self._oprateCode = ReplayFrame.OP_SUBRECORD_RESULT
		self._op_subrecord_result_param[1] = recordid
		self:requestConnect()
	end	
end

--查询一圈游戏详细操作
function ReplayFrame:sendOneTimeOperationRequest(recordid, childid)
	cclog("ReplayFrame:sendOneTimeOperationRequest==recordid: " .. recordid .. "=" .. childid)
	local info = CCmd_Data:create(8)
	info:setcmdinfo(yl.MDM_GP_USER_SERVICE, yl.SUB_GP_GAME_RECORD_CHILD_DATA)
	info:pushdword(recordid)
	info:pushdword(childid)
	---
	self._manager:resetOneTimeOperationRecord()
	self:resetReplayData()
	--提前准备好存储断数据
	self.mReplayPkgCnt = self:getOneTime(childid).m_PaketCount
	if not self:sendSocketData(info) and nil ~= self._callBack then
		self.mReplayPkgCnt = nil
		self._callBack(-1,"请求一圈游戏详细操作失败！")
	end
	
end

function ReplayFrame:onSendOneTimeOperationRequest(recordid, childid)
	if self:isSocketServer() then
		self:sendOneTimeOperationRequest(recordid, childid)
	else
		self._oprateCode = ReplayFrame.OP_ONETIME_RESULT
		self._op_onetime_result_param[1] = recordid
		self._op_onetime_result_param[2] = childid
		self:requestConnect()
	end	
end


--获取一圈
function ReplayFrame:getOneTime(childid)
	for k, one in ipairs(self._manager.mSubRecord) do
		if one.m_iRecordChildID == childid then
		   return one
		end
	end

	return nil
end

-------------------------------------call back--------------------------------
--接收网络事件
function ReplayFrame:onSocketEvent(main,sub,pData)
	cclog("function ReplayFrame:onSocketEvent "..main.." "..sub)
	if main == yl.MDM_GP_USER_SERVICE then --用户服务
		if sub == yl.SUB_GP_GAME_RECORD_TOTAL then  --返回总记录
		   self:onCollectedTotalRecord(pData)
		elseif sub == yl.SUB_GP_GAME_RECORD_TOTAL_FINISH then  --返回完结总
			self:onFinishCollectedTotalRecord(pData)
		elseif sub == yl.SUB_GP_GAME_RECORD_CHILD then --返回一轮记录
			self:onCollectedOneRecord(pData)
		elseif sub == yl.SUB_GP_GAME_RECORD_CHILD_FINISH then --返回完结一轮
			self:onFinishCollectedOneRecord(pData)
		elseif sub == yl.SUB_GP_GAME_RECORD_CHILD_DATA then --返回一回合操作记录
			self:onRecivedOneRoundOperation(pData)
		elseif sub == yl.SUB_GP_GAME_RECORD_CHILD_DATA_FINISH then --返回完结一把游戏
			self:onFinishRecivedOneTimeOperation()
		end
	end
end

--接收总记录，未收到631之前，未收集结束
--[[
	int									m_iRecordID;		//记录ID
	int									m_dwKindID;			//什么类型的游戏
	int									m_dwVersion;		//版本号
	int									m_iRoomNum;			//房间号
	int									m_nUserCount;		//玩家数量	
	SYSTEMTIME							m_StartTime;		//启始时间
	std::string							m_strRecordName;	//给予此记录一个别名

	std::stringstream					m_UsersInfoStream;	//玩家信息数据流 比如4个座位的玩家信息
	std::stringstream					m_TotalScoreStream;	//总积分信息

	例子：m_UsersInfoStream
	for (int i = 0; i < m_nUserCount; i++ )
	{
		Read (nTotalSize,4字节)
		
		Read (UserId,4字节)
		Read (ChairId,4字节)
		
		Read (NickNameLen,4字节)
		Read (strNickName,NickNameLen)
	}

	例子：m_TotalScoreStream
	for (int i = 0; i < m_nUserCount; i++ )
	{
		Read (UserId,4字节)
		Read (SCORE,8字节)
	}
]]
function ReplayFrame:onCollectedTotalRecord(pData)
	cclog("ReplayFrame:onCollectedTotalRecord")
	local oneRecord = ExternalFun.read_netdata(game_cmd.CMD_RP_S_OneRecord, pData)
	dump(oneRecord, "oneRecord")
	local strLen = pData:readdword()

	oneRecord.m_strRecordName = pData:readstring_2(strLen)
	--uinfo
	oneRecord.userinfo = {}
	for i = 1,oneRecord.m_nUserCount do
		local nTotalSize = pData:readdword()
		local oneUserInfo = {}
		oneUserInfo.UserId = pData:readdword()
		oneUserInfo.ChairId = pData:readdword()
		local NickNameLen = pData:readdword()
		oneUserInfo.strNickName = pData:readstring_2(NickNameLen)
		table.insert(oneRecord.userinfo, oneUserInfo)
	end
	--score
	oneRecord.scoretab = {}
	local int64 = Integer64.new()
	for i = 1,oneRecord.m_nUserCount do
		local uid = pData:readdword()
		local score = GlobalUserItem:readScore(pData)
		oneRecord.scoretab[tostring(uid)] = score
	end
	if self._manager.mTotalRecord[oneRecord.m_dwKindID] == nil then
	   self._manager.mTotalRecord[oneRecord.m_dwKindID] = {}
	end
	table.insert(self._manager.mTotalRecord[oneRecord.m_dwKindID], oneRecord)
end

--接收总记录完结
function ReplayFrame:onFinishCollectedTotalRecord(pData)
	cclog("ReplayFrame:onFinishCollectedTotalRecord")
	dump(self._manager.mTotalRecord, "self._manager.mTotalRecord")
	--收集结束，展示界面
	self._callBack(ReplayFrame.OP_TOTALRECORD_RESULT)
end

--接收一轮详细记录，未收到632之前，未收集结束
--[[
	int									m_iRecordID;		//等同于recordid
	int									m_iRecordChildID;	//回合ID
	int									m_iRoundNumber;		//第几圈(预留)
	int									m_iRoundType;		//没有分数时m_iRoundType  会被设置为1 否则为0 

	SYSTEMTIME							m_PlayTime;			//开始时间
	DWORD 								m_PaketCount;		//多少个数据包
	
	std::string							m_strRoundName;		//给予这个圈一个名称


    ==先 Read (TableOwner,4字节) //桌子主人
	std::stringstream m_ScoreStream;						//积分数据流
	[
		for (int i = 0; i < m_nUserCount; i++ )
		{
			Read (UserId,4字节)
			Read (lScore,8字节)
		}
	]
]]
function ReplayFrame:onCollectedOneRecord(pData)
	cclog("ReplayFrame:onCollectedOneRecord")
	local _manager = ReplayManager:getInstance()
	local oneRecord = _manager:getOneRecord(_manager.mSelectedKindID, _manager.mCurRecordId)
	local oneTime = ExternalFun.read_netdata(game_cmd.CMD_RP_S_OneRecord_OneTime, pData)
	local strLen = pData:readdword()
	oneTime.m_strRoundName = pData:readstring_2(strLen)
	oneTime.TableOwner = pData:readdword()
	oneTime.scoretab = {}
	if oneTime.m_iRoundType == 0 then--有可能没分（房间解散时）
		local int64 = Integer64.new()
		for i = 1, oneRecord.m_nUserCount do
			local uid = pData:readdword()
			local score = GlobalUserItem:readScore(pData)
			oneTime.scoretab[tostring(uid)] = score
		end
	end
	table.insert(self._manager.mSubRecord, oneTime)
end

--接收一轮详细记录完结
function ReplayFrame:onFinishCollectedOneRecord(pData)
	cclog("ReplayFrame:onFinishCollectedOneRecord")
	dump(self._manager.mSubRecord, "self.mSubRecord")
	--收集结束，展示界面
	self._callBack(ReplayFrame.OP_SUBRECORD_RESULT)
end


--接收一个回合操作
--[[
	断包
]]
function ReplayFrame:onRecivedOneRoundOperation(pData)
	local datalen = pData:getlen()
	cclog("ReplayFrame:onRecivedOneTimeOperation===datalen:  " .. datalen)
	local tmp = nil
	if self.mReplayData ~= nil then
	   local preLen = self.mReplayData:getlen()
	   local preD = self.mReplayData
	   tmp = CCmd_Data:create(preLen + datalen)
	   tmp:pushbytedata(preD)
	   preD:release()
	else
		tmp = CCmd_Data:create(datalen)
	end
	
	tmp:pushbytedata(pData)
	self.mReplayData = tmp
	self.mReplayData:retain()
end

--接收一圈游戏详细记录完结
--[[
@m_OperateStream（m_PaketCount在上一层获取）
例子：
	for (int i = 0; i < m_PaketCount; i++ )
	{
		Read (nTotalSize,4字节)
		Read (SubCmdID,4字节) //发送是什么操作命令
		Read (ChairId,4字节)  //来自哪个座位发的
		Read (UserID,4字节)   //来自哪个用户发的
		
		Read (BufferLen,4字节)
		Read (Buffer,BufferLen) //这个东西是操作的具体内容
	}
]]
function ReplayFrame:onFinishRecivedOneTimeOperation()
	local pData = self.mReplayData
	pData:resetread()
	cclog("ReplayFrame:onFinishRecivedOneTimeOperation==mReplayPkgCnt: " .. self.mReplayPkgCnt)
	for i = 1,self.mReplayPkgCnt do
		local nTotalSize = pData:readdword()
		local oneOperation = {}
		oneOperation.SubCmdID = pData:readdword()
		oneOperation.ChairId = pData:readdword()
		oneOperation.UserID = pData:readdword()
		local buffLen = pData:readdword()
		oneOperation.BufferLen = buffLen
		oneOperation.Buffer = CCmd_Data:create(buffLen)
		oneOperation.Buffer:pushbytedata(pData, buffLen)
		oneOperation.Buffer:resetread()
		oneOperation.Buffer:retain()
		table.insert(self._manager.mOneTimeOperationRecord, oneOperation)
	end
	self:resetReplayData()
	cclog("ReplayFrame:onFinishRecivedOneTimeOperation===" .. json.encode(self._manager.mOneTimeOperationRecord))
	self._callBack(ReplayFrame.OP_ONETIME_RESULT)
end

return ReplayFrame
