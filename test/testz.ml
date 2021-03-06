
class wobj bpos tpos depth = 
  object
    method bpos : (int*int)= bpos;
    method tpos : (int*int) = tpos;
    value mutable depth : int = depth;
    method depth = depth;
    method setDepth d = depth := d;
  end;

value zObjects : DynArray.t wobj = DynArray.create ();
value init () = 
  let f = open_in "zobjects" in
  read () where
    rec read () = 
      try
        let l = input_line f in
        Scanf.sscanf l "(%d:%d)(%d:%d)%d" begin fun bposx bposy tposx tposy depth ->
          DynArray.add zObjects (new wobj (bposx,bposy) (tposx,tposy) depth)
        end;
(*         read (); *)
      with [ End_of_file -> close_in f ];


value zSort () = 
  let ls = DynArray.copy zObjects in
  let stack = ref [] 
  and max = ref (DynArray.length ls) 
  and isSaveDepth = ref True
  and isStack = ref False 
  and depth = ref 0
  in
  (
    while (!max > 0)  do
      let woA = ref (DynArray.get ls 0) 
      and m = ref 0 
      and go = ref True 
      and flag = ref True 
      in 
        (
          decr max;
          DynArray.delete ls 0;
          while !go do
            (
              match !isStack with
              [ True -> 
                  (
                    isStack.val := False;
                    match !stack with
                    [ [] -> go.val := False
                    | [ (m',wo) :: tail] -> 
                        (
                          m.val := m';
                          woA.val := wo;
                          stack.val := tail
                        )
                    ]
                  )
              | _ -> () 
              ];
              match !go with
              [ True -> 
                  (
                    flag.val := True;
                    let cnt = !max - 1 in 
                    match cnt < !m with
                    [ True -> ()
                    | _ ->  
                        try
                          for i = !m to cnt do 
                            let woB = DynArray.get ls i in
                            match ((fst woB#tpos) <= (fst !woA#bpos)) && ((snd woB#tpos) >= (snd !woA#bpos)) with
                            [ True -> 
                                (
                                  flag.val := False;
                                  stack.val := [ (i, !woA) :: (List.map (fun (k,wo) -> match k > 0 && k >= i with [ True -> (k - 1, wo) | _ ->  (k, wo)]) !stack) ];
                                  woA.val := woB; 
                                  m.val := 0;
                                  decr max;
                                  DynArray.delete ls i; 
                                  raise Exit;
                                )
                            | _ -> ()
                            ]
                          done
                        with [ Exit -> () ]
                    ];
                    match !flag with
                    [ True ->
                        (
                          isStack.val := True;
                          (*
                          match !woA#parent with 
                          [ Some parent when parent = (objPanel :> DisplayObject.container) ->
                            *)
                              match (not !isSaveDepth) || !depth <> !woA#depth with
                              [ True -> 
                                  (
                                    isSaveDepth.val := False;
(*                                     objPanel#removeChild !woA; *)
(*                                     objPanel#addChild ~index:!depth  !woA; *)
                                    !woA#setDepth !depth;
                                  )
                              | _ -> ()
                              ];
                              (*
                          | _ -> ()
                          ];
                          *)
                          incr depth;
                        )
                    | _ -> ()
                    ];
                  )
              | _ -> ()
              ];
            )
          done 
        )
    done;
(*     DynArray.iter (fun a ->  DynArray.iter (fun b -> if (a<>b) && (a#depth = b#depth) then  (debug "depth : %d " a#depth) else ()) zObjects) zObjects; *)
  ); 
