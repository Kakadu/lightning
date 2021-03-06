type t = { x : float; y : float; };
value empty : t;
value length : t -> float;
value angle : t -> float;
value addPoint : t -> t -> t;
value subtractPoint : t -> t -> t;
value scaleBy : t -> float -> t;
value mul : t -> float -> t;
value div : t -> float -> t;
value normalize : t -> t;
value isEqual : t -> t -> bool;
value description : t -> string;
value distanceFromPoint : t -> t -> float;
value to_string : t -> string;
value create : float -> float -> t;
