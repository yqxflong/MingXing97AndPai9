--@NEW
-- Name: UserInfoLayer
-- Func: 用户信息界面
-- Author: Johny



local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")
local loginCMD = appdf.req(appdf.HEADER_SRC .. "CMD_LogonServer")
local HeadSprite = appdf.req(appdf.EXTERNAL_SRC .. "HeadSprite")

--[[
	包含   SelectHeadLayer UserInfoLayer 
]]


-------------------------------------------头像选择界面-----------------------------------
local SelectHeadLayer = class("SelectHeadLayer", cc.Layer)

SelectHeadLayer.BTN_LOCAL = 101
SelectHeadLayer.BTN_SYS = 102
function SelectHeadLayer:ctor( viewparent )

	cclog("function SelectHeadLayer:ctor( viewparent ) ==>")

	self.m_parent = viewparent
	--注册触摸事件
	ExternalFun.registerTouchEvent(self, true)

	--加载csb资源
	local rootLayer, csbNode = ExternalFun.loadRootCSB("plazanew/SelectHeadLayer.csb", self)

	local function btnEvent( sender, eventType )
		if eventType == ccui.TouchEventType.ended then
			self:onButtonClickedEvent(sender:getTag(), sender)
		end
	end
	------
	--选择方式
	self.m_spSelectType = csbNode:getChildByName("img_bg")
	local img_bg2 = self.m_spSelectType:getChildByName("img_bg2")
	--本地图片
	local btn = img_bg2:getChildByName("btn_camera")
	btn:setTag(SelectHeadLayer.BTN_LOCAL)
	btn:addTouchEventListener(btnEvent)
	--系统头像
	btn = img_bg2:getChildByName("btn_photo")
	btn:setTag(SelectHeadLayer.BTN_SYS)
	btn:addTouchEventListener(btnEvent)
	------

	------
	--系统头像列表
	self.m_spSysSelect = csbNode:getChildByName("headlist")
	self.m_spSysSelect:setVisible(false)
	self.m_tableView = nil
	self.m_tabSystemHead = {}
	self.m_vecTouchBegin = {x = 0, y = 0}
	--------------------------------
end

