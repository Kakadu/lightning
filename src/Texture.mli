
type textureID = int;
type textureFormat = 
  [ TextureFormatRGBA
  | TextureFormatRGB
  | TextureFormatAlpha
  | TextureFormatPvrtcRGB2
  | TextureFormatPvrtcRGBA2
  | TextureFormatPvrtcRGB4
  | TextureFormatPvrtcRGBA4
  | TextureFormat565
  | TextureFormat5551
  | TextureFormat4444
  ];


class type c = 
  object
    method width: float;
    method height: float;
    method hasPremultipliedAlpha:bool;
    method scale: float;
    method textureID: textureID;
    method base : option c;
    method clipping: option Rectangle.t;
    method rootClipping: option Rectangle.t;
(*     method update: string -> unit; *)
    method release: unit -> unit;
    method subTexture: Rectangle.t -> c;
  end;



value create: textureFormat -> int -> int -> option (Bigarray.Array1.t int Bigarray.int8_unsigned_elt Bigarray.c_layout) -> c;
value load: string -> c;

type framebufferID;
class type rendered =
  object
    inherit c;
    method realWidth: int;
    method realHeight: int;
    method framebufferID: framebufferID;
    method resize: float -> float -> unit;
    method draw: (unit -> unit) -> unit;
    method clear: int -> float -> unit;
  end;

value glRGBA:int;
value glRGB:int;
value glAlpha:int;

value rendered: ?format:int -> ?color:int -> ?alpha:float -> float -> float -> rendered; (*object inherit c; method renderObject: !'a. (#renderObject as 'a) -> unit; end;*)
