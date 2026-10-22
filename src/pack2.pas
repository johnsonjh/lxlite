{$mode delphi}{$H-}
unit pack2;

interface

Function Compress  (Length:longint;Source,Destin:PByte):longint;
Function Decompress(Length:longint;Source,Destin:PByte):longint;

implementation

const
  TEXTSEARCH = 768;
  BINSEARCH  = 192;
  TEXTNEXT   = 64;
  BINNEXT    = 16;
  MAXFREQ    = 2000;
  MINCOPY    = 3;
  MAXCOPY    = 66;
  SHORTRANGE = 3;
  COPYRANGES = 7;
  CopyBits: array[0..PRED(COPYRANGES)] of Integer = (4,6,8,10,12,14,14);
  CODESPERRANGE = (MAXCOPY - MINCOPY + 1);
  NUL = -1;
  HASHSIZE = 32768;
  HASHMASK = (HASHSIZE - 1);
  TERMINATE = 256;
  FIRSTCODE = 257;
  MAXCHAR = (FIRSTCODE+COPYRANGES*CODESPERRANGE-1);
  SUCCMAX = (MAXCHAR+1);
  TWICEMAX = (2*MAXCHAR+1);
  ROOT = 1;
  MAXBUF = 4096;

type
  Copy_Type = Array[0..PRED(CopyRanges)] OF Integer;
const
  CopyMin: Copy_Type = (0,16,80,320,1024,4096,16384);
  CopyMax: Copy_Type = (15,79,319,1023,4095,16383,32768-Maxcopy);
  MaxDistance: Integer = 32768-Maxcopy;
  MaxSize = 32768;

type
  HashType    = packed Array[0..PRED(HashSize)] OF longint;
  Hash_Ptr    = ^HashType;
  ListType    = packed Array[0..MaxSize] OF longint;
  List_Ptr    = ^ListType;
  Buffer_Type = Array[0..MaxSize] OF byte;
  Buffer_Ptr  = ^Buffer_Type;
  HTree_Type  = packed Array[0..MaxChar] OF longint;
  THTree_Type = packed Array[0..TwiceMax] OF longint;

var
  Distance, Insrt: longint;
  DictFile, Binary: longint;
  Head, Tail: Hash_Ptr;
  Next, Prev: List_Ptr;
  Buffer: Buffer_Ptr;
  LeftC, RightC: HTree_Type;
  Parent, Freq: THTree_Type;
  CurBuf: PByte;
  Input_Bit_Count: longint;
  Input_Bit_Buffer: longint;
  Output_Bit_Count: longint;
  Output_Bit_Buffer: longint;
  Stack: array[0..50] of longint;

procedure initialize;
var i: longint;
begin
  for i:=2 to TWICEMAX do begin Parent[i]:=i shr 1; Freq[i]:=1; end;
  for i:=1 to MAXCHAR do begin LeftC[i]:=i shl 1; RightC[i]:=i shl 1+1; end;
end;

procedure Flush_Bits;
begin
  if Output_Bit_Count > 0 then
  begin
    Output_Bit_Buffer := Output_Bit_Buffer shl (32 - Output_Bit_Count);
    PLongint(CurBuf)^ := Output_Bit_Buffer;
    Inc(CurBuf, 4);
    Output_Bit_Count := 0;
  end;
end;

procedure Update_Freq(A, B: Integer);
begin
  repeat
    Freq[Parent[A]] := Freq[A] + Freq[B];
    A := Parent[A];
    if A <> ROOT then
      if LeftC[Parent[A]] = A then B := RightC[Parent[A]] else B := LeftC[Parent[A]];
  until A = ROOT;
  if Freq[ROOT] >= MAXFREQ then
  begin
    for A := 2 to TWICEMAX do Freq[A] := Freq[A] shr 1;
    for A := 1 to MAXCHAR do
      if (LeftC[A] <= MAXCHAR) and (Freq[LeftC[A]] = 0) then Freq[LeftC[A]] := 1;
  end;
end;

procedure Update_Model(Code: Integer);
var A, B, C: Integer;
begin
  A := Code + SUCCMAX;
  Inc(Freq[A]);
  if Parent[A] <> ROOT then
  begin
    repeat
      B := Parent[A];
      if LeftC[B] = A then C := RightC[B] else C := LeftC[B];
      Update_Freq(A, C);
      A := B;
    until Parent[A] = ROOT;
  end;
end;

