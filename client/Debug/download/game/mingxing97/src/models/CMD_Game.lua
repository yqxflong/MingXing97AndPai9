-- Name: CMD_Game
-- Func: 游戏配置
-- Author: Johny


local cmd = {}

--游戏版本
cmd.VERSION 					= appdf.VersionValue(6,7,0,1)
--游戏标识
cmd.KIND_ID						= 100
cmd.GAME_NAME					="明星97"
cmd.RES_PATH                    = "download/game/mingxing97/res/"

cmd.FULL_COUNT                  = 27                                    --全牌数目
cmd.MAX_COUNT                   = 9                                     --最大数目

--状态定义
cmd.GS_TK_FREE				    = 0
cmd.GS_TK_PLAYING				= 100									--游戏开始

--TAG定义
cmd.NUMBER7                     = 0                                     --数字7
cmd.BLUECARD                    = 1                                     --蓝牌
cmd.REDCARD                     = 2                                     --红牌
cmd.YELLOWCARD                  = 3                                     --黄牌
cmd.STRAWBERRY                  = 4                                     --草莓
cmd.WATERMELON                  = 5                                     --西瓜
cmd.BELL                        = 6                                     --铃铛
cmd.PAWPAW                      = 7                                     --木瓜
cmd.ORANGE                      = 8                                     --桔子

--常量定义
--单线赔率 数字7、蓝牌、红牌、黄牌、草莓、西瓜、铃铛、木瓜、桔子、杂牌、1草莓、2草莓
local LineTimes = { 80, 70, 50, 30, 10, 20, 18, 14, 10, 10, 2, 5 }
--全盘赔率 数字7、蓝牌、红牌、黄牌、草莓、西瓜、铃铛、木瓜、桔子、杂牌、全水果
local AllWinTimes = { 200, 100, 90, 60, 80, 60, 40, 40, 40, 40, 15}
--奖池奖励 数字7、蓝牌、红牌、黄牌、草莓、西瓜、铃铛、木瓜、桔子
local JackPot = { 10000, 10000, 10000, 10000, 10000, 10000, 5000, 5000, 5000, 0, 0}
--额外奖励(9个全图案、9个7、8个7、7个7、6个7、5个7、4个7、3个7且连线、蓝牌连线、红牌连线、全水果)
local ExtraAwards = { 10000, 20000, 5000, 2500, 2000, 1500, 1000, 500, 500, 500, 500 }
-------------------------------------------------------------------------------------
--服务器命令结构
cmd.SUB_S_GAME_END              = 100               --游戏滚动
cmd.SUB_S_RECORD_LOTTERY        = 101               --大奖记录
-- cmd.SUB_S_MEINV_CONTROL         = 102               --美女控制结果
-- cmd.SUB_S_STOCK_CONTROL         = 103               --库存控制结果
cmd.SUB_S_WEIGHT_CONTROL        = 104               --权重配置结果
cmd.SUB_S_STOCK_SECTION_CONTROL = 105               --库存区间结果
cmd.SUB_S_LOTTERY_CONTROL       = 106               --大奖控制结果
cmd.SUB_S_STOCK_MEINV_CONTROL   = 107               --美女概率、五个库存、衰减值和抽水值一起查询结果


--游戏状态
cmd.CMD_S_StatusFree = {
  {k = "iChangeRadio", t = "int"},            --兑换倍率
  {k = "lJackPot", t = "score"},              --奖池信息
  {k = "iUnitUpScore", t = "int"},            --单位上分
  {k = "szGameRoomName", t = "string", s = 32} --房间名称
}
--游戏状态
cmd.CMD_S_StatusPlay = {

}

