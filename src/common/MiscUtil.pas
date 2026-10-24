{$mode delphi}{$H-}
Unit miscUtil;

Interface

const
{$ifdef OS2}
 tickerFreq             = 100;  {ticker frequence in 100000/Freq (1000)}
{$endif}
{$ifdef MSWINDOWS}
 tickerFreq             = 100;  {ticker frequence in 100000/Freq (1000)}
{$endif}
{$ifdef UNIX}
 tickerFreq             = 100;
{$endif}

type
  SmallWord  = System.Word;
  SmallInt   = System.SmallInt;
  Word16     = System.Word;
  Integer16  = System.SmallInt;
  Integer32  = System.Longint;
  Word32     = System.LongWord;
  Integer    = System.Longint;
  Word       = System.LongWord;
const
  MaxInt     = MaxLongint;

type
 tByteArray      = array[0..65500] of Byte;
 pByteArray      = ^tByteArray;
 tWordArray      = array[0..32700] of Word;
 pWordArray      = ^tWordArray;
 tSmallWordArray = array[0..32700] of SmallWord;
 pSmallWordArray = ^tSmallWordArray;
 pWord16Array    = ^tWord16Array;
 tWord16Array    = array[0..32700] of Word16;
 tLongArray      = array[0..16380] of Longint;
 pLongArray      = ^tLongArray;
 tPointerArray   = array[0..16380] of Pointer;
 pPointerArray   = ^tPointerArray;
 tCharArray      = array[0..65500] of Char;
 pCharArray      = ^tCharArray;
 pByte           = ^Byte;
 pWord           = ^Word;
 pSmallWord      = ^SmallWord;
 pWord16         = ^Word16;
 pSmallInt       = ^SmallInt;
 pInteger16      = ^Integer16;
 pWord32         = ^Word32;
 pInteger        = ^Integer;
 pLong           = ^Longint;
 pInteger32      = ^Integer32;
 pString         = ^String;

 tCmpFunc        = Function(var Buff; N1,N2 : Word) : boolean;
 tXchgProc       = Procedure(var Buff; N1,N2 : Word);

 pObject = ^tObject;
 tObject = object
  Constructor Create;
  Procedure   Zero;
  Procedure   Free; virtual;
  Destructor  Destroy; virtual;
 end;

 Function  NewStr(const S : String) : pString;
 Procedure DisposeStr(P : PString);
 Function  TimeInterval(sYear,sMonth,sDay,sHour,sMin,
                        fYear,fMonth,fDay,fHour,fMin : Word) : Longint;

 Procedure QuickSort(var Buff; First,Last : Word; ElementSize : Byte;
                     cmpFunc : tCmpFunc; xchgProc : tXchgProc);

 Function  bitTest(var bitArray; BitNo : Word) : boolean;
 Procedure bitSet(var bitArray; BitNo : Word);
 Procedure bitReset(var bitArray; BitNo : Word);

 Function  BitSF(A : Longint) : Byte;
 Function  BitSR(A : Longint) : Byte;

 Function  minL(A,B : Longint) : Longint;
 Function  maxL(A,B : Longint) : Longint;
 Function  minI(A,B : Integer) : Integer;
 Function  maxI(A,B : Integer) : Integer;

 Procedure linearMove(var A,B; Size : Word);

 Procedure XchgB(var A,B);
 Procedure XchgW(var A,B);
 Procedure XchgL(var A,B);
 Procedure Xchg(var A,B; Size : Word);

 Function  MemCmp(var A,B; Size : Word) : Shortint;
 Function  Search(var Buff; BuffLen : Word; var Target; TargetLen : Word) : Word;
 Function  MemScanFwd(var Buff; BuffLen : Word; Value : byte) : Word;
 Function  MemScanBwd(var Buff; BuffLen : Word; Value : byte) : Word;

 Function  bTicker : Byte;
 Function  wTicker : Word;
 Function  lTicker : Longint;

 Function  level2call(Proc,Info : Pointer) : boolean;

Implementation 
{$ifDef os2}   uses os2base; {$endIf}
{$ifDef MSWINDOWS} uses windows; {$endIf}
{$ifDef unix}  uses Unix; {$endIf}

constructor tObject.Create;
begin
 Zero;
end;

procedure tObject.Zero;
begin
 if SizeOf(Self) > SizeOf(tObject) then
   FillChar((PAnsiChar(@Self) + SizeOf(tObject))^, SizeOf(Self) - SizeOf(tObject), 0);
end;

procedure tObject.Free;
begin
end;

destructor tObject.Destroy;
begin
 Free;
end;

const EmptyStr : string[1] = '';

Function NewStr(const S : String) : pString;
var p : PString;
begin
 if S = ''
  then p := @EmptyStr
  else begin
        GetMem(p, succ(length(S)));
        p^ := S;
       end;
 NewStr := p;
end;

Procedure DisposeStr(P : PString);
begin
 if (P <> nil) and (p <> @EmptyStr) then FreeMem(p, succ(integer(length(p^))));
