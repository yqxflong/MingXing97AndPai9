-- Name: CardLayer
-- Func: 牌层
-- Author: Johny

local cmd = appdf.req(appdf.GAME_SRC.."paijiu.src.models.CMD_Game")
local GameLogic = appdf.req(appdf.GAME_SRC.."paijiu.src.models.GameLogic")
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")

local CardLayer = class("CardLayer", cc.Layer)

--各家牌的位置
local POS_NODE_CARD_ARR = {cc.p(695, 620), cc.p(190, 360), cc.p(570,74), cc.p(970, 360)}

--各家组牌完成提示位置
local POS_HINT_COMCARD  = {cc.p(770, 620), cc.p(265, 360), cc.p(750,74), cc.p(1040, 360)}

--拖动牌的层级
local ZORDER_DRAGCARD   = 10

--发牌过程时间
local INTERVAL_SENDCARD = 0.2

function CardLayer:ctor(scene)
	self._scene = scene
	self:setContentSize(cc.size(yl.WIDTH, yl.HEIGHT))

	--注册触摸事件
	ExternalFun.registerTouchEvent(self, true)

	--var
	self.mCardSpriteArr = {}
	for i = 1, cmd.GAME_PLAYER do
		self.mCardSpriteArr[i] = {}
	end

	--自己四张牌的位置
	self.mPosMyCards = {}

	self.mChoosedSpCard = nil
	self.mChoosedSpCard_orPos = nil
	self.mChoosedSpCard_orZOrder = nil

	self._canDragCard = false

	--组牌完成提示数组
	self.mHintFinishComCardArr = {}

end


--发牌显示
function CardLayer:sendCardDisplay(viewId, cardDataArr, finish)
	cclog("CardLayer:sendCardDisplay===>" .. viewId .. "=" .. json.encode(cardDataArr))

	local node_card = POS_NODE_CARD_ARR[viewId]
	if viewId == cmd.MY_VIEWID then--发自己的牌
		self:sendCard_me(viewId, node_card, cardDataArr, finish)
	else--发其他人的牌
		self:sendCard_other(viewId, node_card, cardDataArr, finish)
	end
end


--发自己牌
function CardLayer:sendCard_me(viewId, node_card, cardDataArr, finish)
	cclog("CardLayer:sendCard_me===>" .. viewId)
	local posX = node_card.x
	local posY = node_card.y
	local midSpace = 50
	local cardActArr = {}
	local i = 1
	local function sendOne()
		--记录牌位置
		self.mPosMyCards[i] = cc.p(posX, posY)
		--
		local cardData = cardDataArr[i]
		local cardValue = GameLogic.getCardValue(cardData)
		local cardColor = GameLogic.getCardColor(cardData)
		local spCard = display.newSprite(string.format("game/cards/card_%d%d.png", cardColor, cardValue))
		self.mCardSpriteArr[viewId][i] = spCard
		spCard:move(cc.p(yl.WIDTH*0.5, yl.HEIGHT*0.5))
		spCard:addTo(self)
		spCard:setTag(cardData)
		--action
		if i < #cardDataArr then
			local seq = cc.Sequence:create(cc.MoveTo:create(INTERVAL_SENDCARD, cc.p(posX, posY)), cc.CallFunc:create(sendOne))
			spCard:runAction(seq)
		else--最后一张牌
			local seq = cc.Sequence:create(cc.MoveTo:create(INTERVAL_SENDCARD, cc.p(posX, posY)), cc.CallFunc:create(finish))
			spCard:runAction(seq)
		end
		if i == 2 then
			posX = posX + spCard:getContentSize().width + midSpace
		else
			posX = posX + spCard:getContentSize().width
		end	
		i = i + 1
	end
	sendOne()
end

