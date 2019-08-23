-- Name: SubGameUpdateAgent
-- Func: 子游戏更新代理（单例）
-- Author: Johny

local Update = appdf.req(appdf.BASE_SRC.."app.controllers.ClientUpdate")

SubGameUpdateAgent = class("SubGameUpdateAgent", cc.Node)
SubGameUpdateAgent.instance = nil

function SubGameUpdateAgent:getInstance()
    if SubGameUpdateAgent.instance == nil then
        SubGameUpdateAgent.instance = SubGameUpdateAgent:create()
    end
    return SubGameUpdateAgent.instance
end

function SubGameUpdateAgent:create()
    local obj= SubGameUpdateAgent.new()
    obj:init()
    return obj
end

function SubGameUpdateAgent:destroy()
	SubGameUpdateAgent.instance = nil
end

function SubGameUpdateAgent:init()
	self.mDelegate = nil
	self.mIsFree = true
	self._update = nil
	self._downgameinfo = nil
	self._pageInfo = nil
end

function SubGameUpdateAgent:setDelegate(_del)
	self.mDelegate = _del
end

--是否空闲
function SubGameUpdateAgent:isFree()
	return self.mIsFree
end

--获取pageinfo
function SubGameUpdateAgent:getPageInfo()
	return self._pageInfo
end


--@创建更新任务
-- _app:
-- _pageInfo: {pageIdx, appIdx}
function SubGameUpdateAgent:createUpdateTask(gameinfo, _app, _pageInfo)
	cclog("function SubGameUpdateAgent:createUpdateTask(gameinfo) ==> ")

	--记录必要信息
	self.mApp = _app
	if _pageInfo then
	   self._pageInfo = _pageInfo
	end

	--失败重试
	if not gameinfo and self._update ~= nil then
		self._update:UpdateFile()
		return true
	end

	if not gameinfo and not self._downgameinfo then 
		return false
	end

	--记录
	if gameinfo ~= nil then
		self._downgameinfo = gameinfo
	end

	--更新参数
	local newfileurl = self.mApp._updateUrl.."game/"..self._downgameinfo._Module.."res/filemd5List.json"
	local dst = device.writablePath .. "download/game/"
	local src = device.writablePath .. "download/game/"..self._downgameinfo._Module.."res/filemd5List.json"
	local downurl = self.mApp._updateUrl .. "game/"

	--创建更新
	self._update = Update:create(newfileurl,dst,src,downurl)
	self._update:upDateClient(self)

	--状态不空闲
	self.mIsFree = false

	return true
end

------------------------------底层更新回调------------------------
--更新进度
function SubGameUpdateAgent:updateProgress(sub, msg, mainpersent)
	cclog("function SubGameUpdateAgent:updateProgress(sub, msg, mainpersent) ==> ")
	if self.mDelegate then
	   self.mDelegate:updateProgress(sub, msg, mainpersent)
	end
end

--更新结果
function SubGameUpdateAgent:updateResult(result,msg)
	cclog("function SubGameUpdateAgent:updateResult(result,msg) ==> ")
	self.mIsFree = true
	if self.mDelegate then
	   self.mDelegate:updateResult(result,msg)
	else
		if result == true then
			local app = self.mApp

			--更新版本号
			for k,v in pairs(app._gameList) do
				if v._KindID == self._downgameinfo._KindID then
					app:getVersionMgr():setResVersion(v._ServerResVersion, v._KindID)
					v._Active = true
					break
				end
			end
		end
	end
end