-- Name: ReplayLayer
-- Func: 战绩主界面, 战绩相关界面宿主
-- Author: Johny

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local ReplayFrame = appdf.req(appdf.CLIENT_SRC.."replay.models.ReplayFrame")
local ReplayDetailLayer = appdf.req(appdf.CLIENT_SRC.."replay.views.ReplayDetailLayer")
local ReplayManager = appdf.req(appdf.CLIENT_SRC .. "replay.ReplayManager")


local ReplayLayer = class("ReplayLayer", cc.Layer)

--------------------------------------常量定义------------------------------------
local BTN_CLOSE     = 1


-----------------------------------局部函数------------------------------------
local function tableView_cell_hideall_name_score(csbNode)
	for i = 1, 4 do
		local lb_p = csbNode:getChildByName("lb_name_" .. i)
		lb_p:setVisible(false)
	end
	for i =1, 4 do
		local lb_score = csbNode:getChildByName("lb_score_" .. i)
		lb_score:setVisible(false)
	end
end

-------------------------------------------------------------------
function ReplayLayer:onEnterTransitionFinish()
    cclog("ReplayLayer:onEnterTransitionFinish")
    self._scene:showPopWait()
    self._frame:onSendTotalGameRecordRequest()
end

-- 退出场景而且开始过渡动画时候触发。
function ReplayLayer:onExitTransitionStart()
    cclog("function ReplayLayer:onExitTransitionStart() ==>")
    self._frame:destroy()

    return self
end

function ReplayLayer:ctor(scene)
	cclog("function ReplayLayer:ctor(scene) ==>")
	ExternalFun.registerNodeEvent(self)

    self:registerScriptHandler(function(eventType)
        if eventType == "enterTransitionFinish" then  -- 进入场景而且过渡动画结束时候触发。
            self:onEnterTransitionFinish()
        elseif eventType == "exitTransitionStart" then  -- 退出场景而且开始过渡动画时候触发。
            self:onExitTransitionStart()
        end
    end)



	self._scene = scene
	self._manager = ReplayManager:getInstance()
	self._manager:setClientScene(scene)
	

	--网络回调
    local netCallBack = function(result,message)
		self:onNetCallBack(result,message)
	end
    --网络处理
	self._frame = ReplayFrame:create(self, netCallBack)

	--详细界面
	self.mDetailLayer = nil


	self:setContentSize(yl.WIDTH,yl.HEIGHT) 
	self:layoutUI()
end

