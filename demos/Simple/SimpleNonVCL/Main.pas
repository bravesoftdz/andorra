unit Main;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  AdFreeImage, AdStdWindow, AdClasses, AdEvents, AdDraws, AdTypes;

type
  TAdAppl = class
    private
      AdDraw:TAdDraw;
      AdImage:TAdImage;
    public
      MouseX, MouseY : integer;
      procedure Idle(Sender:TObject; var Done:boolean);
      procedure Run;
      procedure MouseMove(Sender: TObject; Shift:TAdShiftState; X, Y:integer);
      procedure KeyDown(Sender: TObject; Key: Word; Shift:TAdShiftState);
  end;

implementation

{ TAdAppl }

procedure TAdAppl.Idle(Sender: TObject; var Done: boolean);
begin
  if AdDraw.CanDraw then
  begin
    AdDraw.ClearSurface(0);
    AdDraw.BeginScene;

    AdImage.Draw(AdDraw, 0, 0, 0);

    with AdDraw.Canvas do
    begin
      TextOut(MouseX, MouseY, 'Andorra 2D ['+AdDraw.DllName+','+AdDraw.Window.ClassName+']');
      Release;
    end;

    AdDraw.EndScene;
    AdDraw.Flip;
  end;

  Done := true;
end;

procedure TAdAppl.KeyDown(Sender: TObject; Key: Word; Shift: TAdShiftState);
begin
  if Key = AVK_ESCAPE then
    AdDraw.Window.Terminate;
end;

procedure TAdAppl.MouseMove(Sender: TObject; Shift: TAdShiftState; X,
  Y: integer);
begin
  MouseX := X;
  MouseY := Y;
end;

procedure TAdAppl.Run;
begin
  AdDraw := TAdDraw.Create(nil);

  {$IFDEF FPC}
    {$IFDEF WIN32}
      AdDraw.DllName := 'AndorraOGLLaz.dll';
    {$ELSE}
      AdDraw.DllName := 'libAndorraOGLLaz.so';
    {$ENDIF}
  {$ELSE}
    AdDraw.DllName := 'AndorraOGL.dll';
  {$ENDIF}


  with AdDraw.Display do
  begin
    Width := 800;
    Height := 600;
    BitDepth := ad32Bit;
  end;
  if AdDraw.Initialize then
  begin
    AdDraw.Window.Events.OnIdle := Idle;
    AdDraw.Window.Events.OnMouseMove := MouseMove;
    AdDraw.Window.Events.OnKeyDown := KeyDown;
    AdDraw.Window.Title := 'Andorra 2D';

    AdImage := TAdImage.Create(AdDraw);
    AdImage.Texture.LoadGraphicFromFile('icon64.png');
    AdImage.Restore;

    AdDraw.Run;

    AdImage.Free;
  end;
  AdDraw.Free;
end;

end.
