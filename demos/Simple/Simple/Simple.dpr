program Simple;

uses
  Forms,
  Main in 'Main.pas' {Form1},
  AdDraws in '..\..\..\src\AdDraws.pas',
  AdParticles in '..\..\..\src\AdParticles.pas',
  AdSprites in '..\..\..\src\AdSprites.pas',
  Andorra in '..\..\..\src\Andorra.pas',
  AndorraUtils in '..\..\..\src\AndorraUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Andorra 2D Simple Demo';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.