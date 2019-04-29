functor
import
   System
   OS  
   GUI
   Input
   PlayerManager
   GameControler
   GameState
export 
   portWindow:PortWindow
define
  GameStateInit
  Show
  PortWindow
  NbSpawPosition
  RandomListSpawPosition
  RandomPositionNotSpawn
  ShowWinner
  FloorSpawn
  SimulationPort

  %Helper game
   ShuffleListNumber
   DropNthOfList


  %Init game
  RandomPosition
  Init_Show_Bombers
  InitGamestate
  
  %Turn by turn game
  LoopTurnByTurn
  ShowAction
  TurnByTurn
  
  % Simultaneous game
   Simultaneous
   LoopSimulataneous
   CheckAvailability
  
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
                  {Show 'Game State '#GameState}
                  {Show '2'}
               % Init   
               {Send H.mybomberPort assignSpawn({RandomPosition Count})}
               {Send H.mybomberPort spawn(ID Position)}
               {Wait ID}
               {Wait Position}
               {Show '3'}
               % Show 
               {Send PortWindow initPlayer(ID)}
               {Send PortWindow spawnPlayer(ID Position)}
               {Adjoin H extendedBomber(currentPosition:Position)}|{Helper_Init_Show_Bombers T Count+1}
         end
      end
      UpdatePlayerList in 
       {Show '1'# GameState.playersList }
      UpdatePlayerList= {Helper_Init_Show_Bombers GameState.playersList 1}
      {Show '4'}
      {Adjoin GameState gameState(playersList: UpdatePlayerList)}
      
   end



 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Turn By Turn
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   
   proc{ShowAction ActionList}
   %% Attention entre explosion and hide 
      case ActionList
      of nil then skip 
      [] H|T then
         %{Show 'Drawing: '#H}
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
   

fun{InitGamestate GameState}
    FloorSpawn
in     
      % Get List with spawn posiion
      FloorSpawn= GameState.wfloorSapwan
      %{Show 'FlooSpawn is nul: '# {FlooSpawn == nil }}
      NbSpawPosition= {Length FloorSpawn}
      % Random List of spawn position (variable global) to use in inner fun 
      RandomListSpawPosition= {ShuffleListNumber FloorSpawn}
      % init and show bombers 
      {Init_Show_Bombers GameState}
end 

 proc {TurnByTurn}
   GameState1 GameState
 in
     
      %Create the state of the game  
      GameState1 = {GameControler.createState}
      GameState = {InitGamestate GameState1}
      {LoopTurnByTurn {Adjoin GameState gameState(portWindow: PortWindow)} GameState.playersList}
 end

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Simultaneous
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


   proc {LoopSimulataneous Bomberman PortGameState}
         Decision in 
         {Send PortGameState decision(Decision)}
          {Wait Decision}
         if Decision == true then 
         % Loop until is abailable to make changes 
         {LoopSimulataneous Bomberman PortGameState}       
         else 
            GameState in
            % Play once and free GameState 
            {Send PortGameState getGameState(GameState)}
            {Wait GameState}
            if (GameState.endGame == true) then % end of the game 
               {Show 'Main Action to show '#GameState.actionToShow}
               {ShowAction GameState.actionToShow}
            else 
               UpdateGameState in
               {Send PortGameState play(UpdateGameState Bomberman)}
               {Wait UpdateGameState}
               {ShowAction UpdateGameState.actionToShow}
               {Send PortGameState  freeGamestate()}
               {LoopTurnByTurn Bomberman PortGameState} 
            end
         end    
   end 

  proc{Simultaneous}
     Coucou PortGameState ResultGameState UpdatedGameState GameState
  in
    PortGameState = {GameControler.portGameState}
   

    {Send PortGameState getGameState(GameState)}
    {Wait GameState}
    UpdatedGameState= {InitGamestate GameState}
    {Show 'Update Init '}
    {Send PortGameState updateGameState(UpdatedGameState)}
    {Show 'end'}

    %%%%% To Delete Test Message Port %%%%%%
    {Send PortGameState testMessage(Coucou)}
    {Wait Coucou}
    {Show 'Message test to Port GameState '#Coucou}
    %%%%%%% End To Delete%%%%%%%%%%%%%%%%%%%



  end


  
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Main
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   PortWindow = {GUI.portWindow}
   {Send PortWindow buildWindow}
   if (Input.isTurnByTurn == true) then 
      {TurnByTurn}
   else 
      {Simultaneous}
   end
 
end

