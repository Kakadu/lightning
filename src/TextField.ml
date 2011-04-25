open LightCommon;


class c [ 'event_type, 'event_data ] ?fontName ?fontSize ?color ~width ~height text = 
  let _fontName = Option.default "Helvetica" fontName in
  object(self)
    inherit DisplayObject.container [ 'event_type, 'event_data ] as super;

    value mutable fontSize = fontSize;
    value mutable color = Option.default color_black color;
    value mutable hAlign : halign = `HAlignCenter;
    value mutable vAlign : valign = `VAlignCenter;
    value mutable border = False;
    value mutable fontName = _fontName;
    value mutable text = text;
    value hitArea = Quad.create width height;
    value textArea = Quad.create width height;
    value mutable requiresRedraw = True;
    value mutable isRenderedText = not (BitmapFont.exists _fontName);
    value mutable contents = None;

    initializer 
      (
        hitArea#setAlpha 0.;
        self#addChild hitArea;
        textArea#setVisible False;
        self#addChild textArea;
      );

    method setText ntext = 
    (
      text := ntext;
      requiresRedraw := True;
    );

    method! setWidth nw = 
    (
      hitArea#setWidth nw;
      requiresRedraw := True;
    );

    method! setHeight nh = 
    (
      hitArea#setHeight nh;
      requiresRedraw := True
    );

    method setFontName fname = 
    (
      fontName := fname;
      requiresRedraw := True;
      isRenderedText := not (BitmapFont.exists fname);
    );

    method setFontSize size = 
    (
      fontSize := size;
      requiresRedraw := True;
    );


    method setBorder nb = 
      if nb <> border 
      then
      (
        border := nb;
        requiresRedraw := True;
      )
      else ();

    method setColor ncolor = 
      if ncolor <> color
      then
      (
        color := ncolor;
        (*
        if (mIsRenderedText)
            [(SPImage * )mContents setColor:color];
        else *)
            requiresRedraw := True;
      )
      else ();
      
    method setHAlign nha = 
      if nha <> hAlign
      then
        (
          hAlign := nha;
          requiresRedraw := True;
        )
      else ();
      
    method setVAlign nva = 
      if nva <> vAlign
      then
        (
          vAlign := nva;
          requiresRedraw := True;
        )
      else ();
        
    method private createRenderedContents () = assert False;
    method private createComposedContents () =
      let bitmapFont = BitmapFont.get fontName in
      let contents = BitmapFont.createText bitmapFont ~width ~height ?size:fontSize ~color ~border ~hAlign ~vAlign text in
      let bounds = contents#bounds in
      (
        hitArea#setX bounds.Rectangle.x; hitArea#setY bounds.Rectangle.y;
        hitArea#setWidth bounds.Rectangle.width; hitArea#setHeight bounds.Rectangle.height;
        contents;
      );

    method private redrawContents () = 
      (
        match contents with
        [ Some c -> c#removeFromParent ()
        | None -> ()
        ];
        let contents' = 
            match isRenderedText with
            [ True -> self#createRenderedContents ()
            | False -> self#createComposedContents ()
            ]
        in
        (
          contents'#setTouchable False;
          self#addChild contents';
          contents := Some contents';
        );
        requiresRedraw := False;
      );

    method! render () = 
      (
        if requiresRedraw then self#redrawContents () else ();
        super#render();
      );

    method textBounds = 
    (
      if requiresRedraw then self#redrawContents () else ();
      textArea#boundsInSpace (match parent with [ Some p -> Some (p#asDisplayObject) | None -> None ]);
    );

    method! boundsInSpace targetCoordinateSpace = hitArea#boundsInSpace targetCoordinateSpace;

  end;


value create = new c;
