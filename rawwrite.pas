unit rawwrite;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, BlockDev, WinIOCTL, IniFiles ; //, AutoUpdate;

const
   DebugHigh = 0;
   DebugOff = 0;
   DebugLow = 0;
type
  TMainForm = class(TForm)
    Label2: TLabel;
    StatusBar1: TStatusBar;
    DriveComboBox: TComboBox;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Button3: TButton;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    Label1: TLabel;
    FileNameEdit: TEdit;
    Button1: TButton;
    OpenDialog1: TOpenDialog;
    WriteButton: TButton;
    Label7: TLabel;
    ReadFileNameEdit: TEdit;
    Button4: TButton;
    ReadButton: TButton;
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
    TabSheet5: TTabSheet;
    Memo2: TMemo;
    TabSheet6: TTabSheet;
    Label12: TLabel;
    Label6: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    TabSheet7: TTabSheet;
    DebugMemo: TMemo;
    CancelButton: TButton;
    CancelButton2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure DriveComboBoxDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure WriteButtonClick(Sender: TObject);
    procedure Label5Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure ReadButtonClick(Sender: TObject);
    procedure CancelButton2Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    StopRead : Boolean ;
    yes : boolean ;
    procedure FindNTFloppy;
    function GetDrive(texte : string):string;
    procedure ReadLanguageFile() ;
    procedure TranslateText(texte : string; Memo : TMemo) ;
    procedure SelectDisk(drive : string) ;
    function GetPhysicalDriveNumber(texte : string) : string ;
  public
    { Public declarations }
    procedure FindFloppy;
    procedure Wait;
    procedure UnWait;
  end;

var
  MainForm: TMainForm;
  WriteWarning : String = 'Are you sur you want erase destination disk ?' ;
  WarningTitle : String = 'Warning' ;
  DriveNotFound : String = 'Drive not found !' ;
  FileNotFound : String = 'Specified file not found' ;
  DiskText : string = 'Disk %d of %d' ;
  ErrorOpeningDisk : string = 'Error (%d) opening disk' ;
  ErrorOpeningImage : string = 'Error (%d) opening image file' ;
  ErrorMsg : string = 'Error (%d)' ;
  Aborted : string = 'Cancel' ;
  Finish : string = 'Ok' ;
  PleaseSelectDrive : string = 'Please Select a disk drive' ;
  ErrorGetParameterOfDisk : string = 'Can''t get disk parameter' ;
  UnknowLineOption : string = 'Unknown command line option' ;
  WriteSuccessFull : string = 'The image was not successfully written.  Do you want to continue with the remaining %d copies ?' ;
  WriteSuccessFull2 : string = 'Image successfully written.  Insert next disk' ;
  WriteFailed : string = 'Image was not successfully written.' ;
  WriteSuccessFull3 : string = 'Image successfully written.' ;
const
  VERSION : string = '0.8' ;

function ReadFile2(hFile: THandle; Buffer : Pointer; nNumberOfBytesToRead: DWORD;
   var lpNumberOfBytesRead: DWORD; lpOverlapped: POverlapped): BOOL; stdcall;
function WriteFile2(hFile: THandle; Buffer : Pointer; nNumberOfBytesToWrite: DWORD;
   var lpNumberOfBytesWritten: DWORD; lpOverlapped: POverlapped): BOOL; stdcall;

procedure Debug(Str : String; Level : Integer);

implementation

uses ShellAPI; // DiskIO

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
   CmdRead : Boolean;
   CmdCopies : Integer;
   CmdImage : String;
   CmdDrive : String;
   i : Integer;
