-- Name: GameQuickAPI
-- Func: 用于游戏内部的方法封装，快速调用
-- Author: Johny

local TAG = "meinv"
local logFile_handler = nil
local _ENABLE_DURING_MONITOR_ = false


-------------------------------------------Log--------------------------------------------
-- custom error report
function G_ErrorReport(msg)
    local errMsg = string.format("[LUA ERROR]: %s\n",tostring(msg))
    cclog(errMsg)
    cclog(debug.traceback())
    --for bugly
    if GAME_MODE ~= ENUM_GAMEMODE.debug then
       buglyReportLuaException(errMsg, debug.traceback())
    else
       doAssert(string.format("%s-%s",errMsg,debug.traceback()))
    end 
end

-- log file
function LogFile(_open)
    if GAME_MODE ~= ENUM_GAMEMODE.release then
      if _open then
         local _file = string.format("%sBeta_log.txt", cc.FileUtils:getInstance():getWritablePath()) 
         logFile_handler = assert(io.open(_file, "w"))
         logFile_handler:setvbuf("no")
      else
         logFile_handler:close()
      end
    end
end

-- cclog
cclog = function(...)
    if GAME_MODE ~= ENUM_GAMEMODE.release then
      local _string = string.format("%s-----%s-----%s\n",TAG, os.date("%X", time), ...)
      print(_string)
      logFile_handler:write(_string)
    end
end

-- debugLog,用于输出单项调试
debugLog = function(...)
    if GAME_MODE ~= ENUM_GAMEMODE.release then
      local _string = string.format("%s-----%s-----%s\n",TAG, os.date("%X", time), ...)
      print(_string)
      logFile_handler:write(_string)
    end
end


-- 用于封装带一个对象的方法
function handler(target, method)
    return function(...) return method(target, ...) end 
end

function iter(t)
  local index = 0
  return function()
         index = index + 1
         return t[i] end
end
---------------------------------------------------------------------------------------------------

--重置搜索路径
function GG_RemoveSearchPath(_searchPath)
    local oldPaths = cc.FileUtils:getInstance():getSearchPaths();
    local newPaths = {};
    for k,v in pairs(oldPaths) do
        if tostring(v) ~= tostring(_searchPath) then
            table.insert(newPaths, v);
        end
    end
    cc.FileUtils:getInstance():setSearchPaths(newPaths);
    cclog("GG_RemoveSearchPath==remove: " .. _searchPath .. "=afterRemove: " .. json.encode(newPaths))
end

--------------------------------------------------------------------------------------------
-- 获得屏幕大小
function GG_GetScreenSize()
    local director = cc.Director:getInstance()
    local glview = director:getOpenGLView()
    local _sz = glview:getFrameSize()
    cclog("GG_GetSceenSize == " .. _sz.width .. " == " .. _sz.height)
    return _sz
end

-- 获得画布大小
function GG_GetWinSize()
    local _sz = cc.Director:getInstance():getWinSize()
    cclog("GG_GetWinSize == " .. _sz.width .. " == " .. _sz.height)
    return _sz
end

local function setDesignResolution(r, framesize)
    local director = cc.Director:getInstance()
    local view = director:getOpenGLView()
    local scaleX, scaleY = framesize.width / r.width, framesize.height / r.height
    local width, height = framesize.width, framesize.height
    if r.autoscale == "FIXED_WIDTH" then
        width = framesize.width / scaleX
        height = framesize.height / scaleX
        view:setDesignResolutionSize(width, height, cc.ResolutionPolicy.FIXED_WIDTH)
    elseif r.autoscale == "FIXED_HEIGHT" then
        width = framesize.width / scaleY
        height = framesize.height / scaleY
        view:setDesignResolutionSize(width, height, cc.ResolutionPolicy.FIXED_HEIGHT)
    elseif r.autoscale == "EXACT_FIT" then
        width = framesize.width / scaleX
        height = framesize.height / scaleY
        view:setDesignResolutionSize(r.width, r.height, cc.ResolutionPolicy.EXACT_FIT)
    elseif r.autoscale == "NO_BORDER" then
        view:setDesignResolutionSize(r.width, r.height, cc.ResolutionPolicy.NO_BORDER)
    elseif r.autoscale == "SHOW_ALL" then
        view:setDesignResolutionSize(r.width, r.height, cc.ResolutionPolicy.SHOW_ALL)
    else
        printError(string.format("display - invalid r.autoscale \"%s\"", r.autoscale))
    end
