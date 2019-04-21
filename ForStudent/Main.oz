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
  ExtendedPortBombers
  NbSpawPosition
  RandomListSpawPosition
  RandomPositionNotSpawn

  %Helper
   CheckPosition
   ShuffleListNumber
   DropNthOfList


  %Init
  CreatePortBomberAndExtend
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

   fun{CheckPosition Position TailToCheck}
    Row Column 
   in 
    Column= Position.x
    Row = {Nth Input.map Position.y}
     if ({Nth Row Column} == TailToCheck) then 
         true
      else
	      false
      end
   end



%%%%%%%%%%%%%%%%%%%%%%% Init Helper Functions %%%%%%%%%%%%%%%%%%%%%%%

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
                           nbBombs:Input.nbBombs 
                           explodeBombIn:Input.timingBomb
                           currentBombPos:_
                           currentPoints:_ )
            ExtendedBomber|{CreatePortBomberAndExtend T Count+1}
          end
      end
   end


  fun {RandomPositionNotSpawn}
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

  fun{DropNthOfList List N Count}
    case List 
      of nil then nil 
    []H|T then
         if (Count == N) then {DropNthOfList T N Count+1}
         else  
            H|{DropNthOfList T N Count+1}
         end 
    end 
   end

   fun{ShuffleListNumber List}
      case List
      of nil then nil 
      [] H|T then 
         local  Random Size Item in
            Size = {Length List}
            Random = ({OS.rand} mod Size) +1
            Item = {Nth List Random}
            Item|{ShuffleListNumber {DropNthOfList List Random 1}}
         end 
      end  
   end


  fun {RandomPosition Count}
   if Count > NbSpawPosition then RandomListSpawPosition.1
   else 
    {Nth RandomListSpawPosition Count}
    end 
  end


   proc {Init_Show_Bombers ExtendedBombers Count}
	   case ExtendedBombers
      of nil then skip 
	   [] H|T then ID Position in
             % Init   
            {Send H.mybomberPort assignSpawn({RandomPosition Count})}
            {Send H.mybomberPort spawn(ID Position)}
            {Wait ID}
            {Wait Position}
             % Show 
            {Send PortWindow initPlayer(ID)}
            {Send PortWindow spawnPlayer(ID Position)}
            {Init_Show_Bombers T Count+1}
	   end
	end



   %%%%%%%%%%%%%%%%%%%%%%% Turn by Turn Helper Functions %%%%%%%%%%%%%%%%%%%%%%%

   fun{CheckIfAlive ExtendedBomber}
    ID State in
     {Send ExtendedBomber.mybomberPort getState(ID State)}
     {Wait ID} {Wait State}
     case State 
       of off then false
       else true 
     end  
   end


   fun{PlayOnce ExtendedBomber}
      local ID Action Pos in
         {Send ExtendedBomber.mybomberPort doaction(ID Action)}
         {Wait ID} {Wait Action}
         case Action 
         of move(Pos) then
             {Wait Pos}
             {Send PortWindow movePlayer(ID Pos)}
             {Adjoin ExtendedBomber extendedBomber(currentPosition:Pos)}
         [] bomb(Pos) then
             {Send PortWindow spawnBomb(Pos)}
             {Adjoin ExtendedBomber extendedBomber(explodeBombIn:Input.timingBomb currentBombPos:Pos)}
         end
      end
   end


   fun{PalyAndSkipDeadBombers ExtendedBomber}
     {Delay 400}
    case ExtendedBomber
     of nil then nil
     [] Bomber|T then 
         local UpdateExtenderBomber in 
            if ({CheckIfAlive Bomber}) then 
               UpdateExtenderBomber =  {PlayOnce Bomber}
               UpdateExtenderBomber|{PalyAndSkipDeadBombers T}
            else  
               {PalyAndSkipDeadBombers T}
            end
         end
      end
   end


    proc{LoopTurnByTurn ExtendedBomber}
      local Bombers_Alive Alive in      
         Bombers_Alive = {PalyAndSkipDeadBombers ExtendedBomber}
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
 

 ExtendedPortBombers ={CreatePortBomberAndExtend Input.bombers 1}
 NbSpawPosition= {Length Input.mapDescription.floorSapwan}
 RandomListSpawPosition= {ShuffleListNumber Input.mapDescription.floorSapwan}
 
 {Show RandomListSpawPosition}

 {Init_Show_Bombers ExtendedPortBombers 1}

 {LoopTurnByTurn ExtendedPortBombers}





end

