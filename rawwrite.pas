unit rawwrite;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, BlockDev;

const
   DebugHigh = 0;
   DebugOff = 0;
   DebugLow = 0;
type
  TMainForm = class(TForm)
    Label2: TLabel;
    StatusBar1: TStatusBar;
    FloppyImage: TImage;
    DriveComboBox: TComboBox;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Button3: TButton;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    Label1: TLabel;
    FileNameEdit: TEdit;
    Button1: TButton;
    OpenDialog1: TOpenDialog;
    DebugMemo: TMemo;
    Button2: TButton;
    Label7: TLabel;
    ReadFileNameEdit: TEdit;
    Button4: TButton;
    Button5: TButton;
    SaveDialog1: TSaveDialog;
    TabSheet3: TTabSheet;
    Memo1: TMemo;
    Label8: TLabel;
    Label9: TLabel;
    TabSheet4: TTabSheet;
    Label10: TLabel;
    Label11: TLabel;
    WriteCopyEdit: TEdit;
    UpDown1: TUpDown;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure DriveComboBoxDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure Button2Click(Sender: TObject);
    procedure Label5Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Label3DblClick(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure TabSheet3Show(Sender: TObject);
  private
    { Private declarations }
    OSis95 : Boolean;

    procedure Find95Floppy;
    procedure FindNTFloppy;

  public
    { Public declarations }
    procedure FindFloppy;
    procedure Wait;
    procedure UnWait;
  end;

var
  MainForm: TMainForm;


function ReadFile2(hFile: THandle; Buffer : Pointer; nNumberOfBytesToRead: DWORD;
   var lpNumberOfBytesRead: DWORD; lpOverlapped: POverlapped): BOOL; stdcall;
function WriteFile2(hFile: THandle; Buffer : Pointer; nNumberOfBytesToWrite: DWORD;
   var lpNumberOfBytesWritten: DWORD; lpOverlapped: POverlapped): BOOL; stdcall;

procedure Debug(Str : String; Level : Integer);

implementation

uses DiskIO, ShellAPI;

{$R *.DFM}

function ReadFile2; external kernel32 name 'ReadFile';
function WriteFile2; external kernel32 name 'WriteFile';

procedure Debug(Str : String; Level : Integer);
begin
   MainForm.DebugMemo.Lines.Add(Str);
end;

procedure TMainForm.Wait;
begin
   Screen.Cursor := crHourGlass;
end;

procedure TMainForm.UnWait;
begin
   Screen.Cursor := crDefault;
end;

procedure TMainForm.Button1Click(Sender: TObject);
begin
   OpenDialog1.FileName := FileNameEdit.Text;
   if OpenDialog1.Execute then
   begin
      FileNameEdit.Text := OpenDialog1.FileName;
   end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
   Version : TOSVersionInfo;
   VersionString : String;
   CommandLine : Boolean;
   CmdRead : Boolean;
   CmdCopies : Integer;
   CmdImage : String;
   CmdDrive : String;
   i : Integer;
begin
   // Prevent error messages being displayed by NT
   SetErrorMode(SEM_FAILCRITICALERRORS);

   // what OS
   Version.dwOSVersionInfoSize := Sizeof(Version);
   if GetVersionEx(Version) then
   begin
      case Version.dwPlatformId of
         VER_PLATFORM_WIN32s        : VersionString := 'WIN32s';
         VER_PLATFORM_WIN32_WINDOWS : VersionString := 'Windows 95';
         VER_PLATFORM_WIN32_NT      : VersionString := 'Windows NT';
      else
         VersionString := 'Unknown OS';
      end;
      VersionString := VersionString + ' ' + IntToStr(Version.dwMajorVersion) +
                                       '.' + IntToStr(Version.dwMinorVersion) +
                                       ' build number ' + IntToStr(Version.dwBuildNumber);
      StatusBar1.Panels[2].Text := VersionString;
      if Version.dwPlatformId = VER_PLATFORM_WIN32_WINDOWS then
      begin
         OSis95 := True;
      end
      else
      begin
         OSis95 := False;
      end;
   end
   else
   begin
      MessageDlg('Could not get Version info!', mtError, [mbOK], 0);
   end;
   FindFloppy;
   if DriveComboBox.Items.Count > 0 then
   begin
      DriveComboBox.ItemIndex := 0;
   end
   else
   begin
      MessageDlg('No Floppy drives found', mtInformation, [mbOK], 0);
   end;

   PageControl1.ActivePage := TabSheet1;
{
   if ParamCount > 0 then
   begin
      CommandLine := True;
      CmdRead := False;
      CmdCopies := 1;

      i := 1;
      while i <= ParamCount do
      begin
         if ParamStr(i) = '--read' then
         begin
            Inc(i);
            CmdRead := True;
         end
         else if ParamStr(i) = '--write' then
         begin
            Inc(i);
            CmdRead := False;
         end
         else if ParamStr(i) = '--write' then
         begin
            Inc(i);
            CmdCopies := StrToIntDef(ParamStr(i), 1);
            Inc(i);
         end
         else if ParamStr(i) = '--drive' then
         begin
            Inc(i);
            CmdDrive := ParamStr(i);
            Inc(i);
         end
         else
         begin
            if Pos('--', ParamStr(i)) = 1 then
            begin
               // unknown command
               MessageDlg('Unknown command line option ''' + ParamStr(i) + '''', mtError, [mbOK], 0);
               break;
            end
            else
            begin
               CmdImage := ParamStr(i);
               break;
            end;
         end;
      end;
      // check command line parameters
      // [--write] [--copies n] [--drive \\.\a:] file.img
      // --read [--drive \\.\a:] file.img
   end
   else
   begin
      CommandLine := False;
   end;
   }
end;

procedure TMainForm.FindFloppy;
begin
   if OSis95 then
   begin
      Find95Floppy;
   end
   else
   begin
      FindNTFloppy;
   end;
end;

procedure TMainForm.Find95Floppy;
begin
   // just add a and b ...? at least for now
   DriveComboBox.Items.Add('A:');
   DriveComboBox.Items.Add('B:');
end;

procedure TMainForm.FindNTFloppy;
var
   Drive : Char;
   h : THandle;
   FileName : String;
   Error : DWORD;
begin
   for Drive := 'A' to 'B' do
   begin
      FileName := '\\.\' + Drive + ':';
      h := CreateFile(PChar(FileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
      if h <> INVALID_HANDLE_VALUE then
      begin
         DriveComboBox.Items.Add(FileName);
         CloseHandle(h);
      end
      else
      begin
         Error := GetLastError;
         if Error = 21 then
         begin
            DriveComboBox.Items.Add(FileName);
         end
         else
         begin
            Debug(FileName, DebugLow);
            Debug(IntToStr(GetLastError) + #10 + SysErrorMessage(Error), DebugLow);
         end;
      end;
   end;
end;

procedure TMainForm.DriveComboBoxDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
begin
   with Control as TComboBox do
   begin
      // draw the icon
      Canvas.Draw(Rect.Left + 2, Rect.Top + 3, FloppyImage.Picture.Graphic);
      Canvas.TextOut(Rect.Left + 20, Rect.Top, Items[Index]);
   end;
end;

procedure TMainForm.Button2Click(Sender: TObject);
var
   h1       : THandle;
   Buffer   : String;
   Read     : DWORD;
   Written  : DWORD;
   Blocks   : Integer;
   WrittenBlocks  : Integer;
   BlocksCount    : Integer;
   BlocksRemaining : Integer;
   BlockCount     : Integer;
   FileSize  : Integer;
   CopiesRemaining : Integer;

   Device   : TBlockDevice;
   Zero     : _Large_Integer;
   DiskSize : _Large_Integer;
   HadError : Boolean;
   DiskNumber : Integer;
   Error : DWORD;
begin
   if DriveComboBox.ItemIndex < 0 then
   begin
      MessageDlg('Please Select a disk drive', mtWarning, [mbOK], 0);
      exit;
   end;

   HadError := False;

   Wait;
   try
      CopiesRemaining := UpDown1.Position;
      DiskNumber := 0;

      while CopiesRemaining > 0 do
      begin
         DiskNumber := DiskNumber + 1;
         StatusBar1.Panels[1].Text := 'Disk ' + IntToStr(DiskNumber) + ' of ' + IntToStr(UpDown1.Position);
         CopiesRemaining := CopiesRemaining - 1;
         BlocksCount := 64;

         // make sure that the file exists...
         h1 := CreateFile(PChar(FileNameEdit.Text), GENERIC_READ, 0, nil, OPEN_EXISTING, 0, 0);
         if h1 <> INVALID_HANDLE_VALUE then
         try
            FileSize := GetFileSize(h1, nil);
            Blocks := FileSize div 512;
            if (Blocks * 512) < FileSize then
            begin
               Blocks := Blocks + 1;
            end;

            WrittenBlocks := 0;

            SetLength(Buffer, 512 * BlocksCount);
            // open the drive
            if osIs95 then
            begin
               Device := TWin95Disk.Create;
               TWin95Disk(Device).SetDiskNumber(DriveComboBox.ItemIndex);
               TWin95Disk(Device).SetOffset(0);
            end
            else
            begin
               Zero.Quadpart := 0;
               DiskSize.Quadpart := 512 * 80 * 2 * 18;
               Device := TNTDisk.Create;
               TNTDisk(Device).SetFileName(DriveComboBox.Text);
               TNTDisk(Device).SetMode(True);
               TNTDisk(Device).SetPartition(Zero, DiskSize);
            end;

            if Device.Open then
            try
               try
                  // write away...
                  while WrittenBlocks < Blocks do
                  begin
                     BlocksRemaining := Blocks - WrittenBlocks;
                     if BlocksRemaining > BlocksCount then
                     begin
                        BlockCount := BlocksCount;
                     end
                     else
                     begin
                        BlockCount := BlocksRemaining;
                     end;

                     ReadFile2(h1, PChar(Buffer), 512 * BlockCount, Read, nil);
                     if Read = 0 then break;
                     Device.WritePhysicalSector(WrittenBlocks, BlockCount, PChar(Buffer));
                     WrittenBlocks := WrittenBlocks + BlockCount;
                     StatusBar1.Panels[0].Text := IntToStr((WrittenBlocks * 100) div Blocks) + '%';
                     Application.ProcessMessages;
                  end;
               except
                  on E : Exception do
                  begin
                     MessageDlg(E.Message, mtError, [mbOK], 0);
                     HadError := True;
                  end;
               end;
            finally
               Device.Close;
               Device.Free;
            end
            else
            begin
               Error := GetLastError;
               MessageDlg('Error (' + IntToStr(GetLastError) + ')'#10 + SysErrorMessage(Error) , mtError, [mbOK], 0);
               HadError := True;
            end;
         finally
            CloseHandle(h1);
         end
         else
         begin
            Error := GetLastError;
            MessageDlg('Error (' + IntToStr(GetLastError) + ')'#10 + SysErrorMessage(Error) , mtError, [mbOK], 0);
            HadError := True;
         end;

         if CopiesRemaining > 0 then
         begin
            if HadError then
            begin
               if MessageDlg('The image was not successfully written.  Do you want to continue with the remaining ' + IntToStr(CopiesRemaining) + ' copies?', mtConfirmation, [mbYes, mbNo], 0) = mrNo then
               begin
                  CopiesRemaining := 0;
               end
               else
               begin
                  HadError := False;
               end;
            end
            else
            begin
               if MessageDlg('Image successfully written.  Insert next disk', mtInformation, [mbOK, mbCancel], 0) = mrCancel then
               begin
                  CopiesRemaining := 0;
               end;
            end;
         end
         else
         begin
            if HadError then
            begin
               MessageDlg('Image was not successfully written.', mtError, [mbOK], 0);
            end
            else
            begin
               MessageDlg('Image successfully written.', mtInformation, [mbOK], 0);
            end;
         end;
      end;
   finally
      UnWait;
   end;
end;

procedure TMainForm.Label5Click(Sender: TObject);
begin
   ShellExecute(Handle, 'open', PChar(TLabel(Sender).Caption), nil, nil, SW_SHOWNORMAL)
end;

procedure TMainForm.Button3Click(Sender: TObject);
begin
   Close;
end;

procedure TMainForm.Label3DblClick(Sender: TObject);
begin
//   This will enable the original write code
   DebugMemo.Visible    := True;
//   WriteButton.Visible  := True;
end;

procedure TMainForm.Button4Click(Sender: TObject);
begin
   SaveDialog1.FileName := ReadFileNameEdit.Text;
   if SaveDialog1.Execute then
   begin
      ReadFileNameEdit.Text := SaveDialog1.FileName;
   end;
end;

procedure TMainForm.Button5Click(Sender: TObject);
var
   h1       : THandle;
   Buffer   : String;
   Read     : DWORD;
   Written  : DWORD;
   Blocks   : Integer;
   WrittenBlocks  : Integer;
   BlocksCount    : Integer;
   BlocksRemaining : Integer;
   BlockCount     : Integer;
   FileSize  : Integer;

   Device   : TBlockDevice;
   Zero     : _Large_Integer;
   DiskSize : _Large_Integer;
   Error : DWORD;
begin
   if DriveComboBox.ItemIndex < 0 then
   begin
      MessageDlg('Please Select a disk drive', mtWarning, [mbOK], 0);
      exit;
   end;

   Wait;
   try

      BlocksCount := 64;

      // make sure that the file exists...
      h1 := CreateFile(PChar(ReadFileNameEdit.Text), GENERIC_WRITE, 0, nil, CREATE_ALWAYS, 0, 0);
      if h1 <> INVALID_HANDLE_VALUE then
      try
         // we need to read until the end of the disk
         // all data gets written to the file...

{         FileSize := GetFileSize(h1, nil);
         Blocks := FileSize div 512;
         if (Blocks * 512) < FileSize then
         begin
            Blocks := Blocks + 1;
         end;}

         WrittenBlocks := 0;

         Blocks := 2880; // no of 512 blocks on a 1.44 (= 80 * 2 * 18)

         SetLength(Buffer, 512 * BlocksCount);
         // open the drive
         if osIs95 then
         begin
            Device := TWin95Disk.Create;
            TWin95Disk(Device).SetDiskNumber(DriveComboBox.ItemIndex);
            TWin95Disk(Device).SetOffset(0);
         end
         else
         begin
            Zero.Quadpart := 0;
            DiskSize.Quadpart := 512 * 80 * 2 * 18;
            Device := TNTDisk.Create;
            TNTDisk(Device).SetFileName(DriveComboBox.Text);
            TNTDisk(Device).SetMode(True);
            TNTDisk(Device).SetPartition(Zero, DiskSize);
         end;

         if Device.Open then
         try
            // write away...
            while WrittenBlocks < Blocks do
            begin
               BlocksRemaining := Blocks - WrittenBlocks;
               if BlocksRemaining > BlocksCount then
               begin
                  BlockCount := BlocksCount;
               end
               else
               begin
                  BlockCount := BlocksRemaining;
               end;


               Device.ReadPhysicalSector(WrittenBlocks, BlockCount, PChar(Buffer));

               WriteFile2(h1, PChar(Buffer), 512 * BlockCount, Read, nil);
//               if Read = 0 then break;

//               Device.WritePhysicalSector(WrittenBlocks, BlockCount, PChar(Buffer));
               WrittenBlocks := WrittenBlocks + BlockCount;
               StatusBar1.Panels[0].Text := IntToStr((WrittenBlocks * 100) div Blocks) + '%';
               Application.ProcessMessages;
            end;
         finally
            Device.Close;
            Device.Free;
         end
         else
         begin
            Error := GetLastError;
            MessageDlg('Error (' + IntToStr(GetLastError) + ')'#10 + SysErrorMessage(Error) , mtError, [mbOK], 0);
         end;
      finally
         CloseHandle(h1);
      end
      else
      begin
         Error := GetLastError;
         MessageDlg('Error (' + IntToStr(GetLastError) + ')'#10 + SysErrorMessage(Error) , mtError, [mbOK], 0);
      end;
   finally
      UnWait;
   end;
end;

procedure TMainForm.TabSheet3Show(Sender: TObject);
begin
   Memo1.Text :=
'RawWrite for windows version 0.4'#13#10+
'Written by John Newbigin'#13#10+
'Copyright (C) 2000 John Newbigin'#13#10+
''#13#10+
'Under 95, this program requires diskio.dll.'#13#10+
''#13#10+
'This program is a replacement for the traditional command'#13#10+
'line rawrite.  This version works under Windows NT 4,'#13#10+
'Windows 2000, Windows 95, Windows 98 & Windows ME.'#13#10+
''#13#10+
'It should be very easy to use, just select the drive you want'#13#10+
'to use, select the image file and hit read or write.'#13#10+
''#13#10+
'This verson supports reading an image from a disk.  Only'#13#10+
'1.44 disks is supported at this time.  Writing to 1.2 drives'#13#10+
'might work.'#13#10+
''#13#10+
'If your floppy drive is not listed in the combo box, please'#13#10+
'send me an e-mail and I will try and fix the problem.'#13#10+
''#13#10+
'Copyright'#13#10+
'========='#13#10+
'This program is free software; you can redistribute it and/or'#13#10+
'modify it under the terms of the GNU General Public License'#13#10+
'as published by the Free Software Foundation; either'#13#10+
'version 2 of the License, or (at your option) any later'#13#10+
'version.'#13#10+
''#13#10+
'This program is distributed in the hope that it will be useful,'#13#10+
'but WITHOUT ANY WARRANTY; without even the implied'#13#10+
'warranty of MERCHANTABILITY or FITNESS FOR A'#13#10+
'PARTICULAR PURPOSE.  See the GNU General Public'#13#10+
'License for more details.'#13#10+
''#13#10+
'You should have received a copy of the GNU General'#13#10+
'Public License along with this program; if not, write to the'#13#10+
'Free Software Foundation, Inc., 675 Mass Ave, Cambridge,'#13#10+
'MA 02139, USA.'

end;

end.


