type touchPhase =
  [ TouchPhaseBegan
  | TouchPhaseMoved
  | TouchPhaseStationary
  | TouchPhaseEnded
  | TouchPhaseCancelled ];

value string_of_touchPhase : touchPhase -> string;
type n = {
  n_tid : int32;
  n_timestamp : mutable float;
  n_globalX : float;
  n_globalY : float;
  n_previousGlobalX : mutable float;
  n_previousGlobalY : mutable float;
  n_tapCount : int;
  n_phase : mutable touchPhase;
};
type t = {
  tid : int32;
  timestamp : float;
  globalX : float;
  globalY : float;
  previousGlobalX : float;
  previousGlobalY : float;
  tapCount : int;
  phase : touchPhase;
};
external t_of_n : n -> t = "%identity";

