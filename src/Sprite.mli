
open LightCommon;

class c:
  object
    inherit DisplayObject.container;
    method ccast: [= `Sprite of c];
    value mutable filters: list Filters.t;
    method color: color;
    method setColor: color -> unit;
    method filters: list Filters.t;
    method setFilters: list Filters.t -> unit;
    method cacheAsImage: bool;
    method setCacheAsImage: bool -> unit;
  end;

value create: unit -> c;