--发自己牌(无动画)
function CardLayer:sendCard_me_noani(viewId, node_card, cardDataArr)
	cclog("CardLayer:sendCard_me_noani===>" .. viewId)
	local posX = node_card.x
	local posY = node_card.y
	local midSpace = 50
	local cardActArr = {}
	for i = 1, 4 do
		--记录牌位置
		self.mPosMyCards[i] = cc.p(posX, posY)
		--
		local cardData = cardDataArr[i]
		local cardValue = GameLogic.getCardValue(cardData)
		local cardColor = GameLogic.getCardColor(cardData)
		local spCard = display.newSprite(string.format("game/cards/card_%d%d.png", cardColor, cardValue))
		self.mCardSpriteArr[viewId][i] = spCard
		spCard:move(cc.p(posX, posY))
		spCard:addTo(self)
		spCard:setTag(cardData)
		if i == 2 then
			posX = posX + spCard:getContentSize().width + midSpace
		else
			posX = posX + spCard:getContentSize().width
		end	
	end
end

--发其他牌
function CardLayer:sendCard_other(viewId, node_card, cardDataArr, finish)
	cclog("CardLayer:sendCard_other===>" .. viewId)
    --其他玩家是否明牌
	local isOtherMing = false
	for i = 1, #cardDataArr do
		if cardDataArr[i] == 0 then
			self.mCardSpriteArr[viewId][i] = display.newSprite("game/cards/beimian.png")
			self.mCardSpriteArr[viewId][i]:move(cc.p(yl.WIDTH * 0.5, yl.HEIGHT * 0.5))
			self.mCardSpriteArr[viewId][i]:addTo(self)
			self.mCardSpriteArr[viewId][i]:setVisible(false)
		else
			isOtherMing = true
			local cardData = cardDataArr[i]
			local cardValue = GameLogic.getCardValue(cardData)
			local cardColor = GameLogic.getCardColor(cardData)
			local spCard = display.newSprite(string.format("game/cards/card_%d%d.png", cardColor, cardValue))
			self.mCardSpriteArr[viewId][i] = spCard
		end
	end
	--布局牌
	if isOtherMing then--明牌
		local posX = node_card.x
		if viewId == 4 then posX = posX - 180 end--4号位明牌放不下
		local posY = node_card.y
		local midSpace = 50
		for i = 1, #self.mCardSpriteArr[viewId] do
			local spCard = self.mCardSpriteArr[viewId][i]
			spCard:move(cc.p(posX, posY))
			spCard:addTo(self)
			if i == 2 then
				posX = posX + spCard:getContentSize().width + midSpace
			else
				posX = posX + spCard:getContentSize().width
			end
		end
	else--暗牌
		local posX = node_card.x
		local posY = node_card.y
		local i = 1
		local function sendOne()
			local function finishAll()
				--如果此位置没人，则去除牌
				if self._scene.m_tabUserItem[viewId] == nil then
				   for i = 1, #self.mCardSpriteArr[viewId] do
				   	   self.mCardSpriteArr[viewId][i]:removeFromParent()
				   end
				   self.mCardSpriteArr[viewId] = {}
				end
				finish()
			end
			local spCard = self.mCardSpriteArr[viewId][i]
			spCard:setVisible(true)
			if i < #self.mCardSpriteArr[viewId] then
				i = i + 1
				local seq = cc.Sequence:create(cc.MoveTo:create(INTERVAL_SENDCARD, cc.p(posX, posY)), cc.CallFunc:create(sendOne))
				spCard:runAction(seq)
			else
				local seq = cc.Sequence:create(cc.MoveTo:create(INTERVAL_SENDCARD, cc.p(posX, posY)), cc.CallFunc:create(finishAll))
				spCard:runAction(seq)
			end
			posX = posX + spCard:getContentSize().width * 0.5
		end
		sendOne()
	end
end

