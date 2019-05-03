functor
import
   Player000bomber
   Player000basic
   Player000simultaneous
   Player000survivor
   
   %Players for interoperability tests
   Player003John
   Random
   Player001name
   Player100advanced
   Player101advanced
   Player038Luigi
   %% Add here the name of the functor of a player
   %% Player000name
export
   playerGenerator:PlayerGenerator
define
   PlayerGenerator
in
   fun{PlayerGenerator Kind ID}
      case Kind
      of player000bomber then {Player000bomber.portPlayer ID}
      [] player000basic then {Player000basic.portPlayer ID}
      [] player000simultaneous then {Player000simultaneous.portPlayer ID}
      [] player000survivor then {Player000survivor.portPlayer ID}
      %Players for interoperability tests:
      [] player003John then {Player003John.portPlayer ID}
      [] random then {Random.portPlayer ID}
      [] player001name then {Player001name.portPlayer ID}
      [] player100advanced then {Player100advanced.portPlayer ID}
      [] player101advanced then {Player101advanced.portPlayer ID}
      [] player038Luigi then {Player038Luigi.portPlayer ID}
      %% Add here the pattern to recognize the name used in the 
      %% input file and launch the portPlayer function from the functor
      %%[] player000name then {Player000name.portPlayer ID}
      else
         raise 
            unknownedPlayer('Player not recognized by the PlayerManager '#Kind)
         end
      end
   end
end
