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

   
   %proc{TreatStream Stream} %% TODO you may add some arguments if needed
     
     
   %end

  
	proc {TreatStream Stream }
		case Stream
		of Msg|Stail then
			{TreatStream Stail}
		else skip %something went wrong
		end
	end
   

end
