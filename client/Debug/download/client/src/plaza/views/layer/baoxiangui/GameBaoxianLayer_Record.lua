-- Name: GameBaoxianLayer_Record
-- Func: 保险柜-记录
-- Author: Johny

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local BankFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.BankFrame")

local GameBaoxianLayer_Record = class("GameBaoxianLayer_Record", cc.Layer)

local RECORD_LIST = {}

function GameBaoxianLayer_Record:ctor(scene)
	self._scene = scene
	--
	RECORD_LIST = {}
	--
	self:layoutUI()
    --网络回调
    local  bankCallBack = function(result,message)
    	if self.onBankCallBack then
			self:onBankCallBack(result,message)
		end
	end

	--网络处理
	self._bankFrame = BankFrame:create(self, bankCallBack)
	--请求交易记录
	self._bankFrame:onGetTransferRecord(0, 15)
	self._scene:showPopWait()
end

function GameBaoxianLayer_Record:layoutUI()
	local csbNode = ExternalFun.loadCSB("baoxian/layer_record.csb", self)

	--tableview
	local content = appdf.getNodeByName(self, "content")
	local size = content:getContentSize()
	self._listView = cc.TableView:create(size)
	self._listView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)    
	self._listView:setPosition(cc.p(0,0))
	self._listView:setDelegate()
	self._listView:addTo(content)
	self._listView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
	self._listView:registerScriptHandler(self.cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)
	self._listView:registerScriptHandler(self.tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)
	self._listView:registerScriptHandler(self.numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
end

-------------------------------Tableview Delegate---------------------------------
--子视图大小
function GameBaoxianLayer_Record.cellSizeForTable(view, idx)
	cclog("GameBaoxianLayer_Record.cellSizeForTable(view, idx) ==> ")
  	return 677 , 35
end

--子视图数目
function GameBaoxianLayer_Record.numberOfCellsInTableView(view)
	cclog("function GameBaoxianLayer_Record.numberOfCellsInTableView(view) ==> ")
	return #RECORD_LIST
end
	
--获取子视图
function GameBaoxianLayer_Record.tableCellAtIndex(view, idx)
	cclog("function GameBaoxianLayer_Record.tableCellAtIndex(view, idx) ==> ")
	local cell = view:dequeueCell()
	local item = RECORD_LIST[idx+1]
	local width = 677
	local height= 35

	if not cell then
		cell = cc.TableViewCell:new()
	else
		cell:removeAllChildren()
	end

	--layout
	local csbNode = ExternalFun.loadCSB("baoxian/cell_record.csb")
	cell:addChild(csbNode)

	appdf.getNodeByName(csbNode, "lb_time"):setString(item.szDateTime)
	appdf.getNodeByName(csbNode, "lb_senderid"):setString(item.dwSourceGameID)
	appdf.getNodeByName(csbNode, "lb_reid"):setString(item.dwTargetGameID)
	if item.bType == 0 then
		appdf.getNodeByName(csbNode, "lb_type"):setString("转出")
		appdf.getNodeByName(csbNode, "lb_count"):setString("-" .. item.lSwapScore)
	else
		appdf.getNodeByName(csbNode, "lb_type"):setString("转进")
		appdf.getNodeByName(csbNode, "lb_count"):setString("+" .. item.lSwapScore)
	end
	

	return cell
end
---------------------------------------------------------------------

--操作结果
function GameBaoxianLayer_Record:onBankCallBack(result, list)
	cclog("function GameBaoxianLayer_Record:onBankCallBack(result,message) ==> ")
	self._scene:dismissPopWait()
	if  message ~= nil and message ~= "" then
		showToast(self._scene,message,2)
	end
    --返回记录
	if result == BankFrame.OP_GET_TRANSFERRECORD then
	   RECORD_LIST = list
	   self._listView:reloadData()
	end
end

return GameBaoxianLayer_Record
