// I don't why it's doesn't work in object but work in procedural
{*
 * Copyright MARTINEAU Emeric (C) 2007
 * 
 * This program is free software; you can redistribute it and/or 
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later
 * version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A
 * PARTICULAR PURPOSE.  See the GNU General Public
 * License for more details.
 * '
 * You should have received a copy of the GNU General
 * Public License along with this program; if not, write to the
 * Free Software Foundation, Inc., 675 Mass Ave, Cambridge,
 * MA 02139, USA.
 * 
 * Explain (start at byte 0)
 *  FAT : 
 *        54 (8 bytes) : 'FAT     '
 *        43 (11 bytes) : volume name
 *  FAT12 : 
 *        54 (8 bytes) : 'FAT12   '
 *        43 (11 bytes) : volume name
 *  FAT16 : 
 *        54 (8 bytes) : 'FAT16   '
 *        43 (11 bytes) : volume name
 *  FAT32 : 
 *        82 (8 bytes) : 'FAT32   '
 *        71 (11 bytes) : volume name
 *  NTFS : 
 *        3 (8 bytes) : 'NTFS    '
 *        where is volume name ?
 *  EXT2/3/4 : 
 *        0 to 1023 ; boot loader
 *        1024 + 56 (2 bytes) : MagicNumber = $53 $EF or EF53
 *        1024 + 56 + 62 (16 bytes) : volume name
 *  ISO 9660 :
 *        $8000 : $01'CD001'$01$00
 *        $8028 (32 bytes) : volume name
 *     or 
 *        In one CD i found this
 *        $20800 : $01'CD001'$01$00
 *        $20808 (32 bytes) : volume name
 *  ReiserFS :
 *        65536 + 52 (12 bytes) : 'ReIsEr2Fs'
 *        volume name ?
 *  HFS :
 *        0 to 1023 : boot loader
 *        TYPE MDB          =           (master directory block)
 *        RECORD
 *        4  drSigWord:     Integer;    (volume signature = 0x4244)
 *        8  drCrDate:      LongInt;    (date and time of volume creation)
 *        8  drLsMod:       LongInt;    (date and time of last modification)
 *        4  drAtrb:        Integer;    (volume attributes)
 *        4  drNmFls:       Integer;    (number of files in root directory)
 *        4  drVBMSt:       Integer;    (first block of volume bitmap)
 *        4  drAllocPtr:    Integer;    (start of next allocation search)
 *        4  drNmAlBlks:    Integer;    (number of allocation blocks in volume)
 *        8  drAlBlkSiz:    LongInt;    (size (in bytes) of allocation blocks)
 *        8  drClpSiz:      LongInt;    (default clump size)
 *        4  drAlBlSt:      Integer;    (first allocation block in volume)
 *        8  drNxtCNID:     LongInt;    (next unused catalog node ID)
 *        4  drFreeBks:     Integer;    (number of unused allocation blocks)
 *           drVN:          String[27]; (volume name) start + 72
 *           drVolBkUp:     LongInt;    (date and time of last backup)
 *           drVSeqNum:     Integer;    (volume backup sequence number)
 *           drWrCnt:       LongInt;    (volume write count)
 *           drXTClpSiz:    LongInt;    (clump size for extents overflow file)
 *           drCTClpSiz:    LongInt;    (clump size for catalog file)
 *           drNmRtDirs:    Integer;    (number of directories in root directory)
 *           drFilCnt:      LongInt;    (number of files in volume)
 *           drDirCnt:      LongInt;    (number of directories in volume)
 *           drFndrInfo:    ARRAY[1..8] OF LongInt;
 *                                      (information used by the Finder)
 *           drVCSize:      Integer;    (size (in blocks) of volume cache)
 *           drVBMCSize:    Integer;    (size (in blocks) of volume bitmap cache)
 *           drCtlCSize:    Integer;    (size (in blocks) of common volume cache)
 *           drXTFlSize:    LongInt;    (size of extents overflow file)
 *           drXTExtRec:    ExtDataRec; (extent record for extents overflow file)
 *           drCTFlSize:    LongInt;    (size of catalog file)
 *           drCTExtRec:    ExtDataRec; (extent record for catalog file)
 *        END;
 *  MFS :
 *        0 to 1023 : boot loader
 *        MagicNumber : $D2D7 
 *}
unit SystemFile;

interface

uses Windows, Messages, Classes, StrUtils, SysUtils ;

