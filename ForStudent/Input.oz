functor
import
   OS
   System
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
   namesBombers:NamesBombers
   nbLives:NbLives
   nbBombs:NbBombs
   thinkMin:ThinkMin
   thinkMax:ThinkMax
   fire:Fire
   timingBomb:TimingBomb
   timingBombMin:TimingBombMin
   timingBombMax:TimingBombMax
   %% Not gived
   nbBoxes:NbBoxes
   mapDescription:MapDescription

define
   NewRow
   NewColumn
   NbRow
   CountMapBoxes
   CountBoxesInList
   NbColumn
   IsTurnByTurn UseExtention PrintOK
   NbRow NbColumn Map MapDescription NbBoxes
   NbBombers Bombers ColorBombers NamesBombers
   NbLives NbBombs
   ThinkMin ThinkMax
   TimingBomb TimingBombMin TimingBombMax Fire
   
in 


%%%% Style of game %%%%
   
   IsTurnByTurn = true
   UseExtention = false
   PrintOK = true


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

   
 
 fun {CountBoxesInList List Row Column BoxPointPosition BoxBonusPosition FloorSpwan}
      case List 
       of nil then dscrpt(boxPointPosition:BoxPointPosition boxBonusPosition:BoxBonusPosition floorSapwan:FloorSpwan)
       [] H|T then 
          if (H == 2)     then {CountBoxesInList T Row Column+1 {Append BoxPointPosition [pt(x:Column y:Row)]} BoxBonusPosition FloorSpwan}
          elseif (H == 3) then {CountBoxesInList T Row Column+1 BoxPointPosition {Append BoxBonusPosition [pt(x:Column y:Row)]} FloorSpwan}
          elseif (H == 4) then {CountBoxesInList T Row Column+1 BoxPointPosition  BoxBonusPosition {Append FloorSpwan [pt(x:Column y:Row)]}} 
          else {CountBoxesInList T Row Column+1 BoxPointPosition BoxBonusPosition FloorSpwan}
          end 
      end  
   end

   fun {CountMapBoxes Map Row Dscrpt} 
     case Map
       of nil then Dscrpt
       [] H|T then {CountMapBoxes T Row+1 {CountBoxesInList H Row 1 Dscrpt.boxPointPosition Dscrpt.boxBonusPosition Dscrpt.floorSapwan}}
     end
   end

  NbRow = 7
  NbColumn = 13
  Map = [
     [1 1 1 1 1 1 1 1 1 1 1 1 1]
	  [1 4 0 0 2 2 2 2 2 2 0 4 1]
	  [1 0 1 3 1 2 1 2 1 2 1 0 1]
	  [1 0 2 2 3 2 2 2 2 3 2 2 1]
	  [1 0 1 2 1 2 1 3 1 2 1 0 1]
	  [1 4 0 2 2 2 2 0 0 0 0 4 1]
	  [1 1 1 1 1 1 1 1 1 1 1 1 1]
     ]

   %%%%%%%%% ATTENTION %%%%%%%%%%
   %Map = {NewRow NbRow} % this is the call for random map,  then random map need somme fix bug 
 
  MapDescription= {CountMapBoxes Map 1 dscrpt(boxPointPosition:nil boxBonusPosition:nil floorSapwan:nil)} 
  NbBoxes = {Length MapDescription.boxPointPosition } + {Length MapDescription.boxBonusPosition}

%%%% Players description %%%%

   NbBombers = 2
   Bombers = [player000bomber player000bomber ]
   ColorBombers = [yellow red blue]
   NamesBombers = [lary alba github]

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