end

--设置竖屏模式
function GG_setVerScreen()
    local config = {}
    config.width = G_WIDTH_GLVIEW
    config.height = G_HEIGHT_GLVIEW
    config.autoscale = "EXACT_FIT"
    setDesignResolution(config ,GG_GetScreenSize())
end

--还原屏幕
function GG_resetScreen()
    local config = {}
    config.width = G_HEIGHT_GLVIEW
    config.height = G_WIDTH_GLVIEW
    config.autoscale = "EXACT_FIT"
    setDesignResolution(config ,GG_GetScreenSize())
end
---------------------------------------------------------------------

-- 下一帧执行
function nextTick(func)
  local scheduler = cc.Director:getInstance():getScheduler()
  local schedulerHandler = nil

  local function doSomthing()
    func()
    scheduler:unscheduleScriptEntry(schedulerHandler)
  end

  schedulerHandler = scheduler:scheduleScriptFunc(doSomthing, 0, false)
end

-- 延迟几秒执行
function nextTick_frameCount(func, _second)
    local scheduler = cc.Director:getInstance():getScheduler()
    local schedulerHandler = nil

    local function doSomthing()
      func()
      scheduler:unscheduleScriptEntry(schedulerHandler)
    end

    schedulerHandler = scheduler:scheduleScriptFunc(doSomthing, _second, false)

    return schedulerHandler
end

-- 间隔几秒执行
function nextTick_eachSecond(func, _second)
    local scheduler = cc.Director:getInstance():getScheduler()

    local function doSomthing()
        func()
    end

    return scheduler:scheduleScriptFunc(doSomthing, _second, false)
end

-- 解注册计时器
function G_unSchedule(_scheduler)
    if not _scheduler then return end
    local scheduler = cc.Director:getInstance():getScheduler()
    scheduler:unscheduleScriptEntry(_scheduler)
end


-- 注册弹起
function registerWidgetReleaseUpEvent(widget, func)
  local function onReleaseUp(widget, eventType)
    if eventType == ccui.TouchEventType.ended then
      func(widget)
    end
  end
  widget:addTouchEventListener(onReleaseUp)
end

-- 注册按下
function registerWidgetPushDownEvent(widget, func)
  local function onPushDown(widget, eventType)
    if eventType == ccui.TouchEventType.began then
      func(widget)
    end
  end
  widget:addTouchEventListener(onPushDown)
end

-- 注册按下和弹起
function registerWidgetPushAndReleaseEvent(widget, func, _param)
    local function onTouch(widget, eventType)
      if eventType == ccui.TouchEventType.began then
        func(widget, 1, _param)
      elseif eventType == ccui.TouchEventType.ended then
        func(widget, 2, _param)
      elseif eventType == ccui.TouchEventType.moved then
        func(widget, 3, _param)
      elseif eventType == ccui.TouchEventType.canceled then
        func(widget, 4, _param)
      end
    end
    widget:addTouchEventListener(onTouch)
end

-- 快速设置元表
function newObject(o, class)
    class.__index = class
    return setmetatable(o, class)
end

-- 断言
function doAssert(text)
  if GAME_MODE ~= ENUM_GAMEMODE.debug then return end
  nativeMessageBox(text, "lua_src_error")
end

--断言
function LuaDoAssert(b,text)
    if not b then
      if not text then
        text = "default"
      end
      doAssert(text .. "-" .. debug.traceback())
    end
    return b
end
_G["assert"] = LuaDoAssert


-- 函数调用前，判断函数的持有者是否为空
function pCall(_holder, _func, ...)
    if _holder == nil then return end
    return _func(...)
