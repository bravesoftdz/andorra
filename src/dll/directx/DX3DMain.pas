{
* This program is licensed under the GNU Lesser General Public License Version 2
* You should have recieved a copy of the license with this file.
* If not, see http://www.gnu.org/licenses/lgpl.html for more informations
*
* Project: Andorra 2D
* Author:  Andreas Stoeckel
* File: DX3DMain.pas
* Comment: The Direct 3D DLL 
}

unit DX3DMain;

interface

uses d3d9, d3dx9, AndorraUtils, Classes, Windows, Graphics;

type TAndorraApplicationItem = class
  public
    Direct3d9:IDirect3D9;
    Direct3d9Device:IDirect3dDevice9;
    SizeX,SizeY:integer;
    TextureFilter:TD3DTextureFilterType;
end;

type TAndorraTextureItem = class
  public
    AAppl:TAndorraApplication;
    ATexWidth,ATexHeight:integer;
    AFormat:TD3DFormat;
    ATexture:IDirect3DTexture9;
    destructor Destroy;override;
end;

type TAndorraImageItem = class
  private
    FAppl:TAndorraApplication;
    FVertexBuffer:IDirect3DVertexBuffer9;
    FImage:IDirect3DTexture9;
    FWidth,FHeight:integer;
    FColor:TAndorraColor;
    FSrcRect:TRect;
    procedure SetSourceRect(ARect:TRect);
    function CompRects(Rect1,Rect2:TRect):boolean;
  protected
    function SetupBuffer:HRESULT; 
  public
    constructor Create(Appl:TAndorraApplication);
    procedure Draw(DestApp:TAndorraApplication;DestRect,SourceRect:TRect;Rotation:integer;RotCenterX,RotCenterY:single;BlendMode:TAndorraBlendMode);
    procedure LoadTexture(ATexture:TAndorraTexture);
    procedure SetColor(AColor:TAndorraColor);
    destructor Destroy;override;
    function GetImageInfo:TImageInfo;
end;


//Initialization
function CreateApplication:TAndorraApplication;stdcall;
procedure DestroyApplication(Appl:TAndorraApplication);stdcall;
function GetLastError:PChar;stdcall;
function InitDisplay(Appl:TAndorraApplication; AWindow:hWnd; doHardware:boolean=true;
                     fullscreen:boolean=false; bitcount:byte=32;
                     resx:integer=0; resy:integer=0):boolean;stdcall;
procedure SetTextureQuality(Appl:TAndorraApplication;Quality:TAndorraTextureQuality);stdcall;

//Render Control
procedure BeginScene(Appl:TAndorraApplication);stdcall;
procedure EndScene(Appl:TAndorraApplication);stdcall;
procedure ClearScene(Appl:TAndorraApplication;AColor:TAndorraColor);stdcall;
procedure SetupScene(Appl:TAndorraApplication;AWidth,AHeight:integer);stdcall;
procedure Flip(Appl:TAndorraApplication);stdcall;

//SpriteControl
function CreateImage(Appl:TAndorraApplication):TAndorraImage;stdcall;
procedure DrawImage(DestApp:TAndorraApplication;Img:TAndorraImage;DestRect,SourceRect:TRect;Rotation:integer;
  RotCenterX,RotCenterY:single;BlendMode:TAndorraBlendMode);stdcall;
procedure DestroyImage(Img:TAndorraImage);stdcall;
procedure ImageLoadTexture(Img:TAndorraImage;ATexture:TAndorraTexture);stdcall;
procedure SetImageColor(Img:TAndorraImage;AColor:TAndorraColor);stdcall;
function GetImageInfo(Img:TAndorraImage):TImageInfo;stdcall;

