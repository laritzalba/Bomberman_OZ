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
   MakeSpawn
   UpdateMap
   CheckTile
   MoveRandom
   DoAction
   AddObject
   TakeHit
   ManageInfo
   GetRivalByID
   AddPlayer
   RemovePlayer
   TreatStream
   Name = 'namefordebug'

   %Values that represents items on map
   FLOOR = 0
   WALL = 1
   BOX_POINT = 2
   BOX_BONUS = 3
   FLOOR_SPAWN = 4
   OTHER_BOMB = 1000 %
   MY_BOMB = 100
   %The values can be added. The different type informations are held in different power of 10 to be able to retrieve the information with the operation 'mod'
   %NbRow = Input.NbRow
   %NbColumn = Input.NbColumn

   % Debug
   Show Show2
   LocalDebug= true
   LocalDebug2= true
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
    * Make PlayerInfo spawn on the board if appropriate
    * @NewPlayer is bound to the updated version of the PlayerInfo is it could spawn,
    *            is bound to null otherwise
    */
   proc{MakeSpawn PlayerInfo NewPlayer}
      if PlayerInfo.state == off andthen PlayerInfo.lives > 0 then
         NewPlayer = infos(id: PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombs score:PlayerInfo.score state:on currentPos:PlayerInfo.initPos initPos:PlayerInfo.initPos map:PlayerInfo.map rivals:PlayerInfo.rivals)
      else
         NewPlayer = null
      end
   end

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
      if X == 0 orelse Y == 0 orelse X == Input.nbRow orelse Y == Input.nbColumn then %This is a wall
         1
      else
         {Nth {Nth Map Y} X}
      end
    end

   /*
    * Take a player in argument and return a player that has moved in a rondaom direction, avoiding walls
    * @NewPlayer: Updated version of PlayerInfo where currentPos has been updated regarding the new position
    */
   %Cas limite: Tourne en boucle si un player se trouve entouré uniquement de murs (possible si map mal faite et spawn à cet endroit là)
   proc{MoveRandom PlayerInfo NewPlayer}
   {Show2 'MoveRandom'}
      local
         NewPos Rand
         fun{GetNewPos Pos Dir}
            {Show2 'GetNewPos in direction'#Dir}
            local
               TryPos
            in
               if Dir == 0 then
                  TryPos = pt(x:(Pos.x+1) y:Pos.y)
               elseif Dir == 1 then
                  TryPos = pt(x:Pos.x y:(Pos.y+1))
               elseif Dir == 2 then
                  TryPos = pt(x:(Pos.x-1) y:Pos.y)
               elseif Dir == 3 then
                  TryPos = pt(x:Pos.x y:(Pos.y-1))
               end
               local TileType in
                  TileType = {CheckTile PlayerInfo.map TryPos.x TryPos.y}
                  {Show 'GetNewPos - TileType is '#TileType}
                  if TileType == WALL orelse TileType == BOX_BONUS orelse TileType == BOX_POINT then %The wanted direction is a wall or there is a box, need to change direction
                     {Show 'GetNewPos - Find other Pos'#Pos#'in direction'#((Dir+1) mod 4)}
                     {GetNewPos Pos ((Dir+1) mod 4)}
                  else %It is possible to go in the wanted direction
                     {Show 'GetNewPos - NewPosition is'#TryPos}
                     TryPos
                  end
               end
            end
         end
      in
         Rand = {OS.rand} mod 4
         NewPos = {GetNewPos PlayerInfo.currentPos Rand}
         NewPlayer = infos(id: PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombs score:PlayerInfo.score state:PlayerInfo.state currentPos:NewPos initPos:PlayerInfo.initPos map:PlayerInfo.map rivals:PlayerInfo.rivals)
      end
   end

   /*
    * Drop a bomb if possible in 0.1 of the case
    * Move randomly in a non-wall direction in 0.9 other case or if there is no bomb left
    * @NewPlayer: is bound to the updated version of PlayerInfo
    *             currentPos is updated to new position if the player has moved
    *             bombs is decreased by one if a bomb was droped
    * @Action: is bound to bomb(PlayerInfo.currentPos) if a bomb was drop and
    *          is bound to move(pos) where pos is the new player position
    */
   proc{DoAction PlayerInfo Action NewPlayer}
         Rand NewMap
      in
         Rand = ({OS.rand} mod 10)
         if PlayerInfo.state == off then
            Action = null
            NewPlayer = PlayerInfo
         else
            if Rand == 0 then % chance of 0.1 to drop a bomb if possible
               if PlayerInfo.bombs > 0 andthen ({CheckTile PlayerInfo.map PlayerInfo.currentPos.x PlayerInfo.currentPos.y} mod MY_BOMB) == 0 then %There are still bomb left and none of my bombs on the tile
                  Action = bomb(PlayerInfo.currentPos)
                  NewMap = {UpdateMap PlayerInfo.map PlayerInfo.currentPos.x PlayerInfo.currentPos.y MY_BOMB}
                  NewPlayer = infos(id: PlayerInfo.id lives:PlayerInfo.lives bombs:(PlayerInfo.bombs-1) score:PlayerInfo.score state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos map:NewMap rivals:PlayerInfo.rivals)
                  {Show 'DoAction - Bombed'}
               else
                  {MoveRandom PlayerInfo NewPlayer}
                  Action = move(NewPlayer.currentPos)
                  {Show 'DoAction - Moved'}
               end
            else % chance of 0.9 to move
               {MoveRandom PlayerInfo NewPlayer}
               Action = move(NewPlayer.currentPos)
               {Show2 'DoAction - Moved'}
            end
         end
   end

   /*
    * Add [Option] item(s) of type [Type] to the items owned by the player represented byPlayerInfo
    * @NewPlayer: Updated version of NewPlayer with the new number of item where appropriate
    * @Result: Updated number of item(s) [Type]
    * Supported items: 'bomb','point'
    */
   proc {AddObject Type Option PlayerInfo NewPlayer Result}
      if Type == bomb then
         NewPlayer = infos(id: PlayerInfo.id lives:PlayerInfo.lives bombs:(PlayerInfo.bombs+1) score:PlayerInfo.score state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos map:PlayerInfo.map rivals:PlayerInfo.rivals)
         Result = NewPlayer.bombs
      elseif Type == point then
         NewPlayer = infos(id: PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombs score:(PlayerInfo.score+Option) state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos map:PlayerInfo.map rivals:PlayerInfo.rivals)
         Result = NewPlayer.score
      else skip %This option is supported
      end
   end

   /*
    * Update a player that has been hit, taking it off the board and taking off a live if appropriate
    * @NewPlayer: New version of PlayerInfo with lives diminished by one and state == off if player was on the board and could die
    *             Null if the player was already off the board or could not die
    */
   proc {TakeHit PlayerInfo NewPlayer}
      if PlayerInfo.state == off then %The player is already off the board
         NewPlayer = null
      else %The player is on the board and need to die
         NewPlayer = infos(id: PlayerInfo.id lives:(PlayerInfo.lives-1) bombs:PlayerInfo.bombs score:PlayerInfo.score state:off currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos map:PlayerInfo.map rivals:PlayerInfo.rivals)
      end
   end

   /*
    * Return the tupple corresponding to most recent state corresponding to the rival ID if it is in the list Rivals,
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
    * @NewPlayer: Bound to new state of player informations
    * Handled messages: spawnPlayer, movePlayer, deadPlayer, bombPlanted, bombPlanted, bombExploded, boxRemoved
    */
   fun {ManageInfo M PlayerInfo}
      %{Show 'ManageInfo'#PlayerInfo.id.id#'has received message'#M}
      %{Show 'ManageInfo - Player infos'#PlayerInfo}
      case M of spawnPlayer(ID Pos) then
         {Show 'ManageInfo'#PlayerInfo.id.id#' Spawn player'#ID#'in pos'#Pos}
         if ID == PlayerInfo.id then %Info about itself return same state
            PlayerInfo
         else
               CurrentVal = {CheckTile PlayerInfo.map Pos.x Pos.y}
               NewPlayer NewMap NewRivalState
            in
               NewMap = {UpdateMap PlayerInfo.map Pos.x Pos.y CurrentVal+10}
               NewRivalState = rival(id:ID state:on pos:Pos)|PlayerInfo.rivals
               NewPlayer = infos(id:PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombs score:PlayerInfo.score state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos map:NewMap rivals:NewRivalState)
               NewPlayer
         end
      []movePlayer(ID Pos) then
         {Show 'ManageInfo'#PlayerInfo.id.id#' Move player'#ID.id#'in pos'#Pos}
         if ID == PlayerInfo.id then %Info about itself return same state
            PlayerInfo
         else
               Rival NewRivalState TemporaryMap NewMap NewPlayer
            in 
               Rival = {GetRivalByID PlayerInfo.rivals ID}
               if Rival == null orelse Rival.pos == null then %Problem, rival was not register on our list, shouldn't happen
                  {Show2 'Error'#PlayerInfo.id.id#' in movePlayer: Result of GetRivalByID for playre'#ID#'is'#Rival}
                  TemporaryMap = PlayerInfo.map
               else %Rival was on list and it is remove from old position
                  TemporaryMap = {RemovePlayer PlayerInfo.map Rival.pos.x Rival.pos.y}
               end
               NewRivalState = rival(id:ID state:on pos:Pos)|PlayerInfo.rivals
               NewMap = {AddPlayer TemporaryMap Pos.x Pos.y}%Add rival to new position
               NewPlayer = infos(id:PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombs score:PlayerInfo.score state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos map:NewMap rivals:NewRivalState)
               {Show 'ManageInfo'#PlayerInfo.id.id#' MovePlayer - NewRivalSate is'#NewRivalState}
               NewPlayer
         end
      []deadPlayer(ID) then
         if ID == PlayerInfo.id then %Info about itself return same state
            PlayerInfo
         else
               Rival NewRivalState NewMap NewPlayer
            in
               Rival = {GetRivalByID PlayerInfo.rivals ID}
               if Rival == null orelse Rival.pos == null then %Problem, rival was not register on our list or was marked off board, shouldn't happen
                  {Show2 'Error: Rival'#ID#'has died and was not on our rival list or was considered of the board'}
                  NewMap = PlayerInfo.map
               else
                  NewMap = {RemovePlayer PlayerInfo.map Rival.pos.x Rival.pos.y} % Remove rival ID from old position
               end
               NewRivalState = rival(id:ID state:off pos:null)|PlayerInfo.rivals %update of rival state
               NewPlayer = infos(id:PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombs score:PlayerInfo.score state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos map:NewMap rivals:NewRivalState)
               NewPlayer
         end
      []bombPlanted(Pos) then
         {Show2 'Message bombPlanted has been used'}
         PlayerInfo
      []spawnBomb(Pos) then
            CurrentVal = {CheckTile PlayerInfo.map Pos.x Pos.y}
            NewMap NewPlayer
         in
            NewMap = {UpdateMap PlayerInfo.map Pos.x Pos.y CurrentVal + OTHER_BOMB}
            NewPlayer = infos(id:PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombs score:PlayerInfo.score state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos map:NewMap rivals:PlayerInfo.rivals)
            NewPlayer
      []bombExploded(Pos) then
            CurrentVal = {CheckTile PlayerInfo.map Pos.x Pos.y}
            NewMap NewPlayer
         in 
            if(CurrentVal mod OTHER_BOMB) < 10 then %There was only my bombs on the tile
               NewMap = {UpdateMap PlayerInfo.map Pos.x Pos.y CurrentVal - MY_BOMB}
            else %There is at least another bomb than mine on the tile. Assume it was someone else's that exploded (safer to resoect rules of the game)
               NewMap = {UpdateMap PlayerInfo.map Pos.x Pos.y CurrentVal - OTHER_BOMB}
            end
            NewPlayer = infos(id:PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombs score:PlayerInfo.score state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos map:NewMap rivals:PlayerInfo.rivals)
            NewPlayer
      []boxRemoved(Pos) then
            NewMap NewPlayer
         in 
            NewMap = {UpdateMap PlayerInfo.map Pos.x Pos.y 0} %Assume that if there was a box the tile is just floor (Good for basic player, but not for more advanced ones)
            NewPlayer = infos(id:PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombs score:PlayerInfo.score state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos map:NewMap rivals:PlayerInfo.rivals)
            NewPlayer
      else %Message not handled, return same state to continue game
         {Show2 'Reception of a message that could not be handled'}
         PlayerInfo
      end
   end
   
   %%%%%%%%%%%%%%%%Treatmen and handling of received messages

   proc{TreatStream Stream PlayerInfo} %% TODO you may add some arguments if needed
     case Stream of nil then skip
     []Head|Tail then
         case Head of getId(BomberID) then
            BomberID = PlayerInfo.id
            %{Show }
            {TreatStream Tail PlayerInfo}
         []getState(BomberID BomberState) then
            BomberID = PlayerInfo.id
            BomberState = PlayerInfo.state
            {TreatStream Tail PlayerInfo}
         []assignSpawn(Pos) then
            local
               NewPlayer
            in
               NewPlayer = infos(id: PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombs score: PlayerInfo.score state:PlayerInfo.state currentPos:Pos initPos:Pos map:PlayerInfo.map rivals:PlayerInfo.rivals)
               {TreatStream Tail NewPlayer} %TODO Est-ce que cette position a été vérifiée comme possible?
            end
         []spawn(BomberID BomberPos) then
            local
               NewPlayer
            in
               {MakeSpawn PlayerInfo NewPlayer}
               if NewPlayer \= null then %Bomber could spawn
                  BomberID = PlayerInfo.id
                  BomberPos = PlayerInfo.currentPos
               else %Bomber could not spawn
                  BomberID = null
                  BomberPos = null
               end
               {TreatStream Tail NewPlayer}
            end
         []doaction(BomberID BomberAction) then
            local
               NewPlayer
            in
               {Show 'TreatStream - Asked to do action'}
               {DoAction PlayerInfo BomberAction NewPlayer}
               if BomberAction == null then %The player is off the board and no action could be done
                  BomberID = null
               else
                  BomberID = NewPlayer.id
               end
               {TreatStream Tail NewPlayer}
            end
         []add(Type Option BomberResult) then
            local
               NewPlayer
            in
               {AddObject Type Option PlayerInfo NewPlayer BomberResult}
               {TreatStream Tail NewPlayer}
            end
         []gotHit(BomberID BomberResult) then
            local
               NewPlayer
            in
               {TakeHit PlayerInfo NewPlayer}
               BomberID = NewPlayer.id
               BomberResult = death(NewPlayer.lives)
               {TreatStream Tail NewPlayer}
            end
         []info(M) then
               NewPlayer
            in
               NewPlayer = {ManageInfo M PlayerInfo}
               {TreatStream Tail NewPlayer}
         end
      end
   end

  
	/*proc {TreatStream Stream }
		case Stream
		of Msg|Stail then
			{TreatStream Stail}
		else skip %something went wrong
		end
	end*/
   
end %End Module
