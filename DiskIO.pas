unit DiskIO;

interface

uses QTThunkU, Classes, Dialogs;

type
  {$A-}
  TSectorInfo = record
    Drive      : BYTE;
    Cylinder   : WORD;
    Head       : BYTE;
    Sector     : BYTE;
    Count      : BYTE;
  end;
  {$A+}

  T95Disk = class
  public
    constructor Create;
    destructor Destroy; override;
    function SetDisk(Disk : Integer) : Boolean;

    function ReadSector(SectorNo : LongInt; Buffer : Pointer; Count : LongInt) : Boolean;
    function WriteSector(SectorNo : LongInt; Buffer : Pointer; Count : LongInt) : Boolean;
    function SectorCount : LongInt;

    function DoRead(Sector : Integer; Head : Integer; Cylinder : Integer; Buffer : Pointer; Count : Integer) : Boolean;
    function DoWrite(Sector : Integer; Head : Integer; Cylinder : Integer; Buffer : Pointer; Count : Integer) : Boolean;

    function ResetDisk : Boolean;

    function GetGeometry : TSectorInfo;
  private
    Ready      : Boolean;
    DLLHandle  : THandle16;
    Geometry   : TSectorInfo;
  end;

implementation
uses Forms, sysutils;

constructor T95Disk.Create;
var
   Path : String;
begin
   Path := ExtractFilePath(Application.ExeName) + 'Diskio.DLL';
   //ShowMessage('Loading ' + Path);
   try
      DLLHandle := LoadLib16(Path);
      Ready := False;
   except
      on E : EFOpenError do
      begin
         MessageDlg('Failed to load diskio.dll.  Please make sure that this file is available (in the same directory as this application)'#10 +
                    'If you do not have a copy you can download it from http://uranus.it.swin.edu.au/~jn/linux', mtError, [mbCancel], 0);
         raise;
      end;
   end;
end;

destructor T95Disk.Destroy;
begin
   FreeLibrary16(DllHandle);
end;

function T95Disk.SetDisk(Disk : Integer) : Boolean;
begin
   Geometry.Drive := Disk;
   Geometry.Sector := 0;
   Call16BitRoutine('READDISKGEOMETRY', DllHandle, ccPascal,
                         [@Geometry], [sizeof(Geometry)]);
   if Geometry.Sector = 0 then
   begin
      Result := False;
   end
   else
   begin
      Result := True;
      Ready := True;
   end;
end;

function T95Disk.ResetDisk : Boolean;
var
   Pram  : TSectorInfo;
   R     : LongInt;
begin
   if Ready then
   begin
      Pram.Drive  := Geometry.Drive;

      r := Call16BitRoutine('RESETDISK', DllHandle, ccPascal,
                            [@Pram], [sizeof(Pram)]);
      if r > 0 then
      begin
         Result := True;
      end
      else
      begin
         Result := False;
      end;
   end
   else
   begin
      Result := False;
   end;
end;

function T95Disk.DoRead(Sector : Integer; Head : Integer; Cylinder : Integer; Buffer : Pointer; Count : Integer) : Boolean;
var
   Pram  : TSectorInfo;
   R     : LongInt;
begin
   if Ready then
   begin
      Pram.Drive  := Geometry.Drive;
   	Pram.Sector := Sector;
   	Pram.Head   := Head;
   	Pram.Cylinder := Cylinder;
      Pram.Count  := Count;

      r := Call16BitRoutine('READPHYSICALSECTOR', DllHandle, ccPascal,
                            [@Pram, Buffer, Count * 512], [sizeof(Pram), Count * 512, 4]);
      if r > 0 then
      begin
         Result := True;
      end
      else
      begin
         Result := False;
      end;
   end
   else
   begin
      Result := False;
   end;
end;

function T95Disk.DoWrite(Sector : Integer; Head : Integer; Cylinder : Integer; Buffer : Pointer; Count : Integer) : Boolean;
var
   Pram  : TSectorInfo;
   R     : LongInt;
begin
   if Ready then
   begin
      Pram.Drive  := Geometry.Drive;
   	Pram.Sector := Sector;
   	Pram.Head   := Head;
   	Pram.Cylinder := Cylinder;
      Pram.Count  := Count;

      r := Call16BitRoutine('WRITEPHYSICALSECTOR', DllHandle, ccPascal,
                            [@Pram, Buffer, 512 * Count], [sizeof(Pram), 512 * Count, 4]);
      if r > 0 then
      begin
         Result := True;
      end
      else
      begin
         Result := False;
      end;
   end
   else
   begin
      Result := False;
   end;
end;

function T95Disk.ReadSector(SectorNo : LongInt; Buffer : Pointer; Count : LongInt) : Boolean;
var
   Sector      : Integer;
   Head        : Integer;
   Cylinder    : Integer;
   Remainder   : Integer;

   BlockCount  : Integer;
begin
   Result := True;
   while Count > 0 do
   begin
      // xlate into chs
      Sector    := SectorNo mod Geometry.Sector;
      Remainder := SectorNo div Geometry.Sector;
   	Head      := Remainder mod (Geometry.Head + 1);
   	Cylinder  := Remainder div (Geometry.Head + 1);

      // see how many sectors ther are till the end of the track.....
      BlockCount := Geometry.Sector - Sector;
      if BlockCount > 255 then // max size...
      begin
         BLockCount := 255;
      end;

      if Count > BlockCount then
      begin
         if not DoRead(Sector + 1, Head, Cylinder, Buffer, BlockCount) then
         begin
            Result := False;
            break;
         end;
         Buffer := @PChar(Buffer)[512 * BlockCount]; // inc to next sector?
         SectorNo := SectorNo + BlockCount;
         Count := Count - BlockCount;
      end
      else
      begin
         if not DoRead(Sector + 1, Head, Cylinder, Buffer, Count) then
         begin
            Result := False;
            break;
         end;
         Count := 0;
      end;
   end;
end;

function T95Disk.WriteSector(SectorNo : LongInt; Buffer : Pointer; Count : LongInt) : Boolean;
var
   Sector      : Integer;
   Head        : Integer;
   Cylinder    : Integer;
   Remainder   : Integer;

   BlockCount  : Integer;
begin
   Result := True;
   while Count > 0 do
   begin
      // xlate into chs
      Sector    := SectorNo mod Geometry.Sector;
      Remainder := SectorNo div Geometry.Sector;
   	Head      := Remainder mod (Geometry.Head + 1);
   	Cylinder  := Remainder div (Geometry.Head + 1);

      // see how many sectors ther are till the end of the track.....
      BlockCount := Geometry.Sector - Sector;
      if BlockCount > 255 then // max size...
      begin
         BLockCount := 255;
      end;

      if Count > BlockCount then
      begin
         if not DoWrite(Sector + 1, Head, Cylinder, Buffer, BlockCount) then
         begin
            Result := False;
            break;
         end;
         Buffer := @PChar(Buffer)[512 * BlockCount]; // inc to next sector?
         SectorNo := SectorNo + BlockCount;
         Count := Count - BlockCount;
      end
      else
      begin
         if not DoWrite(Sector + 1, Head, Cylinder, Buffer, Count) then
         begin
            Result := False;
            break;
         end;
         Count := 0;
      end;
   end;
end;

function T95Disk.SectorCount : LongInt;
begin
   if Ready then
   begin
      Result := Geometry.Sector * (Geometry.Head + 1) * (Geometry.Cylinder + 1);
   end
   else
   begin
      Result := 0;
   end;
end;

function T95Disk.GetGeometry : TSectorInfo;
begin
   Result := Geometry;
end;

end.
