-- Name: BindingRegisterLayer
-- Func: 账号绑定注册界面
-- Author: Johny



local ModifyFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.ModifyFrame")
local NotifyMgr = appdf.req(appdf.EXTERNAL_SRC .. "NotifyMgr")
local ServiceLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.other.ServiceLayer")


local BindingRegisterLayer = class("BindingRegisterLayer",function(scene)
        local lay =  display.newLayer()
    return lay
end)

BindingRegisterLayer.BT_REGISTER = 1
BindingRegisterLayer.BT_RETURN   = 2
BindingRegisterLayer.BT_AGREEMENT= 3
BindingRegisterLayer.CBT_AGREEMENT = 4

BindingRegisterLayer.bAgreement = false
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")

function BindingRegisterLayer:ctor(scene)

    cclog("function BindingRegisterLayer:ctor(scene) ==> ")

    local this = self
    self._scene = scene

    local  btcallback = function(ref, type)
        if type == ccui.TouchEventType.ended then
            this:onButtonClickedEvent(ref:getTag(),ref)
        end
    end

    --网络回调
    local modifyCallBack = function(result,message)
        this:onModifyCallBack(result,message)
    end
    --网络处理
    self._modifyFrame = ModifyFrame:create(self,modifyCallBack)


    local layer, csbNode = ExternalFun.loadRootCSB("register/RegisterLayer.csb", self)
    local img_bg = csbNode:getChildByName("img_bg")

    --close
    local btn_close = img_bg:getChildByName("btn_close")
    btn_close:setTag(BindingRegisterLayer.BT_RETURN)
    btn_close:addTouchEventListener(btcallback)

    --账号输入
    local img_input_acc = img_bg:getChildByName("img_input_acc")
    self.edit_Account = ccui.EditBox:create(img_input_acc:getContentSize(), "blank.png")
        :move(img_input_acc:getPosition())
        :setAnchorPoint(cc.p(0.5,0.5))
        :setFontName("fonts/yuanti_sc_light.ttf")
        :setPlaceholderFontName("fonts/yuanti_sc_light.ttf")
        :setFontSize(24)
        :setPlaceholderFontSize(24)
        :setPlaceholderFontColor(yl.G_COLOR_INPUT_PLACEHOLDER)
        :setFontColor(yl.G_COLOR_INPUT_FONT)
        :setMaxLength(31)
        :setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
        :setPlaceHolder("6-31位字符")
        :addTo(img_bg)

    --密码输入  
    local img_input_pwd = img_bg:getChildByName("img_input_pwd")
    self.edit_Password = ccui.EditBox:create(img_input_pwd:getContentSize(), "blank.png")
        :move(img_input_pwd:getPosition())
        :setAnchorPoint(cc.p(0.5,0.5))
        :setFontName("fonts/yuanti_sc_light.ttf")
        :setPlaceholderFontName("fonts/yuanti_sc_light.ttf")
        :setFontSize(24)
        :setPlaceholderFontSize(24)
        :setPlaceholderFontColor(yl.G_COLOR_INPUT_PLACEHOLDER)
        :setFontColor(yl.G_COLOR_INPUT_FONT)
        :setMaxLength(26)
        :setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
        :setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
        :setPlaceHolder("6-26位英文字母，数字，下划线组合")
        :addTo(img_bg)


    --确认密码输入    
    local img_input_okpwd = img_bg:getChildByName("img_input_okpwd")
    self.edit_RePassword = ccui.EditBox:create(img_input_okpwd:getContentSize(), "blank.png")
        :move(img_input_okpwd:getPosition())
        :setAnchorPoint(cc.p(0.5,0.5))
        :setFontName("fonts/yuanti_sc_light.ttf")
        :setPlaceholderFontName("fonts/yuanti_sc_light.ttf")
        :setFontSize(24)
        :setPlaceholderFontSize(24)
        :setPlaceholderFontColor(yl.G_COLOR_INPUT_PLACEHOLDER)
        :setFontColor(yl.G_COLOR_INPUT_FONT)
        :setMaxLength(26)
        :setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
        :setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
        :setPlaceHolder("6-26位英文字母，数字，下划线组合")
        :addTo(img_bg)


    --推广员   
    local img_input_prom = img_bg:getChildByName("img_input_prom")
    self.edit_Spreader = ccui.EditBox:create(img_input_prom:getContentSize(), "blank.png")
        :move(img_input_prom:getPosition())
        :setAnchorPoint(cc.p(0.5,0.5))
        :setFontName("fonts/yuanti_sc_light.ttf")
        :setPlaceholderFontName("fonts/yuanti_sc_light.ttf")
        :setFontSize(24)
        :setPlaceholderFontSize(24)
        :setPlaceholderFontColor(yl.G_COLOR_INPUT_PLACEHOLDER)
        :setFontColor(yl.G_COLOR_INPUT_FONT)
        :setMaxLength(32)
        :setInputMode(cc.EDITBOX_INPUT_MODE_NUMERIC)--:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
        :setPlaceHolder("请输入推广员ID")
        :addTo(img_bg)

        
    --条款协议
    self.cbt_Agreement = img_bg:getChildByName("check_rules")
        :setSelected(BindingRegisterLayer.bAgreement)
        :setTag(BindingRegisterLayer.CBT_AGREEMENT)

    --显示协议
    local btn_rules = img_bg:getChildByName("btn_rules")
        :setTag(BindingRegisterLayer.BT_AGREEMENT)
        :addTouchEventListener(btcallback)

    --注册按钮
    local btn_okre = img_bg:getChildByName("btn_okre")
        :setTag(BindingRegisterLayer.BT_REGISTER)
        :addTouchEventListener(btcallback)



    --条款界面
    self._serviceView = nil
