
module type S = sig
  module D: DisplayObjectT.M;
  class c :  [ ?fontName:string ] -> [ ?fontSize:int ] -> [ ?color:int ] -> [ ~width:float ] -> [ ~height:float ] -> [ string ] ->
  object
    inherit D.container;
    method setText: string -> unit;
    method setFontName: string -> unit;
    method setFontSize: option int -> unit;
    method setBorder: bool -> unit;
    method setColor: int -> unit;
    method setHAlign: LightCommon.halign -> unit;
    method setVAlign: LightCommon.valign -> unit;
    method textBounds: Rectangle.t;
  end;


  value create: ?fontName:string -> ?fontSize:int -> ?color:int -> ~width:float -> ~height:float -> string -> c;
end;


module Make(Quad:Quad.S)(FontCreator:BitmapFont.Creator with module Sprite.D = Quad.D): S with module D = Quad.D;
