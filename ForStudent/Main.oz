functor
import
   System
   OS
   Browser  
   GUI
   Input
   PlayerManager
  
define
  PortPlayer
  PortWindow

in
 {System.show 'Start'}
 
 PortWindow = {GUI.portWindow}
 {Send PortWindow buildWindow}


end