procedure _Compress(code: Integer);
var a, _sp, bit: longint;
begin
  _Sp := 0; A := Code + SUCCMAX;
  repeat
    Stack[_Sp] := longint(RightC[Parent[A]] = A);
    Inc(_Sp);
    A := Parent[A];
  until A = ROOT;
  while _Sp > 0 do
  begin
    Dec(_Sp);
    bit := Stack[_Sp];
    Output_Bit_Buffer := (Output_Bit_Buffer shl 1) or (bit and 1);
    Inc(Output_Bit_Count);
    if Output_Bit_Count = 32 then
    begin
      PLongint(CurBuf)^ := Output_Bit_Buffer;
      Inc(CurBuf, 4);
      Output_Bit_Count := 0;
    end;
  end;
  Update_Model(Code);
end;

procedure Add_Node(N: longint);
var Key: longint;
begin
  Key := (Buffer^[N] xor (Buffer^[(N+1) and $7FFF] shl 4)) xor
         ((Buffer^[(N+2) and $7FFF] shl 8) and HASHMASK);
  if Head^[Key] = NUL then
  begin
    Tail^[Key] := N;
    Next^[N] := NUL;
  end
  else
  begin
    Next^[N] := Head^[Key];
    Prev^[Head^[Key]] := N;
  end;
  Head^[Key] := N;
  Prev^[N] := NUL;
end;

procedure Delete_Node(N: longint);
var Key: longint;
begin
  Key := (Buffer^[N] xor (Buffer^[(N+1) and $7FFF] shl 4)) xor
         ((Buffer^[(N+2) and $7FFF] shl 8) and HASHMASK);
  if Head^[Key] = Tail^[Key] then Head^[Key] := NUL
  else
  begin
    Next^[Prev^[Tail^[Key]]] := NUL;
    Tail^[Key] := Prev^[Tail^[Key]];
  end;
end;

function Match(N, Depth: longint): longint;
var
  Index, Dist, Len, Best, Count: longint;
  Key, I, J: longint;
begin
  Best := 0;
  Count := 0;
  if N = MaxSize then N := 0;
  Key := (Buffer^[N] xor (Buffer^[(N+1) and $7FFF] shl 4)) xor
         ((Buffer^[(N+2) and $7FFF] shl 8) and HASHMASK);
  Index := Head^[Key];
  while Index <> NUL do
  begin
    Inc(Count);
    if Count > Depth then break;
    if Buffer^[(N + Best) and $7FFF] = Buffer^[(Index + Best) and $7FFF] then
    begin
      J := Index;
      Len := 0;
      I := N;
      while (Buffer^[I and $7FFF] = Buffer^[J and $7FFF]) and (Len < MAXCOPY) and (J <> N) and (I <> Insrt) do
      begin
        Inc(Len);
        Inc(I);
        Inc(J);
      end;
      Dist := (N - Index) and $7FFF;
      Dist := Dist - Len;
      if (DictFile <> 0) and ((Dist and DictFile) > CopyMax[0]) then break;
      if (Len > Best) and (Dist <= MaxDistance) then
      begin
        if (Len > MINCOPY) or (Dist <= CopyMax[SHORTRANGE + Binary]) then
        begin
          Best := Len;
          Distance := Dist;
        end;
      end;
    end;
    Index := Next^[Index];
  end;
  Match := Best;
end;

function Compress(Length: longint; Source, Destin: PByte): longint;
const
  IDLE = 0;
  COPYING = 1;
var
  I, N, Len, NextLen, State, Full, AddPos: longint;
  bit, BitVal, C: longint;
