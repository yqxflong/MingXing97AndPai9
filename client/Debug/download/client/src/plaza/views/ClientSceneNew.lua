--@NEW
-- Name: ClientSceneNew
-- Func: 新大厅界面
-- Author: Johny

local PopWait = appdf.req(appdf.BASE_SRC.."app.views.layer.other.PopWait")
local LevelFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.LevelFrame")
local ShopDetailFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.ShopDetailFrame")
local TaskFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.TaskFrame")
local GameFrameEngine = appdf.req(appdf.CLIENT_SRC.."plaza.models.GameFrameEngine")
local Room = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.room.RoomLayer")
local HeadSprite = appdf.req(appdf.EXTERNAL_SRC .. "HeadSprite")
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local NotifyMgr = appdf.req(appdf.EXTERNAL_SRC .. "NotifyMgr")
local ClipText = appdf.req(appdf.EXTERNAL_SRC .. "ClipText")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")
local chat_cmd = appdf.req(appdf.HEADER_SRC.."CMD_ChatServer")

--客服
local GameServiceLayer = appdf.req(appdf.CLIENT_SRC .. "plaza.views.layer.plazanew.GameServiceLayer")
--分享
local GameShareLayer = appdf.req(appdf.CLIENT_SRC .. "plaza.views.layer.plazanew.ShareLayer")
--保险柜
local GameBaoxianLayer = appdf.req(appdf.CLIENT_SRC .. "plaza.views.layer.baoxiangui.GameBaoxianLayer")
--设置
local GameSettingLayer = appdf.req(appdf.CLIENT_SRC .. "plaza.views.layer.plazanew.SettingLayer")

local ClientScene = class("ClientScene", cc.load("mvc").ViewBase)

----------------------------------常量定义------------------------------
ClientScene.BT_SETTING      = 1
ClientScene.BT_SHARE        = 2
ClientScene.BT_SERVICE      = 3
ClientScene.BT_BAOXIANGUI   = 4
ClientScene.BT_MX97         = 11
ClientScene.BT_MXFQ         = 12
ClientScene.BT_MXDDZ        = 13


--相关文件存储文件夹名
local HELP_LAYER_NAME = "__introduce_help_layer__"
local VOICE_BTN_NAME = "__voice_record_button__"
local VOICE_LAYER_NAME = "__voice_record_layer__"

--广播大厅文字位置
local POS_TRUMPET_CLIENT_TXT  =   cc.p(220, 30)
--广播游戏中文字位置
local POS_TRUMPET_INGAME_TXT  =   cc.p(220, 30)
------------------------------------------------------------------------------------

-- 进入场景而且过渡动画结束时候触发。
function ClientScene:onEnterTransitionFinish()
	cclog("function ClientScene:onEnterTransitionFinish() ==>")
	----设置更新代理
    SubGameUpdateAgent:getInstance():setDelegate(self)

	--裁切头像
	if not self._head then
		local head = HeadSprite:createNormal(GlobalUserItem, 90)
		if nil ~= head then
			head:setPosition(self._frame:getPosition())
			head:addTo(self._frame:getParent())
			self._head = head
		end		
	else
		self._head:updateHead(GlobalUserItem)
	end

	--配置子游戏信息
	GlobalUserItem.nCurGameKind = G_GAME_KINDID
	local gameinfo = self:getGameInfo(GlobalUserItem.nCurGameKind)
	self:updateEnterGameInfo(gameinfo)

	-- 游戏币查询
	self:queryUserScoreInfo(handler(self, self.updateInfomation))	

    return self
end

-- 退出场景而且开始过渡动画时候触发。
function ClientScene:onExitTransitionStart()
	cclog("function ClientScene:onExitTransitionStart() ==>")
	----设置更新代理
    SubGameUpdateAgent:getInstance():setDelegate(nil)
    --
	self._sceneLayer:unregisterScriptKeypadHandler()
    return self
end

function ClientScene:onExit()
	cclog("function ClientScene:onExit() ==>")
	if self._gameFrame:isSocketServer() then
		self._gameFrame:onCloseSocket()
	end
	self:disconnectFrame()	
	ExternalFun.SAFE_RELEASE(self.m_actCoinAni)
	self.m_actCoinAni = nil
	self:releasePublicRes()
	self:removeListener()	
	removebackgroundcallback()
	if PriRoom then
		PriRoom:getInstance():onExitPlaza()
	end		
	--清理子游戏更新代理
	SubGameUpdateAgent:getInstance():destroy()
    --清除广播监听
    G_unSchedule(self.mBroadMonitor)
    self.mBroadMonitor = nil
		
	return self
end

