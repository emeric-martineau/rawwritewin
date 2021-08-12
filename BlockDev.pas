unit BlockDev;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, WinIOCTL; // DiskIO

type

  TBlockDevice = class(TObject)
  public                            
    constructor Create; virtual;
    destructor Destroy; override;

    procedure ReadPhysicalSector(Sector : DWORD; count : DWORD; Buffer : Pointer); virtual; abstract;
    procedure WritePhysicalSector(Sector : DWORD; count : DWORD; Buffer : Pointer); virtual; abstract;

    function Open  : Boolean; virtual; abstract;
    function Close : Boolean; virtual; abstract;
  end;

  TNTDisk = class(TBlockDevice)
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure ReadPhysicalSector (Sector : DWORD; count : DWORD; Buffer : Pointer); override;
    procedure WritePhysicalSector(Sector : DWORD; count : DWORD; Buffer : Pointer); override;

    function Open  : Boolean; override;
    function Close : Boolean; override;

    procedure SetFileName(Name : String);
    procedure SetMode(Writeable : Boolean);
    procedure SetPartition(Start : _Large_Integer; Length : _Large_Integer);
  private
    FileName   : String;
    h          : THandle;
    Writeable  : Boolean;
    SectorSize : DWORD;
    Start       : _Large_Integer; //longlong; // start
    Length      : _Large_Integer; //longlong; // length
  end;

{  TVirtualDisk = class(TNTDisk)
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure ReadPhysicalSector(Sector : DWORD; count : DWORD; Buffer : Pointer); override;
    procedure WritePhysicalSector(Sector : DWORD; count : DWORD; Buffer : Pointer); override;
  end;}

implementation

uses rawwrite;


//////////////////////////////
// TBlockDevice
//////////////////////////////

constructor TBlockDevice.Create;
begin
   inherited Create;
   Debug('Creating BlockDevice', DebugHigh);
end;

destructor TBlockDevice.Destroy;
begin
   Debug('Destroying BlockDevice', DebugHigh);
   inherited Destroy;
end;

//////////////////////////////
// TNTDisk
//////////////////////////////

// This is a type of block device which uses the
// WIN32 API


constructor TNTDisk.Create;
begin
   inherited Create;
   Debug('Creating NTDisk', DebugHigh);
   h := INVALID_HANDLE_VALUE;
   Writeable   := False;
   SectorSize  := 512;
end;

destructor TNTDisk.Destroy;
begin
   Debug('Destroying NTDisk', DebugHigh);
   Close;
   inherited Destroy;
end;

function TNTDisk.Open  : Boolean;
begin
   if Writeable then
   begin
      h := Windows.CreateFile(PChar(FileName), GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ , nil, OPEN_EXISTING, FILE_FLAG_RANDOM_ACCESS, 0);
   end
   else
   begin
      h := Windows.CreateFile(PChar(FileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_FLAG_RANDOM_ACCESS, 0);
   end;
   if h <> INVALID_HANDLE_VALUE then
   begin
      Result := True;
   end
   else
   begin
      Result := False;
   end;
end;

function TNTDisk.Close : Boolean;
begin
   if h <> INVALID_HANDLE_VALUE then
   begin
      CloseHandle(h);
   end;
   h := INVALID_HANDLE_VALUE;
   Result := True;
end;

procedure TNTDisk.SetFileName(Name : String);
begin
   FileName := Name;
end;

procedure TNTDisk.SetMode(Writeable : Boolean);
begin
   self.Writeable := Writeable;
end;

procedure TNTDisk.SetPartition(Start : _Large_Integer; Length : _Large_Integer);
begin
   self.Start.QuadPart  := Start.QuadPart;
   self.Length.QuadPart := Length.QuadPart;
end;

procedure TNTDisk.ReadPhysicalSector(Sector : DWORD; count : DWORD; Buffer : Pointer);
var
   ReadStart  : _Large_Integer;
   ReadLength : DWORD;
   ActualLengthRead : DWORD;
   Seek       : DWORD;
   Error : DWORD;
   ErrorMsg : String;
begin
   Debug('Reading sector ' + IntToStr(Sector) + ' count = ' + IntToStr(count), DebugHigh);
   // check for a valid handle
   if h <> INVALID_HANDLE_VALUE then
   begin
//      Debug('Read sector', DebugOff);
      // work out the start address (of partition/file)
      ReadStart.QuadPart := SectorSize;
      ReadStart.QuadPart := ReadStart.QuadPart * Sector;
      ReadStart.QuadPart := ReadStart.QuadPart + Start.Quadpart;
      ReadLength := Count * SectorSize;

      // seek to the correct pos
      Seek := SetFilePointer(h, ReadStart.LowPart, @ReadStart.HighPart, FILE_BEGIN);
      if Seek <> $FFFFFFFF then
      begin
         // seek successful, lets read
         if not ReadFile2(h, Buffer, ReadLength, ActualLengthRead, nil) then
         begin
            Error := GetLastError;
            ErrorMsg := 'Read failed error = ' + IntToStr(Error) + '(' + SysErrorMessage(Error) + ')';
            Debug(ErrorMsg, DebugOff);
            raise Exception.Create(ErrorMsg);
         end
         else if ReadLength <> ActualLengthRead then
         begin
            Debug('Possible error, only ' + IntToStr(ActualLengthRead) + ' bytes read', DebugLow);
         end;
      end
      else
      begin
         // error
         Error := GetLastError;
         ErrorMsg := 'Seek failed error = ' + IntToStr(Error) + '(' + SysErrorMessage(Error) + ')';
         Debug(ErrorMsg, DebugOff);
         raise Exception.Create(ErrorMsg);
      end;
   end;
end;

procedure TNTDisk.WritePhysicalSector(Sector : DWORD; count : DWORD; Buffer : Pointer);
var
   WriteStart           : _Large_Integer;
   WriteLength          : DWORD;
   ActualLengthWritten  : DWORD;
   Seek                 : DWORD;
   Error                : DWORD;
begin
   // check for a valid handle
   if h <> INVALID_HANDLE_VALUE then
   begin
      Debug('Write sector ' + IntToStr(Sector) + ' count = ' + IntToStr(Count), DebugOff);
      // work out the start address (of partition/file)

      WriteStart.QuadPart := Start.QuadPart + (Sector * SectorSize);
      WriteLength := Count * SectorSize;

      // seek to the correct pos
      Seek := SetFilePointer(h, WriteStart.LowPart, @WriteStart.HighPart, FILE_BEGIN);
      if Seek <> $FFFFFFFF then
      begin
         // seek successful, lets read
         if not WriteFile2(h, Buffer, WriteLength, ActualLengthWritten, nil) then
         begin
            Error := GetLastError;
            Debug('Write failed error=' + IntToStr(GetLastError), DebugOff);
            raise Exception.Create('Write Failed: (' + IntToStr(GetLastError) + ')'#10 + SysErrorMessage(Error));
         end
         else if WriteLength <> ActualLengthWritten then
         begin
            Debug('Possible error, only ' + IntToStr(ActualLengthWritten) + ' bytes written', DebugLow);
         end;
      end
      else
      begin
         // error
         Debug('Seek failed error=' + IntToStr(GetLastError), DebugOff);
         raise Exception.Create('Seek failed');
      end;
   end;
end;



{constructor TVirtualDisk.Create;
begin
   inherited Create;
   Debug('Creating VirtualDisk', DebugHigh);
end;

destructor TVirtualDisk.Destroy;
begin
   Debug('Destroying VirtualDisk', DebugHigh);
   inherited Destroy;
end;}

end.
