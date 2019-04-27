functor
import
   OS 
   System
   Input
   Main
   PlayerManager
   %% Add here the name of the functor of a player  
export
   gameState: GameState
   createState: CreateState
   play: Play
   doAction:DoAction
   getWinner:GetWinner
   countMapBoxes:CountMapBoxes
define
   Show
   GameState
   UpdateGamestate
   CreateState
   InitBomb
   RandName
   RandomPositionNotSpawn
   DropNthOfList
   ShuffleListNumber
   RandomPosition
   KaBoom
   CreateBomb
   UpdateBomb
   Play
   PlayOneTurn
   CheckHitBomber
   CreateBonus
   CreateBonusExtension
   CreatePortBomberAndExtend
   TestFunc
   UpdateBoxe
   DoAction
   CheckIfAlive
   GetIteminMap
   UpdateInnerMap
   ReplaceValInList
   Replace
   RefreshList
   BroadcastMessage
   FuncEvaluation
   CreateListeToExplose
   ExploseListPoints
   HidePointInFire
   CheckDamage
   GetWinner
   CountBoxesInList
   CountMapBoxes
   CreatePortBomberAndExtend
   GetState
   GotAWinner
   AddWinnerMessage 
   Find

in
 %%% TOOLS %%%%
  proc {Show Msg}
    if (Input.printOK == true) then {System.show Msg}
    else skip end 
  end
 %%% END TOOLS %%%%

 %%%%%%%%%%%%%%  INIT GAMESTATE %%%%%%%%%%%%%%%%%%%%%

  fun{CreateState }
    ExtendedPortBombers  MapDescription
  in 
    ExtendedPortBombers= {CreatePortBomberAndExtend Input.bombers 1} 
    
    MapDescription= {CountMapBoxes Input.map 1 dscrpt(boxPointPosition:nil boxBonusPosition:nil floorSapwan:nil)}

     gameState(
         playersList: ExtendedPortBombers
         deadPlayersList: nil 
         boxPoint:MapDescription.boxPointPosition
         nbBoxPoint:{Length MapDescription.boxPointPosition}
        
         boxBonus:MapDescription.boxBonusPosition
         nbBoxBonus:{Length MapDescription.boxBonusPosition}
         map:Input.map
                
         unveiledPoint:nil
         unveiledBonus:nil
         nbRemainingBoxes: {Length MapDescription.boxPointPosition} + {Length MapDescription.boxBonusPosition}       

         bombList:nil
         messageList: nil
         actionToShow:nil
         map: Input.map
         portWindow:_
         pointBox:1
         pointBonus:10
         endGame: false
         winnerList:nil
         wfloorSapwan:MapDescription.floorSapwan
         )
  
  end
  
   fun {CreatePortBomberAndExtend BombersList Count}
      case BombersList 
        of nil then nil 
        [] H|T then 
          local MyBomber ExtendedBomber in 
            MyBomber = {PlayerManager.playerGenerator {Nth Input.bombers Count} 
                              bomber(id:Count 
                                     color:{Nth Input.colorsBombers Count} 
                                     name:{RandName Count})
                           }            
            ExtendedBomber = extendedBomber(mybomberPort:MyBomber 
                                            currentPosition:_ 
                                            score:0
                                            )
            ExtendedBomber|{CreatePortBomberAndExtend T Count+1}
          end
      end
   end
   
 fun{RandName Count}
   'bomberman'#Count
 end 

   fun {CountBoxesInList List Row Column BoxPointPosition BoxBonusPosition FloorSpwan}
      case List 
       of nil then dscrpt(boxPointPosition:BoxPointPosition boxBonusPosition:BoxBonusPosition floorSapwan:FloorSpwan)
       [] H|T then 
          if (H == 2)     then {CountBoxesInList T Row Column+1 {Append BoxPointPosition [pt(x:Column y:Row)]} BoxBonusPosition FloorSpwan}
          elseif (H == 3) then {CountBoxesInList T Row Column+1 BoxPointPosition {Append BoxBonusPosition [pt(x:Column y:Row)]} FloorSpwan}
          elseif (H == 4) then {CountBoxesInList T Row Column+1 BoxPointPosition  BoxBonusPosition {Append FloorSpwan [pt(x:Column y:Row)]}} 
          else {CountBoxesInList T Row Column+1 BoxPointPosition BoxBonusPosition FloorSpwan}
          end 
      end  
   end

   fun {CountMapBoxes Map Row Dscrpt} 
     case Map
       of nil then Dscrpt
       [] H|T then {CountMapBoxes T Row+1 {CountBoxesInList H Row 1 Dscrpt.boxPointPosition Dscrpt.boxBonusPosition Dscrpt.floorSapwan}}
     end
   end


    fun{ReplaceValInList List Val N Count}
      case List 
      of nil then nil 
      [] H|T then
         if(Count==N) then Val|T
         else
           H|{ReplaceValInList T Val N Count+1}
         end
      end
   end

    fun{Find L Item}
        case L
        of nil then false
        []H|T then
            if (H== Item ) then true
            else {Find T Item}
            end
        end
    end

   % Replace A Bomber in PlayerList 
   fun{Replace List ItemToFind ItemToReplace}
        case List 
        of nil then nil
        []H|T then 
            if (H.mybomberPort == ItemToFind.mybomberPort) then ItemToReplace|T 
            else  H|{Replace T ItemToFind ItemToReplace}
            end
        end
    end

   fun{UpdateInnerMap GameState Item Position}
      NewMap
    in
      NewMap = {ReplaceValInList GameState.map 
               {ReplaceValInList {Nth GameState.map Position.y} Item Position.x 1} Position.y 1} 
    {Adjoin GameState gameState(map:NewMap)}
   end 

   fun{CreateBomb Position ExtendedBomber}
     bomb(extendedBomber:ExtendedBomber bombpos:Position timingBomb:Input.timingBomb)
   end
   

   %%%%%%%%%%%%%% END INIT %%%%%%%%%%%%%%%%%%%%%


   fun{CreateBonusExtension}
     if ({OS.rand} mod 2) == 0 then bomb else 10 end
     %% add shield and life
   end 

   fun{CreateBonus GameState}
      if ({OS.rand} mod 2) == 0 then bomb else GameState.pointBonus end
   end 


  fun{CheckIfAlive ExtendedBomber}
    ID State in
     {Send ExtendedBomber.mybomberPort getState(ID State)}
     {Wait ID} {Wait State}
     case State 
       of off then false
       else true 
     end  
   end 


   fun{CheckDamage GameState ListHitedBombers BombersNOThited PointInFire}

        fun{LoopToCheckDamage ListHitedBombers MessageList WindowsList Dead Alive}
            case ListHitedBombers
            of nil then rec( dead:Dead alive:Alive messageList:MessageList windowsList:WindowsList)
            [] BomberHited|T then
                ID Result ID2 Pos Wind in
                {Send BomberHited.mybomberPort gotHit(ID Result)}
                {Wait ID}
                {Wait Result}
                Wind = {Append WindowsList [hidePlayer(ID)]}
                case Result 
                of death(NewLife) then
                    if (NewLife==0) then %
                    % BomberHited is dead 
                        {LoopToCheckDamage T 
                            {Append MessageList [deadPlayer(ID)]}
                            {Append WindowsList [hidePlayer(ID) lifeUpdate(ID NewLife)]}
                            {Append Dead [BomberHited]}
                            Alive
                        }
                    else
                    %Bomber Hited has remaining lives
                        {Send BomberHited.mybomberPort spawn(ID2 Pos)}
                        {Wait ID2}
                        {Wait Pos}
                        {LoopToCheckDamage T 
                            {Append MessageList [spawnPlayer(ID2 Pos)]}
                            {Append WindowsList [hidePlayer(ID) lifeUpdate(ID2 NewLife) spawnPlayer(ID2 Pos)]}
                            Dead
                            {Append Alive [BomberHited]}
                        }
                    end
                else 
                    % To revoir
                    {LoopToCheckDamage T MessageList Wind Dead Alive}  
                end            
            end 
        end     
    Rec in 
        Rec= {LoopToCheckDamage ListHitedBombers nil [spawnFire(PointInFire)] nil nil}
        {Adjoin GameState gameState(
            actionToShow: {Append GameState.actionToShow Rec.windowsList}
            messageList: {Append GameState.messageList Rec.messageList}
            playersList: {Append BombersNOThited Rec.alive}
            deadPlayersList:{Append GameState.deadPlayersList Rec.dead}
        )}
    end

    fun{CheckHitBomber PlayersList PointInFire BombersHited BombersNOThited}
        case PlayersList 
        of nil then rec(bomersHited:BombersHited  bombersNothited:BombersNOThited ) 
        [] Bomber|T then 
             if (Bomber.currentPosition == PointInFire) then 
                {CheckHitBomber T PointInFire {Append BombersHited [Bomber]} BombersNOThited}  
            else 
                {CheckHitBomber T PointInFire BombersHited {Append BombersNOThited [Bomber]}}
            end
        end
    end 


  
 % TO DO ATTENTION
  fun{CreateListeToExplose BombPos GameState}
      fun{CheckLoop X Y Xsup Ysup N}
            {Show 'Create List Explose 1'}
             XFin YFin in
            if(Xsup<0) then XFin=X-1 else XFin=(X)+(Xsup) end
            if(Ysup<0) then YFin=Y-1 else YFin=(Y)+(Ysup) end
            {Show 'Create List Explose 2'}
            if (XFin =< 0) then nil
            elseif(XFin>Input.nbColumn) then nil
            elseif(YFin=<0) then nil
            elseif(YFin>Input.nbRow) then nil
            elseif(N=<0) then nil
            else
                {Show 'Create List Explose 3'}
                Point in 
                Point = pt(x:X+Xsup y:Y+Ysup)
                {Show 'Bomb Pos'#Point}
                if {Find GameState.boxPoint Point} 
                    then 
                     {Show 'Create List Explose 4 Floor with box point ' # GameState.boxPoint}
                    pt(x:XFin y:YFin)|nil % is a box with points 2
                elseif {Find GameState.boxBonus Point}  
                    then 
                     {Show 'Create List Explose 5 Floor with spawn ' # GameState.boxBonus}
                    pt(x:XFin y:YFin)|nil %is a box with bonus 3
                elseif {Find GameState.wfloorSapwan Point}
                    then 
                     {Show 'Create List Explose 6' # GameState.wfloorSapwan}
                    pt(x:XFin y:YFin)|{CheckLoop XFin YFin Xsup Ysup N-1} %% is a spawn position 4 
                else Item in
                    Item= {Nth {Nth GameState.map Y+Ysup} X+Xsup} 
                     {Show 'Create List Explose 7 (possible here are 1 and 0) Item found in map is: ' # Item}
                    case Item
                        of 1 then nil %% is a wall 1
                        else  pt(x:XFin y:YFin)|{CheckLoop XFin YFin Xsup Ysup N-1} %% is a flooor tile 0
                    end
                end 
            end
      end
   N PointsInFire in
   N= Input.fire
       PointsInFire= {Append 
		   {Append 
			    {Append 
		           {Append {CheckLoop BombPos.x BombPos.y 0 1 N} {CheckLoop BombPos.x BombPos.y 0 ~1 N}}
				 {CheckLoop BombPos.x BombPos.y 1 0 N}}
			{CheckLoop BombPos.x BombPos.y ~1 0 N}} 
		[BombPos]}
        {Show 'Point in fire '#PointsInFire}
        PointsInFire
   end

  
fun{ExploseListPoints GameState ListPointToExplose Bomb}
    case ListPointToExplose
    of nil then GameState
    [] PointInFire|T then 
        NewBoxPointList NewBoxBonusList NewGameState in
        {Show ' ExploseListPoints: Box Point List' #GameState.boxPoint #{List.is GameState.boxPoint}}
        NewBoxPointList= {List.subtract GameState.boxPoint PointInFire}
         {Show 'Explose List Point 2'#NewBoxPointList}
        NewBoxBonusList= {List.subtract GameState.boxBonus PointInFire}
         {Show 'Explose List Point 3' # NewBoxBonusList}
        if ({Length NewBoxPointList} < GameState.nbBoxPoint) then
        % there is a box point to explose
            %Update Gamestate           
            NewGameState = {Adjoin GameState 
            gameState( actionToShow:{Append GameState.actionToShow [spawnFire(PointInFire) hideBox(PointInFire) spawnPoint(PointInFire)]}
                       messageList:{Append GameState.messageList [ boxRemoved(PointInFire)]}
                       boxPoint:NewBoxPointList 
                       nbBoxPoint:{Length NewBoxPointList}
                       unveiledPoint: {Append GameState.unveiledPoint [PointInFire]}
                       nbRemainingBoxes: GameState.nbRemainingBoxes -1
                     )}
            {ExploseListPoints NewGameState T Bomb}            
        elseif ({Length NewBoxBonusList} < GameState.nbBoxBonus) then 
        % there is a box bonus to explose  
            %Update Gamestate           
            NewGameState = {Adjoin GameState 
              gameState(
                    actionToShow:{Append GameState.actionToShow [spawnFire(PointInFire) hideBox(PointInFire) spawnBonus(PointInFire)]}
                    messageList:{Append GameState.messageList [boxRemoved(PointInFire)]}
                    boxBonus:NewBoxBonusList 
                    nbBoxBonus:{Length NewBoxBonusList}
                    unveiledBonus: {Append GameState.unveiledBonus [PointInFire]} 
                    nbRemainingBoxes: GameState.nbRemainingBoxes -1                            
            )}
            {ExploseListPoints NewGameState T Bomb}   
        else ListHitedBombers BombersNOThited Rec in
            Rec= {CheckHitBomber GameState.playersList PointInFire nil nil}
            BombersNOThited = Rec.bombersNothited
            ListHitedBombers = Rec.bomersHited            
            if (ListHitedBombers \= nil) then 
              % bomber got hit 
               NewGameState = {CheckDamage GameState ListHitedBombers BombersNOThited PointInFire} 
               {ExploseListPoints NewGameState T Bomb}           
            else  % there is nothing in this tile --> continue to check next point in fire
               NewGameState = {Adjoin GameState gameState(actionToShow:{Append GameState.actionToShow [spawnFire(PointInFire)]})}
              {ExploseListPoints NewGameState T Bomb} 
            end  
        end           
    end
 end        

    fun {HidePointInFire GameState ListPointToHire}
    fun{AddMessage List}
        case List 
        of nil then nil 
        [] Pos|T then
            hideFire(Pos)|{AddMessage T}
        end
    end
    ListMessage 
    in
    ListMessage= {AddMessage ListPointToHire}
    {Adjoin GameState gameState(actionToShow:{Append GameState.actionToShow ListMessage})}
    end



    fun{KaBoom Bomb GameState}    
      % no update bomblist here
      NewGamestate1 NewGameState2 NewGameState3 ListPointToExplose Result
    in
      ListPointToExplose = {CreateListeToExplose Bomb.bombpos GameState}      
      NewGamestate1= {Adjoin GameState gameState(actionToShow:{Append GameState.actionToShow [hideBomb(Bomb.bombpos)]})}
      NewGameState2= {ExploseListPoints NewGamestate1 ListPointToExplose Bomb}
      {Send Bomb.extendedBomber.mybomberPort add(bomb 1 Result)}
      {Wait Result}
      %{Delay 700} % ???
      {HidePointInFire NewGameState2 ListPointToExplose}
    end


    fun{UpdateBomb GameState}
        fun {Helper_UpdateBomb GameState ListBomb UpdatedListBomb}
            case ListBomb
            of nil then rec(lb:UpdatedListBomb gs:GameState)
            [] Bomb|T then 
                if (Bomb.timingBomb - 1) == 0 then  % explode                       
                    {Helper_UpdateBomb {KaBoom Bomb GameState} T {List.subtract UpdatedListBomb Bomb}} 
                else  
                    local NewtimingBomb in % decrement this bomb timer and continue to check bombTimer
                        NewtimingBomb= (Bomb.timingBomb-1)
                        {Helper_UpdateBomb GameState T {Append UpdatedListBomb [{Adjoin Bomb bomb(timingBomb:NewtimingBomb)}]}}
                    end 
                end
            end      
        end
    in % if there are not bombs I dont need to update state because nothing happend 
        if GameState.bombList == nil then GameState
        else Rec in 
            Rec= {Helper_UpdateBomb GameState GameState.bombList nil}
            {Adjoin Rec.gs gameState(bombList:Rec.lb)} 
        end       
    end
    
    fun{DoAction GameState ExtendedBomber}
        %{Delay 400}
            ID Action UpdateGameState in  
            %%PlayOnce               
            {Send ExtendedBomber.mybomberPort doaction(ID Action)}
            {Wait ID} 
            {Wait Action}
            case Action 
            of move(Pos) then  
                UpdateExtenderBombers in
                {Show '6.1'#Action}
                % check if in this position there are a point or a bonus 
                if {List.member Pos GameState.unveiledPoint} then 
                {Show '6.2 point in this pos '}
                    %there are a point in this position
                    Result in
                    {Send ExtendedBomber.mybomberPort add(point 1 Result)}
                    {Wait Result}
                    UpdateExtenderBombers = {Adjoin ExtendedBomber extendedBomber(currentPosition:Pos
                                                                                  score:Result  
                                                                                  )}
                    UpdateGameState= {Adjoin GameState gameState(
                                playersList: {Replace GameState.playersList ExtendedBomber UpdateExtenderBombers}
                                unveiledPoint: {List.subtract GameState.unveiledPoint Pos}
                                messageList: {Append GameState.messageList [movePlayer(ID Pos)]} 
                                actionToShow: {Append GameState.actionToShow [movePlayer(ID Pos) 
                                                                              hidePoint(Pos)
                                                                              scoreUpdate(ID Result)]}                            
                    )}
                    UpdateGameState
                elseif {List.member Pos GameState.unveiledBonus} then
                  {Show '6.3 bonus in this pos '}
                    %there are a bonus in this position 
                    Bonus Result in
                    Bonus ={CreateBonus GameState}
                        if (Bonus == GameState.pointBonus) then 
                        % add BonusPoint
                        {Send ExtendedBomber.mybomberPort add(point Bonus Result)}
                        {Wait Result}
                        UpdateExtenderBombers = {Adjoin ExtendedBomber extendedBomber(currentPosition:Pos
                                                                                  score:Result  
                                                                                  )}
                        UpdateGameState= {Adjoin GameState gameState(
                                playersList: {Replace GameState.playersList ExtendedBomber UpdateExtenderBombers}
                                unveiledPoint: {List.subtract GameState.unveiledBonus Pos}
                                messageList: {Append GameState.messageList [movePlayer(ID Pos)]} 
                                actionToShow: {Append GameState.actionToShow [movePlayer(ID Pos) 
                                                                        hidePoint(Pos)
                                                                        scoreUpdate(ID Result)]}
                        )} 
                        UpdateGameState
                        else % add BonusBomb
                        {Send ExtendedBomber.mybomberPort add(bomb 1 Result)}
                        {Wait Result}
                        %% to check if we need to ask for id again  
                        UpdateExtenderBombers = {Adjoin ExtendedBomber extendedBomber(currentPosition:Pos)}
                        UpdateGameState= {Adjoin GameState gameState(
                                    playersList:  {Replace GameState.playersList ExtendedBomber UpdateExtenderBombers}
                                    unveiledBonus: {List.subtract GameState.unveiledBonus Pos}
                                    messageList:  {Append GameState.messageList [movePlayer(ID Pos)]} 
                                    actionToShow: {Append GameState.actionToShow [movePlayer(ID Pos) 
                                                                            hideBonus(Pos)]}                                
                        )}
                        UpdateGameState
                        end 
                else %there are a nothing in this position
                  {Show '6.4 nothing in this pos '} 
                  UpdateExtenderBombers = {Adjoin ExtendedBomber extendedBomber(currentPosition:Pos)}
                  UpdateGameState= {Adjoin GameState gameState(
                            playersList:  {Replace GameState.playersList ExtendedBomber UpdateExtenderBombers}
                            messageList:  {Append GameState.messageList [movePlayer(ID Pos)]} 
                            actionToShow: {Append GameState.actionToShow [movePlayer(ID Pos)]}
                  )}
                  {Show '6.4.1 nothing in this pos '#UpdateGameState} 
                  UpdateGameState
                end
            [] bomb(Pos) then 
                    {Show '6.5 bom  '}                
                    UpdateGameState= {Adjoin GameState gameState(
                            messageList:  {Append GameState.messageList [bombPlanted(Pos)]} 
                            actionToShow: {Append GameState.actionToShow [spawnBomb(Pos)]}
                            bombList: {Append GameState.bombList [{CreateBomb Pos ExtendedBomber}]}
                    )}
                    UpdateGameState
            %[] add extention exemple shield                                           
            end
    end    

    fun{RefreshList GameState}
       {Adjoin GameState gameState(messageList:nil actionToShow:nil)}
    end 

     proc{BroadcastMessage PlayerList MessageInfoList }
       for Player in PlayerList do 
         for Message in MessageInfoList do 
           {Send Player.mybomberPort info(Message)}
         end 
       end 
     end

    fun{FuncEvaluation GameState}
        % TODO
        0
    end

   % to delete
    fun{UpdateGamestate GameState}
        NewGameState GameStateUpdateBomb
    in 
       % move and explose bomb 
       {UpdateBomb GameState}
       
       %Only move 
       %GameState
    end

    fun {AddWinnerMessage PlayerList}
        {Show {List.is PlayerList}}
        case PlayerList
        of nil then nil 
        [] Winner|T then
         ID in
         {Send Winner.mybomberPort getId(ID)}
         {Wait ID} 
         displayWinner(ID)|{AddWinnerMessage T}
        end
        /*
      ID
      in
         {Send PlayerList.1.mybomberPort getId(ID)}
         {Wait ID} 
         {Show displayWinner(ID)}
         [displayWinner(ID)]
         */
    end 

    fun {GetWinner GameState}
      fun{CheckScore PlayerList WinnerList MaxScore}
        case PlayerList 
        of nil then WinnerList 
        [] H|T then 
            CurrentScore in 
            CurrentScore = H.score 
            if (CurrentScore > MaxScore) then {CheckScore T [H] CurrentScore}
            elseif (CurrentScore == MaxScore) then {CheckScore T {Append WinnerList [H]} MaxScore}
            else {CheckScore T WinnerList MaxScore}
            end
        end  
      end
    PlayerList 
    in 
        PlayerList= {Append GameState.playersList GameState.deadPlayersList}
        {CheckScore  PlayerList.2 [PlayerList.1] PlayerList.1.score}       
    end

    fun{GotAWinner GameState}
        WinnerList 
    NewGameState Message in 

       {Show 'Got Winner 1'}
        WinnerList = {GetWinner GameState} 
        {Show 'Got Winner 2'# WinnerList # {List.is WinnerList}}
        Message= {AddWinnerMessage WinnerList}
        {Show 'winner message '#Message}
        NewGameState= {Adjoin GameState gameState(
                        endGame: true
                        winnerList:WinnerList
                        actionToShow: {Append GameState.actionToShow Message}    
        )}
        {Show 'final actionto Show'#NewGameState.actionToShow}
        NewGameState
    end 

    fun{GetState ExtendedBomber}
        ID State 
    in
        {Send ExtendedBomber.mybomberPort getState(ID State)}
        {Wait ID}
        {Wait State}
        State
    end

  %% Play One turn
  fun {Play GameState ExtendedBomber}
    UpdateGameState NewGameState BroadC
  in   
        if {CheckIfAlive ExtendedBomber} then         
          % this player is alive
            UpdateGameState = {UpdateGamestate {RefreshList GameState}}
            {Show '1'}
            {Show (UpdateGameState.actionToShow == nil)}
            
            if (UpdateGameState.playersList == nil ) 
                then   % every body dead --> end
                {Show '2'} 
                {GotAWinner UpdateGameState}      
            elseif ({Length UpdateGameState.playersList } == 1) 
                then  % one winner --> end show winner        
                {Show '3 actionToShow' # GameState.actionToShow}
                
                {GotAWinner UpdateGameState} 
            elseif UpdateGameState.nbRemainingBoxes == 0 
                then % there are not more boxes left --> end show winner(s)            
                {Show '4'}
                {GotAWinner UpdateGameState} 
            elseif ({FuncEvaluation UpdateGameState} == 1) 
                then  % one winner --> end show winner  
                {Show '5'}
                {GotAWinner UpdateGameState} 
            else  % Continue to play 
                {Show '6'}
                NewGameState = {DoAction UpdateGameState ExtendedBomber} 
                {Show '7'}
                {BroadcastMessage UpdateGameState.playersList NewGameState.messageList}
                {Show '8'}
                NewGameState
            end
        else % this palyer is Dead 
            GameState
        end 
   end

   
end % End Module