--@界面布局
function ClientScene:layoutUI()
	local btncallback = function(ref, type)
        if type == ccui.TouchEventType.ended then
         	self:onButtonClickedEvent(ref:getTag(),ref)
        end
    end

    --加载csb资源
	local rootLayer, csbNode = ExternalFun.loadRootCSB( "clientscene/ClientScene.csb", self )
	self.m_plazaLayer = csbNode

	--场景层
	local panel_scene = csbNode:getChildByName("panel_scene")
	self._sceneRecord = {} --场景记录
	self._sceneLayer = display.newLayer()
		:setContentSize(yl.WIDTH,yl.HEIGHT)
		:addTo(panel_scene)

    --返回键事件
	self._sceneLayer:registerScriptKeypadHandler(function(event)
		if event == "backClicked" then
			 if self._popWait == nil then
			 	if #self._sceneRecord > 0 then
					local cur_layer =  self._sceneLayer:getChildByTag(self._sceneRecord[#self._sceneRecord])
					if cur_layer  and cur_layer.onKeyBack then
						if cur_layer:onKeyBack() == true then
							return
						end
					end
				end
				self:onKeyBack()
			end
		end
	end)

	--头像框
	local frame = appdf.getNodeByName(csbNode, "img_headbg")
	self._frame = frame

	--名字
	local testen = cc.Label:createWithSystemFont("A","Arial", 24)
    self._enSize = testen:getContentSize().width
    local testcn = cc.Label:createWithSystemFont("游","Arial", 24)
    self._cnSize = testcn:getContentSize().width
    --
	self._name = appdf.getNodeByName(csbNode, "lb_name")
	self._name:setString(string.stringEllipsis(GlobalUserItem.szNickName, self._enSize, self._cnSize, 320))

	--ID
	self._id = appdf.getNodeByName(csbNode, "lb_id")
	self._id:setString("" .. GlobalUserItem.dwGameID)

	--金币
	self._coin = appdf.getNodeByName(csbNode, "lb_coin")
	self._coin:setString("" .. GlobalUserItem.lUserScore)

	--公告
	self._notice = appdf.getNodeByName(csbNode, "lb_notice")
	self._notice:setString("")

	--广播
	self.mLbBroadCast = appdf.getNodeByName(csbNode, "lb_broadcast")
	self.mNodeBCInit = appdf.getNodeByName(csbNode, "node_broadcast")

	--明星97
	self.mBtnMX97 = appdf.getNodeByName(csbNode, "btn_mx97")
	self.mBtnMX97:setTag(ClientScene.BT_MX97)
	self.mBtnMX97:addTouchEventListener(btncallback)

	--排行榜
	self.mRankingLayer = appdf.getNodeByName(csbNode, "panel_ranking")

	--客服
	local btn_service = appdf.getNodeByName(csbNode, "btn_kefu")
	btn_service:setTag(ClientScene.BT_SERVICE)
	btn_service:addTouchEventListener(btncallback)

	--设置
	local btn_setting = appdf.getNodeByName(csbNode, "btn_setting")
	btn_setting:setTag(ClientScene.BT_SETTING)
	btn_setting:addTouchEventListener(btncallback)

	--分享
	local btn_service = appdf.getNodeByName(csbNode, "btn_share")
	btn_service:setTag(ClientScene.BT_SHARE)
	btn_service:addTouchEventListener(btncallback)

	--保险柜
	local btn_baoxian = appdf.getNodeByName(csbNode, "btn_baoxian")
	btn_baoxian:setTag(ClientScene.BT_BAOXIANGUI)
	btn_baoxian:addTouchEventListener(btncallback)
end

-- 初始化界面
function ClientScene:onCreate()
	cclog("function ClientScene:onCreate() ==>")

	math.randomseed(os.time())
	--init SubGameUpdateAgent
	local sguaNode = SubGameUpdateAgent:getInstance()
	self:addChild(sguaNode)
	
	--var
	self.m_listener = nil
	self:cachePublicRes()
	--保存进入的游戏记录信息
	GlobalUserItem.m_tabEnterGame = nil
	--上一个场景
	self.m_nPreTag = nil
	--喇叭发送界面
	self.m_trumpetLayer = nil	
	GlobalUserItem.bHasLogon = true
	self.m_tabInfoTips = {}
	self._tipIndex = 1
	self.m_nNotifyId = 0
	-- 系统公告列表
	self.m_tabSystemNotice = {}
	self._sysIndex = 1
	-- 公告是否运行
	self.m_bNotifyRunning = false
	-- 回退
	self.m_bEnableKeyBack = true
	--广播列表
	self.mBroadList = {}
	-- 是否广播中
	self.mIsBroadCasting = false
	--排行列表
	self._rankList = {}


	--init gameframe
	self._gameFrame = GameFrameEngine:create(self,function (code,result)
		self:onRoomCallBack(code,result)
	end)	

	if PriRoom then
		PriRoom:getInstance():onEnterPlaza(self, self._gameFrame)
	end
	
	self:registerScriptHandler(function(eventType)
		if eventType == "enterTransitionFinish" then	-- 进入场景而且过渡动画结束时候触发。			
			self:onEnterTransitionFinish()			
		elseif eventType == "exitTransitionStart" then	-- 退出场景而且开始过渡动画时候触发。
			self:onExitTransitionStart()
		elseif eventType == "exit" then
			self:onExit()
		end
	end)

	self:layoutUI()

	setbackgroundcallback(function (bEnter)
		if type(self.onBackgroundCallBack) == "function" then
			self:onBackgroundCallBack(bEnter)
		end
	end)

	self:initListener()

	self:onChangeShowMode(yl.SCENE_GAMELIST)
end

function ClientScene:onBackgroundCallBack(bEnter)
	cclog("function ClientScene:onBackgroundCallBack(bEnter) ==>")
end

--gameframeengine回调
function ClientScene:onRoomCallBack(code,message)
	cclog("function ClientScene:onRoomCallBack(code,message) ==>")
	cclog("onRoomCallBack:"..code)
	if message then
		showToast(self,message,1)
	end
	if code == -1  then
		self:dismissPopWait()
		self:onLeaveSubGame()
	end
end

--离开子游戏
function ClientScene:onLeaveSubGame()
	cclog("ClientSceneNew:onLeaveSubGame===>")
	local curScene = self._sceneRecord[#self._sceneRecord]
	if curScene == yl.SCENE_ROOM or curScene == yl.SCENE_GAME then
		cclog("onRoomCallBack curscene is "..curScene)
		local curScene = self._sceneLayer:getChildByTag(curScene)
		if curScene and curScene.onExitRoom then
			curScene:onExitRoom()
		end
	end
end

function ClientScene:onReQueryFailure(code, msg)
	cclog("function ClientScene:onReQueryFailure(code, msg) ==>")
	self:dismissPopWait()
	if nil ~= msg and type(msg) == "string" then
		showToast(self,msg,2)
	end
end

--进入房间
function ClientScene:onEnterRoom()
	cclog("function ClientScene:onEnterRoom() ==>")
	self:dismissPopWait()
	local entergame = self:getEnterGameInfo()
	--检查子游戏是否自定义房间
	if nil ~= entergame then
		local modulestr = string.gsub(entergame._KindName, "%.", "/")
		local targetPlatform = cc.Application:getInstance():getTargetPlatform()
		local customRoomFile = "game/" .. modulestr .. "src/views/GameRoomListLayer.lua"
		if cc.FileUtils:getInstance():isFileExist(customRoomFile) then
			cclog("ClientScene:onEnterRoom===>子游戏自定义房间")
			if (appdf.req(customRoomFile):onEnterRoom(self._gameFrame)) then
				self:showPopWait()
				return
			else
				--断网、退出房间
				if nil ~= self._gameFrame then
					self._gameFrame:onCloseSocket()
					GlobalUserItem.nCurRoomIndex = -1
				end
			end
		end
	end
end

function ClientScene:onEnterTable()
	cclog("function ClientScene onEnterTable ==>")

	if PriRoom and GlobalUserItem.bPrivateRoom then
		-- 动作记录
		PriRoom:getInstance().m_nLoginAction = PriRoom.L_ACTION.ACT_ENTERTABLE
	end
	local tag = self._sceneRecord[#self._sceneRecord]
	if tag == yl.SCENE_GAME then
		self._gameFrame:setViewFrame(self._sceneLayer:getChildByTag(yl.SCENE_GAME))
	else
		self:onChangeShowMode(yl.SCENE_GAME)
	end
end

--启动游戏
function ClientScene:onStartGame()
	cclog("function ClientScene:onStartGame() ==>")

	local app = self:getApp()
	local entergame = self:getEnterGameInfo()
	if nil == entergame then
		showToast(self, "游戏信息获取失败", 3)
		return
	end
	self:getEnterGameInfo().nEnterRoomIndex = GlobalUserItem.nCurRoomIndex
	if nil ~= self.m_touchFilter then
		self.m_touchFilter:dismiss()
		self.m_touchFilter = nil
	end

	self:showPopWait()
	self._gameFrame:onInitData()
	self._gameFrame:setKindInfo(GlobalUserItem.nCurGameKind, entergame._KindVersion)
	local curScene = self._sceneRecord[#self._sceneRecord]
	self._gameFrame:setViewFrame(self)
	self._gameFrame:onCloseSocket()
	self._gameFrame:onLogonRoom()
end

function ClientScene:onCleanPackage(name)
	cclog("function ClientScene:onCleanPackage(name) ==>")

	if not name then
		return
	end
	for k ,v in pairs(package.loaded) do
		if k ~= nil then 
			if type(k) == "string" then
				if string.find(k,name) ~= nil or string.find(k,name) ~= nil then
					cclog("package kill:"..k) 
					package.loaded[k] = nil
				end
			end
		end
	end
end

function ClientScene:onUserInfoChange( event  )
	cclog("function ClientScene:onUserInfoChange( event  ) ==>")
	local msgWhat = event.obj
	
	if nil ~= msgWhat and msgWhat == yl.RY_MSG_USERHEAD then
		--更新头像
		if nil ~= self._head then
			self._head:updateHead(GlobalUserItem)
		end
	end

	if nil ~= msgWhat and msgWhat == yl.RY_MSG_USERWEALTH then
		--更新财富
		self:updateInfomation()
	end
end

function ClientScene:initListener(  )
	cclog("function ClientScene:initListener(  ) ==>")
	self.m_listener = cc.EventListenerCustom:create(yl.RY_USERINFO_NOTIFY,handler(self, self.onUserInfoChange))
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(self.m_listener, self)
    --广播监听器
    self.mBroadMonitor = nextTick_eachSecond(function()
    		if not self.mIsBroadCasting and #self.mBroadList > 0 then
    			self:onBroadCastPlay(self.mBroadList[1])
    			table.remove(self.mBroadList, 1)
    		end
    	end, 3.0)
end

function ClientScene:removeListener(  )
	cclog("function ClientScene:removeListener(  ) ==>")
	if nil ~= self.m_listener then
		cc.Director:getInstance():getEventDispatcher():removeEventListener(self.m_listener)
		self.m_listener = nil
	end	
end

--返回上一界面
function ClientScene:onKeyBack()
	cclog("function ClientScene:onKeyBack() ==>")
	if not self.m_bEnableKeyBack then
		return
	end
	self:onChangeShowMode()
end

--跑马灯更新
function ClientScene:onChangeNotify(msg)
	cclog("function ClientScene:onChangeNotify(msg) ==>" .. json.encode(msg))
	self._notice:setString(msg.str)
end

function ClientScene:ExitClient()
	cclog("function ClientScene:ExitClient() ==>")
	GlobalUserItem.nCurRoomIndex = -1
	self:updateEnterGameInfo(nil)
	self:getApp():enterSceneEx(appdf.CLIENT_SRC.."plaza.views.LogonScene","FADE",1)

	GlobalUserItem.reSetData()
	--读取配置
	GlobalUserItem.LoadData()
	--断开好友服务器
	FriendMgr:getInstance():reSetAndDisconnect()
	--通知管理
	NotifyMgr:getInstance():clear()
	-- 私人房数据
	if PriRoom then
		PriRoom:getInstance():reSet()
	end
end

--按钮事件
function ClientScene:onButtonClickedEvent(tag,ref)
	cclog("function ClientScene:onButtonClickedEvent(tag,ref) ==>")
	if tag == ClientScene.BT_MX97 then
		if not self:onCheckUpdateSubgame() then
		   	GlobalUserItem.nCurGameKind = G_GAME_KINDID
			GlobalUserItem.szCurGameName = yl.getSubGameFolder("" .. G_GAME_KINDID)
			self:onChangeShowMode(yl.SCENE_ROOMLIST)
		end
	elseif tag == ClientScene.BT_SHARE then
		local layer = GameShareLayer:create(self)
		layer:addTo(self)
	elseif tag == ClientScene.BT_SETTING then
		local layer = GameSettingLayer:create(self)
		layer:addTo(self)
	elseif tag == ClientScene.BT_SERVICE then
		local layer = GameServiceLayer:create(self)
		layer:addTo(self)
	elseif tag == ClientScene.BT_BAOXIANGUI then
		local layer = GameBaoxianLayer:create(self)
		layer:addTo(self)
	end
end

--切换目标界面
function ClientScene:onChangeShowMode_ChangeToDstLayer(tag, dst_layer)
    cclog("ClientScene:onChangeShowMode_ChangeToDstLayer===>SCENE_GAME")
	dst_layer:addTo(self._sceneLayer)
	if dst_layer.onSceneAniFinish then
		dst_layer:onSceneAniFinish()
	end
end

--是否保留大厅基本控件
function ClientScene:onChangeShowMode_ifshowBasic(tag)
    cclog("ClientScene:onChangeShowMode_ChangeToDstLayer===>SCENE_GAME")
end


--切换页面
function ClientScene:onChangeShowMode(nTag, param)
	local tag = nTag
	local curtag 			--当前页面ID
	local bIn 				--进入判断

	cclog("function ClientScene:onChangeShowMode ==> ")

	--当前页面
	if #self._sceneRecord > 0 then
		curtag = self._sceneRecord[#self._sceneRecord]
		if curtag == yl.SCENE_GAME then
		   table.remove(self._sceneRecord, #self._sceneRecord)
		end
	end
	ExternalFun.dismissTouchFilter()

	--当前页面
	if curtag then
        cclog("ClientScene:onChangeShowMode() --> if curtag then===curtag: " .. curtag)
		local cur_layer = self._sceneLayer:getChildByTag(curtag)
		if cur_layer then
            cclog("ClientScene:onChangeShowMode() --> if cur_layer then: " .. curtag)
			cur_layer:stopAllActions()
			cur_layer:removeFromParent()
		end 
	end

	if not tag then
	   if curtag == yl.SCENE_GAME then
	   	  tag = self._sceneRecord[#self._sceneRecord]
	      table.remove(self._sceneRecord, #self._sceneRecord)
	   elseif #self._sceneRecord > 1 then
	      tag = self._sceneRecord[#self._sceneRecord - 1]
	      table.remove(self._sceneRecord, #self._sceneRecord)
	      table.remove(self._sceneRecord, #self._sceneRecord)
	   else
	   	  tag = yl.SCENE_GAMELIST
	   end
	end

	--目标页面
	local dst_layer = self:getTagLayer(tag, param)
	if dst_layer then
		cclog("dst_layer==>" .. tag)
		table.insert(self._sceneRecord, tag)
		self:onChangeShowMode_ifshowBasic(tag)
		self:onChangeShowMode_ChangeToDstLayer(tag, dst_layer)
	else
		doAssert("ClientScene:onChangeShowMode() --> dst_layer is nil")
		self:ExitClient()
		return
	end

	if tag == yl.SCENE_GAME then
		self._gameFrame:setViewFrame(dst_layer)
	end

	--游戏信息
	GlobalUserItem.bEnterGame = ( tag == yl.SCENE_GAME )

	--返回大厅调用刷新
	if tag == yl.SCENE_GAMELIST then
		self:updateInfomation()
	end

    cclog("ClientScene:onChangeShowMode <== end")
end

--获取页面
function ClientScene:getTagLayer(tag, param)
	cclog("function ClientScene:getTagLayer(tag, param) ==>tag: " .. tag)

	local dst
	if tag == yl.SCENE_GAMELIST then
		dst = cc.Layer:create()
	elseif tag == yl.SCENE_ROOMLIST then
		--是否有自定义房间列表
		local entergame = self:getEnterGameInfo()
		if nil ~= entergame then
			cclog("ClientScene:getTagLayer==自定义房间")
			local modulestr = string.gsub(entergame._KindName, "%.", "/")
			local targetPlatform = cc.Application:getInstance():getTargetPlatform()
			local customRoomFile = "game/" .. modulestr .. "src/views/GameRoomListLayer.lua"
			if cc.FileUtils:getInstance():isFileExist(customRoomFile) then
				dst = appdf.req(customRoomFile):create(self, self._gameFrame, param)
			end
		end
		if nil == dst then
			dst = RoomList:create(self, param)
		end	
	elseif tag == yl.SCENE_GAME then --进入子游戏
		local entergame = self:getEnterGameInfo()
		if nil ~= entergame then
			local modulestr = entergame._KindName
			local gameScene = appdf.req(appdf.GAME_SRC.. modulestr .. "src.views.GameLayer")
			if gameScene then
				dst = gameScene:create(self._gameFrame,self)				
			end
		else
			cclog("游戏记录错误")
		end
	end
	if dst then
		if dst.setTag ~= nil then
			dst:setTag(tag)
		end
	end
	return dst
end

--显示等待
function ClientScene:showPopWait(isTransparent)
	cclog("function ClientScene:showPopWait(isTransparent) ==>")
	if not self._popWait then
		self._popWait = PopWait:create(isTransparent)
			:show(self,"请稍候！")
		self._popWait:setLocalZOrder(yl.MAX_INT)
	end
end

--关闭等待
function ClientScene:dismissPopWait()
	cclog("function ClientScene:dismissPopWait() ==>")
	if self._popWait and self._popWait.dismiss then
		self._popWait:dismiss()
		self._popWait = nil
	end
end

--更新进入游戏记录
function ClientScene:updateEnterGameInfo( info )
	cclog("function ClientScene:updateEnterGameInfo( info ) ==>" .. json.encode(info))
	GlobalUserItem.m_tabEnterGame = info
end

function ClientScene:getEnterGameInfo(  )
	cclog("function ClientScene:getEnterGameInfo(  ) ==>")

	return GlobalUserItem.m_tabEnterGame
end

--获取游戏信息
function ClientScene:getGameInfo(wKindID)
	cclog("function ClientScene:getGameInfo(wKindID) ==>" .. wKindID)
	for k,v in pairs(self:getApp()._gameList) do
		if tonumber(v._KindID) == tonumber(wKindID) then
			return v
		end
	end
	return nil
end

function ClientScene:getSceneRecord(  )
	cclog("function ClientScene:getSceneRecord(  ) ==>")
	return self._sceneRecord
end

--@更新信息
function ClientScene:updateInfomation(  )
	cclog("function ClientScene:updateInfomation(  ) ==>")
	--更新金币
	self._coin:setString("" .. GlobalUserItem.lUserScore)
	--请求公告
	self:requestNotice()
	--请求排行
	self:requestRanking()
end

--缓存公共资源
function ClientScene:cachePublicRes(  )
	cclog("function ClientScene:cachePublicRes(  ) ==>")

	--cache public
	cc.SpriteFrameCache:getInstance():addSpriteFrames("public/public.plist")
	local dict = cc.FileUtils:getInstance():getValueMapFromFile("public/public.plist")
	local framesDict = dict["frames"]
	if nil ~= framesDict and type(framesDict) == "table" then
		for k,v in pairs(framesDict) do
			local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(k)
			if nil ~= frame then
				frame:retain()
			end
		end
	end

	--cache ani
	cc.SpriteFrameCache:getInstance():addSpriteFrames("plazanew/plazaAni.plist")	
	dict = cc.FileUtils:getInstance():getValueMapFromFile("plazanew/plazaAni.plist")
	framesDict = dict["frames"]
	if nil ~= framesDict and type(framesDict) == "table" then
		for k,v in pairs(framesDict) do
			local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(k)
			if nil ~= frame then
				frame:retain()
			end
		end
	end

	--cache plaza
	cc.SpriteFrameCache:getInstance():addSpriteFrames("plazanew/plazanew.plist")	
	dict = cc.FileUtils:getInstance():getValueMapFromFile("plazanew/plazanew.plist")
	framesDict = dict["frames"]
	if nil ~= framesDict and type(framesDict) == "table" then
		for k,v in pairs(framesDict) do
			local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(k)
			if nil ~= frame then
				frame:retain()
			end
		end
	end
end

--释放公共资源
function ClientScene:releasePublicRes(  )
	cclog("function ClientScene:releasePublicRes(  ) ==>")

    -- public
	local dict = cc.FileUtils:getInstance():getValueMapFromFile("public/public.plist")
	local framesDict = dict["frames"]
	if nil ~= framesDict and type(framesDict) == "table" then
		for k,v in pairs(framesDict) do
			local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(k)
			if nil ~= frame and frame:getReferenceCount() > 0 then
				frame:release()
			end
		end
	end

	-- ani
	local dict = cc.FileUtils:getInstance():getValueMapFromFile("plazanew/plazaAni.plist")
	local framesDict = dict["frames"]
	if nil ~= framesDict and type(framesDict) == "table" then
		for k,v in pairs(framesDict) do
			local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(k)
			if nil ~= frame and frame:getReferenceCount() > 0 then
				frame:release()
			end
		end
	end

	-- plaza
	dict = cc.FileUtils:getInstance():getValueMapFromFile("plazanew/plazanew.plist")
	framesDict = dict["frames"]
	if nil ~= framesDict and type(framesDict) == "table" then
		for k,v in pairs(framesDict) do
			local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(k)
			if nil ~= frame and frame:getReferenceCount() > 0 then
				frame:release()
			end
		end
	end

	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("public/public.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey("public/public.png")

	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("plazanew/plazaAni.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey("plazanew/plazaAni.png")
	
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("plazanew/plazanew.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey("plazanew/plazanew.png")

	cc.Director:getInstance():getTextureCache():removeUnusedTextures()
	cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()
end

--输出日志
function ClientScene:logData(msg, addExtral)
	cclog("function ClientScene:logData(msg, addExtral) ==>")

	addExtral = addExtral or false
	local logtable = {}
	local entergame = self:getEnterGameInfo()
	if nil ~= entergame then
		logtable.name = entergame._KindName
		logtable.id = entergame._KindID
	end
	logtable.msg = msg
	local jsonStr = cjson.encode(logtable)
	LogAsset:getInstance():logData(jsonStr,true)
end

--请求公告
function ClientScene:requestNotice()
	cclog("function ClientScene:requestNotice() ==>")

	local url = yl.HTTP_URL .. "/WS/MobileInterface.ashx?action=GetMobileRollNotice"         	
	appdf.onHttpJsionTable(url ,"GET","",function(jstable,jsdata)
		if type(jstable) == "table" then
			local data = jstable["data"]
			local msg = jstable["msg"]
			if type(data) == "table" then
				local valid = data["valid"]
				if nil ~= valid and true == valid then
					local list = data["notice"]
					if type(list)  == "table" then
						local listSize = #list
						self.m_nNoticeCount = listSize
						for i = 1, listSize do
							local item = {}
							item.str = list[i].content or ""
							item.id = self:getNoticeId()
							item.color = cc.c4b(255,255,255,255)
							item.autoremove = false
							item.showcount = 0
							table.insert(self.m_tabSystemNotice, item)
						end
						self:onChangeNotify(self.m_tabSystemNotice[self._sysIndex])
					end
				end
			end
			if type(msg) == "string" and "" ~= msg then
				showToast(self, msg, 3)
			end
		end
	end)
end

function ClientScene:addNotice(item)
	cclog("function ClientScene:addNotice(item) ==>")
	if nil == item then
		return
	end
	table.insert(self.m_tabInfoTips, 1, item)
	if not self.m_bNotifyRunning then
		self:onChangeNotify(self.m_tabInfoTips[self._tipIndex])
	end
end

function ClientScene:removeNoticeById(id)
	cclog("function ClientScene:removeNoticeById(id) ==>")

	if nil == id then
		return
	end

	local idx = nil
	for k,v in pairs(self.m_tabInfoTips) do
		if nil ~= v.id and v.id == id then
			idx = k
			break
		end
	end

	if nil ~= idx then
		table.remove(self.m_tabInfoTips, idx)
	end
end

function ClientScene:getNoticeId()
	cclog("function ClientScene:getNoticeId() ==>")

	local tmp = self.m_nNotifyId
	self.m_nNotifyId = self.m_nNotifyId + 1
	return tmp
end


function ClientScene:queryUserScoreInfo(queryCallBack)
	cclog("function ClientScene:queryUserScoreInfo(queryCallBack) ==>")

	local ostime = os.time()
    local url = yl.HTTP_URL .. "/WS/MobileInterface.ashx"

    self:showPopWait()
    appdf.onHttpJsionTable(url ,"GET","action=GetScoreInfo&userid=" .. GlobalUserItem.dwUserID .. "&time=".. ostime .. "&signature=".. GlobalUserItem:getSignature(ostime),function(sjstable,sjsdata)
        self:dismissPopWait()
        dump(sjstable, "sjstable", 5)
        if type(sjstable) == "table" then
            local data = sjstable["data"]
            if type(data) == "table" then
                local valid = data["valid"]
                if true == valid then
                    local score = tonumber(data["Score"]) or 0
                    local bean = tonumber(data["Currency"]) or 0
                    local ingot = tonumber(data["UserMedal"]) or 0
                    local roomcard = tonumber(data["RoomCard"]) or 0

                    local needupdate = false
                    if score ~= GlobalUserItem.lUserScore 
                    	or bean ~= GlobalUserItem.dUserBeans
                    	or ingot ~= GlobalUserItem.lUserIngot
                    	or roomcard ~= GlobalUserItem.lRoomCard then
                    	GlobalUserItem.dUserBeans = bean
                    	GlobalUserItem.lUserScore = score
                    	GlobalUserItem.lUserIngot = ingot
                    	GlobalUserItem.lRoomCard = roomcard
                        needupdate = true
                    end
                    if needupdate then
                        cclog("update score")
                        --通知更新        
                        local eventListener = cc.EventCustom:new(yl.RY_USERINFO_NOTIFY)
                        eventListener.obj = yl.RY_MSG_USERWEALTH
                        cc.Director:getInstance():getEventDispatcher():dispatchEvent(eventListener)
                    end 
                    if type(queryCallBack) == "function" then
                    	queryCallBack(needupdate)
                    end                   
                end
            end
        end
    end)
end


function ClientScene:disconnectFrame()
	cclog("function ClientScene:disconnectFrame() ==>")

	if nil ~= self._shopDetailFrame and self._shopDetailFrame:isSocketServer() then
		self._shopDetailFrame:onCloseSocket()
		self._shopDetailFrame = nil
	end

	if nil ~= self._levelFrame and self._levelFrame:isSocketServer() then
		self._levelFrame:onCloseSocket()
		self._levelFrame = nil
	end

	if nil ~= self._taskFrame and self._taskFrame:isSocketServer() then
		self._taskFrame:onCloseSocket()		

		if nil ~= self._taskFrame._gameFrame then
            self._taskFrame._gameFrame._shotFrame = nil
            self._taskFrame._gameFrame = nil
        end
        self._taskFrame = nil
	end
end


function ClientScene:popTargetShare( callback )
	cclog("function ClientScene:popTargetShare( callback ) ==>")

	local TargetShareLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.plaza.TargetShareLayer")
	local lay = TargetShareLayer:create(callback)
	self:addChild(lay)
	lay:setLocalZOrder(yl.MAX_INT - 3)
end

--游戏说明窗口
function ClientScene:popHelpLayer( url, zorder)
	cclog("function ClientScene:popHelpLayer( url, zorder) ==>")
	zorder = zorder or yl.MAX_INT - 1
	local IntroduceLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.plaza.IntroduceLayer")
	local lay = IntroduceLayer:create(self, url)
	lay:setName(HELP_LAYER_NAME)
	self:addChild(lay)
	lay:setLocalZOrder(zorder)
end

--[TODO: 没有实现，暂用popHelpLayer代替]
function ClientScene:popHelpLayer2( kindId, type, zorder)
	cclog("function ClientScene:popHelpLayer2( kindId, type, zorder) ==>")
	self:popHelpLayer(kindId, zorder)
end

appdf.req(appdf.CLIENT_SRC .. "plaza.views.layer.game.VoiceRecorderKit")
function ClientScene:createVoiceBtn(pos, zorder, parent)

	cclog("function ClientScene:createVoiceBtn(pos, zorder, parent) ==>")
	parent = parent or self
	zorder = zorder or (yl.MAX_INT - 4)
	local function btncallback(ref, tType)
		if tType == ccui.TouchEventType.began then
			self:startVoiceRecord()
        elseif tType == ccui.TouchEventType.ended 
        	or tType == ccui.TouchEventType.canceled then
            self:stopVoiceRecord()
        end
    end
	pos = pos or cc.p(100, 100)
	local btn = ccui.Button:create("plazanew/btn_voice_chat_0.png", "plazanew/btn_voice_chat_1.png", "plazanew/btn_voice_chat_0.png")
	btn:setPosition(pos)
	btn:setName(VOICE_BTN_NAME)
	btn:addTo(parent)
	btn:setLocalZOrder(zorder)
    btn:addTouchEventListener(btncallback)
end

function ClientScene:startVoiceRecord()
	cclog("function ClientScene:startVoiceRecord() ==>")
	--防作弊不聊天
	if GlobalUserItem.isAntiCheat() then
		local runScene = cc.Director:getInstance():getRunningScene()
		showToast(runScene, "防作弊房间禁止聊天", 3)
		return
	end
	
	local lay = VoiceRecorderKit.createRecorderLayer(self, self._gameFrame)
	if nil ~= lay then
		lay:setName(VOICE_LAYER_NAME)
		self:addChild(lay)
	end
end

function ClientScene:stopVoiceRecord()

	cclog("function ClientScene:stopVoiceRecord() ==>")

	local voiceLayer = self:getChildByName(VOICE_LAYER_NAME)
	if nil ~= voiceLayer then
		voiceLayer:removeRecorde()
	end
end

function ClientScene:cancelVoiceRecord()

	cclog("function ClientScene:cancelVoiceRecord() ==>")

	local voiceLayer = self:getChildByName(VOICE_LAYER_NAME)
	if nil ~= voiceLayer then
		voiceLayer:cancelVoiceRecord()
	end
end

-- 邀请好友来一起玩
function ClientScene:inviteFriend(inviteFriend, gameKind, serverId, tableId, inviteMsg)
	cclog("function ClientScene:inviteFriend(inviteFriend, gameKind, serverId, tableId, inviteMsg) ==>")
	local tab = {}
    tab.dwInvitedUserID = inviteFriend
    tab.wKindID = gameKind
    tab.wServerID = serverId
    tab.wTableID = tableId
    tab.szInviteMsg = inviteMsg
    FriendMgr:getInstance():sendInviteGame(tab)
end

-- 好友截图分享
function ClientScene:imageShareToFriend( toFriendId, imagepath, shareMsg )
	cclog("function ClientScene:imageShareToFriend( toFriendId, imagepath, shareMsg ) ==>")

	local param = imagepath
    if cc.FileUtils:getInstance():isFileExist(param) then
    	self:showPopWait()
        --发送上传头像
        local url = yl.HTTP_URL .. "/WS/Account.ashx?action=uploadshareimage"
        local uploader = CurlAsset:createUploader(url,param)
        if nil == uploader then
            showToast(self, "分享图上传异常", 2)
            return
        end
        local nres = uploader:addToFileForm("file", param, "image/png")
        --用户标示
        nres = uploader:addToForm("userID", GlobalUserItem.dwUserID)
        --分享用户
        nres = uploader:addToForm("suserID", toFriendId)
        --登陆时间差
        local delta = tonumber(currentTime()) - tonumber(GlobalUserItem.LogonTime)
        cclog("time delta " .. delta)
        nres = uploader:addToForm("time", delta .. "")
        --客户端ip
        local ip = MultiPlatform:getInstance():getClientIpAdress() or "192.168.1.1"
        nres = uploader:addToForm("clientIP", ip)
        --机器码
        local machine = GlobalUserItem.szMachine or "A501164B366ECFC9E249163873094D50"
        nres = uploader:addToForm("machineID", machine)
        --会话签名
        nres = uploader:addToForm("signature", GlobalUserItem:getSignature(delta))
        if 0 ~= nres then
            showToast(self, "上传表单提交异常,error code ==> " .. nres, 2)
            return
        end

        uploader:uploadFile(function(sender, ncode, msg)
            local logtable = {}
            logtable.msg = msg
            logtable.ncode = ncode
            local jsonStr = cjson.encode(logtable)
            LogAsset:getInstance():logData(jsonStr,true)

            local ok, msgTab = pcall(function()
				return cjson.decode(msg)
			end)
            if ok then
            	local dataTab = msgTab["data"]
            	if type(dataTab) == "table" then
            		local address = ""
            		if true == dataTab["valid"] then
            			address = dataTab["ShareUrl"] or ""
            		end
            		local tab = {}
		            tab.dwSharedUserID = toFriendId
		            tab.szShareImageAddr = address
		            tab.szMessageContent = shareMsg
		            tab.szImagePath = imagepath
		            if FriendMgr:getInstance():sendShareMessage(tab) then
		            	showToast(self, "分享成功!", 2)
		           	end
            	end
            else

            end
            self:dismissPopWait()
        end)
    else
    	showToast(self, "您要分享的图片不存在, 请重试", 2)
    end
end


--系统消息
function ClientScene:onSysMessage(pData)
	cclog("ClientScene:onSysMessage===>")
	local wType = pData:readword()
	local wLength = pData:readword()
	local strContent = pData:readstring()
	table.insert(self.mBroadList, strContent)
end

--播放广播
function ClientScene:onBroadCastPlay(str)
	cclog("ClientScene:onBroadCastPlay===>" .. str)
	self.mIsBroadCasting = true
	self.mLbBroadCast:setString(str)
	self.mLbBroadCast:move(self.mNodeBCInit:getPosition())
	--
	local actMove = cc.MoveTo:create(10, cc.p(- self.mLbBroadCast:getContentSize().width, self.mNodeBCInit:getPositionY()))
	self.mLbBroadCast:runAction(cc.Sequence:create(actMove, cc.CallFunc:create(function()
		self.mIsBroadCasting = false
	end)))
end

--请求排行榜
function ClientScene:requestRanking()
	self:showPopWait()
	appdf.onHttpJsionTable(yl.HTTP_URL .. "/WS/PhoneRank.ashx","GET","action=getscorerank97&pageindex=1&pagesize=10&userid="..GlobalUserItem.dwUserID,function(jstable,jsdata)
		self:dismissPopWait()
		dump(jstable, "jstable", 5)
		if type(jstable) == "table" then
			self._rankList = {}
			for i = 1, #jstable do
				local item = {}
				item.szNickName = jstable[i]["NickName"]
				item.lScore = jstable[i]["Score"]..""
				item.wFaceID = tonumber(jstable[i]["FaceID"])
				item.lv = jstable[i]["Experience"]
				item.cbMemberOrder = tonumber(jstable[i]["MemberOrder"])
				item.dBeans = tonumber(jstable[i]["Currency"])
				item.lIngot = tonumber(jstable[i]["UserMedal"])
				item.dwGameID = tonumber(jstable[i]["GameID"])
				item.dwUserID = tonumber(jstable[i]["UserID"])
				item.szSign = jstable[i]["szSign"] or "此人很懒，没有签名"
				item.szIpAddress = jstable[i]["ip"]
				table.insert(self._rankList,item)
			end
			self:onShowRankingList()
		else
			showToast(self,"抱歉，获取排行榜信息失败！",2,cc.c3b(250,0,0))
		end
	end)	
end

--显示排行榜
function ClientScene:onShowRankingList()
	if #self._rankList == 0 then return end
    local testen = cc.Label:createWithSystemFont("A","Arial", 24)
    self._enSize = testen:getContentSize().width
    local testcn = cc.Label:createWithSystemFont("游","Arial", 24)
    self._cnSize = testcn:getContentSize().width
	for i = 1, #self._rankList do
		if i > 10 then break end
		local data = self._rankList[i]
		local node = appdf.getNodeByName(self.mRankingLayer, "node_rank_" .. i)
		node:getChildByName("lb_num"):setString("" .. i)
		node:getChildByName("lb_name"):setString(string.stringEllipsis(data.szNickName,self._enSize,self._cnSize, 250))
		node:getChildByName("lb_coin"):setString(ExternalFun.formatScoreText(tonumber(data.lScore)))
		node:setVisible(true)
	end
end


------------------------about update game res-------------------------
function ClientScene:onCheckUpdateSubgame()
	cclog("ClientScene:onCheckUpdateSubgame===>" .. json.encode(self:getApp()._gameList))
	local gameinfo = nil
	for k,v in ipairs(self:getApp()._gameList) do
		if tonumber(v._KindID) == G_GAME_KINDID then
		   gameinfo = v
		break end
	end
	--下载/更新资源 clientscene:getApp
	local app = self:getApp()
	local version = tonumber(app:getVersionMgr():getResVersion(gameinfo._KindID))
	if not version or gameinfo._ServerResVersion > version then
		return self:onUpdateSubGame(gameinfo)
	end	
	return false
end

--更新子游戏总入口
function ClientScene:onUpdateSubGame(gameinfo)
	cclog("function ClientScene:updateGame(gameinfo, index) ==>")
	--更新任务不处于空闲
	if not SubGameUpdateAgent:getInstance():isFree() then
		showToast(self, "游戏更新中,请稍候！", 1)
	return true end
	--开始更新
	local needUpdate = SubGameUpdateAgent:getInstance():createUpdateTask(gameinfo, self:getApp())
	if needUpdate then
		self.mUpdateMask = ExternalFun.loadCSB("clientscene/GameUpdateMask.csb", self)
		local circle = appdf.getNodeByName(self.mUpdateMask, "img_circle")
		local rf = cc.RepeatForever:create(cc.RotateBy:create(1.0, 360))
		circle:runAction(rf)
		appdf.getNodeByName(self.mUpdateMask, "lb_per"):setString("0%")
	else
		showToast(self, "无效游戏信息！",1)
	end

	return needUpdate
end

------------------------------代理更新回调------------------------
--更新进度
function ClientScene:updateProgress(sub, msg, mainpersent)
	cclog("function GameRoomLayer:updateProgress(sub, msg, mainpersent) ==> ")

	local permsg = string.format("%d%%", mainpersent)
	if self.mUpdateMask then
	   appdf.getNodeByName(self.mUpdateMask, "lb_per"):setString(permsg)
	end
end

--更新结果
function ClientScene:updateResult(result,msg)
	cclog("function GameRoomLayer:updateResult(result,msg) ==> ")

	if self.mUpdateMask then
	   self.mUpdateMask:removeFromParent()
	   self.mUpdateMask = nil
	end
	
	if result == true then
		local app = self:getApp()

		--更新版本号
		for k,v in pairs(app._gameList) do
			if v._KindID == SubGameUpdateAgent:getInstance()._downgameinfo._KindID then
				app:getVersionMgr():setResVersion(v._ServerResVersion, v._KindID)
				v._Active = true
				break
			end
		end
	else
		local runScene = cc.Director:getInstance():getRunningScene()
		if nil ~= runScene then
			QueryDialog:create(msg.."\n是否重试？",function(bReTry)
					if bReTry == true then
						self:onUpdateSubGame(SubGameUpdateAgent:getInstance()._downgameinfo)
					end
				end)
				:addTo(runScene)
		end		
	end
end

return ClientScene