begin
  Output_Bit_Count := 0; Output_Bit_Buffer := 0; Addpos := 0; Len := 0; Full := 0;
  State := IDLE; C := 0; CurBuf := Destin; N := MINCOPY;
  Binary := 0; DictFile := 0;
  initialize;
  New(Head); New(Tail); New(Next); New(Prev); New(Buffer);
  for i := 0 to PRED(HASHSIZE) do Head^[i] := NUL;

  for i := 0 to PRED(MINCOPY) do
  begin
    C := Source^; Inc(Source); Dec(Length);
    if Length = 0 then
    begin
      _Compress(TERMINATE);
      Flush_Bits;
      Dispose(Head); Dispose(Tail); Dispose(Next); Dispose(Prev); Dispose(Buffer);
      Compress := CurBuf - Destin;
      Exit;
    end;
    _Compress(C);
    Buffer^[i] := C;
  end;

  Insrt := MINCOPY;
  for i := 0 to PRED(MAXCOPY) do
  begin
    if Length = 0 then break;
    C := Source^; Inc(Source); Dec(Length);
    Buffer^[Insrt] := C;
    Inc(Insrt);
    if C > 127 then Binary := 1;
  end;

  while N <> Insrt do
  begin
    if Full <> 0 then Delete_Node(Insrt);
    Add_Node(AddPos);

    if State = COPYING then
    begin
      Dec(Len);
      if Len = 1 then State := IDLE;
    end
    else
    begin
      if Binary <> 0 then
      begin
        NextLen := Match(N + 1, BINNEXT);
        Len := Match(N, BINSEARCH);
      end
      else
      begin
        NextLen := Match(N + 1, TEXTNEXT);
        Len := Match(N, TEXTSEARCH);
      end;
      if (Len >= MINCOPY) and (Len >= NextLen) then
      begin
        State := COPYING;
        for i := 0 to PRED(COPYRANGES) do
        begin
          if Distance <= CopyMax[i] then
          begin
            _Compress(FIRSTCODE - MINCOPY + Len + I * CODESPERRANGE);
            BitVal := Distance - CopyMin[i];
            for bit := 1 to CopyBits[i] do
            begin
              Output_Bit_Buffer := (Output_Bit_Buffer shl 1) or (BitVal and 1);
              BitVal := BitVal shr 1;
              Inc(Output_Bit_Count);
              if Output_Bit_Count = 32 then
              begin
                PLongint(CurBuf)^ := Output_Bit_Buffer;
                Inc(CurBuf, 4);
                Output_Bit_Count := 0;
              end;
            end;
            break;
          end;
        end;
      end
      else
        _Compress(Buffer^[N]);
    end;

    N := (N + 1) and $7FFF;
    AddPos := (AddPos + 1) and $7FFF;

    if Length > 0 then
    begin
      Buffer^[Insrt] := Source^;
      Inc(Source);
      Dec(Length);
      Inc(Insrt);
      if Insrt = MaxSize then begin Insrt := 0; Full := 1; end;
    end
    else Full := 0;
  end;
  _Compress(TERMINATE);
  Flush_Bits;
  Dispose(Head); Dispose(Tail); Dispose(Next); Dispose(Prev); Dispose(Buffer);
  Compress := CurBuf - Destin;
end;

function Decompress(Length: longint; Source, Destin: PByte): longint;
var
  I, J, Dist, Len, Index, K, T: longint;
  N, C: longint;
begin
  Input_Bit_Count := 0; Input_Bit_Buffer := 0; N := 0; CurBuf := Destin;
  initialize;
  New(Buffer);
  C := 1;
  repeat
    if Input_Bit_Count = 0 then
    begin
      Input_Bit_Buffer := PLongint(Source)^;
      Inc(Source, 4);
      Input_Bit_Count := 31;
    end else Dec(Input_Bit_Count);
    if Input_Bit_Buffer < 0 then C := RightC[C] else C := LeftC[C];
    Input_Bit_Buffer := Input_Bit_Buffer shl 1;
  until C > MAXCHAR;
  Dec(C, SUCCMAX);
  Update_Model(C);

  while C <> TERMINATE do
  begin
    if C < 256 then
    begin
      CurBuf^ := C; Inc(CurBuf);
      Buffer^[N] := C; Inc(N); if N = MaxSize then N := 0;
    end
    else
    begin
      T := C - FIRSTCODE;
      Index := T div CODESPERRANGE;
      Len := T + MINCOPY - Index * CODESPERRANGE;
      Dist := 0;
      for i := 0 to CopyBits[Index] - 1 do
      begin
        if Input_Bit_Count = 0 then
        begin
          Input_Bit_Buffer := PLongint(Source)^;
          Inc(Source, 4);
          Input_Bit_Count := 31;
        end else Dec(Input_Bit_Count);
        if Input_Bit_Buffer < 0 then Dist := Dist or (1 shl i);
        Input_Bit_Buffer := Input_Bit_Buffer shl 1;
      end;
      Inc(Dist, Len + CopyMin[Index]);
      J := N;
      K := N - Dist;
      if K < 0 then Inc(K, MaxSize);
      for i := 0 to PRED(Len) do
      begin
        CurBuf^ := Buffer^[K]; Inc(CurBuf);
        Buffer^[J] := Buffer^[K];
        Inc(J); if J = MaxSize then J := 0;
        Inc(K); if K = MaxSize then K := 0;
      end;
      Inc(N, Len);
      if N >= MaxSize then Dec(N, MaxSize);
    end;
    C := 1;
    repeat
      if Input_Bit_Count = 0 then
      begin
        Input_Bit_Buffer := PLongint(Source)^;
        Inc(Source, 4);
        Input_Bit_Count := 31;
      end else Dec(Input_Bit_Count);
      if Input_Bit_Buffer < 0 then C := RightC[C] else C := LeftC[C];
      Input_Bit_Buffer := Input_Bit_Buffer shl 1;
    until C > MAXCHAR;
    Dec(C, SUCCMAX);
    Update_Model(C);
  end;
  Dispose(Buffer);
  Decompress := CurBuf - Destin;
end;

end.
