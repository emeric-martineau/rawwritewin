unit BinFile;

interface

// beware the EInOutError

type
   TBinaryFile = class
      private
         FileName : String;
         F : File;
         IsOpen : Boolean;
      public
         constructor Create;
         destructor Destroy; override;
         procedure Assign(Name : String);
         procedure Open(Mode : Integer);
         procedure Close;
         procedure CloseFile;
         function  ReadString : String;
         procedure WriteString(S : String);
         function  ReadInteger : Integer;
         procedure WriteInteger(Val : Integer);
         function  ReadChar : Char;
         procedure WriteChar(Val : Char);
         procedure BlockRead(var Buf; Count: Integer);
         procedure BlockRead2(Buf : Pointer; Count: Integer);
         procedure BlockWrite(var Buf; Count: Integer);
         function EOF : Boolean;
         function FileSize : Integer;
   end;
implementation

constructor TBinaryFile.Create;
begin
   IsOpen := False;
end;

destructor TBinaryFile.Destroy;
begin
   if IsOpen then
   begin
      Close;
   end;
end;

procedure TBinaryFile.Assign(Name : String);
begin
   FileName := Name;
   AssignFile(F, Name);
end;

procedure TBinaryFile.Open(Mode : Integer);
begin
   // Mode 0 = read
   // Mode 1 = write
   // Mode 2 = append

   case Mode of
      0: begin
            Reset(F, 1);
         end;
      1: begin
            Rewrite(F, 1);
         end;
      2: begin
            try
               Reset(F, 1);
               Seek(F, System.FileSize(F));
            except
               Rewrite(F, 1);
            end;
         end;
   end;
   IsOpen := True;
end;

procedure TBinaryFile.Close;
begin
   System.CloseFile(F);
   IsOpen := False;
end;

procedure TBinaryFile.CloseFile;
begin
   Close;
end;

function TBinaryFile.ReadInteger : Integer;
begin
   if not IsOpen then
   begin
      Open(0);
   end;
   System.BlockRead(F, Result, SizeOf(Result));
end;

function TBinaryFile.ReadString : String;
var
   Len : Integer;
   S : String;
begin
   Len := ReadInteger;
   SetLength(S, Len);
//   System.BlockRead(F, S[i], Len);
   System.BlockRead(F, PChar(S)^, Len);
   Result := S;
end;

function  TBinaryFile.ReadChar : Char;
begin
   if not IsOpen then
   begin
      Open(0);
   end;
   System.BlockRead(F, Result, SizeOf(Result));
end;

procedure TBinaryFile.WriteChar(Val : Char);
begin
   if not IsOpen then
   begin
      Open(1);
   end;
   System.BlockWrite(F, Val, SizeOf(Val));
end;

procedure TBinaryFile.WriteInteger(Val : Integer);
begin
   if not IsOpen then
   begin
      Open(1);
   end;
   System.BlockWrite(F, Val, SizeOf(Val));
end;

procedure TBinaryFile.WriteString(S : String);
begin
   WriteInteger(Length(S));
//   System.BlockWrite(F, S[i], Length(S));
   System.BlockWrite(F, PChar(S)^, Length(S));
end;

procedure TBinaryFile.BlockRead(var Buf; Count: Integer);
begin
   if not IsOpen then
   begin
      Open(0);
   end;
   System.BlockRead(F, Buf, Count);
end;

procedure TBinaryFile.BlockRead2(Buf : Pointer; Count: Integer);
begin
   if not IsOpen then
   begin
      Open(0);
   end;
   System.BlockRead(F, Buf^, Count);
end;

procedure TBinaryFile.BlockWrite(var Buf; Count: Integer);
begin
   if not IsOpen then
   begin
      Open(1);
   end;
   System.BlockWrite(F, Buf, Count);
end;

function TBinaryFile.EOF : Boolean;
begin
   if not IsOpen then
   begin
      Open(0);
   end;
   Result := System.Eof(F);
end;

function TBinaryFile.FileSize : Integer;
begin
   if not IsOpen then
   begin
      Open(0);
   end;
   Result := System.FileSize(F);
end;

end.
