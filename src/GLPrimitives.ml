open LightCommon;

class virtual base = 
  object(self)
    inherit DisplayObject.c as super;
  end;

class _c  =
  object(self)
    inherit base as super;

    method !name = if name = ""  then Printf.sprintf "glprimitives%d" (Oo.id self) else name;
    method setColor _ = ();
    method color = `NoColor;
    method filters = [];
    method setFilters _ = ();
    method boundsInSpace: 
      !'space. (option (<asDisplayObject: DisplayObject.c; .. > as 'space)) -> Rectangle.t = 
      fun _ ->  Rectangle.create 0. 0. 300. 300.
    ;
    method private render' ?alpha:(alpha') ~transform _ = 
    (
      debug "GLPrimitives._c.render";
      Render.GLPrimitives.render ()
    ); 
end;

class c  = 
  object(self)
    inherit _c ;
    method ccast : [= `Image of c ] = `Image (self :> c);
  end;

value create () = new c;