begin
   yes := false ;
   
   Caption := Caption + ' ' + VERSION ;

   ReadLanguageFile() ;

   // Charge l'icone de la main de Windows plutôt que de delphi
   Screen.Cursors[crHandPoint] := LoadCursor(0, IDC_HAND);

   // Prevent error messages being displayed by NT
   SetErrorMode(SEM_FAILCRITICALERRORS);


   FindFloppy;

   if DriveComboBox.Items.Count > 0 then
   begin
      DriveComboBox.ItemIndex := 0;
   end
   else
   begin
      MessageDlg('No drives found', mtInformation, [mbOK], 0);
   end;

   PageControl1.ActivePage := TabSheet1;

   if ParamCount > 0 then
   begin
      CmdRead := False;
      CmdCopies := 1;
      CmdDrive := '';

      i := 1 ;
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
         else if ParamStr(i) = '--copies' then
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
         else if ParamStr(i) = '--yes' then
         begin
            Inc(i);
            yes := true ;
         end
         else
         begin
            if Pos('--', ParamStr(i)) = 1 then
            begin
               // unknown command
               MessageDlg(UnknowLineOption + ' ''' + ParamStr(i) + '''', mtError, [mbOK], 0);
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
      // --read [--drive 0|1|...] file.img
      if CmdRead then
      begin
         try
            // do a command line read
            ReadFileNameEdit.Text := CmdImage;
            SelectDisk(CmdDrive) ;
            //DriveComboBox.ItemIndex := CmdDrive;
            ReadButtonClick(ReadButton);
         except
            on E : Exception do
            begin
               MessageDlg(E.Message, mtError, [mbOK], 0);
            end;
         end;
         Application.Terminate;
      end
      else
      begin
         // do a command line write
         try
            WriteCopyEdit.Text := IntToStr(CmdCopies);
            FileNameEdit.Text := CmdImage;
            SelectDisk(CmdDrive) ;
            //DriveComboBox.ItemIndex := CmdDrive;
            WriteButtonClick(WriteButton);
         except
            on E : Exception do
            begin
               MessageDlg(E.Message, mtError, [mbOK], 0);
            end;
         end;
         Application.Terminate;
      end;

   end ;
end;

procedure TMainForm.FindFloppy;
begin
      FindNTFloppy;
end;

procedure TMainForm.FindNTFloppy;
var
    { Liste des lecteurs présents }
    DriveList : DWORD ;
    { compteur et masque }
    iDL : BYTE ;
    jDL : DWORD ;
    tmp : string ;
    TypeLecteur : Integer ;
    i : SmallInt ;
    hDrive   : THandle ;
    ShInfo1 : SHFILEINFO ;
    tGem : TDISK_GEOMETRY ;
    taille : int64 ;
    bytesReturned : DWORD ;
begin
    { Récupère la liste des lecteurs }
    DriveList := GetLogicalDrives() ;

    { Ajoute les Lecteur }
    for iDL := 0 to 25 do
    begin
        jDL := DriveList and (1 shl iDL) ;

        if jDL <> 0
        then begin
            { Lecteur }
            tmp := Chr(97 + iDL) + ':' ;

            { Lit le type de lecteur }
            TypeLecteur := GetDriveType(PChar(tmp)) ;

            { Si c'est un CD-ROM ou un disque amovible, ils peuvent être ejecté }
             if (TypeLecteur = DRIVE_CDROM) or (TypeLecteur = DRIVE_REMOVABLE) or
            //if (TypeLecteur = DRIVE_REMOVABLE) or
               (TypeLecteur = DRIVE_RAMDISK)  or (TypeLecteur = DRIVE_FIXED)
            then begin
                { Récupère les informations liés au lecteur }
                SHGetFileInfo(PChar(tmp + '\'), 0, ShInfo1, sizeOF(SHFILEINFO), SHGFI_ICON or SHGFI_SMALLICON or SHGFI_DISPLAYNAME) ;

                // DriveComboBox.Items.Add(tmp) ;
                DriveComboBox.Items.Add(String(ShInfo1.szDisplayName)) ;
            end ;
        end ;
    end ;

    // lecture des disques physiques
    for i := 0 to 255 do
    begin
        // tente d'ouvrir les Drives 0,1,2,3,.....
        // s'arrête à la première erreur (hdrive=-1)
        hDrive := CreateFile(PChar('\\.\PHYSICALDRIVE' + IntToStr(i)), GENERIC_READ, FILE_SHARE_READ Or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0) ;

        if hDrive <> INVALID_HANDLE_VALUE
        then begin
            DeviceIoControl(hDrive, IOCTL_DISK_GET_DRIVE_GEOMETRY, nil, 0, @tGem, sizeof(tGem), bytesReturned, nil);
            
            taille := tGem.TracksPerCylinder * tGem.SectorsPerTrack * tGem.Cylinders.QuadPart * tGem.BytesPerSector ;
            
            if taille < (1024)
            then begin
                tmp := ' bytes' ;
            end
            else begin
                taille := taille div 1024 ;

                if taille < (1024)
                then begin
                    tmp := ' Kb' ;
                end
                else begin
                    taille := taille div 1024 ;

                    if taille < (1024)
                    then begin
                        tmp := ' Mb' ;
                    end
                    else begin
                        taille := taille div 1024 ;

                        if taille < (1024)
                        then begin
                            tmp := ' Gb' ;
                        end
                        else begin
                            taille := taille div 1024 ;

                            if taille < (1024)
                            then begin
                                tmp := ' Tb' ;
                            end
                            else begin
                                tmp := ' ???' ;
                            end ;
                        end ;
                    end ;
                end ;

            end ;

            DriveComboBox.Items.Add('Disk ' + IntToStr(i) + ' [' + IntToStr(taille) + tmp + ']') ;
        end
        else
            break ;
            
        CloseHandle(hDrive) ;            
    end ;
end;

procedure TMainForm.DriveComboBoxDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
var Bmp1 : TBitmap ;
    ShInfo1 : SHFILEINFO ;
begin
    { Créer le BMP }
    Bmp1 := TBitmap.Create() ;
    { Définir la couleur de transparence }
    Bmp1.Canvas.Brush.Color := clMenu ;
    Bmp1.Canvas.Pen.Color := clMenu ;
    { Active la transparence. Prend le pixel 1:1 }
    Bmp1.Transparent := True ;
    Bmp1.Width := 16;
    Bmp1.Height := 16;

    with Control as TComboBox do
    begin
        { Récupère les informations liés au lecteur }
        SHGetFileInfo(PChar(GetDrive(Items[Index]) + ':\'), 0, ShInfo1, sizeOF(SHFILEINFO), SHGFI_ICON or SHGFI_SMALLICON or SHGFI_DISPLAYNAME) ;

        { Dessine l'icône }
        DrawIconEx(Bmp1.Canvas.Handle, 0, 0, ShInfo1.hIcon, 0, 0, 0, 0, DI_NORMAL) ;

        // draw the icon
        // disable show bug
        Canvas.Pen.Color := clWindow ;
        Canvas.Rectangle(Rect.Right, Rect.Top, Rect.Left, Rect.Bottom);
        Canvas.Draw(Rect.Left, Rect.Top, Bmp1);

        Canvas.TextOut(Rect.Left + 20, Rect.Top, Items[Index]);
    end;

   Bmp1.Free ;
end;

procedure TMainForm.WriteButtonClick(Sender: TObject);
var
   h1       : THandle;
   Buffer   : String;
   Read     : DWORD;
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
   tmp : string ;
   tGem : TDISK_GEOMETRY ;
   hDrive   : THandle;
   bytesReturned : DWORD ;   
begin
   if not FileExists(FileNameEdit.Text)
   then begin
       MessageDlg(FileNotFound, mtWarning, [mbOK], 0);
       exit ;
   end ;

   if yes = false
   then
       if Application.MessageBox(PChar(WriteWarning), PChar(WarningTitle), MB_YESNO or MB_ICONWARNING or MB_DEFBUTTON2) = ID_NO
       then
           exit ;

   Wait;
   
   DebugMemo.Clear ;

   CancelButton2.Enabled := True ;
   
   StopRead := False ;

   if DriveComboBox.ItemIndex < 0 then
   begin
      MessageDlg(PleaseSelectDrive, mtWarning, [mbOK], 0);
      exit;
   end;

   tmp := GetDrive(DriveComboBox.Text) ;
   if (tmp <> '')
   then begin
       tmp := '\\.\' + tmp + ':' ;
   end
   else begin
       tmp := GetPhysicalDriveNumber(DriveComboBox.Text) ;
       tmp := '\\.\PHYSICALDRIVE' + tmp ;
   end ;   

   HadError := False;

   FillChar(tGem, sizeof(tGem), 0) ;

   hDrive := CreateFile(PChar(tmp), GENERIC_READ, FILE_SHARE_READ Or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0) ;

   if hDrive <> INVALID_HANDLE_VALUE
   then
       DeviceIoControl(hDrive, IOCTL_DISK_GET_DRIVE_GEOMETRY, nil, 0, @tGem, sizeof(tGem), bytesReturned, nil);

   CloseHandle(hDrive) ;

   if tGem.BytesPerSector = 0
   then
       tGem.BytesPerSector := 512 ;

   try
      CopiesRemaining := UpDown1.Position;
      DiskNumber := 0;

      while CopiesRemaining > 0 do
      begin
         if StopRead = True
         then
             break ;

         DiskNumber := DiskNumber + 1;
         StatusBar1.Panels[1].Text := Format(DiskText, [DiskNumber, UpDown1.Position]);
         CopiesRemaining := CopiesRemaining - 1;
         BlocksCount := 64;

         // make sure that the file exists...
         h1 := CreateFile(PChar(FileNameEdit.Text), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
         if h1 <> INVALID_HANDLE_VALUE then
         try
            FileSize := GetFileSize(h1, nil);
            if FileSize = 0 then
            begin
               raise Exception.Create('File ' + FileNameEdit.Text + ' is 0 bytes long');
            end;
            Blocks := FileSize div tGem.BytesPerSector;
            if (Blocks * tGem.BytesPerSector) < FileSize then
            begin
               Blocks := Blocks + 1;
            end;

            WrittenBlocks := 0;

            SetLength(Buffer, tGem.BytesPerSector * BlocksCount);

            // open the drive
            Zero.Quadpart := 0;

            DiskSize.Quadpart := tGem.BytesPerSector * Blocks;

            Device := TNTDisk.Create;

            TNTDisk(Device).SetFileName(tmp);
            TNTDisk(Device).SetMode(True);
            TNTDisk(Device).SetPartition(Zero, DiskSize);


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

                     ReadFile2(h1, PChar(Buffer), tGem.BytesPerSector * BlockCount, Read, nil);
                     if Read = 0 then break;

                     try
                         Device.WritePhysicalSector(WrittenBlocks, BlockCount, PChar(Buffer));
                     except
                         StopRead := True ;
                         break ;
                     end ;
                     
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
               MessageDlg(Format(ErrorOpeningDisk, [GetLastError]) + #10 + SysErrorMessage(Error) , mtError, [mbOK], 0);
               HadError := True;
            end;
         finally
            CloseHandle(h1);
         end
         else
         begin
            Error := GetLastError;
            MessageDlg(Format(ErrorOpeningImage, [GetLastError]) + FileNameEdit.Text + #10 + SysErrorMessage(Error) , mtError, [mbOK], 0);
            HadError := True;
         end;

         if CopiesRemaining > 0 then
         begin
            if HadError then
            begin
               if MessageDlg(Format(WriteSuccessFull, [CopiesRemaining]), mtConfirmation, [mbYes, mbNo], 0) = mrNo then
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
               if MessageDlg(WriteSuccessFull2, mtInformation, [mbOK, mbCancel], 0) = mrCancel then
               begin
                  CopiesRemaining := 0;
               end;
            end;
         end
         else
         begin
            if HadError then
            begin
               MessageDlg(WriteFailed, mtError, [mbOK], 0);
            end
            else
            begin
               MessageDlg(WriteSuccessFull3, mtInformation, [mbOK], 0);
            end;
         end;
      end;
   finally
      CancelButton2.Enabled := True ;   
      UnWait;
   end;

   if StopRead = True
   then
       StatusBar1.Panels[0].Text := Aborted
   else
       StatusBar1.Panels[0].Text := Finish ;       

   CancelButton2.Enabled := False ;
end;

procedure TMainForm.Label5Click(Sender: TObject);
begin
   ShellExecute(Handle, 'open', PChar(TLabel(Sender).Caption), nil, nil, SW_SHOWNORMAL)
end;

procedure TMainForm.Button3Click(Sender: TObject);
begin
    Close ;
end;

procedure TMainForm.Button4Click(Sender: TObject);
begin
   SaveDialog1.FileName := ReadFileNameEdit.Text;
   if SaveDialog1.Execute then
   begin
      ReadFileNameEdit.Text := SaveDialog1.FileName;
   end;
end;

procedure TMainForm.ReadButtonClick(Sender: TObject);
var
   h1       : THandle;
   hDrive   : THandle ;
   Buffer   : String;
   Read     : DWORD;
   Blocks   : Int64 ;
   WrittenBlocks  : Integer;
   BlocksCount    : Integer;
   BlocksRemaining : Integer;
   BlockCount     : Integer;
   Device   : TBlockDevice;
   Zero     : _Large_Integer;
   DiskSize : _Large_Integer;
   Error : DWORD;
   tmp, tmp2 : string ;
   tGem : TDISK_GEOMETRY ;
   bytesReturned : DWORD ;
   // On some CD-ROM drive DeviceIoControl doesn't work
   lpFreeBytesAvailableToCaller : TLargeInteger;
   lpTotalNumberOfBytes : TLargeInteger;
   lpTotalNumberOfFreeBytes : TLargeInteger;
begin
   DebugMemo.Clear ;
   
   Wait;

   CancelButton.Enabled := True ;

   StopRead := False ;
   
   if DriveComboBox.ItemIndex < 0 then
   begin
      MessageDlg(PleaseSelectDrive, mtWarning, [mbOK], 0);
      exit;
   end;

   tmp := GetDrive(DriveComboBox.Text) ;
   if (tmp <> '')
   then begin
       tmp := '\\.\' + tmp + ':' ;
   end
   else begin
       tmp := GetPhysicalDriveNumber(DriveComboBox.Text) ;
       tmp := '\\.\PHYSICALDRIVE' + tmp ;
   end ;   

   FillChar(tGem, sizeof(tGem), 0) ;

   hDrive := CreateFile(PChar(tmp), GENERIC_READ, FILE_SHARE_READ Or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0) ;

   if hDrive <> INVALID_HANDLE_VALUE
   then
       DeviceIoControl(hDrive, IOCTL_DISK_GET_DRIVE_GEOMETRY, nil, 0, @tGem, sizeof(tGem), bytesReturned, nil);

   CloseHandle(hDrive) ;

   try

      BlocksCount := 64;

      // make sure that the file exists...
      h1 := CreateFile(PChar(ReadFileNameEdit.Text), GENERIC_WRITE, 0, nil, CREATE_ALWAYS, 0, 0);
      if h1 <> INVALID_HANDLE_VALUE then
      try
         // we need to read until the end of the disk
         // all data gets written to the file...
         WrittenBlocks := 0;

//         Blocks := 2880; // no of 512 blocks on a 1.44 (= 80 * 2 * 18)
         Blocks := tGem.TracksPerCylinder ;
         Debug('Tracks per cylinder : ' + IntToStr(tGem.TracksPerCylinder), DebugHigh) ;
         Blocks := Blocks * tGem.SectorsPerTrack ;
         Debug('Sector per track : ' + IntToStr(tGem.SectorsPerTrack), DebugHigh) ;
         Blocks := Blocks * tGem.Cylinders.QuadPart ;
         Debug('Cylinder : ' + IntToStr(tGem.Cylinders.QuadPart), DebugHigh) ;

         Debug('Byte per sector : ' + IntToStr(tGem.BytesPerSector), DebugHigh) ;

         // On some CD-ROM drive DeviceIoControl doesn't work
         if (Blocks = 0)
         then begin
             Debug(ErrorGetParameterOfDisk,  DebugHigh) ;

             tmp2 := GetDrive(DriveComboBox.Text) ;

             if (GetDiskFreeSpaceEx(PChar(tmp2 + ':'), lpFreeBytesAvailableToCaller, lpTotalNumberOfBytes, @lpTotalNumberOfFreeBytes)) and (tGem.BytesPerSector > 0)
             then begin
                 Debug('GetDiskFreeSpaceEx ok',  DebugHigh) ;
                 Blocks := lpTotalNumberOfBytes div tGem.BytesPerSector
             end
             else begin
                 Debug('GetDiskFreeSpaceEx failed or BytesPerSector=0',  DebugHigh) ;
                 MessageDlg(ErrorGetParameterOfDisk, mtError, [mbOK], 0);
             end ;
         end ;

//         SetLength(Buffer, 512 * BlocksCount);
         SetLength(Buffer, tGem.BytesPerSector * BlocksCount);

         // open the drive
         Zero.Quadpart := 0;

//         DiskSize.Quadpart := 512 * 80 * 2 * 18;
         DiskSize.Quadpart := tGem.BytesPerSector * Blocks;

         Device := TNTDisk.Create;
         TNTDisk(Device).SetFileName(tmp);
         TNTDisk(Device).SetMode(True);
         TNTDisk(Device).SetPartition(Zero, DiskSize);

         if Device.Open then
         try
            // write away...
            while WrittenBlocks < Blocks do
            begin
               if StopRead = True
               then
                   break ;

               BlocksRemaining := Blocks - WrittenBlocks;
               if BlocksRemaining > BlocksCount then
               begin
                  BlockCount := BlocksCount;
               end
               else
               begin
                  BlockCount := BlocksRemaining;
               end;

               try
                   Device.ReadPhysicalSector(WrittenBlocks, BlockCount, PChar(Buffer));
               except
                   StopRead := True ;
                   break ;
               end ;

               WriteFile2(h1, PChar(Buffer), tGem.BytesPerSector * BlockCount, Read, nil);

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
            MessageDlg(Format(ErrorMsg, [GetLastError]) + #10 + SysErrorMessage(Error) , mtError, [mbOK], 0);
         end;
      finally
         CloseHandle(h1);
      end
      else
      begin
         Error := GetLastError;
         MessageDlg(Format(ErrorMsg, [GetLastError]) +#10 + SysErrorMessage(Error) , mtError, [mbOK], 0);
      end;
   finally
      CancelButton.Enabled := True ;   
      UnWait;
   end;

   if StopRead = True
   then
       StatusBar1.Panels[0].Text := Aborted
   else
       StatusBar1.Panels[0].Text := Finish ;

   CancelButton.Enabled := False ;
end;

function TMainForm.GetDrive(texte : string): string ;
begin
   if (texte[length(texte)] = ')') and (texte[length(texte) - 3] = '(')
   then
       Result := texte[length(texte) - 2]
   else
       Result := '' ;
end ;

procedure TMainForm.CancelButton2Click(Sender: TObject);
begin
    StopRead := True ;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   StopRead := True ;
   TButton(Sender).Enabled := false ;
end;

{*******************************************************************************
 * Read language
 ******************************************************************************}
procedure TMainForm.ReadLanguageFile() ;
Var FichierLangue : TIniFile ;
    tmp : string ;
begin
    FichierLangue := TIniFile.Create('.\lang.ini') ;

    tmp := FichierLangue.ReadString('rawwrite', 'Drive', '') ;

    if tmp <> ''
    then
        Label2.Caption := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'Write', '') ;

    if tmp <> ''
    then
        TabSheet1.Caption := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'WriteButton', '') ;

    if tmp <> ''
    then
        WriteButton.Caption := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'Label8', '') ;

    if tmp <> ''
    then
        Label8.Caption := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'Label1', '') ;

    if tmp <> ''
    then
        Label1.Caption := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'Label11', '') ;

    if tmp <> ''
    then
        Label11.Caption := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'Cancel', '') ;

    if tmp <> ''
    then
        CancelButton2.Caption := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'Exit', '') ;

    if tmp <> ''
    then
        Button3.Caption := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'Create', '') ;

    if tmp <> ''
    then
        TabSheet2.Caption := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'Label9', '') ;

    if tmp <> ''
    then
        Label9.Caption := tmp ;

    tmp := Label1.Caption ;

    if tmp <> ''
    then
         Label7.Caption := tmp ;

    tmp := CancelButton2.Caption ;

    if tmp <> ''
    then
         CancelButton.Caption := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'About', '') ;

    if tmp <> ''
    then
        TabSheet3.Caption := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'Help', '') ;

    if tmp <> ''
    then
         TabSheet5.Caption := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'HelpText', '') ;

    if tmp <> ''
    then
        TranslateText(tmp, Memo2) ;

    tmp := FichierLangue.ReadString('rawwrite', 'Support', '') ;

    if tmp <> ''
    then
        TabSheet6.Caption := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'Debug', '') ;

    if tmp <> ''
    then
        TabSheet7.Caption := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'WriteWarning', '') ;

    if tmp <> ''
    then
        WriteWarning := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'WarningTitle', '') ;

    if tmp <> ''
    then
        WarningTitle := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'DriveNotFound', '') ;

    if tmp <> ''
    then
        DriveNotFound := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'FileNotFound', '') ;

    if tmp <> ''
    then
        FileNotFound := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'DiskText', '') ;

    if tmp <> ''
    then
        DiskText := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'ErrorOpeningDisk', '') ;

    if tmp <> ''
    then
        ErrorOpeningDisk := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'ErrorOpeningImage', '') ;

    if tmp <> ''
    then
        ErrorOpeningImage := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'Error', '') ;

    if tmp <> ''
    then
        ErrorMsg := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'Aborted', '') ;

    if tmp <> ''
    then
        Aborted := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'Finish', '') ;

    if tmp <> ''
    then
        Finish := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'CreateBtn', '') ;

    if tmp <> ''
    then
        ReadButton.Caption := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'FilterFile', '') ;

    if tmp <> ''
    then begin
        OpenDialog1.Filter := tmp ;
        SaveDialog1.Filter := tmp ;
    end ;

    tmp := FichierLangue.ReadString('rawwrite', 'PleaseSelectDrive', '') ;

    if tmp <> ''
    then
        PleaseSelectDrive := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'ErrorGetParameterOfDisk', '') ;

    if tmp <> ''
    then
        ErrorGetParameterOfDisk := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'UnknowLineOption', '') ;

    if tmp <> ''
    then
        UnknowLineOption := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'WriteSuccessFull', '') ;

    if tmp <> ''
    then
        WriteSuccessFull := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'WriteSuccessFull2', '') ;

    if tmp <> ''
    then
        WriteSuccessFull2 := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'WriteFailed', '') ;

    if tmp <> ''
    then
        WriteFailed := tmp ;

    tmp := FichierLangue.ReadString('rawwrite', 'WriteSuccessFull3', '') ;
    
    if tmp <> ''
    then
        WriteSuccessFull3 := tmp ;

    FichierLangue.Free ;
end ;

{*******************************************************************************
 * Translate texte with \n new line in TMemo
 ******************************************************************************}
procedure TMainForm.TranslateText(texte : string; Memo : TMemo) ;
var i, nb : integer ;
    tmp : string ;
begin
    Memo.Clear ;

    nb := length(texte) ;
    tmp := '' ;
    i := 1 ;
    
    while i <= nb do
    begin
        if texte[i] = '\'
        then begin
            if i < nb
            then
                if texte[i+1] = 'n'
                then begin
                    Memo.Lines.Add(tmp)  ;
                    tmp := '' ;
                    Inc(i) ;
                end ;
        end
        else
            tmp := tmp + texte[i] ;

        Inc(i) ;
    end ;

    Memo.Lines.Add(tmp)  ;
    
end ;

{*******************************************************************************
 * Select disk in combobox with letter or number of physical drive
 ******************************************************************************}
procedure TMainForm.SelectDisk(drive : string) ;
Var i, nb : integer ;
    found : boolean ;

    function finddrive(drive : string; i : integer) : boolean;
    begin
        if GetDrive(DriveComboBox.Items[i]) = drive
        then
            Result := True
        else if GetPhysicalDriveNumber(DriveComboBox.Items[i]) = drive
        then
            Result := True
        else
            Result := False ;
            

    end ;
begin
    nb := DriveComboBox.Items.Count ;
    found := False ;

    for i := 0 to nb - 1 do
    begin
        if finddrive(drive, i) = true
        then begin
            DriveComboBox.ItemIndex := i ;
            found := True ;
            break ;
        end ;
    end ;

    if found = false
    then
        MessageDlg(DriveNotFound, mtError, [mbOk], 0) ;
end ;

{*******************************************************************************
 * Get physical drive number.
 * string must be 'Disk XXX'
 ******************************************************************************}
function TMainForm.GetPhysicalDriveNumber(texte : string) : string ;
Var i, nb : integer ;
begin
    nb := length(texte) ;
    Result := '' ;

    for i := 6 to nb do
    begin
        if texte[i] in ['0'..'9']
        then
            Result := Result + texte[i]
        else
            break ;
    end ;

end ;

end.