//Texture Creation
function LoadTextureFromFile(Appl:TAndorraApplication;AFile:PChar;ATransparentColor:TAndorraColor):TAndorraTexture;stdcall;
function LoadTextureFromFileEx(Appl:TAndorraApplication;AFile:PChar;AWidth,AHeight:integer;AColorDepth:byte;ATransparentColor:TAndorraColor):TAndorraTexture;stdcall;
function LoadTextureFromBitmap(Appl:TAndorraApplication;ABitmap:Pointer;AColorDepth:byte):TAndorraTexture;stdcall;
procedure FreeTexture(ATexture:TAndorraTexture);stdcall;
procedure AddTextureAlphaChannel(ATexture:TAndorraTexture;ABitmap:Pointer);stdcall;

//Our Vertex and the definition of the flexible vertex format (FVF)
type TD3DLVertex = record
  position: TD3DXVector3;
  diffuse: TD3DColor;
  textur1: TD3DXVector2;
end;

const
  D3DFVF_TD3DLVertex = D3DFVF_XYZ or D3DFVF_DIFFUSE or D3DFVF_TEX1;

//Stores error messages
var
  ErrorLog:TStringList;

implementation

//The Andorra Texture
destructor TAndorraTextureItem.Destroy;
begin
  if ATexture <> nil then
  begin
    ATexture._Release;
    ATexture := nil;
  end;
  inherited Destroy;
end;

//The Andorra Image
constructor TAndorraImageItem.Create(Appl: Pointer);
begin
  inherited Create;
  if Appl <> nil then
  begin
    FAppl := Appl;
    FColor := Ad_ARGB(255,255,255,255);
  end
  else
  begin
    ErrorLog.Add('Application is nil');
    Free;
  end;
end;

procedure TAndorraImageItem.SetSourceRect(ARect: TRect);
begin
  FSrcRect.Left := ARect.Left;
  FSrcRect.Right := ARect.Right;
  FSrcRect.Top := ARect.Top;
  FSrcRect.Bottom := ARect.Bottom;
  SetupBuffer;
end;

procedure TAndorraImageItem.SetColor(AColor:TAndorraColor);
begin
  FColor := AColor;
  SetupBuffer;
end;

function TAndorraImageItem.SetupBuffer;
var
  Vertices: Array[0..3] of TD3DLVertex;
  pVertices: Pointer;
begin
  //Create Plane


  //0-----2
  //|    /|
  //|  /  |
  //|/    |
  //1-----3

  Vertices[0].position := D3DXVector3(0,0,0);
  Vertices[0].diffuse := D3DColor_ARGB(FColor.a,FColor.r,FColor.g,FColor.b);
  Vertices[0].textur1 := D3DXVector2(FSrcRect.Left/FWidth,FSrcRect.Top/FHeight);

  Vertices[1].position := D3DXVector3(0,FHeight,0);
  Vertices[1].diffuse := D3DColor_ARGB(FColor.a,FColor.r,FColor.g,FColor.b);
  Vertices[1].textur1 := D3DXVector2(FSrcRect.Left/FWidth,FSrcRect.Bottom/FHeight);

  Vertices[2].position := D3DXVector3(FWidth,0,0);
  Vertices[2].diffuse := D3DColor_ARGB(FColor.a,FColor.r,FColor.g,FColor.b);
  Vertices[2].textur1 := D3DXVector2(FSrcRect.Right/FWidth,FSrcRect.Top/FHeight);

  Vertices[3].position := D3DXVector3(FWidth,FHeight,0);
  Vertices[3].diffuse := D3DColor_ARGB(FColor.a,FColor.r,FColor.g,FColor.b);
  Vertices[3].textur1 := D3DXVector2(FSrcRect.Right/FWidth,FSrcRect.Bottom/FHeight);

  //Create Vertexbuffer and store the vertices
  with TAndorraApplicationItem(FAppl) do
  begin
    //Create Vertexbuffer
    result := Direct3D9Device.CreateVertexBuffer(Sizeof(TD3DLVertex)*3,
      D3DUSAGE_WRITEONLY, D3DFVF_TD3DLVertex, D3DPOOL_DEFAULT,
      fvertexbuffer, nil);
    if result <> D3D_OK then exit;

    //Lock the buffer
    result := fvertexbuffer.Lock(0,SizeOf(TD3DLVertex)*3, pVertices, 0);
    if result <> D3D_OK then exit;

    //Move the Vertices into the buffer
    Move(Vertices, pVertices^, Sizeof(Vertices));

    result := fvertexbuffer.Unlock;
  end;
