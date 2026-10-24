{$mode delphi}{$packrecords 1}{$H-}
Unit lxLite_Global;

Interface uses exe286, exe386, os2exe, Collect, SysLib, Country;

const
 Version          : string[8] = '1.3.11u';

{ Message Identifiers }
 msgProgHeader1   = 100;
 msgProgHeader2   = 101;
 msgProgHeader3   = 102;
 msgProgHeader4   = 103;
 msgProgHeader5   = 104;
 msgProgHeaderX   = 623;
 msgProgHeader6   = 105;
 msgDone          = 106;
 msgMore          = 107;
 msgInvalidSwitch = 108;
 msgAborted       = 109;
 msgRuntime1      = 110;
 msgRuntime2      = 111;

 msgCantLoadStub  = 151;
 msgFatalIOerror  = 152;
 msgInvalidStub   = 153;
 msgCannotLoadCFG = 154;
 msgCannotOpenLog = 155;
 msgNoCountryInfo = 156;
 msgBadFileMask   = 157;
 msgEqualFilename = 158;
 msgCantWriteOut  = 159;
 msgRecursiveCfg  = 160;
 msgCantCreateDir = 161;
 msgCantCopyBackup= 162;
 msgCfgLoadFailed = 163;
 msgCantWriteBin  = 164;
 msgCantReadBin   = 165;

 msgEmpty         = 192;

 msgPageFlags     = 193;

 msgEntryPoints   = 200;

 msgCPU           = 206;

 msgNameTableHdr  = 224;
 msgImpTableHdr   = 225;
 msgExported      = 226;
 msgSharedData    = 227;
 msgParamCount    = 228;
 msgProcOffs      = 229;
 msgApplication   = 230;
 msgFullScreen    = 231;
 msgWindowed      = 232;
 msgPMapplication = 233;
 msgUnknownType   = 234;
 msgDLL           = 235;
 msgProtDLL       = 236;
 msgPDD           = 237;
 msgVDD           = 238;
 msgPerProcInit   = 239;
 msgPerProcTerm   = 240;
 msgUnknownModType= 241;
 msgNoIntFixups   = 242;
 msgNoExtFixups   = 243;
 msgNotLoadable   = 244;
 msgModuleType    = 250;
 msgReqCPU        = 251;
 msgReqOS         = 252;
 msgPageSize      = 253;
 msgObjects       = 254;
 msgObjTableOfs   = 255;
 msgMapTableOfs   = 256;
 msgNResTableOfs  = 257;
 msgImpProcOfs    = 258;
 msgPageDataOfs   = 259;
 msgPageFixOfs    = 260;
 msgFixupSize     = 261;
 msgResidentSize  = 262;
 msgImpTableOfs   = 263;
 msgImpEntries    = 264;
 msgStartEIP      = 265;
 msgAutoData      = 266;
 msgStackSize     = 267;
 msgModuleName    = 268;
 msgDescription   = 269;
 msgObjectTable   = 270;
 msgObjTableHdr   = 271;
 msgPageTableHdr  = 272;
 msgResTableHdr   = 273;
 msgNResTableHdr  = 274;
 msgImportTable   = 275;
 msgImpProcHdr    = 276;
 msgEntryTable    = 277;
 msgEntryTblHdr   = 278;
 msgRelocTable    = 279;
 msgRelocTblHdr   = 280;
 msgFixByte       = 281;
 msgFixSelector   = 282;
 msgFixPtr16      = 283;
 msgFixOfs16      = 284;
 msgFixPtr48      = 285;
 msgFixOfs32      = 286;
 msgFixRelOfs32   = 287;
 msgFixOf         = 288;
 msgFixObject     = 289;
 msgFixOffset     = 290;
 msgFixImport     = 291;
 msgFixModEntry   = 292;

 msgConfigHeader  = 300;
 msgShowInfo      = 301;
 msgForceIdle     = 302;
 msgUnpack        = 303;
 msgBackup        = 304;
 msgPause         = 305;
 msgReplaceStub   = 306;
 msgRemoveStub    = 307;
 msgAlignFO       = 308;
 msgAlignFONone   = 309;
 msgAlignFOShift  = 310;
 msgAlignFOSect   = 311;
 msgAlignObj      = 312;
 msgAlignObjShift = 313;
 msgAlignObjSect  = 314;
 msgSetPageShift  = 315;
 msgDontChange    = 316;
 msgRunLength     = 317;
 msgRLoff         = 318;
 msgRLmin         = 319;
 msgRLmed         = 320;
 msgRLmax         = 321;
 msgLempelZiv     = 322;
 msgExcludedFiles = 323;
 msgFixupsPack    = 324;
 msgFXoff         = 325;
 msgFXv2          = 326;
 msgFXv4          = 327;
 msgFXmax         = 328;
 msgSixPack       = 329;
 msgPageM3        = 330;
 msgWritingPage   = 331;
 msgReadingPage   = 332;

 msgLXerror       = 350;

 msgModInUse      = 400;
 msgModInUseAsk   = 401;
 msgModInUseRpl   = 402;
 msgModInUseCant  = 403;
 msgProcessing    = 410;
 msgModDebugInfo  = 411;
 msgModDebugAsk   = 412;
 msgModDebugRpl   = 413;
 msgAlreadyProc   = 414;
 msgModOverlay    = 415;
 msgModOvrAsk     = 416;
 msgModOvrRpl     = 417;
 msgBackupExists  = 418;
 msgBackupAsk     = 419;
 msgBackupRpl     = 420;
 msgBackingUp     = 421;
 msgBackupError   = 422;
 msgSaving        = 423;
 msgCompRate      = 424;
 msgOverall       = 425;
 msgCurDir        = 426;
 msgNResTable     = 427;
 msgNResAsk       = 428;
 msgNResRpl       = 429;

 msgLogStart      = 430;
 msgLogOp         = 431;
 msgLogDebug      = 432;
 msgLogDebugRmv   = 433;
 msgLogDebugKept  = 434;
 msgLogXtra       = 435;
 msgLogXtraRmv    = 436;
 msgLogXtraKept   = 437;
 msgLogBackOverw  = 438;
 msgLogBackSkip   = 439;
 msgLogModLocked  = 440;
 msgLogStubOut    = 441;
 msgLogError      = 442;
 msgLogCurDir     = 443;
 msgLogOverall    = 444;
 msgLogNResRmv    = 445;
 msgLogNResKept   = 446;
 msgDelBackup     = 447;

 msgCantFindFile  = 450;
 msgConfirmAsk    = 451;
 msgConfirmRpl    = 452;

 msgDbgSkip       = 460;
 msgDbgAbort      = 461;
 msgOverlaySkip   = 462;
 msgOverlayAbort  = 463;
 msgFileInUse     = 464;
 msgBackupSkip    = 465;
 msgBackupAbort   = 466;
 msgNResSkip      = 467;
 msgNResAbort     = 468;

 msgListCfg       = 480;
 msgListSel       = 481;

 msgOutputMode    = 620;
 msgUTF8          = 621;
 msgTraditional   = 622;
 msgLZoptimal     = 624;

 msgHelpFirst     = 500;
 msgHelpLast      = 616;