--游戏结束
cmd.CMD_S_GameEnd = {
	{k = "cbHandReelData", t = "byte", l = {5, 5, 5, 5, 5, 5, 5, 5, 5}},           --格子结果
	{k = "cbWinLine", t = "bool", l = {8}},       --可连的线
	{k = "cbGirlPicIndex", t = "byte"},           --哪张美女图片1表示没有，2、3、4分别对应倍数
	{k = "cbGirlAwardTimes", t = "int"},          --美女图案奖励倍数
	{k = "cbGirlAwardCount", t = "int"},          --美女图案奖励次数
	{k = "lJackPot", t = "score"},                --累计奖池
	{k = "lLineWinScore", t = "score"},           --单线赢分
	{k = "lAllWinScore", t = "score"},            --全盘赢分
	{k = "lJackPotWinScore", t = "score"},        --奖池赢分
	{k = "lExtraWinScore", t = "score"},          --额外赢分
	{k = "lNumber7WinScore", t = "score"},        --数字7得分
	{k = "lGirlWinScore", t = "score"},           --美女图案得分
}

-- --美女概率控制
-- cmd.CMD_S_MeiNvControl = {
--     {k = "iGirlOutProbability",t = "int", l = {4}}   --美女控制概率

-- }

-- --库存控制（包含5个库存、衰减值和抽水值）
-- cmd.CMD_S_StockControl = {
--     {k = "cbControlType", t = "byte"},                --控制类型   //0表示80库存，1表示160库存，2表示240库存，3表示320库存，4表示400库存，5表示衰减值（抽水率），6表示抽水值
--     {k = "lControlScore", t = "score"}             --控制值
-- }

--权重配置（有五个权重）
cmd.CMD_S_WeightControl = {
    {k = "cbControlType", t = "byte"},                --控制类型  //0表示非常困难权重，1表示困难权重，2表示普通权重，3表示容易权重，4表示非常容易权重
    {k = "iReelWeight", t = "int", l = {cmd.FULL_COUNT}}   --控制值    //每一个权重都有27个值
}

--库存区间（有五个库存区间）
cmd.CMD_S_StockSectionControl = {
    {k = "cbControlType", t = "byte"},              --//控制类型    //0表示80的库存区间，1表示160的库存区间，2表示240的库存区间，3表示320的库存区间，4表示400的库存区间
    {k = "iStockScoreSection", t = "int" ,l = {4} } --库存区间（5个库存区间对应80、160、240、320、400分;每个库存区间有4个，如0-100,100-200,200-300,400-最大）
}

--大奖控制（概率控制）
cmd.CMD_S_LotteryControl = {
    {k = "cbControlType", t = "byte"},              --控制类型  //0表示非常困难大奖概率，1表示困难大奖概率，2表示普通大奖概率，3表示容易大奖概率，4表示非常容易大奖概率
    {k = "ProbabilityLottery", t = "int" ,l= {14}}   --概率控制大奖（第一个值保存的是是否出大奖，剩余的包括9个全盘，全水果，8个7，7个7，6个7）
}

--美女概率  五个库存、衰减值和抽水值一起查询结果
cmd.CMD_S_StockMeiNvControl = {
    {k = "cbControlType", t = "byte"},            --控制类型 23表示美女概率、五个库存、衰减值和抽水值一起查询结果
    {k = "iGirlOutProbability", t = "int", l={4}},--美女概率
    {k="lStockScore",t="score", l={5}},           --五个库存值
    {k="lStorageDeduct",t= "score"},              --库存衰减
    {k="lStockWin",t = "score"}                   --库存抽水值
}

-------------------------------------------------------------------------------------
--客户端命令结构
--用户下注
cmd.SUB_C_ADD_SCORE               = 1
cmd.SUB_C_RECORD_LOTTERY          = 2

cmd.SUB_C_MEINV_CONTROL           = 5       --美女概率控制
cmd.SUB_C_STOCK_CONTROL           = 6       --库存控制（包含5个库存，衰减值，和抽水值）
cmd.SUB_C_WEIGHT_CONTROL          = 7       --权重配置（有五个权重）
cmd.SUB_C_STOCK_SECTION_CONTROL   = 8       --库存区间（有5个库存区间）
cmd.SUB_C_LOTTERY_CONTROL         = 9       --大奖控制（概率控制）
cmd.SUB_C_QUERY_CONRTOL           = 10      --查询控制


