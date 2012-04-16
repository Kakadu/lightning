


type http_method = [= `GET | `POST ];
type data = [= `Buffer of Buffer.t | `String of string | `URLVariables of list (string*string) ];

type request = 
  {
    httpMethod: mutable http_method;
    headers: mutable list (string*string);
    data: option data;
    url: string;
  };

value get_header name headers = 
  let name = String.lowercase name in
  try
    let hv = MList.find_map (fun (hn,hv) -> match String.lowercase hn = name with [ True -> Some hv | False -> None ]) headers in
    Some hv
  with [ Not_found -> None ];


value string_of_httpMethod = fun
  [ `GET -> "GET"
  | `POST -> "POST"
  ];

value request ?(httpMethod=`GET) ?(headers=[]) ?data url = { httpMethod; headers; data; url};

value ev_PROGRESS = Ev.gen_id "PROGRESS";
value ev_COMPLETE =  Ev.gen_id "COMPLETE";
value ev_IO_ERROR = Ev.gen_id "IO_ERORR";

value (data_of_ioerror,ioerror_of_data) = Ev.makeData();


exception Incorrect_request;



value prepare_request r = 
  match r.httpMethod with
  [ `POST -> 
      let data = 
        match r.data with
        [ Some d ->
          let data = 
            match d with
            [ `Buffer b -> Buffer.contents b 
            | `String s -> s
            | `URLVariables vars -> 
              (
                match get_header "content-type" r.headers with
                [ None -> r.headers := [ ("content-type","application/x-www-form-urlencoded; charset=utf-8") :: r.headers ]
                | _ -> ()
                ];
                UrlEncoding.mk_url_encoded_parameters vars
              )
            ]
          in
          Some data
        | None -> None
        ]
      in
      (r.url,data)
  | `GET -> 
      let url = 
        match r.data with
        [ None -> r.url
        | Some (`URLVariables variables) -> 
            let params = UrlEncoding.mk_url_encoded_parameters variables in
            match r.url.[String.length r.url - 1] with
            [ '&' -> r.url ^ params
            | _ -> r.url ^ "?" ^ params
            ]
        | _ -> raise Incorrect_request
        ]
      in
      (url,None)
  ];

type loader_wrapper = 
  {
    onResponse: int -> string -> int64 -> unit;
    onData: string -> unit;
    onComplete: unit -> unit;
    onError: int -> string -> unit
  };
