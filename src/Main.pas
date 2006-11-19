{This is a simple test unit for Andorra 2D}
unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, AdDraws, StdCtrls, ExtCtrls, Andorra, AndorraUtils;

type
  TFmMain = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
    AdDraw1:TAdDraw;
    AdImage:TPictureCollectionItem;
    procedure ApplicationIdle(Sender:TObject;var Done:boolean);
  end;

var
  FmMain: TFmMain;
  AdImg:TAndorraImage;
  i:single;
  sx,sy,ax,ay:single;
  tg,lt:double;
  fc,cw,ch:integer;

implementation

{$R *.dfm}

procedure TFmMain.FormCreate(Sender: TObject);
var bmp:TBitmap;
begin
  Application.OnIdle := ApplicationIdle;

  AdDraw1 := TAdDraw.Create(Handle);
  AdDraw1.Options := [doHardware];
  AdDraw1.DllName := 'AndorraDX93D.dll';
  if not AdDraw1.Initialize then
  begin
    Application.Terminate;
  end;
  AdImage := TPictureCollectionItem.Create(AdDraw1);
  bmp := TBitmap.Create;
  bmp.LoadFromFile('texture.bmp');
  AdImage.Texture.LoadFromBitmap(bmp);
  AdImage.Texture.AddAlphaChannel(bmp);
  bmp.Free;
  AdImage.Restore;
  AdImage.Color := clYellow;

  sx := 0.2;
  sy := 0.05;

  cw := ClientWidth;
  ch := ClientHeight;

  tg := 0;
  lt := GetTickCount;

  i := 0;
end;

procedure TFmMain.FormDestroy(Sender: TObject);
begin
  AdDraw1.Finalize;
  AdDraw1.Free;
end;

procedure TFmMain.ApplicationIdle(Sender: TObject; var Done: Boolean);
begin
  tg := tg+(GetTickCount-lt);
  lt := GetTickCount;
  fc := fc + 1;
  if tg > 1000 then
  begin
    Caption := 'FPS: '+inttostr(fc);
    fc := 0;
    tg := 0;
  end;
  AdDraw1.BeginScene;
  AdDraw1.ClearSurface(clBlack);
  i := i + 0.05;
  if i > 360 then i := 0;
  AdImage.Draw(AdDraw1,round(ax),round(ay),0);
  AdImage.Draw(AdDraw1,cw-round(ax)-128,ch-round(ay)-128,0);

  ax := ax + sx;
  ay := ay + sy;
  if (ax + AdImage.Width > cw) or (ax < 0) then
    sx := -sx;
  if (ay + AdImage.Height > ch) or (ay < 0) then
    sy := -sy;

  AdDraw1.EndScene;

  AdDraw1.Flip;
  Done := false;
end;

end.

