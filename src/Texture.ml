open LightCommon;

type ubyte_array = Bigarray.Array1.t int Bigarray.int8_unsigned_elt Bigarray.c_layout;

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



type textureInfo = 
  {
    texFormat: textureFormat;
    realWidth: int;
    width: int;
    realHeight: int;
    height: int;
    numMipmaps: int;
    generateMipmaps: bool;
    premultipliedAlpha:bool;
    scale: float;
    textureID: textureID;
  };




type event = [= `RESIZE | `CHANGE ]; 

class type renderer = 
  object
    method onTextureEvent: event -> c -> unit;
  end
and c =
  object
    method width: float;
    method height: float;
    method hasPremultipliedAlpha:bool;
    method scale: float;
    method textureID: textureID;
    method base : option c; 
    method clipping: option Rectangle.t;
    method rootClipping: option Rectangle.t;
    method release: unit -> unit;
    method subTexture: Rectangle.t -> c;
    method addRenderer: renderer -> unit;
    method removeRenderer: renderer -> unit;
  end;


external loadTexture: textureInfo -> option ubyte_array -> textureInfo = "ml_loadTexture";

IFDEF SDL THEN

value loadImage ?(textureID=0) ~path ~contentScaleFactor = 
  let surface = Sdl_image.load (LightCommon.resource_path path) in
  let bpp = Sdl.Video.surface_bpp surface in
  let () = assert (bpp = 32) in
  let width = Sdl.Video.surface_width surface in
  let legalWidth = nextPowerOfTwo width in
  let height = Sdl.Video.surface_height surface in
  let legalHeight = nextPowerOfTwo height in
  let rgbSurface = Sdl.Video.create_rgb_surface [] legalWidth legalHeight bpp in
  (
    Sdl.Video.set_blend_mode surface Sdl.Video.BLENDMODE_NONE;
    Sdl.Video.blit_surface surface None rgbSurface None;
    Sdl.Video.free_surface surface;
    let textureInfo = 
      {
        texFormat = TextureFormatRGBA;
        realWidth = width;
        width = legalWidth;
        realHeight = height;
        height = legalHeight;
        numMipmaps = 0;
        generateMipmaps = False;
        premultipliedAlpha = False;
        scale = 2.0;
        textureID = textureID;
      }
    in
(*     let () = debug "loaded texture" (* : [%d:%d] -> [%d:%d] width height legalWidth legalHeight*) in *)
    let res = loadTexture textureInfo (Some (Sdl.Video.surface_pixels rgbSurface)) in
    (
      Sdl.Video.free_surface rgbSurface;
      res
    );
  );

ELSE IFDEF IOS THEN
external loadImage: ?textureID:textureID -> ~path:string -> ~contentScaleFactor:float -> textureInfo = "ml_loadImage";
(* external freeImageData: GLTexture.textureInfo -> unit = "ml_freeImageData"; *)
ELSE IFDEF ANDROID THEN
external loadImage: ?textureID:textureID -> ~path:string -> ~contentScaleFactor:float -> textureInfo = "ml_loadImage";
ENDIF;
ENDIF;
ENDIF;

module Cache = WeakHashtbl.Make (struct
  type t = string;
  value equal = (=);
  value hash = Hashtbl.hash;
end);


class type r = 
  object
    inherit c;
    method setTextureID: textureID -> unit;
    method retain: unit -> unit;
    method releaseSubTexture: unit -> unit;
  end;

class subtexture region baseTexture = 
  let tw = baseTexture#width
  and th = baseTexture#height in
  let clipping = Rectangle.create (region.Rectangle.x /. tw) (region.Rectangle.y /. th) (region.Rectangle.width /. tw) (region.Rectangle.height /. th) in
  let rootClipping = Rectangle.tm_of_t clipping in
  let () = 
    let open Rectangle in
    adjustClipping (baseTexture :> c) where
      rec adjustClipping texture =
        match texture#clipping with
        [ None -> ()
        | Some baseClipping ->
            (
              rootClipping.m_x := baseClipping.x +. rootClipping.m_x *. baseClipping.width;
              rootClipping.m_y := baseClipping.y +. rootClipping.m_y *. baseClipping.height;
              rootClipping.m_width := rootClipping.m_width *. baseClipping.width;
              rootClipping.m_height := rootClipping.m_height *. baseClipping.height;
              match texture#base with
              [ Some baseTexture -> adjustClipping baseTexture
              | None -> ()
              ]
            )
        ]
  in
  let rootClipping : Rectangle.t = Obj.magic rootClipping in
  let width = region.Rectangle.width
  and height = region.Rectangle.height in
  object(self)
    method width = width;
    method height = height;
    method textureID = baseTexture#textureID;
    method hasPremultipliedAlpha = baseTexture#hasPremultipliedAlpha;
    method scale = baseTexture#scale;
    method base = Some (baseTexture :> c);
    method clipping = Some clipping;
    value rootClipping : option Rectangle.t = Some (Obj.magic rootClipping);
    method rootClipping = rootClipping;