{-Backup flags-}
 bkfIfDebug       = $0001;
 bkfIfXtra        = $0002;
 bkfIfNE          = $0004;
 bkfAlways        = $FFFF;

{-Log condition flags-}
 lcfSucc          = $0001;
 lcfUnsucc        = $0002;
 lcfAlways        = $FFFF;

{-NEloadMode flags (except that in OS2EXE.PAS)-}
 lneAlways        = $FFFF;

{-FinalWrite flags-}
 fwfWrite         = $0001;
 fwfSimulate      = $0002;
 fwfAlways        = $FFFF;

{-NewType conditions-}
 ntfExecutable    = $0001;
 ntfLibrary       = $0002;
 ntfPhysDriver    = $0004;
 ntfVirtDriver    = $0008;
 ntfNEmodule      = $0010;
 ntfLXmodule      = $0020;
 ntfAlways        = $FFFF;

{-ForceOut bit flags-}
 fofDebug         = $0001;
 fofXtra          = $0002;
 fofStub          = $0004;
 fofAlways        = $0008;
 fofAnything      = $FFFF;

{-Confirmation query subsystem constants-}
 askInUse         = 1;
 askExtraData     = 2;
 askOverBak       = 3;
 askConfirm       = 4;
 askDbgInfo       = 5;
 askNResTable     = 6;
 askFirst         = askInUse;
 askLast          = askNResTable;

