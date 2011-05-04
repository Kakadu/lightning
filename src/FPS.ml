
module Make(D:DisplayObjectT.M with type evType = private [> `ENTER_FRAME | DisplayObjectT.eventType ] and type evData = private [> `PassedTime of float | DisplayObjectT.eventData] )= struct

  module TextField = TextField.Make D;

class c ?fontSize ?color () = 
  object(self)
    inherit TextField.c ?fontSize ?color ~width:100. ~height:30. "";
    value mutable frames = 0;
    value mutable time = 0.;

    initializer self#addEventListener `ENTER_FRAME self#onEnterFrame;

    method private onEnterFrame event = 
      match event.Event.data with
      [ `PassedTime dt -> 
        let osecs = int_of_float time in
        (
          time := time +. dt;
          let seconds = (int_of_float time) - osecs in
          match seconds with
          [ 0 ->  frames := frames + 1
          | _ -> 
            (
              self#setText (string_of_int (frames / seconds));
              frames := 1;
            )
          ]
        )
      | _ -> assert False
      ];

  end;

value create = new c;

end;
