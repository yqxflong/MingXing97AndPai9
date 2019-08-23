-- Name: GameLogic
-- Func: 游戏逻辑
-- Author: Johny


local GameLogic = GameLogic or {}

function GameLogic.randTagIdx()
	return math.random(1, 9)
end

function GameLogic.randTagIdx_5()
	return {GameLogic.randTagIdx(), GameLogic.randTagIdx(), GameLogic.randTagIdx(), GameLogic.randTagIdx(), GameLogic.randTagIdx()}
end


return GameLogic