program rawwritewin;

uses
  Forms,
  rawwrite in 'rawwrite.pas' {MainForm},
  DiskIO in 'DiskIO.pas',
  QTThunkU in 'QTThunkU.pas',
  BlockDev in 'BlockDev.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'RawWrite for Windows';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
