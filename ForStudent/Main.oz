functor
import
   System
   OS  
   GUI
   Input
   PlayerManager
  
define
  Show
  PortPlayer
  PortWindow
  PortBombers

  NewBombers
  Init_Show_Bombers
  RandomPosition

in
  %%% TOOLS %%%%
  proc {Show Msg}
		{System.show Msg}
	end
 %%% END TOOLS %%%%


   fun {NewBombers Count BombersList}
      if Input.nbBombers < Count then BombersList
      else
         local ThisPlayer in
            ThisPlayer = {PlayerManager.playerGenerator {Nth Input.bombers Count} 
                              bomber(id:Count 
                                       color:{Nth Input.colorsBombers Count} 
                                       name:{Nth Input.namesBombers Count})
                           }
            {NewBombers Count+1 ThisPlayer|BombersList}
         end
      end
   end


  fun {RandomPosition}
    % (Math.random() * ((max - min) + 1)) + min
     pt(x:({OS.rand} mod Input.nbColumn) y:({OS.rand} mod Input.nbRow))
     % TO DO 
     % Verify if this position is not a wall or box or other 
  end


   proc {Init_Show_Bombers PortBombers}
	   case PortBombers
      of nil then skip 
	   [] H|T then ID Position in
             % Init 
            {Send H assignSpawn({RandomPosition})}
            {Send H spawn(ID Position)}
            {Wait ID}
            {Wait Position}
             % Show 
            {Send PortWindow initPlayer(ID)}
            {Send PortWindow spawnPlayer(ID Position)}
            {Init_Show_Bombers T}
	   end
	end

   




 
 %%%%%%%%%%%%%%%%%%%%%%% Main %%%%%%%%%%%%%%%%%%%%%%%
 PortWindow = {GUI.portWindow}
 {Send PortWindow buildWindow}
 
 PortBombers = {NewBombers 1 nil}

 {Init_Show_Bombers PortBombers}





end

