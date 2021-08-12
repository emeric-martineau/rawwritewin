program rawwritewin;

uses
  Forms,
  rawwrite in 'rawwrite.pas' {MainForm},
  BlockDev in 'BlockDev.pas',
  XPTheme in 'XPTheme.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'RawWrite for Windows';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
