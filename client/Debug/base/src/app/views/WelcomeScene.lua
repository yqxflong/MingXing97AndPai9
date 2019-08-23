--[[
	欢迎界面
			2015_12_03 C.P
	功能：本地版本记录读取，如无记录，则解压原始大厅及附带游戏
--]]

local WelcomeScene = class("WelcomeScene", cc.load("mvc").ViewBase)

local ClientUpdate = appdf.req("base.src.app.controllers.ClientUpdate")
local QueryDialog = appdf.req("base.src.app.views.layer.other.QueryDialog")
local ClientConfig = appdf.req(appdf.BASE_SRC .."app.models.ClientConfig")


----------------------常量定义--------------------------------
--附加脚本版本号
local EXTRA_CMD_KEY   = "extra_command_version"
--------------------------------------------------------------


--全局toast函数(ios/android端调用)
cc.exports.g_NativeToast = function (msg)
	cclog("cc.exports.g_NativeToast = function (msg)==>")
	local runScene = cc.Director:getInstance():getRunningScene()
	if nil ~= runScene then
		showToastNoFade(runScene, msg, 2)
	end
end

function WelcomeScene:onCreate()
	cclog("function WelcomeScene:onCreate()==>")
	function uiLayout()
		--背景
		local newbasepath = cc.FileUtils:getInstance():getWritablePath() .. "download/baseupdate/"
		local bgfile = newbasepath .. "base/res/base_bg1.jpg"	
		local sp = cc.Sprite:create(bgfile)
		if nil == sp then
			sp = cc.Sprite:create("base_bg1.jpg")
		end
		if nil ~= sp then
			sp:setPosition(G_WIDTH_GLVIEW/2, G_HEIGHT_GLVIEW/2)
			self:addChild(sp)
		end

		--提示文本
		self._txtTips = cc.Label:createWithTTF("", "fonts/yuanti_sc_light.ttf", 24)
			:setTextColor(cc.c4b(0,250,0,255))
			:setAnchorPoint(cc.p(1,0))
			:enableOutline(cc.c4b(0,0,0,255), 1)
			:move(G_WIDTH_GLVIEW,0)
			:addTo(self)

		self.m_progressLayer = display.newLayer(cc.c4b(0, 0, 0, 0))
		self:addChild(self.m_progressLayer)
		self.m_progressLayer:setVisible(false)
		--总进度
		local total_bg = cc.Sprite:create("base_wait_frame_0.png")
		self.m_spTotalBg = total_bg
		self.m_progressLayer:addChild(total_bg)
		total_bg:setPosition(G_WIDTH_GLVIEW/2, 80)
		self.m_totalBar = ccui.LoadingBar:create()
		self.m_totalBar:loadTexture("base_wait_frame_3.png")	
		self.m_progressLayer:addChild(self.m_totalBar)
		self.m_totalBar:setPosition(G_WIDTH_GLVIEW/2, 80)
		self._totalTips = cc.Label:createWithTTF("", "fonts/yuanti_sc_light.ttf", 20)
			--:setTextColor(cc.c4b(0,250,0,255))
			:setName("text_tip")
			:enableOutline(cc.c4b(0,0,0,255), 1)
			:move(self.m_totalBar:getContentSize().width * 0.5, self.m_totalBar:getContentSize().height * 0.5)
			:addTo(self.m_totalBar)
		self.m_totalThumb = cc.Sprite:create("base_thumb_1.png")
		self.m_totalBar:addChild(self.m_totalThumb)
		self.m_totalThumb:setPositionY(self.m_totalBar:getContentSize().height * 0.5)
		self:updateBar(self.m_totalBar, self.m_totalThumb, 0)

		--单文件进度
		local file_bg = cc.Sprite:create("base_wait_frame_0.png")
		self.m_spFileBg = file_bg
		self.m_progressLayer:addChild(file_bg)
		file_bg:setPosition(G_WIDTH_GLVIEW/2, 120)
		self.m_fileBar = ccui.LoadingBar:create()
		self.m_fileBar:loadTexture("base_wait_frame_2.png")
		self.m_fileBar:setPercent(0)
		self.m_progressLayer:addChild(self.m_fileBar)
		self.m_fileBar:setPosition(G_WIDTH_GLVIEW/2, 120)
		self._fileTips = cc.Label:createWithTTF("", "fonts/yuanti_sc_light.ttf", 20)
			--:setTextColor(cc.c4b(0,250,0,255))
			:setName("text_tip")
			:enableOutline(cc.c4b(0,0,0,255), 1)
			:move(self.m_fileBar:getContentSize().width * 0.5, self.m_fileBar:getContentSize().height * 0.5)
			:addTo(self.m_fileBar)
		self.m_fileThumb = cc.Sprite:create("base_thumb_0.png")
		self.m_fileBar:addChild(self.m_fileThumb)
		self.m_fileThumb:setPositionY(self.m_fileBar:getContentSize().height * 0.5)
		self:updateBar(self.m_fileBar, self.m_fileThumb, 0)
	end
	--检查版本情况
	function checkVersion()
        --无版本信息或不对应 解压自带ZIP
        local nResversion = tonumber(self:getApp()._version:getResVersion())
	    if nil == nResversion then
	 	    self:onUnZipBase()        
	    else
	    	--版本同步
	        self:httpNewVersion()
	    end
	end

	----
	local this = self
	self:setTag(1)
    -- 资源同步队列
	self.m_tabUpdateQueue = {}
	-- 界面布局
	uiLayout()
	-- 检查版本情况
	checkVersion()
