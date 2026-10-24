{$mode delphi}{$packrecords 1}{$H-}
Unit lxLite_Objects;

Interface uses exe286, exe386, os2exe, miscUtil, sysLib,
               strOp, Country, Collect, lxlite_Global;
type
 pMyCmdLineParser = ^tMyCmdLineParser;
 tMyCmdLineParser = object(tCommandLineParser)
  function    ParmHandler(var ParmStr : string) : Word; virtual; {returns numbers of characters parsed}
  function    NameHandler(var ParmStr : string) : Word; virtual; {returns numbers of characters parsed}
  procedure   PreProcess(var ParmStr : string); virtual;
  procedure   PostProcess; virtual;
  destructor  Destroy; virtual;
 end;

 pMyLX = ^tMyLX;
 tMyLX = object(tLX)
  procedure   DisplayExeInfo;
  procedure   ReadPagesFromFile(StartP,EndP:Longint;var FileName:string;ReadPack:LongInt);
  procedure   WritePagesToFile(StartP,EndP:Longint;var FileName:string;PageUnpFlags:LongInt);
 end;

var
 LX        : pMyLX;
 Parser    : pMyCmdLineParser;
 pfNames,
 cfgIDs    : pStringCollection;
 cfgOpts,
 extra,
 extraOpts : pCollection;
 totalGain : Longint;
 allDone   : boolean;
 oldExit   : Procedure;
 logFile   : Text;
 Cntry     : pCountry;
 ModDef    : pModuleCollection;

 procedure PrintHeader;
 procedure ApplyOutputMode;
 procedure WriteError(const msg: string);
 procedure Stop(eCode : Word; const ParmStr : string);
 function  FormatStr(Template : Longint; Params : array of const) : string;
 procedure NL;
 procedure LoadConfig;
 procedure setConfig(const ID : string);
 procedure ShowConfig;

Implementation uses Crt, Dos, Strings, Drivers
{$IFDEF MSWINDOWS}, Windows{$ENDIF};

var
 CmdLineStack : pStringCollection;

procedure SwitchStdOut(State : boolean);
begin
 if State
  then begin
        Move(StdOut, Output, sizeOf(Output));
        Move(StdIn, Input, sizeOf(Input));
       end
  else begin
        AssignCrt(Output);
        Rewrite(Output);
       end;
end;

{ CRT's 80-column byte-oriented writer can split a multibyte UTF-8 glyph.
  Use the regular text stream for Unicode output, including a TTY. }
procedure ApplyOutputMode;
begin
 SwitchStdOut(opt.UseStdOut or opt.UnicodeOutput);
 ConfigureOutputTTY;
 SetColor(textAttr);
end;

procedure WriteError(const msg: string);
begin
 Writeln(StdErr, msg);
end;

function FormatStr(Template : Longint; Params : array of const) : string;
var
 nP : array[0..31] of PtrUInt;
 I  : Integer;
 S  : string;
begin
 for I := Low(Params) to High(Params) do
 case Params[I].VType of
   vtInteger: nP[I - Low(Params)] := PtrUInt(Params[I].VInteger);
   vtInt64: nP[I - Low(Params)] := PtrUInt(Params[I].VInt64^);
   vtPointer: nP[I - Low(Params)] := PtrUInt(Params[I].VPointer);
   vtPChar: nP[I - Low(Params)] := PtrUInt(Params[I].VPChar);
   vtString: nP[I - Low(Params)] := PtrUInt(Params[I].VString);
   vtAnsiString: nP[I - Low(Params)] := PtrUInt(Params[I].VAnsiString);
   vtChar: nP[I - Low(Params)] := PtrUInt(Ord(Params[I].VChar));
   else nP[I - Low(Params)] := PtrUInt(Params[I].VPointer);
 end;
 S := OutputResource(Template);
 Drivers.FormatStr(Result, S, nP);
end;

procedure PrintHeader;
const
 Already : boolean = FALSE;
begin
 if Already then Exit;
 Already := TRUE;
 Write(FormatStr(msgProgHeader1, [lxLite_Global.Version])); NL;
 Write(OutputResource(msgProgHeader2)); NL;
 Write(OutputResource(msgProgHeader3)); NL;
 Write(OutputResource(msgProgHeader4)); NL;
 Write(OutputResource(msgProgHeader5)); NL;
 Write(OutputResource(msgProgHeaderX)); NL;
 Write(OutputResource(msgProgHeader6)); NL;
end;

{$IFDEF MSWINDOWS}
{ The Windows CRT ReadKey implementation reads from TextRec(Input).Handle,
  which is vulnerable to changes in the application's text stream setup.
  Only the help pager uses this direct console-event path; the traditional
  keyboard handling on OS/2 and Unix is unchanged. }
function PagerHasConsoleInput: Boolean;
var
  H : THandle;
  Mode : DWORD;
begin
  H := GetStdHandle(STD_INPUT_HANDLE);
  PagerHasConsoleInput := FALSE;
  if (H = 0) or (H = INVALID_HANDLE_VALUE) then Exit;
  if not GetConsoleMode(H, Mode) then Exit;
  { Never stop for a key when the help text itself is being redirected. }
  H := GetStdHandle(STD_OUTPUT_HANDLE);
  if (H = 0) or (H = INVALID_HANDLE_VALUE) then Exit;
  PagerHasConsoleInput := GetConsoleMode(H, Mode);
end;

function PagerReadKey: Char;
var
  H : THandle;
  E : TInputRecord;
  N : DWORD;
begin
  { If the console disappears while paging, advance instead of hanging. }
  PagerReadKey := ' ';
  H := GetStdHandle(STD_INPUT_HANDLE);
  if (H = 0) or (H = INVALID_HANDLE_VALUE) then Exit;
  repeat
    if not ReadConsoleInputW(H, E, 1, N) then Exit;
    if N = 0 then Continue;
    if E.EventType <> KEY_EVENT then Continue;
    if not E.Event.KeyEvent.bKeyDown then Continue;
    case E.Event.KeyEvent.wVirtualKeyCode of
      VK_SPACE  : begin PagerReadKey := ' '; Exit; end;
      VK_RETURN : begin PagerReadKey := #13; Exit; end;
      VK_ESCAPE : begin PagerReadKey := #27; Exit; end;
      Ord('Q')  : begin PagerReadKey := 'Q'; Exit; end;
    end;
  until FALSE;
end;
{$ELSE}
function PagerHasConsoleInput: Boolean;
begin
  PagerHasConsoleInput := TRUE;
end;

function PagerReadKey: Char;
begin
  PagerReadKey := ReadKey;
end;
{$ENDIF}

procedure NL;
const
 Rows : Longint = -1;
var
 Attr : Byte;
 I    : Integer;
 S    : string;
