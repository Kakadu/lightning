
type eventType = [= DisplayObject.eventType | `TOUCH | `ENTER_FRAME | `TIMER  | `TIMER_COMPLETE ];
type eventData = [= DisplayObject.eventData | `Touches of list Touch.t | `PassedTime of float ];



module Make(D:DisplayObjectT.M with type evType = private [> eventType ] and type evData = private [> eventData ]) : sig
  type tween = < process: float -> bool >;
  value addTween: tween -> unit;

  class virtual c: [ float ] -> [ float ] ->
    object
      inherit D.container;
      value virtual color: int;
      method createTimer: ?repeatCount:int -> float -> Timer.c D.evType D.evData;
      method processTouches: list Touch.t -> unit;
      method advanceTime: float -> unit;
    end;
end;
