-- Name: PageViewIndicator
-- Func: 封装PageView的索引豆
-- Author: Johny

local PageViewIndicator = class("PageViewIndicator", function(file_selected, file_unselected, align)
		local layer =  display.newNode()
    return layer
end)

function PageViewIndicator:ctor(texType, file_selected, file_unselected, align)
	cclog("PageViewIndicator:ctor===>" .. file_selected)
	self._texType = texType
	self._filePath_Selected = file_selected
	self._filePath_UnSelected = file_unselected
	self._indicatorList = {}
	self._totalWidth = 0
	self._align = align
	self._curIdx = 1
end

function PageViewIndicator:addOne()
	local sp = ccui.ImageView:create(self._filePath_UnSelected, self._texType)
	:setContentSize(cc.size(30,30))
	:setAnchorPoint(cc.p(0, 0.5))
	:move(cc.p(self._totalWidth + self._align, 0.0))
	:addTo(self)
	table.insert(self._indicatorList, sp)
	self._totalWidth = self._totalWidth + self._align + 30
end

function PageViewIndicator:turnTo(idx)
	cclog("PageViewIndicator:turnTo===idx: " .. idx)
	if idx == 0 then idx = 1 end
	self._curIdx = idx
	for i = 1, #self._indicatorList do
		local sp = self._indicatorList[i]
		if i == idx then
			sp:loadTexture(self._filePath_Selected, self._texType)
		else
			sp:loadTexture(self._filePath_UnSelected, self._texType)
		end
	end
end

--重新调整位置
function PageViewIndicator:rePosToCenter(pageWidth)
	local posX = pageWidth * 0.5
	posX = posX - self._totalWidth * 0.5
	self:setPositionX(posX)
end

return PageViewIndicator