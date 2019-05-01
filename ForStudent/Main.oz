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
    LocalDebug3= true


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
         {Show3 'Drawing: '#H}
         {Delay 100}
         {Send PortWindow H} 
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


  /* proc {LoopSimulataneous Bomberman PortGameState ThreadID}
         Decision in 
         {Delay ({OS.rand} mod (Input.thinkMax-Input.thinkMin))+Input.thinkMin}
         {Send PortGameState decision(Decision)}
         {Wait Decision}
         if (Decision == false) then 
             % Loop until is abailable to make changes 
             {Show 'ThreadID: '# ThreadID #'Decision is '#Decision}
             {LoopSimulataneous Bomberman PortGameState ThreadID}       
         else 
            GameState Coucou in
            {Show 'ThreadID: '# ThreadID #'Decision is acepted'#Decision}
            % Play once and free GameState    

            {Send PortGameState getGameState(GameState)}
            {Wait GameState}
             {Show 'ThreadID: '# ThreadID #'Gamestate to paly '#GameState.actionToShow}

    %%%%% To Delete Test Message Port %%%%%%
    {Send PortGameState testMessage(Coucou)}
    {Wait Coucou}
    {Show 'Message test to Port GameState Coucoou2 '#Coucou}
    %%%%%%% End To Delete%%%%%%%%%%%%%%%%%%%

           if (GameState.endGame == true) then % end of the game 
               {Show 'ThreadID: '# ThreadID #'Main Action to show 3 '} %#GameState.actionToShow}
               {ShowAction GameState.actionToShow}
            else 
               UpdateGameState in
               {Show 'ThreadID: '# ThreadID #'Playing 4'}
               {Send PortGameState play(UpdateGameState Bomberman)}
               {Wait UpdateGameState}
                 {Show 'ThreadID: '# ThreadID #'Playing 5'}
               {ShowAction UpdateGameState.actionToShow}
               {Send PortGameState freeGameState()}
               {Show 'ThreadID: '# ThreadID #'Gamestate is free '}
               {LoopSimulataneous Bomberman PortGameState ThreadID} 
            end
         end    
   end 
*/


   
    proc {WaitForMinTime Continue}
       if Continue == unit then skip
       else 
         {WaitForMinTime Continue}
       end 
    end

    proc {GetSecondDecision PortGameState}
        SecondDecision
   in
         {Send PortGameState getSecondDecision(SecondDecision)}
         {Wait SecondDecision}
         if SecondDecision == true then skip
           else {GetSecondDecision PortGameState}
         end 
    end 

 proc {LoopSimulataneous Bomberman PortGameState ThreadID}
         Decision 
 in 
         {Send PortGameState decision(Decision)}
         {Wait Decision}
         if (Decision == false) then 
             % Loop until is abailable to make changes 
            % {Show 'ThreadID: '# ThreadID #'Decision is '#Decision}
             {LoopSimulataneous Bomberman PortGameState ThreadID}       
         else  Continue GameState DoActionGamestate IsEnded in
           % {Show 'ThreadID: '# ThreadID #'Decision is acepted'#Decision}
            % Play once and free GameState    
            {Time.alarm ({OS.rand} mod (Input.thinkMax-Input.thinkMin))+Input.thinkMin Continue}
            
            {Send PortGameState getGameState(GameState)}           
            {Wait GameState}
            % return a  Message Record with actions rec(1:State 2:Broadcast 3:Wind)
            DoActionGamestate = {GameControler.doAction GameState Bomberman}
            %Wait for min time to continue 
            {WaitForMinTime Continue}
             
            %Wait for acces to GameState 
            {GetSecondDecision PortGameState} %% attention if time of thinking expire what to do ?
            % I'm in GameState only for me
            {Send PortGameState isGameOver(IsEnded)}
            {Wait IsEnded}    
            if (IsEnded) then skip 
            else AmIDead in
                {Send PortGameState getBomberEtat(AmIDead Bomberman)}
                {Wait AmIDead}
               if (AmIDead) then skip 
               else (IsFree) LastGameState in

                  {Send PortGameState executeAction(DoActionGamestate DoActionGamestate.1 LastGameState)}
                  {Wait LastGameState} 
                  {Send PortGameState broadcast(DoActionGamestate.2)}
                  {ShowAction DoActionGamestate.3}

                  {Send PortGameState freeSecondDecision(IsFree)}
                  {Wait IsFree}

                  {Send PortGameState freeGameState()}
                  {Show 'ThreadID: '# ThreadID #'Gamestate is free '}
                  {LoopSimulataneous Bomberman PortGameState ThreadID} 
               end
            end 
         end    
   end

 /*
   To implement in ControlGameState 
   lock 2
   getSecondDecision(SecondDecision)
   freeSecondDecision()
  
   isGameOver(IsEnded) 
   getBomberEtat(AmIDead) 
   broadcast() 
   executeAction(DoActionGamestate DoActionGamestate.1 LastGameState)
   */

/*

   %%%%% To Delete Test Message Port %%%%%%
   {Send PortGameState testMessage(Coucou)}
   {Wait Coucou}
   {Show 'Message test to Port GameState Coucoou2 '#Coucou}
   %%%%%%% End To Delete%%%%%%%%%%%%%%%%%%%

*/

   proc{CreateThread PlayersList PortGameState Count}
      case PlayersList
      of nil then skip
      []Bomberman|Tail then 
        {Show 'Creating thread 2'}
        thread {LoopSimulataneous Bomberman PortGameState Count} end 
        {CreateThread Tail PortGameState Count+1}
      end
       {Show3 'Creating Bomb Update thread'}
       thread {LoopUpdateBomb PortGameState} end 
   end 


   proc{LoopUpdateBomb PortGameState}
     SecondDecision
   in
      {Send PortGameState getSecondDecision(SecondDecision)}
      {Wait SecondDecision}
     if (SecondDecision == false ) then      
         {LoopUpdateBomb PortGameState}
     else GamestateUpToDate in 

       {Send PortGameState updateGamestate(GamestateUpToDate)}
       {Wait GamestateUpToDate}
       {Send PortGameState  broadcast()}
       {ShowAction GamestateUpToDate.actionToShow}
       {Send PortGameState freeSecondDecision()}
       {Delay 100} % wait to do next update
       {LoopUpdateBomb PortGameState}
      end 
   end

   
      
  proc{Simultaneous}
     Coucou PortGameState ResultGameState UpdatedGameState GameState
  in
    PortGameState = {GameControler.portGameState}
   

    {Send PortGameState getGameState(GameState)}
    {Wait GameState}
    UpdatedGameState= {InitGamestate GameState}
    {Show 'Update Init 1 '}
    {Send PortGameState updateGameState(UpdatedGameState)}
    {CreateThread UpdatedGameState.playersList PortGameState 1}
      
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