begin
 Attr := textAttr;
 SetColor($07); Writeln;
 if Rows = -1 then Rows := hi(WindMax);
 Dec(Rows);
 if Rows = 0
  then if not (RedirOutput or RedirInput) and PagerHasConsoleInput
        then begin
              S := OutputResource(msgMore);
              SetColor($30); I := (80 - OutputWidth(S)) div 2;
              Write(Strg(' ', I), S); ClearToEOL;
              Flush(Output);
              repeat
               I := 0;
               case upCase(PagerReadKey) of
                ' ' : Rows := hi(WindMax);
                #13 : Rows := 1;
                'Q',
                #27 : begin
                       Write(#13); SetColor($07); ClearToEOL;
                       SetColor($04);
                       Writeln(OutputResource(msgAborted));
                       Halt(1);
                      end;
                else I := 1;
               end;
              until I = 0;
              Write(#13); SetColor($07); ClearToEOL;
             end
        else Rows := hi(WindMax);
 SetColor(Attr);
end;

Procedure Stop;
var
 I : Integer;
 S : string;
 B : boolean;
begin
 if WhereX > 1 then Write(#13);
 PrintHeader;
 SetColor($04);
 case eCode of
  0     : ;
  1,2   : begin
           if eCode = 2
            then begin
                  SetColor($0E);
                  if (CmdLineStack <> nil) and (CmdLineStack^.Count > 0)
                   then S := pString(CmdLineStack^.At(pred(CmdLineStack^.Count)))^
                   else S := '';
                  S := Copy(S, 1, length(S) - length(ParmStr));
                  DelStartSpaces(S);
                  Write(FormatStr(msgInvalidSwitch, [S]));
                  // we also write all errors to stderr
                  WriteError(FormatStr(msgInvalidSwitch, [S]));
                  SetColor($04);
                  S := parmStr;
                  DelTrailingSpaces(S);
                  Write(S); NL;
                  // we also write all errors to stderr
                  WriteError(S);
                 end;
           B := TRUE;
           For I := msgHelpFirst to msgHelpLast do
            begin
             { The help markup is still inspected in CP437, before display. }
             S := SysLib.GetResourceString(I);
             case S[1] of
              '≥' : if B then SetColor($09);
              '√' : case S[2] of
                     '¥' : begin SetColor($03); B := FALSE; end;
                     else SetColor($0B);
                    end;
              '¿' : SetColor($08);
             end;
             Write(OutputCP437(S)); NL;
             if I = 532 then begin
               SetColor($0B);
               Write(OutputResource(617)); NL;
               SetColor($09);
               Write(OutputResource(618)); NL;
               Write(OutputResource(619)); NL;
             end;
            end;
          end;
  else begin 
   Writeln(FormatStr(eCode, [parmStr]));
   // we also write all errors to stderr
   WriteError(FormatStr(eCode, [parmStr]));
  end;
 end;
 Halt(eCode mod 100);
end;

procedure tMyLX.DisplayExeInfo;
const
 txtGfx      : array[boolean] of array[1..6] of Char = ('≥≥≥≥≥≥','¿¡Ÿ√¡Ÿ');
 atDefault   = $0B;
 atInfo      = $0A;
 atFlags     = $0C;
 atHLinfo    = $0B;
 atFixups    = $03;
 atFixupOfs  = $02;
 atSeparator = $0E;
var
 S,tmpS    : String;
 oldAt,
 I,J,K,L,M : Longint;
 pFixOfs   : pWord16;
 Fixups    : pFixupCollection;
 oldPage   : Pointer;
 oldPageMap: tObjMapRec;

procedure AddStr(const nS : string);
begin
 if (S <> '') and (nS <> '') then S := S + ', ';
 S := S + nS;
end;

procedure AddS(msgIndex : Longint);
begin
 AddStr(OutputResource(msgIndex));
end;

function txtOS(OS : Byte) : string;
begin
 if OS = 1
  then txtOS := 'OS/2'
  else txtOS := 'ID = ' + long2str(OS);
end;

procedure Separator(S : string);
begin
 SetColor(atInfo);
 Write(OutputCP437('√'));
 SetColor(atSeparator);
 Write(S + OutputCP437(Strg('ƒ', 59 - OutputWidth(S)))); NL;
 SetColor(atInfo);
end;

procedure ShowNamesTable(NT : pNamedEntryCollection);
var
 i : Integer;
begin
 if NT^.Count = 0
  then begin Separator(''); Write(OutputResource(msgEmpty)); NL; end
  else Separator(OutputResource(msgNameTableHdr));
 For i := 1 to NT^.Count do
  with pNameTblRec(NT^.At(pred(I)))^ do
   begin
    if i < NT^.Count then Write(OutputCP437('≥')) else Write(OutputCP437('√'));
    Write(' ', Sstr(Ord, 5, '0'), ' ');
    if i < NT^.Count then Write(OutputCP437('≥')) else Write(OutputCP437('¡'));
    Write(' ', OutputCP437(Name^)); NL;
   end;
end;

procedure ShowImportTable(SC : pStringCollection);
var
 i,j : Integer;
 pS  : pString;
begin
 if SC^.Count = 0
  then begin Separator(''); Write(OutputResource(msgEmpty)); NL; end
  else Separator(OutputResource(msgImpTableHdr));
 j := 0;
 for i := 1 to SC^.Count do
  begin
   pS := SC^.At(pred(I));
   if i < SC^.Count then Write(OutputCP437('≥')) else Write(OutputCP437('√'));
   Write(' ', Sstr(i, 5, '0'), ' ');
   if i < SC^.Count then Write(OutputCP437('≥')) else Write(OutputCP437('¡'));
   Write(' ', Sstr(j, 5, '0'), ' ');
   if i < SC^.Count then Write(OutputCP437('≥')) else Write(OutputCP437('¡'));
   if pS <> nil
    then begin
          Write(' ', OutputCP437(pS^));
          Inc(j, succ(length(pS^)));
         end
    else Inc(j);
   NL;
  end;
end;

function EntryName(ProcOrd : Longint) : String;
var
 pN : pNameTblRec;
 tS : string;
 I  : Integer;
 MD : pModuleDef;
begin
 EntryName := '';
 pN := ResNameTbl^.At(0);
 if (pN = nil) or (pN^.Name = nil) then exit;
 tmpS := upStrg(pN^.Name^);
 I := ModDef^.IndexOf(@tmpS);
 if I >= 0
  then begin
        MD := ModDef^.At(I);
        if ProcOrd < MD^.defLength
         then begin
               tmpS := OutputResource(MD^.defStart + ProcOrd);
               if tmpS = '' then exit;
              end
         else exit;
       end
  else exit;
 EntryName := '(' + tmpS + ')';
end;

procedure AddF(F : Byte);
begin
 if F and lxExport <> 0
  then AddS(msgExported);
 if F and lxShared <> 0
  then AddS(msgSharedData);
 if F and lxParams <> 0
  then AddStr(FormatStr(msgParamCount, [(F and lxParams) shr lxParamsShft]));
end;

function ImpByOrd(ModIndx, ProcOrd : Longint) : pString;
var
 tS : string;
 I  : Integer;
 MD : pModuleDef;
begin
 tmpS := upStrg(pString(ImpModTbl^.At(pred(ModIndx)))^);
 tS := '';
 I := ModDef^.IndexOf(@tmpS);
 if I >= 0
  then begin
        MD := ModDef^.At(I);
        if ProcOrd < MD^.defLength
         then tS := OutputResource(MD^.defStart + ProcOrd);
       end;
 tmpS := OutputCP437(tmpS) + '.' + long2str(ProcOrd);
 if tS <> '' then tmpS := tmpS + '(' + tS + ')';
 ImpByOrd := @tmpS;
end;

function ImpByName(ModIndx, ProcOfs : Longint) : pString;
var
 i,j : Integer;
 pS  : pString;
begin
 j := 0;
 pS := nil;
 For i := 1 to ImpProcTbl^.Count do
  begin
   pS := ImpProcTbl^.At(pred(i));
   if ProcOfs = j then break;
   if pS <> nil then Inc(j, succ(length(pS^))) else Inc(j);
   pS := nil;
  end;
 tmpS := OutputCP437(pString(ImpModTbl^.At(pred(ModIndx)))^);
 if pS <> nil
  then tmpS := tmpS + '.' + OutputCP437(pS^)
  else tmpS := tmpS + FormatStr(msgProcOffs, [ProcOfs]);
 ImpByName := @tmpS;
end;

function relOfs(O : Longint) : Longint;
begin
 if O <> 0 then Inc(O, stubSize);
 relOfs := O;
end;

begin
 SetColor(atInfo);
 S := '';
 case Header.lxMFlags and lxModType of
  lxEXE   : begin
             case Header.lxMFlags and lxAppMask of
              lxNoPMwin : AddS(msgFullScreen);
              lxPMwin   : AddS(msgWindowed);
              lxPMapi   : AddS(msgPMapplication);
              else AddS(msgUnknownType);
             end;
             S := S + ' ' + OutputResource(msgApplication);
            end;
  lxDLL,
  lxPMDLL,
  lxPDD,
  lxVDD   : begin
             case Header.lxMFlags and lxModType of
              lxDLL   : AddS(msgDLL);
              lxPMDLL : AddS(msgProtDLL);
              lxPDD   : AddS(msgPDD);
              lxVDD   : AddS(msgVDD);
             end;
             if Header.lxMFlags and lxLibInit <> 0
              then AddS(msgPerProcInit);
             if Header.lxMFlags and lxLibTerm <> 0
              then AddS(msgPerProcTerm);
            end;
  else AddS(msgUnknownModType);
 end;
 if Header.lxMFlags and lxNoIntFix <> 0
  then AddS(msgNoIntFixups);
 if Header.lxMFlags and lxNoExtFix <> 0
  then AddS(msgNoExtFixups);
 if Header.lxMFlags and lxNoLoad <> 0
  then AddS(msgNotLoadable);
 if opt.Verbose and vfHeaderL0 <> 0
  then begin
        Write(FormatStr(msgModuleType, [S])); NL;
        S := OutputResource(msgCPU + Header.lxCpu - lxCPU286);
        Write(FormatStr(msgReqCPU, [S, Header.lxVer shr 16, SmallWord(Header.lxVer)])); NL;
       end;
 if opt.Verbose and vfHeaderL1 <> 0
  then begin
        S := txtOS(Header.lxOS);
        Write(FormatStr(msgReqOS, [S, Header.lxMPages])); NL;
       end;
 if opt.Verbose and vfHeaderL0 <> 0
  then begin
        Write(FormatStr(msgPageSize, [Header.lxPageSize, Header.lxPageShift])); NL;
        Write(FormatStr(msgObjects, [Header.lxObjCnt, Header.lxRsrcCnt])); NL;
       end;
 if opt.Verbose and vfHeaderL3 <> 0
  then begin
        Write(FormatStr(msgObjTableOfs, [relOfs(Header.lxObjTabOfs), relOfs(Header.lxRsrcTabOfs)])); NL;
        Write(FormatStr(msgMapTableOfs, [relOfs(Header.lxObjMapOfs), relOfs(Header.lxDirTabOfs)])); NL;
        Write(FormatStr(msgNResTableOfs,[Header.lxNResTabOfs, Header.lxNResTabSize])); NL;
        Write(FormatStr(msgImpProcOfs,  [relOfs(Header.lxImpProcOfs), relOfs(Header.lxEntTabOfs)])); NL;
       end;
 if opt.Verbose and vfHeaderL2 <> 0
  then begin
        Write(FormatStr(msgPageDataOfs,  [Header.lxDataPageOfs, Header.lxIterMapOfs])); NL;
        Write(FormatStr(msgPageFixOfs,  [relOfs(Header.lxFPageTabOfs), relOfs(Header.lxFRecTabOfs)])); NL;
       end;
 if opt.Verbose and vfHeaderL1 <> 0
  then begin
        Write(FormatStr(msgFixupSize,  [Header.lxFixupSize, Header.lxFixupSum])); NL;
        Write(FormatStr(msgResidentSize,  [Header.lxLdrSize, Header.lxLdrSum])); NL;
       end;
 if opt.Verbose and vfHeaderL2 <> 0
  then begin
        Write(FormatStr(msgImpTableOfs,  [relOfs(Header.lxImpModOfs), Header.lxDebugInfoOfs])); NL;
       end;
 if opt.Verbose and vfHeaderL0 <> 0
  then begin
        Write(FormatStr(msgImpEntries,  [Header.lxImpModCnt, Header.lxDebugLen])); NL;
        Write(FormatStr(msgStartEIP,  [Header.lxStartObj, Header.lxEIP, Header.lxStackObj, Header.lxESP])); NL;
       end;
 if opt.Verbose and vfHeaderL1 <> 0
  then begin
        Write(FormatStr(msgAutoData,  [Header.lxAutoData, Header.lxPreload])); NL;
        Write(FormatStr(msgStackSize, [Header.lxStackSize, Header.lxHeapSize])); NL;
       end;
 if opt.Verbose and vfHeaderL0 <> 0
  then begin
        For i := 1 to ResNameTbl^.Count do
         with pNameTblRec(ResNameTbl^.At(pred(I)))^ do
          if Ord = 0
           then begin
                 if Name <> nil then tmpS := OutputCP437(Name^) else tmpS := '';
                 Write(FormatStr(msgModuleName, [tmpS])); NL; break;
                end;
        For i := 1 to NResNameTbl^.Count do
         with pNameTblRec(NResNameTbl^.At(pred(I)))^ do
          if Ord = 0
           then begin
                 if Name <> nil then tmpS := OutputCP437(Name^) else tmpS := '';
                 Write(FormatStr(msgDescription, [tmpS])); NL; break;
                end;
       end;
 if opt.Verbose and vfObjects <> 0
  then begin
        Separator('');
        Write(OutputResource(msgObjectTable)); NL;
        Separator('');
        For I := 1 to Header.lxObjCnt do
         with ObjTable^[I] do
          begin
           SetColor(atInfo);
           if (I = 1) or (opt.Verbose and vfPageMap = vfPageMap)
            then begin
                  Write(OutputResource(msgObjTableHdr));
                  NL;
                 end;
           Write(OutputCP437('≥'), I:3, ' ', Hex8(oBase), ' ', Hex8(oSize), ' ');
           SetColor(atFlags);
           For J := 0 to 14 do
            begin
             if J > 2 then Write(' ');
             if (oFlags and (1 shl (J + byte(J > 10))) <> 0)
              then Write(OutputCP437('˚ ')) else Write('  ');
             if J > 2 then Write(' ');
            end;
           NL;
           if opt.Verbose and vfPageMap = vfPageMap
            then begin
                  if oMapSize > 0
                   then begin
                         SetColor(atInfo);
                         Write(OutputCP437('≥  '));
                         SetColor(atHLinfo);
                         Write(OutputResource(msgPageTableHdr)); NL;
                        end;
                  For J := 1 to oMapSize do
                   with ObjMap^[pred(oPageMap + J)] do
                    begin
                     SetColor(atInfo);
                     Write(OutputCP437('≥   '));
                     SetColor(atHLinfo);
                     Write(     OutputChar(txtGfx[J = oMapSize][1]), ' ', Sstr(pred(oPageMap + J), 8, '0'),
                           ' ', OutputChar(txtGfx[J = oMapSize][2]), ' ');
                     case PageFlags of
                      pgIterData,
                      pgIterData2,
                      pgIterData3:
                       Write(Hex8(Header.lxIterMapOfs + PageDataOffset shl Header.lxPageShift));
                      pgValid:
                       Write(Hex8(Header.lxDataPageOfs + PageDataOffset shl Header.lxPageShift));
                      else Write('--------');
                     end;
                     Write(' ', OutputChar(txtGfx[J = oMapSize][2]), ' ', Hex4(PageSize),
                           ' ', OutputChar(txtGfx[J = oMapSize][2]), ' ');
                     if PageFlags <= pgIterData2
                      then Write(OutputResource(msgPageFlags+PageFlags)) else
                     if PageFlags = pgIterData3
                      then Write(OutputResource(msgPageM3))
                      else Write(OutputResource(msgPageFlags+succ(pgIterData2)));
                     Write(' ', OutputChar(txtGfx[J = oMapSize][3]));
                     NL;
                    end;
                 end;
          end;
       end;
 if (opt.Verbose and vfResName <> 0)
  then begin
        Separator('');
        Write(OutputResource(msgResTableHdr)); NL;
        ShowNamesTable(ResNameTbl);
      end;
 if (opt.Verbose and vfNResName <> 0)
  then begin
        Separator('');
        Write(OutputResource(msgNResTableHdr)); NL;
        ShowNamesTable(NResNameTbl);
      end;
 if (opt.Verbose and vfImpName <> 0)
  then begin
        Separator('');
        Write(OutputResource(msgImportTable)); NL;
        ShowImportTable(ImpModTbl);
       end;
 if (opt.Verbose and vfImpProc <> 0)
  then begin
        Separator('');
        Write(OutputResource(msgImpProcHdr)); NL;
        ShowImportTable(ImpProcTbl);
       end;
 if (opt.Verbose and vfEntTable <> 0)
  then begin
        Separator('');
        Write(OutputResource(msgEntryTable)); NL;
        if EntryTbl^.Count = 0
         then begin Separator(''); Write(OutputResource(msgEmpty)); NL; end
         else Separator(OutputResource(msgEntryTblHdr));
        For i := 1 to EntryTbl^.Count do
         with pEntryPoint(EntryTbl^.At(pred(I)))^ do
          begin
           if BndType = btEmpty then Continue;
           Write(OutputChar(txtGfx[i = EntryTbl^.Count][4]), ' ',
                 Sstr(Ordinal, 5, '0'), ' ', OutputChar(txtGfx[i = EntryTbl^.Count][5]), ' ');
           if BndType <= btEntryFwd
            then Write(OutputResource(msgEntryPoints + BndType))
            else Write(OutputResource(msgEntryPoints + succ(btEntryFwd)));
           S := ' ' + OutputChar(txtGfx[i = EntryTbl^.Count][5]);
           Write(S);
           case BndType of
            btEntry16:
             begin
              S := long2str(Obj) + ':' + Hex4(Entry.e16Ofs);
              AddF(Entry.e16Flags);
             end;
            btGate16:
             begin
              S := long2str(Obj) + ':' + Hex4(Entry.eGate16Ofs);
              AddF(Entry.eGate16Flags);
             end;
            btEntry32:
             begin
              S := long2str(Obj) + ':' + Hex8(Entry.e32Ofs);
              AddF(Entry.e32Flags);
             end;
            btEntryFwd:
             begin
              S := '-> ';
              if Entry.eForwFlags and fwd_Ordinal <> 0
               then S := S + ImpByOrd(Entry.eForwModOrd, Entry.eForwOfs)^
               else S := S + ImpByName(Entry.eForwModOrd, Entry.eForwOfs)^;
             end;
            else S := '';
           end;
           AddStr(EntryName(Ordinal));
           Write(' ', S); NL;
          end;
       end;
 if (opt.Verbose and vfFixups <> 0)
  then begin
        Separator('');
        Write(OutputResource(msgRelocTable)); NL;
        Separator('');
        New(Fixups, Create(16, 16));
        For I := 1 to Header.lxObjCnt do
         with ObjTable^[I] do
          For J := 1 to oMapSize do
           begin
            Write(OutputCP437('√ '));
            SetColor(atHLinfo);
            Write(FormatStr(msgRelocTblHdr, [I, J, pred(oPageMap + J), 
              oBase + lx386PageSize * (J - 1)])); NL;
            SetColor(atInfo);

            oldPageMap := ObjMap^[pred(oPageMap + J)];
            GetMem(oldPage, oldPageMap.PageSize);
            Move(Pages^[oPageMap + J - 2]^, oldPage^, oldPageMap.PageSize);
            Fixups^.FreeAll;
            K := byte(GetFixups(pred(oPageMap + J), Fixups));

            FreeMem(Pages^[oPageMap + J - 2], ObjMap^[pred(oPageMap + J)].PageSize);
            ObjMap^[pred(oPageMap + J)] := oldPageMap;
            Pages^[oPageMap + J - 2] := oldPage;

            if K = 0 then Continue;

            For K := 1 to Fixups^.Count do
             with pLXreloc(Fixups^.At(pred(K)))^ do
              begin
               case sType and nrSType of
                nrSByte:  S := OutputResource(msgFixByte);
                nrSSeg:   S := OutputResource(msgFixSelector);
                nrSPtr:   S := OutputResource(msgFixPtr16);
                nrSOff:   S := OutputResource(msgFixOfs16);
                nrPtr48:  S := OutputResource(msgFixPtr48);
                nrOff32:  S := OutputResource(msgFixOfs32);
                nrSoff32: S := OutputResource(msgFixRelOfs32);
               end;
               S := S + OutputResource(msgFixOf);
               case Flags and nrRtype of
                nrRint: begin
                         S := S + FormatStr(msgFixObject, [ObjMod]);
                         if sType and nrSType <> nrSSeg
                          then S := S + FormatStr(msgFixOffset, [Target.intRef]);
                        end;
                nrRord: S := S + FormatStr(msgFixImport, [ImpByOrd(ObjMod, Target.extRef.Ord)]);
                nrRnam: S := S + FormatStr(msgFixImport, [ImpByName(ObjMod, Target.extRef.Ord)]);
                nrRent: S := S + FormatStr(msgFixModEntry, [ObjMod]);
               end;
               Write(OutputCP437('≥ '));
               if (sType and nrChain <> 0)
                then begin
                      L := targetCount;
                      pFixOfs := @targets^;
                     end
                else begin
                      L := 1;
                      pFixOfs := @sOffs;
                     end;
               SetColor(atFixups);
               Write(S); NL;
               SetColor(atInfo);
               M := -1;
               While L > 0 do
                begin
                 if (M >= lo(WindMax) - 5) or (M = -1)
                  then begin
                        if M <> -1 then NL;
                        M := 0; Write(OutputCP437('≥ '))
                       end;
                 SetColor(atFixupOfs);
                 Write(Hex4(pFixOfs^), ' ');
                 SetColor(atInfo);
                 Inc(pFixOfs); Dec(L);
                 Inc(M, 5);
                end;
               if M > 0 then NL;
              end;
           end;
        Dispose(Fixups, Destroy);
       end;
 SetColor(atDefault);
end;

{$I-}
procedure tMyLX.WritePagesToFile(StartP,EndP:Longint;var FileName:string;PageUnpFlags:LongInt);
var FF   :File;
    ii,jj:Longint;
    st   :string;
    rs   :string;
    Fst  :boolean;
    pdata:pointer;
    psize:Longint;
    zbuf :array [0..255] of char;
begin
  assign(FF,FileName);
  rewrite(FF,1);
  if ioresult<>0 then Stop(msgCantWriteBin, FileName);
  fillchar(zbuf,sizeof(zbuf),#0);
  Fst:=true;

  For ii := 1 to Header.lxObjCnt do
    with ObjTable^[ii] do
    begin
      For jj := 0 to oMapSize - 1 do
      if oPageMap + jj = StartP then
      begin
        if Fst then NL; Fst:=false;

        with ObjMap^[StartP] do
        begin
          if (PageUnpFlags and 2<>0) and (PageFlags in [pgIterData, pgIterData2, pgIterData3]) then
          begin
            pdata:=UnpackPageNoTouch(StartP,psize); Fst:=true;
            rs:=OutputResource(msgPageFlags+pgValid)
          end else
          begin
            pdata:=Pages^[StartP-1]; Fst:=false;
            psize:=PageSize;
            if PageFlags <= pgIterData2 then rs:=OutputResource(msgPageFlags+PageFlags) else
            if PageFlags = pgIterData3 then rs:=OutputResource(msgPageM3) else
               rs:=OutputResource(msgPageFlags+succ(pgIterData2));
          end;
        end;
        SetColor($0A);
        st:=FormatStr(msgWritingPage, [Sstr(StartP, 5, '0'), rs, Sstr(psize, 4, '0'),Hex8(filepos(FF))]);
        Write(st); NL;

        with ObjMap^[StartP] do
        begin
           case PageFlags of
             pgIterData,
             pgIterData2,
             pgIterData3,
             pgValid:begin
               if psize<>0 then blockwrite(FF,pdata^,psize);
               if PageUnpFlags and 4<>0 then
               begin
                 if psize=0 then psize:=Header.lxPageSize else
                 begin
                   psize:=filepos(FF);
                   psize:=(psize+Header.lxPageSize-1) div Header.lxPageSize * Header.lxPageSize - psize;
                 end;
                 while psize>=256 do
                 begin
                   blockwrite(FF,zbuf,256);
                   dec(psize,256);
                 end;
                 if psize>0 then blockwrite(FF,zbuf,psize);
               end;
             end;
           end;
        end;
        if Fst then FreeMem(pdata, Header.lxPageSize);
        inc(StartP);
        Fst:=false;
        if StartP>EndP then break;
      end;
      if StartP>EndP then break;
    end;
  close(FF);
end;

procedure tMyLX.ReadPagesFromFile(StartP,EndP:Longint;var FileName:string;ReadPack:LongInt);
var FF   :File;
    ii,jj:Longint;
    st   :string;
    rs   :string;
    Fst  :boolean;
    pdata:pchar;
    psize:Longint;
    pl   :Longint;
    pd   :pchar;
    svmode:Longint;
begin
  svmode  :=FileMode;
  FileMode:=0;
  assign(FF,FileName);
  reset(FF,1);
  if ioresult<>0 then Stop(msgCantReadBin, FileName);
  FileMode:=svmode;

  psize:=FileSize(FF);
  pdata:=nil;
  if psize<>0 then
  begin
    GetMem(pdata,psize);
    blockread(FF,pdata^,psize);
  end;
  pl:=psize;
  pd:=pdata;
  close(FF);

  Fst:=true;

  For ii := 1 to Header.lxObjCnt do
    with ObjTable^[ii] do
    begin
      For jj := 0 to oMapSize - 1 do
      if oPageMap + jj = StartP then
      begin
        if Fst then NL; Fst:=false;

        with ObjMap^[StartP] do
        begin
          if Pages^[StartP-1]<>nil then FreeMem(Pages^[StartP-1],PageSize);
          if ReadPack<>0 then PageFlags:=ReadPack else PageFlags:=pgValid;
          if pl>=Header.lxPageSize then PageSize:=Header.lxPageSize else
            PageSize:=pl;
          dec(pl,PageSize);
          if PageSize>0 then
          begin
            GetMem(Pages^[StartP-1],PageSize);
            Move(pd^,Pages^[StartP-1]^,PageSize);
            inc(pd,PageSize);
          end else Pages^[StartP-1]:=nil;

          if PageFlags <= pgIterData2 then rs:=OutputResource(msgPageFlags+PageFlags) else
          if PageFlags = pgIterData3 then rs:=OutputResource(msgPageM3) else
             rs:=OutputResource(msgPageFlags+succ(pgIterData2));
          st:=FormatStr(msgReadingPage, [Sstr(StartP, 5, '0'), rs, Sstr(PageSize, 4, '0')]);
        end;
        SetColor($0A);
        Write(st); NL;

        inc(StartP);
        if StartP>EndP then break;
      end;
      if StartP>EndP then break;
    end;
  FreeMem(pdata,psize);
end;

Procedure ShowConfig;
const
 ONOFF : array[boolean] of string[3] = ('OFF', 'ON');
var
 S   : string;
 I,J : Word;

function VerbLvl : pString;
begin
 if opt.Verbose = 0
  then S := ONOFF[FALSE]
  else S := '';
 if opt.Verbose and vfHeaderL0 <> 0
  then S := S + '0';
 if opt.Verbose and vfHeaderL1 <> 0
  then S := S + '1';
 if opt.Verbose and vfHeaderL2 <> 0
  then S := S + '2';
 if opt.Verbose and vfHeaderL3 <> 0
  then S := S + '3';
 if opt.Verbose and vfObjects <> 0
  then S := S + 'O';
 if (opt.Verbose and vfPageMap) = vfPageMap
  then S := S + 'C';
 if opt.Verbose and vfResName <> 0
  then S := S + 'R';
 if opt.Verbose and vfNResName <> 0
  then S := S + 'N';
 if opt.Verbose and vfImpName <> 0
  then S := S + 'M';
 if opt.Verbose and vfImpProc <> 0
  then S := S + 'P';
 if opt.Verbose and vfEntTable <> 0
  then S := S + 'E';
 if opt.Verbose and vfFixups <> 0
  then S := S + 'F';
 if opt.Verbose and vfExtra <> 0
  then S := S + 'X';
 if opt.Verbose and vfDebug <> 0
  then S := S + 'D';
 VerbLvl := @S;
end;

function BackupLvl : pString;
begin
 if opt.Backup and bkfAlways = bkfAlways
  then BackupLvl := @ONOFF[TRUE]
  else begin
        if (opt.Backup and bkfAlways) and (not (bkfIfDebug+bkfIfXtra+bkfIfNE)) <> 0
         then S := 'A'
         else begin
               S := '';
               if opt.Backup and bkfIfDebug <> 0
                then S := S + 'D';
               if opt.Backup and bkfIfXtra <> 0
                then S := S + 'X';
               if opt.Backup and bkfIfNE <> 0
                then S := S + 'N';
              end;
        if S = ''
         then BackupLvl := @ONOFF[FALSE]
         else BackupLvl := @S;
       end;
end;

begin
 SetColor($0B);
 Write(OutputResource(msgConfigHeader)); NL;
 SetColor($03);
 if opt.UnicodeOutput then S := OutputResource(msgUTF8)
                      else S := OutputResource(msgTraditional);
 Write(FormatStr(msgOutputMode, [S])); NL;
 Write(FormatStr(msgShowInfo, [VerbLvl])); NL;
 Write(FormatStr(msgForceIdle, [ONOFF[opt.ForceIdle]])); NL;
 Write(FormatStr(msgUnpack, [ONOFF[opt.Unpack]])); NL;
 Write(FormatStr(msgBackup, [BackupLvl])); NL;
 Write(FormatStr(msgPause, [ONOFF[opt.Pause]])); NL;
 if opt.tresholdStub > 0
  then begin
        if opt.stubName <> ''
         then S := opt.stubName
         else S := OutputResource(msgRemoveStub);
        Write(FormatStr(msgReplaceStub, [S])); NL;
       end;
 case opt.SaveMode and svfAlignFirstObj of
  svfFOalnNone   : I := msgAlignFONone;
  svfFOalnShift  : I := msgAlignFOShift;
  svfFOalnSector : I := msgAlignFOSect;
  else I := msgUnknownType;
 end;
 S := OutputResource(I);
 Write(FormatStr(msgAlignFO, [S])); NL;

 case opt.SaveMode and svfAlignEachObj of
  svfEOalnShift  : I := msgAlignObjShift;
  svfEOalnSector : I := msgAlignObjSect;
  else I := msgUnknownType;
 end;
 S := OutputResource(I);
 Write(FormatStr(msgAlignObj, [S])); NL;

 if opt.Realign = NoRealign
  then S := OutputResource(msgDontChange)
  else S := long2str(1 shl opt.Realign);
 Write(FormatStr(msgSetPageShift, [S])); NL;
 if not opt.doUnpack
  then begin
        if opt.PackMode and pkfRunLength = 0
         then I := msgRLoff
         else case opt.PackMode and pkfRunLengthLvl of
               pkfRunLengthMin : I := msgRLmin;
               pkfRunLengthMid : I := msgRLmed;
               pkfRunLengthMax : I := msgRLmax;
               else I := msgUnknownType;
              end;
        if opt.PackMode and pkfFixups = 0
         then J := msgFXoff
         else case opt.PackMode and pkfFixupsLvl of
               pkfFixupsVer2 : J := msgFXv2;
               pkfFixupsVer4 : J := msgFXv4;
               pkfFixupsMax  : J := msgFXmax;
               else J := msgUnknownType;
              end;
        Write(FormatStr(msgRunLength, [OutputResource(I)])); NL;
        if opt.PackMode and pkfLempelOptimal <> 0
         then S := OutputResource(msgLZoptimal)
         else S := ONOFF[opt.PackMode and pkfLempelZiv <> 0];
        Write(FormatStr(msgLempelZiv, [S])); NL;
        Write(FormatStr(msgSixPack, [ONOFF[opt.PackMode and pkfSixPack <> 0]])); NL;
        Write(FormatStr(msgFixupsPack, [OutputResource(J)])); NL;
       end;
 S := '';
 For I := 1 to exclude^.matchStrings^.Count do
  begin
   if S <> '' then S := S + ':';
   S := S + strPas(pChar(exclude^.matchStrings^.At(pred(I))));
  end;
 if S <> ''
  then Writeln(FormatStr(msgExcludedFiles, [S]));
end;

function tMyCmdLineParser.ParmHandler;
const
 optSep : string[4] = #9' /-';
var
 I,J,K : Longint;
 S     : string;
 logPath : string;

Function isEnabled : boolean;
begin
 isEnabled := TRUE;
 if length(parmStr) < 2 then exit;
 case parmStr[2] of
  '+','-' : parmHandler := 2;
  ' ','/' : exit;
  else Stop(2, parmStr);
 end;
 if parmStr[2] = '-' then isEnabled := FALSE;
end;

function ColonGetWord(Start : Word; var S : string) : Word;
begin
 ColonGetWord := GetWord(ParmStr, Start, S);
 if (S <> '') and (S[1] <> ':')
  then Stop(2, parmStr);
 Delete(S, 1, 1); { drop : }
end;

function ColonGetRange(Start : Word; var StartVal,EndVal:longint) : Word;
var ii,jj:longint;
    st:string;
begin
 ColonGetRange:=length(ParmStr)-Start;
 st:=copy(ParmStr,Start+1,length(ParmStr)-Start-1);
 if st[1] <> ':' then Stop(2, ParmStr);
 delete(st,1,1);
 val(st,StartVal,ii);
 if ii<>0 then
 begin
   val(copy(st,1,ii-1),StartVal,jj);
   if jj<>0 then Stop(2, ParmStr);
   if st[ii]='-' then
   begin
     jj:=ii;
     delete(st,1,ii);
     val(st,EndVal,ii);
     if ii<>0 then
     begin
       ColonGetRange:=jj+ii;
       val(copy(st,1,ii-1),EndVal,jj);
       if jj<>0 then Stop(2, ParmStr);
     end;
   end else ColonGetRange:=ii;
 end;
end;

procedure SetNewPageShift(StartChar : Word);
begin
 S := Copy(ParmStr, StartChar, 255);
 J := length(S); I := DecVal(S);
 if I <> 0
  then begin
   opt.Realign := BitSR(I);
   if opt.Realign > 12 then Stop(2, parmStr);
  end
  else opt.Realign := NoRealign;
 parmHandler := pred(StartChar + J - length(S));
end;

{ 2011-11-16 SHL add }
procedure SetPageToEnlarge(StartChar : Word);
begin
 S := Copy(ParmStr, StartChar, 255);
 J := length(S);
 I := DecVal(S);
 if I > 0 then
   opt.pageToEnlarge := I
 else
   Stop(2, parmStr);
 parmHandler := pred(StartChar + J - length(S));
end;

procedure SetRC(parmLen : Word);
begin
 parmHandler := parmLen;
 if (length(parmStr) > parmLen) and (First(parmStr[succ(parmLen)], OptSep) = 0)
  then Stop(2, parmStr);
end;

procedure SetForceOut(Mask, Flag : Longint; var fileMask : string);
begin
 Mask := Mask or Flag;
 if J and Mask = 0
  then begin
        fileMask := '';
        opt.ForceOut := opt.ForceOut and (not Flag);
       end
  else
 if J and Mask = Mask
  then begin
        fileMask := S; S := '';
        if fileMask = ''
         then Stop(2, parmStr);
        if J and fofAlways <> 0
         then opt.ForceOut := opt.ForceOut or Flag
         else opt.ForceOut := opt.ForceOut and (not Flag);
       end;
end;

procedure SetTreshold(var Treshold : longint);
begin
 Delete(ParmStr, 1, 2);
 if ParmStr[1] <> ':'
  then begin Treshold := $7FFFFFFF; exit; end;
 Delete(ParmStr, 1, 1);
 if (ParmStr <> '') and (ParmStr[1] in ['0'..'9'])
  then Treshold := DecVal(ParmStr)
  else Treshold := $7FFFFFFF;
end;

begin
 parmHandler := 1;
 case upCase(ParmStr[1]) of
  'A' : if length(ParmStr) > 1
         then begin
               case upCase(ParmStr[2]) of
                'N' : opt.SaveMode := (opt.SaveMode and (not svfAlignFirstObj)) or svfFOalnNone;
                'P' : opt.SaveMode := (opt.SaveMode and (not svfAlignFirstObj)) or svfFOalnShift;
                'S' : opt.SaveMode := (opt.SaveMode and (not svfAlignFirstObj)) or svfFOalnSector;
                ':' : begin SetNewPageShift(3); exit; end;
                else Stop(2, parmStr);
               end;
               parmHandler := 2;
               if length(ParmStr) > 2
                then begin
                      case upCase(ParmStr[3]) of
                       'P' : opt.SaveMode := (opt.SaveMode and (not svfAlignEachObj)) or svfEOalnShift;
                       'S' : opt.SaveMode := (opt.SaveMode and (not svfAlignEachObj)) or svfEOalnSector;
                       ':' : begin SetNewPageShift(4); exit; end;
                       else exit;
                      end;
                      parmHandler := 3;
                      if (length(ParmStr) > 3) and (ParmStr[4] = ':')
                       then begin
                             SetNewPageShift(5);
                             exit;
                            end;
                     end;
              end;
  'B' : begin
         I := 1 + GetOpt(parmStr, 2, 'DXN', [bkfIfDebug, bkfIfXtra, bkfIfNE, bkfAlways], opt.Backup);
         if I < length(parmStr)
          then if ParmStr[succ(I)] = ':'
                then parmHandler := I + ColonGetWord(succ(I), opt.backupDir)
                else SetRC(I)
          else parmHandler := I;
         if opt.backupDir <> ''
          then if not (opt.backupDir[length(opt.backupDir)] in ['/','\'])
                then opt.backupDir := opt.backupDir + nativeDirDelim;
        end;
  'C' : case UpCase(parmStr[2]) of
         ':' : begin
                parmHandler := 1 + ColonGetWord(2, S);
                if S <> ''
                 then setConfig(S)
                 else Stop(2, parmStr);
               end;
         'S' : begin
                Delete(parmStr, 1, 1);
                opt.UseStdOut := isEnabled;
                ApplyOutputMode;
               end;
         else opt.ColoredOutput := isEnabled;
        end;
  'D' : opt.DiscardXOpts := isEnabled;
  'E' : begin
         parmHandler := 1 + ColonGetWord(2, S);
         if S = ''
          then exclude^.matchStrings^.FreeAll
          else exclude^.AddMask(S);
        end;
  'F' : opt.ForceRepack := isEnabled;
  'G' : if length(ParmStr) >= 2
         then begin
               case UpCase(ParmStr[2]) of
                'T' : opt.UnicodeOutput := FALSE;
                'U' : opt.UnicodeOutput := TRUE;
                else Stop(2, ParmStr);
               end;
               SetRC(2);
               ApplyOutputMode;
              end
         else Stop(2, ParmStr);
  '?',
  'H' : Stop(1, '');
  'I' : opt.ForceIdle := isEnabled;
  'J' : if length(ParmStr) > 1
         then begin
               case upCase(ParmStr[2]) of
                'A' : opt.NewType := -1;
                'E' : opt.NewType := lxEXE;
                'L' : opt.NewType := lxDLL;
                'P' : opt.NewType := lxPDD;
                'V' : opt.NewType := lxVDD;
                else Stop(2, ParmStr);
               end;
               SetRC(2 + GetOpt(parmStr, 3, 'ELPVNX', [ntfExecutable, ntfLibrary, ntfPhysDriver,
                ntfVirtDriver, ntfNEmodule, ntfLXmodule, ntfAlways], opt.NewTypeCond));
               if opt.NewType = -1 then opt.NewTypeCond := 0;
              end
         else Stop(2, parmStr);
  'L' : begin
         I := 1 + GetOpt(parmStr, 2, 'SUA', [lcfSucc, lcfUnsucc, lcfAlways], opt.Log);
         if I < length(parmStr)
          then if ParmStr[succ(I)] = ':'
                then parmHandler := I + ColonGetWord(succ(I), opt.logFileName)
                else SetRC(I)
          else parmHandler := I;
         if (opt.Log <> 0) and (opt.logFileName = '')
          then begin
            logPath := GetEnv('LOGFILES');
            if logPath = '' then logPath := sourcePath;
            if not (logPath[length(logPath)] in ['/', '\']) then logPath := logPath + nativeDirDelim;
            opt.logFileName := logPath + logFname;
          end;
        end;
  'M' : if length(ParmStr) > 1
         then case upCase(ParmStr[2]) of
               'R' : begin
                      parmHandler := 3;
                      opt.PackMode := opt.PackMode and not (pkfRunLength or pkfRunLengthLvl);
                      if length(ParmStr) > 2
                       then case upCase(ParmStr[3]) of
                             '1' : opt.PackMode := opt.PackMode or pkfRunLength or pkfRunLengthMin;
                             '2' : opt.PackMode := opt.PackMode or pkfRunLength or pkfRunLengthMid;
                             '3' : opt.PackMode := opt.PackMode or pkfRunLength or pkfRunLengthMax;
                             'N' : ;
                             else Stop(2, parmStr);
                            end
                       else Stop(2, parmStr);
                     end;
               'L' : begin
                      parmHandler := 3;
                      if length(ParmStr) > 2
                       then case upCase(ParmStr[3]) of
                             '1' : opt.PackMode := (opt.PackMode or pkfLempelZiv) and not pkfLempelOptimal;
                             '2' : opt.PackMode := opt.PackMode or pkfLempelZiv or pkfLempelOptimal;
                             'N' : opt.PackMode := opt.PackMode and not (pkfLempelZiv or pkfLempelOptimal);
                             '3' : opt.PackMode := (opt.PackMode and not (pkfLempelZiv or pkfLempelOptimal)) or pkfSixPack;
                             else Stop(2, parmStr);
                            end
                       else Stop(2, parmStr);
                     end;
               'F' : begin
                      ParmHandler := 3;
                      opt.PackMode := opt.PackMode ;
                      if length(ParmStr) > 2
                       then case upCase(ParmStr[3]) of
                             '1' : opt.PackMode := (opt.PackMode and (not pkfFixupsLvl)) or pkfFixups or pkfFixupsVer2;
                             '2' : opt.PackMode := (opt.PackMode and (not pkfFixupsLvl)) or pkfFixups or pkfFixupsVer4;
                             '3' : opt.PackMode := (opt.PackMode and (not pkfFixupsLvl)) or pkfFixups or pkfFixupsMax;
                             'N' : opt.PackMode := (opt.PackMode and (not (pkfFixups or pkfFixupsLvl)));
                             'A' : begin
                                    Delete(ParmStr, 1, 2);
                                    if ParmStr[2]=':' then
                                    begin
                                       opt.ApplyFixups := TRUE;
                                       ParmHandler := 1 + ColonGetWord(2, S);
                                       I := 0; J := 1;
                                       if S <> '' then val(S,I,J);
                                       if (S = '') or (J<>0) or (I<=0) or (I>7) then Stop(2, parmStr)
                                          else opt.ApplyMask := I;
                                    end else
                                       opt.ApplyFixups := isEnabled;
                                   end;
                             'B' : begin
                                    Delete(ParmStr, 1, 2);
                                    if ParmStr[2]=':' then
                                    begin
                                       opt.ForceApply := TRUE;
                                       ParmHandler := 1 + ColonGetWord(2, S);
                                       I := 0; J := 1;
                                       if S <> '' then val(S,I,J);
                                       if (S = '') or (J<>0) or (I<=0) or (I>7) then Stop(2, parmStr)
                                          else opt.ApplyMask := I;
                                    end else
                                       opt.ForceApply  := isEnabled;
                                    if opt.ForceApply then opt.ApplyFixups:=TRUE;
                                   end;
                             else Stop(2, parmStr);
                            end
                       else Stop(2, parmStr);
                     end;
               else Stop(2, parmStr);
              end
         else Stop(2, parmStr);
  'N' : SetRC(1 + GetOpt(parmStr, 2, 'BLRA', [lneIgnoreBound, lneIgnoreLngName, lneIgnoreRsrc, lneAlways], opt.NEloadMode));
  'O' : begin
         J := fofDebug + fofXtra + fofStub;
         I := 1 + GetOpt(parmStr, 2, 'DXSA', [fofDebug + $10, fofXtra + $20,
               fofStub + $40, fofAlways, fofAnything], J);
         parmHandler := I + ColonGetWord(succ(I), S);
         SetForceOut($10, fofDebug, opt.ddFileMask);
         SetForceOut($20, fofXtra,  opt.xdFileMask);
         SetForceOut($40, fofStub,  opt.sdFileMask);
         if S <> '' then Stop(2, parmStr);
        end;
  'P' : if length(ParmStr) > 1 then
        begin
          case upCase(ParmStr[2]) of
            'R':if length(ParmStr) > 2 then
               begin
                 if opt.PageRWStart<>-1 then Stop(2, parmStr);
                 J:=3;
                 case upCase(ParmStr[3]) of
                   '1' : opt.PageReadPack := pgIterData;
                   '2' : opt.PageReadPack := pgIterData2;
                   '3' : opt.PageReadPack := pgIterData3;
                   else J:=2;
                 end;
                 J:= J + ColonGetRange(J, opt.PageRWStart, opt.PageRWEnd);
                 J:= J + ColonGetWord(J + 1, opt.pageFileName);
                 if opt.PageRWEnd=-1 then opt.PageRWEnd:=opt.PageRWStart;
                 if (opt.PageReadPack<>0) and (opt.PageRWEnd<>opt.PageRWStart) then Stop(2, parmStr);
                 if (opt.PageRWEnd<opt.PageRWStart) or (opt.PageRWStart<=0) then Stop(2, parmStr);
                 if length(opt.pageFileName)=0 then Stop(2, parmStr);
                 parmHandler := J;
               end  else Stop(2, parmStr);
            'W':if length(ParmStr) > 2 then
               begin
                 if opt.PageRWStart<>-1 then Stop(2, parmStr);
                 J:=3;
                 opt.PageWriteOpt:= 1;
                 case upCase(ParmStr[3]) of
                   'U' : opt.PageWriteOpt := opt.PageWriteOpt or 2;
                   'A' : opt.PageWriteOpt := opt.PageWriteOpt or 6;
                   else J:=2;
                 end;
                 J:= J + ColonGetRange(J, opt.PageRWStart, opt.PageRWEnd);
                 J:= J + ColonGetWord(J + 1, opt.pageFileName);
                 if opt.PageRWEnd=-1 then opt.PageRWEnd:=opt.PageRWStart;
                 if (opt.PageRWEnd<opt.PageRWStart) or (opt.PageRWStart<=0) then Stop(2, parmStr);
                 if length(opt.pageFileName)=0 then Stop(2, parmStr);
                 parmHandler := J;
               end else Stop(2, parmStr);
            'Z':begin
                Delete(parmStr, 1, 1);
                opt.AllowZTrunc := isEnabled;
               end;
            else opt.Pause := isEnabled;
          end;
        end else
          opt.Pause := isEnabled;
  'Q' : opt.QueryCfgList := isEnabled;
  'R' : opt.RecurSearch := isEnabled;
  'S' : opt.ShowConfig := isEnabled;
  'T' : parmHandler := 1 + ColonGetWord(2, opt.stubName);
  'U' : opt.Unpack := isEnabled;
  'V' : SetRC(1 + GetOpt(parmStr, 2, '0123OCRNMPEFXD', [vfHeaderL0, vfHeaderL1,
         vfHeaderL2, vfHeaderL3, vfObjects, vfPageMap, vfResName, vfNResName,
         vfImpName, vfImpProc, vfEntTable, vfFixups, vfExtra, vfDebug, vfAnything], opt.Verbose));
  'W' : begin
         opt.FinalWrite := 0;
         SetRC(1 + GetOpt(parmStr, 2, 'SW', [fwfSimulate, fwfWrite, fwfAlways], opt.FinalWrite));
         if opt.FinalWrite and fwfWrite <> 0
          then opt.FinalWrite := fwfWrite;
        end;
  'X' : begin
         {2011-11-16 SHL support /X:pagenum}
         if (length(ParmStr) > 1) and (ParmStr[2] = ':') then begin
           SetPageToEnlarge(3);
           exit
         end
         else begin
           opt.doUnpack := isEnabled;
           if opt.doUnpack then setConfig('unpack')
         end
        end;
  'Y' : if (length(ParmStr) > 1) and (ParmStr[2] > ' ')
         then begin
               parmHandler := 2;
               For I := askFirst to askLast do {Enable all queries}
                with opt.AskStatus[I] do
                 if UpCase(ParmStr[2]) = ID
                  then begin
                        if (length(ParmStr) > 2) and (ParmStr[3] > ' ')
                         then begin
                               Reply := ParmStr[3];
                               parmHandler := 3;
                              end
                         else Reply := #0;
                        exit;
                       end;
               Stop(2, parmStr);
              end
         else For I := askFirst to askLast do {Enable all queries}
               opt.AskStatus[I].Reply := #0;
  'Z' : if length(ParmStr) > 1
         then case upCase(ParmStr[2]) of
               'D' : SetTreshold(opt.tresholdDbug);
               'S' : SetTreshold(opt.tresholdStub);
               'X' : SetTreshold(opt.tresholdXtra);
              end
         else Stop(2, parmStr);
  else Stop(2, parmStr);
 end;
end;

function tMyCmdLineParser.NameHandler;
var
 S : string;
begin
 NameHandler := GetWord(ParmStr, 1, S);
 if S <> '' then fNames^.AtInsert(fNames^.Count, NewStr(S));
end;

procedure tMyCmdLineParser.PreProcess;
begin
 if CmdLineStack = nil then New(CmdLineStack, Create(8, 8));
 CmdLineStack^.AtInsert(CmdLineStack^.Count, NewStr(ParmStr));
end;

procedure tMyCmdLineParser.PostProcess;
begin
 CmdLineStack^.AtFree(pred(CmdLineStack^.Count));
end;

destructor tMyCmdLineParser.Destroy;
begin
 if CmdLineStack <> nil
  then Dispose(CmdLineStack, Destroy);
 inherited Destroy;
end;

procedure LoadConfig;
label
 newID;
var
 T    : text;
 I    : Integer;
 Mode : Byte;
 iPos : pCollection;
 pSC  : pStringCollection;
 S    : string;
 cfgPath : string;
 unixroot: string;
 
begin
{$ifdef OS2}
 unixroot := GetEnv('UNIXROOT');
{$else}
 unixroot := '';
{$endif}
 if unixroot <> '' then begin
  cfgPath := unixroot + '\etc\lxLite\'; 
  if not FileExist(cfgPath + cfgFname) then cfgPath := sourcePath;
 end else cfgPath := sourcePath;
 S := cfgPath + cfgFname;
 Assign(T, S); Reset(T);
 if ioResult <> 0 then Stop(msgCannotLoadCFG, S);
 New(iPos, Create(4, 4));
 Mode := 0;
 While (ioResult = 0) and (not SeekEOF(T)) do
  begin
   Readln(T, S);
   DelTrailingSpaces(S);
   if First(';', S) <> 0
    then Delete(S, First(';', S), 255);
   While S <> '' do
    begin
     case Mode of
      0 : if S[1] = '['
           then begin
newID:           Delete(S, 1, 1); Mode := 1;
                 iPos^.DeleteAll;
                end
           else S := '';
      1 : begin
           if S[length(S)] = ']'
            then begin
                  Dec(byte(S[0])); Mode := 2;
                  DelTrailingSpaces(S);
                 end;
           UpStr(S);
           I := cfgIDs^.Insert(NewStr(S));
           pSC := New(pStringCollection, Create(16, 16));
           iPos^.Insert(pSC);
           cfgOpts^.AtInsert(I, pSC);
           S := '';
          end;
      2 : begin
           if S[1] = '[' then Goto newID;
           For I := 1 to iPos^.Count do
            pStringCollection(iPos^.At(pred(I)))^.Insert(NewStr(S));
           S := '';
          end;
     end;
     DelStartSpaces(S);
    end;
  end;
 Close(T);
 iPos^.DeleteAll;
 Dispose(iPos, Destroy);
 for I := cfgIDs^.Count downto 1 do
  begin
   S := pString(cfgIDs^.At(pred(I)))^;
   if S[1] = '/'
    then begin
          Delete(S, 1, 1);
          extra^.AtInsert(extra^.Count, New(pFileMatch, Create(S)));
          extraOpts^.AtInsert(extraOpts^.Count, cfgOpts^.At(pred(I)));
          cfgIDs^.AtFree(pred(I));
          cfgOpts^.AtDelete(pred(I));
         end;
  end;
end;

procedure setConfig;
var
 S   : String;
 I   : Longint;
 pSC : pStringCollection;
begin
 s := upStrg(ID);
 if loadCFG^.IndexOf(@s) <> -1 then exit;
 loadCFG^.Insert(NewStr(s));
 I := cfgIDs^.IndexOf(@s);
 if I = -1
  then begin
        SetColor($0C);
        Stop(msgCfgLoadFailed, ID);
       end;
 pSC := cfgOpts^.At(I);
 if pSC <> nil
  then For I := 1 to pSC^.Count do
        begin
         S := pString(pSC^.At(pred(I)))^;
         Parser^.Parse(S);
        end;
end;

end.