end




--进入登录界面
function  WelcomeScene:EnterClient()
	cclog("function  WelcomeScene:EnterClient()==>")
	--重置大厅与游戏
  	for k ,v in pairs(package.loaded) do
		if k ~= nil then 
			if type(k) == "string" then
				if string.find(k,"plaza.") ~= nil or string.find(k,"game.") ~= nil then
					cclog("package kill:"..k) 
					package.loaded[k] = nil
				end
			end
		end
	end	
	--场景切换
	self:getApp():enterSceneEx(appdf.CLIENT_SRC.."plaza.views.LogonScene","FADE",1)
end

--解压自带ZIP
function WelcomeScene:onUnZipBase()
	local this = self

	if self._unZip == nil then --大厅解压
		-- 状态提示
		self._txtTips:setString("解压文件，请稍候...")
		self._unZip = 0
		--解压
		local dst = device.writablePath .. "download/"
		unZipAsync(cc.FileUtils:getInstance():fullPathForFilename("client.zip"),dst,function(result)
				this:onUnZipBase()
			end)
	elseif self._unZip == 0 then --默认游戏解压
		self._unZip = 1
		--解压
		local dst = device.writablePath .. "download/"
		unZipAsync(cc.FileUtils:getInstance():fullPathForFilename("game.zip"),dst,function(result)
				this:onUnZipBase()
			end)
	else 			-- 解压完成
		self._unZip = nil
		--更新本地版本号
		self:getApp()._version:setResVersion(appdf.BASE_C_RESVERSION)
		for k ,v in pairs(appdf.BASE_GAME) do
			self:getApp()._version:setResVersion(v.version,v.kind)
		end
		self._txtTips:setString("解压完成！")

		--版本同步
	    self:httpNewVersion()
		return	
	end
end

--执行附加脚本
function WelcomeScene:excuteExtraCmd()
	cclog("WelcomeScene:excuteExtraCmd===>")
	local url = self:getApp()._updateUrl .. "command/extra_command.lua"
	local localver = cc.UserDefault:getInstance():getIntegerForKey(EXTRA_CMD_KEY, 0)
	local savePath = device.writablePath .. "download/command/"
	local extramodule = "command.extra_command"
	local targetPlatform = cc.Application:getInstance():getTargetPlatform()
	cclog("WelcomeScene:excuteExtraCmd==url: " .. url .. "=savePath: " .. savePath)
	--调用C++下载
    downFileAsync(url, "extra_command.lua", savePath, function(main,sub)
    	cclog("WelcomeScene:excuteExtraCmd=downFileAsync=main: " .. main)
        --下载回调
        if main == appdf.DOWN_PRO_INFO then --进度信息
            
        elseif main == appdf.DOWN_COMPELETED then --下载完毕
        	cclog("extra_cmd download")
            --执行、下载附加命令脚本
			local extra = savePath .. "/extra_command"
			if cc.FileUtils:getInstance():isFileExist(extra .. ".lua") then
				cclog("cmd exist")
				local extracmd = appdf.req(extramodule)
				-- dump(extracmd, "extracmd", 4)
				if (nil == extracmd.excute) or (false == extracmd.excute(localver, self, self:getApp()._updateUrl)) then
					cclog("WelcomeScene:excuteExtraCmd===cmd fail")
					--跳过执行
            		self:onCommandExcuted(localver)
				end
			else
				cclog("WelcomeScene:excuteExtraCmd===cmd not exist")
				--跳过执行
            	self:onCommandExcuted(localver)
			end
        else
        	cclog("WelcomeScene:excuteExtraCmd==down error")
        	cc.FileUtils:getInstance():removeFile(savePath .. "extra_command.lua")
            --跳过执行
            self:onCommandExcuted(localver)
        end
    end)	
