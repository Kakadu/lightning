
type eventType = [= `ADDED | `ADDED_TO_STAGE | `REMOVED | `REMOVED_FROM_STAGE | `ENTER_FRAME ]; 
type eventData = [= Ev.dataEmpty | `PassedTime of float ];

(* {{{
class type virtual _c' [ 'evType, 'evData, 'parent ] =
  object('self)
    type 'displayObject = _c' 'evType 'evData 'parent;
    type 'parent = 
      < 
        asDisplayObject: _c' _ _ _; removeChild': _c' _ _ _-> unit; dispatchEvent': !'ct. Event.t 'evType 'evData 'displayObject (< .. > as 'ct) -> unit; 
        name: string; transformationMatrixToSpace: !'space. option (<asDisplayObject: _c' _ _ _; ..> as 'space) -> Matrix.t; stage: option 'parent; height: float; modified: unit -> unit; .. >;
(*     inherit EventDispatcher.c [ 'event_type, 'event_data , _c _ _ _, _]; *)

    type 'event = Event.t 'evType 'evData 'displayObject 'self;
    type 'listener = 'event -> int -> unit;
    method addEventListener: 'evType -> 'listener -> int;
    method removeEventListener: 'evType -> int -> unit;
    method dispatchEvent': !'ct. Event.t 'evType 'evData 'displayObject (< .. > as 'ct) -> unit;
    method dispatchEvent: !'ct. Event.t 'evType 'evData 'displayObject (< .. > as 'ct) -> unit;
    method hasEventListeners: 'evType -> bool;

    value name: string;
    method name: string;
    method setName: string -> unit;
    value transformPoint: Point.t;
    method setTransformPoint: Point.t -> unit;
    value x:float;
    method x: float;
    method setX: float -> unit;
    value y:float;
    method y: float;
    method setY: float -> unit;
    method pos: Point.t;
    method setPos: Point.t -> unit;
    method width: float;
    method setWidth: float -> unit;
    method height: float;
    method setHeight: float -> unit;
    value scaleX:float;
    method scaleX: float;
    method setScaleX: float -> unit;
    value scaleY:float;
    method scaleY: float;
    method setScaleY: float -> unit;
    method setScale: float -> unit;
    value alpha:float;
    method alpha: float;
    method setAlpha: float -> unit;
    method rotation: float;
    method setRotation: float -> unit;
    method setAlpha: float -> unit;
    value visible: bool;
    method visible: bool;
    method setVisible: bool -> unit;
    value touchable: bool;
    method touchable: bool;
    method setTouchable: bool -> unit;
    value parent: option 'parent;
    method parent: option 'parent;
    method removeFromParent: unit -> unit;
    method private hitTestPoint': Point.t -> bool -> option (_c' _ _ _);
    method hitTestPoint: Point.t -> bool -> option (_c' _ _ _) ;
    method virtual bounds: Rectangle.t;
    method transformGLMatrix: unit -> unit;
    method transformationMatrix: Matrix.t;
    method transformationMatrixToSpace: !'space. option (<asDisplayObject: 'displayObject; ..> as 'space) -> Matrix.t;
    method virtual boundsInSpace: !'space. option (<asDisplayObject: 'displayObject; ..> as 'space) -> Rectangle.t;
    method globalToLocal: Point.t -> Point.t;
    method localToGlobal: Point.t -> Point.t;
    method setMask: ?onSelf:bool -> Rectangle.t -> unit;
    method virtual private render': option Rectangle.t -> unit;
    method render: option Rectangle.t -> unit;
    method asDisplayObject: _c' 'evType 'evData 'parent;
    method virtual dcast: [= `Object of _c' _ _ _ | `Container of 'parent ];
    method root: _c' _ _ _;
    method stage: option 'parent;
    method modified: unit -> unit;

    (* need to be hidden *)
    method clearParent: unit -> unit;
    method setParent: 'parent -> unit;
  end;


class type virtual container [ 'evType, 'evData ]=
  object
    inherit _c' [ 'evType,'evData,container 'evType 'evData ] ;
    type 'displayObject = _c' 'evType 'evData (container 'evType 'evData);

    method dcast: [= `Object of 'displayObject | `Container of (container 'evType 'evData) ];

    method bounds: Rectangle.t;
    method asDisplayObjectContainer: container 'evType 'evData;
    method children: Enum.t 'displayObject;
    method addChild: !'child. ?index:int -> (#_c' 'evType 'evData (container 'evType 'evData) as 'child) -> unit;
    method containsChild: !'child. (#_c' 'evType 'evData (container 'evType 'evData) as 'child) -> bool;
    method getChildAt: int -> 'displayObject;
    method getLastChild: 'displayObject;
    method numChildren: int;
    method removeChild: !'child. (#_c' 'evType 'evData (container 'evType 'evData) as 'child) -> unit;
    method removeChildAtIndex: int -> unit;
    (* need to be hidden *)
    method removeChild': 'displayObject -> unit;
    method containsChild': 'displayObject -> bool;
    method clearChildren: unit -> unit;
    method dispatchEventOnChildren: !'ct. Event.t 'evType 'evData 'displayObject (< .. > as 'ct) -> unit;
    method boundsInSpace: !'space. option (<asDisplayObject: 'displayObject; ..> as 'space) -> Rectangle.t;
    method private render': option Rectangle.t -> unit;
    method private hitTestPoint': Point.t -> bool -> option ('displayObject);
    method renderPrepare: unit -> unit;
  end;


class type virtual c ['evType,'evData]=
  object
    inherit _c'   ['evType,'evData,container 'evType 'evData ];
    method dcast: [= `Object of c 'evType 'evData | `Container of container 'evType 'evData ];
    method bounds: Rectangle.t;
  end;
}}} *)

module type M = sig

type hidden 'a;
type evType = private [> eventType ];
type evData = private [> eventData ];

value dispatchEnterFrame: float -> unit;
class virtual _c [ 'parent ] : (*  _c' [evType,evData,'parent];  =  *)

  object('self)
    type 'displayObject = _c 'parent;
    type 'parent = 
      < 
        asDisplayObject: _c _; removeChild': _c _ -> unit; dispatchEvent': !'ct. Ev.t evType evData _ (< .. > as 'ct) -> unit; 
        name: string; transformationMatrixToSpace: !'space. option (<asDisplayObject: _c _; ..> as 'space) -> Matrix.t; stage: option 'parent; height: float; modified: unit -> unit; .. >;
(*     inherit EventDispatcher.c [ 'event_type, 'event_data , _c _ _ _, _]; *)

    type 'event = Ev.t evType evData 'displayObject 'self;
    type 'listener = 'event -> int -> unit;
    method addEventListener: evType -> 'listener -> int;
    method removeEventListener: evType -> int -> unit;
    method dispatchEvent: ! 't 'ct. Ev.t evType evData ( < .. > as 't) (< .. > as 'ct) -> unit;
    method dispatchEvent': !'ct. Ev.t evType evData 'displayObject (< .. > as 'ct) -> unit;
    method hasEventListeners: evType -> bool;

    value name: string;
    method name: string;
    method setName: string -> unit;
    value transformPoint: Point.t;
    method transformPointX: float;
    method setTransformPointX: float -> unit;
    method transformPointY: float;
    method setTransformPointY: float -> unit;
    method transformPoint: Point.t;
    method setTransformPoint: Point.t -> unit;
    value x:float;
    method x: float;
    method setX: float -> unit;
    value y:float;
    method y: float;
    method setY: float -> unit;
    method pos: Point.t;
    method setPos: Point.t -> unit;
    method width: float;
    method setWidth: float -> unit;
    method height: float;
    method setHeight: float -> unit;
    value scaleX:float;
    method scaleX: float;
    method setScaleX: float -> unit;
    value scaleY:float;
    method scaleY: float;
    method setScaleY: float -> unit;
    method setScale: float -> unit;
    value alpha:float;
    method alpha: float;
    method setAlpha: float -> unit;
    method rotation: float;
    method setRotation: float -> unit;
    method setAlpha: float -> unit;
    value visible: bool;
    method visible: bool;
    method setVisible: bool -> unit;
    value touchable: bool;
    method touchable: bool;
    method setTouchable: bool -> unit;
    value parent: option 'parent;
    method parent: option 'parent;
    method removeFromParent: unit -> unit;
    method private hitTestPoint': Point.t -> bool -> option (_c _);
    method hitTestPoint: Point.t -> bool -> option (_c _) ;
    method virtual bounds: Rectangle.t;
    method transformGLMatrix: unit -> unit;
    method transformationMatrix: Matrix.t;
    method transformationMatrixToSpace: !'space. option (<asDisplayObject: 'displayObject; ..> as 'space) -> Matrix.t;
    method virtual boundsInSpace: !'space. option (<asDisplayObject: 'displayObject; ..> as 'space) -> Rectangle.t;
    method globalToLocal: Point.t -> Point.t;
    method localToGlobal: Point.t -> Point.t;
    method setMask: ?onSelf:bool -> Rectangle.t -> unit;
    method virtual private render': option Rectangle.t -> unit;
    method render: option Rectangle.t -> unit;
    method asDisplayObject: _c _;
    method virtual dcast: [= `Object of _c _ | `Container of 'parent ];
    method root: _c _;
    (* need to be hidden *)
    method clearParent: hidden unit -> unit;
    method setParent: hidden 'parent -> unit;
    method stage: option 'parent;
    method modified: unit -> unit;
  end;



class virtual container:
  object
    inherit _c [ container ];
    type 'displayObject = _c container;

    method dcast: [= `Object of 'displayObject | `Container of container ];

    method bounds: Rectangle.t;
    method asDisplayObjectContainer: container;
    method children: Enum.t 'displayObject;
    method addChild: !'child. ?index:int -> (#_c container as 'child) -> unit;
    method containsChild: !'child. (#_c container as 'child) -> bool;
    method getChildAt: int -> 'displayObject;
    method getLastChild: 'displayObject;
    method numChildren: int;
    method removeChild: !'child. (#_c container as 'child) -> unit;
    method removeChildAtIndex: int -> unit;
    (* need to be hidden *)
    method removeChild': 'displayObject -> unit;
    method containsChild': 'displayObject -> bool;
    method clearChildren: unit -> unit;
    method dispatchEventOnChildren: !'ct. Ev.t evType evData 'displayObject (< .. > as 'ct) -> unit;
    method boundsInSpace: !'space. option (<asDisplayObject: 'displayObject; ..> as 'space) -> Rectangle.t;
    method private render': option Rectangle.t -> unit;
    method private hitTestPoint': Point.t -> bool -> option ('displayObject);
    method renderPrepare: unit -> unit;
  end;


class virtual c:
  object
    inherit _c  [ container ];
    method dcast: [= `Object of c | `Container of container ];
    method bounds: Rectangle.t;
  end;
end;
