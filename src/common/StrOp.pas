{$mode delphi}{$H-}
Unit strOp;

Interface

const
     keywordSep = ' ';

type
     Str2       = String[2];
     Str4       = String[4];
     Str8       = String[8];
     Str10      = String[10];
     Str16      = String[16];

 Procedure LowStr(var S : String);
 Procedure UpStr(var S : String);
 Function  LowStrg(S : String) : String;
 Function  UpStrg(S : String) : String;

 Function  Hex8(A : Longint) : Str8;
 Function  Hex4(A : Word) : Str4;
 Function  Hex2(A : Byte) : Str2;
 Function  HexChar(A : Byte) : Char;

 Function  Bin16(a : Word) : Str16;
 Function  Bin8(a : Byte) : Str8;

 Function  HexVal(var s : String) : Longint;
 Function  DecVal(var s : String) : Longint;

 Procedure FormatStr(var Result: String; const Format: String; var Params);

 Function  SStr(a : Longint; n : Byte; ch : Char) : String;

 Function Left(const S : string; N : Integer) : string;
 Function Right(const S : string; N : Integer) : string;
 Function Center(const S : string; N : Integer; Fill : Char) : string;

 Function  long2str(L : Longint) : String;
 Function  signStr(L : Longint) : String;

 Procedure DelStartSpaces(var S : String);
 Procedure DelTrailingSpaces(var S : String);

 Function extractDir(const fName : string) : String;
 Function extractName(const fName : string) : String;
 Function extractExt(const fName : string) : String;

 Function  GetASCIIZ(var Text; No : Longint) : String;
 Function  GetASCIIZptr(var Text; No : Longint) : pChar;
 Function  CountASCIIZ(var Text) : Longint;

 Function  StripBlanks(const S : String) : String;
 Function  StrPercent(Val,Max : Longint; NFrac : Byte) : String;
 Function  StrFloat(Val,Base : Longint; NFrac : Byte) : String;

 Function  RomanNumber(A : Word) : string;
 Function  Short(const pathName : String; W : Byte) : String;

 Function  Strg(Ch : Char; Num : Integer) : String;
 Function  First(ch : Char; const S : String) : Byte;
 Function  Last(ch : Char; const S : String) : Byte;
 Function  ScanFwd(ch : Char; const S : String; N : Byte) : Byte;
 Function  ScanBwd(ch : Char; const S : String; N : Byte) : Byte;
 Function  CharCount(ch : Char; const S : String) : Byte;
 Function  Exclude(const S : String; Ch : Char) : String;

 Function  Keyword(var S : String; var KwData) : Byte;
 Function  KeywordSpc(var S : String; var KwData) : Byte;
 Function  GetKeyword(var KwData; No : Word) : String;

 Function  UpCase(C : Char) : Char;
 Function  LowCase(C : Char) : Char;
 Function  SetUpCase(var c : Char) : boolean;

Implementation uses Strings, Drivers;

Function HexChar(A : Byte) : Char;
const HexDigits : array[0..15] of Char = '0123456789ABCDEF';
begin
 HexChar := HexDigits[A and $0F];
end;

Function Hex2(A : Byte) : Str2;
begin
 Hex2 := HexChar(a shr 4) + HexChar(a);
end;

Function Hex4(A : Word) : Str4;
begin
 Hex4 := HexChar(Hi(a) shr 4) + HexChar(Hi(a))+
         HexChar(Lo(a) shr 4) + HexChar(Lo(a));
end;

Function Hex8(A : Longint) : Str8;
begin
 { A may be a signed 32-bit value.  Truncate the halves explicitly so
   range-checked FPC builds do not reject the Longint-to-Word cast. }
 Hex8 := Hex4(Word((A shr 16) and $FFFF)) + Hex4(Word(A and $FFFF));
end;

Function Bin16(a : Word) : Str16;
var s : Str16;
    i : Integer;
begin
 s := '';
 for i := 15 downto 0 do
   s := s + Char(48 + ((a shr i) and 1));
 Bin16 := s;
end;

Function Bin8(a : Byte) : Str8;
var s : Str8;
    i : Integer;
begin
 s := '';
 for i := 7 downto 0 do
   s := s + Char(48 + ((a shr i) and 1));
 Bin8 := s;
end;

Function UpCase(C : Char) : Char;
begin
 UpCase := System.UpCase(C);
end;

