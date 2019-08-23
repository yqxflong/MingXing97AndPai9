-- Name: PriRoomCreateLayer
-- Func: 私房创建界面
-- Author: Johny


local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local CreateLayerModel = appdf.req(PriRoom.MODULE.PLAZAMODULE .."models.CreateLayerModel")
local PriRoomCreateLayer = class("PriRoomCreateLayer", CreateLayerModel)


local BTN_CLOSE = 1
local BTN_START = 2

local CHECK_JUSHU_BASE = 10
local CHECK_JUSHU_2  = 10
local CHECK_JUSHU_3  = 13
local CHECK_JUSHU_4  = 14

local CHECK_FANGFEI_1 = 20
local CHECK_FANGFEI_2 = 23

local CHECK_ZHUANGJIA_1 = 30
local CHECK_ZHUANGJIA_2 = 31

--根据读取资源模式添加路径
local RES_PATH = device.writablePath .. "download/game/paijiu/privatemode/res/"

function PriRoomCreateLayer:ctor( scene )
    PriRoomCreateLayer.super.ctor(self, scene)

    --var
    self.mPlayerCnt   = 2   --人数
    self.mJushuCnt    = 10  --局数
    self.mFangfeiMode = 0   --房费模式
    self.mZhuangjiaMode = 0 --庄家模式
    self.mJushuArr = {}
    self.mFangfeiArr = {}
    self.mZhuangjiaArr = {}




    --添加沙盒路径
    cc.FileUtils:getInstance():addSearchPath(RES_PATH)
    -- 加载csb资源
    local rootLayer, csbNode = ExternalFun.loadRootCSB("room/PrivateRoomCreateLayer.csb", self )
    self.m_csbNode = csbNode

    local function btncallback(ref, tType)
        if tType == ccui.TouchEventType.ended then
            self:onButtonClickedEvent(ref:getTag(),ref)
        end
    end

    local checkcallback = function (sender,eventType)
        self:onCheckEvent(sender:getTag(),sender)
    end

    local btn_close = appdf.getNodeByName(csbNode, "btn_close")
    btn_close:setTag(BTN_CLOSE)
    btn_close:addTouchEventListener(btncallback)

    local btn_start = appdf.getNodeByName(csbNode, "btn_start")
    btn_start:setTag(BTN_START)
    btn_start:addTouchEventListener(btncallback)

    --局数选择
    local check_jushu_2 = appdf.getNodeByName(csbNode, "check_jushu_2")
    check_jushu_2:setTag(CHECK_JUSHU_2)
    check_jushu_2:addEventListener(checkcallback)
    check_jushu_2:setSelected(true)

    local check_jushu_3 = appdf.getNodeByName(csbNode, "check_jushu_3")
    check_jushu_3:setTag(CHECK_JUSHU_3)
    check_jushu_3:addEventListener(checkcallback)

    local check_jushu_4 = appdf.getNodeByName(csbNode, "check_jushu_4")
    check_jushu_4:setTag(CHECK_JUSHU_4)
    check_jushu_4:addEventListener(checkcallback)

    self.mJushuArr = {check_jushu_2, check_jushu_3, check_jushu_4}

    --房费模式
    local check_fangfei_1 = appdf.getNodeByName(csbNode, "check_fangfei_1")
    check_fangfei_1:setTag(CHECK_FANGFEI_1)
    check_fangfei_1:addEventListener(checkcallback)
    check_fangfei_1:setSelected(true)

    local check_fangfei_2 = appdf.getNodeByName(csbNode, "check_fangfei_2")
    check_fangfei_2:setTag(CHECK_FANGFEI_2)
    check_fangfei_2:addEventListener(checkcallback)

    self.mFangfeiArr = {check_fangfei_1, check_fangfei_2}
    --庄家模式
    local check_zhuangjia_1 = appdf.getNodeByName(csbNode, "check_zhuangjia_1")
    check_zhuangjia_1:setTag(CHECK_ZHUANGJIA_1)
    check_zhuangjia_1:addEventListener(checkcallback)
    check_zhuangjia_1:setSelected(true)

    local check_zhuangjia_2 = appdf.getNodeByName(csbNode, "check_zhuangjia_2")
    check_zhuangjia_2:setTag(CHECK_ZHUANGJIA_2)
    check_zhuangjia_2:addEventListener(checkcallback)

    self.mZhuangjiaArr = {check_zhuangjia_1, check_zhuangjia_2}