end


-- 字段是否在table中
function isValueInTable(_value, _table)
   for k,v in pairs(_table) do
       if v == _value then
       return true end
   end

   return false
end

-- table判空条件
function table_is_empty(t)
    return _G.next( t ) == nil
end

-- 查看lua内存占用
function doLuaMemory()
  local count = collectgarbage("count")
  cclog("当前lua虚拟机占用内存为:", count)
end

-- 是否是需要合成的纹理文件
function isNeedCoporateTexFile(_file)
   return not string.find(_file, ".png") and not string.find(_file, ".jpg")
end

----------------------------------------------字符串处理--------------------------------------------
local character = 
{
  "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", 
  "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",  
  "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
  "!", "@", "$", "%", "^", "&", "*", "(", ")", "-", "+", "=", "/", "?", ",", ".", "<", ">", "[", "]", "{", "}", "|", "/",      
}

function isASCII(str)
  for k, v in pairs(character) do
    if str == v then
      return true
    end
  end
  return false
end

-- Split String
function extern_string_split_(szFullString, szSeparator)  
    local nFindStartIndex = 1  
    local nSplitIndex = 1  
    local nSplitArray = {}  
    while true do  
       local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)  
       if not nFindLastIndex then  
        nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))  
        break  
       end  
       nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)  
       nFindStartIndex = nFindLastIndex + string.len(szSeparator)  
       nSplitIndex = nSplitIndex + 1  
    end  
    return nSplitArray  
end 


function splitChineseString(srcString)
  local result = {}
  local strLen = string.len(srcString)

  local i = 1
  while i < strLen do
    local str = string.sub(srcString, i, i)
    if isASCII(str) then
      i = i + 1
    elseif str == "#" then
      local nextShape,len = string.find(srcString, "#", i+1)
      if len and len > 0 then
         local len_Color = nextShape - i
         str = string.sub(srcString,i,i+len_Color)
         i = nextShape + 1
      end
    else
      str = string.sub(srcString, i, i + 2)
      i = i + 3
    end
    table.insert(result, str)
  end
  local newResult = {}
  
  for i = 1, #result do
    local newStr = ""
    for j = 1, i do
      newStr = string.format("%s%s",newStr,result[j])
    end
    table.insert(newResult, newStr)
  end
  return newResult
end

function getChineseStringLength(srcString)
  local result = {}
  local strLen = string.len(srcString)

  local i = 1
  while i <= strLen do
    local str = string.sub(srcString, i, i)
    if isASCII(str) then
      i = i + 1
    else
      str = string.sub(srcString, i, i + 2)
      i = i + 3
    end
    table.insert(result, str)
  end
  return #result
end

-- 获取一段文字(包括汉字、英文、数字)所占字符个数
function getStringLength(srcString)
  local result = {}
  local strLen = string.len(srcString)

  local i = 1
  while i < strLen do
    local str = string.sub(srcString, i, i)
    if isASCII(str) then
      i = i + 1
    else
      str = string.sub(srcString, i, i + 2)
      i = i + 3
    end
    table.insert(result, str)
  end

  local newLength = 0
  for j = 1, #result do
    if isASCII(result[j]) then
      newLength = newLength + 2
    else
      newLength = newLength + 3
    end
  end
  return newLength
end

-------------------lua字符串替换---------------------
function G_stringReplace(str, srcString, destString)
   local _begin,_end = string.find(str, srcString)
   if not _begin then return str end
   local _str1 = string.sub(str, 0, _begin - 1)
   local ret = string.format("%s%s", _str1, destString)

   return ret
end
-------------------lua字符串替换---------------------