end

--同步版本
function WelcomeScene:httpNewVersion()	
	cclog("WelcomeScene:httpNewVersion===>")
	self._txtTips:setString("获取服务器信息...")
	local this = self

	--数据解析
	local vcallback = function(datatable)
	 	local succeed = false
	 	local msg = "网络获取失败！"
	 	if type(datatable) == "table" then	 
	 	    cclog("WelcomeScene:httpNewVersion==datatable: " .. cjson.encode(datatable))		
            local databuffer = datatable["data"]
            if databuffer then
                --返回结果
	 		    succeed = databuffer["valid"]
	 		    --提示文字
	 		    local tips = datatable["msg"]

	 		    --获取信息
	 		    if succeed == true then	 
	 		    	this:getApp()._serverConfig = databuffer		     
 				    --下载地址
 				    this:getApp()._updateUrl = databuffer["downloadurl"]						
 				    if true == ClientConfig.APPSTORE_VERSION then
 				    	this:getApp()._updateUrl = this:getApp()._updateUrl .. "appstore/"
 				    end
 				    --大厅版本
 				    this._newVersion = tonumber(databuffer["clientversion"])          	
 				    --大厅资源版本
 				    this._newResVersion = tonumber(databuffer["resversion"])
 				    --苹果大厅更新地址
 				    this._iosUpdateUrl = databuffer["ios_url"]
 				    if true == ClientConfig.APPSTORE_VERSION then
 				    	this._iosUpdateUrl = nil
 				    end

 				    -- 检查资源版本号
 				    local nNewV = self._newResVersion
					local nCurV = tonumber(self:getApp()._version:getResVersion())
					cclog("WelcomeScene:httpNewVersion==nNewV: " .. nNewV .. "=nCurV: " .. nCurV)
					if nNewV and nCurV then
						if nNewV > nCurV then
							-- 更新配置
		 				    local updateConfig = {}
					 		updateConfig.isClient = true
					 		updateConfig.newfileurl = this:getApp()._updateUrl.."client/res/filemd5List.json"
							updateConfig.downurl = this:getApp()._updateUrl
							updateConfig.dst = device.writablePath.."download/"
							updateConfig.src = device.writablePath.."download/client/res/filemd5List.json"
							local targetPlatform = cc.Application:getInstance():getTargetPlatform()			
					 		table.insert(self.m_tabUpdateQueue, updateConfig)
						end
					end		 

 				    --加载游戏列表
 				    local rows = databuffer["gamelist"]
 				    this:getApp()._gameList = {}
 				    for k,v in pairs(rows) do
 					    local gameinfo = {}
 					    gameinfo._KindID = v["KindID"]
 					    gameinfo._KindName = string.lower(v["ModuleName"]) .. "."
 					    gameinfo._Module = string.gsub(gameinfo._KindName, "[.]", "/")
 					    gameinfo._KindVersion = v["ClientVersion"]
 					    gameinfo._ServerResVersion = tonumber(v["ResVersion"])
 					    gameinfo._Type = gameinfo._Module
 					    --检查本地文件是否存在
 					    local path = device.writablePath .. "download/game/" .. gameinfo._Module
 					    cclog("WelcomeScene:httpNewVersion==gamelist=path: " .. path)
 					    gameinfo._Active = cc.FileUtils:getInstance():isDirectoryExist(path)
 					    local e = string.find(gameinfo._KindName, "[.]")
 					    if e then
 					    	gameinfo._Type = string.sub(gameinfo._KindName,1,e - 1)
 					    end
 					    -- 排序
 					    gameinfo._SortId = tonumber(v["SortID"]) or 0
 					    table.insert(this:getApp()._gameList, gameinfo)
 				    end
 				    table.sort( this:getApp()._gameList, function(a, b)
 				    	return a._SortId > b._SortId
 				    end)
 				    
				  	cclog("WelcomeScene:httpNewVersion==gamelist: " .. cjson.encode(this:getApp()._gameList))
	 		    end
            end	 		
	 	end
	 	cclog("WelcomeScene:httpNewVersion==updateQueue" .. cjson.encode(self.m_tabUpdateQueue))
	 	self._txtTips:setString("")
	 	if succeed then
	 		self:excuteExtraCmd()
	 	else
	 		this:httpNewVersionCallBack(succeed,msg)
	 	end	 	
	end

	--获取版本信息from server
	local url = URL_VERSION_GET .. "/WS/MobileInterface.ashx"
	cclog("appdf.onHttpJsionTable==url: " .. url)
	appdf.onHttpJsionTable(url,"get","action=getgamelist",vcallback)
