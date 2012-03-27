
open LightCommon;


type bc = 
  {
    charID:int;
    xOffset:float;
    yOffset:float;
    xAdvance: float;
    atlasNode: AtlasNode.t;
  };

type t = 
  {
    chars: Hashtbl.t int bc;
    scale: float;
    ascender: float;
    descender: float;
    lineHeight: float;
    space:float;
    texture: Texture.c;
  };

module MapInt = Map.Make (struct type t = int; value compare (k1:int) k2 = compare k1 k2; end);
value fonts = Hashtbl.create 0;
value exists ?(style="regular") name = Hashtbl.mem fonts (name,style);
exception Font_not_found of (string*string);

value default_size = 24;


value get ?(applyScale=False) ?(style="regular") ?size name =
  let sizes = try Hashtbl.find fonts (name,style) with [ Not_found -> raise (Font_not_found (name,style)) ] in
  match size with
  [ None -> 
    let (fsize,font) = MapInt.choose sizes in
    font
  | Some size ->
    let (l,f,r) = MapInt.split size sizes in
    match f with
    [ Some f -> f
    | None -> 
        let () = Debug.e "SCALE FONT: %s:%s:%d" name style size in
        let (fsize,font) = 
          match MapInt.is_empty r with
          [ False -> MapInt.min_binding r
          | True -> MapInt.max_binding l
          ]
        in
        match applyScale with
        [ True -> 
          let scale = (float size) /. (float fsize) in
          {(font) with scale = scale; space = font.space *. scale; ascender = font.ascender *. scale; descender = font.descender *. scale; lineHeight = font.lineHeight *. scale }
        | False -> {(font) with scale = (float size) /. (float fsize) }
        ]
    ]
  ];

DEFINE CHAR_NEWLINE = 10;
DEFINE CHAR_SPACE = 32;
DEFINE CHAR_TAB = 9;


