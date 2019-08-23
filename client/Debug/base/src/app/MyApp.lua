require("base.src.app.models.bit")
require("base.src.app.models.AppDF")
require("base.src.app.Toolkits.TimerProxy") --added ycc
require("base.src.app.GameConfig")
require("base.src.app.GameQuickAPI")

cjson = require("cjson")

local Version = import(".models.Version")

local MyApp = class("MyApp", cc.load("mvc").AppBase)



function MyApp:enableSearchPath()
	--添加沙盒路径
	cc.FileUtils:getInstance():addSearchPath(device.writablePath)
	cc.FileUtils:getInstance():addSearchPath(device.writablePath .. "download/")
	cc.FileUtils:getInstance():addSearchPath(device.writablePath .. "download/client/src/")
	cc.FileUtils:getInstance():addSearchPath(device.writablePath .. "download/client/res/")
end


function MyApp:onCreate()
    math.randomseed(os.time())

    -- 开启文本log输出
	LogFile(true)
	appdf.req("base.src.app.views.layer.other.Toast")

	--开启搜索路径
	self:enableSearchPath()

	--版本信息
	self._version = Version:create()
	--游戏信息
	self._gameList = {}
	--更新地址
	self._updateUrl = ""
	--初次启动获取的配置信息
	self._serverConfig = {}
end

function MyApp:getVersionMgr()
	return self._version
end

return MyApp
