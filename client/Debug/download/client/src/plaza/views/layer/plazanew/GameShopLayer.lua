-- Name: GameShopLayer
-- Func: 商店
-- Author: Johny

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")

local GameShopLayer = class("GameShopLayer", cc.Layer)
--------------------------------------------------------
--@商品url
local URL_GOODS = yl.HTTP_URL .. "/WS/MobileInterface.ashx"
--@订单
local URL_ORDER = yl.HTTP_URL .. "/WS/MobileInterface.ashx"

--支付方式
local CBT_WECHAT = 1
local CBT_ALIPAY = 2
local CBT_JFT    = 3

local PAYTYPE = {}
PAYTYPE[CBT_WECHAT] =
{
    str = "wx",
    plat = yl.ThirdParty.WECHAT
}
PAYTYPE[CBT_ALIPAY] =
{
    str = "zfb",
    plat = yl.ThirdParty.ALIPAY
}
PAYTYPE[CBT_JFT] =
{
    str = "jft",
    plat = yl.ThirdParty.JFT
}

--------------------------------------------------------
local BTN_CLOSE     = 1
local BTN_BUY       = 2

local BTN_GOOD_BASE =10
local BTN_GOOD_1    =11
local BTN_GOOD_2    =12
local BTN_GOOD_3    =13

function GameShopLayer:onEnterTransitionFinish()
    cclog("function GameShopLayer:onEnterTransitionFinish() ==>")
    self:onRequestGoodsList()
end

function GameShopLayer:onExit()
    cclog("function GameShopLayer:onExit() ==>")

end


function GameShopLayer:ctor(scene)
	ExternalFun.registerNodeEvent(self)
	self._scene = scene

    --var
    self._goodList = {}
    self._choosedId = -1



	local btcallback = function(ref, type)
		if type == ccui.TouchEventType.ended then
			self:OnButtonClickedEvent(ref:getTag(),ref)
        end
	end

	--layout
	local csbNode = ExternalFun.loadCSB("shop/ShopLayer.csb", self)
    self.mCsbNode = csbNode

	--close
	local btn_close = appdf.getNodeByName(csbNode, "btn_close")
	btn_close:setTag(BTN_CLOSE)
	btn_close:addTouchEventListener(btcallback)

    --buy
    local btn_buy = appdf.getNodeByName(csbNode, "btn_buy")
    btn_buy:setTag(BTN_BUY)
    btn_buy:addTouchEventListener(btcallback)

    --good btn
    local btn_good_1 = appdf.getNodeByName(csbNode, "btn_good_1")
    btn_good_1:setTag(BTN_GOOD_1)
    btn_good_1:addTouchEventListener(btcallback)
    btn_good_1:setVisible(false)

    local btn_good_2 = appdf.getNodeByName(csbNode, "btn_good_2")
    btn_good_2:setTag(BTN_GOOD_2)
    btn_good_2:addTouchEventListener(btcallback)
    btn_good_2:setVisible(false)

    local btn_good_3 = appdf.getNodeByName(csbNode, "btn_good_3")
    btn_good_3:setTag(BTN_GOOD_3)
    btn_good_3:addTouchEventListener(btcallback)
    btn_good_3:setVisible(false)

    --当前房卡
    self.mLbCurFangka = appdf.getNodeByName(csbNode, "lb_leftfangka")
    local str = string.formatNumberThousands(GlobalUserItem.lRoomCard, true, ",")
    self.mLbCurFangka:setString(str)

    --当前选中物品获得房卡数
    self.mLbGetFangkaCnt = appdf.getNodeByName(csbNode, "lb_buycnt")
    self.mLbGetFangkaCnt:setVisible(false)

    --当前选中物品价格
    self.mLbPayPrice = appdf.getNodeByName(csbNode, "lb_buypricecnt")
    self.mLbPayPrice:setVisible(false)
end

