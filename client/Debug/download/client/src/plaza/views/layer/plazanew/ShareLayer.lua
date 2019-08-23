-- Name: ShareLayer
-- Func: 分享界面
-- Author: Johny

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")

local ShareLayer = class("ShareLayer", cc.Layer)

local BTN_CLOSE     = 1
local BTN_WECHAT    = 2
local BTN_MOMENT    = 3

function ShareLayer:ctor(scene)
	self._scene = scene

	local btcallback = function(ref, type)
		if type == ccui.TouchEventType.ended then
			self:OnButtonClickedEvent(ref:getTag(),ref)
        end
	end

	local csbNode = ExternalFun.loadCSB("share/GameShareLayer.csb", self)

	local btn_close = appdf.getNodeByName(csbNode, "btn_close")
	btn_close:setTag(BTN_CLOSE)
	btn_close:addTouchEventListener(btcallback)

	local btn_wechat = appdf.getNodeByName(csbNode, "btn_wechat")
	btn_wechat:setTag(BTN_WECHAT)
	btn_wechat:addTouchEventListener(btcallback)

	local btn_moment = appdf.getNodeByName(csbNode, "btn_moment")
	btn_moment:setTag(BTN_MOMENT)
	btn_moment:addTouchEventListener(btcallback)

end

--按键响应
function ShareLayer:OnButtonClickedEvent(tag,ref)
	if tag == BTN_CLOSE then
		self:removeFromParent()
	elseif tag == BTN_WECHAT then
		self:onWechatShare()
	elseif tag == BTN_MOMENT then
		self:onMomentShare()
	end
end

--微信分享
function ShareLayer:onWechatShare()
	local function sharecall( isok )
	    if type(isok) == "string" and isok == "true" then
	        -- showToast(self, "分享完成", 1)
	    end
	end
	local url = GlobalUserItem.szWXSpreaderURL or yl.HTTP_URL
	cclog("ShareLayer:onWechatShare===>" .. yl.SocialShare.content .. "=" .. url)
	MultiPlatform:getInstance():shareToTarget(yl.ThirdParty.WECHAT, sharecall, yl.SocialShare.title, yl.SocialShare.content, url)
end

--朋友圈分享
function ShareLayer:onMomentShare()
	local function sharecall( isok )
        if type(isok) == "string" and isok == "true" then
            -- showToast(self, "分享完成", 1)
        end
    end
    local url = GlobalUserItem.szWXSpreaderURL or yl.HTTP_URL
    cclog("ShareLayer:onMomentShare===>" .. yl.SocialShare.content .. "=" .. url)
    MultiPlatform:getInstance():shareToTarget(yl.ThirdParty.WECHAT_CIRCLE, sharecall, yl.SocialShare.title, yl.SocialShare.content, url)
end

return ShareLayer