end;

function TAndorraImageItem.CompRects(Rect1,Rect2:TRect):boolean;
begin
  result := (Rect1.Left = Rect2.Left) and
            (Rect1.Right = Rect2.Right) and
            (Rect1.Top = Rect2.Top) and
            (Rect1.Bottom = Rect2.Bottom);
end;

procedure TAndorraImageItem.Draw(DestApp:TAndorraApplication;DestRect,SourceRect:TRect;Rotation:integer;
  RotCenterX,RotCenterY:single;BlendMode:TAndorraBlendMode);
var matTrans1,matTrans2:TD3DXMatrix;
    curx,cury:single;
begin
  with TAndorraApplicationItem(DestApp) do
  begin
    if (FWidth > 0) and (FHeight > 0) and (FImage <> nil) then
    begin

      if not CompRects(SourceRect,FSrcRect) then
      begin
        SetSourceRect(SourceRect);
      end;

      //Initialize "The Matrix"
      matTrans1 := D3DXMatrixIdentity;
      matTrans2 := D3DXMatrixIdentity;

      //Set Blendmode
      if BlendMode = bmAdd then
      begin
        Direct3D9Device.SetRenderState(D3DRS_SRCBLEND,D3DBLEND_ONE);
        Direct3D9Device.SetRenderState(D3DRS_DESTBLEND,D3DBLEND_ONE);
      end;
 
      //Scale the Box
      D3DXMatrixScaling(matTrans1,(DestRect.Right-DestRect.Left)/FWidth,
        (DestRect.Bottom-DestRect.Top)/FHeight,0);
      D3DXMatrixMultiply(matTrans2,matTrans1,matTrans2);

      if (Rotation <> 0) then
      begin
        CurX := (DestRect.Right-DestRect.Left)*RotCenterX;
        CurY := (DestRect.Bottom-DestRect.Top)*RotCenterY;

        D3DXMatrixTranslation(matTrans1,-CurX,-CurY,0);
        D3DXMatrixMultiply(matTrans2,matTrans2,matTrans1);

        D3DXMatrixRotationZ(matTrans1,Rotation/360*2*PI);
        D3DXMatrixMultiply(matTrans2,matTrans2,matTrans1);

        D3DXMatrixTranslation(matTrans1,CurX,CurY,0);
        D3DXMatrixMultiply(matTrans2,matTrans2,matTrans1);
      end;

      //Translate the Box
      D3DXMatrixTranslation(matTrans1,DestRect.Left,DestRect.Top,0);
      D3DXMatrixMultiply(matTrans2,matTrans2,matTrans1);

      with Direct3D9Device do
      begin
        SetTexture(0,FImage);
        SetTransform(D3DTS_WORLD, matTrans2);
        SetStreamSource(0, FVertexbuffer, 0, SizeOf(TD3DLVertex));
        SetFVF(D3DFVF_TD3DLVertex);
        DrawPrimitive(D3DPT_TRIANGLESTRIP,0,2);
      end;
      
      if BlendMode <> bmAlpha then
      begin
        Direct3D9Device.SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA);
        Direct3D9Device.SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);
      end;
    end;
  end;
end;

procedure TAndorraImageItem.LoadTexture(ATexture:TAndorraTexture);
begin
  with TAndorraTextureItem(ATexture) do
  begin
    FImage := ATexture;
    FWidth := ATexWidth;
    FHeight := ATexHeight;
    FSrcRect.Left   := 0;
    FSrcRect.Top    := 0;
    FSrcRect.Right  := ATexWidth;
    FSrcRect.Bottom := ATexHeight;
    SetupBuffer;
  end;
