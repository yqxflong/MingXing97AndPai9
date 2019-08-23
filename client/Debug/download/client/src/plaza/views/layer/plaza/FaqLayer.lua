-- Name: FaqLayer
-- Func: 常见问题
-- Author: Johny



local FaqLayer = class("FaqLayer", cc.Layer)
local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")

--返回按钮
local BT_EXIT 		= 101
function FaqLayer:ctor( scene )

	cclog("function FaqLayer:ctor( scene ) ==> ")

	self._scene = scene

	--加载csb资源
	local rootLayer, csbNode = ExternalFun.loadRootCSB("optionnew/FaqLayer.csb", self)
	local img_bg = csbNode:getChildByName("img_bg")

	local function btncallback(ref, type)
        if type == ccui.TouchEventType.ended then
         	self:onButtonClickedEvent(ref:getTag(),ref)
        end
    end

    --返回按钮
    local btn = appdf.getNodeByName(img_bg, "btn_return")
    btn:setTag(BT_EXIT)
    btn:addTouchEventListener(btncallback)

	local tmp = appdf.getNodeByName(img_bg, "img_bg2")
	--平台判定
	local targetPlatform = cc.Application:getInstance():getTargetPlatform()
	if (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform) or (cc.PLATFORM_OS_ANDROID == targetPlatform) then
		--页面
		self.m_webView = ccexp.WebView:create()
	    self.m_webView:setPosition(tmp:getPosition())
	    self.m_webView:setContentSize(cc.size(1155, 520))
	    
	    self.m_webView:setScalesPageToFit(true)
	    local url = yl.HTTP_URL .. "/Mobile/Faq.aspx"
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
	    img_bg:addChild(self.m_webView)
	end
end

function FaqLayer:onButtonClickedEvent( tag, sender )

	cclog("function FaqLayer:onButtonClickedEvent( tag, sender ) ==> ")

	if BT_EXIT == tag then
		self._scene:onKeyBack()
	end
end

return FaqLayer