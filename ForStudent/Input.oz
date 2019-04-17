functor
import
   OS
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
   NewRow
   NewColumn
   CheckBoxPosition
   NbRow
   NbColumn
   IsTurnByTurn UseExtention PrintOK
   NbRow NbColumn Map
   NbBombers Bombers ColorBombers
   NbLives NbBombs
   ThinkMin ThinkMax
   TimingBomb TimingBombMin TimingBombMax Fire
in 


%%%% Style of game %%%%
   
   IsTurnByTurn = true
   UseExtention = false
   PrintOK = true


%%%% Description of the map %%%%
   
   NbRow = 13
   NbColumn = 13

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
               N=6
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

   Map = {NewRow NbRow}

   /*
   fun{CheckBoxPosition Map} 
    % TO DO
    
      at least one size is not wall
      the map may be cut in two parts
      there is not accesible points 
      Check all possiblities    
    
   end
   */
  
  /* Map = [
     [1 1 1 1 1 1 1 1 1 1 1 1 1]
	  [1 4 0 2 2 2 2 2 2 2 0 4 1]
	  [1 0 1 3 1 2 1 2 1 2 1 0 1]
	  [1 2 2 2 3 2 2 2 2 3 2 2 1]
	  [1 0 1 2 1 2 1 3 1 2 1 0 1]
	  [1 4 0 2 2 2 2 2 2 2 0 4 1]
	  [1 1 1 1 1 1 1 1 1 1 1 1 1]
     ]
  */
%%%% Players description %%%%

   NbBombers = 2
   Bombers = [player000bomber player000bomber]
   ColorBombers = [yellow red]

%%%% Parameters %%%%

   NbLives = 3
   NbBombs = 1
 
   ThinkMin = 500  % in millisecond
   ThinkMax = 2000 % in millisecond
   
   Fire = 3
   TimingBomb = 3 
   TimingBombMin = 3000 % in millisecond
   TimingBombMax = 4000 % in millisecond

end