end;

function TAndorraImageItem.GetImageInfo;
begin
  result.Width := FWidth;
  result.Height := FHeight;
end;

destructor TAndorraImageItem.Destroy;
begin
  FVertexBuffer := nil;
  FImage := nil;
  inherited Destroy;
end;


//Initialization
function CreateApplication:TAndorraApplication;
begin
  result := TAndorraApplicationItem.Create;
  with TAndorraApplicationItem(result) do
  begin
    //Create Direct 3D Interface
    Direct3D9 := Direct3DCreate9( D3D_SDK_VERSION );
    if Direct3D9 = nil then
    begin
      result := nil;
      ErrorLog.Add('Can not create Direct3D Interface.');
    end;
  end;
end;

function InitDisplay(Appl:TAndorraApplication; AWindow:hWnd; doHardware:boolean;
  fullscreen:boolean; bitcount:byte; resx:integer; resy:integer):boolean;
var
  d3dpp:TD3DPresent_Parameters;
  d3ddm:TD3DDisplayMode;
  D3DCaps9:TD3DCaps9;
  dtype:TD3DDevType;
  hvp:boolean;
  vp : Integer;
  total:LongWord;
begin
  result := false;
  if Appl <> nil then
  begin
    with TAndorraApplicationItem(Appl) do
    begin
      if Direct3D9 = nil then
      begin
        ErrorLog.Add('Direct3D9 is nil.');
        exit;
      end;

      //Clear the Present Parameters Array
      Fillchar(d3dpp,sizeof(d3dpp),0);
      with d3dpp do
      begin
        Windowed := not fullscreen;
        SwapEffect := D3DSWAPEFFECT_DISCARD;
        FullScreen_PresentationInterval := D3DPRESENT_INTERVAL_IMMEDIATE;

        //Set Presentation Parameters
        if Fullscreen then
        begin
          BackBufferWidth := ResX;
          BackBufferHeight := ResY;
          case bitcount of
            16: BackBufferFormat := D3DFMT_R5G6B5;
            24: BackBufferFormat := D3DFMT_R8G8B8;
            32: BackBufferFormat := D3DFMT_A8R8G8B8;
            else
              BackBufferFormat := D3DFMT_A8R8G8B8;
          end;
        end
        else
        begin
          if failed(Direct3D9.GetAdapterDisplayMode(
            D3DADAPTER_DEFAULT, d3ddm)) then
          begin
            ErrorLog.Add('Error while setting displaymode');
            exit;
          end
          else
          begin
            BackbufferFormat := d3ddm.Format;
          end;
        end;
      end;

      //Is HardwareVertexProcessing supported?
      Direct3D9.GetDeviceCaps(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, D3DCaps9);
      hvp := D3DCaps9.DevCaps and D3DDEVCAPS_HWTRANSFORMANDLIGHT <> 0;

      if hvp then
        vp := D3DCREATE_HARDWARE_VERTEXPROCESSING
      else
        vp := D3DCREATE_SOFTWARE_VERTEXPROCESSING;

      //Set weather to use HAL
      if doHardware then
        dtype := D3DDEVTYPE_HAL
      else
        dtype := D3DDEVTYPE_REF;

      if failed(Direct3D9.CreateDevice(D3DADAPTER_DEFAULT, dtype, awindow,
          vp, d3dpp, Direct3D9Device)) then
      begin
        Errorlog.Add('Error while creating display (DIRECT3D9DEVICE)');
        exit;
      end;

      SizeX := ResX;
      SizeY := ResY;

      //No lighting
      Direct3D9Device.SetRenderState(D3DRS_LIGHTING, 0);

      //No culling
      Direct3D9Device.SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);

      //Enable Texture alphablending
      Direct3D9Device.SetRenderState(D3DRS_ALPHABLENDENABLE, LongWord(TRUE));
      Direct3D9Device.SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA);
      Direct3D9Device.SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);
      Direct3D9Device.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
    end;
  end;

  result := true;
