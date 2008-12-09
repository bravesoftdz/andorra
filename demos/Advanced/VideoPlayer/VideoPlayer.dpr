program VideoPlayer;

//Set a icon for the application when using windows
{$IFDEF WIN32}
  {$R '..\..\icon.res' '..\..\icon.rc'}
{$ENDIF}

uses
  Main in 'Main.pas';

var
  Appl: TAdAppl;

begin
  Appl := TAdAppl.Create;
  Appl.Run;
  Appl.Free;
end.
