functor
import
   OS 
   System
   Input
   Main
   PlayerManager
    Projet2019util
   %% Add here the name of the functor of a player  
export
   createState: CreateState
   play: Play
   doAction:DoAction
   getWinner:GetWinner
   countMapBoxes:CountMapBoxes
   portGameState: AccesToGameState
   broadcastMessage: BroadcastMessage
   isGameOver:IsGameOver
   updateBombGamestate: UpdateBombGamestate
   playOnce:PlayOnce
   treatStream:TreatStream
define
  /* Show
   Show2
   Show3
    Show4
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
   CheckTimesUp
   DecreaseTimeBombing
    % Simultaneous
    CreateBombSimultaneos
   */
    AccesToGameState
    TreatStream
     
     

  % Debug
   LocalDebug= false
   LocalDebug2= false
   LocalDebug3= false
   LocalDebug4= false
   LocalDebug5= false
   LocalDebug6 = false 
   LocalDebug7 = true

 %%% TOOLS %%%%
  proc {Show Msg}
    if (LocalDebug == true) then {System.show Msg}
    else skip end 
  end

   proc {Show2 Msg}
    if (LocalDebug2 == true) then {System.show Msg}
    else skip end 
  end

    proc {Show3 Msg}
    if (LocalDebug3 == true) then {System.show Msg}
    else skip end 
  end

   proc {Show4 Msg}
    if (LocalDebug4 == true) then {System.show Msg}
    else skip end 
  end

  proc {Show5 Msg}
    if (LocalDebug5 == true) then {System.show Msg}
    else skip end 
  end

  proc {Show6 Msg}
    if (LocalDebug6 == true) then {System.show Msg}
    else skip end 
  end

  proc {Show7 Msg}
    if (LocalDebug7 == true) then {System.show Msg}
    else skip end 
  end
 %%% END TOOLS %%%%

 %%%%%%%%%%%%%%  INIT GAMESTATE %%%%%%%%%%%%%%%%%%%%%

 fun{CreateState}
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
                                            isOnBoard:true
                                            localID: Count
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
        if (Input.isTurnByTurn) then 
            bomb(extendedBomber:ExtendedBomber bombpos:Position timingBomb:Input.timingBomb)
        else 
            bomb(extendedBomber:ExtendedBomber bombpos:Position timingBomb:{Alarm Input.timingBombMin+({OS.rand} mod (Input.timingBombMax-Input.timingBombMin))} )
        end 
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
                {BroadcastMessage GameState.playersList [deadPlayer(ID)]}
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
                            % respaw in the next round Atttention change
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
        of nil then rec(bomersHited:BombersHited  bombersNothited:BombersNOThited)
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


     fun{DecreaseTimeBombing TimingBomb}
        if (Input.isTurnByTurn) then 
           TimingBomb -1 
        else 
           TimingBomb
        end
     end 

     fun{CheckTimesUp TimingBomb}
        NewtimingBomb 
     in
        if (Input.isTurnByTurn) then
          if (TimingBomb == 0 ) then true 
          else  false  end           
        else % is Simultaneous 
          if (TimingBomb == unit) then true 
          else  false  end      
        end
     end 



    fun{UpdateBomb GameState}
        fun {Helper_UpdateBomb GameState ListBomb UpdatedListBomb}
            case ListBomb
            of nil then rec(lb:UpdatedListBomb gs:GameState)
            [] Bomb|T then  NewtimingBomb in 
                NewtimingBomb = {DecreaseTimeBombing Bomb.timingBomb}
                {Show5 'Bomb Timing' # NewtimingBomb # Bomb.extendedBomber}  
                if {CheckTimesUp NewtimingBomb}  then  % explode                   
                    {Helper_UpdateBomb {KaBoom Bomb GameState} T {List.subtract UpdatedListBomb Bomb}} 
                else 
                    if (Input.isTurnByTurn) then   
                        %  continue to check bombTimer in turn by turn 
                        {Helper_UpdateBomb GameState T {Append UpdatedListBomb [{Adjoin Bomb bomb(timingBomb:NewtimingBomb)}]}}
                    else 
                        %  continue to check bombTimer in simultaneous
                        {Helper_UpdateBomb GameState T UpdatedListBomb}
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

/*
     fun{UpdateBomb GameState}
        fun {Helper_UpdateBomb GameState ListBomb UpdatedListBomb}
            case ListBomb
            of nil then rec(lb:UpdatedListBomb gs:GameState)
            [] Bomb|T then  NewtimingBomb in 
                NewtimingBomb = Bomb.timingBomb -1 
                {Show5 'Bomb Timing ' # NewtimingBomb # Bomb.bombpos}  
                if NewtimingBomb == 0 then  % explode 
                     {Show5 'Go to explose ************\n'#GameState.bombList}                      
                    {Helper_UpdateBomb {KaBoom Bomb GameState} T {List.subtract UpdatedListBomb Bomb}} 
                else  
                    %  continue to check bombTimer
                    NewtimingBomb= (Bomb.timingBomb-1)
                    {Helper_UpdateBomb GameState T {Append UpdatedListBomb [{Adjoin Bomb bomb(timingBomb:NewtimingBomb)}]}}
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

 */
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Update Gamestate
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % updateBomberManState(ExtendedBomber UpdateExtenderBombers)
    fun{UpdateBomberManState GameState ExtendedBomber UpdateExtenderBomber}    
      {Adjoin GameState gameState(playersList:{Replace GameState.playersList ExtendedBomber UpdateExtenderBomber})}
    end 

      % hidePoint(Pos)
    fun{HidePoint GameState Pos}
      {Adjoin GameState gameState(unveiledPoint: {List.subtract GameState.unveiledPoint Pos})}
    end 

     % hideBonus(Pos)
    fun{HideBonus GameState Pos}
      {Adjoin GameState gameState(unveiledBonus: {List.subtract GameState.unveiledBonus Pos})}
    end 

    %bombPlanted(Pos ExtendedBomber)
    fun{BombPlanted GameState Pos ExtendedBomber}
     {Show5 'Adding bomb to list ' # Pos }
     {Adjoin GameState gameState(bombList: {Append GameState.bombList [{CreateBomb Pos ExtendedBomber}]})}
    end 
    
    %  movePlayer(ID Pos)
   fun {MovePlayer GameState Pos ExtendedBomber}
      UpdateExtenderBomber  
   in 
      UpdateExtenderBomber = {Adjoin ExtendedBomber extendedBomber(currentPosition:Pos)}
      {Adjoin GameState gameState(playersList:{Replace GameState.playersList ExtendedBomber UpdateExtenderBomber})}
   end 

   % add(Type Option ?Result)
    fun{Add GameState Type Option Result ExtendedBomber Pos} 
      {Send ExtendedBomber.mybomberPort add(Type Option Result)}
      {Wait Result}
      case Type 
      of point then UpdateExtenderBomber in 
         UpdateExtenderBomber = {Adjoin ExtendedBomber extendedBomber(score:Result)}
          
         {Adjoin GameState gameState(unveiledPoint: {List.subtract GameState.unveiledPoint Pos}
                                     playersList:{Replace GameState.playersList ExtendedBomber UpdateExtenderBomber})}
      [] bomb then 
         {Adjoin GameState gameState(unveiledBonus: {List.subtract GameState.unveiledBonus Pos})}
      end      
   end 

  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %  End Update Gamestate 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      fun{DoAction GameState ExtendedBomber}
        ID Action in                         
        {Send ExtendedBomber.mybomberPort doaction(ID Action)}
        {Wait ID} 
        {Wait Action}
        {PlayOnce GameState ExtendedBomber Action ID}

      end 

      fun{PlayOnce GameState ExtendedBomber Action ID}
            State Broadcast Wind in
            %%PlayOnce 
            case Action 
            of move(Pos) then  
            {Show 'Action is ' #Action}
                % check if in this position there are a point or a bonus 
                if {List.member Pos GameState.unveiledPoint} then 
                
                    %there are a point in this position
                    Result in
                    State = [movePlayer(ID Pos ExtendedBomber) hidePoint(Pos) add(point 1 Result ExtendedBomber Pos)]
                    Broadcast= [movePlayer(ID Pos)]
                    Wind = [movePlayer(ID Pos) hidePoint(Pos) scoreUpdate(ID Result)]

                    rec(1:State 2:Broadcast 3:Wind)                 
                elseif {List.member Pos GameState.unveiledBonus} then
                  
                    %there are a bonus in this position 
                    Bonus Result in
                    Bonus ={CreateBonus GameState}
                        if (Bonus == GameState.pointBonus) then 
                        % add BonusPoint
                            State = [movePlayer(ID Pos ExtendedBomber) hideBonus(Pos) add(point Bonus Result ExtendedBomber Pos)]
                            Broadcast= [movePlayer(ID Pos)]
                            Wind = [movePlayer(ID Pos) hideBonus(Pos) scoreUpdate(ID Result)]

                            rec(1:State 2:Broadcast 3:Wind)
                        else % add BonusBomb                                          
                            State = [movePlayer(ID Pos ExtendedBomber) hideBonus(Pos) add(bomb 1 Result ExtendedBomber Pos)] 
                            Broadcast= [movePlayer(ID Pos)]
                            Wind = [movePlayer(ID Pos) hideBonus(Pos)]

                            rec(1:State 2:Broadcast 3:Wind)
                        end 
                else %there are a nothing in this position                  
                   State = [movePlayer(ID Pos ExtendedBomber)]
                   Broadcast= [movePlayer(ID Pos)]
                   Wind = [movePlayer(ID Pos)]                     
                   rec(1:State 2:Broadcast 3:Wind)                  
                end
            [] bomb(Pos) then                      
                     State = [bombPlanted(Pos ExtendedBomber)]
                     Broadcast= [bombPlanted(Pos)]
                     Wind = [spawnBomb(Pos)]
                     {Show5 '1 BOMB PLANTED: message to process'# State# Pos}
                     rec(1:State 2:Broadcast 3:Wind)               
            %[] add extention exemple shield 
            else nil                                           
            end
    end 

    


    fun{RefreshList GameState}
       {Adjoin GameState gameState(messageList:nil actionToShow:nil)}
    end 

     proc{BroadcastMessage PlayerList MessageInfoList}
       for Player in PlayerList do 
         for Message in MessageInfoList do 
           {Send Player.mybomberPort info(Message)}
         end 
       end 
     end


     proc{BroadcastDoAction PlayerList MessageInfoList}
       for Player in PlayerList do 
         for Message in MessageInfoList do 
            {Show 'Message '# Message}
            case Message                    
            of bombPlanted(Pos ExtendedBomber) then
                {Send Player.mybomberPort info(bombPlanted(Pos))}
            [] movePlayer(ID Pos ExtendedBomber) then 
                   {Send Player.mybomberPort info(movePlayer(ID Pos))}
             else   
                {Send Player.mybomberPort info(Message)}
            end
         end 
       end 
     end
     
    fun{FuncEvaluation GameState}
        % TODO
        0
    end


    fun{UpdateBombGamestate GameState}    
       % move and explose bomb 
       {UpdateBomb {RefreshList GameState}}

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
        WinnerList NewGameState Message 
    in 
       {Show 'Got Winner 1'}
        WinnerList = {GetWinner GameState} 
         {Show7 ' &&&&&&&&&&&&&& **************Got Winner &&&&&&&&&&&*************'}
        {Show7 ' &&&&&&&&&&&&&& **************Got Winner 2'# WinnerList # {List.is WinnerList}}
         {Show7 ' &&&&&&&&&&&&&& **************Got Winner &&&&&&&&&&&*************'}
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

    fun {IsGameOver  GameState}
        if (GameState.playersList == nil ) 
            then   % every body dead --> end
            {Show '2'} 
            true       
        elseif ({Length GameState.playersList } == 1) 
            then  % one winner --> end show winner        
            {Show '3 actionToShow' # GameState.actionToShow}                
           true
        elseif GameState.nbRemainingBoxes == 0 
            then % there are not more boxes left --> end show winner(s)            
            {Show2 '4'}
            true
        elseif({FuncEvaluation GameState} == 1) 
            then  % one winner --> end show winner  
            {Show '5'}
             true
        else 
            false
        end 
    end 
   

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Play One turn
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  fun {Play GameState ExtendedBomber}
    UpdateGameState NewGameState BroadC Tbegin Tend
  in   
        if {CheckIfAlive ExtendedBomber} then  
           {Show5 'Bomb List to update Last and first  here il faut decrementer '#GameState.bombList}       
          % this player is alive
            UpdateGameState = {UpdateBombGamestate GameState}
            {Show '1'}
            {Show (UpdateGameState.actionToShow == nil)}            
            if {IsGameOver GameState} then 
               {GotAWinner GameState} 
            else  MessageRec in % Continue to play               
                {Show '6'}
                {Show5 'List Bomb After UPDATE %%%%%%%%%%%%%%%%%/n'# UpdateGameState.bombList}
                {Show5 '**********Actions to show after update bomb **********/n'# UpdateGameState.actionToShow}
                MessageRec = {DoAction UpdateGameState ExtendedBomber}
                if (MessageRec \= nil ) then ToBroadcast LastGamestate in 
                    {Show '7.0' # MessageRec}
                    {Show5 ' 2 Message to execute ' # MessageRec.1}
                    {Show '7.0' # MessageRec.2}
                    {Show '7.0' # MessageRec.3}
                     {Show5 ' 2.1Message to show ' # MessageRec.3}
                    {TreatStream MessageRec.1 UpdateGameState NewGameState}
                     {Show5 '5 After proceced list bomb: ' #NewGameState.bombList}
                    % need to put show info dans le gamestate
                    {Show '7'}
                    %Broadcast Bomb and Do action 
                    
                    ToBroadcast =  {Append NewGameState.messageList MessageRec.2}
                    {Show 'ToBroadcats ' # ToBroadcast}
                    {BroadcastMessage NewGameState.playersList  ToBroadcast}
                    {Show '8'}
                    
                    LastGamestate= {Adjoin NewGameState gameState(actionToShow:{Append NewGameState.actionToShow MessageRec.3}
                                                    messageList: ToBroadcast)} 
                    {Show5 '**********Actions to show to show in windows **********/n'# LastGamestate.actionToShow}
                    LastGamestate 
                else 
                    UpdateGameState
                end
            end
        else % this palyer is Dead 
            GameState
        end 
   end

 % Return true if bomber is in this List of extender Bombers 
  fun{FindBomber PlayerList Bomberman}
     case PlayerList 
     of nil then false
     [] CurrentBomber|T then 
        {Show7 'PlayerList'# PlayerList}
        {Show7 'PlayerList'# CurrentBomber}
        if CurrentBomber.localID == Bomberman.localID then true 
         else 
         {FindBomber T Bomberman}
         end 
    end 
end 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Simultaneous Port Acces 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
in
    fun{AccesToGameState}
       GameStateBasic GameState Stream Port FinalGamestate 
   in
      {NewPort Stream Port}
      GameStateBasic = {CreateState} 
      GameState = {Adjoin GameStateBasic gameState(decision:true secondDecision:true isChanging:0)}
      thread {TreatStream Stream GameState FinalGamestate} end
      Port
   end 

   proc{TreatStream Stream GameState FinalGamestate}
    %{System.show Stream.1}
    case Stream
    of nil then FinalGamestate= GameState
    [] Message|Stail then
           case Message
        of play(NewGameState ExtendedBomber) then 
                {Show2 'PLAY THIS GAMESTATE IS BOUND '#GameState.actionToShow}
                NewGameState= {Play GameState ExtendedBomber}
                 {Show2 'play(NewGameState ExtendedBomber)' # NewGameState.actionToShow}
                {TreatStream Stail NewGameState FinalGamestate}

        [] decision(DecisionResult) then NewGameState in
                if GameState.decision == true then 
                    NewGameState= {Adjoin GameState gameState(decision:false)}
                    DecisionResult = true 
                    {TreatStream Stail NewGameState FinalGamestate}
                else 
                    DecisionResult = false 
                    {Show6 'decision(DecisionResult)'# DecisionResult}
                    {TreatStream Stail GameState FinalGamestate} 
                end
        [] freeGameState() then  NewGameState in
                NewGameState= {Adjoin GameState gameState(decision:true)}
                 {Show6 'updatingDecision(Val)'}
                {TreatStream Stail NewGameState FinalGamestate}
        [] askChange(Res) then 
	                 Res=GameState.isChanging
	                {TreatStream Stail GameState FinalGamestate}
        [] changing(Res) then NewGameState in
	             NewGameState={Adjoin GameState gameState(isChanging:Res)}
	             {TreatStream Stail NewGameState FinalGamestate}

        [] getSecondDecision(SecondDecision) then NewGameState in 
                 if GameState.secondDecision == true then 
                    NewGameState= {Adjoin GameState gameState(secondDecision:false)}
                    SecondDecision = true 
                    {TreatStream Stail NewGameState FinalGamestate}
                else 
                    SecondDecision = false 
                    {Show6 'second get decision(DecisionResult)'# SecondDecision}
                    {TreatStream Stail NewGameState FinalGamestate} 
                end               
            
        []freeSecondDecision() then NewGameState in
                NewGameState= {Adjoin GameState gameState(secondDecision:true)}
                {Show6 'freeSecondDecision()'}
                {TreatStream Stail NewGameState FinalGamestate}        

        [] getGameState(ResultGameState) then 
                ResultGameState= GameState
                {Show2 'THIS GAMESTATE IS BOUND '#GameState}
                {Show2 'get Gamestate()' #ResultGameState}
                {TreatStream Stail GameState FinalGamestate}

        [] updateGameState(NewGameState) then 
                {Show2 'update NewGamestate'}
                {TreatStream Stail NewGameState FinalGamestate}
        [] updateBombGamestate(GamestateUpToDate) then 
                 GamestateUpToDate= {UpdateBombGamestate GameState}
                 {TreatStream Stail GamestateUpToDate FinalGamestate}
                %Update info in State 
        [] hidePoint(Pos) then NewGameState in
                NewGameState = {HidePoint GameState Pos}
                {TreatStream Stail NewGameState FinalGamestate}
                
        [] bombPlanted(Pos ExtendedBomber) then NewGameState in 
                NewGameState = {BombPlanted GameState Pos ExtendedBomber}
                {Show ' 3 in treat stream Bomb List is '# NewGameState.bombList}
                {TreatStream Stail NewGameState FinalGamestate}

         [] hideBonus(Pos) then NewGameState in
                NewGameState = {HideBonus GameState Pos}
                {TreatStream Stail NewGameState FinalGamestate}

         [] movePlayer(ID Pos ExtendedBomber) then NewGameState in 
                NewGameState= {MovePlayer GameState Pos ExtendedBomber}
                {TreatStream Stail NewGameState FinalGamestate} 

        [] doaction(ExtendedBomber Action)then
                Action = {DoAction GameState ExtendedBomber}
                {TreatStream Stail GameState FinalGamestate}

        [] add(Type Option Result ExtendedBomber Pos) then NewGameState in 
                NewGameState = {Add GameState Type Option Result ExtendedBomber Pos} 
                {TreatStream Stail NewGameState FinalGamestate}            
        
        [] isGameOver(IsEnded) then 
                IsEnded= {IsGameOver GameState} 
                {TreatStream Stail GameState FinalGamestate} 

          [] getBomberEtat(AmIDead Bomberman) then 
                AmIDead = {FindBomber GameState.deadPlayersList Bomberman}
                {TreatStream Stail GameState FinalGamestate} 
                
          [] broadcast(ToBroadcast) then 
                {BroadcastMessage GameState.playersList ToBroadcast}
                {TreatStream Stail GameState FinalGamestate} 
                %Nex to review 
          [] executeAction(ActionList NewGameState) then 
                    {Show6 ' ********** executeAction(ActionList NewGameState)************'}
                    {TreatStream ActionList GameState NewGameState}
                    {TreatStream Stail NewGameState FinalGamestate}
        [] testMessage(Coucou)then
                Coucou='Coucou'
                {TreatStream Stail GameState FinalGamestate}
        [] getWinner(LastGAmestate) then 
                LastGAmestate = {GotAWinner GameState} 
                {TreatStream Stail LastGAmestate FinalGamestate} % close port  ? nil
        [] clean() then  NewGameState in
              NewGameState = {RefreshList GameState} 
             {TreatStream Stail NewGameState FinalGamestate}
        else
	        {System.show 'unsupported message'#Message}
	        {TreatStream Stail GameState FinalGamestate}
         end
      end
   end

  /*
  proc{ExecuteActions Stream GameState FinalGamestate}
    %{System.show Stream.1}
    case Stream
    of nil then FinalGamestate= GameState
    [] Message|Stail then
           case Message
            of movePlayer(ID Pos) then 
            [] hideBonus(Pos) then 
            [] hidePoint(Pos) then 
            [] add(Type Option Result) then % add(point Bonus Result ExtendedBomber Pos) = 
            [] bombPlanted(Pos) then 
           end
    end        
 end 



 fun{GetMessagesToBroadcast Message} 
    case Messages
    of nil then nil
    [] CurrentMessage|Stail then
           case CurrentMessage
            of spawnPlayer(ID Pos) % Player <bomber> ID has spawn in <position> Pos
              then  CurrentMessage|{Broadcast Stail} 
            [] movePlayer(ID Pos) % Player <bomber> ID has move to <position> Pos
                then  CurrentMessage|{Broadcast Stail} 
            [] deadPlayer(ID) % Player <bomber> ID has died
                then  CurrentMessage|{Broadcast Stail} 
            [] bombPlanted(Pos) % Bomb has been planted at <position> Pos
                then  CurrentMessage|{Broadcast Stail} 
            [] bombExploded(Pos) % Bomb has exploded at <position> Pos
                then  CurrentMessage|{Broadcast Stail} 
            [] boxRemoved(Pos) % Tile at <position> Pos who previously had a box on it is now a floor
                then  CurrentMessage|{Broadcast Stail} 
             else {GetMessagesToBroadcast Stail}   
           end
    end        
 end


  proc{ShowInWindows PortWindows MessageList}
    case MessageList
    of nil then skip
    [] CurrentMessage|Stail then
        case CurrentMessage
        of buildWindow % Create and launch the window (no player on it).
            then {Send PortWindow CurrentMessage} 
            {ShowInWindows PortWindows Stail}
        [] initPlayer(ID) % Initialize the <bomber> ID (doesn’t place the bomberman but just inform the GUI of it’s existence, allow to create the score place initialised to 0 and the lives counter initialised to Input.nbLives). For a given ID, this should only be used once.
            then {Send PortWindow CurrentMessage} 
            {ShowInWindows PortWindows Stail}
        [] spawnPlayer(ID Pos) % Spawn the <bomber> ID at <position> Pos. The bomberman should be displayed on the board when sending this message.
            then {Send PortWindow CurrentMessage} 
            {ShowInWindows PortWindows Stail}
        [] movePlayer(ID Pos) % Move the <bomber> ID at new position <position> Pos.
            then {Send PortWindow CurrentMessage} 
            {ShowInWindows PortWindows Stail}
        [] hidePlayer(ID) % Hide the <bomber> ID. This removes the bomberman from the screen.
            then {Send PortWindow CurrentMessage} 
            {ShowInWindows PortWindows Stail}
        [] spawnBonus(Pos) % Spawn the bonus at <position> Pos. The bonus should be displayed on the board when sending this message.
            then {Send PortWindow CurrentMessage} 
            {ShowInWindows PortWindows Stail}
        [] hideBonus(Pos) % Hide the bonus at <position> Pos. This removes the bonus from the screen.
            then {Send PortWindow CurrentMessage} 
            {ShowInWindows PortWindows Stail}
        [] spawnPoint(Pos) %
            then {Send PortWindow CurrentMessage} 
            {ShowInWindows PortWindows Stail}
        [] hidePoint(Pos) % Same as for bonuses, but for points.
            then {Send PortWindow CurrentMessage} 
            {ShowInWindows PortWindows Stail}
        [] spawnBox(Pos) %
            then {Send PortWindow CurrentMessage} 
            {ShowInWindows PortWindows Stail}
        [] spawnBomb(Pos) %
            then {Send PortWindow CurrentMessage} 
            {ShowInWindows PortWindows Stail}
        [] hideBox(Pos) % Same as for bonuses, but for boxes. For the initialisation, an additionnal parameter IsBonus is added. It should be put to true if the box is put over a bonus, false if the box is put over a point.
            then {Send PortWindow CurrentMessage} 
            {ShowInWindows PortWindows Stail}
        [] lifeUpdate(ID Life) % Change the value of the counter for the number of lives left for <bomber> ID to the new number of <life> Life (put the new value Life as number of lives left for the bomberman).
            then {Send PortWindow CurrentMessage} 
            {ShowInWindows PortWindows Stail}
        [] scoreUpdate(ID Score) % Change the value of the counter for the score for <bomber> ID to the new number of <score> Score (put the new value Score as score for the bomberman).
             then {Send PortWindow CurrentMessage} 
            {ShowInWindows PortWindows Stail}
        [] displayWinner(ID) % Inform the end of the game, giving the <bomber> ID of the highest score bomberman.
            then {Send PortWindow CurrentMessage} 
            {ShowInWindows PortWindows Stail}
         else 
            {ShowInWindows PortWindows Stail}
        end
    end        
 end

 */
   
end % End Module


               