-- Name: GameLogic
-- Func: 逻辑封装
-- Author: Johny


local GameLogic = {}


--**************    扑克库    ******************--
GameLogic.CardLib = {
	0x4E, 0x4F, --两王
	0x0D, 0x2D,	--天牌
	0x02, 0x22,	--地牌
	0x08, 0x28,	--人牌
	0x04, 0x24,	--鹅牌
	0x14, 0x34, 0x16, 0x36, 0x1A, 0x3A,--三长
	0x06, 0x26, 0x07, 0x27, 0x0A, 0x2A, 0x1B, 0x3B,--四短
	0x15, 0x35, 0x17, 0x37, 0x18, 0x38, 0x19, 0x39,--五点
}



--**************    大类型    ******************--
GameLogic.PJ_INVALID			 =   0									--无效类型
GameLogic.PJ_POINT				 =   1									--点数类型--还有子类型
GameLogic.PJ_DIGANG				 =   2									--地杠类型
GameLogic.PJ_TIANGANG			 =   3									--天杠类型
GameLogic.PJ_PAIRCARD			 =   4									--对子类型--还有子类型
GameLogic.PJ_WANGYE			     =   5									--王爷类型
GameLogic.PJ_HUANGSHANG		     =   6									--皇上类型

--**************    子类型    ******************--
GameLogic.PJ_SUB_TIAN            =   7 --天
GameLogic.PJ_SUB_DI              =   6 --地
GameLogic.PJ_SUB_REN             =   5 --人
GameLogic.PJ_SUB_E               =   4 --鹅
GameLogic.PJ_SUB_CHANG           =   3 --长
GameLogic.PJ_SUB_DUAN            =   2 --短
GameLogic.PJ_SUB_DIAN            =   1 --点
GameLogic.PJ_SUB_DIANBI    	     =   10--闭10		




--取模
function GameLogic.mod(a,b)
    return a - math.floor(a/b)*b
end
--获得牌的数值（1 -- 13）
function GameLogic.getCardValue(cbCardData)
    return GameLogic.mod(cbCardData, 16)
end

--获得牌的颜色（0 -- 4）
function GameLogic.getCardColor(cbCardData)
    return math.floor(cbCardData/16)
end
--获得牌的逻辑值
function GameLogic.getCardLogicValue(cbCardData)
	local bCardColor = GameLogic.getCardColor(cbCardData)
	local bCardValue = GameLogic.getCardValue(cbCardData)

	if (bCardColor == 0 or bCardColor == 2) and bCardValue == 13 then --天
		return GameLogic.PJ_SUB_TIAN
	elseif (bCardColor == 0 or bCardColor == 2) and bCardValue == 2 then --地
		return GameLogic.PJ_SUB_DI
	elseif (bCardColor == 0 or bCardColor == 2) and bCardValue == 8 then --人
		return GameLogic.PJ_SUB_REN
	elseif (bCardColor == 0 or bCardColor == 2) and bCardValue == 4 then --鹅
		return GameLogic.PJ_SUB_E
	elseif (bCardColor == 1 or bCardColor == 3) and (bCardValue == 4 or bCardValue == 6 or bCardValue == 10) then --三长
		return GameLogic.PJ_SUB_CHANG
	elseif (bCardColor == 0 or bCardColor == 2) and (bCardValue == 6 or bCardValue == 7 or bCardValue == 10) then --四短
		return GameLogic.PJ_SUB_DUAN
	elseif (bCardColor == 1 or bCardColor == 3) and bCardValue == 11 then --四短
		return GameLogic.PJ_SUB_DUAN
	elseif (bCardColor == 1 or bCardColor == 3) and (bCardValue == 5 or bCardValue == 7 or bCardValue == 8 or bCardValue == 9) then --五点
		return GameLogic.PJ_SUB_DIAN
	else
		return 0
	end
end

--获取点数值
function GameLogic.getCardPoint(cbCardData)
	local bCardColor = GameLogic.getCardColor(cbCardData)
	local bCardValue = GameLogic.getCardValue(cbCardData)

	if bCardValue == 15 then 
		return 6 --大王点数
	elseif bCardValue == 14 then 
		return 3 --小王点数
	elseif bCardValue == 13 then 
		return 2 --K点数
	else
		return GameLogic.mod(bCardValue, 10)
	end
end

