unit QTThunkU;

{$R-,S-,Q-}

//Define only one of these symbols
//If none are defined it defaults to original windows

{$define Generic} //Should work on all versions of Win95
{ $define OSR2}    //Works on newer OSR2 versions
{ $define OSR1}    //Works on original version of Win95

interface

uses
  Windows, SysUtils;

type
  THandle16 = Word;

//Windows 95 undocumented routines. These won't be found in Windows NT
{$ifdef Generic}
var
  QT_Thunk: TProcedure;
{$else}
procedure QT_Thunk;
{$endif}
function  LoadLibrary16(LibFileName: PChar): THandle; stdcall;
procedure FreeLibrary16(LibModule: THandle); stdcall;
function  GetProcAddress16(Module: HModule; ProcName: PChar): TFarProc; stdcall;
function  GlobalAlloc16(Flags: Integer; Bytes: Longint): THandle16; stdcall;
function  GlobalFree16(Mem: THandle16): THandle16; stdcall;
function  GlobalLock16(Mem: THandle16): Pointer; stdcall;
function  GlobalUnLock16(Mem: THandle16): WordBool; stdcall;

//Windows NT/95 documented but undeclared routines

// 16:16 -> 0:32 Pointer translation.
//
// WOWGetVDMPointer will convert the passed in 16-bit address
// to the equivalent 32-bit flat pointer.  If fProtectedMode
// is TRUE, the function treats the upper 16 bits as a selector
// in the local descriptor table.  If fProtectedMode is FALSE,
// the upper 16 bits are treated as a real-mode segment value.
// In either case the lower 16 bits are treated as the offset.
//
// The return value is NULL if the selector is invalid.
//
// NOTE:  Limit checking is not performed in the retail build
// of Windows NT.  It is performed in the checked (debug) build
// of WOW32.DLL, which will cause NULL to be returned when the
// limit is exceeded by the supplied offset.
function WOWGetVDMPointer(vp, dwBytes: DWord;
                          fProtectedMode: Bool): Pointer; stdcall;

// The following two functions are here for compatibility with
// Windows 95.  On Win95, the global heap can be rearranged,
// invalidating flat pointers returned by WOWGetVDMPointer, while
// a thunk is executing.  On Windows NT, the 16-bit VDM is completely
// halted while a thunk executes, so the only way the heap will
// be rearranged is if a callback is made to Win16 code.
//
// The Win95 versions of these functions call GlobalFix to
// lock down a segment's flat address, and GlobalUnfix to
// release the segment.
//
// The Windows NT implementations of these functions do *not*
// call GlobalFix/GlobalUnfix on the segment, because there
// will not be any heap motion unless a callback occurs.
// If your thunk does callback to the 16-bit side, be sure
// to discard flat pointers and call WOWGetVDMPointer again
// to be sure the flat address is correct.
function WOWGetVDMPointerFix(vp, dwBytes: DWord;
                             fProtectedMode: Bool): Pointer; stdcall;
procedure WOWGetVDMPointerUnfix(vp: DWord); stdcall;

//My compound memory routines
function GlobalAllocPtr16(Flags: Word; Bytes: Longint): Pointer;
function GlobalAllocPointer16(Flags: Word; Bytes: Longint;
  var FlatPointer: Pointer; var Source; DataSize: Longint): Pointer;
function GlobalFreePtr16(P: Pointer): THandle16;

//My utility routines
function Ptr16To32(P: Pointer): Pointer;
function Ptr16To32Fix(P: Pointer): Pointer;
procedure Ptr16To32Unfix(P: Pointer);
function GetAddress16(Module: HModule; ProcName: String): TFarProc;

function LoadLib16(LibFileName: String): THandle;
function GDI16Handle: THandle;
function Kernel16Handle: THandle;
function User16Handle: THandle;

type
  TConvention = (ccPascal, ccCDecl);

function Call16BitRoutine(Name: String; DllHandle: THandle16;
  Convention: TConvention; Args: array of const;
  ArgSizes: array of Integer): Longint;

implementation

uses
  Classes, Dialogs;

type
  EInvalidArgument = class(EMathError);
  EInvalidProc = class(Exception);
  EThunkError = class(Exception);

const
  kernel32 = 'kernel32.dll';
  wow32 = 'wow32.dll';

//QT_Thunk changes its ordinal number under
//Windows 95 OSR2 so we link to it dynamically
//instead of statically, to ensure we get the right link
{$ifndef Generic}
  {$ifdef OSR2}
procedure QT_Thunk;              external kernel32 index 561;//name 'QT_Thunk';
  {$else} {OSR1 - original Win95}
procedure QT_Thunk;              external kernel32 index 559;//name 'QT_Thunk';
  {$endif}
{$endif}
//Don't link by name to avoid ugly messages under NT
//These routines are exported with no names, hence the use of index
function  LoadLibrary16;         external kernel32 index 35;
procedure FreeLibrary16;         external kernel32 index 36;
function  GetProcAddress16;      external kernel32 index 37;
function  GlobalAlloc16;         external kernel32 index 24;
function  GlobalFree16;          external kernel32 index 31;
function  GlobalLock16;          external kernel32 index 25;
function  GlobalUnLock16;        external kernel32 index 26;