end

--服务器版本返回
function WelcomeScene:httpNewVersionCallBack(result,msg)
	cclog("WelcomeScene:httpNewVersionCallBack===>")
    local this = self
    
    --获取失败
    if not result then
	    self._txtTips:setString("")
	    QueryDialog:create(msg.."\n是否重试？",function(bReTry)
			    if bReTry == true then
				    this:httpNewVersion()
			    else
				    os.exit(0)
			    end
		    end)
	    	:setCanTouchOutside(false)
		    :addTo(self)
    else
	    --升级判断
	    local bUpdate = self:updateClient()
	    if not bUpdate then
		    --进入登录界面
		    self._txtTips:setString("OK")
		    self:runAction(cc.Sequence:create(
			    cc.DelayTime:create(1),
			    cc.CallFunc:create(function()
				    this:EnterClient()
			    end)
			    ))
	    end
    end
end


--升级大厅【仅手机执行】
function WelcomeScene:updateClient() 
	cclog("WelcomeScene:updateClient ===>")
	local newV = tonumber(self._newVersion)
	local curV = tonumber(self:getApp():getVersionMgr():getVersion())
	if newV and curV then		
		--更新APP
		if newV > curV then
			if device.platform == "ios" and (type(self._iosUpdateUrl) ~= "string" or self._iosUpdateUrl == "") then
				cclog("ios update fail, url is nil or empty")
			else
				self._txtTips:setString("")
				QueryDialog:create("有新的版本，是否现在下载升级？",function(bConfirm)
	                    if bConfirm == true then                    	
							self:upDateBaseApp()				    
						else
							os.exit(0)
	                    end					
					end)
					:setCanTouchOutside(false)
					:addTo(self)	
				return true
			end				
		end
	end

	--资源同步
	if 0 ~= #self.m_tabUpdateQueue then
		self:goUpdate()
		return true
	end
	cclog("version did not need to update")
end

function WelcomeScene:upDateBaseApp()
	cclog("WelcomeScene:upDateBaseApp===>")
	self.m_progressLayer:setVisible(true)
	self.m_totalBar:setVisible(false)
	self.m_spTotalBg:setVisible(false)
	self.m_fileBar:setVisible(true)
	self.m_spFileBg:setVisible(true)

	if device.platform == "android" then
		local this = self
		local argsJson 
		local url = ""

		if isDebug() then
			url = self:getApp()._updateUrl .. G_APK_DEBUG_REMOTE
		else			
			url = self:getApp()._updateUrl .. G_APK_REMOTE		 
		end
		cclog("WelcomeScene:upDateBaseApp==url: " .. url)
	    --调用C++下载
	    local luaj = require "cocos.cocos2d.luaj"
		local className = "org/cocos2dx/lua/AppActivity"

	    local sigs = "()Ljava/lang/String;"
   		local ok,ret = luaj.callStaticMethod(className,"getSDCardDocPath",{},sigs)
   		if ok then
   			local dstpath = ret .. "/update/"
   			local filepath = dstpath .. G_APK_LOCAL
		    if cc.FileUtils:getInstance():isFileExist(filepath) then
		    	cc.FileUtils:getInstance():removeFile(filepath)
		    end
		    if false == cc.FileUtils:getInstance():isDirectoryExist(dstpath) then
		    	cc.FileUtils:getInstance():createDirectory(dstpath)
		    end
		    self:updateBar(self.m_fileBar, self.m_fileThumb, 0)
			downFileAsync(url, G_APK_LOCAL, dstpath, function(main,sub)
					--下载回调
					if main == appdf.DOWN_PRO_INFO then --进度信息
						self:updateBar(self.m_fileBar, self.m_fileThumb, sub)
					elseif main == appdf.DOWN_COMPELETED then --下载完毕
						self._txtTips:setString("下载完成")
						self.m_progressLayer:setVisible(false)

						--安装apk						
						local args = {filepath}
						sigs = "(Ljava/lang/String;)V"
		   				ok,ret = luaj.callStaticMethod(className, "installClient",args, sigs)
		   				if ok then
		   					os.exit(0)
		   				end
					else
						QueryDialog:create("下载失败,code:".. main .."\n是否重试？",function(bReTry)
							if bReTry == true then
								this:upDateBaseApp()
							else
								os.exit(0)
							end
						end)
						:setCanTouchOutside(false)
						:addTo(self)
					end
				end)
		else
			os.exit(0)
   		end	    
	elseif device.platform == "ios" then
		local luaoc = require "cocos.cocos2d.luaoc"
		local ok,ret  = luaoc.callStaticMethod("AppController","updateBaseClient",{url = self._iosUpdateUrl})
	    if not ok then
	        cclog("luaoc error:" .. ret)        
	    end
	end