--用户加注
cmd.CMD_C_AddScore = {
	{k = "lScore", t = "score"}                 --加注数目
}

--查询大奖记录
cmd.CMD_S_RecordLottery = {
	{k = "BigAwardRecord", t = "int", l = {16}}  --大奖数据记录，顺序是蓝牌、红牌、草莓、黄牌、西瓜、铃铛、木瓜、桔子、杂牌、9个7、8个7、7个7、6个7、5个7、4个7、全水果
}

--美女控制概率
cmd.CMD_C_MeiNvControl = {
    --0表示出美女概率，1表示出两倍美女概率，2表示出三倍美女概率，3表示出四倍美女概率
    {k = "iGirlOutProbability",t = "int", l={4}}  --美女控制概率
}

--库存控制（包含5个库存、衰减值和抽水值）
cmd.CMD_C_StockControl={
    {k="cbControlType",t="byte"},   --//控制类型
    --0表示80库存，1表示160库存，2表示240库存，3表示320库存，4表示400库存，5表示衰减值（抽水率），6表示抽水值
    {k= "lControlScore" , t = "score", l={16}} --控制值
    --//控制类型 //0表示80库存，1表示160库存，2表示240库存，3表示320库存，4表示400库存，5表示衰减值（抽水率），6表示抽水值
}

--权重配置（有五个权重）
cmd.CMD_C_WeightControl={
    {k="cbControlType" , t = "byte"},   --控制类型
    --0表示非常困难权重，1表示困难权重，2表示普通权重，3表示容易权重，4表示非常容易权重
    {k="iReelWeight" , t = "int",l ={cmd.FULL_COUNT}} --控制值 每一个权重都有27个值
    --控制类型 0表示非常困难权重，1表示困难权重，2表示普通权重，3表示容易权重，4表示非常容易权重
}

--库存区间（有五个库存区间）
cmd.CMD_C_StockSectionControl={
    {k ="cbControlType" , t = "byte"},     --控制类型
    --0表示80的库存区间，1表示160的库存区间，2表示240的库存区间，3表示320的库存区间，4表示400的库存区间
    {k ="iStockScoreSection", t = "int" ,l={4}} --库存区间
    --（5个库存区间对应80、160、240、320、400分;每个库存区间有4个，如0-100,100-200,200-300,400-最大）
}

--大奖控制（概率控制）
cmd.CMD_C_LotteryControl = {
    {k = "cbControlType",t="byte"},    --控制类型
    --0表示非常困难大奖概率，1表示困难大奖概率，2表示普通大奖概率，3表示容易大奖概率，4表示非常容易大奖概率
    {k = "ProbabilityLottery",t="int",l = {14}} --概率控制大奖
    --（第一个值保存的是是否出大奖，剩余的包括9个全盘，全水果，8个7，7个7，6个7）
}

--控制查询
cmd.CMD_C_QueryControl ={
--0表示查询美女概率，
--1表示查询80的库存，2表示查160库存，3表示查询240库存，4表示查询320库存，5表示查询400库存
--6表示查询衰减值，7表示查询抽水值，
--8表示查询非常困难权重，9表示查询困难权重，10表示查询普通权重，11表示容易权重，12表示非常容易权重，
--13表示80的库存区间，14表示160的库存区间，15表示240的库存区间，16表示320的库存区间，17表示400的库存区间，
--18表示非常困难的大奖控制，19表示困难的大奖控制，20表示普通的大奖控制，21表示容易的大奖控制，22表示非常容易的大奖控制
--23 表示美女概率、五个库存、衰减值和抽水值一起查询结果
    {k="cbQueryControlType",t="byte"}
}
return cmd