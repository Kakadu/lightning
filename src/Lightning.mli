
value deviceIdentifier: unit -> option string;

value init: (float -> float -> #Stage.c) -> unit;
value openURL : string -> unit;
value sendEmail : string -> ~subject:string -> ?body:string -> unit -> unit;
external memUsage: unit -> int = "ml_memUsage";
external setMaxGC: int64 -> unit = "ml_setMaxGC";
type malinfo = 
  {
    malloc_total: int;
    malloc_used: int;
    malloc_free: int;
  };

external malinfo: unit -> malinfo = "ml_malinfo";

type remoteNotification = [= `RNBadge | `RNSound | `RNAlert ];
value request_remote_notifications: list remoteNotification ->  (string -> unit) -> (string -> unit) -> unit;

value getLocale: unit -> string;

value addExceptionInfo: string -> unit;
value setSupportEmail: string -> unit;
value extractAssets: (unit -> unit) -> unit -> unit;
value getMACID: unit -> string;
