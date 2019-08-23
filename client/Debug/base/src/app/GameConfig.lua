-- Name: GameConfig
-- Func: 游戏配置
-- Author: Johny


--------------------屏幕设置----------------------------
--画布
G_WIDTH_GLVIEW  = 750
G_HEIGHT_GLVIEW = 1334
--模拟器屏幕
G_WIDTH_SCREEN  = 640
G_HEIGHT_SCREEN = 960
-----------------------------------出包前确认设置------------------------------------------
--@调试模式设置
-- 0: debug  1: inner  2: real
ENUM_GAMEMODE = {debug = 0, inner = 1, release = 2}
GAME_MODE = ENUM_GAMEMODE.debug


--@测试账号密码
G_ACCOUNT  =  "aacc123"
G_PWD      =  "abcd.1234"

--游戏名
G_GAME_NAME  = "明星97"
G_SHARE_CONTENT = "9个7天天有（游），水果多如米。游米游戏就是有米，快来收米！"
--游戏KindID
G_GAME_KINDID = 100


--@获取版本信息链接
-- URL_VERSION_GET = "http://192.168.1.9:8010" --@内网
URL_VERSION_GET = "http://47.96.252.57:80" --@login_ip 外网

--@http请求链接地址
G_URL_HTTP        = URL_VERSION_GET

--@LoginUrl
G_URL_LOGINSERVER  = "47.96.252.57"     --外网
-- G_URL_LOGINSERVER  = "192.168.1.9"       --内网
-- G_URL_LOGINSERVER = "192.168.1.57"    --老严
-- G_URL_LOGINSERVER = "192.168.1.86"    --小陈


--@登录服务器端口
G_PORT_LOGINSERVER = 8600

--@好友服务器端口
G_PORT_FRIEND  = 8630

--apk文件名
G_APK_DEBUG_REMOTE  =  "LuaMBClient_LY-debug.apk"
G_APK_REMOTE        =  "LuaMBClient_LY.apk"
G_APK_LOCAL         =  "ry_client.apk"


-------------------------平台配置--------------------------------------
--微信配置定义
G_CONFIG_WECHAT = 
{
	AppID 								= "wx96b0a55e4aaae2b8", --@wechat_appid_wx
	AppSecret 							= "c927795589feee065095a92acf95265c", --@wechat_secret_wx
	-- 商户id
	PartnerID 							= " ", --@wechat_partnerid_wx
	-- 支付密钥					        
	PayKey 								= " ", --@wechat_paykey_wx
	URL 								= G_URL_HTTP,
}

--支付宝配置
G_CONFIG_AliPay = 
{
	-- 合作者身份id
	PartnerID							= " ", --@alipay_partnerid_zfb
	-- 收款支付宝账号						
	SellerID							= " ", --@alipay_sellerid_zfb
	-- rsa密钥
	RsaKey								= " ", --@alipay_rsa_zfb
	NotifyURL							= G_URL_HTTP .. "/Pay/ZFB/notify_url.aspx",
	-- ios支付宝Schemes
	AliSchemes							= "JLZLAliPay", --@alipay_schemes_zfb
}



---------------------------------about cheat right-------------------
--作弊权限码
local _CHEAT_USER_RIGHT     = 536870912
local _CHEAT_MASTER_RIGHT   = 17907712

local _CAN_CHEAT            = false
function G_CHECKCHEAT_RIGHT(dwUserRight, dwMasterRight)
	cclog("G_CHECKCHEAT_RIGHT===>dwUserRight: " .. dwUserRight .. "=dwMasterRight: " .. dwMasterRight)
	_CAN_CHEAT = _CHEAT_USER_RIGHT == dwUserRight and _CHEAT_MASTER_RIGHT == dwMasterRight
end

function G_CAN_CHEAT()
	return _CAN_CHEAT
end
---------------------------------about cheat right-------------------