end;

Function TimeInterval(sYear,sMonth,sDay,sHour,sMin,
                      fYear,fMonth,fDay,fHour,fMin : Word) : Longint;
const
    daysInMonth      : array[1..12] of Byte =
    (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
var cY,cM,cD,cH,cMin : Word;
    tI               : Longint;

procedure IncMonth;
begin
 Inc(cM);
 if cM > 12 then begin cM := 1; Inc(cY); end;
end;

procedure IncDay;
begin
 Inc(cD);
 if cD > daysInMonth[cM] + byte((cM = 2) and (cY and 3 = 0))
  then begin cD := 1; IncMonth; end;
end;

procedure IncHour;
begin
 Inc(cH);
 if cH > 23 then begin cH := 0; IncDay; end;
end;

procedure IncMin;
begin
 Inc(cMin);
 if cMin > 59 then begin cMin := 0; IncHour; end;
end;

begin
 cY := sYear; cM := sMonth; cD := sDay;
 cH := sHour; cMin := sMin; tI := 0;
 While (cY <> fYear) or (cM <> fMonth) or (cD <> fDay) or
       (cH <> fHour) or (cMin <> fMin) do
  begin
   if (cY <> fYear) and (cM = 1) and (cD = 1) and (cH = 0) and (cMin = 0)
    then begin
          Inc(tI, longint(365 + byte(cY and 3 = 0)) * 1440);
          Inc(cY);
         end
    else
   if ((cY <> fYear) or (cM <> fMonth)) and (cD = 1) and (cH = 0) and (cMin = 0)
    then begin
          Inc(tI, longint(daysInMonth[cM] + byte((cM = 2) and (cY and 3 = 0))) * 1440);
          IncMonth;
         end
    else
   if ((cY <> fYear) or (cM <> fMonth) or (cD <> fDay)) and (cH = 0) and (cMin = 0)
    then begin
          Inc(tI, 1440); IncDay;
         end
    else
   if ((cY <> fYear) or (cM <> fMonth) or (cD <> fDay) or (cH <> fHour)) and (cMin = 0)
    then begin
          Inc(tI, 60); IncHour;
         end
    else begin
          Inc(tI); IncMin;
         end;
  end;
 TimeInterval := tI;
end;

Function lTicker : Longint;
{$IFDEF OS2}
var L : Longint;
begin
 DosQuerySysInfo(qsv_Ms_Count, qsv_Ms_Count, L, SizeOf(L));
 lTicker := L;
end;
{$ELSE}
{$IFDEF UNIX}
var tv: timeval;
begin
 fpgettimeofday(@tv, nil);
 lTicker := Longint(tv.tv_sec * 1000 + tv.tv_usec div 1000);
end;
{$ELSE}
begin
 lTicker := GetTickCount;
end;
{$ENDIF}
{$ENDIF}

Function wTicker : Word;
begin
 wTicker := lTicker and $FFFF;
end;

Function bTicker : Byte;
begin
 bTicker := lTicker and $FF;
end;

Function minL(A,B : Longint) : Longint;
begin if A <= B then minL := A else minL := B; end;

Function maxL(A,B : Longint) : Longint;
begin if A >= B then maxL := A else maxL := B; end;

Function minI(A,B : Integer) : Integer;
begin if A <= B then minI := A else minI := B; end;

Function maxI(A,B : Integer) : Integer;
begin if A >= B then maxI := A else maxI := B; end;

Procedure QuickSort(var Buff; First,Last : Word; ElementSize : Byte;
                    cmpFunc : tCmpFunc; xchgProc : tXchgProc);

function CmpInt(var Buff; N1,N2:Word):boolean;
begin
  case ElementSize of
  1: cmpInt := tByteArray(Buff)[N1] >= tByteArray(Buff)[N2];
  2: cmpInt := tWord16Array(Buff)[N1] >= tWord16Array(Buff)[N2];
  4: cmpInt := tWordArray(Buff)[N1] >= tWordArray(Buff)[N2];
  else cmpInt := True;
  end;
end;

procedure XchgInt(var Buff; N1,N2:Word);
begin
  case ElementSize of
  1: xchgB(tByteArray(Buff)[N1],tByteArray(Buff)[N2]);
  2: xchgW(tWord16Array(Buff)[N1],tWord16Array(Buff)[N2]);
  4: xchgL(tWordArray(Buff)[N1],tWordArray(Buff)[N2]);
  end;
end;

var i,med,c:Word;

procedure QuickSort2(First,Last:Word);
var j:Word;
begin
    c := succ(Last-First);
    if c<=1 then Exit;
    med := First + Random(c);
    i := First; j := Last;
    while true do
    begin
        while (i<j) and CmpFunc(Buff,j,med) do dec(j);
        while (i<j) and not CmpFunc(Buff,i,med) do inc(i);
        if i>=j then break;
        if med=i then med:=j else if med=j then med:=i;
        XchgProc(Buff,i,j);
    end;
    QuickSort2(First,j);
    QuickSort2(j+1,Last);
end;

begin
    if @CmpFunc=nil then
        case ElementSize of
          1,2,4: CmpFunc := @CmpInt;
          else Exit;
        end;

    if @XchgProc=nil then
        case ElementSize of
          1,2,4: XchgProc := @XchgInt;
          else Exit;
        end;

    QuickSort2(First,Last);
end;

Function bitTest(var bitArray; BitNo : Word) : boolean;
begin
  bitTest := (pByteArray(@bitArray)^[BitNo shr 3] and (1 shl (BitNo and 7))) <> 0;
end;

Procedure bitSet(var bitArray; BitNo : Word);
begin
  pByteArray(@bitArray)^[BitNo shr 3] := pByteArray(@bitArray)^[BitNo shr 3] or (1 shl (BitNo and 7));
end;

Procedure bitReset(var bitArray; BitNo : Word);
begin
  pByteArray(@bitArray)^[BitNo shr 3] := pByteArray(@bitArray)^[BitNo shr 3] and not (1 shl (BitNo and 7));
end;

Procedure XchgB(var a,b);
var T : Byte;
begin
  T := Byte(A); Byte(A) := Byte(B); Byte(B) := T;
end;

Procedure XchgW(var a,b);
var T : Word16;
begin
  T := Word16(A); Word16(A) := Word16(B); Word16(B) := T;
end;

Procedure XchgL(var a,b);
var T : Longint;
begin
  T := Longint(A); Longint(A) := Longint(B); Longint(B) := T;
end;

Procedure Xchg(var A,B; Size : Word);
var
  pA, pB : PByteArray;
  T : Byte;
  I : Word;
begin
  if Size = 0 then Exit;
  pA := @A; pB := @B;
  for I := 0 to Size - 1 do
  begin
    T := pA^[I]; pA^[I] := pB^[I]; pB^[I] := T;
  end;
end;

Procedure linearMove(var A,B; Size : Word);
var
  pA, pB : PByteArray;
  I : Word;
begin
  if Size = 0 then Exit;
  pA := @A; pB := @B;
  for I := 0 to Size - 1 do
    pB^[I] := pA^[I];
end;

Function BitSF(A : Longint) : Byte;
var I : Byte;
begin
  if A = 0 then BitSF := 255
  else
  begin
    I := 0;
    while (A and 1) = 0 do
    begin
      Inc(I);
      A := A shr 1;
    end;
    BitSF := I;
  end;
end;

Function BitSR(A : Longint) : Byte;
var I : Byte;
    uA : LongWord;
begin
  uA := LongWord(A);
  if uA = 0 then BitSR := 255
  else
  begin
    I := 31;
    while (uA and $80000000) = 0 do
    begin
      Dec(I);
      uA := uA shl 1;
    end;
    BitSR := I;
  end;
end;

Function MemCmp(var A,B; Size : Word) : Shortint;
var
  pA, pB : PByteArray;
  I : Word;
begin
  if Size = 0 then begin MemCmp := 0; Exit; end;
  pA := @A; pB := @B;
  for I := 0 to Size - 1 do
  begin
    if pA^[I] < pB^[I] then begin MemCmp := -1; Exit; end
    else if pA^[I] > pB^[I] then begin MemCmp := 1; Exit; end;
  end;
  MemCmp := 0;
end;

Function Search(var Buff; BuffLen : Word; var Target; TargetLen : Word) : Word;
var
  pB, pT : PByteArray;
  I, J : Word;
  match : Boolean;
begin
  if (TargetLen = 0) or (BuffLen < TargetLen) then
  begin
    Search := Word(-1);
    Exit;
  end;
  pB := @Buff; pT := @Target;
  for I := 0 to BuffLen - TargetLen do
  begin
    match := True;
    for J := 0 to TargetLen - 1 do
    begin
      if pB^[I + J] <> pT^[J] then
      begin
        match := False;
        break;
      end;
    end;
    if match then
    begin
      Search := I;
      Exit;
    end;
  end;
  Search := Word(-1);
end;

Function MemScanFwd(var Buff; BuffLen : Word; Value : byte) : Word;
var
  pB : PByteArray;
  I : Word;
begin
  pB := @Buff;
  I := 0;
  while (I < BuffLen) and (pB^[I] = Value) do
    Inc(I);
  MemScanFwd := I;
end;

Function MemScanBwd(var Buff; BuffLen : Word; Value : byte) : Word;
var
  pB : PByteArray;
  I : Word;
begin
  if BuffLen = 0 then begin MemScanBwd := 0; Exit; end;
  pB := @Buff;
  I := 0;
  while (I < BuffLen) and (pB^[BuffLen - 1 - I] = Value) do
    Inc(I);
  MemScanBwd := I;
end;

type
  tProcInfo = function(Info: Pointer): Boolean;

Function level2call(Proc,Info : Pointer) : boolean;
begin
  if Proc <> nil then
    level2call := tProcInfo(Proc)(Info)
  else
    level2call := False;
end;

end.
