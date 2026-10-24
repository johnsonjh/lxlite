unit LZOptimal;

interface

function PackMethod2Optimal(var srcData, dstData; srcDataSize: Longint;
                            var dstDataSize: Longint): Boolean;

implementation

const
  maxPageSize = 4096;
  hashSize = 4096;
  noLink = $FFFF;
  maxCost = $7FFFFFFF;

  tokenLiteral = 0;
  tokenRepeat = 1;
  tokenShort = 2;
  tokenMedium = 3;
  tokenLong = 4;

type
  tByteArray = array[0..65535] of Byte;
  pByteArray = ^tByteArray;
  tWordArray = array[0..65535] of Word;
  pWordArray = ^tWordArray;

  tOptimalState = record
    Cost, ShortCost, LongCost: Longint;
    Distance: Word;
    TokenLength: Byte;
    Prefix: Byte;
    Kind: Byte;
    ShortLength: Byte;
    LongLength: Byte;
  end;
  tStateArray = array[0..65535] of tOptimalState;
  pStateArray = ^tStateArray;

procedure Consider(var S: tOptimalState; C: Longint;
                   K, P, L: Byte; D: Word);
begin
  if C < S.Cost then
   begin
    S.Cost := C;
    S.Kind := K;
    S.Prefix := P;
    S.TokenLength := L;
    S.Distance := D;
   end;
end;

function PackMethod2Optimal;
label cleanup;
var
  Src: tByteArray absolute srcData;
  Dst: tByteArray absolute dstData;
  Chain, Heads, NearDistance, FarDistance: pWordArray;
  NearLength, FarLength: pByteArray;
  States: pStateArray;
  N, I, J, K, H, P, D, L, Limit, Prefix,
  RepeatLength, OutPos, Candidate, Capacity: Longint;
  Encoded: Word;
