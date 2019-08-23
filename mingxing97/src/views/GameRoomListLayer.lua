-- Name: RoomListLayer
-- Func: 明星97房间层
-- Author: Johny

-- local RoomListLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.plazanew.RoomListLayer")
local ExternalFun =  appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local module_pre = "game.mingxing97.src"
local cmd = appdf.req(module_pre .. ".models.CMD_Game")

local GameRoomListLayer = class("GameRoomListLayer", cc.Layer)

local BT_CHUJI1 = 1
local BT_CHUJI2 = 2
local BT_ZHONGJI1 = 3
local BT_ZHONGJI2 = 4
local BT_GAOJI1 = 5
local BT_GAOJI2 = 6
local BT_RETURN = 11

--获取开始坐下默认坐下位置
function GameRoomListLayer.getDefaultSit()
    return yl.INVALID_TABLE,yl.INVALID_CHAIR
end

function GameRoomListLayer:onEnterRoom( frameEngine )
    cclog("自定义房间进入")
    if nil ~= frameEngine and frameEngine:SitDown(yl.INVALID_TABLE,yl.INVALID_CHAIR) then
        return true
    end
end

--游戏房间列表
function GameRoomListLayer:ctor(scene, frameEngine, isQuickStart)
	self._scene = scene
    self._frameEngine = frameEngine
	--添加沙盒路径
    cc.FileUtils:getInstance():addSearchPath(device.writablePath .. cmd.RES_PATH)
    self:layoutUI()

    self.m_tabRoomListInfo = {}
    dump(GlobalUserItem.roomlist, "GlobalUserItem.roomlist")
    for k,v in pairs(GlobalUserItem.roomlist) do
        if tonumber(v[1]) == GlobalUserItem.nCurGameKind then
            local listinfo = v[2]
            if type(listinfo) ~= "table" then
                break
            end
            local normalList = {}
            for k,v in pairs(listinfo) do
                if v.wServerType ~= yl.GAME_GENRE_PERSONAL then
                    table.insert( normalList, v)
                end
            end
            self.m_tabRoomListInfo = normalList
            break
        end
    end 
    dump(self.m_tabRoomListInfo, "self.m_tabRoomListInfo")
end

function GameRoomListLayer:layoutUI()
	local csbNode = ExternalFun.loadCSB(cmd.RES_PATH.."gameroomlist/GameRoomListLayer.csb", self)
	local function btncallback(ref, tType)
        if tType == ccui.TouchEventType.ended then
            self:onButtonClickedEvent(ref:getTag(),ref)
        end
    end


    --进游戏
    local aa = 1
    for i = 1, 3 do
    	for j = 1, 2 do
    		local btn = appdf.getNodeByName(csbNode, "btn_" .. i .. "_" .. j)
    		btn:setTag(aa)
    		btn:addTouchEventListener(btncallback)
            aa = aa + 1
    	end
    end

    --返回
    local btn_return = appdf.getNodeByName(csbNode, "btn_return")
    btn_return:setTag(BT_RETURN)
    btn_return:addTouchEventListener(btncallback)

    --id
    appdf.getNodeByName(csbNode, "lb_id"):setString("" .. GlobalUserItem.dwGameID)

    --coin
    appdf.getNodeByName(csbNode, "lb_coin"):setString("" .. GlobalUserItem.lUserScore)
end

function GameRoomListLayer:onButtonClickedEvent(tag, ref)
	if tag >= BT_CHUJI1 and tag <= BT_GAOJI2 then
        self:onEnterGame(tag)
	elseif tag == BT_RETURN then
        self._scene:onChangeShowMode()
	end
end

function GameRoomListLayer:onEnterGame(tag)
    local index = tag
    local roominfo = self.m_tabRoomListInfo[index]
    if not roominfo then
        return
    end
    GlobalUserItem.nCurRoomIndex = roominfo._nRoomIndex
    GlobalUserItem.bPrivateRoom = false
    cclog("GameRoomListLayer:onEnterGame===>" .. roominfo._nRoomIndex)
    self._scene:onStartGame()
end

return GameRoomListLayer