Function LowCase(C : Char) : Char;
begin
 if C in ['A'..'Z'] then LowCase := Char(Ord(C) + 32)
 else LowCase := C;
end;

procedure LowStr(var S : String);
var i : byte;
begin
 for i:=1 to length(s) do s[i]:=LowCase(s[i]);
end;

Function LowStrg(S : String) : String;
begin
 LowStr(s); LowStrg := s;
end;

Procedure UpStr(var S : String);
var i : byte;
begin
 for i:=1 to length(s) do s[i]:=UpCase(s[i]);
end;

Function UpStrg(S : String) : String;
begin
 UpStr(s); UpStrg := s;
end;

Function SStr(a : Longint; n : Byte; ch : Char) : String;
var s : String;
    i : Byte;
begin
 Str(a:n,s);
 for i := 1 to n do if s[i] = ' ' then s[i] := ch else break;
 SStr := s;
end;

Function Left(const S : string; N : Integer) : string;
begin
 Left := Copy(S, 1, N);
end;

Function Right(const S : string; N : Integer) : string;
begin
 Right := Copy(S, succ(length(S) - N), N);
end;

Function Center(const S : string; N : Integer; Fill : Char) : string;
var
 tS    : string;
 l,f,c : Integer;
begin
 c := length(S); l := (N - c) div 2;
 if l < 1
  then begin f := -l+2; l := 1; end
  else f := 1;
 if f + c > N then c := succ(N - f);
 tS := Strg(Fill, N);
 Move(S[f], tS[l], c);
 Center := tS;
end;

procedure FormatStr(var Result: String; const Format: String; var Params);
begin
 Drivers.FormatStr(Result, Format, Params);
end;

Function Strg(Ch : Char; Num : Integer) : String;
var S: String;
begin
 if Num < 0 then Num := 0;
 if Num > 255 then Num := 255;
 SetLength(S, Num);
 if Num > 0 then FillChar(S[1], Num, Ch);
 Strg := S;
end;

Function SetUpCase(var c : Char) : boolean;
begin
 c := UpCase(c);
 SetUpCase := c in ['0'..'9', 'A'..'F'];
end;

Function HexVal(var s : String) : Longint;
var i,j : Byte;
    k   : LongInt;
begin
 k:=0;i:=1;
 While SetUpCase(s[i]) and (i<=Length(s)) and (i<9) do
  begin
   j:=Byte(UpCase(s[i]))-48;if j>9 then Dec(j,7);
   k:=(k shl 4) or j;Inc(i);
  end;
 HexVal:=k;Delete(s,1,i-1);
end;

Function DecVal(var s : String) : Longint;
var i : Byte;
    k : LongInt;
    m : Boolean;
begin
 k := 0; i:=1;
 m := False;
 case s[1] of
  '-' : begin m := TRUE; Inc(i); end;
  '+' : Inc(i);
 end;
 While (i <= Length(s)) and (i < 11) and (UpCase(s[i]) in ['0'..'9']) do
  begin
   k := (k * 10) + (Byte(UpCase(s[i])) - 48);
   Inc(i);
  end;
 if m
  then DecVal := -k
  else DecVal := k;
 Delete(s, 1, i - 1);
end;

Function First(ch : Char; const S : String) : Byte;
var I : Integer;
begin
 for I := 1 to Length(S) do
  if S[I] = ch then begin First := I; Exit; end;
 First := 0;
end;

Function Last(ch : Char; const S : String) : Byte;
var I : Integer;
begin
 for I := Length(S) downto 1 do
  if S[I] = ch then begin Last := I; Exit; end;
 Last := 0;
end;

Function ScanFwd(ch : Char; const S : String; N : Byte) : Byte;
var I, C : Integer;
begin
 C := 0;
 for I := 1 to Length(S) do
  if S[I] = ch then
  begin
   Inc(C);
   if C = N then begin ScanFwd := I; Exit; end;
  end;
 ScanFwd := 0;
end;

Function ScanBwd(ch : Char; const S : String; N : Byte) : Byte;
var I, C : Integer;
begin
 C := 0;
 for I := Length(S) downto 1 do
  if S[I] = ch then
  begin
   Inc(C);
   if C = N then begin ScanBwd := I; Exit; end;
  end;
 ScanBwd := 0;
end;

