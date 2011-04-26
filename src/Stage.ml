
open Touch;


type eventType = [= DisplayObject.eventType | `TOUCH ];
type eventData 'event_type 'event_data = [= Event.dataEmpty | `Touch of (list (Touch.et 'event_type 'event_data)) ];


exception Restricted_operation;

module TimersQueue = PriorityQueue.Make (struct type t = (float*int); value order (t1,_) (t2,_) = t1 >= t2; end);

class type inner_timer ['event_type,'event_data] = 
  object
    inherit Timer.c  ['event_type,'event_data];
    method fire: unit -> unit;
  end;

class c ['event_type,'event_data ] (width:float) (height:float) =
  object(self)
    inherit DisplayObject.container ['event_type,'event_data ] as super;
    method! width = width;
    method! setWidth _ = raise Restricted_operation;
    method! height = height;
    method! setHeight _ = raise Restricted_operation;
    method! setX _ = raise Restricted_operation;
    method! setY _ = raise Restricted_operation;
    method! setScaleX _ = raise Restricted_operation;
    method! setScaleY _ = raise Restricted_operation;
    method! setRotation _ = raise Restricted_operation;

    value mutable currentTouches = [];

    method! isStage = True;

    value mutable time = 0.;
    value mutable timerID = 0;
    value timersQueue = TimersQueue.make ();
    value timers : Hashtbl.t int (inner_timer 'event_type 'event_data) = Hashtbl.create 0;

    method createTimer ?(repeatCount=0) delay = 
      let o = 
        object(timer)
          type 'timer = Timer.c 'event_type 'event_data;
          inherit EventDispatcher.simple ['event_type,'event_data,'timer];
          value id = let id = timerID in (timerID := timerID + 1; id);
          value mutable running = False;
          value mutable currentCount = 0;
          method private bubbleEvent _ = ();
          method delay = delay;
          method repeatCount = repeatCount;
          method fire () = 
          (
            let event = Event.create `TIMER () in
            timer#dispatchEvent event; 
            currentCount := currentCount + 1;
            if repeatCount <= 0 || currentCount < repeatCount
            then
              TimersQueue.add timersQueue ((time +. delay),id)
            else 
              (
                running := False;
                Hashtbl.remove timers id;
                let event = Event.create `TIMER_COMPLETE () in
                timer#dispatchEvent event
              )
          );
          method start () = 
            match running with
            [ False ->
              (
                TimersQueue.add timersQueue ((time +. delay),id);
                Hashtbl.add timers id timer;
                currentCount := repeatCount;
                running := True
              )
            | True -> failwith "Timer alredy started"
            ];
          method stop () = 
            match running with
            [ True -> assert False
            | False -> failwith "Timer alredy stopped"
            ];
          method private asEventTarget = (timer : inner_timer _ _ :> Timer.c _ _);
          method reset () = assert False;
        end
      in
      (o :> Timer.c _ _ );

    method processTouches (touches:list Touch.t) = (*{{{*)
      let () = Printf.eprintf "process touches %d\n%!" (List.length touches) in
      let processedTouches = 
        List.fold_left begin fun processedTouches touch ->
          (*let () = 
            Printf.printf "touch: %f [%f:%f], [%f:%f], %d, %s\n%!" 
              touch.timestamp touch.globalX touch.globalY 
              touch.previousGlobalX touch.previousGlobalY
              touch.tapCount (string_of_touchPhase touch.phase)
          in*)
          let touch = 
            try
              let existingTouch =
                List.find begin fun existingTouch ->
                  (existingTouch.touch.globalX = touch.previousGlobalX && existingTouch.touch.globalY = touch.previousGlobalY) ||
                  (existingTouch.touch.globalX = touch.globalX && existingTouch.touch.globalY = touch.globalY)
                end currentTouches
              in
              match existingTouch.target with
              [ None -> {touch; target = self#hitTestPoint (touch.globalX,touch.globalY) True}
              | Some target when target#stage = None -> {touch; target = self#hitTestPoint (touch.globalX,touch.globalY) True} 
              | _ -> let () = print_endline "this is exists touch" in {touch; target = existingTouch.target}
              ]
            with [ Not_found -> {touch; target = self#hitTestPoint (touch.globalX,touch.globalY) True} ]
          in
          [ touch :: processedTouches ]
        end [] touches
      in
      (
        List.iter begin fun t ->
          let touch = t.touch in
          Printf.printf "touch: %f [%f:%f], [%f:%f], %d, %s, [ %s ]\n%!" 
            touch.timestamp touch.globalX touch.globalY 
            touch.previousGlobalX touch.previousGlobalY
            touch.tapCount (string_of_touchPhase touch.phase)
            (match t.target with [ None -> "none" | Some t -> t#name ])
        end processedTouches;
        let event = Event.create `TOUCH ~bubbles:True () in
        List.iter begin fun etouch ->
          match etouch.target with
          [ Some t -> 
            let event = {(event) with Event.data = `Touch (etouch.touch,processedTouches)} in
            t#dispatchEvent event
          | None -> ()
          ]
        end processedTouches;
        currentTouches := processedTouches;
      );(*}}}*)

    method !render () =
    (
      RenderSupport.clearTexture ();
      RenderSupport.clearWithColorAlpha 0x0 1.0;
      RenderSupport.setupOrthographicRendering 0. width height 0.;
      super#render();
      ignore(RenderSupport.checkForOpenGLError());
      (*
      #if DEBUG
      [SPRenderSupport checkForOpenGLError];
      #endif
      *)
    );

    method advanceTime (seconds:float) = 
    (
      time := time +. seconds;
      (* jugler here *)
      (* timers *)
      let rec run_timers () = 
        match TimersQueue.first timersQueue with
        [ (t,id) when t <= time ->
          (
            TimersQueue.remove_first timersQueue;
            let timer = Hashtbl.find timers id in
            timer#fire();
            run_timers ();
          )
        | _ -> ()
        ]
      in
      run_timers ();
      (* dispatch EnterFrameEvent *)
      let enterFrameEvent = Event.create `ENTER_FRAME ~data:(`PassedTime seconds) () in
      self#dispatchEventOnChildren enterFrameEvent;
    );

    method! hitTestPoint localPoint isTouch =
      match isTouch && (not visible || not touchable) with
      [ True -> None 
      | False ->
          match super#hitTestPoint localPoint isTouch with
          [ None -> (* different to other containers, the stage should acknowledge touches even in empty parts. *)
            let bounds = Rectangle.create x y width height in
            match Rectangle.containsPoint bounds localPoint with
            [ True -> Some self#asDisplayObject
            | False -> None
            ]
          | res -> res
          ]
      ];
    
  end;
