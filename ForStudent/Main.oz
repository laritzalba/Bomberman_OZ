functor
import
   System
   OS  
   GUI
   Input
   PlayerManager
  
define
  Show
  PortWindow
  PortBombers
  
  %Init
  NewBombers
  RandomPosition
  Init_Show_Bombers
  
  %Turn by turn
  CheckIfAlive
  PlayOnce
  PalyAndSkipDeadBombers
  LoopTurnByTurn

in
  %%% TOOLS %%%%
  proc {Show Msg}
		{System.show Msg}
	end
 %%% END TOOLS %%%%

%%%%%%%%%%%%%%%%%%%%%%% Init Helper Functions %%%%%%%%%%%%%%%%%%%%%%%

   fun {NewBombers Count BombersList}
      if Input.nbBombers < Count then BombersList
      else
         local ThisPlayer in
            ThisPlayer = {PlayerManager.playerGenerator {Nth Input.bombers Count} 
                              bomber(id:Count 
                                       color:{Nth Input.colorsBombers Count} 
                                       name:{Nth Input.namesBombers Count})
                           }
            {NewBombers Count+1 ThisPlayer|BombersList}
         end
      end
   end


  fun {RandomPosition}
    local X Y in
         X= ({OS.rand} mod (Input.nbColumn-2))
         Y= ({OS.rand} mod (Input.nbRow-2))
         if (X =<1)  then 
            if (Y=<1) then pt(x:X+2 y:Y+2)
            else pt(x:X+2 y:Y) end
         elseif Y=<1 then pt(x:X y:Y+2)
         else 
         pt(x:X y:Y)  
         end
     end 
     % TO DO 
     % Verify if this position is not a wall or box or other 
  end


   proc {Init_Show_Bombers PortBombers}
	   case PortBombers
      of nil then skip 
	   [] H|T then ID Position in
             % Init 
            {Send H assignSpawn({RandomPosition})}
            {Send H spawn(ID Position)}
            {Wait ID}
            {Wait Position}
             % Show 
            {Send PortWindow initPlayer(ID)}
            {Send PortWindow spawnPlayer(ID Position)}
            {Init_Show_Bombers T}
	   end
	end

   %%%%%%%%%%%%%%%%%%%%%%% Turn by Turn Helper Functions %%%%%%%%%%%%%%%%%%%%%%%

   fun{CheckIfAlive PortBombers}
    ID State in
     {Send PortBombers getState(ID State)}
     {Wait ID} {Wait State}
     case State 
       of off then false
       else true 
     end  
   end


   proc{PlayOnce Bomber}
      local ID Action Pos in
         {Send Bomber doaction(ID Action)}
         {Wait ID} {Wait Action}
         case Action 
          of move(Pos) then
             {Wait Pos}
             {Send PortWindow movePlayer(ID Pos)}
          [] bomb(Pos) then
             {Send PortWindow spawnBomb(Pos)}
         end
      end
   end


   fun{PalyAndSkipDeadBombers PortBombers}
     {Delay 400}
    case PortBombers
     of nil then PortBombers
     [] H|T then 
         if ({CheckIfAlive H}) then 
            {PlayOnce H}
            H|{PalyAndSkipDeadBombers T}
         else  
            {PalyAndSkipDeadBombers T}
         end
      end
   end


    proc{LoopTurnByTurn PortBombers}
      local Bombers_Alive Alive in
         Bombers_Alive = {PalyAndSkipDeadBombers PortBombers}
         Alive = {Length Bombers_Alive}
         if (Alive == 0) then skip % every body dead
         elseif (Alive ==1) then skip % one winer
         else 
          {LoopTurnByTurn Bombers_Alive}
         end
      end
   end
 

 

   

 %%%%%%%%%%%%%%%%%%%%%%% Main %%%%%%%%%%%%%%%%%%%%%%%
 PortWindow = {GUI.portWindow}
 {Send PortWindow buildWindow}
 
 PortBombers = {NewBombers 1 nil}

 {Init_Show_Bombers PortBombers}

 {LoopTurnByTurn PortBombers}





end

