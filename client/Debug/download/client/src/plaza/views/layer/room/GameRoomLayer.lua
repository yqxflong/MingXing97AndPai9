-- Name: GameRoomLayer
-- Func: 游戏房间层
-- Author: Johny

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local GameRoomLayer = class("GameRoomLayer", cc.Layer)
local QueryDialog = appdf.req("app.views.layer.other.QueryDialog")


local BT_CREATEROOM   = 11
local BT_JOINROOM     = 12
local BT_MYROOM       = 13


function GameRoomLayer:onExit(  )
	cclog("GameRoomLayer:onExit===>")
	G_unSchedule(self.mSpineAniScheduler)
	self.mSpineAniScheduler = nil
end

-- 退出场景而且开始过渡动画时候触发。
function GameRoomLayer:onExitTransitionStart()
	cclog("function GameRoomLayer:onExitTransitionStart() ==> ")
	----设置更新代理
    SubGameUpdateAgent:getInstance():setDelegate(nil)
end


function GameRoomLayer:onEnterTransitionFinish(  )
	cclog("GameRoomLayer:onEnterTransitionFinish===>")
	----设置更新代理
    SubGameUpdateAgent:getInstance():setDelegate(self)
end

function GameRoomLayer:ctor(scene, gamelist)
	cclog("GameRoomLayer:ctor===>")
	self._scene = scene
	self._gameList = gamelist
	self.mUpdateMask = nil

	--注册事件
	self:registerScriptHandler(function(eventType)
		if eventType == "enterTransitionFinish" then	-- 进入场景而且过渡动画结束时候触发。
			self:onEnterTransitionFinish()
		elseif eventType == "exitTransitionStart" then	-- 退出场景而且开始过渡动画时候触发。
			self:onExitTransitionStart()
        elseif eventType == "exit" then
        	self:onExit()
		end
	end)

	local btcallback = function(ref, type)
        if type == ccui.TouchEventType.ended then
         	self:onButtonClickedEvent(ref:getTag(),ref)
        end
    end

	local csbNode = ExternalFun.loadCSB("clientscene/GameRoomLayer.csb", self)
	local img_bg = csbNode:getChildByName("img_bg")

	--create
    local btn_create = appdf.getNodeByName(csbNode, "btn_create")
    btn_create:setTag(BT_CREATEROOM)
    btn_create:addTouchEventListener(btcallback)

    --join
    local btn_join = appdf.getNodeByName(csbNode, "btn_join")
    btn_join:setTag(BT_JOINROOM)
    btn_join:addTouchEventListener(btcallback)

    --myroom
    local btn_myroom = appdf.getNodeByName(csbNode, "btn_myroom")
    btn_myroom:setTag(BT_MYROOM)
    btn_myroom:addTouchEventListener(btcallback)

    --spine
    self:loadAnimationGirl(img_bg)
end

function GameRoomLayer:loadAnimationGirl(img_bg)
    local node_girl = img_bg:getChildByName("node_girl")
    self.mSpineMM = GG_createSpine("clientscene/skeleton.json", "clientscene/skeleton.atlas", 1.0)
    self.mSpineMM:addTo(node_girl)
    --正常动作
    self.mSpineMM:setAnimation(0, "huxi", true)
    --特殊动作
    self.mSpineAniScheduler = nextTick_eachSecond(function()
    	    if not self.mSpineMM then return end
    		if math.random(1,10) >= 8 then
    		   self.mSpineMM:addAnimation(0, "dadong", false)
    		   self.mSpineMM:addAnimation(0, "huxi", true)
    		else
    			self.mSpineMM:addAnimation(0, "zhayan", false)
    			self.mSpineMM:addAnimation(0, "huxi", true)
    		end
    	end, 10.0)
end


function GameRoomLayer:onButtonClickedEvent(tag,ref)
	GlobalUserItem.nCurGameKind = G_GAME_KINDID
	GlobalUserItem.szCurGameName = yl.getSubGameFolder("" .. G_GAME_KINDID)
	self._scene:onChangeShowMode(yl.SCENE_ROOMLIST)
end


function GameRoomLayer:onCheckUpdateSubgame()
	cclog("GameRoomLayer:onCheckUpdateSubgame===>" .. json.encode(self._gameList))
	local gameinfo = nil
	for k,v in ipairs(self._gameList) do
		if tonumber(v._KindID) == G_GAME_KINDID then
		   gameinfo = v
		break end
	end
	--下载/更新资源 clientscene:getApp
	local app = self._scene:getApp()
	local version = tonumber(app:getVersionMgr():getResVersion(gameinfo._KindID))
	if not version or gameinfo._ServerResVersion > version then
		return self:onUpdateSubGame(gameinfo)
	end	
	return false
end

--更新子游戏总入口
function GameRoomLayer:onUpdateSubGame(gameinfo)
	cclog("function GameRoomLayer:updateGame(gameinfo, index) ==>")
	--更新任务不处于空闲
	if not SubGameUpdateAgent:getInstance():isFree() then
		showToast(self, "游戏更新中,请稍候！", 1)
	return true end
	--开始更新
	local needUpdate = SubGameUpdateAgent:getInstance():createUpdateTask(gameinfo, self._scene:getApp())
	if needUpdate then
		self.mUpdateMask = ExternalFun.loadCSB("clientscene/GameUpdateMask.csb", self._scene)
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
function GameRoomLayer:updateProgress(sub, msg, mainpersent)
	cclog("function GameRoomLayer:updateProgress(sub, msg, mainpersent) ==> ")

	local permsg = string.format("%d%%", mainpersent)
	if self.mUpdateMask then
	   appdf.getNodeByName(self.mUpdateMask, "lb_per"):setString(permsg)
	end
end

--更新结果
function GameRoomLayer:updateResult(result,msg)
	cclog("function GameRoomLayer:updateResult(result,msg) ==> ")

	if self.mUpdateMask then
	   self.mUpdateMask:removeFromParent()
	   self.mUpdateMask = nil
	end
	
	if result == true then
		local app = self._scene:getApp()

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

return GameRoomLayer