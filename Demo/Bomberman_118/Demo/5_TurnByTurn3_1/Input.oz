functor
import % Extra
   OS  % Extra 
export
   isTurnByTurn:IsTurnByTurn
   useExtention:UseExtention
   printOK:PrintOK
   nbRow:NbRow
   nbColumn:NbColumn
   map:Map
   nbBombers:NbBombers
   bombers:Bombers
   colorsBombers:ColorBombers
   nbLives:NbLives
   nbBombs:NbBombs
   thinkMin:ThinkMin
   thinkMax:ThinkMax
   fire:Fire
   timingBomb:TimingBomb
   timingBombMin:TimingBombMin
   timingBombMax:TimingBombMax
define
   IsTurnByTurn UseExtention PrintOK
   NbRow NbColumn Map
   NbBombers Bombers ColorBombers
   NbLives NbBombs
   ThinkMin ThinkMax
   TimingBomb TimingBombMin TimingBombMax Fire
   %Extra
   NewColumn
   NewRow
   ReplaceValInList
   RandomPositionNotSpawn
   ReplaceValInList
   CreateMap
   RandomPositionNotSpawn
   DefaultMap
in 

%%%% Style of game %%%%
   
   IsTurnByTurn =true
   UseExtention = false
   PrintOK = false


%%%% Description of the map %%%%
     fun {NewColumn Count CountRow}
      if Count==0 then nil
       % map borders up and down 
      elseif (CountRow == 1) then 
          1|{NewColumn Count-1 CountRow}  % wall down (black and gray)
      elseif (CountRow == NbRow) then
           1|{NewColumn Count-1 CountRow}  % wall up (black and gray)
      else
         % map borders right and left 
         if (Count == NbColumn)then  
             1|{NewColumn Count-1 CountRow}  % wall left (black and gray)
         elseif (Count == 1) then 
             1|{NewColumn Count-1 CountRow}  % wall right (black and gray)
         else 
            % map not borders 
            local Random N in 
               N=4
               Random = ({OS.rand} mod 30)                  
               if (Random =< N) then
                  1|{NewColumn Count-1 CountRow}  % wall (black and gray)
               elseif (Random =<N+2) then 
                  2|{NewColumn Count-1 CountRow}  % box with points (orange light)
               elseif (Random =< N+5) then
                  3|{NewColumn Count-1 CountRow} % box with bonus (orange dark)
               elseif (Random =<N+6) then 
                  4|{NewColumn Count-1 CountRow} % flor with spawn (green blue)
               else
                  0|{NewColumn Count-1 CountRow} % simple floor (blue)
               end
            end
         end   
      end
   end
  
   fun {NewRow Count}
      if Count==0 then nil
      else
         {NewColumn NbColumn Count}|{NewRow Count-1}
      end
   end

    fun {RandomPositionNotSpawn}
    local X Y in
         X= ({OS.rand} mod (NbColumn-2))
         Y= ({OS.rand} mod (NbRow-2))
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

   % Create a random Map,  Attention --> NbRow >=3 and NbColumn >=3
   fun{CreateMap DefaultMap}
      Map RandPos
   in 
      if (UseExtention) then 
         Map = {NewRow NbRow} % this is the call for random map
         RandPos = {RandomPositionNotSpawn}
         {ReplaceValInList Map {ReplaceValInList {Nth Map RandPos.y} 4 RandPos.x 1} RandPos.y 1}
      else DefaultMap end  
    end

% 5) Turn by turn, no extensions, as many players as you want (your best one vs the one from the other groups you tested with) on a map as you want

   NbRow = 7
   NbColumn = 13

   %Map initiale
   DefaultMap = [[1 1 1 1 1 1 1 1 1 1 1 1 1]
                  [1 4 0 2 2 2 2 2 2 2 0 4 1]
                  [1 0 1 3 1 2 1 2 1 2 1 0 1]
                  [1 2 2 2 3 2 2 2 2 3 2 2 1]
                  [1 0 1 2 1 2 1 3 1 2 1 0 1]
                  [1 4 0 2 2 2 2 2 2 2 0 4 1]
                  [1 1 1 1 1 1 1 1 1 1 1 1 1]]
  

 /*DefaultMap =     [[1 1 1 1 1 1 1 1 1 1 1 1 1]
                  [1 4 0 0 4 0 0 4 0 0 0 4 1]
                  [1 0 1 3 1 2 1 2 0 2 0 0 1]
                  [1 2 1 3 1 2 2 2 2 3 2 2 1]
                  [1 0 1 2 1 1 1 1 1 2 1 0 1]
                  [1 0 1 0 2 0 0 2 2 2 0 0 1]
                  [1 1 1 1 1 1 1 1 1 1 1 1 1]]

*/

/*DefaultMap = [[1 1 1 1 1 1 1 1 1 1 1 1 1]
	  [1 4 0 0 0 0 0 0 0 0 0 4 1]
	  [1 0 0 0 0 0 0 0 0 0 1 0 1]
	  [1 0 0 2 3 2 2 2 2 3 2 2 1]
	  [1 0 0 0 0 0 0 0 0 0 0 0 1]
	  [1 4 0 0 0 2 2 0 0 0 0 4 1]
	  [1 1 1 1 1 1 1 1 1 1 1 1 1]]
*/

% Map to test if player avoid walls and boxes properly
/*DefaultMap = [[1 1 1 1 1 1 1 1 1 1 1 1 1]
	  [1 4 0 0 1 0 2 0 0 2 0 4 1]
	  [1 0 0 0 1 0 3 0 0 2 0 0 1]
	  [1 1 1 1 0 0 0 0 0 2 2 2 1]
	  [1 0 0 0 1 0 1 0 3 0 0 0 1]
	  [1 4 0 0 1 0 1 0 3 0 0 4 1]
	  [1 1 1 1 1 1 1 1 1 1 1 1 1]]
   
*/

   Map = {CreateMap DefaultMap}

 

%%%% Players description %%%%

   NbBombers = 4
   Bombers = [player000simultaneous player000simultaneous player000simultaneous player003John]
   ColorBombers = [blue red yellow green] 
   %player000simultaneous
   %player000survivor
   %player003John
   %random
   %player001name
   %player100advanced
   %player101advanced
   %player038Luigi

%%%% Parameters %%%%

   NbLives = 3
   NbBombs = 2
 
   ThinkMin = 50  % in millisecond
   ThinkMax = 200 % in millisecond
   
   Fire = 3
   TimingBomb = 12
   TimingBombMin = 3000 % in millisecond
   TimingBombMax = 4000 % in millisecon
end
