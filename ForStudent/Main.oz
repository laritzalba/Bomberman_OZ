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
  PortWindow
  /*GameStateInit
  Show
  Show2
  Show3
  
  
  
  
  ShowWinner
  FloorSpawn
  SimulationPort

  %Helper game
   ShuffleListNumber
   DropNthOfList
   */
   NbSpawPosition
   RandomPositionNotSpawn
   RandomListSpawPosition
   LocalDebug= false
   LocalDebug2= false
    LocalDebug3= false
    LocalDebug4= false
    LocalDebug5= false
    LocalDebug6= true
   

  /*%Init game
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
   CreateThread*/


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

     fun {AddSpawnMessage PlayerList}
        {Show {List.is PlayerList}}
        case PlayerList
        of nil then nil 
        [] Bomber|T then
           ID in
           {Send Bomber.mybomberPort getId(ID)}
           {Wait ID} 
           spawnPlayer(ID Bomber.currentPosition)|{AddSpawnMessage T}
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
         {Show3 'Drawing: '#H}
         {Send PortWindow H} 
         {ShowAction T}
      end
   end 


   proc{ShowActionEndGame ActionList}
   %% Attention entre explosion and hide 
      case ActionList
      of nil then skip 
      [] H|T then
          case H
          of displayWinner(ID) then 
            {Show3 'Drawing: '#H}
            {Send PortWindow H} 
            {ShowAction T}
         else 
           {ShowActionEndGame T}
         end 
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
               {Show3   'pdateGameState.actionToShow'# UpdateGameState.actionToShow }
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
   GameState1 GameState MessageSpawnInit
 in
     
      %Create the state of the game  
      GameState1 = {GameControler.createState}
      GameState = {InitGamestate GameState1}
      MessageSpawnInit = {AddSpawnMessage GameState.playersList}
      {GameControler.broadcastMessage GameState.playersList MessageSpawnInit}
      {LoopTurnByTurn {Adjoin GameState gameState(portWindow: PortWindow)} GameState.playersList}
 end

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Simultaneous
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  
    proc {WaitForMinTime Continue}
       if Continue == unit then skip
       else 
         {WaitForMinTime Continue}
       end 
    end

    proc {GetSecondDecision PortGameState}
        SecondDecision
   in
         {Show5 'prefunando'}
         {Send PortGameState askChange(SecondDecision)}
         {Show5 'casi'}
         {Wait SecondDecision}
         {Show5 'Ya /sali'}
         if SecondDecision == 0 then skip
           else 
           {GetSecondDecision PortGameState}
         end 
    end 

 proc {LoopSimulataneous Bomberman PortGameState ThreadID}
         Decision 
 in 
         {Show4 ' 1 ThreadID: '# ThreadID # 'Start LoopSimulataneous'}
         {Send PortGameState decision(Decision)}
         {Wait Decision}
         if (Decision == false) then 
             % Loop until is abailable to make changes 
             %{Show4 ' 2 ThreadID: '# ThreadID #'Decision is '#Decision} 
             {LoopSimulataneous Bomberman PortGameState ThreadID}       
         else  Continue GameState DoActionGamestate IsEnded AmIDead  in
           % {Show5 '3 ThreadID: '# ThreadID #'Decision is acepted'#Decision}
            % Play once and free GameState    
            {Time.alarm ({OS.rand} mod (Input.thinkMax-Input.thinkMin))+Input.thinkMin Continue}
            
            %{Show5 'esperando YYYYYYYYYY'}
            {Send PortGameState getGameState(GameState)}           
            % {Show5 'esperando Yjhgjhgjhgj'}
            {Wait GameState}
            % {Show5 'esperando hgyvbhg'}
            {Show5 '4 ThreadID: '# ThreadID #'Get Gamestatte ok '}
            % return a  Message Record with actions rec(1:State 2:Broadcast 3:Wind)
            DoActionGamestate = {GameControler.doAction GameState Bomberman}
            %Wait for min time to continue 
            {Show5 '5 ThreadID: '# ThreadID #'DoAction ok '}
            
            {WaitForMinTime Continue}
            {Show5 'esperando YYYYYYYYYY3333333333333'} 
            %Wait for acces to GameState 
            {GetSecondDecision PortGameState} %% attention if time of thinking expire what to do ?
            % I'm in GameState only for me
             {Show5 'esperando YYYYYYYYYY222222222'}
             {Send PortGameState isGameOver(IsEnded)}
             {Wait IsEnded} 
             {Send PortGameState getBomberEtat(AmIDead Bomberman)}
             {Wait AmIDead }   
             {Show5 'esperando YYYYYYYYYY4444444444444'}

            %  if not IsEnded and not AmIDead
            if (IsEnded == false ) andthen (AmIDead == false) then  LastGameState in             
                  {Send PortGameState executeAction(DoActionGamestate.1 LastGameState)}
                  {Wait LastGameState} 
                  {GameControler.broadcastMessage LastGameState.playersList DoActionGamestate.2}
                  {ShowAction DoActionGamestate.3}
                  {Send PortGameState clean()} 
 
                  {Send PortGameState freeGameState()}
                  {Show5 '6 ThreadID: '# ThreadID #' Update bomb is free '}
                  {Show5 ' 7 ThreadID: '# ThreadID #'Gamestate is free '}
                  {Delay 100} % change delay el min time of game /2
                  {LoopSimulataneous Bomberman PortGameState ThreadID} 
            elseif (IsEnded== true) then  EndGameState in % if IsEnded 
                  {Show6 'END OF GAME  000 NEXT PRINT (((((((((((((((()))))))))))))'# Bomberman}              
                  {Send PortGameState getWinner(EndGameState)}
                  {Wait EndGameState}
                  {ShowAction EndGameState.actionToShow}
                 % {Send PortGameState freeGameState()} 
            else  %(AmIDead == true) %if AmIDead          
                  {Send PortGameState freeGameState()}
            end
            
            if IsEnded andthen AmIDead then skip end 
         end 
   end



   proc{CreateThread PlayersList PortGameState Count}
      case PlayersList
      of nil then skip
      []Bomberman|Tail then 
        {Show3 'Creating thread 2'}
        thread {LoopSimulataneous Bomberman PortGameState Count} end 
        {CreateThread Tail PortGameState Count+1}
      end
   end 
   

 proc{LoopUpdateBomb BombList PortGameState}
       case BombList 
       of nil then skip 
       [] Bomb|T then  IsEnded in 
            if(Bomb.timingBomb == unit) then GamestateUpToDate in
               {Show5 'Entro a la bomba!!!!!'}
               {Send PortGameState changing(1)}
               {Send PortGameState isGameOver(IsEnded)}
               {Wait IsEnded}  
               if (IsEnded) then 
                  {Show5 'END GAME IN BOMB'}
                  {Send PortGameState changing(0)}
                  skip
               else 
                  {Send PortGameState updateBombGamestate(GamestateUpToDate)}
                  {Wait GamestateUpToDate}
                  {GameControler.broadcastMessage GamestateUpToDate.playersList GamestateUpToDate.messageList}            
                  {ShowAction GamestateUpToDate.actionToShow}
                  {Send PortGameState changing(0)}
                  {Show5 'Salgo de la bomba !!!!!!!!!!!!'}
                  {Send PortGameState clean()}
                  {LoopUpdateBomb T PortGameState}
               end
            else 
               {LoopUpdateBomb BombList PortGameState}
            end
       end
   end


    proc{CheckTimingBomb PortGameState} 
         List  GameState IsEnded
    in
         {Send PortGameState getGameState(GameState)}
         {Wait GameState}
         {LoopUpdateBomb GameState.bombList PortGameState}
         {Delay 100} % delay time min of all game /2 
         {CheckTimingBomb PortGameState} 
   end
   

   proc{EndOfGame PortGameState}
      IsEnded
   in
      {Send PortGameState isGameOver(IsEnded)}
      {Wait IsEnded}    
      if (IsEnded) then EndGameState in 
         {Send PortGameState getWinner(EndGameState)}
         {Wait EndGameState}
         {ShowAction EndGameState.actionToShow} 
      else
        {EndOfGame PortGameState}
      end 
   end 

  proc{Simultaneous}
     Coucou PortGameState ResultGameState UpdatedGameState GameState PlayerToTest MessageSpawnInit
  in
    PortGameState = {GameControler.portGameState}
   

    {Send PortGameState getGameState(GameState)}
    {Wait GameState}
    UpdatedGameState= {InitGamestate GameState}
    {Show 'Update Init 1 '}
    {Send PortGameState updateGameState(UpdatedGameState)}
    {Show3 'Gamestatte to start '# UpdatedGameState}
   
    MessageSpawnInit = {AddSpawnMessage UpdatedGameState.playersList}
    {GameControler.broadcastMessage UpdatedGameState.playersList MessageSpawnInit}

    PlayerToTest= {Nth UpdatedGameState.playersList 1}
    {Show3 'PlayerToTest' # PlayerToTest}
   
    %{CreateThread [PlayerToTest] PortGameState 1}
    
    thread {CheckTimingBomb PortGameState} end
    {CreateThread UpdatedGameState.playersList PortGameState 1}
    %thread {EndOfGame PortGameState} end 
    
    %{Show3 'Creating Bomb Update thread'}
      
      
    %%%%% To Delete Test Message Port %%%%%%
    {Send PortGameState testMessage(Coucou)}
    {Wait Coucou}
    {Show 'Message test to Port GameState '#Coucou}
    %%%%%%% End To Delete%%%%%%%%%%%%%%%%%%%
end



  in 
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

