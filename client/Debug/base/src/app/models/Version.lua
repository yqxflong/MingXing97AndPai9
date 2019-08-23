--[[
	版本保存
]]
local Version = class("Version", function()
     local node = display.newNode()
     return node
end)	

function Version:ctor()
	cclog("function Version:ctor()==>")
	self:retain()
	local fileUitls=cc.FileUtils:getInstance()
	local fileName = "version.plist"
	self._savePath = device.writablePath .. fileName
	--沙盒中未找到版本信息，读包里的
	if fileUitls:isFileExist(self._savePath) then
	    self._versionInfo  = fileUitls:getValueMapFromFile(self._savePath)
	    cclog("Version:ctor==_versionInfo1: " .. cjson.encode(self._versionInfo))
	else
	    self._versionInfo  = fileUitls:getValueMapFromFile(fileName)
	    cclog("Version:ctor==_versionInfo2: " .. cjson.encode(self._versionInfo))
	end
	self._downUrl = nil
end

--设置版本
function Version:setVersion(version,kindid)
	cclog("function Version:setVersion(version,kindid)==>" .. version)
	if not kindid then
		self._versionInfo["client"] = version
	else
		self._versionInfo["game_"..kindid] = version
	end
end

--获取版本
function Version:getVersion(kindid)
	cclog("function Version:getVersion(kindid)==>")
	if not kindid then 
		return self._versionInfo["client"]
	else
		return self._versionInfo["game_"..kindid]
	end
end

--设置资源版本
function Version:setResVersion(version,kindid)
	cclog("function Version:setResVersion(version,kindid)==>")
	if not kindid then
		self._versionInfo["res_client"] = version
	else
		self._versionInfo["res_game_"..kindid] = version
	end
	self:save()
end

--获取资源版本
function Version:getResVersion(kindid)
	cclog("function Version:getResVersion(kindid)==>")
	if not kindid then 
		return self._versionInfo["res_client"]
	else
		return self._versionInfo["res_game_"..kindid]
	end
end

--保存版本
function Version:save()
	cclog("function Version:save()==>")
	cc.FileUtils:getInstance():writeToFile(self._versionInfo,self._savePath)
end

return Version