-- Name: ReplayDetailLayer
-- Func: 战绩详细界面
-- Author: Johny

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local ReplayManager = appdf.req(appdf.CLIENT_SRC .. "replay.ReplayManager")

local ReplayDetailLayer = class("ReplayDetailLayer", cc.Layer)


--------------------------------------常量定义------------------------------------
local BTN_CLOSE     = 1




function ReplayDetailLayer:onEnterTransitionFinish()
    cclog("ReplayDetailLayer:onEnterTransitionFinish")
end

-- 退出场景而且开始过渡动画时候触发。
function ReplayDetailLayer:onExitTransitionStart()
    cclog("function ReplayDetailLayer:onExitTransitionStart() ==>")


    return self
end



function ReplayDetailLayer:ctor(replaymainlayer, frame, kindid, recordid)
	cclog("function ReplayDetailLayer:ctor(scene) ==>")

    self:registerScriptHandler(function(eventType)
        if eventType == "enterTransitionFinish" then  -- 进入场景而且过渡动画结束时候触发。
            self:onEnterTransitionFinish()
        elseif eventType == "exitTransitionStart" then  -- 退出场景而且开始过渡动画时候触发。
            self:onExitTransitionStart()
        end
    end)

	self._mainLayer = replaymainlayer
	self._frame = frame
	self._manager = ReplayManager:getInstance()
	self._kindID   = kindid
	self._recordID = recordid

	self:setContentSize(yl.WIDTH,yl.HEIGHT) 
	self:layoutUI()
end

function ReplayDetailLayer:getDataTableView(size, pos)
	cclog("function ReplayDetailLayer:getDataTableView(size) ==>")


	--tableview
	local m_tableView = cc.TableView:create(size)
	m_tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
	m_tableView:setVerticalFillOrder(0)
	m_tableView:setPosition(pos)
	m_tableView:setDelegate()
	m_tableView:registerScriptHandler(handler(self, self.cellSizeForTable), cc.TABLECELL_SIZE_FOR_INDEX)
	m_tableView:registerScriptHandler(handler(self, self.tableCellAtIndex), cc.TABLECELL_SIZE_AT_INDEX)
	-- m_tableView:registerScriptHandler(handler(self, self.tableCellTouched), cc.TABLECELL_TOUCHED)
	m_tableView:registerScriptHandler(handler(self, self.numberOfCellsInTableView), cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
	return m_tableView
end

function ReplayDetailLayer:layoutUI()
	local  btcallback = function(ref, type)
    	if type == ccui.TouchEventType.ended then
         	self:onButtonClickedEvent(ref:getTag(),ref)
        end
    end

	--layout
	local csbNode = ExternalFun.loadCSB("gamerecord/GameRecordDetailLayer.csb", self)

	--close
	local btn_close = appdf.getNodeByName(csbNode, "btn_close")
	btn_close:setTag(BTN_CLOSE)
	btn_close:addTouchEventListener(btcallback)


	--head
	local oneRecord = self._manager:getOneRecord(self._kindID, self._recordID)
	if oneRecord then
		for i = 1, oneRecord.m_nUserCount do
			local lb_p1 = appdf.getNodeByName(csbNode, string.format("lb_p%d", i))
			lb_p1:setString(oneRecord.userinfo[i].strNickName)
			lb_p1:setVisible(true)
		end
	end


	--detail layer
	local content = appdf.getNodeByName(csbNode, "content")
	self.mDetailView = self:getDataTableView(content:getContentSize(), cc.p(content:getPosition()))
	content:getParent():addChild(self.mDetailView)
	content:removeFromParent()
	self.mDetailView:reloadData()
end

--离开界面
function ReplayDetailLayer:onExit()
	self:removeFromParent()
end




------------------------call back----------------------------------------------
function ReplayDetailLayer:onButtonClickedEvent(tag,ref)
	cclog("function ReplayDetailLayer:onButtonClickedEvent(tag,ref) ==>")

	if tag == BTN_CLOSE then
		self:removeFromParent()
	end
end

--子记录回放按钮事件
function ReplayDetailLayer:onChildRecordPlay(sender, type)
	if type == ccui.TouchEventType.ended then
		local childid = sender:getTag()
		self._manager.mCurChildId = childid
		self._mainLayer:requestPlayOneChildRecord(self._recordID, childid)
	end
end

------------------------------delegate------------------------------------------------
function ReplayDetailLayer:cellSizeForTable( view, idx )
	return 980, 120
end

function ReplayDetailLayer:tableCellAtIndex(view, idx)
	local cell = view:dequeueCell()

	if nil == cell then
		cell = cc.TableViewCell:new()
		local csbNode = ExternalFun.loadCSB("gamerecord/GameRecordDetailCell.csb")
		csbNode:setName("csbNode")
		cell:addChild(csbNode)
		local btn_play = appdf.getNodeByName(csbNode, "btn_play")
		btn_play:addTouchEventListener(handler(self, self.onChildRecordPlay))
	end

	--数据组
	local oneTime = self._manager.mSubRecord[idx + 1]
	--界面
	local csbNode = cell:getChildByName("csbNode")
	local lb_id = csbNode:getChildByName("lb_id")
	lb_id:setString(idx + 1)
	local lb_date = csbNode:getChildByName("lb_date")
	lb_date:setString(string.format("%d-%d-%d", oneTime.m_PlayTime.wYear, oneTime.m_PlayTime.wMonth, oneTime.m_PlayTime.wDayOfWeek))
	local lb_time = csbNode:getChildByName("lb_time")
	lb_time:setString(string.format("%d:%d", oneTime.m_PlayTime.wHour, oneTime.m_PlayTime.wMinute))
	--score
	--先隐藏所有分数
	for i =1 ,4 do
		local lb_p1 = appdf.getNodeByName(csbNode, string.format("lb_p%d", i))
		lb_p1:setVisible(false)
	end
	local oneRecord = self._manager:getOneRecord(self._kindID, self._recordID)
	if oneRecord then
		for i = 1, oneRecord.m_nUserCount do
			local lb_p1 = appdf.getNodeByName(csbNode, string.format("lb_p%d", i))
			local userinfo = oneRecord.userinfo[i]
			local score = oneTime.scoretab[tostring(userinfo.UserId)]
			if score then
				if score >= 0 then
				   lb_p1:setString("+" .. score)
				else
	 			   lb_p1:setString(tostring(score))
				end
			else--房间解散，没分
				lb_p1:setString("中断")
			end
			lb_p1:setVisible(true)
		end
	end

	--按钮
	local btn_play = csbNode:getChildByName("btn_play")
	btn_play:setTag(oneTime.m_iRecordChildID) 

	cell:setTag(idx)
	return cell
end

function ReplayDetailLayer:numberOfCellsInTableView( view )
	return #self._manager.mSubRecord
end

return ReplayDetailLayer