//These routines are exported with names, hence the normal use of name
function  WOWGetVDMPointer;      external wow32 name 'WOWGetVDMPointer';
function  WOWGetVDMPointerFix;   external wow32 name 'WOWGetVDMPointerFix';
procedure WOWGetVDMPointerUnfix; external wow32 name 'WOWGetVDMPointerUnfix';

function GlobalAllocPtr16(Flags: Word; Bytes: Longint): Pointer;
begin
  Result := nil;
  //Ensure memory is fixed, meaning there is no need to lock it
  Flags := Flags or gmem_Fixed;
  LongRec(Result).Hi := GlobalAlloc16(Flags, Bytes);
end;

//16-bit pointer returned. FlatPointer is 32-bit pointer
//Bytes-sized buffer is allocated and then DataSize bytes
//from Source are copied in
function GlobalAllocPointer16(Flags: Word; Bytes: Longint;
  var FlatPointer: Pointer; var Source; DataSize: Longint): Pointer;
begin
  //Allocate memory in an address range
  //that _can_ be accessed by 16-bit apps
  Result := GlobalAllocPtr16(Flags, Bytes);
  //Get 32-bit pointer to this memory
  FlatPointer := Ptr16To32(Result);
  //Copy source data into the new bimodal buffer
  Move(Source, FlatPointer^, DataSize);
end;

function GlobalFreePtr16(P: Pointer): THandle16;
begin
  Result := GlobalFree16(LongRec(P).Hi);
end;

//Turn 16-bit pointer (selector and offset)
//into 32-bit pointer (offset)
function Ptr16To32(P: Pointer): Pointer;
begin
  Result := WOWGetVDMPointer(DWord(P), 0, True);
end;

//Turn 16-bit pointer (selector and offset)
//into 32-bit pointer (offset) and ensure it stays valid
function Ptr16To32Fix(P: Pointer): Pointer;
begin
  Result := WOWGetVDMPointerFix(DWord(P), 0, True);
end;

//Apply required housekeping to fixed 16-bit pointer
procedure Ptr16To32Unfix(P: Pointer);
begin
  WOWGetVDMPointerUnfix(DWord(P));
end;

function GetAddress16(Module: HModule; ProcName: String): TFarProc;
begin
  Result := GetProcAddress16(Module, PChar(ProcName));
  if not Assigned(Result) then
    raise EInvalidProc.Create('GetProcAddress16 failed');
end;

function LoadLib16(LibFileName: String): THandle;
begin
  Result := LoadLibrary16(PChar(LibFileName));
  if Result < HInstance_Error then
    raise EFOpenError.Create('LoadLibrary16 failed!');
end;

function GDI16Handle: THandle;
begin
  //Get GDI handle by loading it.
  Result := LoadLib16('GDI.EXE');
  //Free this particular load - GDI will stay in memory
  FreeLibrary16(Result);
end;

function Kernel16Handle: THandle;
begin
  //Get Kernel handle by loading it.
  Result := LoadLib16('KRNL386.EXE');
  //Free this particular load - Kernel will stay in memory
  FreeLibrary16(Result);
end;

function User16Handle: THandle;
begin
  //Get User handle by loading it.
  Result := LoadLib16('USER.EXE');
  //Free this particular load - User will stay in memory
  FreeLibrary16(Result);
end;

type
  TPtrSize = (ps16, ps32);

const
  //Max of 10 pointer params - no error checking yet
  MaxPtrs = 10;
  //Max of 1024 bytes passed, inc. indirectly - no error checking yet
  MaxParamBytes = 1024;

var
  ArgByteCount: Integer;
  ArgBuf: array[0..MaxParamBytes - 1] of Byte;
  ProcAddress: Pointer;

{$StackFrames On}
{$Optimization Off}
function CallQT_Thunk(Convention: TConvention): Longint;
var
  EatStackSpace: String[$3C];
begin
  //Ensure buffer isn't optimised away
  EatStackSpace := '';
  //Push ArgByteCount bytes from ArgBuf onto stack
  asm
    mov   edx, 0
  @LoopStart:
    cmp   edx, ArgByteCount
    je    @DoneStackBit
    mov   ax, word ptr [ArgBuf + edx]
    push  ax
    inc   edx
    inc   edx
    jmp   @LoopStart
  @DoneStackBit:
    mov   edx, ProcAddress
    call  QT_Thunk
    mov   Result.Word.0, ax
    mov   Result.Word.2, dx
    cmp   Convention, ccCDecl
    jne   @Exit
    add   esp, ArgByteCount
  @Exit:
  end;
end;
{$Optimization On}

