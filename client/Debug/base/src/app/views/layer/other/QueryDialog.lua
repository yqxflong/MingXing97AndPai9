-- Name: QueryDialog
-- Func: 系统对话框
-- Author: Johny


local QueryDialog = class("QueryDialog", function(msg,callback)
		local queryDialog = display.newLayer()
    return queryDialog
end)

--默认字体大小
QueryDialog.DEF_TEXT_SIZE 	= 32

--UI标识
QueryDialog.DG_QUERY_EXIT 	=  2 
QueryDialog.BT_CANCEL		=  0   
QueryDialog.BT_CONFIRM		=  1

-- 对话框类型
QueryDialog.QUERY_SURE 			= 1
QueryDialog.QUERY_SURE_CANCEL 	= 2

-- 进入场景而且过渡动画结束时候触发。
function QueryDialog:onEnterTransitionFinish()
    return self
end

-- 退出场景而且开始过渡动画时候触发。
function QueryDialog:onExitTransitionStart()
	self:unregisterScriptTouchHandler()
    return self
end

--窗外触碰
function QueryDialog:setCanTouchOutside(canTouchOutside)
	self._canTouchOutside = canTouchOutside
	return self
end

--
local function loadCSB(csbFile, parent)
	local csbnode = cc.CSLoader:createNode(csbFile);
	if nil ~= parent then
		parent:addChild(csbnode);
	end
	return csbnode;	
end

--msg 显示信息
--callback 交互回调
--txtsize 字体大小
function QueryDialog:ctor(msg, callback, txtsize, queryType)
	queryType = queryType or QueryDialog.QUERY_SURE_CANCEL
	self._callback = callback
	self._canTouchOutside = true

	local this = self 
	self:setContentSize(G_WIDTH_GLVIEW, G_HEIGHT_GLVIEW)

	--回调函数
	self:registerScriptHandler(function(eventType)
		if eventType == "enterTransitionFinish" then	-- 进入场景而且过渡动画结束时候触发。
			this:onEnterTransitionFinish()
		elseif eventType == "exitTransitionStart" then	-- 退出场景而且开始过渡动画时候触发。
			this:onExitTransitionStart()
		end
	end)

	--按键监听
	local  btcallback = function(ref, type)
        if type == ccui.TouchEventType.ended then
         	this:onButtonClickedEvent(ref:getTag(),ref)
        end
    end

    --
	local csbNode = loadCSB("QueryDialog.csb", self)
    local img_bg = csbNode:getChildByName("img_bg")
    self.mImg_bg = img_bg

    --button
    if QueryDialog.QUERY_SURE == queryType then
        local btn_ok = img_bg:getChildByName("btn_ok")
        btn_ok:setTag(QueryDialog.BT_CONFIRM)
        btn_ok:addTouchEventListener(btcallback)
    else
        local btn_ok = img_bg:getChildByName("btn_ok")
        btn_ok:setTag(QueryDialog.BT_CONFIRM)
        btn_ok:addTouchEventListener(btcallback)

        local btn_cancel = img_bg:getChildByName("btn_cancel")
        btn_cancel:setTag(QueryDialog.BT_CANCEL)
        btn_cancel:addTouchEventListener(btcallback)
    end

    --content
    local lb_maintext = img_bg:getChildByName("lb_maintext")
    lb_maintext:ignoreContentAdaptWithSize(false); 
    lb_maintext:setSize(cc.size(400, 200))
    lb_maintext:setString(msg)

    local lb_subtext = img_bg:getChildByName("lb_subtext")
    lb_subtext:setVisible(false)

    self.mImg_bg:setPositionY(G_HEIGHT_GLVIEW + img_bg:getContentSize().height*0.5)
	self._dismiss  = false
	self.mImg_bg:runAction(cc.MoveTo:create(0.3,cc.p(G_WIDTH_GLVIEW/2,G_HEIGHT_GLVIEW/2)))
end

--按键点击
function QueryDialog:onButtonClickedEvent(tag,ref)
	if self._dismiss == true then
		return
	end
	--取消显示
	self:dismiss()
	--通知回调
	if self._callback then
		self._callback(tag == QueryDialog.BT_CONFIRM)
	end
end

--取消消失
function QueryDialog:dismiss()
	self._dismiss = true
	local this = self
	self.mImg_bg:stopAllActions()
	self.mImg_bg:runAction(
		cc.Sequence:create(
			cc.MoveTo:create(0.3, cc.p(G_WIDTH_GLVIEW / 2, G_HEIGHT_GLVIEW + self.mImg_bg:getContentSize().height*0.5)),
			cc.CallFunc:create(function()
					this:removeSelf()
				end)
			))	
end

return QueryDialog