function ReplayLayer:getDataTableView(size, pos)
	cclog("function ReplayLayer:getDataTableView(size) ==>")


	--tableview
	local m_tableView = cc.TableView:create(size)
	m_tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
	m_tableView:setVerticalFillOrder(1)
	m_tableView:setPosition(pos)
	m_tableView:setDelegate()
	m_tableView:registerScriptHandler(handler(self, self.cellSizeForTable), cc.TABLECELL_SIZE_FOR_INDEX)
	m_tableView:registerScriptHandler(handler(self, self.tableCellAtIndex), cc.TABLECELL_SIZE_AT_INDEX)
	m_tableView:registerScriptHandler(handler(self, self.tableCellTouched), cc.TABLECELL_TOUCHED)
	m_tableView:registerScriptHandler(handler(self, self.numberOfCellsInTableView), cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
	return m_tableView
end

function ReplayLayer:layoutUI()
	local  btcallback = function(ref, type)
    	if type == ccui.TouchEventType.ended then
         	self:onButtonClickedEvent(ref:getTag(),ref)
        end
    end

	--layout
	local csbNode = ExternalFun.loadCSB("gamerecord/GameRecordLayer.csb", self)

	--close
	local btn_close = appdf.getNodeByName(csbNode, "btn_close")
	btn_close:setTag(BTN_CLOSE)
	btn_close:addTouchEventListener(btcallback)


	--detail layer
	local content = appdf.getNodeByName(csbNode, "content")
	self.mDetailView = self:getDataTableView(content:getContentSize(), cc.p(content:getPosition()))
	content:getParent():addChild(self.mDetailView)
	content:removeFromParent()
end


--请求回放一个子记录
function ReplayLayer:requestPlayOneChildRecord(recordid, childid)
	self._scene:showPopWait()
	self._frame:onSendOneTimeOperationRequest(recordid, childid)
end

------------------------call back----------------------------------------------
--列表回调
function ReplayLayer:onGameHeadListEvent(ref, type)
   --先取消所有选中
   for k, item in ipairs(self.mGameHeadList:getItems()) do
   	   listview_item_selected_display(item:getChildByName("csbNode"), false)
   end
   listview_item_selected_handle(self, ref:getParent():getParent())
end


function ReplayLayer:onButtonClickedEvent(tag,ref)
	cclog("function ReplayLayer:onButtonClickedEvent(tag,ref) ==>")

	if tag == BTN_CLOSE then
		self:removeFromParent()
	end
end

--网络回调
function ReplayLayer:onNetCallBack(result, tips)
    cclog("function ReplayLayer:onNetCallBack(result, tips) ==>")
    self._scene:dismissPopWait()

    if type(tips) == "string" and "" ~= tips then
        showToast(self, tips, 2)
    end 

    if ReplayFrame.OP_TOTALRECORD_RESULT == result then --回调总记录
    	self:onTotalRecordCallback()
    elseif ReplayFrame.OP_SUBRECORD_RESULT == result then --回调子记录
    	self:onSubRecordCallBack()
    elseif ReplayFrame.OP_ONETIME_RESULT == result then --回调具体操作
    	self:onOneTimeOperationCallback()
    end
end

--回调总记录
function ReplayLayer:onTotalRecordCallback()
	self._manager.mSelectedKindID = G_GAME_KINDID
	self.mDetailView:reloadData()
end

--回调子记录
function ReplayLayer:onSubRecordCallBack()
	--显示详细界面
	self.mDetailLayer = ReplayDetailLayer:create(self, self._frame, self._manager.mSelectedKindID, self._manager.mCurRecordId)
	self:addChild(self.mDetailLayer)
end

--回调一圈具体操作
function ReplayLayer:onOneTimeOperationCallback()
	--进入回放场景
	self._manager:enterReplay()	
	self.mDetailLayer:onExit()
	self:removeFromParent()
end

------------------------------delegate------------------------------------------------
function ReplayLayer:cellSizeForTable( view, idx )
	return 980, 120
end

function ReplayLayer:tableCellAtIndex(view, idx)
	local cell = view:dequeueCell()

	if nil == cell then
		cell = cc.TableViewCell:new()
		local csbNode = ExternalFun.loadCSB("gamerecord/GameRecordCell.csb")
		csbNode:setName("csbNode")
		cell:addChild(csbNode)
	end
	--数据组
	local oneRecord = self._manager.mTotalRecord[self._manager.mSelectedKindID][idx + 1]
	--界面
	local csbNode = cell:getChildByName("csbNode")
	local lb_roomnum = csbNode:getChildByName("lb_roomid")
	lb_roomnum:setString(string.format("%06d", oneRecord.m_iRoomNum))
	local lb_date = csbNode:getChildByName("lb_date")
	lb_date:setString(string.format("%d-%d-%d", oneRecord.m_StartTime.wYear, oneRecord.m_StartTime.wMonth, oneRecord.m_StartTime.wDayOfWeek))
	local lb_time = csbNode:getChildByName("lb_time")
	lb_time:setString(string.format("%d:%d", oneRecord.m_StartTime.wHour, oneRecord.m_StartTime.wMinute))
	--
	tableView_cell_hideall_name_score(csbNode)
	for i = 1, oneRecord.m_nUserCount do
		local uinfo = oneRecord.userinfo[i]
		local lb_player = csbNode:getChildByName("lb_name_" .. i)
		lb_player:setString(uinfo.strNickName)
		lb_player:setVisible(true)
		local score = oneRecord.scoretab[tostring(uinfo.UserId)]
		if not score then score = 0 end
		if score then
			local lb_score = csbNode:getChildByName("lb_score_" .. i)
			if score >= 0 then
				lb_score:setString("+" .. score)
			else
				lb_score:setString("" .. score)
			end
			lb_score:setVisible(true)
			--判断输赢
			if uinfo.UserId == GlobalUserItem.dwUserID then
				if score > 0 then
					csbNode:getChildByName("lb_ret"):setVisible(true)
					csbNode:getChildByName("lb_ret"):setString("赢")
				elseif score == 0 then
					csbNode:getChildByName("lb_ret"):setVisible(true)
					csbNode:getChildByName("lb_ret"):setString("平")
				else
					csbNode:getChildByName("lb_ret"):setVisible(true)
					csbNode:getChildByName("lb_ret"):setString("输")
				end
			end
		else
			csbNode:getChildByName("lb_ret"):setVisible(false)
		end
	end

	cell:setTag(oneRecord.m_iRecordID)
	return cell
end

function ReplayLayer:tableCellTouched(view, cell)
	cclog("function ReplayLayer:tableCellTouched(view, cell) ==>")
	local recordid = cell:getTag()
	self._scene:showPopWait()
	self._frame:onSendOneRecordDetailRequest(recordid)
end

function ReplayLayer:numberOfCellsInTableView( view )
	if self._manager.mSelectedKindID and self._manager.mTotalRecord[self._manager.mSelectedKindID] then
		return #self._manager.mTotalRecord[self._manager.mSelectedKindID]
	else
		return 0
	end
end

return ReplayLayer