(*
value register xmlpath = (*{{{*)
  let module XmlParser = MakeXmlParser(struct value path = xmlpath; end) in
  let floats = XmlParser.floats in
  let () = XmlParser.accept (`Dtd None) in
  let parse_info () = 
    match XmlParser.parse_element "info" [ "face"; "size"] with
    [ Some [ face; size ] _ -> (face,XmlParser.ints size)
    | None -> XmlParser.error "font->info not found"
    | _ -> assert False
    ]
  and parse_common () = 
    match XmlParser.parse_element "common" ["space";"lineHeight";"base"] with
    [ Some [ space; lineHeight; base ] _ -> (floats space, floats lineHeight, floats base)
    | None -> XmlParser.error "font->common not found"
    | _ -> assert False
    ]
  and parse_page () = 
    match XmlParser.next () with
    [ `El_start ((_,"pages"),_) ->
      match XmlParser.parse_element "page" [ "file"] with
      [ Some [ file ] _ -> 
        let () = XmlParser.accept `El_end in
        file
      | None -> XmlParser.error "font->pages->page not found"
      | _ -> assert False
      ]
    | _ -> XmlParser.error "font->pages not found"
    ]
  and parse_chars texture = 
    match XmlParser.next () with
    [ `El_start ((_,"chars"),attributes) ->
      let count = match XmlParser.get_attribute "count" attributes with [ Some count -> int_of_string count | None -> 0] in
      let chars = Hashtbl.create count in
      let rec loop () =
        match XmlParser.parse_element "char" ["id";"x";"y";"width";"height";"xoffset";"yoffset";"xadvance"] with
        [ Some [ id;x;y;width;height;xoffset;yoffset;xadvance ] _ ->
          (
            let charID = int_of_string id in
            let bc = 
              let region = Rectangle.create (floats x) (floats y) (floats width) (floats height) in
              let atlasNode = AtlasNode.create texture region () in
              { charID ; xOffset = floats xoffset; yOffset = floats yoffset; xAdvance = floats xadvance; atlasNode }
            in
            Hashtbl.add chars charID bc;
            loop ()
          )
        | None -> chars
        | _ -> assert False
        ]
      in
      loop ()
    | _ -> XmlParser.error "font->chars not found"
    ]
  in
  match XmlParser.next () with
  [ `El_start ((_,"font"),_) -> 
    let (name,size) = parse_info () in
    let (space,lineHeight,baseLine) = parse_common () in
    let imgFile = parse_page () in
    let texture = Texture.load imgFile in
    let chars = parse_chars texture in
    let bf = { texture; chars; (* name; *) scale=1.; baseLine; lineHeight; space } in
    try
      let sizes = Hashtbl.find fonts name in
      let sizes = MapInt.add size bf sizes in
      Hashtbl.replace fonts name sizes
    with [ Not_found -> Hashtbl.add fonts name (MapInt.singleton size bf) ]
  | _ -> XmlParser.error "font not found"
  ];(*}}}*)
*)


value register xmlpath =
  let dirname = match Filename.dirname xmlpath with [ "." -> "" | dir -> dir ] in
  let module XmlParser = MakeXmlParser(struct value path = xmlpath; end) in
  let () = XmlParser.accept (`Dtd None) in
  let floats = XmlParser.floats in
  let parse_pages () = 
    match XmlParser.next () with
    [ `El_start ((_,"Pages"),_) ->
      let rec loop res = 
        match XmlParser.parse_element "page" [ "file"] with
        [ Some [ file ] _ -> loop [ Texture.load (Filename.concat dirname file) :: res ]
        | None -> res 
        | _ -> assert False
        ]
      in
      Array.of_list (List.rev (loop []))
    | _ -> XmlParser.error "Font->Pages not found"
    ]
  in
  match XmlParser.next () with
  [ `El_start ((_,"Font"),attributes) -> 
    match XmlParser.get_attributes "Font" ["face"; "style"; "kerning"] attributes with
    [ [ face;style;kernign] ->
      let pages = parse_pages () in
      let style = String.uncapitalize style in
      let rec parse_chars res = 
        match XmlParser.next () with
        [ `El_start ((_,"Chars"),attributes) ->
          match XmlParser.get_attributes "Chars" [ "space"; "size"; "lineHeight"; "ascender" ; "descender" ] attributes with
          [ [ space; size; lineHeight; ascender; descender ] ->
            let chars = Hashtbl.create 9 in
            let rec loop () = 
              match XmlParser.parse_element "char" [ "id";"x";"y";"width";"height";"xoffset";"yoffset";"xadvance";"page" ] with
              [ Some [ id;x;y;width;height;xOffset;yOffset;xAdvance;page] _ -> (* запихнуть *)
                (
                  let charID = XmlParser.ints id in
                   let bc = 
                     let region = Rectangle.create (floats x) (floats y) (floats width) (floats height) in
                     let atlasNode = AtlasNode.create pages.(XmlParser.ints page) region  () in
                     { charID; xOffset = floats xOffset; yOffset = floats yOffset; xAdvance = floats xAdvance; atlasNode }
                   in
                   Hashtbl.add chars charID bc;
                   loop ()
                )
              | None -> ()
              | _ -> assert False
              ]
            in
            (
              loop ();
              let bf = { chars; texture = pages.(0); scale=1.; ascender =  floats ascender; descender = floats descender; space = floats space; lineHeight = floats lineHeight; } in
              let res = MapInt.add (XmlParser.ints size) bf res in
              parse_chars res
            )
          | _ -> assert False
          ]
        | `El_end -> res
        | _ -> XmlParser.error "unknown signal"
        ]
      in
      let sizes = parse_chars (try Hashtbl.find fonts (face,style) with [ Not_found -> MapInt.empty ]) in
      Hashtbl.replace fonts (face,style) sizes
    | _ -> assert False
    ]
  | _ -> XmlParser.error "Font not found"
  ];

(*
module type Creator = sig
  module Sprite: Sprite.S;
  value createText: t -> ~width:float -> ~height:float -> ~color:int -> ?border:bool -> ?hAlign:LightCommon.halign -> ?vAlign:LightCommon.valign -> string -> Sprite.c;
end;

module MakeCreator(Image:Image.S)(Sprite:Sprite.S with module D = Image.D) = struct

  module Sprite = Sprite;

  value createText t ~width ~height ~color ?(border=False) ?hAlign ?vAlign text =
  (*   let () = Printf.eprintf "create text: [%s]\n%!" text in *)
    let lineContainer = Sprite.create () in
    let containerWidth = width /. t.scale
    and containerHeight = height /. t.scale 
    in
    (
      lineContainer#setScale t.scale;
      let lines = Queue.create () in
      (
        let strLength = String.length text in
        match strLength with
        [ 0 -> ()
        | _ ->
          let lastWhiteSpace = ref None in
          let rec add_line currentLine index = 
            (
              Queue.add currentLine lines;
              match index with
              [ Some index -> 
                let nextLineY = currentLine#y +. t.lineHeight in
                if nextLineY +. t.lineHeight <= containerHeight
                then 
                  let nextLine = Sprite.create () in
                  (
                    nextLine#setY nextLineY;
                    lastWhiteSpace.val := None;
                    add_char nextLine 0. index
                  )
                else ()
              | None -> ()
              ]
            )
          and  add_char currentLine (currentX:float) index = 
    (*         let () = Printf.printf "add char with index: %d\n%!" index in *)
            if index < strLength 
            then
              let code = UChar.code (UTF8.look text index) in
              let bchar = try Hashtbl.find t.chars code with [ Not_found -> let () = Printf.eprintf "char %d not found\n%!" code in Hashtbl.find t.chars CHAR_SPACE ] in
              if code = CHAR_NEWLINE 
              then
                add_line currentLine (Some (UTF8.next text index))
              else 
                if currentX +. bchar.xAdvance > containerWidth (* we need use scale in this comparation ???? *)
                then
                  let idx = 
                    match !lastWhiteSpace with
                    [ Some idx -> 
                      let removeIndex = idx in
                      let numCharsToRemove = currentLine#numChildren - removeIndex in
                      (
    (*                     let () = Printf.printf "lastWhiteSpace: numChildren: %d, removeIndex: %d, numCharsToRemove: %d\n%!" currentLine#numChildren removeIndex numCharsToRemove in *)
                        for i = 0 to numCharsToRemove - 1 do
    (*                       let () = Printf.printf "remove %d\n%!" currentLine#numChildren in *)
                          ignore(currentLine#removeChildAtIndex removeIndex)
                        done;
                        UTF8.move text index ~-numCharsToRemove
                      )
                    | None -> index
                    ]
                  in
                  add_line currentLine (Some idx)
                else
                  let bitmapChar = Image.create bchar.charTexture in
                  (
  (*                   bitmapChar#setName (Printf.sprintf "letter: %d" index); *)
                    bitmapChar#setX (currentX +. bchar.xOffset);
                    bitmapChar#setY bchar.yOffset;
                    bitmapChar#setColor color;
                    currentLine#addChild bitmapChar;
                    if code = CHAR_SPACE then lastWhiteSpace.val := Some currentLine#numChildren else ();
                    add_char currentLine (currentX +. bchar.xAdvance) (UTF8.next text index)
                  )
            else add_line currentLine None
          in
          add_char (Sprite.create()) 0. 0
        ];
        match hAlign with
        [ Some ((`HAlignRight | `HAlignCenter) as halign) ->
          Queue.iter begin fun line ->
            (
              let lastChar = line#getLastChild in
              let lineWidth = lastChar#x +. lastChar#width in
              let widthDiff = containerWidth -. lineWidth in
  (*             let () = Printf.printf "lastChar#x: %f, lastChar#width: %f, lineWidth: %f, widthDiff: %f\n%!" lastChar#x lastChar#width lineWidth widthDiff in *)
              line#setX begin
                match halign with
                [ `HAlignRight -> widthDiff
                | `HAlignCenter -> widthDiff /. 2.
                ]
              end;
              debug "Add line with y = %F" line#y;
              lineContainer#addChild line
            )
          end lines 
        | _ -> Queue.iter lineContainer#addChild lines
        ];
      );
      let outerContainer = Sprite.create () in 
      (
        outerContainer#addChild lineContainer;
        match vAlign with
        [ Some ((`VAlignCenter | `VAlignBottom) as valign) ->
          let contentHeight = (float lineContainer#numChildren) *. t.lineHeight *. t.scale in
          let heightDiff = height -. contentHeight in
          lineContainer#setY begin
            match valign with
            [ `VAlignBottom -> heightDiff 
            | `VAlignCenter -> heightDiff /. 2.
            ]
          end
        | _ -> ()
        ];
        (*
        if border
        then
          let topBorder = Quad.create width 1.
          and bottomBorder = Quad.create width 1.
          and leftBorder = Quad.create 1. (height -. 2.)
          and rightBorder = Quad.create 1. (height -. 2.)
          in
          (
            topBorder#setColor color;
            bottomBorder#setColor color;
            leftBorder#setColor color;
            rightBorder#setColor color;
            bottomBorder#setY (height -. 1.);
            leftBorder#setY 1.;
            rightBorder#setY 1.;
            rightBorder#setX (width -. 1.);
            outerContainer#addChild topBorder;
            outerContainer#addChild bottomBorder;
            outerContainer#addChild leftBorder;
            outerContainer#addChild rightBorder;
          )   
        else ();
        *)
        outerContainer;
      )
    );

end;
*)
