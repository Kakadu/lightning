type t = {
  texture : Texture.c;
  bounds : mutable Rectangle.t;
  clipping : Rectangle.t;
  width : float;
  height : float;
  pos : Point.t;
  color : LightCommon.color;
  alpha : float;
  flipX : bool;
  flipY : bool;
  scaleX : float;
  scaleY : float;
  rotation : float;
};
value create :
  Texture.c ->
  Rectangle.t ->
  ?pos:Point.t ->
  ?scaleX:float ->
  ?scaleY:float ->
  ?color:LightCommon.color ->
  ?flipX:bool -> ?flipY:bool -> ?alpha:float -> unit -> t;
value pos : t -> Point.t;
value x : t -> float;
value y : t -> float;
value setX : float -> t -> t;
value setY : float -> t -> t;
value setPos : float -> float -> t -> t;
value setPosPoint : Point.t -> t -> t;
value update :
  ?pos:Point.t ->
          ?scale:float -> ?color:LightCommon.color -> ?alpha:float -> t -> t;
value color : t -> LightCommon.color;
value setColor : LightCommon.color -> t -> t;
value alpha : t -> float;
value setAlpha : float -> t -> t;
value flipX : t -> bool;
value setFlipX : bool -> t -> t;
value flipY : t -> bool;
value setFlipY : bool -> t -> t;
value scaleX : t -> float;
value setScaleX : float -> t -> t;
value scaleY : t -> float;
value setScaleY : float -> t -> t;
value bounds : t -> Rectangle.t;
value width : t -> float;
value height : t -> float;
value texture : t -> Texture.c;

