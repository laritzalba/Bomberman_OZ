functor
import
   OS 
   System
   Input
   Main
   %% Add here the name of the functor of a player  
export
   gameState: GameState
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

in
 %%% TOOLS %%%%
  proc {Show Msg}
	{System.show Msg}
  end
 %%% END TOOLS %%%%

  fun{CreateState }
     gameState(
         bomberList: nil 
         deadBomberList: nil 
         boxPoint:Input.boxPoint
         nbBoxPoint:{Length Input.boxPoint}
        
         boxBonus:Input.boxBonus
         nbBoxBonus:{Length Input.boxBonus}
        
         nbRemainingBox:Input.nbRemainingBox
         
         bombList:nil
         messageList: nil
         map: Input.map
         )
  
  end

   fun{CreateBomb Position BomberId}
     bomb(bombpos:Position count:Input.timingBomb bomberId:BomberId)
   end


   fun{CreateBonusExtension}
     if ({OS.rand} mod 2) == 0 then bomb else 10 end
     %% add shield and life
   end 

    fun{CreateBonus}
      if ({OS.rand} mod 2) == 0 then bomb else 10 end
   end 

   fun{CheckHitBomber GameSate}
   % TODO
      GameSate
   end

   fun{UpdateBoxesBonus GameSate NewBoxList PosBoxRemoved}
   % TODO UpdateMap
      NewNbBoxBonus NewNbRemainingBox NewMessage 
   in
     NewNbBoxBonus= {Length NewBoxList}
     NewNbRemainingBox = GameSate.nbRemainingBox-1 
     NewMessage = {Append GameSate.messageList [boxRemoved(PosBoxRemoved)]}
     {Adjoin GameSate gameState(boxBonus:NewBoxList 
                                 nbBoxBonus:NewNbBoxBonus
                                 nbRemainingBox: NewNbRemainingBox
                                 messageList: NewMessage
                                  )}
   end

   fun{UpdateBoxesPoint GameSate NewBoxList PosBoxRemoved}
     % TODO UpdateMap
      NewNbBoxPoint NewNbRemainingBox NewMessage 
   in
     NewNbBoxPoint= {Length NewBoxList}
     NewNbRemainingBox = GameSate.nbRemainingBox-1 
     NewMessage = {Append GameSate.messageList [boxRemoved(PosBoxRemoved)]}
     {Adjoin GameSate gameState(boxPoint:NewBoxList 
                                 nbBoxPoint:NewNbBoxPoint
                                 nbRemainingBox: NewNbRemainingBox
                                 messageList: NewMessage
                                  )}
    end

   fun {KaBoom Bomb GameSate}
    
    % no update bomblist here
      NewGamestate NewBoxPoint NewBoxBonus
    in 
      {Send Main.porWindow spawnFire(Bomb.bombpos)}
      NewBoxPoint= {List.substract GameSate.boxPoint Bomb.bombpos}
      NewBoxBonus= {List.substract GameSate.boxBonus Bomb.bombpos}
      if ({Length NewBoxPoint} < GameSate.nbBoxPoint) then
       % there is a box point to explose
       % TODO:  fire propagation 
       local Result in
        {Send Main.porWindow hideBox(Bomb.bombpos)}
        {Send Bomb.bomberId add(point 1 Result)}
        {Wait Result}
        {Send Main.porWindow scoreUpdate(Bomb.bomberId Result)}
        {UpdateBoxesPoint GameSate NewBoxPoint Bomb.bombpos}
        end 
      elseif ({Length NewBoxBonus} < GameSate.nbBoxBonus) then 
       % there is a box bonus to explose  
       % TODO:  fire propagation 
        local Result Bonus in        
        {Send Main.porWindow hideBox(Bomb.bombpos)}
        Bonus= {CreateBonus}
        {Send Bomb.bomberId add(Bonus 1 Result)}
        {Wait Result}
        {UpdateBoxesBonus GameSate NewBoxBonus Bomb.bombpos}
        end 
      else % there are no box to explose
      {CheckHitBomber GameSate}
      end 
   end

 fun {UpdateBomb GameState ListBomb}
      case ListBomb
       of nil then rec(lb:ListBomb|nil gs:GameState)
       [] Bomb|T then 
          if (Bomb.timingBomb-1) == 0 then  % explode                       
             {UpdateBomb {KaBoom Bomb GameState} T} 
          else  
            local NewtimingBomb in % decrement this bomb timer and continue to check bombTimer
                NewtimingBomb= (Bomb.count-1)
                {Adjoin Bomb bomb(count:NewtimingBomb)}|{UpdateBomb GameState T}
            end 
          end
       end      
   end


   fun{UpdateGamestate GameSate}
        NewState Rec
    in 
        Rec= {UpdateBomb GameSate GameSate.bombList}
        NewState = {Adjoin GameSate gameState(bombList:Rec.lb)} 
       
   end

   fun{PlayOnce ActionToDo GameSate}
      GameSate
   end

      
   fun{Play GameSate ActionToDo}
      NewState 
    in 
      NewState = {UpdateGamestate GameSate}
      {PlayOnce ActionToDo GameSate} % return A newGamestate with the list de message to do bradcast
   end
  




end
