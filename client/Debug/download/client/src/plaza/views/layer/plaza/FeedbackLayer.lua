-- Name: FeedbackLayer
-- Func: 反馈问题
-- Author: Johny


local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")

--返回按钮
local BT_EXIT 		= 101
--选择图片
local BT_PICIMG 	= 102
--发送按钮
local BT_SEND 		= 103
--我的反馈
local BT_MYFEEDBACk = 104

--我的反馈列表
local FeedbackListLayer = class("FeedbackListLayer", cc.Layer)
function FeedbackListLayer:ctor(scene)

	cclog("function FeedbackListLayer:ctor(scene) ==> ")

	self._scene = scene
	
	--加载csb资源
	local rootLayer, csbNode = ExternalFun.loadRootCSB("feedback/FeedbackListLayer.csb", self)
	self.m_csbNode = csbNode

	local function btncallback(ref, type)
        if type == ccui.TouchEventType.ended then
         	self:onButtonClickedEvent(ref:getTag(),ref)
        end
    end

    --返回按钮
    local btn = csbNode:getChildByName("btn_back")
    btn:setTag(BT_EXIT)
    btn:addTouchEventListener(btncallback)
end

function FeedbackListLayer:onButtonClickedEvent( tag, sender )

	cclog("function FeedbackListLayer:onButtonClickedEvent( tag, sender ) ==> ")

	if BT_EXIT == tag then
		self._scene:onKeyBack()		
	end
end

--反馈编辑界面
local FeedbackLayer = class("FeedbackLayer", cc.Layer)
function FeedbackLayer.createFeedbackList( scene )

	cclog("function FeedbackLayer.createFeedbackList( scene ) ==> ")

	local list = FeedbackListLayer.new(scene)
	return list
end

function FeedbackLayer:ctor( scene )
	cclog("function FeedbackLayer:ctor( scene ) ==> ")

	self._scene = scene

	--加载csb资源
	local rootLayer, csbNode = ExternalFun.loadRootCSB("optionnew/FeedbackSendLayer.csb", self)
	self.m_csbNode = csbNode

	local function btncallback(ref, type)
        if type == ccui.TouchEventType.ended then
         	self:onButtonClickedEvent(ref:getTag(),ref)
        end
    end
    --返回按钮
    local btn = appdf.getNodeByName(csbNode, "btn_return")
    btn:setTag(BT_EXIT)
    btn:addTouchEventListener(btncallback)
  

	local tmp = appdf.getNodeByName(csbNode, "img_bg2")
	--平台判定
	local targetPlatform = cc.Application:getInstance():getTargetPlatform()
	if (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform) or (cc.PLATFORM_OS_ANDROID == targetPlatform) then
		--反馈页面
		self.m_webView = ccexp.WebView:create()
	    self.m_webView:setPosition(cc.p(667, 322))
	    self.m_webView:setContentSize(cc.size(1260, 580))
	    
	    self.m_webView:setScalesPageToFit(true)
	    local url = yl.HTTP_URL .. "/SyncLogin.aspx?userid=" .. GlobalUserItem.dwUserID .. "&time=".. os.time() .. "&signature="..GlobalUserItem:getSignature(os.time()).."&url=/Mobile/Feedback.aspx"
	    self.m_webView:loadURL(url)
        ExternalFun.visibleWebView(self.m_webView, false)
	    self._scene:showPopWait()

	    self.m_webView:setOnJSCallback(function ( sender, url )
	    	    	
	    end)

	    self.m_webView:setOnDidFailLoading(function ( sender, url )
	    	self._scene:dismissPopWait()
	    	cclog("open " .. url .. " fail")
	    end)
	    self.m_webView:setOnShouldStartLoading(function(sender, url)
	        cclog("onWebViewShouldStartLoading, url is ", url)	        
	        return true
	    end)
	    self.m_webView:setOnDidFinishLoading(function(sender, url)
	    	self._scene:dismissPopWait()
            ExternalFun.visibleWebView(self.m_webView, true)
	        cclog("onWebViewDidFinishLoading, url is ", url)
	    end)
	    self:addChild(self.m_webView)
	end
end

function FeedbackLayer:onButtonClickedEvent( tag, sender )
	cclog("function FeedbackLayer:onButtonClickedEvent( tag, sender ) ==> ")

	if BT_EXIT == tag then
		self._scene:onKeyBack()
	elseif BT_PICIMG == tag then
		MultiPlatform:getInstance():triggerPickImg(function ( param )
			if type(param) == "string" then
				cclog("lua path ==> " .. param)
			end
		end, false)
	elseif BT_SEND == tag then
		
	elseif BT_MYFEEDBACk == tag then
		self._scene:onChangeShowMode(yl.SCENE_FEEDBACKLIST)
	end
end

return FeedbackLayer