------------------触摸回调-----------------------
function CardLayer:onTouchBegan(touch, event)
	cclog("CardLayer:onTouchBegan===>")
	if not self._canDragCard then return false end
	local pos = touch:getLocation()
	--遍历我的牌，判断是否点击到我的牌
	for k, spCard in ipairs(self.mCardSpriteArr[cmd.MY_VIEWID]) do
		local cardRect = spCard:getBoundingBox()
		if cc.rectContainsPoint(cardRect, pos) then
		   self.mChoosedSpCard = spCard
		   self.mChoosedSpCard_orPos = cc.p(spCard:getPosition())
		   self.mChoosedSpCard_orZOrder = spCard:getLocalZOrder()
		break end
	end
	if self.mChoosedSpCard then
		self.mChoosedSpCard:setPosition(pos)
		self.mChoosedSpCard:setLocalZOrder(ZORDER_DRAGCARD)
		return true
	end

	return false
end

function CardLayer:onTouchMoved(touch, event)
	cclog("CardLayer:onTouchMoved===>")
	local pos = touch:getLocation()
	if not self.mChoosedSpCard then return end
	self.mChoosedSpCard:setPosition(pos)
end

function CardLayer:onTouchEnded(touch, event)
	cclog("CardLayer:onTouchEnded===>")
	local pos = touch:getLocation()
	if not self.mChoosedSpCard then return end
	--遍历我的牌，判断是否点击到我的牌
	local thespCard = nil
	for k, spCard in ipairs(self.mCardSpriteArr[cmd.MY_VIEWID]) do
		local cardRect = spCard:getBoundingBox()
		if cc.rectContainsPoint(cardRect, pos) and spCard:getTag() ~= self.mChoosedSpCard:getTag() then
		   cclog("CardLayer:onTouchEnded==>touch the Card: " .. spCard:getTag())
		   thespCard = spCard
		break end
	end	
	if thespCard then--找到牌，换位置
		local theCardData = thespCard:getTag()
		local orCardData = self.mChoosedSpCard:getTag()
		cclog("CardLayer:onTouchEnded==>orCardData: " .. orCardData .. "=" .. theCardData)
		--换显示位置
		self.mChoosedSpCard:setPosition(thespCard:getPosition())
		thespCard:setPosition(self.mChoosedSpCard_orPos)
		--换数据位置
		GameLogic.switchDataPos(self._scene._scene.cbCardData[cmd.MY_VIEWID], theCardData, orCardData)
	else--没找到牌回原位
		self.mChoosedSpCard:setPosition(self.mChoosedSpCard_orPos)
	end
	self.mChoosedSpCard:setLocalZOrder(self.mChoosedSpCard_orZOrder)--还原层级
	self.mChoosedSpCard = nil
	self.mChoosedSpCard_orPos = nil
	self.mChoosedSpCard_orZOrder = nil
end

--------------------------命令接收------------------------------
--发牌
--[[
	按照投色顺序发
]]
function CardLayer:onSendCard(chairId, cardArr, finishCallBack)
	cclog("CardLayer:onSendCard===>" .. chairId)
	--
	local function send(viewId, finish)
		self:sendCardDisplay(viewId, cardArr[viewId], finish)
	end
	--发牌固定发4家
	local playercnt = 4
	--一一发牌
	local sendCnt = 0
	local viewId = self._scene._scene:SwitchViewChairID(chairId)
	local function finish()
		sendCnt = sendCnt + 1
		if sendCnt >= playercnt then
		   finishCallBack()
		else
			chairId = GameLogic.mod(chairId + 1, playercnt)
			viewId = self._scene._scene:SwitchViewChairID(chairId)
			send(viewId, finish)
		end
	end
	send(viewId, finish)
end

--进入组牌状态
function CardLayer:onEnterComCard(_can)
	self._canDragCard = _can
end

--组牌完成
function CardLayer:onFinishComCard(viewId)
	if viewId == cmd.MY_VIEWID then
		--隐藏自己的组牌完成按键
		self._scene:onShowFinishComCardBtn(false)
		self._canDragCard = fasle
	end
	--牌前面贴上组牌完成
	self.mHintFinishComCardArr[tostring(viewId)] = display.newSprite("game/hint_finishcomcard.png")
	self.mHintFinishComCardArr[tostring(viewId)]:move(POS_HINT_COMCARD[viewId])
	self.mHintFinishComCardArr[tostring(viewId)]:addTo(self)
