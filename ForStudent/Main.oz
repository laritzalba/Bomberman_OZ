functor
import
   System
   OS  
   GUI
   Input
   PlayerManager
   GameControler
export 
   portWindow:PortWindow
define
  GameState
  GameStateInit
  Show
  PortWindow
  NbSpawPosition
  RandomListSpawPosition
  RandomPositionNotSpawn
  ShowWinner
  FloorSapwan
  SimulationPort
  PortWindowSimulation 

  %Helper
   ShuffleListNumber
   DropNthOfList


  %Init
  RandomPosition
  Init_Show_Bombers
  
  %Turn by turn
  LoopTurnByTurn
  ShowAction

in
  %%% TOOLS %%%%
  proc {Show Msg}
		{System.show Msg}
	end
 %%% END TOOLS %%%%

%%%%%%%%%%%%%%%%%%%%%%% Init Helper Functions %%%%%%%%%%%%%%%%%%%%%%%
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

   fun {Init_Show_Bombers GameState}
      fun {Helper_Init_Show_Bombers ExtendedBombers Count}
         case ExtendedBombers
         of nil then nil 
         [] H|T then ID Position in
               % Init   
               {Send H.mybomberPort assignSpawn({RandomPosition Count})}
               {Send H.mybomberPort spawn(ID Position)}
               {Wait ID}
               {Wait Position}
               % Show 
               {Send PortWindow initPlayer(ID)}
               {Send PortWindow spawnPlayer(ID Position)}
               {Adjoin H extendedBomber(currentPosition:Position)}|{Helper_Init_Show_Bombers T Count+1}
         end
      end
      UpdatePlayerList in 
      UpdatePlayerList= {Helper_Init_Show_Bombers GameState.playersList 1}
      {Adjoin GameState gameState(playersList: UpdatePlayerList)}
      
   end



   %%%%%%%%%%%%%%%%%%%%%%% Turn by Turn Helper Functions %%%%%%%%%%%%%%%%%%%%%%%

   
   proc{ShowAction ActionList}
   %% Attention entre explosion and hide 
      case ActionList
      of nil then skip 
      [] H|T then
         {Show 'Drawing: '#H}
         {Send PortWindow H} 
         {Delay 100}
         {ShowAction T}
      end
   end 


   proc {LoopTurnByTurn GameState PlayersList}
      if (GameState.endGame == true) then % end of the game 
         {Show 'Main Action to show '#GameState.actionToShow}
         {ShowAction GameState.actionToShow}
      else 
         case PlayersList 
         of nil then {LoopTurnByTurn GameState GameState.playersList} % end round, start new round 
         []ExtendedBombers|T then 
            UpdateGameState in
            UpdateGameState = {GameControler.play GameState ExtendedBombers}
               {ShowAction UpdateGameState.actionToShow}
               {LoopTurnByTurn UpdateGameState T} 
         end
      end   
   end 
 

fun{SimulationPort}
   Port Stream 
in
   {NewPort Stream Port} 
   Port
end
   

 %%%%%%%%%%%%%%%%%%%%%%% Main %%%%%%%%%%%%%%%%%%%%%%%
 %PortWindow =  {SimulationPort}
 PortWindow = {GUI.portWindow}
 {Send PortWindow buildWindow}

 

 %Create the state of the game  
 GameState = {GameControler.createState }
 % Get List with spawn posiion
 FloorSapwan = GameState.wfloorSapwan
 {Show 'FlooSpawn is nul: '# {FlooSpawn == nil }}
 NbSpawPosition= {Length FloorSapwan}
 % Random List of spawn position (variable global) to use in inner fun 
 RandomListSpawPosition= {ShuffleListNumber FloorSapwan}
 
  % init and show bombers 
 GameStateInit= {Init_Show_Bombers GameState}

 
 {Show GameStateInit}

 {LoopTurnByTurn {Adjoin GameState gameState(portWindow: PortWindow)} GameStateInit.playersList}

end

