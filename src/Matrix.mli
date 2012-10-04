type t = {
  a : float;
  b : float;
  c : float;
  d : float;
  tx : float;
  ty : float;
};
value identity : t;
value to_string : t -> string;
value create :
  ?rotation:float -> ?scale:(float * float) -> ?translate:Point.t -> unit -> t;
value scale : t -> (float * float) -> t;
value concat : t -> t -> t;
value rotate : t -> float -> t;
value translate : t -> (float * float) -> t;
value transformPoint : t -> Point.t -> Point.t;
value transformPoints : t -> array Point.t -> array float;
value transformRectangle : t -> Rectangle.t -> Rectangle.t;
value determinant : t -> float;
value invert : t -> t;
value scaleX : t -> float;
value scaleY : t -> float;
value rotation : t -> float;