IFDEF IOS THEN (*{{{*)
type ns_connection;
value loaders = Hashtbl.create 1;

external url_connection: string -> string -> list (string*string) -> option string -> ns_connection = "ml_URLConnection";

value get_loader ns_connection = 
  try
    Hashtbl.find loaders ns_connection
  with [ Not_found -> failwith("HTTPConneciton not found") ];

value url_response ns_connection httpCode contentType totalBytes =
  let () = debug "url response" in
  let w = get_loader ns_connection in
  w.onResponse httpCode contentType totalBytes;

Callback.register "url_response" url_response;

value url_data ns_connection data = 
  let () = debug "url data" in
  let w = get_loader ns_connection in
  w.onData data;

Callback.register "url_data" url_data;

value url_complete ns_connection = 
  let () = debug "url complete" in
  let w = get_loader ns_connection in
  (
    Hashtbl.remove loaders ns_connection;
    w.onComplete ();
  );

Callback.register "url_complete" url_complete;

value url_failed ns_connection code msg = 
  let () = debug "url failed" in
  let w = get_loader ns_connection in
  (
    Hashtbl.remove loaders ns_connection;
    w.onError code msg;
  );

Callback.register "url_failed" url_failed;

value start_load wrappers r = 
  let (url,data) = prepare_request r in
  let ns_connection = url_connection url (string_of_httpMethod r.httpMethod) r.headers data in
  Hashtbl.add loaders ns_connection wrappers;
(*}}}*)
ELSE
IFDEF SDL THEN (*{{{*)

value curl_initialized = ref False;

module type CurlLoader = sig
  value push_request: loader_wrapper -> request -> unit;
  value check_response: unit -> unit;
end;

module CurlLoader(P:sig end) = struct

  match !curl_initialized with
  [ False -> (Curl.global_init Curl.CURLINIT_GLOBALNOTHING; curl_initialized.val := True)
  | True -> ()
  ];

  value condition = Condition.create ();

  value requests_queue = ThreadSafeQueue.create ();

  value waiting_loaders = Hashtbl.create 1;
  value request_id = ref 0;
  value push_request loader request = 
    (
      incr request_id;
      Hashtbl.add waiting_loaders !request_id loader;
      let (url,data) = prepare_request request in
      ThreadSafeQueue.enqueue requests_queue (!request_id,url,request.httpMethod,request.headers,data);
      Condition.signal condition;
    );

  value response_queue = ThreadSafeQueue.create ();

  value rec check_response () = 
    match ThreadSafeQueue.dequeue response_queue with
    [ Some (request_id,result) ->
      (
        let loader = Hashtbl.find waiting_loaders request_id in
        match result with
        [ `Result (code,contentType,contentLength,data) ->
          (
            loader.onResponse code contentType contentLength;
            loader.onData data;
            loader.onComplete ();
          )
        | `Failure code errmsg -> loader.onError code errmsg
        ];
        check_response ();
      )
    | None -> ()
    ];

  value mutex = Mutex.create ();
  value run () = 
    let () = Mutex.lock mutex in
    let buffer = Buffer.create 1024 in
    let dataf = (fun str -> (Buffer.add_string buffer str; String.length str)) in
    loop () where
      rec loop () = 
        let () = debug "try check requests" in
        match ThreadSafeQueue.dequeue requests_queue with
        [ Some (request_id,url,hmth,headers,body) ->
          (
            let () = debug "new curl request on url: %s" url in
            let ccon = Curl.init () in
            try
              Curl.set_url ccon url;
              let headers = List.map (fun (n,v) -> Printf.sprintf "%s:%s" n v) headers in
              match headers with
              [ [] -> ()
              | _ -> Curl.set_httpheader ccon headers
              ];
              match hmth with
              [ `POST -> Curl.set_post ccon True
              | _ -> ()
              ];
              match body with
              [ Some b -> 
                (
                  Curl.set_postfields ccon b;
                  Curl.set_postfieldsize ccon (String.length b);
                )
              | None -> ()
              ];
              Curl.set_writefunction ccon dataf;
              Curl.perform ccon;
              debug "curl performed";
              let httpCode = Curl.get_httpcode ccon
              and contentType = Curl.get_contenttype ccon
              and contentLength = Int64.of_float (Curl.get_contentlengthdownload ccon)
              in
              ThreadSafeQueue.enqueue response_queue (request_id,`Result (httpCode,contentType,contentLength,Buffer.contents buffer));
              Buffer.clear buffer;
              Curl.cleanup ccon;
            with [ Curl.CurlException _ code str -> ThreadSafeQueue.enqueue response_queue (request_id,(`Failure code str))];
            loop ()
          )
        | None ->
          (
            Condition.wait condition mutex;
            loop ()
          )
        ];
  value thread = Thread.create run ();

end;


value curl_loader = ref None;
value process_events () =
  match !curl_loader with
  [ Some m ->
    let module Loader = (value m:CurlLoader) in
    Loader.check_response ()
  | None -> ()
  ];

value start_load wrapper r = 
  let m =
    match !curl_loader with
    [ Some m -> m
    | None -> 
        let module Loader = CurlLoader (struct end) in
        let m = (module Loader:CurlLoader) in
        (
          curl_loader.val := Some m;
          m
        )
        
    ]
  in
  let module Loader = (value m:CurlLoader) in
  Loader.push_request wrapper r;

(*
type thr = ((Event.channel [= `Result of (int * string * Int64.t * string) | `Failure of (int * string) ]) * (Event.channel (string * http_method * list (string*string) * option string)));
value free_threads: Queue.t thr = Queue.create ();
value working_threads = ref [];

value curl_initialized = ref False;

value curl_thread (inch,outch) = 
  let buffer = Buffer.create 1024 in
  let dataf = (fun str -> (Buffer.add_string buffer str; String.length str)) in
  loop () where
    rec loop () =
    (
      let e = Event.receive inch in
      let (url,hmth,headers,body) = Event.sync e in
      let () = debug "new curl request on url: %s" url in
      let ccon = Curl.init () in
      try
        Curl.set_url ccon url;
        let headers = List.map (fun (n,v) -> Printf.sprintf "%s:%s" n v) headers in
        match headers with
        [ [] -> ()
        | _ -> Curl.set_httpheader ccon headers
        ];
        match hmth with
        [ `POST -> Curl.set_post ccon True
        | _ -> ()
        ];
        match body with
        [ Some b -> 
          (
            Curl.set_postfields ccon b;
            Curl.set_postfieldsize ccon (String.length b);
          )
        | None -> ()
        ];
        Curl.set_writefunction ccon dataf;
        Curl.perform ccon;
        debug "curl performed";
        let httpCode = Curl.get_httpcode ccon
        and contentType = Curl.get_contenttype ccon
        and contentLength = Int64.of_float (Curl.get_contentlengthdownload ccon)
        in
        Event.sync (Event.send outch (`Result (httpCode,contentType,contentLength,Buffer.contents buffer)));
        Buffer.clear buffer;
        Curl.cleanup ccon;
      with [ Curl.CurlException _ code str -> Event.sync (Event.send outch (`Failure code str))];
      loop ();
    );

value global_conn_id = ref 0;
value start_load wrapper r = 
(
  match !curl_initialized with
  [ False -> (Curl.global_init Curl.CURLINIT_GLOBALNOTHING; curl_initialized.val := True)
  | True -> ()
  ];
  let (url,data) = prepare_request r in
  let () = debug "data after prepare: [%s]" (match data with [ None -> "NONE" | Some d -> d]) in
  let ((_,outch) as channels) = 
    match Queue.is_empty free_threads with
    [ True -> 
      let () = debug "create new thread" in
      let inch = Event.new_channel ()
      and outch = Event.new_channel () 
      in
      (
        ignore(Thread.create curl_thread (outch,inch));
        ((inch,outch):thr)
      )
    | False -> 
        let () = debug "take existent thread" in
        Queue.pop free_threads
    ]
  in
  let e = Event.send outch (url,r.httpMethod,r.headers,data) in
  working_threads.val := [ (channels,wrapper,`send_request e) :: !working_threads ]
);

value process_result loader = fun
  [ `Result (code,contentType,contentLength,data) ->
    (
      loader.onResponse code contentType contentLength;
      loader.onData data;
      loader.onComplete ();
    )
  | `Failure code errmsg -> loader.onError code errmsg
  ];

value process_events () =
  match !working_threads with
  [ [] -> ()
  | works -> 
      let () = debug "process working threads" in
      working_threads.val := 
        ExtList.List.filter_map begin fun ((((inch,outch) as worker),loader,state) as j) ->
          match state with
          [ `send_request e ->
            match Event.poll e with
            [ None -> Some j
            | Some () ->
                let e = Event.receive inch in
                Some (worker,loader,`wait_result e)
            ]
          | `wait_result e -> 
              match Event.poll e with
              [ None -> Some j
              | Some result ->
                (
                  process_result loader result;
                  Queue.push worker free_threads;
                  None
                )
              ]
          ]
        end works
  ];

*)

(*}}}*)
ELSE

type ns_connection;
value loaders = Hashtbl.create 1;

external url_connection: string -> string -> list (string*string) -> option string -> ns_connection = "ml_android_connection";

value get_loader ns_connection = 
  try
    Hashtbl.find loaders ns_connection
  with [ Not_found -> failwith("HTTPConneciton not found") ];

value url_response ns_connection httpCode contentType totalBytes =
  let () = debug "url response" in
  let w = get_loader ns_connection in
  w.onResponse httpCode contentType totalBytes;

Callback.register "url_response" url_response;

value url_data ns_connection data = 
  let () = debug "url data" in
  let w = get_loader ns_connection in
  w.onData data;

Callback.register "url_data" url_data;

value url_complete ns_connection = 
  let () = debug "url complete" in
  let w = get_loader ns_connection in
  (
    Hashtbl.remove loaders ns_connection;
    w.onComplete ();
  );

Callback.register "url_complete" url_complete;

value url_failed ns_connection code msg = 
  let () = debug "url failed" in
  let w = get_loader ns_connection in
  (
    Hashtbl.remove loaders ns_connection;
    w.onError code msg;
  );

Callback.register "url_failed" url_failed;

value start_load wrappers r = 
  let (url,data) = prepare_request r in
  let ns_connection = url_connection url (string_of_httpMethod r.httpMethod) r.headers data in
  Hashtbl.add loaders ns_connection wrappers;
(*}}}*)

ENDIF;
ENDIF;

exception Loading_in_progress;

type state = [ Loading | Complete ];

class loader ?request () = 
  object(self)
    inherit EventDispatcher.simple [loader];
    value mutable state = Complete;
    method state = state;
    method private asEventTarget = (self :> loader);

    value mutable httpCode = 0;
    method httpCode = httpCode;
    value mutable contentType = "";
    method contentType = contentType;
    value mutable bytesTotal = 0L;
    method bytesTotal = bytesTotal;
    value mutable bytesLoaded = 0L;
    method bytesLoaded = bytesLoaded;
    value data = Buffer.create 10;
    method data = Buffer.contents data;

    method private onResponse c ct b = 
    (
      debug "onResponse";
      httpCode := c; 
      contentType := ct;
      bytesTotal := b;
      bytesLoaded := 0L;
    );

    method private onData d = 
      let () = debug "onData" in
      let bytes = String.length d in
      (
        bytesLoaded := Int64.add bytesLoaded (Int64.of_int bytes);
        Buffer.add_string data d;
        let event = Ev.create ev_PROGRESS ~data:(Ev.data_of_int bytes) () in
        self#dispatchEvent event;
      );

    method private onError code msg = 
    (
      debug "onError";
      state := Complete;
      let event = Ev.create ev_IO_ERROR ~data:(data_of_ioerror (code,msg)) ()  in
      self#dispatchEvent event
    );

    method private onComplete () = 
    (
      debug "on complete";
      state := Complete;
      let event = Ev.create ev_COMPLETE () in
      self#dispatchEvent event
    );

    method load r =
      match state with
      [ Complete ->
        let wrapper = 
          {
            onResponse = self#onResponse;
            onData = self#onData;
            onComplete = self#onComplete;
            onError = self#onError
          }
        in
        (
          httpCode := 0;
          contentType := "";
          bytesTotal := 0L;
          bytesLoaded := 0L;
          Buffer.clear data;
          state := Loading;
          start_load wrapper r;
        )
      | Loading -> raise Loading_in_progress
      ];

    initializer
      match request with
      [ Some r -> self#load r
      | None -> ()
      ];

  end;