//DLL must already be loaded with LoadLib16 or LoadLibrary16
//The routine name and DLL handle are passed in, along with
//an indication of the calling convention (C or Pascal)
//Parameters are passed in an array. These can be 1, 2 or 4 byte
//ordinals, or pointers to anything.
//Parameter sizes are passed in a second array. If no parameters
//are required, pass a 0 in both arrays. There must be as
//many sizes as there are parameters. If the parameter is a pointer
//the size is the number of significant bytes it points to
//This routine returns a Longint. Consequently, valid return types
//for the target routine are 1, 2 or 4 byte ordinal types or
//pointers. Pointers returned will be 16-bit. These will need
//reading via Ptr16To32Fix and Ptr16To32Unfix
function Call16BitRoutine(Name: String; DllHandle: THandle16;
  Convention: TConvention; Args: array of const;
  ArgSizes: array of Integer): Longint;
var
  Loop: Integer;
  ByteTemp: Word;
  Ptrs: array[0..MaxPtrs-1, TPtrSize] of Pointer;
  PtrCount: Byte;
  PtrArgIndices: array[0..MaxPtrs-1] of integer;       // maps Ptrs[] to
                                                    // original Args[]

  procedure PushParameter(Param: Integer);
  begin
    if ArgByteCount > MaxParamBytes then
      raise EThunkError.Create('Too many parameters');
    case Args[Param].VType of
      vtInteger, vtBoolean, vtChar:
      begin
        //Byte-sized args are passed as words
        if ArgSizes[Param] = 1 then
        begin
          //The important byte is stuck as msb of the 4
          //To get it into a word, assign it to one
          ByteTemp := Byte(Args[Param].VChar);
          Move(ByteTemp, ArgBuf[ArgByteCount], SizeOf(ByteTemp));
          //This means one extra byte on the stack
          Inc(ArgByteCount, 2);
        end
        else
        begin
          //If it's a 4 byte item, push the 2 high bytes
          if ArgSizes[Param] = 4 then
          begin
            Move(LongRec(Args[Param].VInteger).Hi,
              ArgBuf[ArgByteCount], SizeOf(Word));
            Inc(ArgByteCount, SizeOf(Word));
          end;
          //Either way, push the 2 low bytes
          Move(LongRec(Args[Param].VInteger).Lo,
            ArgBuf[ArgByteCount], SizeOf(Word));
          Inc(ArgByteCount, SizeOf(Word));
        end;
      end;
      vtPointer, vtPChar:
      begin
        if PtrCount = MaxPtrs then
          raise EThunkError.Create('Too many pointer parameters');
        //Must keep record of 16-bit and 32-bit
        //allocated pointers for terminal housekeeping
        Ptrs[PtrCount, ps16] := GlobalAllocPointer16(GPTR,
          ArgSizes[Param], Ptrs[PtrCount, ps32],
          Args[Param].vPointer^, ArgSizes[Param]);
        //Save arg position in arg list, may need
        //to copy back if arg is var
        PtrArgIndices[PtrCount] := Param;
        //Move high and low word of new pointer into ArgBuf
        //ready for push onto stack
        Move(LongRec(Ptrs[PtrCount, ps16]).Hi,
          ArgBuf[ArgByteCount], SizeOf(Word));
        Inc(ArgByteCount, SizeOf(Word));
        Move(LongRec(Ptrs[PtrCount, ps16]).Lo,
          ArgBuf[ArgByteCount], SizeOf(Word));
        Inc(ArgByteCount, SizeOf(Word));
        Inc(PtrCount);
      end;
    end;
  end;

begin
  //Check args
  if High(Args) <> High(ArgSizes) then
    raise EInvalidArgument.Create('Parameter mismatch');
  ArgByteCount := 0;
  PtrCount := 0;
  ProcAddress := GetProcAddress16(DLLHandle, PChar(Name));
  if not Assigned(ProcAddress) then
    raise EThunkError.Create('16-bit routine not found');
  //This should count up the number of bytes pushed
  //onto the stack. If Convention = ccCdecl, the stack
  //must be incremented that much after the routine ends
  //Also, parameters are pushed in reverse order if cdecl
  //Check for no parameters first
  if ArgSizes[Low(ArgSizes)] <> 0 then
    if Convention = ccPascal then
      for Loop := Low(Args) to High(Args) do
        PushParameter(Loop)
    else
      for Loop := High(Args) downto Low(Args) do
        PushParameter(Loop);
  Result := CallQT_Thunk(Convention);
  //Dispose of allocated pointers, copying
  //their contents back to 32-bit memory space
  //in case any data was updated by 16-bit code
  for Loop := 0 to Pred(PtrCount) do
  begin
    //Copy data back
    Move(Ptrs[Loop, ps32]^, Args[PtrArgIndices[Loop]].VPointer^,
         ArgSizes[PtrArgIndices[Loop]]);
    //Free pointer
    GlobalFreePtr16(Ptrs[Loop, ps16]);
  end;
end;

{$ifdef Generic}
var
  Kernel32Mod: THandle;

initialization
  Kernel32Mod := GetModuleHandle('Kernel32.Dll');
  QT_Thunk := GetProcAddress(Kernel32Mod, 'QT_Thunk');
//  if @QT_Thunk = nil then
//    raise EThunkError.Create('Flat thunks only supported under Windows 95');
{$else}
initialization
  if Win32Platform <> Ver_Platform_Win32_Windows then
    raise EThunkError.Create('Flat thunks only supported under Windows 95');
{$endif}
end.