end;

procedure DestroyApplication(Appl:TAndorraApplication);
begin
  with TAndorraApplicationItem(Appl) do
  begin
    Direct3d9 := nil;
    Direct3d9Device := nil;
    Free;
  end;
end;

function GetLastError:PChar;
begin
  //Return last Andorra Error
  result := '';
  if ErrorLog.Count > 0 then
  begin
    result := PChar(ErrorLog[ErrorLog.Count-1]);
  end;
end;

//Render Control
procedure BeginScene(Appl:TAndorraApplication);
begin
  if Appl <> nil then
  begin
    with TAndorraApplicationItem(Appl) do
    begin
      Direct3D9Device.BeginScene;
    end;
  end;
end;

procedure EndScene(Appl:TAndorraApplication);
begin
  if Appl <> nil then
  begin
    with TAndorraApplicationItem(Appl) do
    begin
      Direct3D9Device.EndScene;
    end;
  end;
end;

procedure Flip(Appl:TAndorraApplication);
begin
  if Appl <> nil then
  begin
    with TAndorraApplicationItem(Appl) do
    begin
      Direct3D9Device.Present(nil, nil, 0, nil);
    end;
  end;
end;

procedure ClearScene(Appl:TAndorraApplication;AColor:TAndorraColor);
begin
  if Appl <> nil then
  begin
    with TAndorraApplicationItem(Appl) do
    begin
      Direct3D9Device.Clear( 0, nil, D3DCLEAR_TARGET, D3DCOLOR_ARGB(AColor.a,AColor.r,AColor.g,AColor.b),
        1.0, 0);
    end;
  end;
end;

procedure SetupScene(Appl:TAndorraApplication;AWidth,AHeight:integer);
var pos, dir, up : TD3DXVector3;
    matView, matProj: TD3DXMatrix;
begin
  if Appl <> nil then
  begin
    with TAndorraApplicationItem(Appl) do
    begin
      pos := D3DXVector3 (Awidth/2,AHeight/2,-10);
      dir := D3DXVector3 (Awidth/2,AHeight/2,0);
      up := D3DXVector3 (0,-1,0);

      D3DXMatrixLookAtRH( matView, pos, dir, up);
      Direct3d9Device.SetTransform(D3DTS_VIEW, matView);

      D3DXMatrixOrthoRH( matProj, Awidth, Aheight, 0,100);
      Direct3d9Device.SetTransform(D3DTS_PROJECTION, matProj);
    end;
  end;
end;

procedure SetTextureQuality(Appl:TAndorraApplication;Quality:TAndorraTextureQuality);
begin
  with TAndorraApplicationItem(Appl) do
  begin
    case Quality of
      tqNone: TextureFilter := D3DTEXF_POINT;
      tqLinear: TextureFilter := D3DTEXF_LINEAR;
      tqAnisotropic: TextureFilter := D3DTEXF_ANISOTROPIC;
    end;
    Direct3D9Device.SetSamplerState(0,D3DSAMP_MAGFILTER, TextureFilter);
    Direct3D9Device.SetSamplerState(0,D3DSAMP_MINFILTER, TextureFilter);
  end;
end;

//Image Controls

function CreateImage(Appl:TAndorraApplication):TAndorraImage;
begin
  result := TAndorraImageItem.Create(Appl);
end;

procedure DestroyImage(Img:TAndorraImage);
begin
  if Img <> nil then
  begin
    TAndorraImageItem(Img).Destroy;
  end;
end;

procedure DrawImage(DestApp:TAndorraApplication;Img:TAndorraImage;DestRect,SourceRect:TRect;Rotation:integer;
  RotCenterX,RotCenterY:single;BlendMode:TAndorraBlendMode);
begin
  if Img <> nil then
  begin
    TAndorraImageItem(Img).Draw(DestApp,DestRect,SourceRect,Rotation,RotCenterX,RotCenterY,Blendmode);
  end;