Function CharCount(ch : Char; const S : String) : Byte;
var I, C : Integer;
begin
 C := 0;
 for I := 1 to Length(S) do
  if S[I] = ch then Inc(C);
 CharCount := C;
end;

Function Exclude(const S : String; Ch : Char) : String;
var I : Integer;
    Res : String;
begin
 Res := '';
 for I := 1 to Length(S) do
  if S[I] <> ch then Res := Res + S[I];
 Exclude := Res;
end;

Function Keyword(var S : String; var KwData) : Byte;
var
  pKw: PChar;
  curKw: String;
  kwIdx: Byte;
  kwLen: Byte;
begin
  pKw := @KwData;
  kwIdx := 1;
  while pKw^ <> #0 do
  begin
    curKw := '';
    while (pKw^ <> #0) and (pKw^ <> keywordSep) do
    begin
      curKw := curKw + pKw^;
      Inc(pKw);
    end;
    if pKw^ = keywordSep then Inc(pKw);
    kwLen := Length(curKw);
    if (kwLen > 0) and (Length(S) >= kwLen) then
    begin
      if StrLIComp(PChar(@S[1]), PChar(@curKw[1]), kwLen) = 0 then
      begin
        Delete(S, 1, kwLen);
        Result := kwIdx;
        Exit;
      end;
    end;
    Inc(kwIdx);
  end;
  Result := 0;
end;

Function KeywordSpc(var S : String; var KwData) : Byte;
var
  pKw: PChar;
  curKw: String;
  kwIdx: Byte;
  kwLen: Byte;
begin
  pKw := @KwData;
  kwIdx := 1;
  while pKw^ <> #0 do
  begin
    curKw := '';
    while (pKw^ <> #0) and (pKw^ <> keywordSep) do
    begin
      curKw := curKw + pKw^;
      Inc(pKw);
    end;
    if pKw^ = keywordSep then Inc(pKw);
    kwLen := Length(curKw);
    if (kwLen > 0) and (Length(S) >= kwLen) then
    begin
      if StrLIComp(PChar(@S[1]), PChar(@curKw[1]), kwLen) = 0 then
      begin
        if (Length(S) = kwLen) or (S[kwLen + 1] in [' ', #9]) then
        begin
          Delete(S, 1, kwLen);
          while (Length(S) > 0) and (S[1] in [' ', #9]) do Delete(S, 1, 1);
          Result := kwIdx;
          Exit;
        end;
      end;
    end;
    Inc(kwIdx);
  end;
  Result := 0;
end;

Function GetKeyword(var KwData; No : Word) : String;
var
  pKw: PChar;
  curKw: String;
  kwIdx: Word;
begin
  pKw := @KwData;
  kwIdx := 1;
  while pKw^ <> #0 do
  begin
    curKw := '';
    while (pKw^ <> #0) and (pKw^ <> keywordSep) do
    begin
      curKw := curKw + pKw^;
      Inc(pKw);
    end;
    if pKw^ = keywordSep then Inc(pKw);
    if kwIdx = No then
    begin
      Result := curKw;
      Exit;
    end;
    Inc(kwIdx);
  end;
  Result := '';
end;

Procedure DelStartSpaces(var S : String);
var I : Integer;
begin
 I := 1; While (I <= length(S)) and (S[I] in [' ',#9]) do Inc(I);
 Delete(S, 1, I - 1);
end;

Procedure DelTrailingSpaces(var S : String);
begin
 While (Length(S) > 0) and (S[length(S)] in [' ', #9]) do Dec(byte(S[0]));
end;

Function extractDir(const fName : string) : String;
var I : Byte;
begin
 I := length(fName);
 While (I > 0) and (not (fName[I] in ['/', '\', ':'])) do Dec(I);
 extractDir := Copy(fName, 1, I);
end;

Function extractName(const fName : string) : String;
var I : Byte;
begin
 I := length(fName);
 While (I > 0) and (not (fName[I] in ['/', '\', ':'])) do Dec(I);
 extractName := Copy(fName, I + byte(I > 0), 255);
end;

Function extractExt(const fName : string) : String;
var I : Byte;
begin
 I := length(fName);
 While (I > 0) and (not (fName[I] in ['.','/', '\', ':'])) do Dec(I);
 if (I > 0) and (fName[I] = '.')
  then extractExt := Copy(fName, I, 255)
  else extractExt := '';
end;

Function GetASCIIZ(var Text; No : Longint) : String;
var P : pChar;
    S : String;
begin
 P := GetASCIIZptr(Text, No);
 S := '';
 if P <> nil then
   While P^ <> #0 do begin S := S + P^; Inc(P); end;
 GetASCIIZ := S;
end;

Function GetASCIIZptr(var Text; No : Longint) : pChar;
var I   : Integer;
    P,F : pChar;
begin
 P := @Text;
 F := P; Inc(F, PLongint(F)^);
 Inc(P, sizeOf(Longint));
 For I := 2 to No do
  begin
   While (P < F) and (P^ <> #0) do Inc(P);
   if P >= F
    then begin P := nil; break; end
    else Inc(P);
  end;
 GetASCIIZptr := P;
end;

Function CountASCIIZ(var Text) : Longint;
var C   : Longint;
    P,F : pChar;
begin
 P := @Text; C := 0;
 F := P; Inc(F, PLongint(F)^);
 Inc(P, sizeOf(Longint));
 repeat
  While (P < F) and (P^ <> #0) do Inc(P);
  Inc(C);
  if P < F then Inc(P) else break;
 until FALSE;
 CountASCIIZ := C;
end;

Function StripBlanks(const S : String) : String;
var RS  : String;
    I,J : Integer;
begin
 J := 0;
 For I := 1 to length(S) do
  if not (S[I] in [' ',#9]) then begin Inc(J); RS[J] := S[I]; end;
 SetLength(RS, J);
 StripBlanks := RS;
end;

Function StrPercent(Val,Max : Longint; NFrac : Byte) : String;
var S : String;
    P : Longint;
    I : Integer;
begin
 P := 1; For I := 1 to NFrac + 2 do P := P * 10;
 S := SStr(Int64(Val) * P div Max, NFrac + 1, '0');
 if NFrac > 0 then Insert('.', S, length(S) - NFrac + 1);
 StrPercent := S;
end;

Function StrFloat(Val,Base : Longint; NFrac : Byte) : String;
var S : String;
    P : Longint;
    I : Integer;
begin
 P := 1; For I := 1 to NFrac do P := P * 10;
 S := SStr(Int64(Val) * P div Base, NFrac + 1, '0');
 if NFrac > 0 then Insert('.', S, length(S) - NFrac + 1);
 StrFloat := S;
end;

function RomanNumber(A : Word) : string;
var S : String[10];
begin
 if A >= 1000 then S := 'M' else S := '';
 A := A mod 1000;
 if A >= 100
    then case A div 100 of
          1..3 : S := S + Strg('C', A div 100);
          4    : S := S + 'CL';
          5..8 : S := S + 'L' + Strg('C', A div 100 - 5);
          9    : S := S + 'CM';
         end;
 A := A mod 100;
 if A >= 10
    then case A div 10 of
          1..3 : S := S + Strg('X', A div 10);
          4    : S := S + 'XL';
          5..8 : S := S + 'L' + Strg('X', A div 10 - 5);
          9    : S := S + 'XC';
         end;
 A := A mod 10;
 if A >= 1
    then case A of
          1..3 : S := S + Strg('I', A);
          4    : S := S + 'IV';
          5..8 : S := S + 'V' + Strg('I', A - 5);
          9    : S := S + 'IX';
         end;
 RomanNumber := S;
end;

Function Long2str(L : Longint) : String;
var A : String;
begin
 Str(L, A);
 Long2str := A;
end;

Function SignStr(L : Longint) : String;
var A : String;
begin
 Str(L, A);
 if L < 0
  then SignStr := A
  else
 if L > 0
  then SignStr := '+' + A
  else SignStr := ' ' + A;
end;

Function Short(const pathName : String; W : Byte) : String;
var
 sl,dl,
 i,j : integer;
 res : string;
begin
 if length(pathName) <= w
  then begin
        Short := pathName;
        exit;
       end;
 res := extractDir(pathName);
 dl := length(res); sl := 1;
 While (sl < length(res)) and (not (res[sl] in ['/','\'])) do Inc(sl);
 i := sl;
 res := pathName;
 repeat
  j := succ(i);
  While (j < dl) and (not (res[j] in ['/','\'])) do Inc(j);
  Delete(res, i, j-i);
 until (length(res) <= sl) or (length(res) + 4 <= w);
 Insert('...\', res, succ(i));
 Short := Copy(res, 1, w);
end;

end.
