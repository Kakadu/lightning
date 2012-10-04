type glow = {
  glowSize : int;
  glowColor : int;
  glowStrength : float;
  glowKind : [= `linear | `soft ];
};

value glow :
  ?kind:[= `linear | `soft ] ->
          ?size:int -> ?strength:float -> int -> [> `Glow of glow ] ;
type colorMatrix;
value colorMatrix : array float -> [> `ColorMatrix of Render.filter ] ;
type t = [= `ColorMatrix of Render.filter | `Glow of glow ];
value string_of_t : [< `ColorMatrix of 'a | `Glow of glow ] -> string;
