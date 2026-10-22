{$mode delphi}{$H-}
Unit CmdLine;

Interface

type
 ParmHandleFn = Function(var Parm : string) : Byte;

 Procedure ParseCommandLine(const ParmStr : string; PH,NH : ParmHandleFn);
 Function  ParseName(var ParmStr : string; StartChar : Word; var DestStr : string) : Word;

Implementation uses Strings, strOp;

Procedure ParseCommandLine(const ParmStr : string; PH,NH : ParmHandleFn);
var S : String;
    I : Integer;
    P : String;
begin
 if ParmStr = #0
  then begin
        S := '';
        for I := 1 to ParamCount do
        begin
          P := ParamStr(I);
          if Pos(' ', P) > 0 then P := '"' + P + '"';
          if S <> '' then S := S + ' ';
          S := S + P;
        end;
       end
  else S := ParmStr;
 While S <> '' do
  begin
   While (S <> '') and ((S[1] = ' ') or (S[1] = #9)) do Delete(S, 1, 1);
   if S <> ''
    then
     if (S[1] in ['/','-'])
      then begin
            Delete(S, 1, 1);
            if (@PH <> NIL) and (S <> '') then Delete(S, 1, PH(S));
           end
      else
     if @NH <> NIL
      then Delete(S, 1, NH(S))
      else Delete(S, 1, 1);
  end;
end;

Function ParseName(var ParmStr : string; StartChar : Word; var DestStr : string) : Word;
var I,J : Word;
    fCh : Char;
begin
 I := StartChar;
 While (I <= length(ParmStr)) and (ParmStr[I] in [#9, ' ']) do Inc(I);
 if I <= length(ParmStr)
  then begin
        J := I;
        if ParmStr[I] = '"'
         then fCh := '"'
         else fCh := ' ';
        repeat
         Inc(I);
        until (I > length(ParmStr)) or (ParmStr[I] = fCh);
        if fCh = '"'
         then begin DestStr := Copy(ParmStr, succ(J), pred(I - J)); Inc(I); end
         else DestStr := Copy(ParmStr, J, I - J);
       end
  else DestStr := '';
 ParseName := I - StartChar;
end;

end.