end

function PriRoomCreateLayer:onCheckEvent(tag, ref)
    if tag >= CHECK_JUSHU_2 and tag <= CHECK_JUSHU_4 then
       self.mPlayerCnt = tag - CHECK_JUSHU_BASE
       self.mJushuCnt = self.mPlayerCnt * 5
       for k,v in ipairs(self.mJushuArr) do
           v:setSelected(false)
       end
       ref:setSelected(true)
    elseif tag >= CHECK_FANGFEI_1 and tag <= CHECK_FANGFEI_2 then
       self.mFangfeiMode = tag - CHECK_FANGFEI_1
       for k,v in ipairs(self.mFangfeiArr) do
           v:setSelected(false)
       end
       ref:setSelected(true)
    elseif tag >= CHECK_ZHUANGJIA_1 then
       self.mZhuangjiaMode = tag - CHECK_ZHUANGJIA_1
       for k,v in ipairs(self.mZhuangjiaArr) do
           v:setSelected(false)
       end
       ref:setSelected(true)
    end
end

function PriRoomCreateLayer:onButtonClickedEvent(tag, ref)
    if tag == BTN_CLOSE then
        self:removeFromParent()
    elseif tag == BTN_START then
        PriRoom:getInstance():showPopWait()
        PriRoom:getInstance():getNetFrame():onCreateRoom()
    end
end

function PriRoomCreateLayer:onLoginPriRoomFinish()
    cclog("PriRoomCreateLayer:onLoginPriRoomFinish===>")
    local meUser = PriRoom:getInstance():getMeUserItem()
    if nil == meUser then
        return false
    end
    -- 发送创建桌子
    if ((meUser.cbUserStatus == yl.US_FREE or meUser.cbUserStatus == yl.US_NULL or meUser.cbUserStatus == yl.US_PLAYING)) then
        if PriRoom:getInstance().m_nLoginAction == PriRoom.L_ACTION.ACT_CREATEROOM then
            -- 创建登陆
            local buffer = CCmd_Data:create(188)
            buffer:setcmdinfo(self._cmd_pri_game.MDM_GR_PERSONAL_TABLE,self._cmd_pri_game.SUB_GR_CREATE_TABLE)
            buffer:pushscore(1)
            buffer:pushdword(self.mJushuCnt) --局数限制
            buffer:pushdword(0)  --时间限制
            buffer:pushword(self.mPlayerCnt)   --人数
            buffer:pushdword(0)   --税率
            buffer:pushstring("", yl.LEN_PASSWORD)
            --------------------------------一共100个附加参数-------------------
            --单个游戏规则(额外规则)
            buffer:pushbyte(1)                                       --消耗
            buffer:pushbyte(self.mPlayerCnt)  --人数(2,3,4)
            buffer:pushbyte(self.mZhuangjiaMode)      --坐庄模式(0~N)
            buffer:pushbyte(self.mJushuCnt) --局数限制(10,15,20)
            buffer:pushbyte(self.mFangfeiMode) --房费模式(0~N)
            for i = 1, 100 - 5 do
                buffer:pushbyte(0)
            end
            --------------------------------------------------------------------
            PriRoom:getInstance():getNetFrame():sendGameServerMsg(buffer)

            self:removeFromParent()
            return true
        end        
    end
    return false
end


return PriRoomCreateLayer