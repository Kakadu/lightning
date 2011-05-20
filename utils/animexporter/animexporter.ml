module PNG = Png;
module BITMAP = Bitmap;
module GENIMAGE = Genimage;

value (///) = Filename.concat;

(* FIXME: make it configurable *)
value dataDir = "/Volumes/newdata/data";
value img_dir = "/Volumes/newdata/img";
value outputDir = "/tmp/img";

value file_frames = dataDir /// "frames1L.swf";

value libsettings = 
  match Json_io.load_json (dataDir /// "libsettings.json") with
  [ Json_type.Object lst -> 
    fun key ->
      match List.assoc key lst with
      [ Json_type.String s -> s
      | _ -> failwith (Printf.sprintf "bad setting: %s" key)
      ]
  | _ -> assert False
  ];


value info_obj = JSObjAnim.init_obj_info (dataDir /// (libsettings "info"));
value animations = JSObjAnim.init_animations (dataDir /// (libsettings "animations"));
value frames_dir = JSObjAnim.init_frames_dir (dataDir /// "frames_dir.json");

type new_frame_desc_item = {
  xmlId:int;
  recId:int;
  nxi:int;
  nyi:int;
  nflip:bool;
  nalpha:int;
};

type new_frame_desc = {
 nw:int;
 nh:int;
 nx:int;
 ny:int;
 nitems: list new_frame_desc_item;
};

type frame_desc_item = {
 libId:int;
 pngId:int;
 xi:int;
 yi:int;
 flip:bool;
 alpha:int;
 urlId:int;
};

type frame_desc = {
 w:int;
 h:int;
 x:int;
 y:int;
 icon_x: int;
 icon_y: int;
 items: list frame_desc_item;
};


value read_boolean input =
  let i = BatIO.read_byte input in
  if i <> 0
  then True
  else False;

value read_frames () =
  let input = BatFile.open_in file_frames in
  let rec loop index res =
     try
      let w = BatIO.read_i16 input in
      let h = BatIO.read_i16 input in
      let x = BatIO.read_i16 input in
      let y = BatIO.read_i16 input in
      let icon_x = BatIO.read_i16 input in
      let icon_y = BatIO.read_i16 input in
(*       let _ = print_endline (Printf.sprintf "fields: %d, %d, %d, %d" field1 field2 field3 field4) in *)
      let frame = {w;h;x;y;icon_x;icon_y;items=[]} in
      let count = BatIO.read_byte input in
      let _ = print_endline ("count: " ^ (string_of_int count)) in
      let rec loop1 i frame =
          if i <= count
          then
(*             let _ = print_endline ("i: " ^ (string_of_int i)) in *)
            let libId = BatIO.read_byte input in
            let pngId = BatIO.read_i32 input in
            let xi = BatIO.read_i16 input in
            let yi = BatIO.read_i16 input in
            let flags = BatIO.read_byte input in
            let flip = if flags <> 0 then True else False in
            let alpha = if (flags land 2) = 2 then BatIO.read_byte input else 0 in
            let urlId = BatIO.read_i32 input in
(*             let _ = print_endline (Printf.sprintf "ifields: %d, %d, %d, %d, %d, %d" ifield1 ifield2 ifield3 ifield4 ifield6 ifield7) in  *)
            let item = {libId;pngId;xi;yi;flip;alpha;urlId} in
            loop1 (i+1) {(frame) with items = [item::frame.items]}
          else frame
      in
      let frame = loop1 1 frame in
      (
        loop (index+1) (Array.append res [| frame |]);
      )
     with [BatInnerIO.No_more_input -> res]
  in
  let res = loop 0 [||] in
  let _ = print_endline (Printf.sprintf "length res: %d" (Array.length res)) in
  res;

value (=|=) k v = (("",k),v);
value (=.=) k v = k =|= string_of_float v;
value (=*=) k v = k =|= string_of_int v;

value write_animations animations dir = 
  let out = open_out (dir /// "animations.xml") in
  let xml = Xmlm.make_output (`Channel out) in
  (
    Xmlm.output xml (`Dtd None);
    Xmlm.output xml (`El_start (("","Animations"),[]));
    List.iter begin fun (objname,animation) ->
    (
      Xmlm.output xml (`El_start (("","Object"),[ "name" =|= objname ]));
      List.iter begin fun (anim_name,frames) ->
      (
        Xmlm.output xml (`El_start (("","Animation"),[ "name" =|= anim_name ]));
        Array.iter begin fun frame ->
        (
          Xmlm.output xml (`El_start (("","Frame"),[ "id" =*= frame ]));
          Xmlm.output xml `El_end
        )
        end frames;
        Xmlm.output xml `El_end;
      )
      end animation;
      Xmlm.output xml `El_end;
    )
    end animations;
    Xmlm.output xml `El_end;
    close_out out;
  );

value write_frames_and_animations new_obj dir =
  let file_out = BatFile.open_out (dir /// "frames.swf") in
  let (_,animations) = Hashtbl.fold begin fun key anims (index,animations) -> (
    let _ = print_endline (Printf.sprintf "write_frames_and_anim_json obj: %s" key) in
    let (i,animation) =
      List.fold_left begin fun (i,animation) (animn,frames) ->
        let _ = print_endline (Printf.sprintf "write_frames_and_anim_json animn: %s" animn) in
(*         let a = Array.make (List.length frames) 0 in *)
        (
        let (cnt,f) =
          List.fold_left begin fun (cnt,f) (index,frame) ->
          (
            BatIO.write_i16 file_out frame.nw;
            BatIO.write_i16 file_out frame.nh;
            BatIO.write_i16 file_out frame.nx;
            BatIO.write_i16 file_out frame.ny;
            BatIO.write_byte file_out (List.length frame.nitems);
            List.iter begin fun item ->
            (
              BatIO.write_byte file_out item.xmlId;
              BatIO.write_i32 file_out item.recId;
              BatIO.write_i16 file_out item.nxi;
              BatIO.write_i16 file_out item.nyi;
              BatIO.write_byte file_out (if item.nflip then 1 else 0);
              BatIO.write_i32 file_out item.nalpha;
            )
            end frame.nitems;
            (cnt+1,[cnt::f])
          )
          end (i,[]) frames
        in
        (cnt,[(animn,(Array.of_list f))::animation])
        )
      end (index,[]) anims
    in
    (i,[(key,animation)::animations])
  )
  end new_obj (0,[])
  in
  write_animations animations dir;
  (*
  let _ = JSObjAnim.animations_to_json animations dir in
  ();
  *)

value object_items : Hashtbl.t string (list (string*string*int*frame_desc_item*Images.t))= Hashtbl.create 0;

value object_items_create obj frames_desc =
  let anims = List.assoc obj animations in
  let () = Hashtbl.add object_items obj [] in
  (
    List.iter begin fun (animn,frames) ->
      let _ = print_endline (Printf.sprintf "anim_name: %s" animn) in
      Array.iter begin fun index_frame ->
    (*            let _ = print_endline (Printf.sprintf "frame index: %d" index) in *)
        let frame_desc = frames_desc.(index_frame) in
        BatList.iteri begin fun index_item item ->
          let _ = print_endline (Printf.sprintf "item libId: %d, pngId %d, urlId: %d" item.libId item.pngId item.urlId) in
          let png_path = frames_dir.JSObjAnim.paths.(item.urlId) in
          let _ = print_endline (Printf.sprintf "png_path: %s" png_path) in
          let img = Images.load (img_dir /// png_path) [] in
          try
            let items = Hashtbl.find object_items obj in
            Hashtbl.replace object_items obj [(obj,animn,index_frame,item,img)::items]
          with [Not_found -> Hashtbl.add object_items obj [(obj,animn,index_frame,item,img)] ]
        end frame_desc.items
      end frames
    end anims;
    Hashtbl.find object_items obj;
  );

value get_size imgs =
  let (w,h) =
    try
      List.find begin fun (w,h) ->
        let _ = print_endline (Printf.sprintf "w: %d h: %d" w h) in
        try
          let (_,_,_,cnt) =
            List.fold_left begin fun (sx,sy,mh,cnt) (_,_,_,_,img) ->
              let (iw,ih) = Images.size img in
        (*       let _ = print_endline (Printf.sprintf "obj: %s, sx: %d, sy:%d, iw:%d, ih:%d, mh:%d" obj sx sy iw ih mh) in *)
              let (nsx,nsy) = if sx + iw >= w then (0,sy+mh) else (sx,sy) in
              if nsy + ih >= h
              then
                if iw > w || ih > h
                then raise Images.Out_of_image
                else
                  (iw,0,ih,cnt+1)
              else
                if iw > w || ih > h
                then raise Images.Out_of_image
                else
                  let mh = if ih > mh then ih else mh in
                  (nsx+iw,nsy,mh,cnt)
            end (0,0,0,1) imgs
          in
          cnt = 1
        with [Images.Out_of_image -> False]
      end [(64,64);(128,128);(256,256);(512,512);(1024,1024)]
    with [Not_found -> (1024,1024)]
  in
  (w,h);

value create_texture obj imgs oframes =
  let new_obj : Hashtbl.t string (list (string*(list (int*new_frame_desc)))) = Hashtbl.create 0 in
  let add_in_new_obj (objn,animn,indexf,old_item,xmlId,recId) =
    let item = {xmlId=xmlId;recId=recId;nxi=old_item.xi;nyi=old_item.yi;nflip=old_item.flip;nalpha=old_item.alpha} in
    try
      let anims = Hashtbl.find new_obj objn in
      try
        let frames = List.assoc animn anims in
        try
          let fd = List.assoc indexf frames in
          let nfd = {(fd) with nitems = [item::fd.nitems]} in
          let nframes = [(indexf,nfd)::List.remove_assoc indexf frames]in
          Hashtbl.replace new_obj objn [(animn,nframes)::(List.remove_assoc animn anims)]
        with
        [ Not_found ->
          let oldf = oframes.(indexf) in
          let nfd = {nw=oldf.w;nh=oldf.h;nx=oldf.x;ny=oldf.y;nitems=[item]} in
          let nf = [(indexf,nfd)::frames] in
          Hashtbl.replace new_obj objn [(animn,nf)::(List.remove_assoc animn anims)]
        ]
      with
      [ Not_found ->
        let oldf = oframes.(indexf) in
        let nfd = {nw=oldf.w;nh=oldf.h;nx=oldf.x;ny=oldf.y;nitems=[item]} in
        Hashtbl.replace new_obj objn [(animn,[(indexf,nfd)])::anims]
      ]
    with
    [ Not_found ->
      let oldf = oframes.(indexf) in
      let nfd = {nw=oldf.w;nh=oldf.h;nx=oldf.x;ny=oldf.y;nitems=[item]} in
      Hashtbl.add new_obj objn [(animn,[(indexf,nfd)])]
    ]
  in
  let dir = outputDir /// obj in
  let () =
    if not (Sys.file_exists dir)
    then
      Unix.mkdir dir 0o755
    else ()
  in
  let imgs =
    List.sort (fun (_,_,_,_,img1) (_,_,_,_,img2) ->
      let (_,ih1) = Images.size img1 in
      let (_,ih2) = Images.size img2 in
      compare ih1 ih2
    ) imgs
  in
  let (w,h) = get_size imgs in
  let _ = print_endline (Printf.sprintf "create_texture obj: %s, length imgs: %d" obj (List.length imgs)) in
  let rgb = Rgba32.make w h  {Color.color={Color.r=0;g=0;b=0}; alpha=0;} in
  let new_img = (Images.Rgba32 rgb) in
  let out = open_out (dir /// "1.xml") in
  let xml = Xmlm.make_output (`Channel out) in
  let () = Xmlm.output xml (`Dtd None) in
  let () = Xmlm.output xml (`El_start (("","Texture"),[ "imagPath" =|= "1.png" ])) in
  let fname cnt ext = (string_of_int cnt) ^ "." ^ ext in
  let (_,_,_,new_img,cnt,_,xml,out) =
    List.fold_left begin fun (sx,sy,mh,new_img,cnt,i_rec,xml,out) (objn,animn,frame_index,old_item,img) ->
      let (iw,ih) = Images.size img in
(*       let _ = print_endline (Printf.sprintf "obj: %s, sx: %d, sy:%d, iw:%d, ih:%d, mh:%d" obj sx sy iw ih mh) in *)
      let (nsx,nsy) = if sx + iw >= w then (0,sy+mh) else (sx,sy) in
      if nsy + ih >= h
      then
        let _ = Images.save (dir /// (fname cnt "png")) (Some Images.Png) [] new_img in
        let () = Xmlm.output xml `El_end in
        let () = close_out out in
        let out = open_out (dir /// (fname cnt "xml")) in
        let xml = Xmlm.make_output (`Channel out) in
        let () = Xmlm.output xml (`Dtd None) in
        let () = Xmlm.output xml (`El_start (("","Texture"),[ "imagPath" =|= ((string_of_int cnt) ^".png") ])) in
        let rgb = Rgba32.make w h  {Color.color={Color.r=0;g=0;b=0}; alpha=0;} in
        let new_img = (Images.Rgba32 rgb) in
        let _ = Images.blit img 0 0 new_img 0 0 iw ih in
        let () = Xmlm.output xml (`El_start (("","SubTexture"),["x" =|= "0."; "y" =|= "0."; "height" =*= ih; "width" =*= iw])) in
        let () = Xmlm.output xml `El_end in
        let () = add_in_new_obj (objn,animn,frame_index,old_item,cnt,i_rec) in
        (iw,0,ih,new_img,(cnt+1),i_rec+1,xml,out)
      else
(*         let _ = print_endline (Printf.sprintf "obj: %s,nsx: %d, nsy:%d" obj nsx nsy) in *)
        let _ = Images.blit img 0 0 new_img nsx nsy iw ih in
        let () = Xmlm.output xml (`El_start (("","SubTexture"),[ "x" =*= nsx; "y" =*= nsy; "height" =*= ih; "width" =*= iw ])) in
        let () = Xmlm.output xml `El_end in
        let () = add_in_new_obj (objn,animn,frame_index,old_item,cnt,i_rec) in
        let mh = if ih > mh then ih else mh in
        (nsx+iw,nsy,mh,new_img,cnt,i_rec+1,xml,out)
    end (0,0,0,new_img,1,0,xml,out) imgs
  in
  (
    let () = Xmlm.output xml `El_end in
    let () = close_out out in
    Images.save (dir /// (fname cnt "png")) (Some Images.Png) [] new_img;
    write_frames_and_animations new_obj dir;
  );

value get_objects_for_lib lib =
   List.filter begin fun (oname,info) ->
     match info.JSObjAnim.lib with
     [ Some l when lib = l-> True
     | _ -> False
     ]
   end info_obj;

value () =
  let frames = read_frames () in
  List.iter begin fun (oname,info) ->
    let () = print_endline (Printf.sprintf "oname: %s" oname) in
    try
      ignore(Hashtbl.find object_items oname)
    with [Not_found ->
      match info.JSObjAnim.lib with
      [ Some l ->
        let () = print_endline (Printf.sprintf "lib: %s" l) in
        let list_img =
          List.fold_left (fun res (oname,_) ->
            res @ (object_items_create oname frames)
          ) [] (get_objects_for_lib l)
        in
        create_texture l list_img frames
      | None ->
        let () = print_endline (Printf.sprintf "obj: %s" oname) in
        let list_img = object_items_create oname frames in
        create_texture oname list_img frames
      ]
    ]
  end info_obj;