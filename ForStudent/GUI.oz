functor
import
   QTk at 'x-oz://system/wp/QTk.ozf'
   Input
   Browser
   Projet2019util
export
   portWindow:StartWindow
define
   
   StartWindow
   TreatStream

   InitPlayer  
   
   UpdateValue

   BuildWindow
   
   Squares
   Items
   DrawMap
   PrepareMap

   Spawn
   Hide
   Move
   ApplyTo
   ApplyToHandle
   ApplyToHandle2

   StateModification

in

%%%%% Build the initial window and set it up (call only once)
   fun{BuildWindow}
      Grid GridLife GridScore Toolbar Desc DescLife DescScore Window GridItems
   in
      Toolbar=lr(glue:we tbbutton(text:"Quit" glue:w action:toplevel#close))
      Desc=grid(handle:Grid height:50*Input.nbRow width:50*Input.nbColumn)
      DescLife=grid(handle:GridLife height:100 width:50*Input.nbBombers)
      DescScore=grid(handle:GridScore height:100 width:50*Input.nbBombers)
      Window={QTk.build td(Toolbar Desc DescLife DescScore)}
  
      {Window show}

      % configure rows and set headers
      for N in 1..Input.nbRow do
	 {Grid rowconfigure(N minsize:50 weight:0 pad:5)}
      end
      % configure columns and set headers
      for N in 1..Input.nbColumn do
	 {Grid columnconfigure(N minsize:50 weight:0 pad:5)}
      end
      % configure lifeboard
      {GridLife rowconfigure(1 minsize:50 weight:0 pad:5)}
      {GridLife columnconfigure(1 minsize:50 weight:0 pad:5)}
      {GridLife configure(label(text:"life" width:1 height:1) row:1 column:1 sticky:wesn)}
      for N in 1..(Input.nbBombers) do
	 {GridLife columnconfigure(N+1 minsize:50 weight:0 pad:5)}
      end
      % configure scoreboard
      {GridScore rowconfigure(1 minsize:50 weight:0 pad:5)}
      {GridScore columnconfigure(1 minsize:50 weight:0 pad:5)}
      {GridScore configure(label(text:"score" width:1 height:1) row:1 column:1 sticky:wesn)}
      for N in 1..(Input.nbBombers) do
	 {GridScore columnconfigure(N+1 minsize:50 weight:0 pad:5)}
      end
      
      {DrawMap Grid}
      GridItems = {PrepareMap Grid}
      handle(grid:Grid items:GridItems life:GridLife score:GridScore)
   end

   
%%%%% Squares of path and wall
   Squares = square(0:label(text:"" width:1 height:1 bg:c(0 0 204))
		    1:label(text:"" borderwidth:5 relief:raised width:1 height:1 bg:c(0 0 0))
		    2:label(text:"" width:1 height:1 bg:c(0 0 204))
		    3:label(text:"" width:1 height:1 bg:c(0 0 204))
		    4:label(text:"" width:1 height:1 bg:c(0 150 150))
		   )
   Items = items(boxpoint:fun{$ Handle} label(text:"" borderwidth:2 relief:raised width:3 height:2 bg:c(139 69 19) handle:Handle) end 
		 boxbonus:fun{$ Handle} label(text:"" borderwidth:2 relief:raised width:3 height:2 bg:c(210 105 30) handle:Handle) end 
		 point:fun{$ Handle} label(text:"" height:1 width:1 handle:Handle bg:white) end 
		 bonus:fun{$ Handle} label(text:"" height:1 width:1 handle:Handle bg:green) end 
		 bomb:fun{$ Handle} label(text:"" height:1 width:1 handle:Handle bg:black) end 
		 fire:fun{$ Handle} label(text:"" height:1 width:2 handle:Handle bg:red) end 
		)
   
%%%%% Function to draw the map
   proc{DrawMap Grid}
      proc{DrawColumn Column M N}
	 case Column
	 of nil then skip
	 [] T|End then
	    {Grid configure(Squares.T row:M column:N sticky:wesn)}
	    {DrawColumn End M N+1}
	 end
      end
      proc{DrawRow Row M}
	 case Row
	 of nil then skip
	 [] T|End then
	    {DrawColumn T M 1}
	    {DrawRow End M+1}
	 end
      end
   in
      {DrawRow Input.map 1}
   end

   fun{PrepareMap GridHandle}
      Res
      proc{CreateRemove Label Row Col Remove}
         {GridHandle configure(Label row:Row column:Col)}
         if (Remove) then 
            {GridHandle remove(Label.handle)}
         else
            {Label.handle 'raise'()}
         end
      end
      proc{PrepareColumn Column M N}
         case Column 
         of nil then skip
         [] 0|End then BombH FireH in
	    {CreateRemove {Items.bomb BombH} M N true}
	    {CreateRemove {Items.fire FireH} M N true}
            Res.M.N = items(box:null bonus:null point:null bomb:BombH fire:FireH)
            {PrepareColumn End M N+1}
         [] 1|End then
            Res.M.N = items(box:null bonus:null point:null bomb:null fire:null)
            {PrepareColumn End M N+1}
         [] 2|End then BoxH PointH BombH FireH  in
            {CreateRemove {Items.boxpoint BoxH} M N false}
            {CreateRemove {Items.point PointH} M N true}
	    {CreateRemove {Items.bomb BombH} M N true}
	    {CreateRemove {Items.fire FireH} M N true}
            Res.M.N = items(box:BoxH bonus:null point:PointH bomb:BombH fire:FireH)
            {PrepareColumn End M N+1}
         [] 3|End then BoxH BonusH BombH FireH  in
            {CreateRemove {Items.boxbonus BoxH} M N false}
            {CreateRemove {Items.bonus BonusH} M N true}
	    {CreateRemove {Items.bomb BombH} M N true}
	    {CreateRemove {Items.fire FireH} M N true}
            Res.M.N = items(box:BoxH bonus:BonusH point:null bomb:BombH fire:FireH)
            {PrepareColumn End M N+1}
         [] 4|End then BombH FireH in
	    {CreateRemove {Items.bomb BombH} M N true}
	    {CreateRemove {Items.fire FireH} M N true}
            Res.M.N = items(box:null bonus:null point:null bomb:BombH fire:FireH)
            {PrepareColumn End M N+1}
         end
      end
      proc{PrepareRow Row M}
	 case Row
	 of nil then skip
	 [] T|End then
            Res.M = {Tuple.make items Input.nbColumn} 
	    {PrepareColumn T M 1}
            {PrepareRow End M+1}
	 end
      end
   in
      Res = {Tuple.make items Input.nbRow} 
      {PrepareRow Input.map 1}
      Res
   end
%%%%% Init the Player
   fun{InitPlayer Grid ID}
      Handle HandleLife HandleScore Id Color LabelPlayer LabelLife LabelScore
   in
      bomber(id:Id color:Color name:_) = ID
      LabelPlayer = label(text:"P" handle:Handle borderwidth:5 relief:raised bg:Color ipadx:5 ipady:5)
      LabelLife = label(text:Input.nbLives borderwidth:5 handle:HandleLife relief:solid bg:Color ipadx:5 ipady:5)
      LabelScore = label(text:0 borderwidth:5 handle:HandleScore relief:solid bg:Color ipadx:5 ipady:5)
      {Grid.grid configure(LabelPlayer row:0 column:0 sticky:wesn)}
      {Grid.grid remove(Handle)}
      {Grid.life configure(LabelLife row:1 column:Id+1 sticky:wesn)}
      {Grid.score configure(LabelScore row:1 column:Id+1 sticky:wesn)}
      {HandleLife 'raise'()}
      {HandleScore 'raise'()}
      guiPlayer(id:ID life:HandleLife score:HandleScore player:Handle)
   end

   proc{UpdateValue Handle Life}
      {Handle set(Life)}
   end


   proc{ApplyTo Grid Pos Label Fun}
      Row Col Square
   in 
      Pos = pt(x:Col y:Row)
      Square = Grid.items.Row.Col.Label
      if (Square \= null) then
         {Fun Grid Square Row Col}
      end
   end
   proc{ApplyToHandle Grid Handle Pos Fun}
      Row Col
   in 
      Pos = pt(x:Col y:Row)
      {Fun Grid Handle Row Col}
   end
   proc{ApplyToHandle2 Grid Handle Fun}
      {Fun Grid Handle _ _}
   end

   proc{Spawn Grid Handle Row Col}
      {Grid.grid configure(Handle row:Row column:Col)}
      {Handle 'raise'()}
   end
   proc{Hide Grid Handle Row Col}
      {Grid.grid remove(Handle)}
   end
   proc{Move Grid Handle Row Col}
      {Hide Grid Handle Row Col}
      {Spawn Grid Handle Row Col}
   end
   
   
   fun{StateModification Grid Wanted State Fun}
      case State
      of nil then nil
      [] guiPlayer(id:ID life:_ score:_ player:_)|Next then
	 if (ID == Wanted) then
	    {Fun Grid State.1}|Next
	 else
	    State.1|{StateModification Grid Wanted Next Fun}
	 end
      end
   end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fun{StartWindow}
      Stream
      OutputStream
      Port
   in
      {NewPort Stream Port}
      thread
         OutputStream = {Projet2019util.portWindowChecker Stream}
      end
      thread
	 {TreatStream OutputStream nil nil}
      end
      Port
   end

   proc{TreatStream Stream Grid Players}
      {Browser.browse Stream.1}
      case Stream
      of nil then skip
      [] H|T then
         case H 
         of buildWindow then NewGrid in 
	    NewGrid = {BuildWindow}
	    {TreatStream T NewGrid {Tuple.make players Input.nbBombers}}
         [] initPlayer(ID) then
            Players.(ID.id) = {InitPlayer Grid ID}
	    {TreatStream T Grid Players}
         [] spawnPlayer(ID Pos) then
            {ApplyToHandle Grid Players.(ID.id).player Pos Spawn}
	    {TreatStream T Grid Players}
         [] movePlayer(ID Pos) then
            {ApplyToHandle Grid Players.(ID.id).player Pos Move}
	    {TreatStream T Grid Players}
         [] hidePlayer(ID) then
            {ApplyToHandle2 Grid Players.(ID.id).player Hide}
	    {TreatStream T Grid Players}
         [] lifeUpdate(ID Life) then
            {UpdateValue Players.(ID.id).life Life}
            {TreatStream T Grid Players}
         [] scoreUpdate(ID Score) then
            {UpdateValue Players.(ID.id).score Score}
            {TreatStream T Grid Players}
         [] spawnBonus(Pos) then
            {ApplyTo Grid Pos bonus Spawn}
	    {TreatStream T Grid Players}
         [] hideBonus(Pos) then
            {ApplyTo Grid Pos bonus Hide}
	    {TreatStream T Grid Players}
         [] spawnPoint(Pos) then
            {ApplyTo Grid Pos point Spawn}
	    {TreatStream T Grid Players}
         [] hidePoint(Pos) then
            {ApplyTo Grid Pos point Hide}
	    {TreatStream T Grid Players}
         [] spawnFire(Pos) then
            {ApplyTo Grid Pos fire Spawn}
	    {TreatStream T Grid Players}
         [] hideFire(Pos) then
            {ApplyTo Grid Pos fire Hide}
	    {TreatStream T Grid Players}
         [] spawnBomb(Pos) then
            {ApplyTo Grid Pos bomb Spawn}
	    {TreatStream T Grid Players}
         [] hideBomb(Pos) then
            {ApplyTo Grid Pos bomb Hide}
	    {TreatStream T Grid Players}
         [] hideBox(Pos) then
            {ApplyTo Grid Pos box Hide}
	    {TreatStream T Grid Players}
         [] displayWinner(ID) then
	    {Browser.browse 'the winner is '#ID}
         else
	    {Browser.browse 'unsupported message'#H}
	    {TreatStream T Grid Players}
         end
      end
   end
   
  

   
end
