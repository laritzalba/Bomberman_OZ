functor
import
   Input
   Browser
   Projet2019util
   OS
   System
export
   portPlayer:StartPlayer
define   
   StartPlayer
   UpdateMap
   CheckTile
   SafeMove
   DangerValue
   FindMin
   Safest
   MoveRandom
   DoAction
   AddObject
   ManageInfo
   GetRivalByID
   AddPlayer
   RemovePlayer
   TreatStream
   Name = 'survivor'

   %Values that represents items on map
   FLOOR = 0
   WALL = 1
   BOX_POINT = 2
   BOX_BONUS = 3
   FLOOR_SPAWN = 4
   OTHER_BOMB = 1000 %
   MY_BOMB = 100
   %The values can be added. The different type informations are held in different power of 10 to be able to retrieve the information with the operation 'mod'

   %Control the frequence at which bombs are droped, frequency is 1/BOMB_FREQ
   BOMB_FREQ = 10

   % Debug
   Show Show2
   LocalDebug= false
   LocalDebug2= false
in
%%% TOOLS %%%%
  proc {Show Msg} %Used for info messages (in this file)
    if (LocalDebug == true) then {System.show Msg}
    else skip end 
  end

   proc {Show2 Msg} %Used for error messages (in this file)
    if (LocalDebug2 == true) then {System.show Msg}
    else skip end 
  end
 %%% END TOOLS %%%%

   fun{StartPlayer ID}
      local
         Stream Port OutputStream PlayerInfo Rivals
      in
         Rivals = nil
         PlayerInfo = infos(id:ID lives:Input.nbLives bombs:Input.nbBombs score: 0 state:off currentPos:null initPos:null map:Input.map rivals:Rivals)
         thread %% filter to test validity of message sent to the player
            OutputStream = {Projet2019util.portPlayerChecker Name ID Stream}
         end
         {NewPort Stream Port}
         thread
            {TreatStream OutputStream PlayerInfo}
         end
         Port
      end
   end

   %%%%%%%%%%%%%%%%%%%Functions and procedures usefull for TreatStream

   /*
    * Update the map Map by setting the new Value Val at position (X,Y)
    * @Return: The updated map
    */
   fun {UpdateMap Map X Y Val}
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
      in
         {ReplaceValInList Map {ReplaceValInList {Nth Map Y} Val X 1} Y 1}
   end

   /*
    * Return the value corresponding to the type of tile in position X Y (1,2,3 or 4)
    */
    fun {CheckTile Map X Y}
      if X == 1 orelse Y == 1 orelse X == Input.nbColumn orelse Y == Input.nbRow then
         1
      else
         {Nth {Nth Map Y} X}
      end
    end

   /*
    * Take a player in argument and return the random direction in which the player is going to move, avoiding walls and boxes
    * @Return: The new position of the player if it was possible to move
    *          null if the player is trapped (all directions have a wall or a box)
    */
   fun{MoveRandom PlayerInfo}
      {Show 'MoveRandom'}
      local
         NewPos Rand
         fun{GetNewPos Pos Dir Acc}
            if Acc == 4 then %All directions have been tested, player is trapped
               null
            else
               {Show 'GetNewPos in direction'#Dir}
               TryPos TileType in
               if Dir == 0 then
                  TryPos = pt(x:(Pos.x+1) y:Pos.y)
               elseif Dir == 1 then
                  TryPos = pt(x:Pos.x y:(Pos.y+1))
               elseif Dir == 2 then
                  TryPos = pt(x:(Pos.x-1) y:Pos.y)
               else %Dir == 4
                  TryPos = pt(x:Pos.x y:(Pos.y-1))
               end
               %TileType in
               TileType = {CheckTile PlayerInfo.map TryPos.x TryPos.y}
               {Show 'GetNewPos - TileType is '#TileType}
               if TileType == WALL orelse TileType == BOX_BONUS orelse TileType == BOX_POINT then %The wanted direction is a wall or there is a box, need to change direction
                  {Show 'GetNewPos - Find other Pos'#Pos#'in direction'#((Dir+1) mod 4)}
                  {GetNewPos Pos ((Dir+1) mod 4) Acc+1}
               else %It is possible to go in the wanted direction
                  {Show 'GetNewPos - NewPosition is'#TryPos}
                  TryPos
               end
            end
         end
      in
         Rand = {OS.rand} mod 4
         NewPos = {GetNewPos PlayerInfo.currentPos Rand 0}
         NewPos
      end
   end

   

   fun{DangerValue Map X Y}
      {Show 'DangerValue in pos'#X#Y}
         N S E W Val Check
         fun{CheckVal X Y DX DY N Acc}
            {Show 'CheckVal n = '#N}
            if N == 0 then
               Acc
            else
               Tile in
               Tile = {CheckTile Map X Y}
               if Tile == WALL orelse Tile == BOX_BONUS orelse Tile == BOX_POINT then %Stop looking for bomb
                  Acc
               elseif Tile >= MY_BOMB then %There is a bomb that could reach the player
                  {CheckVal X+DX Y+DY DX DY N-1 Acc+1}
               else
                  {CheckVal X+DX Y+DY DX DY N-1 Acc}
               end
            end
         end
      in
         Check = {CheckTile Map X Y}
         {Show 'Tile value is '#Check}
         if Check == WALL orelse Check == BOX_BONUS orelse Check == BOX_POINT then
            {Show 'DangerValue found is null'}
            null
         else
            N = {CheckVal X Y 0 ~1 Input.fire 0}
            S = {CheckVal X Y+1 0 1 Input.fire 0}
            W = {CheckVal X-1 Y ~1 0 Input.fire 0}
            E = {CheckVal X+1 Y 0 1 Input.fire 0}
            Val = N + S + W + E
            {Show 'DangerValue found is'#Val}
            Val
         end
   end

   proc{FindMin A B Min Tie}
      if A == null orelse A.arg == null then
         if B == null orelse B.arg == null then
            Min = null
            Tie = true
         else
            Min = B
            Tie = false
         end
      else
         if B == null orelse B.arg == null then
            Min = A
            Tie = false
         elseif B.arg == A.arg then
            Min = A
            Tie = true
         elseif A.arg < B.arg then
            Min = A
            Tie = false
         else %B < A
            Min = B
            Tie = false
         end
      end
   end

   proc{Safest Pos Map Type Result Nbr}
      N S W E MinX MinY Min Min1 Min2 TieX TieY Tie Tie1 Tie2 in
      if Type == danger then
         N = tile(x:Pos.x y:Pos.y-1 arg:{DangerValue Map Pos.x Pos.y-1})
         {Show 'N danger value'#N.arg}
         S = tile(x:Pos.x y:Pos.y+1 arg:{DangerValue Map Pos.x Pos.y+1})
         {Show 'S danger value'#S.arg}
         W = tile(x:Pos.x-1 y:Pos.y arg:{DangerValue Map Pos.x-1 Pos.y})
         {Show 'W danger value'#W.arg}
         E = tile(x:Pos.x+1 y:Pos.y arg:{DangerValue Map Pos.x+1 Pos.y})
         {Show 'E danger value'#E.arg}
      end
      {FindMin N S MinY TieY}
      {FindMin W E MinX TieX}
      {FindMin MinY MinX Min Tie}
      {Show 'MinY:'#MinY#'TieY'#TieY#'MinX:'#MinX#'TieX'#TieX#'Min'#Min#'Tie:'#Tie}
      if Tie == false then
         if MinX == Min then
            if TieX == true then %W E
               Result = pt(x:W.x y:W.y)#pt(x:E.x y:E.y)
               Nbr = 2
            else %MinX
               Result = pt(x:MinX.x y:MinX.y)
               Nbr = 1
            end
         else %MinY == Min
            if TieY == true then % N S
               Result = pt(x:N.x y:N.y)#pt(x:S.x y:S.y)
               Nbr = 2
            else %MinY
               Result = pt(x:MinY.x y:MinY.y)
               Nbr = 1
            end
         end
      else %Tie
         if TieX == true andthen TieY == true then
            if Min == null then %Trapped
               Result = null
               Nbr = 0
            else % N S W E
               Result = pt(x:N.x y:N.y)#pt(x:S.x y:S.y)#pt(x:W.x y:W.y)#pt(x:E.x y:E.y)
               Nbr = 4
            end
         elseif TieX == false andthen TieY == false then
            Result = pt(x:MinX.x y:MinX.y)#pt(x:MinY.x y:MinY.y)
            Nbr = 2
         elseif TieX == true andthen TieY == false then
            {FindMin MinX N Min1 Tie1}
            if Tie1 == true then %W E N
               Result = pt(x:W.x y:W.y)#pt(x:E.x y:E.y)#pt(x:N.x y:N.y)
               Nbr = 3
            else %W E S
               Result = pt(x:W.x y:W.y)#pt(x:E.x y:E.y)#pt(x:S.x y:S.y)
               Nbr = 3
            end
         elseif TieX == false andthen TieY == true then
            {FindMin MinY W Min2 Tie2}
            if Tie2 == true then %N S W
               Result = pt(x:N.x y:N.y)#pt(x:S.x y:S.y)#pt(x:W.x y:W.y)
               Nbr = 3
            else %N S E
               Result = pt(x:N.x y:N.y)#pt(x:S.x y:S.y)#pt(x:E.x y:E.y)
               Nbr = 3
            end
         end
      end
   end

   %Return a safe position from Pos
   fun{SafeMove Map Pos}
      NewPos SafeOptions Nbr Rand in
      {Safest Pos Map danger SafeOptions Nbr}
      {Show 'SafeMove has received'#Nbr#'safe positions:'#SafeOptions}
      if Nbr =< 1 then NewPos = SafeOptions
      elseif Nbr == 2 then
         Rand = ({OS.rand} mod 2)
         if Rand == 0 then NewPos = SafeOptions.1
         else NewPos = SafeOptions.2
         end
      elseif Nbr == 3 then
         Rand = ({OS.rand} mod 3)
         if Rand == 0 then NewPos = SafeOptions.1
         elseif Rand == 1 then NewPos = SafeOptions.2
         else NewPos = SafeOptions.3
         end
      elseif Nbr == 4 then
         Rand = ({OS.rand} mod 4)
         if Rand == 0 then NewPos = SafeOptions.1
         elseif Rand == 1 then NewPos = SafeOptions.2
         elseif Rand == 2 then NewPos = SafeOptions.3
         else NewPos = SafeOptions.4
         end
      end
      NewPos
   end

   /*
    * Drop a bomb if possible in 0.1 of the case or if it impossible to move if the tile is safe
    * Move in the safest direction in 0.9 other case or if there is no bomb left if tile is safe
    * Move in the safest direction if current tile is not safe
    * Do nothing if no action is possible
    * @NewPlayerInfo: bounded to PlayerInfo if player has moved or if no action could be done,
    *             bounded to an updated version of Info player where bombs is decreased by one if a bomb was droped
    * @Action: is bound to bomb(PlayerInfo.currentPos) if a bomb was drop,
    *          to move(pos) where pos is the new player position if the player has moved,
    *          to null if no action could be done (player is off the board or trapped with no wall left)
    */
   proc{DoAction PlayerInfo Action NewPlayerInfo}
      {Show 'DoAction Player info:'#PlayerInfo}
      if {DangerValue PlayerInfo.map PlayerInfo.currentPos.x PlayerInfo.currentPos.y} > 0 then %Not on a safe tile => move
         {Show 'DoAction'#PlayerInfo.id.id#'Tile is dangerous'}
         NewPos in
         NewPos = {SafeMove PlayerInfo.map PlayerInfo.currentPos}
         if NewPos \= null then %move to new position (the safest one)
            Action = move(NewPos)
            NewPlayerInfo = PlayerInfo
            {Show 'DoAction'#PlayerInfo.id.id#'Player has moved to'#NewPos}
         else %Player is trapped, drop a bomb %Could happend only if player is trapped by boxes and has already dropped a bomb
            if PlayerInfo.bombs > 0 andthen ({CheckTile PlayerInfo.map PlayerInfo.currentPos.x PlayerInfo.currentPos.y} mod OTHER_BOMB) >= MY_BOMB then %There are still bomb left and none of my bombs are on the tile
               Action = bomb(PlayerInfo.currentPos)
               NewPlayerInfo = infos(id: PlayerInfo.id lives:PlayerInfo.lives bombs:(PlayerInfo.bombs-1) score:PlayerInfo.score state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos map:PlayerInfo.map rivals:PlayerInfo.rivals)
               {Show 'DoAction'#PlayerInfo.id.id#'Player could not move and has dropped a bomb'}
            else %Player cannot move nor drop a bomb
               Action = null
               NewPlayerInfo = PlayerInfo
            end
         end
      else %Standing on a safe tile, can either drop a bomb or move
         {Show 'DoAction'#PlayerInfo.id.id#'Tile is safe'}
         Rand in
         Rand = ({OS.rand} mod BOMB_FREQ)
         if Rand == 0 then % chance of 1-(1/BOMB_FREQ) to drop a bomb if possible
            TileCheck in 
            TileCheck = ({CheckTile PlayerInfo.map PlayerInfo.currentPos.x PlayerInfo.currentPos.y} mod OTHER_BOMB) =< MY_BOMB
            {Show 'DoAction'#PlayerInfo.id.id#'Try to drop a bomb:Bomb nbr'#PlayerInfo.bombs#'Tile is'#TileCheck}
            if PlayerInfo.bombs > 0 andthen ({CheckTile PlayerInfo.map PlayerInfo.currentPos.x PlayerInfo.currentPos.y} mod OTHER_BOMB) =< MY_BOMB then %There are still bomb left and none of my bombs are on the tile
               Action = bomb(PlayerInfo.currentPos)
               NewPlayerInfo = infos(id: PlayerInfo.id lives:PlayerInfo.lives bombs:(PlayerInfo.bombs-1) score:PlayerInfo.score state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos map:PlayerInfo.map rivals:PlayerInfo.rivals)
               {Show 'DoAction'#PlayerInfo.id.id#'Bomb has been dropped'}
            else %could not drop bomb, try to move
               NewPos in
               NewPos = {SafeMove PlayerInfo.map PlayerInfo.currentPos}
               if NewPos \= null then %move to new position (the safest)
                  Action = move(NewPos)
                  NewPlayerInfo = PlayerInfo
                  {Show 'DoAction'#PlayerInfo.id.id#'Player has moved to'#NewPos}
               else
                  Action = null
                  NewPlayerInfo = PlayerInfo
                  {Show 'DoAction'#PlayerInfo.id.id#'Player could do no action'}
               end
            end
         else % chance of 1-(1/BOMB_FREQ) to move if possible
            {Show 'DoAction'#PlayerInfo.id.id#'Try to move'}
            NewPos in
            NewPos = {SafeMove PlayerInfo.map PlayerInfo.currentPos}
            if NewPos \= null then %move to new position (the safest)
               Action = move(NewPos)
               NewPlayerInfo = PlayerInfo
               {Show 'DoAction'#PlayerInfo.id.id#'Player has moved to'#NewPos}
            else %drop a bomb if possible
               if PlayerInfo.bombs > 0 andthen ({CheckTile PlayerInfo.map PlayerInfo.currentPos.x PlayerInfo.currentPos.y} mod OTHER_BOMB) >= MY_BOMB then %There are still bomb left and none of my bombs are on the tile
                  Action = bomb(PlayerInfo.currentPos)
                  NewPlayerInfo = infos(id: PlayerInfo.id lives:PlayerInfo.lives bombs:(PlayerInfo.bombs-1) score:PlayerInfo.score state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos map:PlayerInfo.map rivals:PlayerInfo.rivals)
                  {Show 'DoAction'#PlayerInfo.id.id#'Player could not move and has dropped a bomb'}
               else %Player cannot move nor drop a bomb
                  Action = null
                  NewPlayerInfo = PlayerInfo
                  {Show 'DoAction'#PlayerInfo.id.id#'Player could do no action'}
               end
            end
         end
      end
   end

   /*
    * Add [Option] item(s) of type [Type] to the items owned by the player represented byPlayerInfo
    * @NewPlayerInfo: Updated version of NewPlayerInfo with the new number of item where appropriate
    * @Result: Updated number of item(s) [Type]
    * Supported items: 'bomb','point'
    */
   proc {AddObject Type Option PlayerInfo NewPlayerInfo Result}
      if Type == bomb then
         NewPlayerInfo = infos(id: PlayerInfo.id lives:PlayerInfo.lives bombs:(PlayerInfo.bombs+1) score:PlayerInfo.score state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos map:PlayerInfo.map rivals:PlayerInfo.rivals)
         Result = NewPlayerInfo.bombs
      elseif Type == point then
         NewPlayerInfo = infos(id: PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombs score:(PlayerInfo.score+Option) state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos map:PlayerInfo.map rivals:PlayerInfo.rivals)
         Result = NewPlayerInfo.score
      else skip %This option is supported
      end
   end

   /*
    * Return the tupple corresponding to most recent state of to the rival ID if it is in the list Rivals,
    *       null if it is not in the list
    */
   fun {GetRivalByID Rivals RivalID}
      case Rivals of nil then
         null
      [] rival(id:ID state:State pos:Pos)|T then
         if ID == RivalID then
            rival(id:ID state:State pos:Pos)
         else
            {GetRivalByID T RivalID}
         end
      end
   end

   /*
    * Remove one rival from the (X,Y) position of the map and update the value of this position accordingly
    * @Return: The updated map
    *          Value of updated position is 10*nbr of rivals after the update
    */
    fun {RemovePlayer Map X Y}
         CurrentVal = {CheckTile Map X Y}
         NewMap
      in
         NewMap = {UpdateMap Map X Y CurrentVal-10}
   end

   /*
    * Add one rival to the (X,Y) position of the map and update the value of this position accordingly
    * @Return: The updated map
    *          Value of updated position is 10*nbr of rivals after the update
    */
   fun {AddPlayer Map X Y}
         CurrentVal = {CheckTile Map X Y}
         NewMap
      in
         NewMap = {UpdateMap Map X Y CurrentVal+10}
   end

   /*
    * Treat the messages by udating the map and/or the list of rivals and the PlayerInfo
    * @M: Message to be treated
    * @PlayerInfo: CurrentState of information
    * @NewPlayerInfo: Bound to new state of player informations
    * Handled messages: spawnPlayer, movePlayer, deadPlayer, bombPlanted, bombPlanted, bombExploded, boxRemoved
    */
   fun {ManageInfo M PlayerInfo}
      %{Show 'ManageInfo'#PlayerInfo.id.id#'has received message'#M}
      %{Show 'ManageInfo - Player infos'#PlayerInfo}
      case M of spawnPlayer(ID Pos) then
         {Show 'ManageInfo'#PlayerInfo.id.id#' Spawn player'#ID#'in pos'#Pos}
            CurrentVal = {CheckTile PlayerInfo.map Pos.x Pos.y}
            NewPlayerInfo NewMap
         in
            NewMap = {UpdateMap PlayerInfo.map Pos.x Pos.y CurrentVal+10}
            if ID == PlayerInfo.id then %Info about itself, update of map only
               NewPlayerInfo = infos(id:PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombs score:PlayerInfo.score state:on currentPos:Pos initPos:PlayerInfo.initPos map:NewMap rivals:PlayerInfo.rivals)
            else %Info about a rival, update of map and rivals states
                  NewRivalState
               in
                  NewRivalState = rival(id:ID state:on pos:Pos)|PlayerInfo.rivals
                  NewPlayerInfo = infos(id:PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombs score:PlayerInfo.score state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos map:NewMap rivals:NewRivalState)
            end
            NewPlayerInfo
      []movePlayer(ID Pos) then
         {Show 'ManageInfo'#PlayerInfo.id.id#' Move player'#ID.id#'in pos'#Pos}
            NewMap NewPlayerInfo TemporaryMap
         in
            if ID == PlayerInfo.id then
               TemporaryMap = {RemovePlayer PlayerInfo.map PlayerInfo.currentPos.x PlayerInfo.currentPos.y}
               NewMap = {AddPlayer TemporaryMap Pos.x Pos.y}%Add player to new position
               NewPlayerInfo = infos(id:PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombs score:PlayerInfo.score state:PlayerInfo.state currentPos:Pos initPos:PlayerInfo.initPos map:NewMap rivals:PlayerInfo.rivals)
            else
               Rival = {GetRivalByID PlayerInfo.rivals ID}
               if Rival == null orelse Rival.pos == null then %Rival was not on list, happen at start of the game
                  TemporaryMap = PlayerInfo.map
               else %Rival was on list and it is remove from old position
                  TemporaryMap = {RemovePlayer PlayerInfo.map Rival.pos.x Rival.pos.y}
               end
               NewRivalState in
               NewRivalState = rival(id:ID state:on pos:Pos)|PlayerInfo.rivals
               NewMap = {AddPlayer TemporaryMap Pos.x Pos.y}%Add player to new position
               NewPlayerInfo = infos(id:PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombs score:PlayerInfo.score state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos map:NewMap rivals:NewRivalState)
            end
               NewPlayerInfo
      []deadPlayer(ID) then
         NewMap NewPlayerInfo in
         if ID == PlayerInfo.id then
            NewMap = {RemovePlayer PlayerInfo.map PlayerInfo.currentPos.x PlayerInfo.currentPos.y}
            NewPlayerInfo = infos(id:PlayerInfo.id lives:(PlayerInfo.lives-1) bombs:PlayerInfo.bombs score:PlayerInfo.score state:off currentPos:PlayerInfo.initPos initPos:PlayerInfo.initPos map:NewMap rivals:PlayerInfo.rivals)
         else
            Rival NewRivalState in
            Rival = {GetRivalByID PlayerInfo.rivals ID}
            if Rival == null orelse Rival.pos == null then %Problem, rival was not register on our list or was marked off board, shouldn't happen
               {Show 'Error: Rival'#ID#'has died and was not on our rival list or was considered of the board'}
               NewMap = PlayerInfo.map
            else
               NewMap = {RemovePlayer PlayerInfo.map Rival.pos.x Rival.pos.y} % Remove rival ID from old position
            end
            NewRivalState = rival(id:ID state:off pos:null)|PlayerInfo.rivals %update of rival state
            NewPlayerInfo = infos(id:PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombs score:PlayerInfo.score state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos map:NewMap rivals:NewRivalState)
         end
         NewPlayerInfo
      []bombPlanted(Pos) then
         {Show 'Message bombPlanted has been used'}
         PlayerInfo
      []spawnBomb(Pos) then
            CurrentVal = {CheckTile PlayerInfo.map Pos.x Pos.y}
            NewMap NewPlayerInfo
         in
            NewMap = {UpdateMap PlayerInfo.map Pos.x Pos.y CurrentVal + OTHER_BOMB}
            NewPlayerInfo = infos(id:PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombs score:PlayerInfo.score state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos map:NewMap rivals:PlayerInfo.rivals)
            NewPlayerInfo
      []bombExploded(Pos) then
            CurrentVal = {CheckTile PlayerInfo.map Pos.x Pos.y}
            NewMap NewPlayerInfo
         in 
            if(CurrentVal mod OTHER_BOMB) < 10 then %There was only my bombs on the tile
               NewMap = {UpdateMap PlayerInfo.map Pos.x Pos.y CurrentVal - MY_BOMB}
            else %There is at least another bomb than mine on the tile. Assume it was someone else's that exploded (safer to resoect rules of the game)
               NewMap = {UpdateMap PlayerInfo.map Pos.x Pos.y CurrentVal - OTHER_BOMB}
            end
            NewPlayerInfo = infos(id:PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombs score:PlayerInfo.score state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos map:NewMap rivals:PlayerInfo.rivals)
            NewPlayerInfo
      []boxRemoved(Pos) then
            NewMap NewPlayerInfo
         in 
            NewMap = {UpdateMap PlayerInfo.map Pos.x Pos.y 0} %Assume that if there was a box the tile is just floor (Good for basic player, but not for more advanced ones)
            NewPlayerInfo = infos(id:PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombs score:PlayerInfo.score state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos map:NewMap rivals:PlayerInfo.rivals)
            NewPlayerInfo
      else %Message not handled, return same state to continue game
         {Show2 'Reception of a message that could not be handled'}
         PlayerInfo
      end
   end
   
   %%%%%%%%%%%%%%%%Treatmen and handling of received messages

   proc{TreatStream Stream PlayerInfo}
     case Stream of nil then skip
     []Head|Tail then
         {Show2 'TreatStream'#PlayerInfo.id.id#'stream message:'#Head}
         case Head of getId(BomberID) then
            BomberID = PlayerInfo.id
            {TreatStream Tail PlayerInfo}
         []getState(BomberID BomberState) then
            BomberID = PlayerInfo.id
            BomberState = PlayerInfo.state
            {TreatStream Tail PlayerInfo}
         []assignSpawn(Pos) then
            local
               NewPlayerInfo
            in
               NewPlayerInfo = infos(id: PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombs score: PlayerInfo.score state:PlayerInfo.state currentPos:Pos initPos:Pos map:PlayerInfo.map rivals:PlayerInfo.rivals)
               {TreatStream Tail NewPlayerInfo}
            end
         []spawn(BomberID BomberPos) then
            {Show 'TreatStream'#PlayerInfo.id.id#'spawn'}
            if PlayerInfo.state == off andthen PlayerInfo.lives > 0 then %Player could spawn, update of its state
               NewPlayerInfo in
               NewPlayerInfo = infos(id: PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombs score:PlayerInfo.score state:on currentPos:PlayerInfo.initPos initPos:PlayerInfo.initPos map:PlayerInfo.map rivals:PlayerInfo.rivals)
               BomberID = PlayerInfo.id
               BomberPos = PlayerInfo.initPos
               {TreatStream Tail NewPlayerInfo}
            else %Player could not spawn
               BomberID = null
               BomberPos = null
               {TreatStream Tail PlayerInfo}
            end            
         []doaction(BomberID BomberAction) then
            NewPlayerInfo in
            {DoAction PlayerInfo BomberAction NewPlayerInfo}
            if BomberAction == null then %The player is off the board or could neither move nor drop a bomb, no action could be done
               BomberID = null
            else
               BomberID = NewPlayerInfo.id
            end
            {TreatStream Tail NewPlayerInfo}
         []add(Type Option BomberResult) then
            local
               NewPlayerInfo
            in
               {AddObject Type Option PlayerInfo NewPlayerInfo BomberResult}
               {TreatStream Tail NewPlayerInfo}
            end
         []gotHit(BomberID BomberResult) then
            BomberID = PlayerInfo.id
            if PlayerInfo.state == off then %The player is already off the board
               BomberResult = null
               {TreatStream Tail PlayerInfo}
            else %The player is on the board and return its new life number
               {Show2 'BomberSurvivor'#PlayerInfo.id.id#'got hit and has now'#PlayerInfo.lives-1#'lives left'}
               BomberResult = death(PlayerInfo.lives-1)
               {TreatStream Tail PlayerInfo}
            end
         []info(M) then
            NewPlayerInfo in
            NewPlayerInfo = {ManageInfo M PlayerInfo}
            {TreatStream Tail NewPlayerInfo}
         end
      end
   end
   
end %End Module