end


function BindingRegisterLayer:onButtonClickedEvent(tag,ref)
    cclog("function BindingRegisterLayer:onButtonClickedEvent(tag,ref) ==> ")

    if tag == BindingRegisterLayer.BT_RETURN then
        self._scene:onKeyBack()
    elseif tag == BindingRegisterLayer.BT_AGREEMENT then
        if self._serviceView == nil then
            self._serviceView = ServiceLayer:create()
                :move(yl.WIDTH,0)
                :addTo(self)
        else
            self._serviceView:stopAllActions()
        end
        self._serviceView:runAction(cc.MoveTo:create(0.3,cc.p(0,0)))
    elseif tag == BindingRegisterLayer.BT_REGISTER then
        local szAccount = string.gsub(self.edit_Account:getText(), " ", "")
        local szPassword = string.gsub(self.edit_Password:getText(), " ", "")
        local szRePassword = string.gsub(self.edit_RePassword:getText(), " ", "")

        local len = ExternalFun.stringLen(szAccount)--#szAccount
        if len < 6 or len > 31 then
            showToast(self,"游戏帐号必须为6~31个字符，请重新输入！",2,cc.c4b(250,0,0,255));
            return
        end

        --判断emoji
        if ExternalFun.isContainEmoji(szAccount) then
            showToast(self, "帐号包含非法字符,请重试", 2)
            return
        end

        --判断是否有非法字符
        if true == ExternalFun.isContainBadWords(szAccount) then
            showToast(self, "帐号中包含敏感字符,不能注册", 2)
            return
        end

        len = ExternalFun.stringLen(szPassword)
        if len < 6 or len > 26 then
            showToast(self,"密码必须为6~26个字符，请重新输入！",2,cc.c4b(250,0,0,255));
            return
        end 

        if szPassword ~= szRePassword then
            showToast(self,"二次输入密码不一致，请重新输入！",2,cc.c4b(250,0,0,255));
            return
        end

        -- 与帐号不同
        if string.lower(szPassword) == string.lower(szAccount) then
            showToast(self,"密码不能与帐号相同，请重新输入！",2,cc.c4b(250,0,0,255));
            return
        end

        --[[-- 首位为字母
        if 1 ~= string.find(szPassword, "%a") then
            showToast(self,"密码首位必须为字母，请重新输入！",2,cc.c4b(250,0,0,255));
            return
        end]]

        local bAgreement = self:getChildByTag(BindingRegisterLayer.CBT_AGREEMENT):isSelected()
        if bAgreement == false then
            showToast(self,"请先阅读并同意《游戏中心服务条款》！",2,cc.c4b(250,0,0,255));
            return
        end        
                
        local szSpreader = string.gsub(self.edit_Spreader:getText(), " ", "")
        self._scene:showPopWait()
        self._modifyFrame:onAccountRegisterBinding(szAccount,md5(szPassword),szSpreader)
        self.szAccount = szAccount
        self.szPassword = szPassword
    end
end

function BindingRegisterLayer:setAgreement(bAgree)

    cclog("function BindingRegisterLayer:setAgreement(bAgree) ==> ")

    self.cbt_Agreement:setSelected(bAgree)
end

--操作结果
function BindingRegisterLayer:onModifyCallBack(result,message)
    cclog("======== BindingRegisterLayer::onModifyCallBack ========")

    self._scene:dismissPopWait()
    if  message ~= nil and message ~= "" then
        showToast(self,message,2);
    end

    if result == 2 then
        self._scene:showPopWait()
        GlobalUserItem.setBindingAccount()
        GlobalUserItem.szPassword = self.szPassword
        GlobalUserItem.szAccount = self.szAccount
        --保存数据
        GlobalUserItem.onSaveAccountConfig()

        self:runAction(cc.Sequence:create(cc.DelayTime:create(1.0), cc.CallFunc:create(function ()
            self._scene:dismissPopWait()
                  
            --重新登录
            GlobalUserItem.nCurRoomIndex = -1
            self:getParent():getParent():getApp():enterSceneEx(appdf.CLIENT_SRC.."plaza.views.LogonScene","FADE",1)
            GlobalUserItem.reSetData()
            --读取配置
            GlobalUserItem.LoadData()
            --断开好友服务器
            FriendMgr:getInstance():reSetAndDisconnect()
            --通知管理
            NotifyMgr:getInstance():clear()
            end)))
    end
end

return BindingRegisterLayer