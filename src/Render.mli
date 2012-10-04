exception GL_error of string;

external push_matrix : Matrix.t -> unit = "ml_push_matrix";
external restore_matrix : unit -> unit = "ml_restore_matrix";
external clear : int -> float -> unit = "ml_clear";
external checkErrors : string -> unit = "ml_checkGLErrors";
external get_gl_extensions : unit -> string = "ml_get_gl_extensions";

module Program : sig
        type shader_type = [ Vertex | Fragment ];
        type shader;
        
    external compile_shader : shader_type -> string -> shader
      = "ml_compile_shader" ;
    module ShaderCache :
      sig
        type key = string;
        type t 'a;
        value create : int -> t 'a;
        value clear : t 'a -> unit;
        value add : t 'a -> key -> 'a -> unit;
        value replace : t 'a -> key -> 'a -> unit;
        value remove : t 'a -> key -> unit;
        value merge : t 'a -> key -> 'a -> 'a;
        value find : t 'a -> key -> 'a;
        value find_all : t 'a -> key ->  list 'a;
        value mem : t 'a -> key -> bool;
        value iter : (key -> 'a -> unit) -> t 'a -> unit;
        value fold : (key -> 'a -> 'b -> 'b) -> t 'a -> 'b -> 'b;
        value count : t 'a -> int;
        value stats : t 'a -> (int * int * int * int * int * int);
      end;
    value shader_cache : ShaderCache.t shader;
    value get_shader : shader_type -> ShaderCache.key -> shader;
    type attribute = [ AttribPosition | AttribTexCoords | AttribColor ];
    type t;
    value gen_id : unit -> int;
    module Cache :
      sig
        type key = int;
        type t 'a;
        value create : int -> t 'a;
        value clear : t 'a -> unit;
        value add : t 'a -> key -> 'a -> unit;
        value replace : t 'a -> key -> 'a -> unit;
        value remove : t 'a -> key -> unit;
        value merge : t 'a -> key -> 'a -> 'a;
        value find : t 'a -> key -> 'a;
        value find_all : t 'a -> key -> list 'a;
        value mem : t 'a -> key -> bool;
        value iter : (key -> 'a -> unit) -> t 'a -> unit;
        value fold : (key -> 'a -> 'b -> 'b) -> t 'a -> 'b -> 'b;
        value count : t 'a -> int;
        value stats : t 'a -> (int * int * int * int * int * int);
      end;
    value cache : Cache.t t;
    type uniform =
      [ UNone
      | UInt of int
      | UInt2 of (int * int)
      | UInt3 of (int * int * int)
      | UFloat of float
      | UFloat2 of (float * float) ];
      
    external create_program :
      ~vertex:shader ->
      ~fragment:shader ->
      ~attributes:list (attribute * string) ->
              ~uniforms: array (string * uniform) -> t = "ml_program_create";
      
    value load_force :
      ~vertex:ShaderCache.key ->
      ~fragment:ShaderCache.key ->
      ~attributes:list (attribute * string) ->
      ~uniforms:array (string * uniform) -> 
      t;
    value load :
      Cache.key ->
      ~vertex:ShaderCache.key ->
      ~fragment:ShaderCache.key ->
      ~attributes:list (attribute * string) ->
      ~uniforms:array (string * uniform) -> 
      t;
    value clear : unit -> unit;
  end
;
type filter;
type prg = (Program.t * option filter) ;

module Quad :
  sig
    type t;
    external create :
      ~w:float -> ~h:float -> ~color:LightCommon.color -> ~alpha:float -> t
      = "ml_quad_create";
    external points : t -> array Point.t = "ml_quad_points";
    external set_color : t -> LightCommon.color -> unit = "ml_quad_set_color";
    external alpha : t -> float = "ml_quad_alpha";
    external set_alpha : t -> float -> unit = "ml_quad_set_alpha";
    external render : Matrix.t -> prg -> ?alpha:float -> t -> unit
      = "ml_quad_render" "noalloc";
  end;

module Image :
  sig
    type t;
    external create :
      Texture.renderInfo -> ~color:LightCommon.color -> ~alpha:float -> t
      = "ml_image_create";
    external flipTexX : t -> unit = "ml_image_flip_tex_x" "noalloc";
    external flipTexY : t -> unit = "ml_image_flip_tex_y" "noalloc";
    external points : t -> array Point.t = "ml_image_points";
    external set_color : t -> LightCommon.color -> unit
      = "ml_image_set_color" "noalloc";
    external set_alpha : t -> float -> unit = "ml_image_set_alpha" "noalloc";
    external update :
      t -> Texture.renderInfo -> ~flipX:bool -> ~flipY:bool -> unit
      = "ml_image_update" "noalloc";
    external render : Matrix.t -> prg -> ?alpha:float -> t -> unit
      = "ml_image_render" "noalloc";
  end
;