end

--显示所有人牌和类型
function CardLayer:onShowAllCardsAndType()
	cclog("CardLayer:onShowAllCardsAndType===>")
	local function showCardType(viewId, cbCardDataArr, isFrist)
		cclog("showCardType===>begin=" .. json.encode(cbCardDataArr))
		local spCard = self.mCardSpriteArr[viewId][1]
		if not isFrist then spCard = self.mCardSpriteArr[viewId][3] end
		local cardSize = spCard:getContentSize()
		local posX = spCard:getPositionX()
		local posY = spCard:getPositionY() + 100
		if viewId == cmd.MY_VIEWID then
			if isFrist then--首道
				posX = self.mPosMyCards[1].x
				posY = self.mPosMyCards[1].y + 100
			else--尾道
				posX = self.mPosMyCards[3].x
				posY = self.mPosMyCards[3].y + 100
			end
		end
		--
		local tp, subtp, pnt = GameLogic.getCardType(cbCardDataArr, 2)
		cclog("showCardType===>22")
		if tp == GameLogic.PJ_PAIRCARD then--对子类型
			local spSub = display.newSprite("game/op/op_" .. subtp .. ".png")
			local spMain = display.newSprite("game/op/op_tp_" .. tp .. ".png")
			spSub:move(cc.p(posX, posY))
			spSub:addTo(self)
			spMain:move(cc.p(posX + spSub:getContentSize().width, posY))
			spMain:addTo(self)
		elseif tp == GameLogic.PJ_POINT then--点类型
			local spSub = display.newSprite("game/op/op_" .. subtp .. ".png")
			local num = cc.LabelAtlas:_create("" .. pnt,"game/op/atlas_num1.png", 52, 71, string.byte("0"))
			num:setAnchorPoint(cc.p(0.5,0.5))
			spSub:move(cc.p(posX, posY))
			spSub:addTo(self)
			num:move(cc.p(posX + spSub:getContentSize().width, posY))
			num:addTo(self)
		else--大类型
			local spMain = display.newSprite("game/op/op_tp_" .. tp .. ".png")
			spMain:move(cc.p(posX + cardSize.width * 0.5, posY))
			spMain:addTo(self)
		end
		cclog("showCardType==>end")
	end
	--所有玩家清理手牌，亮牌
	cclog("self._scene._scene.cbCardData===>" .. json.encode(self._scene._scene.cbCardData))
	for i = 1, cmd.GAME_PLAYER do
		if self._scene.m_tabUserItem[i] then--如果该位置有玩家
			--清除组牌完成提示
			if self.mHintFinishComCardArr[tostring(i)] then
				self.mHintFinishComCardArr[tostring(i)]:removeFromParent()
				self.mHintFinishComCardArr[tostring(i)] = nil
			end

			local theCardArr = self._scene._scene.cbCardData[i]
		    local node_card = POS_NODE_CARD_ARR[i]
			--清除扣牌
			for j = 1, #self.mCardSpriteArr[i] do
			   self.mCardSpriteArr[i][j]:removeFromParent()
			   self.mCardSpriteArr[i][j] = nil
			end
			--展示明牌
			if i ~= cmd.MY_VIEWID then   
			   self:sendCard_other(i, node_card, theCardArr)
			else
			   self:sendCard_me_noani(i, node_card, theCardArr)
			end

			--显示类型
			local fristTwo = {theCardArr[1], theCardArr[2]}
			local lastTwo = {theCardArr[3], theCardArr[4]}
			showCardType(i, fristTwo, true)
			showCardType(i, lastTwo, false)
		end
	end
end

--重置界面
function CardLayer:onResetView()
	cclog("CardLayer:onResetView===>")
	self:removeAllChildren()
end

return CardLayer