--按键响应
function GameShopLayer:OnButtonClickedEvent(tag,ref)
	if tag == BTN_CLOSE then
		self:removeFromParent()
    elseif tag == BTN_BUY then
        self:onBuyGood()
    elseif tag >= BTN_GOOD_1 and tag <= BTN_GOOD_3 then
        self:onChosenOneGood(tag - BTN_GOOD_BASE)
	end
end

--刷洗商品列表
function GameShopLayer:onRequestGoodsList(isIap)
	cclog("GameShopLayer:onRequestGoodsList===>")
	isIap = isIap or 0
 	local ostime = os.time()
    self._scene:showPopWait()
    appdf.onHttpJsionTable(URL_GOODS ,"GET", "action=GetPayProduct&userid=" .. GlobalUserItem.dwUserID .. "&time=".. ostime .. "&signature=".. GlobalUserItem:getSignature(ostime) .. "&typeID=" .. isIap, function(sjstable,sjsdata)
        dump(sjstable, "商品列表", 6)
        local errmsg = "获取支付列表异常!"
        self._scene:dismissPopWait()
        if type(sjstable) == "table" then
            local sjdata = sjstable["data"]
            local msg = sjstable["msg"]
            errmsg = nil
            if type(msg) == "string" then
                errmsg = msg
            end
            
            if type(sjdata) == "table" then
                local isFirstPay = sjdata["IsPay"] or "0"
                isFirstPay = tonumber(isFirstPay)
                local sjlist = sjdata["list"]
                if type(sjlist) == "table" then
                    for i = 1, #sjlist do
                        local sitem = sjlist[i]
                        local item = {}
                        item.isfirstpay = isFirstPay
                        item.appid = tonumber(sitem["AppID"])
                        item.nProductID = sitem["ProductID"] or ""
                        item.name = sitem["ProductName"]
                        item.description  = sitem["Description"] 
                        item.price = sitem["Price"]
                        item.price = tonumber(item.price)
                        item.currency  = sitem["Currency"]             --购买数量
                        item.paysend = sitem["AttachCurrency"] or "0"  --首充赠送
                        item.paysend = tonumber(item.paysend)
                        item.paycount = sitem["PresentCurrency"] or "0"--赠送数量
                        item.paycount = tonumber(item.paycount)
                        item.count = item.paysend + item.paycount + item.currency      --总数
                        item.sortid = tonumber(sitem["SortID"]) or 0
                        item.nOrder = 0
                        
                        

                        --首充赠送
                        if 0 ~= item.paysend then
                            --当日未首充
                            if 0 == isFirstPay then
                                item.nOrder = 1
                                table.insert(self._goodList, item)
                            end
                        else
                            table.insert(self._goodList, item)
                        end                                             
                    end
                    table.sort(self._goodList, function(a,b)
                            if a.nOrder ~= b.nOrder then
                                return a.nOrder > b.nOrder
                            else
                                return a.sortid < b.sortid
                            end
                        end)
                    GlobalUserItem.tabShopCache["ShopGoodList"] = self._goodList
                    self:onUpdateGoodList()
                end
            end
        end

        if type(errmsg) == "string" and "" ~= errmsg then
            showToast(self,errmsg,2,cc.c3b(250,0,0))
        end 
    end)	
end

--刷新商品信息显示
function GameShopLayer:onUpdateGoodList()
	cclog("GameShopLayer:onUpdateGoodList===>")
    if #self._goodList <= 0 then return end
    --刷新商品数据
    for i = 1,3 do
        local item = self._goodList[i]
        local btnGood = appdf.getNodeByName(self.mCsbNode, "btn_good_" .. i)
        btnGood:setVisible(true)
        btnGood:getChildByName("lb_title"):setString(item.name)
        btnGood:getChildByName("lb_give"):setString(string.format("赠送：%d 张",item.paycount))
        btnGood:getChildByName("lb_price"):setString(string.format("%d元",item.price))
    end

    --默认选中第一个
    self._choosedId = 1
    self.mLbGetFangkaCnt:setString(self._goodList[self._choosedId].count)
    self.mLbGetFangkaCnt:setVisible(true)
    self.mLbPayPrice:setString(self._goodList[self._choosedId].price .. "元")
    self.mLbPayPrice:setVisible(true)
