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
   CheckTile
   MoveRandom
   DoAction
   AddObject
   TakeHit
   GetInfo
   TreatStream
   Name = 'namefordebug'

   % Debug
   Show Show2
   LocalDebug= true
   LocalDebug2= false
in
%%% TOOLS %%%%
  proc {Show Msg}
    if (LocalDebug == true) then {System.show Msg}
    else skip end 
  end

   proc {Show2 Msg}
    if (LocalDebug2 == true) then {System.show Msg}
    else skip end 
  end
 %%% END TOOLS %%%%

   fun{StartPlayer ID}
      local
         Stream Port OutputStream PlayerInfo
      in
         PlayerInfo = infos(id: ID lives:Input.nbLives bombs:Input.nbBombs score: 0 state:off currentPos:null initPos:null)
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
         %TODO Make spawn. Est-ce qu'il faut faire quelque chose en plus???
         NewPlayer = infos(id: PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombs score:PlayerInfo.score state:on currentPos:PlayerInfo.initPos initPos:PlayerInfo.initPos)
      else
         NewPlayer = null
      end
   end

   /*
    * Return the value corresponding to the type of tile in position X Y (1,2,3 or 4)
    */
   %Si on arrive en fin de liste, simmule un mur. Cela ne devrait jamais arriver car le player est toujours arrêté par un mur avant
   fun {CheckTile Map X Y}
      local
         local
            fun {IterateColumns Acc L}
               case L of H|T then
                  if Acc == 1 then H
                  else {IterateColumns Acc-1 T}
                  end
               [] nil then 1 %went too far, shouldn't happen
               end
            end
         in
            fun {IterateLines Acc L}
               case L of H|T then %Head followed by a list
                  if Acc == 1 then {IterateColumns Y H}
                  else
                     {IterateLines Acc-1 T}
                  end
               [] [H] then %Last line possible
                  {IterateColumns Y [H]}
               end
            end
         end
         /*fun {Iterate Acc L}
            case L of H|T then
               if Acc == 1 then H
               else {Iterate Acc-1 T}
            []H|T then
               if Acc == 1 then H
               else
                  {Iterate Acc-1 T}
               end
            [] nil then 1 %If we are reaching the last element, it is a wall %TODOOOOOOOOOOO
            [] 1 then 1
            end
         end*/
      in
         {IterateLines X Map}
         %{Iterate Y {Iterate X Map}}
      end
   end

   /*
    * Take a player in argument and return a player that has moved in a rondaom direction, avoiding walls
    * @NewPlayer: Updated version of PlayerInfo where currentPos has been updated regarding the new position
    */
   %Cas limite: Tourne en boucle si un player se trouve entouré uniquement de murs (possible si map mal faite et spawn à cet endroit là)
   proc{MoveRandom PlayerInfo NewPlayer}
   {Show 'MoveRandom'}
      local
         NewPos Rand
         fun{GetNewPos Pos Dir}
            {Show 'GetNewPos in direction'#Dir}
            local
               TryPos
            in/* 
               if Dir == 0 then
                  TryPos = pt(x:PlayerInfo.currentPos.x+1 y:PlayerInfo.currentPos.y)
               elseif Dir == 1 then
                  TryPos = pt(x:PlayerInfo.currentPos.x y:PlayerInfo.currentPos.y+1)
               elseif Dir == 2 then
                  TryPos = pt(x:PlayerInfo.currentPos.x-1 y:PlayerInfo.currentPos.y)
               elseif Dir == 3 then
                  TryPos = pt(x:PlayerInfo.currentPos.x y:PlayerInfo.currentPos.y-1)
               end*/
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
                  %TileType = {CheckTile Input.map TryPos.x TryPos.y}
                  TileType = {Nth {Nth Input.map TryPos.y} TryPos.x}
                  {Show 'TileType is '#TileType}
                  if TileType == 1 orelse TileType == 2 orelse TileType == 3 then %The wanted direction is a wall or there is a box, need to change direction
                     {Show 'Find other Pos'#Pos#'in direction'#((Dir+1) mod 4)}
                     {GetNewPos Pos ((Dir+1) mod 4)}
                  else %It is possible to go in the wanted direction
                     {Show 'NewPosition is'#TryPos}
                     TryPos
                  end
               end
            end
         end
      in
         Rand = {OS.rand} mod 4
         NewPos = {GetNewPos PlayerInfo.currentPos Rand}
         NewPlayer = infos(id: PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombs score:PlayerInfo.score state:PlayerInfo.state currentPos:NewPos initPos:PlayerInfo.initPos)
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
         Rand
      in
         Rand = ({OS.rand} mod 10)
         if PlayerInfo.state == off then
            Action = null
            NewPlayer = PlayerInfo
         else
            if Rand == 0 then % chance of 0.1 to drop a bomb
               if PlayerInfo.bombs > 0 then
                  Action = bomb(PlayerInfo.currentPos)
                  NewPlayer = infos(id: PlayerInfo.id lives:PlayerInfo.lives bombs:(PlayerInfo.bombs-1) score:PlayerInfo.score state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos)
                  {Show 'Action has bombed'}
               else
                  {MoveRandom PlayerInfo NewPlayer}
                  Action = move(NewPlayer.currentPos)
                  {Show 'Action has moved'}
               end
            else % chance of 0.9 to move
               {MoveRandom PlayerInfo NewPlayer}
               Action = move(NewPlayer.currentPos)
               {Show 'Action has moved'}
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
         NewPlayer = infos(id: PlayerInfo.id lives:PlayerInfo.lives bombs:(PlayerInfo.bombs+1) score:PlayerInfo.score state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos)
         Result = NewPlayer.bombs
      elseif Type == point then
         NewPlayer = infos(id: PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombs score:(PlayerInfo.score+Option) state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos)
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
         NewPlayer = infos(id: PlayerInfo.id lives:(PlayerInfo.lives-1) bombs:PlayerInfo.bombs score:PlayerInfo.score state:off currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos)
      end
   end

   proc {GetInfo M PlayerInfo}
      case M of spawnPlayer(ID Pos) then
         if ID == PlayerInfo.id then skip %Info about itself, can ignore
         else
            skip %TODOOOOOOOOOOOO SaveInfo
         end
      []movePlayer(ID Pos) then
         if ID == PlayerInfo.id then skip %Info about itself, can ignore
         else
            skip %TODOOOOOOOOOOOO SaveInfo
         end
      []deadPlayer(ID) then
         if ID == PlayerInfo.id then skip %Info about itself, can ignore
         else
            skip %TODOOOOOOOOOOOO SaveInfo
         end
      []bombPlanted(Pos) then
         skip %TODOOOOOOOOOOOO
      []bombExploded(Pos) then
         skip %TODOOOOOOOOOOOO
      []boxRemoved(Pos) then
         skip %TODOOOOOOOOOOOO
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
               NewPlayer = infos(id: PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombs score: PlayerInfo.score state:PlayerInfo.state currentPos:Pos initPos:Pos)
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
               {Show 'Asked to do action'}
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
            skip %Basic player only act randomly without taking other informations into account
            {TreatStream Tail PlayerInfo}
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
