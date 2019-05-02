# ----------------------------
# group nb 108
# noma1 : 68171400 Laritza Cabrera Alba
# noma2 : 78531500 Magali Legast
# ----------------------------

# TODO complete the header with your group number, your noma's and full names

# TODO write your makefile here
all :compile run
test : compile test1

compile :
	@ozc -c *.oz
gameC : 
	@ozc -c GameControler.oz
gameM : 
	@ozc -c Main.oz
gameI : 
	@ozc -c Input.oz
basic :
	@ozc -c Player000basic.oz
simultaneous :
	@ozc -c Player000simultaneous.oz
survivor:
	@ozc -c Player000survivor.oz
run :
	@ozengine Main.ozf

clean :
	@rm -rf GUI.ozf Input.ozf Main.ozf PlayerManager.ozf GameControler.ozf Player000basic.ozf Player000simultaneous.ozf Player000survivor.ozf