end

--选中当前商品
function GameShopLayer:onChosenOneGood(idx)
    if self._choosedId == idx then return end
    local item = self._goodList[idx]
    self._choosedId = idx
    self.mLbGetFangkaCnt:setString(item.count)
    self.mLbPayPrice:setString(item.price .. "元") 
end

--购买商品
function GameShopLayer:onBuyGood()
        if self._choosedId <= 0 then
            return
        end
        --选中的商品
        local item = self._goodList[self._choosedId]
        --微信参数
        local plat = yl.ThirdParty.WECHAT
        local str = "微信未安装,无法进行微信支付"
        --判断应用是否安装
        if false == MultiPlatform:getInstance():isPlatformInstalled(plat) then
            showToast(self, str, 2, cc.c4b(250,0,0,255))
            return
        end
        
        self._scene:showPopWait()
        self:runAction(cc.Sequence:create(cc.DelayTime:create(5), cc.CallFunc:create(function()
            self._scene:dismissPopWait()
            end)))
        --生成订单
        local account = GlobalUserItem.dwGameID
        local action = "action=CreatPayOrderID&gameid=" .. account .. "&amount=" .. item.price .. "&paytype=" .. PAYTYPE[CBT_WECHAT].str .. "&appid=" .. item.appid
        --cclog(action)
        appdf.onHttpJsionTable(URL_ORDER, "GET", action, function(jstable,jsdata)
            dump(jstable, "jstable", 6)
            if type(jstable) == "table" then
                local data = jstable["data"]
                if type(data) == "table" then
                    if nil ~= data["valid"] and true == data["valid"] then
                        local payparam = {}
                        --获取微信支付订单id
                        local paypackage = data["PayPackage"]
                        if type(paypackage) == "string" then
                            local ok, paypackagetable = pcall(function()
                                return cjson.decode(paypackage)
                            end)
                            if ok then
                                local payid = paypackagetable["prepayid"]
                                if nil == payid then
                                    showToast(self, "微信支付订单获取异常", 2)
                                    return 
                                end
                                payparam["info"] = paypackagetable
                            else
                                showToast(self, "微信支付订单获取异常", 2)
                                return
                            end
                        end
                        --订单id
                        payparam["orderid"] = data["OrderID"]                       
                        --价格
                        payparam["price"] = item.price
                        --商品名
                        payparam["name"] = item.name

                        local function payCallBack(param)
                            self._scene:dismissPopWait()
                            if type(param) == "string" and "true" == param then
                                GlobalUserItem.setTodayPay()
                                showToast(self, "支付成功", 2)
                                --更新房卡数量
                                GlobalUserItem.lRoomCard = GlobalUserItem.lRoomCard + item.count
                                --通知更新        
                                local eventListener = cc.EventCustom:new(yl.RY_USERINFO_NOTIFY)
                                eventListener.obj = yl.RY_MSG_USERWEALTH
                                cc.Director:getInstance():getEventDispatcher():dispatchEvent(eventListener)
                                --更新当前界面房卡数
                                local str = string.formatNumberThousands(GlobalUserItem.lRoomCard, true, ",")
                                self.mLbCurFangka:setString(str)
                            else
                                showToast(self, "支付异常", 2)
                            end
                        end
                        MultiPlatform:getInstance():thirdPartyPay(PAYTYPE[CBT_WECHAT].plat, payparam, payCallBack)
                    else
                        if type(jstable["msg"]) == "string" and jstable["msg"] ~= "" then
                            showToast(self, jstable["msg"], 2)
                        end
                    end
                end
            end
        end)   
end

return GameShopLayer
