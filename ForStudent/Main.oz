functor
import
   System
   OS  
   GUI
   Input
   PlayerManager
export 
   portWindow:PortWindow
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
  AreRemainigBoxes
  ShowWinner
  ShooseWinner

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
                           currentPoints:0 
                           nbGetBox:0
                           )
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

   fun{AreRemainigBoxes Bombers_Alive}
      fun {CountRemainingBoxes Bombers_Alive Count}
         case Bombers_Alive
         of nil then Count 
         [] H|T then {CountRemainingBoxes T (Count + H.nbGetBox)}
         end
      end
    
    TotalTakenBoxes RemainingBoxes 
    in    
    TotalTakenBoxes = {CountRemainingBoxes Bombers_Alive 0}
    RemainingBoxes =Input.nbBoxes - TotalTakenBoxes 
    if (RemainingBoxes == 0 ) then false else true end
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

 % To Do: verify if two bomber have the same point at the end, what to do 
   fun{ShooseWinner Alive_ExtendedBomber}
      fun{HelperShooseWinner Alive_ExtendedBomber Winner Points}
         case Alive_ExtendedBomber
         of nil then Winner         
         [] H|T then 
            if (H.currentPoints > Points) then {HelperShooseWinner T H H.currentPoints}
            else {HelperShooseWinner T Winner Points} 
            end  
         end   
      end
   in 
     {HelperShooseWinner Alive_ExtendedBomber Alive_ExtendedBomber.1 Alive_ExtendedBomber.1.currentPoints}
  end

   proc{ShowWinner Winner}
     ID in
     {Send Winner.mybomberPort getId(ID)}
     {Wait ID}
     {Send PortWindow displayWinner(ID)}    
   end


    proc{LoopTurnByTurn ExtendedBomber}
      local Bombers_Alive Alive Remaining in      
         Bombers_Alive = {PalyAndSkipDeadBombers ExtendedBomber}
         Alive = {Length Bombers_Alive}
            % every body dead --> end
         if (Alive == 0) then skip 
            % one winer --> end show winer
         elseif (Alive ==1) then skip 
             % there are not more boxes left --> end show winer(s)
         elseif {AreRemainigBoxes Bombers_Alive} == false then skip 
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
 

 {Init_Show_Bombers ExtendedPortBombers 1}

 {LoopTurnByTurn ExtendedPortBombers}





end