function SelectHeadLayer:refreshSystemHeadList(  )

	cclog("function SelectHeadLayer:refreshSystemHeadList(  ) ==>")

	if nil == self.m_tableView then
		local content = self.m_spSysSelect:getChildByName("content")
		local m_tableView = cc.TableView:create(content:getContentSize())
		m_tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
		m_tableView:setPosition(content:getPosition())
		m_tableView:setDelegate()
		m_tableView:registerScriptHandler(self.cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)
		m_tableView:registerScriptHandler(handler(self, self.tableCellAtIndex), cc.TABLECELL_SIZE_AT_INDEX)
		m_tableView:registerScriptHandler(self.numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
		self.m_spSysSelect:addChild(m_tableView)
		self.m_tableView = m_tableView
		content:removeFromParent()
		self.m_tableView:reloadData()
	end
end

function SelectHeadLayer:onButtonClickedEvent( tag, sender )

	cclog("function SelectHeadLayer:onButtonClickedEvent( tag, sender ) ==>")

	self.m_spSelectType:setVisible(false)
	if SelectHeadLayer.BTN_LOCAL == tag then		
		local function callback( param )
			if type(param) == "string" then
				cclog("lua call back " .. param)
				if cc.FileUtils:getInstance():isFileExist(param) then
					--发送上传头像
					local url = yl.HTTP_URL .. "/WS/Account.ashx?action=uploadface"
					local uploader = CurlAsset:createUploader(url,param)
					if nil == uploader then
						showToast(self, "自定义头像上传异常", 2)
						return
					end
					local nres = uploader:addToFileForm("file", param, "image/png")
					--用户标示
					nres = uploader:addToForm("userID", GlobalUserItem.dwUserID)
					--登陆时间差
					local delta = tonumber(currentTime()) - tonumber(GlobalUserItem.LogonTime)
					cclog("time delta " .. delta)
					nres = uploader:addToForm("time", delta .. "")
					--客户端ip
					local ip = MultiPlatform:getInstance():getClientIpAdress() or "192.168.1.1"
					nres = uploader:addToForm("clientIP", ip)
					--机器码
					local machine = GlobalUserItem.szMachine or "A501164B366ECFC9E249163873094D50"
					nres = uploader:addToForm("machineID", machine)
					--会话签名
					nres = uploader:addToForm("signature", GlobalUserItem:getSignature(delta))
					if 0 ~= nres then
						showToast(self, "上传表单提交异常,error code ==> " .. nres, 2)
						return
					end
					self.m_parent:showPopWait()
					uploader:uploadFile(function(sender, ncode, msg)
						self:onUploadFaceResult(sender, ncode, msg, param)
					end)
				end
			end
		end
		MultiPlatform:getInstance():triggerPickImg(callback, true)
	elseif SelectHeadLayer.BTN_SYS == tag then
		self.m_spSysSelect:setVisible(true)
		self:refreshSystemHeadList()
	end
end

function SelectHeadLayer:onUploadFaceResult(sender, ncode, msg, param)

	cclog("function SelectHeadLayer:onUploadFaceResult(sender, ncode, msg, param) ==>")

	self.m_parent:dismissPopWait()
	if 0 == ncode then
		if type(msg) == "string" then
			cclog("msg ==> " .. msg)
		end
		local ok, datatable = pcall(function()
				return cjson.decode(msg)
		end)
		if ok then
			dump(datatable, "datatable")
			if nil ~= datatable.code and 0 == datatable.code then
				local msgdata = datatable.data
				dump(msgdata, "msgdata")
				if nil ~= msgdata and type(msgdata) == "table" then			
					local valid = msgdata.valid
					if valid then
						cc.Director:getInstance():getTextureCache():removeTextureForKey(param)	    									
						local sp = cc.Sprite:create(param)
						if nil ~= sp then
							GlobalUserItem.dwCustomID = tonumber(msgdata.CustomID)
							local frame = sp:getSpriteFrame()
							local framename = GlobalUserItem.dwUserID .. "_custom_" .. GlobalUserItem.dwCustomID .. ".ry"
							local oldframe = cc.SpriteFrameCache:getInstance():getSpriteFrame(framename)
							if nil ~= oldframe then
								oldframe:release()
							end	
							cc.SpriteFrameCache:getInstance():removeSpriteFrameByName(framename)

							cc.SpriteFrameCache:getInstance():addSpriteFrame(frame, framename)
							frame:retain()
							
							if nil ~= self.m_parent and nil ~= self.m_parent.onFaceResultSuccess then
								self.m_parent:onFaceResultSuccess()
							end
							showToast(self, "自定义头像上传成功", 2)
						end		    				
					else
						if type(msg.msg) == "string" then
							showToast(self, msg.msg, 2)
						end			    							
					end
				end
			end
		else
			showToast(self, "自定义头像上传异常", 2)
		end
		return					
	end
	showToast(self, "自定义头像上传异常, error code ==> " .. ncode, 2)
end

function SelectHeadLayer:onTouchBegan(touch, event)

	cclog("function SelectHeadLayer:onTouchBegan(touch, event) ==>")

	self.m_vecTouchBegin = {x = touch:getLocation().x, y = touch:getLocation().y}
	return self:isVisible()
end

function SelectHeadLayer:onTouchEnded( touch, event )
	cclog("function SelectHeadLayer:onTouchEnded( touch, event ) ==>")

	local pos = touch:getLocation()
	if math.abs(pos.x - self.m_vecTouchBegin.x) > 30 
		or math.abs(pos.y - self.m_vecTouchBegin.y) > 30 then
		self.m_vecTouchBegin = {x = 0, y = 0}

		return
	end
	
	local m_spBg = nil
	if self.m_spSelectType:isVisible() then
		m_spBg = self.m_spSelectType
	elseif self.m_spSysSelect:isVisible() then
		m_spBg = self.m_spSysSelect

		local touchHead = false
		local touchSp = nil
		for i,v in pairs(self.m_tabSystemHead) do
			local tmppos = v:convertToNodeSpace(pos)
			local headRect = cc.rect(0, 0, v:getContentSize().width, v:getContentSize().height)
			if true == cc.rectContainsPoint(headRect, tmppos) then
		        touchHead = true
		        touchSp = v
		        break
		    end
		end

		if true == touchHead and nil ~= touchSp then
			local tag = touchSp:getTag()
			cclog("touch head " .. tag)
			if nil ~= self.m_parent and nil ~= self.m_parent.sendModifySystemFace then
				self.m_parent:sendModifySystemFace(tag)
			end
			return
		end
	end
	if nil == m_spBg then
		self:removeFromParent()
		return
	end

    pos = m_spBg:convertToNodeSpace(pos)
    local rec = cc.rect(0, 0, m_spBg:getContentSize().width, m_spBg:getContentSize().height)
    if false == cc.rectContainsPoint(rec, pos) then
        self:removeFromParent()
    end
end

--tableview
function SelectHeadLayer.cellSizeForTable( view, idx )

	cclog("function SelectHeadLayer.cellSizeForTable( view, idx ) ==>")

	return 940,95
end

function SelectHeadLayer.numberOfCellsInTableView( view )

	cclog("function SelectHeadLayer.numberOfCellsInTableView( view ) ==>")

	--一行10个，200个
	return 20
end

function SelectHeadLayer:tableCellAtIndex( view, idx )

	cclog("function SelectHeadLayer:tableCellAtIndex( view, idx ) ==>")

	local cell = view:dequeueCell()
	idx = 19 - idx
	--[[if nil ~= cell and nil ~= cell:getChildByName("head_item_view") then
		cell:removeChildByName("head_item_view", true)	
	end]]
	
	if nil == cell then
		cell = cc.TableViewCell:new()
		local item = self:groupSysHead(idx, view)
		item:setPosition(view:getViewSize().width * 0.5, 0)
		item:setName("head_item_view")
		item:setTag(idx)
		cell:addChild(item)
	else
		local item = cell:getChildByName("head_item_view")
		item:setTag(idx)
		self:updateCellItem(item, idx, view)
	end	

	return cell
end

local xTable = {-450}
function SelectHeadLayer:groupSysHead( idx, view )

	cclog("function SelectHeadLayer:groupSysHead( idx, view ) ==>")

	local item = cc.Node:create()
	local xStart = -450
	local str = ""
	local head = nil
	local frame = nil
	local tag = 0
	for i = 0, 9 do
		head = nil
		tag = idx * 10 + i
		str = string.format("Avatar%d.png", tag)
		frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(str)
		if nil ~= frame then
			head = cc.Sprite:createWithSpriteFrame(frame)
		end

		if nil ~= head then
			item:addChild(head)
			head:setTag(tag)
			local xPos = xStart + i * 100
			head:setPosition(xPos, 45)
			head:setScale(80 / 96)
			head:setName("head_" .. i)

			self.m_tabSystemHead[tag] = head

			local frame = nil
			if tag == GlobalUserItem.wFaceID then
				frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("sp_select_bg.png")
			else
				frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("sp_normal_frame.png")
			end
			if nil ~= frame then
				local spFrame = cc.Sprite:createWithSpriteFrame(frame)
				spFrame:setPosition(xPos, 45)
				item:addChild(spFrame, -1)
				spFrame:setName("frame_" .. i)
			end
		end
	end
	return item
end

function SelectHeadLayer:updateCellItem( item, idx, view )

	cclog("function SelectHeadLayer:updateCellItem( item, idx, view ) ==>")

	local tag = 0
	local frame = nil
	local str = ""
	for i = 0, 9 do
		head = nil
		tag = idx * 10 + i
		frame = nil
		str = ""

		local head = item:getChildByName("head_" .. i)
		if nil ~= head then
			str = string.format("Avatar%d.png", tag)
			frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(str)
			if nil ~= frame then
				head:setSpriteFrame(frame)
				head:setTag(tag)

				self.m_tabSystemHead[tag] = head
			end
		end
		
		local spFrame = item:getChildByName("frame_" .. i)
		if nil ~= spFrame then
			frame = nil
			if tag == GlobalUserItem.wFaceID then
				frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("sp_select_bg.png")
			else
				frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("sp_normal_frame.png")
			end

			if nil ~= frame then
				spFrame:setSpriteFrame(frame)
			end
		end
	end
end

----------------------------------------个人信息界面-------------------------------------------
local UserInfoLayer = class("UserInfoLayer", cc.Layer)

-- local PromoterInputLayer = appdf.req(appdf.CLIENT_SRC .. "plaza.views.layer.plazanew.PromoterInputLayer")

local Bank = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.plaza.BankLayer")
local ModifyFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.ModifyFrame")
local bGender = false
local Shop = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.plaza.ShopLayer")


UserInfoLayer.BT_MODIFY_INFO 	= 1
UserInfoLayer.BT_BANK			= 2
UserInfoLayer.BT_MODIFY_PASS	= 3
UserInfoLayer.BT_ADD			= 4
UserInfoLayer.BT_EXIT			= 5

UserInfoLayer.BT_BINDING 		= 6
UserInfoLayer.BT_VIP 			= 7
UserInfoLayer.BT_NICKEDIT 		= 8
UserInfoLayer.BT_SIGNEDIT 		= 9
UserInfoLayer.BT_TAKE 			= 10
UserInfoLayer.BT_RECHARGE 		= 11
UserInfoLayer.BT_EXCHANGE 		= 12
UserInfoLayer.BT_CONFIRM		= 15

UserInfoLayer.CBT_MAN			= 13
UserInfoLayer.CBT_WOMAN			= 14
UserInfoLayer.LAY_SELHEAD		= 17

UserInfoLayer.BT_QRCODE 		= 19
UserInfoLayer.BT_PROMOTER 		= 20


function UserInfoLayer:layoutUI()
	local  btcallback = function(ref, type)
    if type == ccui.TouchEventType.ended then
         	self:onButtonClickedEvent(ref:getTag(),ref)
        end
    end

    local editHanlder = function(event,editbox)
        self:onEditEvent(event,editbox)
    end

    local cbtlistener = function (sender,eventType)
    	self:onSelectedEvent(sender:getTag(),sender,eventType)
    end

    self._bankNotify = function ()
    	self._txtScore:setString(string.formatNumberThousands(GlobalUserItem.lUserScore))
    end


    local rootLayer, csbNode = ExternalFun.loadRootCSB("plazanew/UserInfoLayer.csb", self)
    local img_bg = csbNode:getChildByName("img_bg")
    local img_bg2 = img_bg:getChildByName("img_bg_2")
    local img_bg3 = img_bg2:getChildByName("img_bg_3")

    --返回
    local btn_return = img_bg:getChildByName("btn_return")
    btn_return:setTag(UserInfoLayer.BT_EXIT)
    btn_return:addTouchEventListener(btcallback)

    --头像
    local headFrame = img_bg2:getChildByName("img_avatar_frame")
	local head = HeadSprite:createClipHead(GlobalUserItem, 90)
	:setPosition(headFrame:getPosition())
	:addTo(img_bg2)
	head:registerInfoPop(true, function( )
		self:onClickUserHead()		
	end)
	self._head = head

	--vip
	local lb_vip = img_bg2:getChildByName("lb_vip")
	lb_vip:setString("VIP: " .. GlobalUserItem.cbMemberOrder)
	self._txtVip = lb_vip


	--ID
	local id = img_bg2:getChildByName("lb_id")
	id:setString("ID: " .. GlobalUserItem.dwGameID)
	self._txtID = id

	--LV
	local lv = img_bg2:getChildByName("lb_level")
	lv:setString("LV: " .. GlobalUserItem.wCurrLevelID)
	self._level = lv

	--exp bar
	local scalex = GlobalUserItem.dwExperience/GlobalUserItem.dwUpgradeExperience
	if scalex > 1 then
		scalex = 1
	end
	local exp = img_bg2:getChildByName("img_barexp2"):getChildByName("bar_exp")
	exp:setPercent(scalex * 100)
	self._levelpro = exp

	-------------hint------------
	local img_hintframe = img_bg2:getChildByName("img_hintframe")
	--hint_exp
	local nextexp = GlobalUserItem.dwUpgradeExperience - GlobalUserItem.dwExperience
	nextexp = (nextexp < 0) and 0 or nextexp
	local lb_lv_hint = img_hintframe:getChildByName("lb_level_hint")
	:setString("下次升级还需要"..(nextexp).."经验")

	--hint coin
	local gold = GlobalUserItem.lUpgradeRewardGold 
	local szgold
	if gold > 9999 then
		szgold = string.format("%0.2f万",gold/10000) 
	else
		szgold = gold..""
	end
	local lb_coin_hint = img_hintframe:getChildByName("lb_coin_hint")
	lb_coin_hint:setString("奖励" .. "+"..szgold.."游戏币")

	--hint yuanbao
	local lb_yuanbao_hint = img_hintframe:getChildByName("lb_yuanbao_hint")
	lb_yuanbao_hint:setString("+ "..GlobalUserItem.lUpgradeRewardIngot.." 元宝")

	--推广码
	local btn_propt = img_bg2:getChildByName("btn_propt")
	btn_propt:setTag(UserInfoLayer.BT_QRCODE)
	btn_propt:addTouchEventListener(btcallback)
	
 	--account
 	local account = GlobalUserItem.szAccount
	--微信登陆显示昵称
	if GlobalUserItem.bWeChat then
	 	account = GlobalUserItem.szNickName
	end
	local lb_account = img_bg3:getChildByName("lb_account")
	lb_account:setString(account)

	--name
	local img_input_name = img_bg3:getChildByName("img_input_name")
	local posX,posY = img_input_name:getPosition()
	self.edit_Nickname = ccui.EditBox:create(cc.size(290,58), "blank.png")
		:move(posX + 10, posY)
		:setAnchorPoint(cc.p(0.5,0.5))
		:setFontName("fonts/yuanti_sc_light.ttf")
		:setPlaceholderFontName("yuanti_sc_light.ttf")
		:setFontSize(30)
		:setPlaceholderFontSize(30)
		:setMaxLength(32)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:setPlaceHolder("请输入您的游戏昵称")
		:setFontColor(cc.c4b(254,164,107,255))
		:setText(GlobalUserItem.szNickName)		
		:addTo(img_bg3)
	self.edit_Nickname:registerScriptEditBoxHandler(editHanlder)
	self.edit_Nickname:setName("edit_nickname")
	self.m_szNick = GlobalUserItem.szNickName

	--sign
	local img_input_sign = img_bg3:getChildByName("img_input_sign")
	local posX,posY = img_input_sign:getPosition()
    self.edit_Sign = ccui.EditBox:create(cc.size(570,40), "blank.png")
		:move(posX + 20, posY)
		:setAnchorPoint(cc.p(0.5,0.5))
		:setFontName("fonts/yuanti_sc_light.ttf")
		:setPlaceholderFontName("fonts/yuanti_sc_light.ttf")
		:setFontSize(24)
		:setPlaceholderFontSize(24)
		:setMaxLength(32)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:setPlaceHolder("请输入您的个人签名")
		:setFontColor(cc.c4b(254,164,107,255))
		:setText(GlobalUserItem.szSign)		
		:addTo(img_bg3)
	self.edit_Sign:registerScriptEditBoxHandler(editHanlder)
	self.edit_Sign:setName("edit_sign")	
	self.m_szSign = GlobalUserItem.szSign

	--游戏币
    self._txtScore = img_bg3:getChildByName("lb_coin")
    self._txtScore:setString(string.formatNumberThousands(GlobalUserItem.lUserScore,true))

	--游戏豆
	self._txtBean = img_bg3:getChildByName("lb_bean")
	self._txtBean:setString(string.format("%.2f", GlobalUserItem.dUserBeans))

	--元宝
	self._txtIngot = img_bg3:getChildByName("lb_yuanbao")
	self._txtIngot:setString(string.formatNumberThousands(GlobalUserItem.lUserIngot,true))
	
	--绑定账号
	local btn_bind = img_bg3:getChildByName("btn_bind")
	if GlobalUserItem.bVisitor == true and false == GlobalUserItem.getBindingAccount() then
		btn_bind:setTag(UserInfoLayer.BT_BINDING)
		:addTouchEventListener(btcallback)
	else
		btn_bind:setVisible(false)
    end

    --开通VIP
    local btn_vip = img_bg3:getChildByName("btn_vip")
	local vip = GlobalUserItem.cbMemberOrder or 0
	if 0 == vip then
		btn_vip:setTag(UserInfoLayer.BT_VIP)
		:addTouchEventListener(btcallback)		
	else
		btn_vip:setVisible(false)
		local sp_vip = cc.Sprite:create("Information/atlas_vipnumber.png")
		if nil ~= sp_vip then
			sp_vip:setPosition(lb_account:getContentSize().width + 610, lb_account:getContentSize().height)
			img_bg3:addChild(sp_vip)
			sp_vip:setTextureRect(cc.rect(28*vip,0,28,26))
		end
	end

	--取款
	local btn_get = img_bg3:getChildByName("btn_coin")
	btn_get:setTag(UserInfoLayer.BT_TAKE)
	btn_get:addTouchEventListener(btcallback)

	--充值
	local btn_charge = img_bg3:getChildByName("btn_bean")
	btn_charge:setTag(UserInfoLayer.BT_RECHARGE)
	btn_charge:addTouchEventListener(btcallback)

	--兑换
	local btn_exchange = img_bg3:getChildByName("btn_yuanbao")
	btn_exchange:setTag(UserInfoLayer.BT_EXCHANGE)
	btn_exchange:addTouchEventListener(btcallback)
	
    --性别选择
    local bGender = (GlobalUserItem.cbGender == yl.GENDER_MANKIND and true or false)

    self._cbtMan = img_bg3:getChildByName("check_man")
	self._cbtMan:setSelected(bGender)
	self._cbtMan:setTag(self.CBT_MAN)
	self._cbtMan:addEventListener(cbtlistener)

    self._cbtWoman = img_bg3:getChildByName("check_woman")
	self._cbtWoman:setSelected(not bGender)
	self._cbtWoman:setTag(self.CBT_WOMAN)
	self._cbtWoman:addEventListener(cbtlistener)
		
end

function UserInfoLayer:ctor(scene)
	cclog("function UserInfoLayer:ctor(scene) ==>")
	ExternalFun.registerNodeEvent(self)
	self._scene = scene
	local this = self
	self:setContentSize(yl.WIDTH,yl.HEIGHT) 

	--网络回调
    local modifyCallBack = function(result,message)
		this:onModifyCallBack(result,message)
	end
    --网络处理
	self._modifyFrame = ModifyFrame:create(self,modifyCallBack)

	self:layoutUI()
end


function UserInfoLayer:onButtonClickedEvent(tag,ref)

	cclog("function UserInfoLayer:onButtonClickedEvent(tag,ref) ==>")

	if tag == UserInfoLayer.BT_EXIT then
		self._scene:onKeyBack()
	elseif tag == UserInfoLayer.BT_TAKE then
		if GlobalUserItem.isAngentAccount() then
			return
		end
		self._scene:onChangeShowMode(yl.SCENE_BANK)
	elseif tag == UserInfoLayer.BT_BINDING then
		if GlobalUserItem.isAngentAccount() then
			return
		end
		self._scene:onChangeShowMode(yl.SCENE_BINDING)
	elseif tag == UserInfoLayer.BT_CONFIRM then
		if GlobalUserItem.isAngentAccount() then
			return
		end

		local szNickname = string.gsub(self.edit_Nickname:getText(), " ", "")

		--判断昵称长度
		if ExternalFun.stringLen(szNickname) < 6 then
			showToast(self, "游戏昵称必须大于6位以上,请重新输入!", 2)
			return
		end

		--判断是否有非法字符
		if true == ExternalFun.isContainBadWords(szNickname) then
			showToast(self, "昵称中包含敏感字符,请重试", 2)
			return
		end

		local szSign = string.gsub(self.edit_Sign:getText(), " ", "")

		--判断是否有非法字符
		if true == ExternalFun.isContainBadWords(szSign) then
			showToast(self, "个性签名中包含敏感字符,请重试", 2)
			return
		end

		if szNickname ~= GlobalUserItem.szNickName or szSign ~= GlobalUserItem.szSign then
			self:showPopWait()
			self._modifyFrame:onModifyUserInfo(GlobalUserItem.cbGender,szNickname,szSign)
		end
	elseif tag == UserInfoLayer.BT_VIP then
		if GlobalUserItem.isAngentAccount() then
			return
		end
		self._scene:onChangeShowMode(yl.SCENE_SHOP, Shop.CBT_VIP)
	elseif tag == UserInfoLayer.BT_RECHARGE then
		if GlobalUserItem.isAngentAccount() then
			return
		end
		self._scene:onChangeShowMode(yl.SCENE_SHOP, Shop.CBT_BEAN)
	elseif tag == UserInfoLayer.BT_EXCHANGE then
		if GlobalUserItem.isAngentAccount() then
			return
		end
		self._scene:onChangeShowMode(yl.SCENE_SHOP, Shop.CBT_ENTITY)
	elseif tag == UserInfoLayer.BT_QRCODE then
		-- local prolayer = PromoterInputLayer:create(self)
		-- self:addChild(prolayer)
	end
end

function UserInfoLayer:onClickUserHead( )
	cclog("function UserInfoLayer:onClickUserHead( ) ==>")

	if GlobalUserItem.isAngentAccount() then
		return
	end
	if GlobalUserItem.notEditAble() then
		return
	end

	local tmp = SelectHeadLayer:create(self)
	tmp:setTag(UserInfoLayer.LAY_SELHEAD)
	self:addChild(tmp)
end

function UserInfoLayer:onSelectedEvent(tag,sender,eventType)

	cclog("function UserInfoLayer:onSelectedEvent(tag,sender,eventType) ==>")

	if GlobalUserItem.isAngentAccount() then
		sender:setSelected(not sender:isSelected())
		return
	end
	if GlobalUserItem.notEditAble() then
		sender:setSelected(not sender:isSelected())
		return
	end

	local szNickname = string.gsub(self.edit_Nickname:getText(), " ", "")
	local szSign = string.gsub(self.edit_Sign:getText(), " ", "")
	if tag == UserInfoLayer.CBT_MAN then
		if GlobalUserItem.cbGender == yl.GENDER_MANKIND then
			sender:setSelected(not sender:isSelected())
			return
		end
		if bGender ~= true then
			local cbGender = yl.GENDER_MANKIND
			self:showPopWait()
			self._modifyFrame:onModifyUserInfo(cbGender, szNickname, szSign)
		end		
	end

	if tag == UserInfoLayer.CBT_WOMAN then
		if GlobalUserItem.cbGender == yl.GENDER_FEMALE then
			sender:setSelected(not sender:isSelected())
			return
		end
		
		if bGender ~= false then
			local cbGender = yl.GENDER_FEMALE
			self:showPopWait()
			self._modifyFrame:onModifyUserInfo(cbGender, szNickname, szSign)
		end
	end	
end

function UserInfoLayer:onEditEvent(name, editbox)

	cclog("function UserInfoLayer:onEditEvent(name, editbox) ==>")

	if "return" == name then
		if "edit_sign" == editbox:getName() then
			if GlobalUserItem.isAngentAccount() then
				self.edit_Sign:setText(GlobalUserItem.szSign)
				return
			end
			if GlobalUserItem.notEditAble() then
				self.edit_Sign:setText(GlobalUserItem.szSign)
				return
			end

			local szSign = string.gsub(self.edit_Sign:getText(), " ", "")
			--判断长度
			if ExternalFun.stringLen(szSign) < 1 then
				showToast(self, "个性签名不能为空", 2)
				self.edit_Sign:setText(GlobalUserItem.szSign)
				return
			end

			--判断emoji
			if ExternalFun.isContainEmoji(szSign) then
				showToast(self, "个性签名中包含非法字符,请重试", 2)
				self.edit_Sign:setText(GlobalUserItem.szSign)
				return
			end

			--判断是否有非法字符
			if true == ExternalFun.isContainBadWords(szSign) then
				showToast(self, "个性签名中包含敏感字符,请重试", 2)
				self.edit_Sign:setText(GlobalUserItem.szSign)
				return
			end
			self.m_szSign = szSign
			if szSign == GlobalUserItem.szSign then
				return
			end
		elseif "edit_nickname" == editbox:getName() then
			if GlobalUserItem.isAngentAccount() then
				self.edit_Nickname:setText(GlobalUserItem.szNickName)
				return
			end

			if GlobalUserItem.notEditAble() then
				self.edit_Nickname:setText(GlobalUserItem.szNickName)
				return
			end

			local szNickname = string.gsub(self.edit_Nickname:getText(), " ", "")
			--判断长度
			if ExternalFun.stringLen(szNickname) < 6 then
				showToast(self, "游戏昵称必须大于6位以上,请重新输入!", 2)
				self.edit_Nickname:setText(GlobalUserItem.szNickName)
				return
			end

			--判断emoji
			if ExternalFun.isContainEmoji(szNickname) then
				showToast(self, "昵称中包含非法字符,请重试", 2)
				self.edit_Sign:setText(GlobalUserItem.szSign)
				return
			end

			--判断是否有非法字符
			if true == ExternalFun.isContainBadWords(szNickname) then
				showToast(self, "昵称中包含敏感字符,请重试", 2)
				self.edit_Nickname:setText(GlobalUserItem.szNickName)
				return
			end
			self.m_szNick = szNickname
			if szNickname == GlobalUserItem.szNickName then
				return
			end
		end

		if self.m_szNick == "" or self.m_szSign == "" then
			return
		end
		self:showPopWait()
		self._modifyFrame:onModifyUserInfo(GlobalUserItem.cbGender,self.m_szNick,self.m_szSign)
	end
end

function UserInfoLayer:onExit( )

	cclog("function UserInfoLayer:onExit( ) ==>")

	if nil ~= self.edit_Sign then
		self.edit_Sign:unregisterScriptEditBoxHandler()
	end

	if nil ~= self.edit_Nickname then
		self.edit_Nickname:unregisterScriptEditBoxHandler()
	end

	if self._modifyFrame:isSocketServer() then
		self._modifyFrame:onCloseSocket()
	end
end

function UserInfoLayer:onEnterTransitionFinish()
	cclog("function UserInfoLayer:onEnterTransitionFinish() ==>")
	self:showPopWait()
	self._modifyFrame:onQueryUserInfo()
end

function UserInfoLayer:sendModifySystemFace( wFaceId )
	cclog("function UserInfoLayer:sendModifySystemFace( wFaceId ) ==>")
	self:showPopWait()
	self._modifyFrame:onModifySystemHead(wFaceId)
end

--操作结果
function UserInfoLayer:onModifyCallBack(result,message)

	cclog("function UserInfoLayer:onModifyCallBack(result,message) ==>")

	self:dismissPopWait()
	if  message ~= nil and message ~= "" then
		showToast(self,message,2);
	end
	if -1 == result then
		return
	end

	bGender = (GlobalUserItem.cbGender == yl.GENDER_MANKIND and true or false)
	self._cbtMan:setSelected(bGender)
	self._cbtWoman:setSelected(not bGender)

	if yl.SUB_GP_USER_FACE_INFO == result then
		self:onFaceResultSuccess()
		self:removeChildByTag(UserInfoLayer.LAY_SELHEAD, true)
	elseif loginCMD.SUB_GP_USER_INDIVIDUAL == result then
		-- 推广员按钮
		--local noSpreader = GlobalUserItem.szSpreaderAccount == ""
		--self.m_btnPromoter:setVisible(noSpreader)
		--self.m_btnPromoter:setEnabled(noSpreader)
	elseif self._modifyFrame.INPUT_SPREADER == result then
		--local noSpreader = GlobalUserItem.szSpreaderAccount == ""
		--self.m_btnPromoter:setVisible(noSpreader)
		--self.m_btnPromoter:setEnabled(noSpreader)
	end	
end

function UserInfoLayer:onKeyBack(  )

	cclog("function UserInfoLayer:onKeyBack(  ) ==>")

	if nil ~= self._scene._popWait then
		showToast(self, "当前操作不可返回", 2)
	end
    return true
end

--显示等待
function UserInfoLayer:showPopWait()
	cclog("function UserInfoLayer:showPopWait() ==>")
	self._scene:showPopWait()
end

--关闭等待
function UserInfoLayer:dismissPopWait()
	cclog("function UserInfoLayer:dismissPopWait() ==>")

	self._scene:dismissPopWait()
end

--头像更改结果
function UserInfoLayer:onFaceResultSuccess()
	cclog("function UserInfoLayer:onFaceResultSuccess() ==>")
	--更新头像
	self._head:updateHead(GlobalUserItem)
	--通知
	local eventListener = cc.EventCustom:new(yl.RY_USERINFO_NOTIFY)
    eventListener.obj = yl.RY_MSG_USERHEAD
    cc.Director:getInstance():getEventDispatcher():dispatchEvent(eventListener)
end

return UserInfoLayer