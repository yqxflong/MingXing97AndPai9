-- Name: ClientUserItem
-- Func: 用户数据class
-- Author: Johny



local ClientUserItem = class("ClientUserItem")

function ClientUserItem:ctor()
	cclog("function ClientUserItem:ctor() ==> ")

	self.dwGameID		= 0
	self.dwUserID		= 0

	self.wFaceID 		= 0
	self.dwCustomID		= 0

	self.cbGender		= yl.GENDER_MANKIND
	self.cbMemberOrder	= 0

	self.wTableID		= yl.INVALID_TABLE
	self.wChairID		= yl.INVALID_CHAIR
	self.cbUserStatus 	= 0

	self.lScore 			= 0
	self.lIngot 			= 0
	self.dBeans 			= 0
	self.lGrade				= 0
	self.lInsure			= 0

	self.dwWinCount		= 0
	self.dwLostCount	= 0
	self.dwDrawCount	= 0
	self.dwFleeCount	= 0
	self.dwExperience	= 0

	self.szNickName = ""
end

function ClientUserItem:testlog()
	cclog("ClientUserItem*******************************************")
	cclog("dwGameID="..self.dwGameID)
	cclog("dwUserID="..self.dwUserID)

	cclog("wFaceID="..self.wFaceID)
	cclog("dwCustomID="..self.dwCustomID)

	cclog("cbGender="..self.cbGender)
	cclog("cbMemberOrder="..self.cbMemberOrder)

	cclog("wTableID="..self.wTableID)
	cclog("wChairID="..self.wChairID)
	cclog("cbUserStatus="..self.cbUserStatus)

	cclog("lScore="..self.lScore)
	cclog("lIngot="..self.lIngot)
	cclog("dBeans="..self.dBeans)

	cclog("dwWinCount="..self.dwWinCount)
	cclog("dwLostCount="..self.dwLostCount)
	cclog("dwDrawCount="..self.dwDrawCount)
	cclog("dwFleeCount="..self.dwFleeCount)
	cclog("dwExperience="..self.dwExperience)

	cclog("szNickName="..self.szNickName)
	cclog("*********************************************************")
end

return ClientUserItem