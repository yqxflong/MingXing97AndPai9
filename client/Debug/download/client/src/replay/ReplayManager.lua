-- Name: ReplayManager
-- Func: 战绩管理器
-- Author: Johny

local ReplayManager = class("ReplayManager")

--实现单例
ReplayManager._instance = nil

function ReplayManager:getInstance()
    if nil == ReplayManager._instance then
        ReplayManager._instance = ReplayManager:create()
    end
    return ReplayManager._instance
end

function ReplayManager:resetMember()
	self.mClientScene = nil
	self.mSelectedKindID = nil
	--
	self.mTotalRecord = {}
	self.mSubRecord = {}
	self:resetOneTimeOperationRecord()
	--
	self.mCurRecordId = nil
	self.mCurChildId = nil
	self.mChairTable = {}
end

function ReplayManager:ctor()
	self:resetMember()
end

function ReplayManager:setClientScene(_scene)
	self.mClientScene = _scene
end

--获取当前子游戏文件夹
function ReplayManager:getCurKindFolder()
	local modulestr = yl.getSubGameFolder(tostring(self.mSelectedKindID))
	return modulestr
end

--清空一圈操作记录
function ReplayManager:resetOneTimeOperationRecord()
	if self.mOneTimeOperationRecord then
		for k, oneOp in ipairs(self.mOneTimeOperationRecord) do
			oneOp.Buffer:release()
			oneOp.Buffer = nil
		end
	end
	self.mOneTimeOperationRecord = {}
end

--检查子游戏资源
function ReplayManager:checkSubGameRes()
	local gameinfo = self.mClientScene:getGameInfo(self.mSelectedKindID)
	local app = self.mClientScene:getApp()
	local version = tonumber(app:getVersionMgr():getResVersion(self.mSelectedKindID))
	if not version or gameinfo._ServerResVersion > version then
		showToast(self.mClientScene, "未找到相应的游戏资源或资源已过期，请去大厅点击游戏下载", 3)
		return false
	end
	return true
end


--找到对应子游戏进入
function ReplayManager:enterReplay()
	cclog("ReplayManager:enterReplay====>" .. self.mSelectedKindID)
	--先判断是否有资源
	if self:checkSubGameRes() then
		self:initSetting()
		local modulestr = self:getCurKindFolder()
		if modulestr then
			local param = {}
			param.kindfolder = modulestr
			self.mClientScene:onChangeShowMode(yl.SCENE_GAME_REPLAY, param)
		else
			doAssert("can not find: " .. self.mSelectedKindID)
		end
	end
end

function ReplayManager:initSetting()
	local oneRecord = self:getOneRecord(self.mSelectedKindID, self.mCurRecordId)
	--算出玩家数量
	self.mPlayerCnt = oneRecord.m_nUserCount
	--找出自己的椅子,收集椅子
	for k, uinfo in ipairs(oneRecord.userinfo) do
		if uinfo.UserId == GlobalUserItem.dwUserID then
		   self.mMyChairID = uinfo.ChairId 
		end
		table.insert(self.mChairTable, uinfo.ChairId)
	end
end

--获取位置数组
function ReplayManager:getChairTable()
	return self.mChairTable
end

--获取玩家数
function ReplayManager:GetChairCount()
	return self.mPlayerCnt
end

-- 获取自己椅子
function ReplayManager:GetMeChairID()
    return self.mMyChairID
end

--获取桌子用户
function ReplayManager:getTableUserItem(chairid)
	cclog("function ReplayManager:getTableUserItem(tableid,chairid) ==> ")
	local oneRecord = self:getOneRecord(self.mSelectedKindID, self.mCurRecordId)
	for k, uinfo in ipairs(oneRecord.userinfo) do
		if uinfo.ChairId == chairid then
		   local item = {}
		   item.dwGameID = uinfo.UserId
		   item.ChairId = uinfo.ChairId
		   item.szNickName = uinfo.strNickName
		   item.lScore = 0
		   item.cbUserStatus = yl.US_READY

		   return item
		end
	end
end


--获取一个record
function ReplayManager:getOneRecord(kindid, recordid)
	local recordArr = self.mTotalRecord[kindid]
	for k,one in ipairs(recordArr) do
		if one.m_iRecordID == recordid then
		   return one
		end
	end

	return nil
end


--获取当前房间id
function ReplayManager:getCurRecordRoomID()
	local record = self:getOneRecord(self.mSelectedKindID, self.mCurRecordId)
	return record.m_iRoomNum
end

--获取当前第几局
function ReplayManager:getCurRoundNum()
	for k,oneTime in ipairs(self.mSubRecord) do
		if oneTime.m_iRecordChildID == self.mCurChildId then
		   return oneTime.m_iRoundNumber
		end
	end
end

return ReplayManager