{-Verbose Information flags-}
 vfHeaderL0       = $00000001;
 vfHeaderL1       = $00000002;
 vfHeaderL2       = $00000004;
 vfHeaderL3       = $00000008;
 vfObjects        = $00000010;
 vfPageMap        = $00000030;
 vfResName        = $00000100;
 vfNResName       = $00000200;
 vfImpName        = $00000400;
 vfImpProc        = $00000800;
 vfEntTable       = $00001000;
 vfFixups         = $00010000;
 vfExtra          = $00100000;
 vfDebug          = $00200000;
 vfAnything        = -1;

 const
  open_access_ReadOnly     = $00;
  open_access_WriteOnly    = $01;
  open_access_ReadWrite    = $02;
  open_share_DenyReadWrite = $10;
  open_share_DenyWrite     = $20;
  open_share_DenyRead      = $30;
  open_share_DenyNone      = $40;

 cfgFname         = 'lxLite.cfg';
 logFname         = 'lxLite.log';

{-Configuration parameters-}
 Opt              : record
  Verbose      : Longint;
  NewType      : Longint;
  NewTypeCond  : Longint;               {ntfXXXX flags}
  doUnpack     : boolean;               {Unpack LX and save unpacked}
  pageToEnlarge: LongInt;               {page to enlarge to maximum size when unpacking 2011-11-16 SHL}
  Unpack       : boolean;               {Unpack LX before packing}
  Backup       : longint;
  Pause        : boolean;
  ApplyFixups  : boolean;
  ForceApply   : boolean;
  ApplyMask    : byte;
  SaveMode     : longint;
  PackMode     : longint;
  NEloadMode   : longint;
  Realign      : longint;
  ForceOut     : longint;
  Log          : longint;
  FinalWrite   : longint;
  PageReadPack : longint;
  PageWriteOpt : longint;
  PageRWStart  : longint;
  PageRWEnd    : longint;
  ForceRepack  : boolean;
  ForceIdle    : boolean;
  ShowConfig   : boolean;
  RecurSearch  : boolean;
  QueryCfgList : boolean;
  DiscardXOpts : boolean;
  ColoredOutput: boolean;
  UnicodeOutput: boolean;
  UseStdOut    : boolean;
  AllowZTrunc  : boolean;
  tresholdStub : Longint;
  tresholdXtra : Longint;
  tresholdDbug : Longint;
  stubName     : string;
  logFileName  : string;
  pageFileName : string;
  backupDir    : string;
  xdFileMask   : string;
  ddFileMask   : string;
  sdFileMask   : string;
  AskStatus    : array[askFirst..askLast] of record
                  ID    : char; {The /Y# character}
                  Reply : char; {What to answer}
                 end;
 end =
 (Verbose      : 0;
  NewType      : 0;
  NewTypeCond  : 0;                     {ntfXXXX flags}
  doUnpack     : FALSE;                 {Unpack LX and save unpacked}
  pageToEnlarge: 0;                     {page to enlarge to maximum size when unpacking}
  Unpack       : TRUE;                  {Unpack LX before packing}
  Backup       : 0;
  Pause        : FALSE;
  ApplyFixups  : TRUE;
  ForceApply   : FALSE;
  ApplyMask    : 7;
  SaveMode     : svfFOalnNone + svfEOalnShift;
  PackMode     : pkfLempelZiv + pkfFixups + pkfFixupsVer2;
  NEloadMode   : 0;
  Realign      : NoRealign;
  ForceOut     : 0;
  Log          : lcfSucc;
  FinalWrite   : fwfWrite;
  PageReadPack : 0;
  PageWriteOpt : 0;
  PageRWStart  : -1;
  PageRWEnd    : -1;
  ForceRepack  : FALSE;
  ForceIdle    : TRUE;
  ShowConfig   : FALSE;
  RecurSearch  : FALSE;
  QueryCfgList : FALSE;
  DiscardXOpts : FALSE;
  ColoredOutput: TRUE;
  UnicodeOutput: {$IFDEF UNIX}TRUE{$ELSE}FALSE{$ENDIF};
  UseStdOut    : {$IFDEF MSWINDOWS}TRUE{$ELSE}FALSE{$ENDIF};
  AllowZTrunc  : TRUE;
  tresholdStub : 0;
  tresholdXtra : 1024;
  tresholdDbug : $7FFFFFFF;
  stubName     : '';
  logFileName  : '';
  pageFileName : '';
  backupDir    : '';
  xdFileMask   : '';
  ddFileMask   : '';
  sdFileMask   : '';
  AskStatus    : ((ID : 'U'; Reply : #0),  {module in Use}
                  (ID : 'X'; Reply : #0),  {eXtra data}
                  (ID : 'B'; Reply : #0),  {overwrite Backup}
                  (ID : 'C'; Reply : #0),  {Confirmation}
                  (ID : 'D'; Reply : #0),  {Debug info}
                  (ID : 'N'; Reply : #0))  {Non-resident name table}
 );

type
 pModuleDef = ^tModuleDef;
 tModuleDef = record
  ModuleName : string;
  defStart,
  defLength  : Longint;
 end;
 pModuleCollection = ^tModuleCollection;
 tModuleCollection = object(tStringCollection)
  procedure FreeItem(Item: Pointer); virtual;
 end;

var
 RedirOutput : boolean = False;
 RedirInput  : boolean = False;
 StdIn       : Text;
 StdOut      : Text;

var
 fNames,
 loadCFG   : pStringCollection;
 exclude   : pFileMatch;
 newStub   : Pointer;
 newStubSz : Longint;

procedure SetColor(Color : Byte);
procedure ClearToEOL;
procedure ConfigureOutputTTY;
function OutputCP437(const S : string) : string;
function OutputChar(C : Char) : string;
function OutputResource(ID : Longint) : string;
function OutputWidth(const S : string) : Integer;

Implementation uses Crt, StrOp{$IFDEF UNIX}, termio{$ENDIF}
                         {$IFDEF MSWINDOWS}, Windows{$ENDIF};

{$IFDEF UNIX}
var
  SavedTTY : Termios;
  SavedTTYFlags : Boolean = FALSE;
  UnicodeTTYActive : Boolean = FALSE;

{ CRT initializes the terminal for its own screen writer.  In that mode
  the kernel may not map LF to CR/LF, so ordinary UTF-8 stdout produces
  the diagonal output seen when /GU is used on a real terminal.  Preserve
  CRT's other tty settings and change only the output processing flags. }
procedure ConfigureOutputTTY;
var
  TTY : Termios;
begin
  UnicodeTTYActive := FALSE;
  if RedirOutput or (TCGetAttr(1, TTY) <> 0) then Exit;
  if not SavedTTYFlags then begin
    SavedTTY := TTY;
    SavedTTYFlags := TRUE;
  end;
  if Opt.UnicodeOutput then
    TTY.c_oflag := TTY.c_oflag or OPOST or ONLCR
  else
    TTY.c_oflag := (TTY.c_oflag and not (OPOST or ONLCR)) or
                   (SavedTTY.c_oflag and (OPOST or ONLCR));
  if TCSetAttr(1, TCSANOW, TTY) = 0 then
    UnicodeTTYActive := Opt.UnicodeOutput;
end;
{$ELSE}
{$IFDEF MSWINDOWS}
const
  WinCP437 = 437;
  WinCPUTF8 = 65001;

var
  WinConsoleOutput : THandle = 0;
  WinConsoleOutputActive : Boolean = FALSE;
  WinSavedOutputCP : UINT = 0;
  WinOutputCPChanged : Boolean = FALSE;

procedure RestoreWinOutputCP;
begin
  if WinOutputCPChanged and (WinSavedOutputCP <> 0) then
    SetConsoleOutputCP(WinSavedOutputCP);
  WinOutputCPChanged := FALSE;
end;

{ Streaming stdout scrolls normally in ConPTY-based terminals.  Use the
  console's selected code page to interpret that stream, but never change
  the code page for redirected stdout.  /CS- restores the original one. }
procedure ConfigureOutputTTY;
var
  H : THandle;
  Mode : DWORD;
  DesiredCP, CurrentCP : UINT;
begin
  WinConsoleOutputActive := FALSE;
  if not (Opt.UseStdOut or Opt.UnicodeOutput) then begin
    RestoreWinOutputCP;
    Exit;
  end;
  H := GetStdHandle(STD_OUTPUT_HANDLE);
  if (H = 0) or (H = INVALID_HANDLE_VALUE) or
     (not GetConsoleMode(H, Mode)) then begin
    RestoreWinOutputCP;
    Exit;
  end;

  WinConsoleOutput := H;
  WinConsoleOutputActive := TRUE;
  CurrentCP := GetConsoleOutputCP;
  if not WinOutputCPChanged then WinSavedOutputCP := CurrentCP;
  if Opt.UnicodeOutput then DesiredCP := WinCPUTF8
                       else DesiredCP := WinCP437;
  if (CurrentCP <> 0) and (CurrentCP <> DesiredCP) and
     SetConsoleOutputCP(DesiredCP) then
    WinOutputCPChanged := TRUE;
end;
{$ELSE}
procedure ConfigureOutputTTY;
begin
end;
{$ENDIF}
{$ENDIF}

{ Convert only text known to be CP437.  Filenames received from Unix must
  stay in their native encoding and must never pass through this function. }
function OutputCP437(const S : string) : string;
const
 CodePoints : array[$80..$FF] of Word = (
  $00C7, $00FC, $00E9, $00E2, $00E4, $00E0, $00E5, $00E7,
  $00EA, $00EB, $00E8, $00EF, $00EE, $00EC, $00C4, $00C5,
  $00C9, $00E6, $00C6, $00F4, $00F6, $00F2, $00FB, $00F9,
  $00FF, $00D6, $00DC, $00A2, $00A3, $00A5, $20A7, $0192,
  $00E1, $00ED, $00F3, $00FA, $00F1, $00D1, $00AA, $00BA,
  $00BF, $2310, $00AC, $00BD, $00BC, $00A1, $00AB, $00BB,
  $2591, $2592, $2593, $2502, $2524, $2561, $2562, $2556,
  $2555, $2563, $2551, $2557, $255D, $255C, $255B, $2510,
  $2514, $2534, $252C, $251C, $2500, $253C, $255E, $255F,
  $255A, $2554, $2569, $2566, $2560, $2550, $256C, $2567,
  $2568, $2564, $2565, $2559, $2558, $2552, $2553, $256B,
  $256A, $2518, $250C, $2588, $2584, $258C, $2590, $2580,
  $03B1, $00DF, $0393, $03C0, $03A3, $03C3, $00B5, $03C4,
  $03A6, $0398, $03A9, $03B4, $221E, $03C6, $03B5, $2229,
  $2261, $00B1, $2265, $2264, $2320, $2321, $00F7, $2248,
  $00B0, $2219, $00B7, $221A, $207F, $00B2, $25A0, $00A0);
var
 I, B, AddBytes : Integer;
 U : Word;
begin
 if not Opt.UnicodeOutput then begin Result := S; exit; end;
 Result := '';
 for I := 1 to Length(S) do begin
   B := Ord(S[I]);
   if B < $80 then begin
     if Length(Result) = 255 then Break;
     Result := Result + S[I];
   end
   else begin
     U := CodePoints[B];
     if U < $800 then AddBytes := 2 else AddBytes := 3;
     { ShortString is limited to 255 bytes.  Never truncate halfway
       through a UTF-8 sequence at that boundary. }
     if Length(Result) + AddBytes > 255 then Break;
     if U < $800 then
       Result := Result + Chr($C0 or (U shr 6)) +
                     Chr($80 or (U and $3F))
     else
       Result := Result + Chr($E0 or (U shr 12)) +
                     Chr($80 or ((U shr 6) and $3F)) +
                     Chr($80 or (U and $3F));
   end;
 end;
end;

function OutputChar(C : Char) : string;
begin
 OutputChar := OutputCP437(C);
end;

function OutputResource(ID : Longint) : string;
begin
 OutputResource := OutputCP437(SysLib.GetResourceString(ID));
end;

{ Screen spacing is measured in characters, not UTF-8 bytes. }
function OutputWidth(const S : string) : Integer;
var I : Integer;
begin
 if not Opt.UnicodeOutput then begin Result := Length(S); exit; end;
 Result := 0;
 for I := 1 to Length(S) do
   if (Ord(S[I]) and $C0) <> $80 then Inc(Result);
end;

procedure SetColor;
const
 ColorTranslate : array[0..15] of Byte =
 (0, 7, 7, 7, 7, 7, 7, 7, 8, 7, 15, 15, 15, 15, 15, 15);
{$IFDEF UNIX}
 FGColors : array[0..7] of Byte = (30, 34, 32, 36, 31, 35, 33, 37);
 BGColors : array[0..7] of Byte = (40, 44, 42, 46, 41, 45, 43, 47);
{$ENDIF}
var
 B,F : Byte;
{$IFDEF UNIX}
 FG,BG : Byte;
{$ENDIF}
begin
 if opt.ColoredOutput
  then textAttr := Color
  else begin
        B := Color shr 4;
        F := Color and $0F;
        textAttr := ColorTranslate[B] * 16 + ColorTranslate[F];
       end;
{$IFDEF UNIX}
 { Direct UTF-8 writes bypass the CRT renderer, so textAttr alone cannot
   color them.  Emit terminal colors only on an interactive Unicode tty. }
 if UnicodeTTYActive then begin
   F := textAttr and $0F;
   B := (textAttr shr 4) and $07;
   FG := FGColors[F and $07];
   if F and $08 <> 0 then Inc(FG, 60);
   BG := BGColors[B];
   Write(Output, #27'[', FG, ';', BG, 'm');
 end;
{$ENDIF}
{$IFDEF MSWINDOWS}
 { The stdout writer bypasses the CRT color renderer as well.  Applying
   console attributes here preserves colors for both /GT and /GU without
   emitting escape sequences into redirected files or pipes. }
 if WinConsoleOutputActive then
   SetConsoleTextAttribute(WinConsoleOutput, textAttr);
{$ENDIF}
end;

procedure ClearToEOL;
var
 Spaces : Integer;
begin
 if not RedirOutput
  then if opt.UseStdOut or opt.UnicodeOutput
        then begin
{$IFDEF UNIX}
              if UnicodeTTYActive then begin
                Write(Output, #27'[K');
                Exit;
              end;
{$ENDIF}
              Spaces := succ(lo(WindMax)) - WhereX;
              Write(strg(' ', Spaces), strg(#8, Spaces));
             end
        else ClrEOL;
end;

procedure tModuleCollection.FreeItem;
begin
 Dispose(pModuleDef(Item));
end;


initialization
{$IFDEF UNIX}
  RedirInput := (isatty(0) = 0);
  RedirOutput := (isatty(1) = 0);
{$ENDIF}
  Assign(StdIn, '');
  Reset(StdIn);
  Assign(StdOut, '');
  Rewrite(StdOut);
{$IFDEF MSWINDOWS}
finalization
  RestoreWinOutputCP;
{$ENDIF}
end.