--获取类型
function GameLogic.getCardType(cbCardData, cbCardCount)
	cclog("GameLogic.getCardType===>begin")
	if cbCardCount ~= 2 then
		return GameLogic.PJ_INVALID
	end

	local cbCardDataSort = {}
	for i =1, #cbCardData do
		table.insert(cbCardDataSort, cbCardData[i])
	end
	GameLogic.sortCardList(cbCardDataSort, cbCardCount)
	cclog("GameLogic.getCardType===>111")
	local specialtype = nil
	if cbCardDataSort[1] == 0x4F and cbCardDataSort[2] == 0x4E then
		return GameLogic.PJ_HUANGSHANG
	elseif GameLogic.getCardValue(cbCardDataSort[1]) == 13 and GameLogic.getCardValue(cbCardDataSort[2]) == 9 then
		return GameLogic.PJ_WANGYE
	elseif GameLogic.getCardLogicValue(cbCardDataSort[1]) == GameLogic.getCardLogicValue(cbCardDataSort[2]) and 
		GameLogic.getCardValue(cbCardDataSort[1]) == GameLogic.getCardValue(cbCardDataSort[2
		])  then
		specialtype = GameLogic.PJ_PAIRCARD
	elseif GameLogic.getCardValue(cbCardDataSort[1]) == 13 and GameLogic.getCardValue(cbCardDataSort[2]) == 8 then
		return GameLogic.PJ_TIANGANG
	elseif GameLogic.getCardValue(cbCardDataSort[1]) == 2 and GameLogic.getCardValue(cbCardDataSort[2]) == 8 then
		return GameLogic.PJ_DIGANG
	else
		specialtype = GameLogic.PJ_POINT
	end
	
	cclog("GameLogic.getCardType===>222")
	--有子类型的
	if specialtype == GameLogic.PJ_PAIRCARD then--对
		local tp = GameLogic.getCardLogicValue(cbCardDataSort[1])
		return specialtype, tp
	elseif specialtype == GameLogic.PJ_POINT then--点
		local tp = GameLogic.getCardLogicValue(cbCardDataSort[1])
		local point = GameLogic.mod(GameLogic.getCardPoint(cbCardDataSort[1]) + GameLogic.getCardPoint(cbCardDataSort[2]), 10)
		if point == 0 then
			return specialtype, GameLogic.PJ_SUB_DIANBI, 10
		else
			return specialtype, tp, point
		end
	end
end

--两个数据换位置
function GameLogic.switchDataPos(cardDataArr, data1, data2)
	for i = 1, #cardDataArr do
		if cardDataArr[i] == data1 then
			cardDataArr[i] = data2
		elseif cardDataArr[i] == data2 then
			cardDataArr[i] = data1
		end
	end
end

--排列扑克
function GameLogic.sortCardList(cbCardData, cbCardCount)
	cclog("GameLogic.sortCardList===>begin: " .. json.encode(cbCardData))
	local cbLogicValue = {}
	for i = 1, cbCardCount do
		cbLogicValue[i] = GameLogic.getCardLogicValue(cbCardData[i])
	end
	cclog("GameLogic.sortCardList===>11: " .. json.encode(cbCardData))
	local bSorted = true
	local cbTempData = nil
	local bLast = cbCardCount - 1
	repeat
	     local bSorted = true
	     for i = 1, bLast do
 			 if (cbLogicValue[i] < cbLogicValue[i + 1]) or ((cbLogicValue[i] == cbLogicValue[i+1]) and (cbCardData[i] < cbCardData[i + 1])) then
 			 	cbTempData = cbCardData[i]
 			 	cbCardData[i] = cbCardData[i + 1]
 			 	cbCardData[i + 1] = cbTempData
 			 	cbTempData = cbLogicValue[i]
 			 	cbLogicValue[i] = cbLogicValue[i+1]
				cbLogicValue[i+1] = cbTempData
				bSorted = false
 			 end
	     end
	     bLast = bLast - 1
	until(bSorted == true)
end


--投色子,返回两个筛子结果
--[[
  庄家投色，点数加和取模从自己开始逆时针，1~playercnt
]]
function GameLogic.throwSice(myChairId, playercnt)
	local sice1 = math.random(6)
	local sice2 = math.random(6)
	return {sice1, sice2}, GameLogic.switchSiceToChairId(myChairId, sice1 + sice2, playercnt)
end

--sicemod转chairid
function GameLogic.switchSiceToChairId(myChairId, sice, playercnt)
	return GameLogic.mod(myChairId + sice - 1, playercnt)
end

--对比扑克
function GameLogic.compareCard(cbFirstData, cbNextData, cbCardCount)
	--获取点数
	local cbNextType = GameLogic.getCardType(cbNextData, cbCardCount)
	local cbFirstType = GameLogic.getCardType(cbFirstData, cbCardCount)

	--点数判断
	if cbFirstType ~= cbNextType then return cbFirstType > cbNextType end

	--排序大小
	local bFirstTemp = {}
	local bNextTemp = {}
	for i =1, #cbFirstData do
		bFirstTemp[i] = cbFirstData[i]
	end
	for i =1, #cbNextData do
		bNextTemp[i] = cbNextData[i]
	end	
	GameLogic.sortCardList(bFirstTemp, cbCardCount)
	GameLogic.sortCardList(bNextTemp, cbCardCount)
	if cbNextType == GameLogic.PJ_PAIRCARD then
		return GameLogic.getCardLogicValue(bFirstTemp[1]) > GameLogic.getCardLogicValue(bNextTemp[2])
	elseif cbNextType == GameLogic.PJ_POINT then
		if  ((GameLogic.getCardPoint(bFirstTemp[1]) + GameLogic.getCardPoint(bFirstTemp[2])) % 10)  ~= ((GameLogic.getCardPoint(bNextTemp[1]) + GameLogic.getCardPoint(bNextTemp[2])) % 10) then
			return ((GameLogic.getCardPoint(bFirstTemp[1]) + GameLogic.getCardPoint(bFirstTemp[2])) % 10) > ((GameLogic.getCardPoint(bNextTemp[1]) + GameLogic.getCardPoint(bNextTemp[2])) % 10)
		else
			return GameLogic.getCardLogicValue(bFirstTemp[1]) > GameLogic.getCardLogicValue(bNextTemp[1])
		end
	end

	return false
end


return GameLogic