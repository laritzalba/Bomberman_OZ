# ----------------------------
# group nb 118
# noma1 : 68171400 Laritza Cabrera Alba
# noma2 : 78531500 Magali Legast
# ----------------------------

all :compile Input.ozf run

compile : compilePlayers GameControler.ozf PlayerManager.ozf GUI.ozf Main.ozf
	@ozc -c *.oz

compilePlayers:
	@ozc -c Player000basic.oz

GameControler.ozf : 
	@ozc -c GameControler.oz
gameCB : 
	@ozc -c GameControlerBomber.oz
gameM :
	@ozc -c Main.oz 
PlayerManager.ozf :
	@ozc -c PlayerManager.oz
GUI.ozf :
	@ozc -c GUI.oz
Main.ozf :
	@ozc -c Main.oz
Input.ozf :
	@ozc -c Input.oz
Player000basic.ozf :
	@ozc -c Player000basic.oz
Player000simultaneous.ozf :
	@ozc -c Player000simultaneous.oz
smart :
	@ozc -c Player000extension.oz
Player000survivor.ozf:
	@ozc -c Player000survivor.oz
Player000extension.ozf:
	@ozc -c Player000extension.oz

run :
	@ozengine Main.ozf

clean :
	@rm -rf GUI.ozf Input.ozf Main.ozf PlayerManager.ozf GameControler.ozf Player000basic.ozf Player000simultaneous.ozf Player000survivor.ozf Player000extension.ozf Player000extension.ozf GameControlerBomber.ozf
