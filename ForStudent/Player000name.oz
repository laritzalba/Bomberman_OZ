functor
import
   Input
   Browser
   Projet2019util
export
   portPlayer:StartPlayer
define   
   StartPlayer
   MakeSpawn
   CheckTile
   MoveRandom
   DoAction
   AddObject
   TreatStream
   Name = 'namefordebug'
in
   fun{StartPlayer ID}
      Stream Port OutputStream PlayerInfo
   in
      PlayerInfo = infos(id: ID lives:Input.nbLives bombs:Input.nbBombes score: 0 state:off currentPos:null initPos:null)
      thread %% filter to test validity of message sent to the player
         OutputStream = {Projet2019util.portPlayerChecker Name ID Stream}
      end
      {NewPort Stream Port}
      thread
	      {TreatStream OutputStream PlayerInfo}
      end
      Port
   end

   %%%%%%%%%%%%%%%%%%%Functions and procedures usefull for TreatStream

   /* 
    * Make PlayerInfo spawn on the board if appropriate
    * @NewPlayer is bound to the updated version of the PlayerInfo is it could spawn,
    *            is bound to null otherwise
    */
   proc{MakeSpawn PlayerInfo NewPlayer}
      ifPlayerInfo.state == off && PlayerInfo.lives > 0 then
         %TODO Make spawn. Est-ce qu'il faut faire quelque chose en plus???
         NewPlayer = infos(id: PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombes score:PlayerInfo.score state:on currentPos:PlayerInfo.initPos initPos:PlayerInfo.initPos)
      else
         NewPlayer = null
      end
   end

   /*
    * Return the value corresponding to the type of tile in position X Y (1,2,3 or 4)
    */
   %Ne gère pas le cas où on arrive à la fin de la liste. Cela ne devrait jamais arriver car le player est toujours arrêté par un mur avant
   fun {CheckTile Map X Y}
      fun {Iterate Acc L}
         case L of H|T then
            if Acc == 1 then H
            else
               {Iterate Acc-1 T}
            end
         end
      end
      in
         {Iterate Y {Iterate X Map}}
   end

   /*
    * Take a player in argument and return a player that has moved in a rondaom direction, avoiding walls
    * @NewPlayer: Updated version of PlayerInfo where currentPos has been updated regarding the new position
    */
   %Cas limite: Tourne en boucle si un player se trouve entouré uniquement de murs (possible si map mal faite et spawn à cet endroit là)
   proc{MoveRandom PlayerInfo NewPlayer}
      local
      NewPos Rand
      fun{GetNewPos Pos Dir}{
         declare TryPos
         if Dir == 0 then
            TryPos = pos(x:PlayerInfo.currentPos.x+1 y=PlayerInfo.currentPos.y)
         elseif Dir == 1 then
            TryPos = pos(x:PlayerInfo.currentPos.x y=PlayerInfo.currentPos.y+1)
         elseif Dir == 2 then
            TryPos = pos(x:PlayerInfo.currentPos.x-1 y=PlayerInfo.currentPos.y)
         elseif Dir == 1 then
            TryPos = pos(x:PlayerInfo.currentPos.x y=PlayerInfo.currentPos.y-1)
         end
         if({CheckTile Input.map TryPos.x TryPos.y} == 1) then %The wanted direction is a wall, need to change direction
            {TryStep Pos ((Dir+1) mod 4)}
         else %It is possible to go in the wanted direction
            TryPos
         end
      }
      in
         Rand = {os.rand} mod 4
         NewPos = {GetNewPos PlayerInfo.currentPos Rand}
         NewPlayer = infos(id: PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombes score:PlayerInfo.score state:PlayerInfo.state currentPos:NewPos initPos:PlayerInfo.initPos)
   end

   /*
    * Drop a bomb if possible in 0.1 of the case
    * Move randomly in a non-wall direction in 0.9 other case or if there is no bomb left
    * @NewPlayer: is bound to the updated version of PlayerInfo
    *             currentPos is updated to new position if the player has moved
    *             bombes is decreased by one if a bomb was droped
    * @Action: is bound to bomb(PlayerInfo.currentPos) if a bomb was drop and
    *          is bound to move(pos) where pos is the new player position
    */
   proc{DoAction PlayerInfo Action NewPlayer}
      if PlayerInfo.state == off then
         Action = null
         NewPlayer = PlayerInfo
      else
         if({os.rand} mod 10) == 0 then % chance of 0.1 to drop a bomb
            if PlayerInfo.bombes > 0 then
               Action = bomb(PlayerInfo.currentPos)
               NewPlayer = infos(id: PlayerInfo.id lives:PlayerInfo.lives bombs:(PlayerInfo.bombes-1) score:PlayerInfo.score state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos)
            else
               {MoveRandom PlayerInfo NewPlayer}
               Action = move(NewPlayer.currentPos)
            end
         else % chance of 0.9 to move
            {MoveRandom PlayerInfo NewPlayer}
            Action = move(NewPlayer.currentPos)
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
         NewPlayer = infos(id: PlayerInfo.id lives:PlayerInfo.lives bombs:(PlayerInfo.bombes+1) score:PlayerInfo.score state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos)
         Result = NewPlayer.bombes
      else if Type == point then
         NewPlayer = infos(id: PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombes score:(PlayerInfo.score+Option) state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos)
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
         NewPlayer = infos(id: PlayerInfo.id lives:(PlayerInfo.lives-1) bombs:PlayerInfo.bombes score:PlayerInfo.score state:off currentPos:PlayerInfo.currentPos initPos:PlayerInfo.initPos)
      end
   end
   
   %%%%%%%%%%%%%%%%Treatmen and handling of received messages

   proc{TreatStream Stream PlayerInfo} %% TODO you may add some arguments if needed
     case Stream of nil then skip
     []Head|Tail then
      case Head of getId(BomberID) then
         BomberID = PlayerInfo.id
         {TreatStream Tail PlayerInfo}
      []getState(BomberID BomberState) then
         BomberID = PlayerInfo.id
         BomberState = PlayerInfo.state
         {TreatStream Tail PlayerInfo}
      []assignSpawn(Pos) then
         NewInfo = infos(id: PlayerInfo.id lives:PlayerInfo.lives bombs:PlayerInfo.bombes score: PlayerInfo.score state:PlayerInfo.state currentPos:PlayerInfo.currentPos initPos:Pos)
         {TreatStream Tail PlayerInfo} %TODO Est-ce que cette position a été vérifiée comme possible?
      []spawn(BomberID BomberPos) then
         declare NewPlayer
         {MakeSpawn PlayerInfo NewPlayer}
         ifNewPlayer != null then %Bomber could spawn
            BomberID = PlayerInfo.id
            BomberPos = PlayerInfo.currentPos
         else %Bomber could not spawn
            BomberID = null
            BomberPos = null
         end
         {TreatStream Tail NewPlayer}
      []doaction(BomberID BomberAction) then
         declare NewPlayer
         {DoAction PlayerInfo BomberAction NewPlayer}
         if BomberAction == null then %The player is of the board and no action could be done
            BomberID = null
         else
            BomberID = NewPlayer.id
         {TreatStream Tail NewPlayer}
      []add(Type Option BomberResult) then
         declare NewPlayer
         {AddObject Type Option PlayerInfo NewPlayer BomberResult}
         {TreatStream Tail NewPlayer}
      []gotHit(BomberID BomberResult) then
         declare NewPlayer
         {TakeHit PlayerInfo NewPlayer}
         BomberResult = death(NewPlayer.lives)
         {TreatStream Tail NewPlayer}
      []info(M) then
         %TODOOOO Create a function for that
      end
   end

  
	/*proc {TreatStream Stream }
		case Stream
		of Msg|Stail then
			{TreatStream Stail}
		else skip %something went wrong
		end
	end*/
   

end
