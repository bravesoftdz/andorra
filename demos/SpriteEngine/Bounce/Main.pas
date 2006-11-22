unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, AdDraws, AdSprites, AndorraUtils;

type
  TForm1 = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { Private-Deklarationen }
  public
    AdDraw:TAdDraw;
    AdSpriteEngine:TSpriteEngine;
    AdPictureCollection:TPictureCollection;
    procedure ApplicationIdle(Sender:TObject;var Done:boolean);
    { Public-Deklarationen }
  end;

  TWall = class(TImageSprite);

  TBall = class(TImageSpriteEx)
    private
      Falling:boolean;
      WillDie:boolean;
    public
      SX,SY:double;
      SourceX,SourceY:integer;
      Color:TColor;
      procedure DoDraw;override;
      constructor Create(AParent:TSprite);override;
      procedure DoMove(TimeGap:double);override;
      procedure DoCollision(Sprite:TSprite; var Done:boolean);override;
      procedure Coll;
  end;

var
  Form1: TForm1;
  lx,ly:integer;
  timegap:double;
  lasttime:double;
  framecount:integer;

const
  path='demos\SpriteEngine\Bounce\';

implementation

{$R *.dfm}

procedure TForm1.ApplicationIdle(Sender: TObject; var Done: boolean);
var tg:double;
begin
  //Calculate FPS
  tg := (gettickcount-lasttime);
  timegap := timegap + tg;
  lasttime := gettickcount;
  framecount := framecount+1;

  if timegap > 1000 then
  begin
    caption := 'FPS: '+inttostr(framecount);
    timegap := 0;
    framecount := 0;
  end;
  
  AdDraw.BeginScene;
  AdDraw.ClearSurface(clSkyBlue);
  AdSpriteEngine.Move(tg/1000);
  AdSpriteEngine.Draw;
  AdSpriteEngine.Dead;
  AdDraw.EndScene;
  AdDraw.Flip;

  Done := false;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  ax,ay: Integer;
  level:TStringList;
begin
  Randomize;

  Application.OnIdle := ApplicationIdle;
  AdDraw := TAdDraw.Create(Handle);
  AdDraw.DllName := 'AndorraDX93D.dll';
  AdDraw.Options := AdDraw.Options+[doLights];
  AdDraw.Initialize;

  AdPictureCollection := TPictureCollection.Create(AdDraw);
  AdPictureCollection.Add('wall').Texture.LoadFromFile(path+'texture.bmp',false,clWhite);
  AdPictureCollection.Add('wallgras').Texture.LoadFromFile(path+'texture2.bmp',false,clWhite);
  with AdPictureCollection.Add('sky') do
  begin
    Texture.LoadFromFile(path+'sky.png',false,clBlack);
    Color := clSkyBlue;
  end;
  with AdPictureCollection.Add('ball') do
  begin
    Texture.LoadFromFile(path+'ball.bmp',true,clYellow);
    PatternWidth := 32;
    PatternHeight := 32;
  end;
  AdPictureCollection.Restore;
  
  AdSpriteEngine := TSpriteEngine.Create(nil);
  AdSpriteEngine.Surface := AdDraw;

  level := TStringList.Create;
  level.LoadFromFile(path+'level.txt');

  with TBackgroundSprite.Create(AdSpriteEngine) do
  begin
    Z := -10;
    Image := AdPictureCollection.Find('sky');
    Tiled := true;
    Depth := 10;
  end;  

  for ay := 0 to level.Count - 1 do
  begin
    for ax := 1 to length(level[ay]) do
    begin
      case level[ay][ax] of
        'x':
        begin
          with TWall.Create(AdSpriteEngine) do
          begin
            Image := AdPictureCollection.Find('wall');
            x := ax*128;
            y := ay*128;
          end;
        end;
        'X':
        begin
          with TWall.Create(AdSpriteEngine) do
          begin
            Image := AdPictureCollection.Find('wallgras');
            x := ax*128;
            y := ay*128;
          end;
        end;
        'b':
        begin
          with TBall.Create(AdSpriteEngine) do
          begin
            Image := AdPictureCollection.Find('ball');
            x := ax*128;
            y := ay*128+128-height;
            sourcex := round(x);
            sourcey := round(y);
          end;
        end;
      end;
    end;
  end;
  level.Free;
  lasttime := GetTickCount;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  AdSpriteEngine.Free;
  AdPictureCollection.Free;
  AdDraw.Finalize;
  AdDraw.Free;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key = VK_LEFT then
  begin
    AdSpriteEngine.X := AdSpriteEngine.X + 10;
  end;
  if key = VK_RIGHT then
  begin
    AdSpriteEngine.X := AdSpriteEngine.X - 10;
  end;
  if key = VK_UP then
  begin
    AdSpriteEngine.Y := AdSpriteEngine.Y + 10;
  end;
  if key = VK_DOWN then
  begin
    AdSpriteEngine.Y := AdSpriteEngine.Y - 10;
  end;
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  lx := x;
  ly := y;
end;

procedure TForm1.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if ssLeft in Shift then
  begin
    AdSpriteEngine.X := AdSpriteEngine.X + X - Lx;
    AdSpriteEngine.Y := AdSpriteEngine.Y + Y - Ly;
    Lx := X;
    Ly := Y;
  end;
end;

{ TBall }

procedure TBall.Coll;
begin
  WillDie := true;
  with TBall.Create(Engine) do
  begin
    Image := self.Image;
    x := self.sourcex;
    y := self.sourcey;
    sourcex := round(x);
    sourcey := round(y);
    Color := self.Color;
  end;
  CanDoCollisions := false;
end;

constructor TBall.Create(AParent: TSprite);
begin
  inherited Create(AParent);

  sy := 200;
  if random(2) = 0 then sx := -200 else sx := 200;

  AnimSpeed := 4;

  Alpha := 0;

  Color := RGB(random(255),random(255),random(255));
end;

procedure TBall.DoCollision(Sprite: TSprite; var Done: boolean);
begin
  if Sprite is TWall then
  begin
    falling := false;
    SY := 128;
    if Sprite.Y > Y then
    begin
      Y := Sprite.Y-Height+1;
    end
    else
    begin
      if (Sprite.X+Sprite.Width > X) and (SX < 0) then
      begin
        SX := -SX;
        X := Sprite.X+Sprite.Width+1;
        exit;
      end;
      if (Sprite.X < X+Width) and (SX > 0) then
      begin
        SX := -SX;
        X := Sprite.X-Width-1;
        exit;
      end;
    end;
  end;
  if Sprite is TBall then
  begin
    Coll;
    TBall(Sprite).Coll;
    Done := true;
  end;
end;

procedure TBall.DoDraw;
begin
  Image.Color := Color;
  inherited DoDraw;
end;

procedure TBall.DoMove(TimeGap: double);
begin
  if not WillDie then
  begin
    inherited DoMove(TimeGap);

    if Alpha < 255 then
    begin
      Alpha := Alpha + 1000*TimeGap;
    end
    else
    begin
      Alpha := 255;
    end;

    falling := true;
    Collision;

    if falling then
    begin
      //SY := SY + SY * 0.000005;
      Y := Y + SY*TimeGap;
    end
    else
    begin
      Angle := Angle + 360*(SX/abs(SX))*TimeGap;
      if Angle > 360 then Angle := 0;
      X := X + SX*TimeGap;
    end;
  end
  else
  begin
    Alpha := Alpha - 1000*TimeGap;
    if Alpha <= 1 then Dead;    
  end;
end;

end.
