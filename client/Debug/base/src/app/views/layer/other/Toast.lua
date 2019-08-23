-- Name: Toast
-- Func: 全局函数，显示提示条
-- Author: Johny


local WINSIZE = GG_GetWinSize()

function showToast(context,message,delaytime,color)
	if (context == nil) or  (message == nil) or (delaytime<1) then
		return
	end

	local msgtype = type(message)
	if msgtype == "userdata" or msgtype == "table" then
		return
	end

	if message == "" then
		return
	end
	local showMessage = message	
	local bg = context:getChildByName("toast_bg")
	bg = ccui.ImageView:create("base_toast.png")
	bg:setOpacity(0)
	bg:move(WINSIZE.width/2, WINSIZE.height/2)
	bg:addTo(context)
	bg:setName("toast_bg")
	bg:setScale9Enabled(true)
	bg:runAction(cc.Sequence:create(cc.FadeTo:create(0.5,255), 
		cc.DelayTime:create(delaytime), 
		cc.Spawn:create(cc.FadeTo:create(0.5,0),cc.CallFunc:create(function()
			lab:runAction(cc.FadeTo:create(0.5,0))
			end)), 
		cc.RemoveSelf:create(true)))

	lab = cc.Label:createWithTTF(showMessage, "fonts/yuanti_sc_light.ttf", 24, cc.size(750,0))
	lab:setName("toast_lab")
	lab:setTextColor(not color and cc.c4b(255,255,255,255) or color)
	lab:addTo(bg)

	if nil ~= lab and nil ~= bg then
		lab:setString(showMessage)
		lab:setTextColor(not color and cc.c4b(255,255,255,255) or color)
		local labSize = lab:getContentSize()		
		lab:setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
		lab:move(WINSIZE.width/2, bg:getContentSize().height * 0.5)
	end
end

--不渐变形式toast(fadeto方法，在安卓调用的时候会导致底图不显示)
function showToastNoFade(context,message,delaytime,color)
	if (context == nil) or  (message == nil) or (delaytime<1) then
		return
	end

	local msgtype = type(message)
	if msgtype == "userdata" or msgtype == "table" then
		return
	end

	if message == "" then
		return
	end
	local showMessage = message	
	
	local bg = context:getChildByName("toast_bg")
	local lab = nil
	if bg then
		bg:stopAllActions()
		lab = bg:getChildByName("toast_lab")
	else
		bg = ccui.ImageView:create("base_toast.png")
		bg:move(WINSIZE.width/2, G_HEIGHT_GLVIEW/2)
		bg:addTo(context)
		bg:setName("toast_bg")
		bg:setScale9Enabled(true)		

		lab = cc.Label:createWithTTF(showMessage, "fonts/yuanti_sc_light.ttf", 24, cc.size(930,0))
		lab:setName("toast_lab")
		
		lab:setTextColor(not color and cc.c4b(255,255,255,255) or color)
		lab:addTo(bg)
	end

	if nil ~= lab and nil ~= bg then
		lab:setString(showMessage)
		lab:setTextColor(not color and cc.c4b(255,255,255,255) or color)
		bg:runAction(cc.Sequence:create(cc.DelayTime:create(delaytime), cc.RemoveSelf:create(true)))

		local labSize = lab:getContentSize()
		if labSize.height < 30 then
			lab:setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
			bg:setContentSize(cc.size(WINSIZE.width, 64))
		else
			lab:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
			bg:setContentSize(cc.size(WINSIZE.width, 64 + labSize.height))		
		end
		lab:move(WINSIZE.width * 0.5, bg:getContentSize().height * 0.5)
	end
end