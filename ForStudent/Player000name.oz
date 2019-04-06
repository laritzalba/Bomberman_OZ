functor
import
   Input
   Browser
   Projet2019util
export
   portPlayer:StartPlayer
define   
   StartPlayer
   TreatStream
   Name = 'namefordebug'

in
   fun{StartPlayer ID}
      Stream Port OutputStream
   in
      thread %% filter to test validity of message sent to the player
         OutputStream = {Projet2019util.portPlayerChecker Name ID Stream}
      end
      {NewPort Stream Port}
      thread
	 {TreatStream OutputStream}
      end
      Port
   end

   
   proc{TreatStream Stream} %% TODO you may add some arguments if needed
      %% TODO complete
   end
   

end