type
  TSystemFile = class
  private
      FileName : string ;
      FileHandle : THandle ;
      Buffer : array[0..32] of char ;
      SizeOfLabel : SmallInt ;
      PositionOfLabel : _Large_Integer ;
  function isISO9660() : boolean ;
  function isFAT() : boolean ;
  function isFAT12() : boolean ;
  function isFAT16() : boolean ;
  function isFAT32() : boolean ;
  function isNTFS() : boolean ;
  function isExt2_3_4() : boolean ;
  function isReiserFS() : boolean ;
  function isHFS() : boolean ;
  function isMFS() : boolean ;
  public
      constructor Create(FileName1 : String) ;
      destructor Destroy ;
      function GetFileName() : string ;
      function GetFSType() : string ;
      function isOpen() : Boolean ;
      function GetSizeOfLabel() : SmallInt ;
      function ReadLabel : string ;
      function WriteLabel(NewLabel : string) : SmallInt ;
  end ;

const
    WRITE_OK = 1 ;
    FILESYSTEM_NOT_SUPPORTED = -1 ;
    WRITE_ERROR = -2 ;
    LABEL_TOO_LONG = -3 ;
    CANT_OPEN_TO_WRITE = -4 ;
      
implementation

constructor TSystemFile.Create(FileName1 : String) ;
begin
    inherited Create ;
    FileName := FileName1 ;
    FileHandle := CreateFile(PChar(FileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
    SizeOfLabel := -1 ;
end ;

destructor TSystemFile.Destroy ;
begin
    if FileHandle <> INVALID_HANDLE_VALUE
    then
        Windows.CloseHandle(FileHandle);

    inherited Destroy ;
end ;

function TSystemFile.isOpen() : Boolean ;
begin
    Result := FileHandle <> INVALID_HANDLE_VALUE ; 
end ;

function TSystemFile.GetFileName() : string;
begin
    Result := Self.FileName ;
end ;

{******************************************************************************
 * Return file system
 * 
 * Call funtion isXXX wich initialise SizeOfLabel and PositionOfLabel 
 *****************************************************************************}
function TSystemFile.GetFSType() : string ;
begin
    Result := '' ;

    if isISO9660()
    then
        Result := 'ISO 9660'
    else if isFAT()
    then
        Result := 'FAT'
    else if isFAT12()
    then
        Result := 'FAT12'
    else if isFAT16()
    then
        Result := 'FAT16'
    else if isFAT32()
    then
        Result := 'FAT32'
    else if isNTFS()
    then
        Result := 'NTFS'
    else if isExt2_3_4()
    then
        Result := 'Ext2/3/4'
    else if isReiserFS()
    then
        Result := 'ReiserFS'
    else if isHFS()
    then
        Result := 'HFS'
    else if isMFS()
    then
        Result := 'MFS'        
    else
        Result := '???' ;
end ;

function TSystemFile.isISO9660() : boolean ;
Var ReadStart  : _Large_Integer;
    ActualLengthRead : DWORD;
    Seek : DWORD;
begin
    ReadStart.QuadPart := $8000 ;
    Result := False ;

    Seek := SetFilePointer(FileHandle, ReadStart.LowPart, @ReadStart.HighPart, FILE_BEGIN);
    if Seek <> $FFFFFFFF
    then begin
        if ReadFile(FileHandle, Buffer, 8, ActualLengthRead, nil)
        then begin
            if (Buffer[0] = Char(01)) and (Buffer[1] = 'C') and (Buffer[2] = 'D') and (Buffer[3] = '0')
               and (Buffer[4] = '0') and (Buffer[5] = '1') and (Buffer[6] = Char(01)) and (Buffer[7] = Char(0))
            then begin
                Result := True ;
                SizeOfLabel := 31 ;
                PositionOfLabel.QuadPart := $8028 ;
            end ;
        end ;
    end
end ;

function TSystemFile.isFAT() : boolean ;
Var ReadStart  : _Large_Integer;
    ActualLengthRead : DWORD;
    Seek : DWORD;
    i : integer ;
    tmp : string ;
begin
    ReadStart.QuadPart := 54 ;
    Result := False ;

    Seek := SetFilePointer(FileHandle, ReadStart.LowPart, @ReadStart.HighPart, FILE_BEGIN);
    if Seek <> $FFFFFFFF
    then begin
        if ReadFile(FileHandle, Buffer, 8, ActualLengthRead, nil)
        then begin
            for i := 0 to 7 do
                tmp := tmp + Buffer[i] ;

            if tmp = 'FAT     '
            then begin
                Result := True ;
                SizeOfLabel := 11 ;
                PositionOfLabel.QuadPart := 43 ;
            end ;
        end ;
    end
end ;

function TSystemFile.isFAT12() : boolean ;
Var ReadStart  : _Large_Integer;
    ActualLengthRead : DWORD;
    Seek : DWORD;
    i : integer ;
    tmp : string ;
begin
    ReadStart.QuadPart := 54 ;
    Result := False ;

    Seek := SetFilePointer(FileHandle, ReadStart.LowPart, @ReadStart.HighPart, FILE_BEGIN);
    if Seek <> $FFFFFFFF
    then begin
        if ReadFile(FileHandle, Buffer, 8, ActualLengthRead, nil)
        then begin
            for i := 0 to 7 do
                tmp := tmp + Buffer[i] ;

            if tmp = 'FAT12   '
            then begin
                Result := True ;
                SizeOfLabel := 11 ;
                PositionOfLabel.QuadPart := 43 ;
            end ;
        end ;
    end
end ;

function TSystemFile.isFAT16 : boolean ;
Var ReadStart  : _Large_Integer;
    ActualLengthRead : DWORD;
    Seek : DWORD;
    i : integer ;
    tmp : string ;
begin
    ReadStart.QuadPart := 54 ;
    Result := False ;

    Seek := SetFilePointer(FileHandle, ReadStart.LowPart, @ReadStart.HighPart, FILE_BEGIN);
    if Seek <> $FFFFFFFF
    then begin
        if ReadFile(FileHandle, Buffer, 8, ActualLengthRead, nil)
        then begin
            for i := 0 to 7 do
                tmp := tmp + Buffer[i] ;

            if tmp = 'FAT16   '
            then begin
                Result := True ;
                SizeOfLabel := 11 ;
                PositionOfLabel.QuadPart := 43 ;
            end ;
        end ;
    end
end ;

function TSystemFile.isFAT32() : boolean ;
Var ReadStart  : _Large_Integer;
    ActualLengthRead : DWORD;
    Seek : DWORD;
    i : integer ;
    tmp : string ;
begin
    ReadStart.QuadPart := 82 ;
    Result := False ;

    Seek := SetFilePointer(FileHandle, ReadStart.LowPart, @ReadStart.HighPart, FILE_BEGIN);
    if Seek <> $FFFFFFFF
    then begin
        if ReadFile(FileHandle, Buffer, 8, ActualLengthRead, nil)
        then begin
            for i := 0 to 7 do
                tmp := tmp + Buffer[i] ;

            if tmp = 'FAT32   '
            then begin
                Result := True ;
                SizeOfLabel := 11 ;
                PositionOfLabel.QuadPart := 71 ;
            end ;
        end ;
    end
end ;

function TSystemFile.isNTFS() : boolean ;
Var ReadStart  : _Large_Integer;
    ActualLengthRead : DWORD;
    Seek : DWORD;
    i : integer ;
    tmp : string ;
begin
    ReadStart.QuadPart := 3 ;
    Result := False ;

    Seek := SetFilePointer(FileHandle, ReadStart.LowPart, @ReadStart.HighPart, FILE_BEGIN);
    if Seek <> $FFFFFFFF
    then begin
        if ReadFile(FileHandle, Buffer, 8, ActualLengthRead, nil)
        then begin
            for i := 0 to 7 do
                tmp := tmp + Buffer[i] ;

            if tmp = 'NTFS    '
            then begin
                Result := True ;
                SizeOfLabel := -1 ;
                PositionOfLabel.QuadPart := -1 ;
            end ;
        end ;
    end
end ;

function TSystemFile.isReiserFS() : boolean ;
Var ReadStart  : _Large_Integer;
    ActualLengthRead : DWORD;
    Seek : DWORD;
    i : integer ;
    tmp : string ;
begin
    ReadStart.QuadPart := 65536 + 52 ;
    Result := False ;

    Seek := SetFilePointer(FileHandle, ReadStart.LowPart, @ReadStart.HighPart, FILE_BEGIN);
    if Seek <> $FFFFFFFF
    then begin
        if ReadFile(FileHandle, Buffer, 12, ActualLengthRead, nil)
        then begin
            for i := 0 to 11 do
                tmp := tmp + Buffer[i] ;

            if tmp = 'ReIsEr2Fs'
            then begin
                Result := True ;
                SizeOfLabel := -1 ;
                PositionOfLabel.QuadPart := -1 ;
            end ;
        end ;
    end
end ;

function TSystemFile.isExt2_3_4() : boolean ;
Var ReadStart  : _Large_Integer;
    ActualLengthRead : DWORD;
    Seek : DWORD;
begin
    ReadStart.QuadPart := 1024 + 56 ;
    Result := False ;

    Seek := SetFilePointer(FileHandle, ReadStart.LowPart, @ReadStart.HighPart, FILE_BEGIN);
    if Seek <> $FFFFFFFF
    then begin
        if ReadFile(FileHandle, Buffer, 2, ActualLengthRead, nil)
        then begin
            if (Buffer[0] = char($53)) and (Buffer[1] = char($EF))
            then begin
                Result := True ;
                SizeOfLabel := 16 ;
                PositionOfLabel.QuadPart := 1024 + 56 + 62 + 2;
            end ;
        end ;
    end
end ;

function TSystemFile.isHFS() : boolean ;
Var ReadStart  : _Large_Integer;
    ActualLengthRead : DWORD;
    Seek : DWORD;
begin
    ReadStart.QuadPart := 1024 ;
    Result := False ;

    Seek := SetFilePointer(FileHandle, ReadStart.LowPart, @ReadStart.HighPart, FILE_BEGIN);
    if Seek <> $FFFFFFFF
    then begin
        if ReadFile(FileHandle, Buffer, 2, ActualLengthRead, nil)
        then begin
            if (Buffer[0] = char($42)) and (Buffer[1] = char($44))
            then begin
                Result := True ;
                SizeOfLabel := 27 ;
                PositionOfLabel.QuadPart := 1024 + 72 ;
            end ;
        end ;
    end
end ;

function TSystemFile.isMFS() : boolean ;
Var ReadStart  : _Large_Integer;
    ActualLengthRead : DWORD;
    Seek : DWORD;
begin
    ReadStart.QuadPart := 1024 ;
    Result := False ;

    Seek := SetFilePointer(FileHandle, ReadStart.LowPart, @ReadStart.HighPart, FILE_BEGIN);
    if Seek <> $FFFFFFFF
    then begin
        if ReadFile(FileHandle, Buffer, 2, ActualLengthRead, nil)
        then begin
            if (Buffer[0] = char($D2)) and (Buffer[1] = char($D7))
            then begin
                Result := True ;
                SizeOfLabel := -1 ;
                PositionOfLabel.QuadPart := -1 ;
            end ;
        end ;
    end
end ;

function TSystemFile.GetSizeOfLabel() : SmallInt ;
begin
    Result := SizeOfLabel ;
end ;

function TSystemFile.ReadLabel : string ;
var ActualLengthRead : DWORD;
    Seek : DWORD;
    i : SmallInt ;
begin
    Result := '' ;
    
    if SizeOfLabel = -1
    then
        GetFSType ;

    if SizeOfLabel <> -1
    then begin
        Seek := SetFilePointer(FileHandle, PositionOfLabel.LowPart, @PositionOfLabel.HighPart, FILE_BEGIN);
        if Seek <> $FFFFFFFF
        then begin
            if ReadFile(FileHandle, Buffer, SizeOfLabel, ActualLengthRead, nil)
            then begin
                For i := 0 to SizeOfLabel -1 do
                begin
                    Result := Result + Buffer[i] ;

                end ;

                Result := TrimRight(Result) ;
            end ;
        end ;
    end ;
end ;

function TSystemFile.WriteLabel(NewLabel : string) : SmallInt ;
var Seek : DWORD ;
    NbWrite : DWORD ;
    len : DWORD ;
    i : SmallInt ;
begin
    Result := WRITE_ERROR ;
    len := length(NewLabel) ;

    if SizeOfLabel = -1
    then
        GetFSType ;

    if SizeOfLabel = -1
    then
        Result := FILESYSTEM_NOT_SUPPORTED
    else
        if len > DWORD(SizeOfLabel)
        then
            Result := LABEL_TOO_LONG
        else begin
            if FileHandle = INVALID_HANDLE_VALUE
            then
                Result := CANT_OPEN_TO_WRITE
            else begin
                CloseHandle(FileHandle) ;
                FileHandle := CreateFile(PChar(FileName), GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0);

                Seek := SetFilePointer(FileHandle, PositionOfLabel.LowPart, @PositionOfLabel.HighPart, FILE_BEGIN);

                if Seek <> $FFFFFFFF
                then begin
                    // add space at end of label
                    for i := len to SizeOfLabel do
                        NewLabel := NewLabel + ' ' ;

                    for i := 1 to SizeOfLabel do
                        Buffer[i-1] := NewLabel[i] ;

                    WriteFile(FileHandle, buffer, SizeOfLabel, NbWrite, nil);

                    if NbWrite = Cardinal(SizeOfLabel)
                    then
                        Result := WRITE_OK ;
                end ;

                CloseHandle(FileHandle) ;
                FileHandle := CreateFile(PChar(FileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
            end ;
        end ;
    
end ;

end.