end;

procedure ImageLoadTexture(Img:TAndorraImage;ATexture:TAndorraTexture);
begin
  if Img <> nil then
  begin
    TAndorraImageItem(Img).LoadTexture(ATexture);
  end;
end;

function AdColorToD3DColor_ARGB(AColor:TAndorraColor):TD3DColor;
begin
  result := D3DColor_ARGB(AColor.a, AColor.r, AColor.g, AColor.b);
end;

procedure SetImageColor(Img:TAndorraImage;AColor:TAndorraColor);
begin
  if Img <> nil then
  begin
    TAndorraImageItem(Img).SetColor(AColor);
  end;
end;

function GetImageInfo(Img:TAndorraImage):TImageInfo;
begin
  if Img <> nil then
  begin
    result := TAndorraImageItem(Img).GetImageInfo;
  end;
end;


//Texture Creation
function LoadTextureFromFile(Appl:TAndorraApplication;AFile:PChar;ATransparentColor:TAndorraColor):TAndorraTexture;
var Info:TD3DXImageInfo;
begin
  result := TAndorraTextureItem.Create;
  with TAndorraApplicationItem(Appl) do
  begin
    with TAndorraTextureItem(result) do
    begin
      AAppl := Appl;
      D3DXCreateTextureFromFileEx( Direct3D9Device, AFile, D3DX_DEFAULT, D3DX_DEFAULT,
          0, 0, D3DFMT_UNKNOWN, D3DPOOL_DEFAULT, TextureFilter, TextureFilter,
          AdColorToD3DColor_ARGB(ATransparentColor) , Info, nil, ATexture);
      ATexWidth := Info.Width;
      ATexHeight := Info.Height;
      AFormat := Info.Format;
    end;
  end;
end;

function LoadTextureFromFileEx(Appl:TAndorraApplication;AFile:PChar;AWidth,AHeight:integer;AColorDepth:byte;ATransparentColor:TAndorraColor):TAndorraTexture;
var Info:TD3DXImageInfo;
    Format:TD3DFormat;
begin
  result := TAndorraTextureItem.Create;
  with TAndorraApplicationItem(Appl) do
  begin
    with TAndorraTextureItem(result) do
    begin
      AAppl := Appl;
      case AColorDepth of
        16: Format := D3DFMT_A4R4G4B4;
        32: Format := D3DFMT_A8R8G8B8;
      else
        Format := D3DFMT_UNKNOWN;
      end;
      D3DXCreateTextureFromFileEx( Direct3D9Device, AFile, AWidth,AHeight,
          0, 0, Format, D3DPOOL_DEFAULT, TextureFilter, TextureFilter,
          AdColorToD3DColor_ARGB(ATransparentColor) ,Info, nil, ATexture);
      ATexWidth := Info.Width;
      ATexHeight := Info.Height;
      AFormat := Info.Format;
    end;
  end;
end;

type TRGBRec = packed record
  r,g,b:byte;
end;

type PRGBRec = ^TRGBRec;

procedure FreeTexture(ATexture:TAndorraTexture);
begin
  IDirect3DTexture9(ATexture)._Release;
end;


//Convert a 8 Bit Color to a 4 Bit Color
function R8ToR4(r:byte):byte;
begin
  result := (r div 16);
end;

//Converts a A8R8G8B8 Value to a A4R4G4B4
function RGBTo16Bit(a,r,g,b:byte):Word;
begin
  Result := (R8ToR4(a) shl 12) or (R8ToR4(r) shl 8)
                        or (R8ToR4(g) shl 4)
                        or R8ToR4(b);
end;

function LoadTextureFromBitmap(Appl:TAndorraApplication;ABitmap:Pointer;AColorDepth:byte):TAndorraTexture;
var d3dlr: TD3DLocked_Rect;
    Cursor32: pLongWord;
    Cursor16: pWord;
    BitCur: PRGBRec;
    x,y:integer;  