--------------------自动添加换行符-------------------
-- 纯英文自动添加换行符
function G_AddChangeLineForText(srcString, fontsize, limitwidth)
      fontsize = fontsize * 0.5

      local result = {}
      local strLen = string.len(srcString)

      local i = 1
      while i <= strLen do
        local str = string.sub(srcString, i, i)
        if isASCII(str) then
           i = i + 1
        else
           return srcString
        end
        table.insert(result, str)
      end
      
      local _curWidth = 0
      local _ret = ""
      for i = 1, #result do
         _ret = string.format("%s%s",_ret,result[i])
         _curWidth = _curWidth + fontsize
         if _curWidth + fontsize > limitwidth then
            _ret = string.format("%s%s",_ret,"\n")
            _curWidth = 0
         end
      end


      return _ret
end
--------------------自动添加换行符-------------------


----------------------------------------------时间转换--------------------------------------------------

-- 秒转时间
function secondToHour(seconds)
    local hour = math.floor(seconds / 3600)
    seconds = math.mod(seconds, 3600)
    local min = math.floor(seconds / 60)
    seconds = math.mod(seconds, 60)
    local sec = math.floor(seconds)
    cclog(hour, "时", min, "分", sec, "秒")
    return hour, min, sec
end

--
function timeFormat(seconds)
  local hour = math.floor(seconds / 3600)
  seconds = math.mod(seconds, 3600)
  local min = math.floor(seconds / 60)
  seconds = math.mod(seconds, 60)
  local sec = seconds
  return string.format("%02d:%02d:%02d",hour,min,sec)
end


---------------------------------------函数性能调试----------------------------------------
-- 计算一个function执行的时间
function caculateFuncDuring(_funcName, _func)
   local _time1 = os.clock()
   local _ret1,_ret2,_ret3 = _func()  
   local _time2 = os.clock()
   if _ENABLE_DURING_MONITOR_ then
      local _during = _time2 - _time1
      monitorFuncDuring(_funcName, _during)
   end

   return _ret1,_ret2,_ret3
end

-- 监视func执行时间，超过给警告
local _MONITOR_LIST_ = {}
function monitorFuncDuring(_funcName, _during)
    if not _MONITOR_LIST_[_funcName] then _MONITOR_LIST_[_funcName] = {0,0} end
    _MONITOR_LIST_[_funcName][1] = _MONITOR_LIST_[_funcName][1] + 1
    _MONITOR_LIST_[_funcName][2] = _MONITOR_LIST_[_funcName][2] + _during
    if _MONITOR_LIST_[_funcName][1] == 1 then
       local msg = string.format("[monitorFuncDuring]%s cost %.4fs, plz check it." , _funcName, _MONITOR_LIST_[_funcName][2])
       debugLog(msg)
       _MONITOR_LIST_[_funcName] = {0,0}
    end
end

--------------------位运算-----------------------------
-- 取第几位的值
-- _idx: 0 ~ n-1
function bitNum(_num, _idx)
   local bit = require "bit"
   return bit.rshift(_num, _idx)
end

-- 打开第几位的值
-- 使该位值为1，其余位不变
-- _idx: 0 ~ n-1
function bitOpenNumBit(_num, _idx)
   local bit = require "bit"
   local _mask = 1
   _mask = bit.lshift(_mask, _idx)
   return bit.bor(_num, _mask)
end

-- 关闭第几位的值
-- 使该位值为0，其余位不变
-- _idx: 0 ~ n-1
function bitCloseNumBit(_num, _idx)
   local bit = require "bit"
   local _mask = 1
   _mask = bit.bnot(bit.lshift(_mask, _idx))
   return bit.band(_num, _mask)
end
--------------------位运算---------------------------


------------------------spine------------------------------
function GG_createSpine(_file, _atlas, _scale)
    local fileUitls = cc.FileUtils:getInstance()
    if not _scale then _scale = 1 end
    if not fileUitls:isFileExist(_file) or not fileUitls:isFileExist(_atlas) then
       doAssert("[Error]Missing Spine: " .. _file .. ";" .. _atlas)
    end
    local _spine = sp.SkeletonAnimation:create(_file, _atlas, 1)
    _spine:setScale(_scale)
    return _spine
end
function GG_stopSpineAni(_spine)
   _spine:clearTracks()
   _spine:setToSetupPose()
end
  ------------------------spine------------------------------