(*     method update path = baseTexture#update path; *)
    method subTexture region = ((new subtexture region (self :> r)) :> c);
    method retain () = baseTexture#retain ();
    method releaseSubTexture () = baseTexture#releaseSubTexture ();
    method release () = let () = debug:gc "release subtexture" in baseTexture#releaseSubTexture ();
    method setTextureID tid = baseTexture#setTextureID tid;
    method addRenderer (_:renderer) = ();
    method removeRenderer (_:renderer) = ();
    initializer Gc.finalise (fun t -> t#release ()) self;
  end;

value cache = Cache.create 11;

(*
IFDEF ANDROID THEN
value reloadTextures () = 
  let () = debug:android "reload textures" in
  Cache.iter begin fun path t ->
    let textureInfo = loadImage path 1. in
    let textureID = GLTexture.create textureInfo in
    t#setTextureID textureID
  end;

Callback.register "realodTextures" reloadTextures;
ENDIF;
*)

external delete_texture: textureID -> unit = "ml_delete_texture";

value make textureInfo = 
  let textureID = textureInfo.textureID
  and width = float textureInfo.width
  and height = float textureInfo.height
  and hasPremultipliedAlpha = textureInfo.premultipliedAlpha
  and scale = textureInfo.scale 
  in
  let () = debug "make texture: width=[%d->%f],height=[%d -> %f],scale=%f" textureInfo.realWidth width textureInfo.realHeight height scale in
  let clipping = 
    if textureInfo.realHeight <> textureInfo.height || textureInfo.realWidth <> textureInfo.width 
    then Some (Rectangle.create 0. 0. ((float textureInfo.realWidth) /. width) ((float textureInfo.realHeight) /. height))
    else None 
  in
  let w = float textureInfo.realWidth
  and h = float textureInfo.realHeight in
  object(self)
    value mutable textureID = textureID;
    value mutable counter = 0;

    method retain () = counter := counter + 1;

    method releaseSubTexture () = 
    (
      counter := counter - 1;
      if counter = 0
      then self#release ()
      else ();
    );

    method release () = 
      if (textureID <> 0) 
      then
      (
        debug:gc "release texture %d" textureID;
        delete_texture textureID; 
        textureID := 0
      )
      else ();
    method width = w;
    method height = h;
    method hasPremultipliedAlpha = hasPremultipliedAlpha;
    method scale = scale;
    method setTextureID tid = textureID := tid;
    method textureID = textureID;
    method base = None;
    method clipping = clipping;
    method rootClipping = clipping;
(*       method update path = ignore(loadImage ~textureID ~path ~contentScaleFactor:1.);  (* Fixme cache it *) *)
    method subTexture region = ((new subtexture region self) :> c);
    method addRenderer (_:renderer) = ();
    method removeRenderer (_:renderer) = ();
    initializer Gc.finalise (fun t -> t#release ()) self;
  end;

value create texFormat width height data =
  let legalWidth = nextPowerOfTwo width
  and legalHeight = nextPowerOfTwo height in
  let textureInfo = 
    {
      texFormat;
      realWidth = width;
      width = legalWidth;
      realHeight = height;
      height = legalHeight;
      numMipmaps = 0;
      generateMipmaps = False;
      premultipliedAlpha = False;
      scale = 1.0;
      textureID = Obj.magic 0;
    }
  in
  let textureInfo = loadTexture textureInfo data in
  let res = make textureInfo in
  (res :> c);


Callback.register "create_ml_texture" begin fun textureID width height clipping ->
  object(self:c)
    value mutable textureID = textureID;
    method textureID = textureID;
    method width = width;
    method height = height;
    method hasPremultipliedAlpha = True;
    method scale = 1.;
    method base = None;
    method clipping = clipping;
    method rootClipping = clipping;
    method release () = 
      if (textureID <> 0) 
      then
      (
        debug:gc "release texture %d" textureID;
        delete_texture textureID; 
        textureID := 0
      )
      else ();
    method subTexture _ = assert False;
    method addRenderer _ = ();
    method removeRenderer _ = ();
    initializer Gc.finalise (fun t -> t#release ()) self;
  end
end;

value load path : c = 
  try
    debug:cache (
      Debug.d "print cache";
      Cache.iter (fun k _ -> Debug.d "image cache: %s" k) cache;
    );
    ((Cache.find cache path) :> c)
  with 
  [ Not_found ->
    let textureInfo = 
      proftimer:t "Loading texture [%F]" loadImage path 1. 
    in
    let () = debug:gc Gc.compact () in
    let () = 
      debug:cache
        "load texture: %s [%d->%d; %d->%d] [pma=%s]\n%!" 
        path textureInfo.realWidth textureInfo.width textureInfo.realHeight textureInfo.height 
        (string_of_bool textureInfo.premultipliedAlpha) 
    in
    let res = make textureInfo in
    (
      debug:cache "texture %d loaded" res#textureID;
      Gc.finalise (fun _ -> Cache.remove cache path) res;
      Cache.add cache path res;
      (res :> c)
    )
  ];


(*
class type renderObject =
  object
    method render: ?alpha:float -> ?transform:bool -> option Rectangle.t -> unit;
  end;
*)

external create_render_texture: int -> int -> float -> int -> int -> (framebufferID*textureID) = "ml_rendertexture_create";
type framebufferState;
external activate_framebuffer: framebufferID -> int -> int -> framebufferState = "ml_activate_framebuffer";
external deactivate_framebuffer: framebufferState -> unit = "ml_deactivate_framebuffer";
external delete_framebuffer: framebufferID -> unit = "ml_delete_framebuffer";
external resize_texture: textureID -> int -> int -> unit = "ml_resize_texture";

class type rendered = 
  object
    inherit c;
    method realWidth:int;
    method realHeight:int;
    method setPremultipliedAlpha: bool -> unit;
    method framebufferID: framebufferID;
    method resize: float -> float -> unit;
    method draw: (unit -> unit) -> unit;
    method clear: int -> float -> unit;
  end;


value glRGBA = 0x1908;
value glRGB = 0x1907;

module Renderers = Weak.Make(struct type t = renderer; value equal r1 r2 = r1 = r2; value hash = Hashtbl.hash; end);



IFDEF IOS THEN
value render_texture_size ((w,h) as ok) =
    if w <= 8 
    then
      if w > h
      then  (w,w) (* incorrect case *)
      else
        if h > w * 2 
        then  (min (h / 2) 16, h) (* incorrect case *)
        else ok
    else
      if h <= 8 
      then (w,min 16 w)
      else ok
    ;

ELSE

value render_texture_size p = p;

ENDIF;

value rendered ?(format=glRGBA) ?(color=0) ?(alpha=0.) width height : rendered = (* make it fucking int {{{*)
  let iw = truncate (ceil width) in
  let ih = truncate (ceil height) in
  let legalWidth = nextPowerOfTwo iw
  and legalHeight = nextPowerOfTwo ih in
  let (legalWidth,legalHeight) = render_texture_size (legalWidth,legalHeight) in
  let (framebufferID,textureID) = create_render_texture format color alpha legalWidth legalHeight in
  let clipping = 
    let flw = float legalWidth and flh = float legalHeight in
    if flw <> width || flh <> height 
    then 
      let () = debug "clipping: [%f:%f] -> [%d:%d]" width height legalWidth legalHeight in
      Some (Rectangle.create 0. 0. (width /. flw) (height /. flh))
    else None
  in
  object(self)
    value mutable isActive = False;
    value mutable textureID = textureID;
    value mutable clipping = clipping;
    value mutable width = width;
    value mutable legalWidth = legalWidth;
    method realWidth = legalWidth;
    method width = width;
    value mutable height = height;
    value mutable legalHeight = legalHeight;
    method realHeight = legalHeight;
    method height = height;
    value mutable hasPremultipliedAlpha = True;
    method setPremultipliedAlpha v = hasPremultipliedAlpha := v;
    method hasPremultipliedAlpha = hasPremultipliedAlpha;
    method scale = 1.;
    method textureID = textureID;
    method base : option c = None;
    method clipping = clipping;
    method rootClipping = clipping;
    method subTexture (region:Rectangle.t) : c = assert False;
    method framebufferID = framebufferID;
    value renderers = Renderers.create 1;
    method addRenderer r = Renderers.add renderers r;
    method removeRenderer r = Renderers.remove renderers r;
    method private changed () = Renderers.iter (fun r -> r#onTextureEvent `CHANGE (self :> c)) renderers;

    method resize w h =
      let () = debug "resize %d from %f->%f, %f->%f" textureID width w height h in
      if w <> width || h <> height
      then
        let iw = truncate (ceil w) in
        let ih = truncate (ceil h) in
        let legalWidth' = nextPowerOfTwo iw
        and legalHeight' = nextPowerOfTwo ih in
        let (legalWidth',legalHeight') = render_texture_size (legalWidth',legalHeight') in
        (
          width := w;
          height := h;
          if (legalWidth' <> legalWidth || legalHeight <> legalHeight')
          then resize_texture textureID legalWidth' legalHeight'
          else ();
          legalWidth := legalWidth'; legalHeight := legalHeight';
          let flw = float legalWidth' and flh = float legalHeight' in
          clipping :=
            if flw <> w || flh <> h 
            then Some (Rectangle.create 0. 0. (w /. flw) (h /. flh))
            else None; 
          Renderers.iter (fun r -> r#onTextureEvent `RESIZE (self :> c)) renderers;
        )
      else ();

    method release () = 
      if textureID <> 0
      then
      (
        delete_framebuffer framebufferID;
        delete_texture textureID;
        textureID := 0;
      )
      else ();

    method draw f = 
      match isActive with
      [ False ->
(*         let oldState = activate_framebuffer framebufferID (truncate width) (truncate height) in *)
        let oldState = activate_framebuffer framebufferID legalWidth legalHeight in
        (
          debug "buffer activated";
          isActive := True;
          f();
          deactivate_framebuffer oldState;
          isActive := False;
          self#changed();
        )
      | True -> f()
      ];

    method clear color alpha = self#draw (fun () -> Render.clear color alpha);
    initializer Gc.finalise (fun r -> r#release ()) self;


  end; (*}}}*)
