-- Name: CMD_Game
-- Func: 命令定义
-- Author: Johny


local cmd =  {}

--游戏版本
cmd.VERSION 					= appdf.VersionValue(6,7,0,1)
--游戏标识
cmd.KIND_ID						= 20
--游戏名字
cmd.KIND_NAME					= "牌九"

--游戏资源路径
cmd.RES_PATH = device.writablePath .. "download/game/paijiu/res/"

-- 语音动画
cmd.VOICE_ANIMATION_KEY = "voice_ani_key"
	
--游戏人数
cmd.GAME_PLAYER					= 4

--视图位置
cmd.MY_VIEWID					= 3

--最大数目
cmd.MAX_COUNT                   = 4

--最大赔率
cmd.MAX_TIMES                   = 5

--
cmd.SERVER_LEN                  = 32

--******************         游戏状态             ************--
--等待开始
cmd.GS_TK_FREE					= 0
--下注状态
cmd.GS_TK_SCORE					= 100
--游戏进行
cmd.GS_TK_PLAYING				= 101

--*********************      服务器命令结构       ************--
--游戏开始
cmd.SUB_S_GAME_START			= 100
--加注结果
cmd.SUB_S_ADD_SCORE				= 101
--用户强退
cmd.SUB_S_PLAYER_EXIT			= 102
--发牌消息
cmd.SUB_S_SEND_CARD				= 103
--游戏结束
cmd.SUB_S_GAME_END				= 104
--用户摊牌
cmd.SUB_S_OPEN_CARD				= 105
--用户打色
cmd.SUB_S_PLAY_SICE             = 106
--停止投色
cmd.SUB_S_STOP_SICE             = 107


--游戏状态
cmd.CMD_S_StatusFree ={
     --历史积分
	{t = "score", k = "lCollectScore", l = {cmd.GAME_PLAYER}}, --积分信息
	{t = "word", k = "wPlayerCount"}, --最大人数
}

--游戏状态
cmd.CMD_S_StatusScore = {
    --下注信息
	{t = "byte", k = "cbPlayStatus", l = {cmd.GAME_PLAYER}},     --用户状态
	{t = "byte", k = "cbDynamicJoin"},                           --动态加入
	{t = "score", k = "lTableScore", l = {cmd.GAME_PLAYER}},     --下注数目
	{t = "word", k = "wBankerUser"},							 --庄家用户

	--历史积分
	{t = "score", k = "lCollectScore", l = {cmd.GAME_PLAYER}},    --积分信息
	{t = "word", k = "wPlayerCount"}, --最大人数
}

--游戏状
cmd.CMD_S_StatusPlay = {
	--状态信息
	{t = "byte", k = "cbPlayStatus", l = {cmd.GAME_PLAYER}},     --用户状态
	{t = "byte", k = "cbDynamicJoin"},							 --动态加入
	{t = "score", k = "lTableScore", l = {cmd.GAME_PLAYER}},     --下注数目
	{t = "word", k = "wBankerUser"},                             --庄家用户
	{t = "word", k = "wStartUser"},                              --开始玩家
	{t = "word", k = "SicePoint", l = {2}},                      --骰子点数 

	--扑克信息
	{t = "byte", k = "cbHandCardData", l = {cmd.MAX_COUNT}}, --桌面扑克
	{t = "byte", k = "cbOpenCard", l = {cmd.GAME_PLAYER}},   --组牌状态(0,1)

	--历史积分
	{t = "score", k = "lCollectScore", l = {cmd.GAME_PLAYER}},   --积分信息
	{t = "word", k = "wPlayerCount"}, --最大人数
}

--游戏开始
cmd.CMD_S_GameStart = {
    --下注信息
	{t = "word", k = "wBankerUser"},          --庄家用户
}

--用户下注
cmd.CMD_S_AddScore = {
	{t = "word", k = "wAddScoreUser"},        --加注用户
	{t = "score", k = "lAddScoreCount"},      --加注数目
}

--游戏结束
cmd.CMD_S_GameEnd = {
	{t = "score", k = "lGameTax", l = {cmd.GAME_PLAYER}},       --游戏税收
	{t = "score", k = "lGameScore", l = {cmd.GAME_PLAYER}},     --游戏得分
	{t = "byte", k = "cbOpenCard", l = {cmd.MAX_COUNT, cmd.MAX_COUNT, cmd.MAX_COUNT, cmd.MAX_COUNT}},  --扑克数据
}

--发牌数据包
cmd.CMD_S_SendCard = {
	{t = "byte", k = "cbCardData", l = {cmd.MAX_COUNT}},       --用户扑克
}

--用户退出
cmd.CMD_S_PlayerExit = {
	{t = "word", k = "wChairID"},                             --退出用户
}

--组牌完成
cmd.CMD_S_Open_Card = {
	{t = "word", k = "wChairID"},                             --摊牌用户
}

--用户打色
cmd.CMD_S_PlaySice = {
	{t = "word", k = "wStartUser"},                          --开始玩家
	{t = "word", k = "wSicePoint", l = {2}},                  --骰子点数
}

--**********************    客户端命令结构        ************--
--用户加注
cmd.SUB_C_ADD_SCORE				= 1
--用户摊牌
cmd.SUB_C_OPEN_CARD             = 2
--用户投色
cmd.SUB_C_PLAY_SICE             = 3
--用户停止投色
cmd.SUB_C_STOP_SICE             = 4



--用户加注
cmd.CMD_C_AddScore = {
	{t = "score", k = "lScore"},                                --加注数目
}

--用户摊牌
cmd.CMD_C_OpenCard = {
	{t = "byte", k = "cbFrontCard", l = {2}},                   --头道扑克
	{t = "byte", k = "cbBackCard", l = {2}},                    --尾道扑克
}

--用户打色
cmd.CMD_C_PlaySice = {
    {t = "word", k = "wStartUser"},                             --开始玩家
	{t = "word", k = "wSicePoint", l = {2}},                    --骰子点数
}

--********************       定时器标识         ***************--
--无效定时器
cmd.IDI_NULLITY					= 200
--开始定时器
cmd.IDI_START_GAME				= 201
--叫庄定时器
cmd.IDI_CALL_BANKER				= 202
--加注定时器
cmd.IDI_TIME_USER_ADD_SCORE		= 1
--摊牌定时器
cmd.IDI_TIME_OPEN_CARD			= 2
--摊牌定时器
cmd.IDI_TIME_NULLITY			= 3
--延时定时器
cmd.IDI_DELAY_TIME				= 4

--*******************        时间标识         *****************--
--叫庄定时器
cmd.TIME_USER_CALL_BANKER		= 30
--开始定时器
cmd.TIME_USER_START_GAME		= 30
--加注定时器
cmd.TIME_USER_ADD_SCORE			= 30
--摊牌定时器
cmd.TIME_USER_OPEN_CARD			= 30

return cmd