end

--开始下载
function WelcomeScene:goUpdate( )
	cclog("WelcomeScene:goUpdate===>")
	self.m_progressLayer:setVisible(true)

	local config = self.m_tabUpdateQueue[1]
	if nil == config then
		self.m_progressLayer:setVisible(false)
		self._txtTips:setString("OK")
		self:runAction(cc.Sequence:create(
				cc.DelayTime:create(1),
				cc.CallFunc:create(function()
					self:EnterClient()
				end)
		))
	else
		ClientUpdate:create(config.newfileurl, config.dst, config.src, config.downurl)
			:upDateClient(self)
	end	
end

--下载进度
function WelcomeScene:updateProgress(sub, msg, mainpersent)
	self:updateBar(self.m_fileBar, self.m_fileThumb, sub)
	self:updateBar(self.m_totalBar, self.m_totalThumb, mainpersent)
end

--下载结果
function WelcomeScene:updateResult(result,msg)
	local this = self
	if result == true then
		self:updateBar(self.m_fileBar, self.m_fileThumb, 0)
		self:updateBar(self.m_totalBar, self.m_totalThumb, 0)

		local config = self.m_tabUpdateQueue[1]
		if nil ~= config then
			if true == config.isClient then
				--更新本地大厅版本
				self:getApp()._version:setResVersion(self._newResVersion)
			else
				self:getApp()._version:setResVersion(config._ServerResVersion, config._KindID)
				for k,v in pairs(self:getApp()._gameList) do
					if v._KindID == config._KindID then
						v._Active = true
					end
				end
			end
			table.remove(self.m_tabUpdateQueue, 1)
			self:goUpdate()
		else
			--进入登录界面
			self._txtTips:setString("OK")
			self:runAction(cc.Sequence:create(
					cc.DelayTime:create(1),
					cc.CallFunc:create(function()
						this:EnterClient()
					end)
			))	
		end
	else
		self.m_progressLayer:setVisible(false)
		self:updateBar(self.m_fileBar, self.m_fileThumb, 0)
		self:updateBar(self.m_totalBar, self.m_totalThumb, 0)

		--重试询问
		self._txtTips:setString("")
		QueryDialog:create(msg.."\n是否重试？",function(bReTry)
				if bReTry == true then
					this:goUpdate()
				else
					os.exit(0)
				end
			end)
			:setCanTouchOutside(false)
			:addTo(self)
	end
end

function WelcomeScene:updateBar(bar, thumb, percent)
	if nil == bar or nil == thumb then
		return
	end
	local text_tip = bar:getChildByName("text_tip")
	if nil ~= text_tip then
		local str = string.format("%d%%", percent)
		text_tip:setString(str)
	end

	bar:setPercent(percent)
	local size = bar:getVirtualRendererSize()
	thumb:setPositionX(size.width * percent / 100)
end

-- 附加脚本执行完毕
function WelcomeScene:onCommandExcuted(NEW_VER)
	cclog("WelcomeScene:onCommandExcuted===NEW_VER: " .. NEW_VER)
	cc.UserDefault:getInstance():setIntegerForKey(EXTRA_CMD_KEY, NEW_VER)
	--同步、更新
	self:httpNewVersionCallBack(true)
end

return WelcomeScene