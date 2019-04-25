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
   updateGamestate: UpdateGamestate
   doAction:DoAction
define
   Show
   GameState
   UpdateGamestate
   CreateState
   InitBomb
   KaBoom
   CreateBomb
   UpdateBomb
   Play
   PlayOnce
   UpdateBoxesPoint
   UpdateBoxesBonus
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
   RefreshList
   BroadcastMessage
   FuncEvaluation

in
 %%% TOOLS %%%%
  proc {Show Msg}
	{System.show Msg}
  end
 %%% END TOOLS %%%%

 %%%%%%%%%%%%%%  INIT GAMESTATE %%%%%%%%%%%%%%%%%%%%%

  fun{CreateState }
    ExtendedPortBombers 
  in 
    ExtendedPortBombers= {CreatePortBomberAndExtend Input.bombers 1} 
     gameState(
         playersList: ExtendedPortBombers
         deadPlayersList: nil 
         boxPoint:Input.mapDescription.boxPointPosition
         nbBoxPoint:{Length Input.mapDescription.boxPointPosition}
        
         boxBonus:Input.mapDescription.boxBonusPosition
         nbBoxBonus:{Length Input.mapDescription.boxBonusPosition}
         map:Input.map
         nbRemainingBox:Input.nbBoxes
         
         bombList:nil
         messageList: nil
         actionToShow:nil
         map: Input.map
         portWindow:_
         pointBox:1
         pointBonus:10
         winer: false
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
                                      name:{Nth Input.namesBombers Count})
                           }            
            ExtendedBomber = extendedBomber(mybomberPort:MyBomber 
                           score:0
                           currentPosition:_
                           life:Input.nbLives
                           )
            ExtendedBomber|{CreatePortBomberAndExtend T Count+1}
          end
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

   fun{UpdateInnerMap GameState Item Position}
    NewMap
    in
      NewMap = {ReplaceValInList GameState.map 
               {ReplaceValInList {Nth GameState.map Position.y} Item Position.x 1} Position.y 1} 
    {Adjoin GameState gameState(map:NewMap)}
   end 

   fun{CreateBomb Position BomberId}
     bomb(bombpos:Position count:Input.timingBomb bomberId:BomberId)
   end

   

   %%%%%%%%%%%%%% END INIT %%%%%%%%%%%%%%%%%%%%%


   fun{CreateBonusExtension}
     if ({OS.rand} mod 2) == 0 then bomb else 10 end
     %% add shield and life
   end 

    fun{CreateBonus}
      if ({OS.rand} mod 2) == 0 then bomb else 10 end
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

   fun{GetIteminMap Map Pos}
     {Nth {Nth Map Pos.y} Pos.x} 
   end

   fun{CheckHitBomber GameState}
   % TODO
      GameState
   end

   fun{UpdateBoxesBonus GameState NewBoxList PosBoxRemoved}
   % TODO UpdateMap
      NewNbBoxBonus NewNbRemainingBox NewMessage 
   in
     NewNbBoxBonus= {Length NewBoxList}
     NewNbRemainingBox = GameState.nbRemainingBox-1 
     NewMessage = {Append GameState.messageList [boxRemoved(PosBoxRemoved)]}
     {Adjoin GameState gameState(boxBonus:NewBoxList 
                                 nbBoxBonus:NewNbBoxBonus
                                 nbRemainingBox: NewNbRemainingBox
                                 messageList: NewMessage
                                  )}
   end

   fun{UpdateBoxesPoint GameState NewBoxList PosBoxRemoved}
     % TODO UpdateMap
      NewNbBoxPoint NewNbRemainingBox NewMessage 
   in
     NewNbBoxPoint= {Length NewBoxList}
     NewNbRemainingBox = GameState.nbRemainingBox-1 
     NewMessage = {Append GameState.messageList [boxRemoved(PosBoxRemoved)]}
     {Adjoin GameState gameState(boxPoint:NewBoxList 
                                 nbBoxPoint:NewNbBoxPoint
                                 nbRemainingBox: NewNbRemainingBox
                                 messageList: NewMessage
                                  )}
    end

   fun {KaBoom Bomb GameState}
    
    % no update bomblist here
      NewGamestate NewBoxPoint NewBoxBonus
    in 
      {Send Main.porWindow spawnFire(Bomb.bombpos)}
      NewBoxPoint= {List.substract GameState.boxPoint Bomb.bombpos}
      NewBoxBonus= {List.substract GameState.boxBonus Bomb.bombpos}
      if ({Length NewBoxPoint} < GameState.nbBoxPoint) then
       % there is a box point to explose
       % TODO:  fire propagation 
       local Result in
        {Send Main.porWindow hideBox(Bomb.bombpos)}
        {Send Bomb.bomberId add(point 1 Result)}
        {Wait Result}
        {Send Main.porWindow scoreUpdate(Bomb.bomberId Result)}
        {UpdateBoxesPoint GameState NewBoxPoint Bomb.bombpos}
        end 
      elseif ({Length NewBoxBonus} < GameState.nbBoxBonus) then 
       % there is a box bonus to explose  
       % TODO:  fire propagation 
        local Result Bonus in        
        {Send Main.porWindow hideBox(Bomb.bombpos)}
        Bonus= {CreateBonus}
        {Send Bomb.bomberId add(Bonus 1 Result)}
        {Wait Result}
        {UpdateBoxesBonus GameState NewBoxBonus Bomb.bombpos}
        end 
      else % there are no box to explose
      {CheckHitBomber GameState}
      end 
   end

    fun{UpdateBomb GameState}
        fun {Helper_UpdateBomb GameState ListBomb UpdatedListBomb}
            case ListBomb
            of nil then rec(lb:UpdatedListBomb gs:GameState)
            [] Bomb|T then 
                if (Bomb.timingBomb - 1) == 0 then  % explode                       
                    {Helper_UpdateBomb {KaBoom Bomb GameState} T {List.substract UpdatedListBomb Bomb}} 
                else  
                    local NewtimingBomb in % decrement this bomb timer and continue to check bombTimer
                        NewtimingBomb= (Bomb.count-1)
                        {Helper_UpdateBomb GameState T {Append UpdatedListBomb [{Adjoin Bomb bomb(count:NewtimingBomb)}]}}
                    end 
                end
            end      
        end
    in 
        % if there are not bombs I dont need to update state because nothing happend 
        if GameState.bombList == nil then GameState
        else Rec in 
            Rec= {Helper_UpdateBomb GameState GameState.bombList nil}
            {Adjoin Rec.gs gameState(bombList:Rec.lb)} 
        end       
    end 


   fun{DoAction GameState}
    fun{PlayOnce ExtendedBombers NewBombers LMessage LBomb LWindows}
        {Delay 400}
        {Show 'delay '}
        case ExtendedBombers
        of nil then rec(lbomber:NewBombers lmessage:LMessage lbomb:LBomb lwindows: LWindows) 
        [] Bomber|T then 
            local UpdateExtenderBombers ID Action in  
                {Show 'Play Once'}
                %%PlayOnce               
                {Send Bomber.mybomberPort doaction(ID Action)}
                {Wait ID} 
                {Wait Action}
                {Show 'have Id and action'}
                {Show Action}
                case Action 
                of move(Pos) then
                    {Show 'fisrt case '} 

                    %{Send GameState.portWindow movePlayer(ID Pos)}
                    {Show 'send to windows ok '} 
                    UpdateExtenderBombers = {Adjoin Bomber extendedBomber(currentPosition:Pos)} 
                    {Show 'Bomber Moving '}                   
                    {PlayOnce T {Append NewBombers [UpdateExtenderBombers]} {Append LMessage [movePlayer(ID Pos)]} LBomb {Append LWindows [movePlayer(ID Pos)]}}
                [] bomb(Pos) then
                    {Show 'second case '}  
                   % {Send GameState.portWindow spawnBomb(Pos)}
                    UpdateExtenderBombers = {Adjoin Bomber extendedBomber(explodeBombIn:Input.timingBomb currentBombPos:Pos)}
                     {Show 'Bomber put a bomb  '}                     
                    {PlayOnce T {Append NewBombers [UpdateExtenderBombers]} {Append LMessage [bombPlanted(Pos)]} {Append LBomb [{CreateBomb Pos ID}]} {Append LWindows [spawnBomb(Pos)]}}                    
                end             
            end
        end
    end
    RecReturn UpdateMessage UpdateListBomber UpdateBombL UpdateWindowsL in 
     if (GameState.playersList == nil) then GameState 
     else
         {Show 'Inside DoAction'}
         RecReturn = {PlayOnce GameState.playersList nil nil nil nil} 
         {Show RecReturn}  
         UpdateListBomber= RecReturn.lbomber
         UpdateMessage = {Append GameState.messageList RecReturn.lmessage}
         UpdateBombL = {Append GameState.bombList RecReturn.lbomb}
         UpdateWindowsL ={Append GameState.actionToShow RecReturn.lmessage}
         {Adjoin GameState gameState(playersList:UpdateListBomber messageList:UpdateMessage bombList:UpdateBombL actionToShow:UpdateWindowsL)}
     end 
   end

   
   fun {UpdateBoxe GameState PlayerList}
      case PlayerList 
      of nil then GameState
      [] Bomber|T then 
        ItemMap in
         ItemMap = {GetIteminMap GameState.Map Bomber.currentPosition}
        if (ItemMap== 5) then 
        % get point  
         {Adjoin Bomber extendedBomber(score:(Bomber.score+Bomber.score + GameState.pointBonus))}
         %To Continue 
         % get bonus 
         elseif(ItemMap ==  6) then GameState 
        end        
      end
   end

    fun{RefreshList GameState}
       {Adjoin GameState gameState(messageList:nil actionToShow:nil)}
    end 

     fun{BroadcastMessage GameState}
        % return nothing 
        % Bradcats message to all player 
            1
     end 

    fun{FuncEvaluation GameState}
        % TODO
        0
    end

   fun{UpdateGamestate GameState}
      NewGameState GameStateUpdateBomb GameStateUpdateBox
    in 
       %GameStateUpdateBox=  {UpdateBoxe GameState GameState.playersList}
       %GameStateUpdateBomb = {UpdateBomb GameStateUpdateBox}
       GameState
    end



  %% Play One turn
  fun {Play GameState}
    UpdateGameState NewGameState BroadC
  in   
        UpdateGameState = {UpdateGamestate {RefreshList GameState}}
        {Show '1'}
        {Show (UpdateGameState.actionToShow == nil)}
        
        if (UpdateGameState.playersList == nil ) 
            then   % every body dead --> end 
            {Show '2'} 
            UpdateGameState      
        elseif ({Length UpdateGameState.playersList } == 1) 
            then  % one winer --> end show winer        
            {Show '3'}
            UpdateGameState
        elseif UpdateGameState.nbRemainingBox == 0 
            then % there are not more boxes left --> end show winer(s)
            {Show '4'}
            UpdateGameState
        elseif ({FuncEvaluation UpdateGameState} == 1) 
            then  % one winer --> end show winer  
            {Show '5'}
            UpdateGameState
        else  % Continue to play 
            {Show '6'}
            NewGameState = {DoAction UpdateGameState}
            {Show '7'}
            BroadC={BroadcastMessage NewGameState}
            {Show '8'}
            NewGameState
        end
   end
  /* fun{Play GameState}
      NewGameState 
    in 
        NewGameState = {UpdateGamestate GameState}
        {Show 'NEXT DO ACTION'}
        {DoAction NewGameState} % return A newGamestate with the list de message to do bradcast
   end
   */
  




end