begin
  PackMethod2Optimal := False;
  N := srcDataSize;
  Capacity := dstDataSize;
  if (N <= 0) or (N > maxPageSize) or (Capacity < 2) then Exit;

  Chain := nil;
  Heads := nil;
  NearDistance := nil;
  FarDistance := nil;
  NearLength := nil;
  FarLength := nil;
  States := nil;

  GetMem(Chain, N * SizeOf(Word));
  if Chain = nil then goto cleanup;
  GetMem(Heads, hashSize * SizeOf(Word));
  if Heads = nil then goto cleanup;
  GetMem(NearDistance, N * SizeOf(Word));
  if NearDistance = nil then goto cleanup;
  GetMem(FarDistance, N * SizeOf(Word));
  if FarDistance = nil then goto cleanup;
  GetMem(NearLength, N);
  if NearLength = nil then goto cleanup;
  GetMem(FarLength, N);
  if FarLength = nil then goto cleanup;
  GetMem(States, (N + 1) * SizeOf(tOptimalState));
  if States = nil then goto cleanup;

  FillChar(Chain^, N * SizeOf(Word), $FF);
  FillChar(Heads^, hashSize * SizeOf(Word), $FF);
  FillChar(NearLength^, N, 0);
  FillChar(FarLength^, N, 0);

  { Match discovery is independent of parsing decisions: every source
    position enters the dictionary.  Only the longest available match in
    each distance class is needed because token prices do not depend on
    the exact distance within that class.  Shorter lengths remain legal. }
  for I := 0 to N - 3 do
   begin
    H := (Longint(Src[I]) or (Longint(Src[I + 1]) shl 8)) and $FFF;
    P := Heads^[H];
    while P <> noLink do
     begin
      D := I - P;
      if D > 4095 then Break;
      if (FarLength^[I] = 63) and
         ((NearLength^[I] = 10) or (D > 511)) then Break;

      Limit := N - I;
      if Limit > 63 then Limit := 63;
      L := 0;
      while L < Limit do
       if Src[P + L] = Src[I + L] then Inc(L) else Break;
      if L >= 3 then
       begin
        if L > FarLength^[I] then
         begin
          FarLength^[I] := L;
          FarDistance^[I] := D;
         end;
        if D <= 511 then
         begin
          if L > 10 then K := 10 else K := L;
          if K > NearLength^[I] then
           begin
            NearLength^[I] := K;
            NearDistance^[I] := D;
           end;
         end;
       end;
      P := Chain^[P];
     end;
    Chain^[I] := Heads^[H];
    Heads^[H] := I;
   end;

  States^[N].Cost := 2;  { Original two-byte end-of-page marker. }
  for I := N - 1 downto 0 do
   begin
    States^[I].Cost := maxCost;
    States^[I].ShortCost := maxCost;
    States^[I].LongCost := maxCost;
    States^[I].ShortLength := 0;
    States^[I].LongLength := 0;

    { Precompute the least-cost suffix after a near or general match.
      Later iterations can then check literal prefixes in constant time. }
    Limit := NearLength^[I];
    if Limit > 10 then Limit := 10;
    for L := 3 to Limit do
     if States^[I + L].Cost < States^[I].ShortCost then
      begin
       States^[I].ShortCost := States^[I + L].Cost;
       States^[I].ShortLength := L;
      end;
    Limit := FarLength^[I];
    for L := 3 to Limit do
     if States^[I + L].Cost < States^[I].LongCost then
      begin
       States^[I].LongCost := States^[I + L].Cost;
       States^[I].LongLength := L;
      end;

    Limit := N - I;
    if Limit > 63 then Limit := 63;
    for L := 1 to Limit do
     Consider(States^[I], 1 + L + States^[I + L].Cost,
              tokenLiteral, 0, L, 0);

    RepeatLength := 1;
    while (RepeatLength < 255) and (I + RepeatLength < N) do
     if Src[I + RepeatLength] = Src[I] then Inc(RepeatLength)
     else Break;
    for L := 3 to RepeatLength do
     Consider(States^[I], 3 + States^[I + L].Cost,
              tokenRepeat, 0, L, 0);

    Limit := FarLength^[I];
    if Limit > 6 then Limit := 6;
    for L := 3 to Limit do
     Consider(States^[I], 2 + States^[I + L].Cost,
              tokenMedium, 0, L, FarDistance^[I]);

    Limit := N - I - 1;
    if Limit > 3 then Limit := 3;
    for Prefix := 0 to Limit do
     begin
      J := I + Prefix;
      if States^[J].ShortLength <> 0 then
       begin
        Candidate := 2 + Prefix + States^[J].ShortCost;
        Consider(States^[I], Candidate, tokenShort, Prefix,
                 States^[J].ShortLength, NearDistance^[J]);
       end;
     end;

    Limit := N - I - 1;
    if Limit > 15 then Limit := 15;
    for Prefix := 0 to Limit do
     begin
      J := I + Prefix;
      if States^[J].LongLength <> 0 then
       begin
        Candidate := 3 + Prefix + States^[J].LongCost;
        Consider(States^[I], Candidate, tokenLong, Prefix,
                 States^[J].LongLength, FarDistance^[J]);
       end;
     end;
   end;

  { The original encoder and OS/2 loader require a worthwhile packed page
    and lxLite limits its encoded stream to less than $FFC bytes. }
  if (States^[0].Cost >= N) or (States^[0].Cost >= $FFC) or
     (States^[0].Cost > Capacity) then goto cleanup;

  I := 0;
  OutPos := 0;
  while I < N do
   begin
    with States^[I] do
     begin
      L := TokenLength;
      Prefix := States^[I].Prefix;
      D := Distance;
      if (L = 0) or (I + Prefix + L > N) then goto cleanup;
      case Kind of
       tokenLiteral:
        begin
         if OutPos + L + 1 > Capacity then goto cleanup;
         Dst[OutPos] := L shl 2;
         Move(Src[I], Dst[OutPos + 1], L);
         Inc(OutPos, 1 + L);
        end;
       tokenRepeat:
        begin
         if OutPos + 3 > Capacity then goto cleanup;
         Dst[OutPos] := 0;
         Dst[OutPos + 1] := L;
         Dst[OutPos + 2] := Src[I];
         Inc(OutPos, 3);
        end;
       tokenMedium:
        begin
         if (D = 0) or (D > 4095) or (L < 3) or (L > 6) or
            (OutPos + 2 > Capacity) then goto cleanup;
         Encoded := 2 or ((L - 3) shl 2) or (D shl 4);
         Move(Encoded, Dst[OutPos], 2);
         Inc(OutPos, 2);
        end;
       tokenShort:
        begin
         if (D = 0) or (D > 511) or (L < 3) or (L > 10) or
            (Prefix > 3) or (OutPos + 2 + Prefix > Capacity)
          then goto cleanup;
         Encoded := 1 or (Prefix shl 2) or ((L - 3) shl 4) or (D shl 7);
         Move(Encoded, Dst[OutPos], 2);
         if Prefix <> 0 then Move(Src[I], Dst[OutPos + 2], Prefix);
         Inc(OutPos, 2 + Prefix);
        end;
       tokenLong:
        begin
         if (D = 0) or (D > 4095) or (L < 3) or (L > 63) or
            (Prefix > 15) or (OutPos + 3 + Prefix > Capacity)
          then goto cleanup;
         Encoded := 3 or (Prefix shl 2) or (L shl 6) or ((D and 15) shl 12);
         Move(Encoded, Dst[OutPos], 2);
         Dst[OutPos + 2] := D shr 4;
         if Prefix <> 0 then Move(Src[I], Dst[OutPos + 3], Prefix);
         Inc(OutPos, 3 + Prefix);
        end;
       else goto cleanup;
      end;
      Inc(I, Prefix + L);
     end;
   end;
  if (OutPos + 2 > Capacity) or (OutPos + 2 <> States^[0].Cost)
   then goto cleanup;
  Dst[OutPos] := 0;
  Dst[OutPos + 1] := 0;
  dstDataSize := OutPos + 2;
  PackMethod2Optimal := True;

cleanup:
  if States <> nil then FreeMem(States, (N + 1) * SizeOf(tOptimalState));
  if FarLength <> nil then FreeMem(FarLength, N);
  if NearLength <> nil then FreeMem(NearLength, N);
  if FarDistance <> nil then FreeMem(FarDistance, N * SizeOf(Word));
  if NearDistance <> nil then FreeMem(NearDistance, N * SizeOf(Word));
  if Heads <> nil then FreeMem(Heads, hashSize * SizeOf(Word));
  if Chain <> nil then FreeMem(Chain, N * SizeOf(Word));
end;

end.