begin
  //Set Result to nil
  result := TAndorraTextureItem.Create;

  with TAndorraApplicationItem(Appl) do
  begin
    with TBitmap(ABitmap) do
    begin
      with TAndorraTextureItem(Result) do
      begin
        AAppl := Appl;
        //Set the Textures Pixel Format
        case AColorDepth of
          16: AFormat := D3DFMT_A4R4G4B4;
          24: AFormat := D3DFMT_A8R8G8B8;
          32: AFormat := D3DFMT_A8R8G8B8;
        else
          AFormat := D3DFMT_A8R8G8B8;
        end;
        ATexWidth := Width;
        ATexHeight := Height;
        //Set the Pixel Format of the Bitmap to 24 Bit
        PixelFormat := pf24Bit;

        //Create the Texture
        if D3DXCreateTexture(Direct3D9Device, Width, Height, 0, 0, AFormat, D3DPOOL_MANAGED, ATexture) = D3D_OK then
        begin
          ATexture.LockRect(0, d3dlr, nil, 0);

          if (AFormat = D3DFMT_A8R8G8B8) then
          begin
            Cursor32 := d3dlr.Bits;

            for y := 0 to Height-1 do
            begin
              BitCur := Scanline[y];
              for x := 0 to Width-1 do
              begin
                Cursor32^ := D3DColor_ARGB(255,BitCur^.b,BitCur^.g,BitCur^.r);
                inc(BitCur);
                inc(Cursor32);
              end;
            end;
          end;

          if AFormat = D3DFMT_A4R4G4B4 then
          begin
            Cursor16 := d3dlr.Bits;
            for y := 0 to Height-1 do
            begin
              BitCur := Scanline[y];
              for x := 0 to Width-1 do
              begin
                Cursor16^ := RGBTo16Bit(255,BitCur^.b,BitCur^.g,BitCur^.r);
                inc(BitCur);
                inc(Cursor16);
              end;
            end;
          end;
        end;
        ATexture.UnlockRect(0);
      end;
    end;
  end;
end;

procedure AddTextureAlphaChannel(ATexture:TAndorraTexture;ABitmap:Pointer);
var d3dlr: TD3DLocked_Rect;
    Cursor32: pLongWord;
    Cursor16: pWord;
    BitCur: PRGBRec;
    x,y:integer;
    temp:Word;
begin
  //Set Result to nil
  with TAndorraTextureItem(ATexture) do
  begin
    with TBitmap(ABitmap) do
    begin
      with TAndorraApplicationItem(AAppl) do
      begin
        //Set the Pixel Format of the Bitmap to 24 Bit
        PixelFormat := pf24Bit;

        ATexture.LockRect(0, d3dlr, nil, 0);

        if AFormat = D3DFMT_A8R8G8B8 then
        begin
          Cursor32 := d3dlr.Bits;
          for y := 0 to Height-1 do
          begin
            BitCur := Scanline[y];
            for x := 0 to Width-1 do
            begin
              Cursor32^ := (((BitCur^.b+BitCur^.g+BitCur^.r) div 3) shl 24) or (Cursor32^ and $00FFFFFF) ;
              inc(BitCur);
              inc(Cursor32);
            end;
          end;
        end;

        if AFormat = D3DFMT_A4R4G4B4 then
        begin
          Cursor16 := d3dlr.Bits;
          for y := 0 to Height-1 do
          begin
            BitCur := Scanline[y];
            for x := 0 to Width-1 do
            begin
              Cursor16^ := (((BitCur^.b+BitCur^.g+BitCur^.r) div 48) shl 12) or (Cursor16^ and $0FFF) ;
              inc(BitCur);
              inc(Cursor16);
            end;
          end;
        end;
      end;
      ATexture.UnlockRect(0);
    end;
  end;
end;

initialization
  ErrorLog := TStringList.Create;

finalization
  ErrorLog.Free;
  
end.
