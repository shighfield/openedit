{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{                                                                   Rev. 017 }
{ Utility Pack                                                               }
{ Miscellaneous Turbo Pascal v7.0 Utilities                                  }
{ By Steve Blinch of Mikerosoft Productions                                  }
{                                                                            }
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

{.$DEFINE SysInfo}
{.$DEFINE Useless}

Unit UtilPack;

{$O+}
{$F+}
{$G+}

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
  Interface

Uses DOS;

Function RemoveWildcard(St: String): String;
Function FileExists(FN: String): Boolean;

Function Capitalize(S: String): String;
Function LoCase(C: Char): Char;
Function UCase(UpString: String): String;
Function FPad(St: String; I: Integer): String;
Function Pad(St: String; I: Integer): String;
Function LTrim(WhatStr: String): String;
Function RTrim(WhatStr: String): String;
Function Zero(I: LongInt; Z: Byte): String;
Function LeadingZero(W: Word): String;
Function MakeStr(Len: Byte; MCh: Char): String;

Function FormatTime(Rl: Real): String;
Function Timer: Real;
Procedure CDelay(D: Word);
Function Julian(DT: String): Longint;
Function UnpackedDT(L: LongInt): String;
Function CurrentDT: LongInt;

Procedure SaveScreen(Idx: Byte);
Procedure RestoreScreen(Idx: Byte);
Function GetChar: Char;
Function VSeg: Word;

Function IntVal(ChrStr: String): Integer;
Function LIntVal(ChrStr: String): LongInt;
Function StrVal(IntNum: LongInt): String;

Type
 SaveScrRec = Record
   X,Y,TxtAttr: Byte;
   WndMin,WndMax: Word;
   Screen     : Array[1..4000] Of Byte;
  End;
Var
 Saved: Array[1..12] Of ^SaveScrRec;

Const
 FT12Hour: Boolean = False;          { Make FormatTime return 12hour time }

  Implementation
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}


Uses Crt;

Procedure SaveScreen(Idx: Byte);
{ No direct video memory on this target - captures cursor position and
  attribute only, not screen content, pending the ncurses/Video-unit port. }
Begin
 If (Idx>10) Or (Idx=0) Then
  Begin
   GotoXY(19,12);
   TextAttr:=$07;
   Write(' Save_Screen ptr ',Idx,' out of range, cannot save! ');
   Halt;
  End;
 New(Saved[Idx]);
 With Saved[Idx]^ Do
  Begin
   X:=WhereX;
   Y:=WhereY;
   TxtAttr:=TextAttr;
   WndMin:=WindMin;
   WndMax:=WindMax;
  End;
End;

Procedure RestoreScreen(Idx: Byte);
Begin
 If (Idx>10) Or (Idx=0) Then
  Begin
   GotoXY(18,12);
   TextAttr:=$07;
   Write(' Restore_Screen ptr ',Idx,' out of range, cannot restore! ');
   Halt;
  End;
 With Saved[Idx]^ Do
  Begin
   WindMin:=WndMin;
   WindMax:=WndMax;
   GotoXY(X,Y);
   TextAttr:=TxtAttr;
  End;
 Dispose(Saved[Idx]); Saved[Idx]:=Nil;
End;

Function RemoveWildcard(St: String): String;
Begin
 While (St[Length(St)]<>'\') And (St<>'') Do Delete(St,Length(St),1);
 RemoveWildcard:=St;
End;


Function FileExists(FN: String): Boolean;
var
 F: file;
begin
 Assign(F,FN);
 {$I-} Reset(F); Close(F); {$I+}
 FileExists := (IOResult = 0) and (FN <> '');
end;

Function Capitalize(S: String): String;
Var Tmp: Byte;
Begin
 For Tmp:=1 To Length(S) Do
  If Not (S[Tmp] in ['A'..'Z','a'..'z','''',#128..#165]) Then
   S[Tmp+1]:=UpCase(S[Tmp+1])
  Else
   S[Tmp+1]:=LoCase(S[Tmp+1]);
 If Pos('BBS',UCase(S))>0 Then
  Begin
   S[Pos('BBS',UCase(S))+0]:='B';
   S[Pos('BBS',UCase(S))+1]:='B';
   S[Pos('BBS',UCase(S))+2]:='S';
  End;
 S[1]:=UpCase(S[1]);
 Capitalize:=S;
End;

Function StrVal(IntNum: LongInt): String;
Var TS: String;
Begin
 Str(IntNum,TS);
 StrVal:=TS;
End;

Function IntVal(ChrStr: String): Integer;
Var TI: Integer;
    Code: Word;
Begin
 Val(ChrStr,TI,Code);
 If Code<>0 Then TI:=-1;
 IntVal:=TI;
End;

Function LIntVal(ChrStr: String): LongInt;
Var TI: LongInt;
    Code: Word;
Begin
 Val(ChrStr,TI,Code);
 If Code<>0 Then TI:=-1;
 LIntVal:=TI;
End;

Function LeadingZero(W: Word): String;
Var S: String;
Begin
 Str(W:0,S);
 If Length(S)=1 then S:='0'+S;
 LeadingZero:=S;
End;

Function UCase(UpString: String): String;
Var LtrNum: Integer;
Begin
 LtrNum:=0;
 For LtrNum:=1 To Length(UpString) do
  UpString[LtrNum]:=UpCase(UpString[LtrNum]);
 UCase:=UpString;
End;

Function LoCase(C: Char): Char;
Begin
 If C in ['A'..'Z'] Then C:=Chr(Ord(C)+32);
 LoCase:=C;
End;

Function Pad(St: String; I: Integer): String;
Var C: Integer;
Begin
 For C:=1 To I-Length(St) Do St:=St+' ';
 Pad:=St;
End;

Function FPad(St: String; I: Integer): String;
Var C: Integer;
Begin
 For C:=1 To I-Length(St) Do St:=' '+St;
 FPad:=St;
End;

Function LTrim(WhatStr: String): String;
Begin
 While (WhatStr[1]=' ') And (WhatStr<>'') Do
  Delete(WhatStr,1,1);
 LTrim:=WhatStr;
End;

Function RTrim(WhatStr: String): String;
Begin
 While (WhatStr[Length(WhatStr)]=' ') And (WhatStr<>'') Do
  Delete(WhatStr,Length(WhatStr),1);
 RTrim:=WhatStr;
End;

Function Timer: Real;
Var H,M,S,S100: Word;
Begin
 GetTime(H,M,S,S100);
 Timer:=H*3600.0+M*60.0+S+S100/100.0;
End;

Procedure CDelay(D: Word);
Var CTime: Real;
Begin
 CTime:=Timer+(D / 1000);
 Repeat Until Timer>=CTime;
End;

Function FormatTime(Rl:Real):String;
Var H,M,S:String;

Function Tch(I:String):String;
Begin
  If Length(I)>2 Then I:=Copy(I,Length(I)-1,2) Else
    If Length(I)=1 Then I:='0'+I;
  Tch:=I;
End;

Function Cstr(I:Longint):String;
Var C:String;
Begin
  Str(I,C); Cstr:=C;
End;

Begin
  S:=Tch(Cstr(Trunc(Rl-Int(Rl/60.0)*60.0)));
  M:=Tch(Cstr(Trunc(Int(Rl/60.0)-Int(Rl/3600.0)*60.0)));
  H:=Tch(Cstr(Trunc(Rl/3600.0)));
  If FT12Hour Then
   Begin
    If IntVal(H)>12 Then
     Begin H:=StrVal(IntVal(H)-12); S:=S+'p'; End
    Else
    Begin
     If IntVal(H)=0 Then H:='12';
     S:=S+'a';
    End;
    FT12Hour:=False;
   End;
  If Length(H)=1 Then H:='0'+H;
  FormatTime:=H+':'+M+':'+S;
End;

Function MakeStr(Len: Byte; MCh: Char): String;
Var MC: Integer;
    Out: String;
Begin
 FillChar(Out,SizeOf(Out),MCh);
 Out[0]:=Chr(Len);
 MakeStr:=Out;
End;

Function Zero(I: LongInt; Z: Byte): String;
Var S: String;
Begin
 S:=StrVal(I);
 While Length(S)<Z Do S:='0'+S;
 Zero:=S;
End;

Function GetChar: Char;
{ Was a BIOS "read char under cursor" call - no equivalent without a real
  screen buffer. Stubbed pending the ncurses/Video-unit port. }
Begin
 GetChar:=' ';
End;

Function Julian(DT: String): Longint;             { MM/DD/YY -> Julian Date }
Var
 Temp,Y,M,D: Longint;
 Code: Word;
Begin
 Val(Copy(DT,7,2),Y,Code);
 Val(Copy(DT,1,2),M,Code);
 Val(Copy(DT,4,2),D,Code);
 If (Y<0) Or (Not (M in [1..12])) Or (Not (D in [1..31])) Then
  Begin
   Julian:=-1;
   Exit;
  End;
 Y:=Y+1900;
 Temp:=(M-14) Div 12;
 Julian:=D-32075+(1461*(Y+4800+Temp) Div 4)+(367*(M-2-Temp*12) Div 12)-
         (3*((Y+4900+Temp) Div 100) Div 4);
End;


Function UnpackedDT(L: LongInt): String;
Var DT: DateTime;
Begin
 UnPackTime(L,DT);
 UnpackedDT:=LeadingZero(DT.Month)+'/'+LeadingZero(DT.Day)+'/'+LeadingZero(DT.Year-1900)+
            ' '+LeadingZero(DT.Hour)+':'+LeadingZero(DT.Min)+':'+LeadingZero(DT.Sec);
End;

Function CurrentDT: LongInt;
Var DT: DateTime;
    W: Word;
    L: LongInt;
Begin
 GetDate(DT.Year,DT.Month,DT.Day,W);
 GetTime(DT.Hour,DT.Min,DT.Sec,W);
 PackTime(DT,L);
 CurrentDT:=L;
End;

Function VSeg: Word;
{ No direct video memory on this target; kept only for API compatibility
  pending the ncurses/Video-unit port. }
Begin
 VSeg:=0;
End;


{$IFDEF SysInfo}
Function AnsiSysLoaded: Boolean;
Var
 _AX : Word;
 Regs: Registers;
Begin
 Regs.AX:=$1a00;
 Intr($2f,Regs);
 _Ax:=Regs.AX;
 ANSISysLoaded:=(Lo(_AX)=$FF);
End;

Function DblLoaded: Boolean;
Var R: Registers;
Begin
 With R Do
  Begin
   AX:=$4A11;
   BX:=$0000;
  End;
 Intr($2F,R);
 DblLoaded:=(R.BX=$444D);
End;

Function x4DOSLoaded: Boolean;
Var R: Registers;
Begin
 With R Do
  Begin
   AX:=$D44D;
   BX:=$0000;
  End;
 Intr($2F,R);
 x4DOSLoaded:=(R.AX=$44DD);
End;

Function ShareLoaded: Boolean;
Var R: Registers;
Begin
 With R Do
  Begin
   AH:=$5C;
   AL:=$01;
  End;
 Intr($21,R);
 ShareLoaded:=((R.Flags And FCarry)=FCarry) And (R.AX<>$01);
End;

Function EnhKbd: Boolean; Assembler;
Asm
    push ds
    mov  ax,40h
    mov  ds,ax
    mov  ah,byte ptr [96h]
    pop ds
    and  ah,16
    mov  al,1
    cmp  ah,16
    je   @@1
    mov  al,0
@@1:
End;

Function NumLock: Boolean; Assembler;
Asm
    push ds
    mov  ax,40h
    mov  ds,ax
    mov  al,byte ptr [17h]
    pop ds
    and  al,32
End;

Function ScrollLock: Boolean; Assembler;
Asm
    push ds
    mov  ax,40h
    mov  ds,ax
    mov  al,byte ptr [17h]
    pop ds
    and  al,16
End;

Function CapsLock: Boolean; Assembler;
Asm
    push ds
    mov  ax,40h
    mov  ds,ax
    mov  al,byte ptr [17h]
    pop ds
    and  al,64
End;

Function SBDetected: Word;
Var xbyte1, xbyte2, xbyte3, xbyte4: Byte;
  xword, xword1, xword2, temp, sbport: Word;
  sbfound, portok: Boolean;
Begin
  sbfound:=False;
  xbyte1:=1;
  While (xbyte1 < 7) And (Not sbfound) Do
  Begin
    sbport:=$200 + ($10 * xbyte1);
    xword1:=0;
    portok:=False;
    While (xword1 < $201) And (Not portok) Do
    Begin
      If (Port[sbport + $0C] And $80) = 0 Then
        portok:=True;
      Inc(xword1)
    End;
    If portok Then
    Begin
      xbyte3:=Port[sbport + $0C];
      Port[sbport + $0C]:=$D3;
      For xword2:=1 To $1000 Do {nothing};
      xbyte4:=Port[sbport + 6];
      Port[sbport + 6]:=1;
      xbyte2:=Port[sbport + 6];
      xbyte2:=Port[sbport + 6];
      xbyte2:=Port[sbport + 6];
      xbyte2:=Port[sbport + 6];
      Port[sbport + 6]:=0;
      xbyte2:=0;
      Repeat
        xword1:=0;
        portok:=False;
        While (xword1 < $201) And (Not portok) Do
        Begin
          If (Port[sbport + $0E] And $80) = $80 Then
            portok:=True;
          Inc(xword1)
        End;
        If portok Then
          If Port[sbport + $0A] = $AA Then
            sbfound:=True;
        Inc(xbyte2);
      Until (xbyte2 = $10) Or (portok);
      If Not portok Then
      Begin
        Port[sbport + $0C]:=xbyte3;
        Port[sbport + 6]:=xbyte4;
      End;
    End;
    If sbfound Then
    Begin
    End
    Else
      Inc(xbyte1);
  End;
 If SBFound Then SBDetected:=SBPort Else SBDetected:=0;
End;

{  For CPU Detection...  }

Const CPU_8088    =  8088;
      CPU_80186   = 80186;
      CPU_80286   = 80286;
      CPU_80386   = 80386;
      CPU_80486   = 80486;
      CPU_UNKNOWN =     0;

Var
 CPU: LongInt;
 OldIntr6Handler: Procedure;
 Valid_Op_Code: Boolean;

 Procedure Intr6Handler; Interrupt;
 Begin
  Valid_Op_Code:=False;
  asm
    add word ptr ss:[bp + 18], 3
  end;
 End;

 Function Isa8088: Boolean;
 Var sp1, sp2 : word;
 Begin
  asm
    mov sp1, sp
    push sp
    pop sp2
  end;
  If sp1<>sp2 Then
   Isa8088:=True
  Else
   Isa8088:=False;
 End;

 Function Isa80186: Boolean;
 Begin
  if Isa8088 Then
   Isa80186:=False
  Else
  Begin
   Valid_Op_Code:=True;
   GetIntVec(6, @OldIntr6Handler);
   SetIntVec(6, Addr(Intr6Handler));
   inline($C1/$E2/$05);  { shl dx, 5 }
   SetIntVec(6, @OldIntr6Handler);
   Isa80186:=Valid_Op_Code;
  End;
 End;

 Function Isa80286: Boolean;
 Begin
  If Isa8088 Then
   Isa80286:=False
  Else
  Begin
   Valid_Op_Code:=True;
   GetIntVec(6, @OldIntr6Handler);
   SetIntVec(6, Addr(Intr6Handler));
   inline($0F/$01/$E2);  { smsw dx }
   SetIntVec(6, @OldIntr6Handler);
   Isa80286:=Valid_Op_Code;
  End;
 End;

 Function Isa80386: Boolean;
 Begin
  If Isa8088 Then
   Isa80386:=False
  Else
  Begin
   Valid_Op_Code:=True;
   GetIntVec(6, @OldIntr6Handler);
   SetIntVec(6, Addr(Intr6Handler));
   inline($0F/$20/$C2);  { mov edx, cr0 }
   SetIntVec(6, @OldIntr6Handler);
   Isa80386:=Valid_Op_Code;
  End;
 End;

 Function Isa80486: Boolean;
 Begin
  If Isa8088 Then
   Isa80486:=False
  Else
  Begin
   Valid_Op_Code:=True;
   GetIntVec(6, @OldIntr6Handler);
   SetIntVec(6, Addr(Intr6Handler));
   inline($0F/$C1/$D2);  { xadd dx, dx }
   SetIntVec(6, @OldIntr6Handler);
   Isa80486:=Valid_Op_Code;
  End;
 End;


Function CPUType: LongInt;
Begin
 If Isa8088 Then
  CPU:=CPU_8088
 Else If Isa80486 Then
  CPU:=CPU_80486
 Else If Isa80386 Then
  CPU:=CPU_80386
 Else If Isa80286 Then
  CPU:=CPU_80286
 Else If Isa80186 Then
  CPU:=CPU_80186
 Else
  CPU:=CPU_UNKNOWN;
 CPUType:=CPU;
End;

Function DVLoaded: Boolean;
Var
  R : Registers;
  VersionMj, VersionMn : byte;
  installed : boolean;

Begin
  installed := false;
  With R do
  Begin
    ah := $2B;
    cx := $4445; {'DE'}
    dx := $5351; {'SQ'}
    al := $01;   {sub func for get version}
    MsDos(R);
    if al = $FF then installed := False
    else
      begin
        installed := true;
        VersionMj := bh; VersionMn := bl
      end
  end;
  DVLoaded:=Installed;
End;

Function WinLoaded: Boolean;
Var
  R : Registers;
  StatusAL: Byte;
Begin
  R.ax:=$1600;
  Intr($2F,r);
  statusAL := r.al;
  WinLoaded:=(StatusAL<>0);
End;

Function OS2Loaded: Boolean;
Var R: Registers;
    Tmp: Integer;
    St: String;
Begin
 With R Do
  Begin
   ah:=$64;
   dx:=$8;
   cx:=$636C;
   bx:=$0;
  End;
 Intr($21,R);
 St:='';
 For Tmp:=1 To 8 Do
  St:=St+Chr(Mem[R.DS:R.DX+Tmp-1]);
 OS2Loaded:=(St='Loading.');
End;

Function CountryData(Var Currency,DateFormat: String;                     {|}
                     Var Thousands,Decimal,DateSep,TimeSep,DataSep: Char; {|}
                     Var CurrencyPlaces,TimeFormat: Byte): Boolean;       {|}
                                                                          {|}
Const                                                                     {|}
 Date_USA    = 0; { mm+dd+yy }                                            {|}
 Date_Europe = 1; { dd+mm+yy }                                            {|}
 Date_Japan  = 2; { yy+mm+dd }                                            {|}
 Time_12Hour = 0;                                                         {|}
 Time_24Hour = 1;                                                         {|}
                                                                          {|}
Type                                                                      {|}
 CountryInfo = Record                                                     {|}
        ciDateFormat    : Word;                                           {|}
        ciCurrency      : Array [1..5] Of Char;                           {|}
        ciThousands     : Char;                                           {|}
        ciASCIIZ_1      : Byte;                                           {|}
        ciDecimal       : Char;                                           {|}
        ciASCIIZ_2      : Byte;                                           {|}
        ciDateSep       : Char;                                           {|}
        ciASCIIZ_3      : Byte;                                           {|}
        ciTimeSep       : Char;                                           {|}
        ciASCIIZ_4      : Byte;                                           {|}
        ciBitField      : Byte;                                           {|}
        ciCurrencyPlaces: Byte;                                           {|}
        ciTimeFormat    : Byte;                                           {|}
        ciCaseMap       : Procedure;                                      {|}
        ciDataSep       : Char;                                           {|}
        ciASCIIZ_5      : Byte;                                           {|}
        ciReserved      : Array [1..10] Of Byte                           {|}
       End;                                                               {|}
Var                                                                       {|}
 Country: CountryInfo;                                                    {|}
                                                                          {|}
Function GetCountryInfo(Buf: Pointer): Boolean; Assembler;                {|}
Asm                                                                       {|}
    mov  ax, 3800h                                                        {|}
    push ds                                                               {|}
    lds  dx, Buf                                                          {|}
    int  21h                                                              {|}
    mov  al, TRUE                                                         {|}
    jnc  @@1                                                              {|}
    xor  al, al                                                           {|}
@@1:                                                                      {|}
    pop  ds                                                               {|}
End;                                                                      {|}
                                                                          {|}
Begin                                                                     {|}
 If Not GetCountryInfo (@Country) Then                                    {|}
  Begin                                                                   {|}
   Country.ciDateFormat:=DATE_USA;                                        {|}
   Country.ciDateSep:='-';                                                {|}
   Country.ciTimeFormat:=TIME_12HOUR;                                     {|}
   Country.ciTimeSep:=':';                                                {|}
   CountryData:=False;                                                    {|}
  End;                                                                    {|}
 Currency:=Country.ciCurrency[1]+Country.ciCurrency[2]+                   {|}
           Country.ciCurrency[3]+Country.ciCurrency[4]+                   {|}
           Country.ciCurrency[5];                                         {|}
 Thousands:=Country.ciThousands;                                          {|}
 Decimal:=Country.ciDecimal;                                              {|}
 DateSep:=Country.ciDateSep;                                              {|}
 TimeSep:=Country.ciTimeSep;                                              {|}
 DataSep:=Country.ciDataSep;                                              {|}
                                                                          {|}
 Case Country.ciDateFormat Of                                             {|}
   Date_USA   : DateFormat:='mm'+DateSep+'dd'+DateSep+'yy';               {|}
   Date_Europe: DateFormat:='dd'+DateSep+'mm'+DateSep+'yy';               {|}
   Date_Japan : DateFormat:='yy'+DateSep+'mm'+DateSep+'dd';               {|}
  End;                                                                    {|}
 Case Country.ciTimeFormat Of                                             {|}
   Time_12Hour: TimeFormat:=12;                                           {|}
   Time_24Hour: TimeFormat:=24;                                           {|}
  End;                                                                    {|}
 CurrencyPlaces:=Country.ciCurrencyPlaces;                                {|}
 CountryData:=True;                                                       {|}
End;                                                                      {|}

Function ResolvePath(Var S: String): Boolean;
Var
  R: Registers;
  X: Byte;
Begin
 ResolvePath:=False;
 S:=S+#0;
 R.DS:=Seg(S);
 R.SI:=Ofs(S)+1;
 R.ES:=Seg(S);
 R.DI:=Ofs(S)+1;
 R.AH:=$60;
 Intr($21,R);
 If R.Flags And 1 = 1 Then
  Exit; { If ZF set then error }
 ResolvePath:=True;
 X:=0;
 While (s[x+1]<>#0) And (x<128) Do
  Inc(X);
 S[0]:=Chr(X);
End;

Function DriveInfo(Var FAT,SerNo: LongInt): Boolean;
Var
 Regs     : Registers;
 LabelInfo: Record
       InfoLevel      : Word;
       SerialNum      : LongInt;
       VolumeLabel    : Array [1..11] of Char;
       FileSystemType : Array [1..8] of Char;
     end;
Begin
 If Lo(DosVersion)<4 Then Begin DriveInfo:=False; Exit; End;
 LabelInfo.InfoLevel := 0;
 With Regs do
  Begin
   AX:=$6900;           { Function $69 With 0 in AL gets, With 1 in AL sets}
   BL:=0;               { Drive, 0 For default, 1 For A:, 2 For B:, ...    }
   DS:=Seg(LabelInfo);  { DS:DX points at structure                        }
   DX:=Ofs(LabelInfo);
   ES:=0;               { Do not have garbage in segment Registers         }
   Flags:=0;            { or in flags                                      }
   MsDos(Regs);
   If Odd(Flags) Then Begin DriveInfo:=False; Exit; End;
  End;
 FAT:=IntVal(Copy(LabelInfo.FileSystemType,4,2));
 SerNo:=LabelInfo.SerialNum;
End;

Procedure CD_ROMData(Var DrvCount: Word; Var FirstDrv: Char;
                     Var IsMSCDEX, IsCDROM: Boolean);
Var Reg : Registers;
Begin
 FirstDrv  := #0;
 IsMSCDEX  := FALSE;
 IsCDROM   := FALSE;
 Reg.AX := $1500;
 Reg.BX := 0;
 Intr ($2F, Reg);                { invoke MSCDEX               }
 DrvCount := Reg.BX;
 IF (DrvCount = 0) THEN EXIT;
 FirstDrv := CHR (Reg.CX + 65);  { first drive IN ['A'..'Z']   }
 Reg.AX := $150B;                { fn: CD-ROM drive check      }
 Reg.BX := 0;                    { Reg.CX already has drive #  }
 Intr ($2F, Reg);
 IF (Reg.BX <> $ADAD) THEN EXIT; { MSCDEX isn't installed      }
 IsMSCDEX := TRUE;
 IF (Reg.AX = 0) THEN EXIT;      { ext. drive isn't a CD-ROM   }
 IsCDROM := TRUE;
End;

Function CoProcessorExist: Boolean;
Begin CoProcessorExist:=(EquipFlag And 2)=2; End;

Function NumPrinters: Word;
Begin NumPrinters:=EquipFlag Shr 14; End;

Function GameIOAttached: Boolean;
Begin GameIOAttached:=(EquipFlag And $1000)=1; End;

Function NumSerialPorts: Integer;
Begin NumSerialPorts:=(EquipFlag Shr 9) And $07; End;

Function NumDisketteDrives: Integer;
Begin NumDisketteDrives := ((EquipFlag And 1) * (1+(EquipFlag Shr 6) And $03)); End;

Function InitialVideoMode: Integer;
Begin InitialVideoMode:=(EquipFlag Shr 4) And $03; End;

Function PrinterOnline: Boolean;
Begin
 If (Port[$379] And 16)<>16 Then
  PrinterOnline:=False
 Else
  PrinterOnline:=True;
End;

Function AdlibCard: Boolean;
Var Val1,Val2: Byte;
Begin
 Port[$388]:=4; Delay(3); Port[$389]:=$60; Delay(23); Port[$388]:=4; Delay(3);
 Port[$389]:=$80; Delay(23); Val1:=Port[$388]; Port[$388]:=2; Delay(3);
 Port[$389]:=$FF; Delay(23); Port[$388]:=4; Delay(3); Port[$389]:=$21; Delay(85);
 Val2:=Port[$388]; Port[$388]:=4; Delay(3); Port[$389]:=$60; Delay(23);
 Port[$388]:=4; Delay(3); Port[$389]:=$80;
 If ((Val1 And $E0)=0) And ((Val2 And $E0)=$C0) Then
  AdlibCard:=True
 Else
  AdlibCard:=False;
End;

Function TrueDosVer: Word; Assembler;
Asm
    mov     ax,3306h
    int     21h
    mov     ax,bx
End;

Function NetworkDrive(Drive: Char; Var DOSErrorCode: Word): Boolean;
Var Reg: Registers;
Begin
 Drive:=UpCase (Drive);
 If (Drive In ['A'..'Z']) Then
  Begin
   Reg.BL:=ORD(Drive) - 64;
   Reg.AX:=$4409;
   MsDos (Reg);
   If Odd(Reg.Flags) Then
    DosErrorCode:=Reg.AX
   Else
   Begin
    DosErrorCode:=0;
    If Odd(Reg.DX SHR 12) Then
     NetworkDrive:=True
    Else
     NetworkDrive:=False;
   End;
  End;
End;

Function OpModeCheck: Integer;
Begin
 asm
   mov  ax,   $4680
   int  $2f
   mov  dl,   $1
   or   ax,   ax
   jz   @finished
   mov  ax,   $1600
   int  $2f
   mov  dl,   $2
   or   al,   al
   jz   @Not_Win
   cmp  al,   $80
   jne  @finished
  @Not_Win:
   mov  ax,   $1022
   mov  bx,   $0
   int  $15
   mov  dl,   $3
   cmp  bx,   $0a01
   je   @finished
   xor  dl,   dl
  @finished:
   xor  ah,   ah
   mov  al,   dl
   mov  @Result, ax
 End;
End;

Function UART(ComX: Byte): String;
Const
 ComPortText: Array[0..4] of String[11] =
         ('N/A',
          '8250/8250B',
          '8250A/16450',
          '16550A',
          '16550N');
 IIR     = 2;
 SCRATCH = 7;

Var
 PortAdr    : Array[1..4] of Word absolute $40:0;
 ComPortType: Byte;
Begin
 ComPortType:=0;
 If (PortAdr[ComX] =0) Or (Port[PortAdr[ComX]+ IIR ] And $30 <> 0) Then
  Begin
   UART:=ComPortText[ComPortType];                   {No comport!}
   Exit;
  End;
 Port[PortAdr[ComX]+IIR]:=1;                         {Test: enable FIFO}
 If (Port[PortAdr[ComX]+IIR] And $C0) = $C0 Then     {enabled?}
  ComPortType:=3 Else
 If (Port[PortAdr[ComX]+IIR] and $80) = $80 Then     {16550, old version}
  ComPortType:=4 Else
 Begin
  Port[Portadr[ComX]+SCRATCH]:=$AA;
  If Port [Portadr[ComX]+SCRATCH]=$AA Then           {w/scratch reg. ?}
   ComPortType:=2
  Else
   ComPortType:=1;
 End;
 UART:=ComPortText[ComPortType];
End;

Function LPTAddr(LPTX: Byte): Word;
Begin
 If LPTX in [1..3] Then
  LPTAddr:=MemW[$40:6+(LPTX*2)]
 Else
  LPTAddr:=0;
End;

Function BaseAddr(ComX: Byte): Word;
Begin
 If ComX in [1..4] Then
  BaseAddr:=MemW[$40:(ComX-1) SHL 1]
 Else
  BaseAddr:=0;
End;

Function PortRate(ComPort: Word; Var Baud: LongInt): Boolean;
Const
 DLAB = $80;                       { divisor latch access bit    }
Var
 BaseIO,                           { COM base i/o port address   }
 BRGdiv,                           { baud rate generator divisor }
 regDLL,                           { BRG divisor, latched LSB    }
 regDLM,                           { BRG divisor, latched MSB    }
 regLCR: Word;                     { line control register       }
Begin
 Baud:=0;                                  { assume nothing      }
 If (ComPort In [1..4]) Then               { must be 1..4        }
  Begin
   BaseIO:=MemW[$40:(ComPort-1) SHL 1];    { fetch base i/o port }
   If (BaseIO <> 0) Then                   { has BIOS seen it?   }
    Begin
     regDLL:=BaseIO;                       { BRGdiv, latched LSB }
     regDLM:=BaseIO+1;                     { BRGdiv, latched MSB }
     regLCR:=BaseIO+3;                     { line control reg    }
     Port[regLCR]:=Port[regLCR] Or DLAB;           { set DLAB    }
     BRGdiv:=WORD(Port[regDLL]);                   { BRGdiv LSB  }
     BRGdiv:=BRGdiv Or WORD(Port[regDLM]) SHL 8;   { BRGdiv MSB  }
     Port[regLCR]:=Port[regLCR] And Not DLAB;      { reset DLAB  }
     If (BRGdiv <> 0) Then
      Baud:=1843200 Div (LONGINT(BRGdiv) SHL 4);     { calc bps  }
    End;
  End;
 PortRate:=(Baud<>0);
End;

Function PortInfo(ComX: Byte; Var DataBits,StopBits,Parity: Byte): Boolean;
Var
 B,S,CO: Integer;
 ComList: Array[1..4] Of Word ABSOLUTE $0000:$0400;
Begin
 CO:=ComList[ComX];
 If CO=0 Then
  PortInfo:=False
 Else
  PortInfo:=True;
 S:=Port[CO+3];
 If (S And 3)=3 Then
  B:=8 Else
 If (S And 2)=2 Then
  B:=7 Else
 If (S And 1)=1 Then
  B:=6 Else B:=5;
 DataBits:=B;
 If (S And 4)=4 Then
  B:=2
 Else
  B:=1;
 StopBits:=B;
 If (S And 24)=24 Then
  Parity:=2 Else { Even }
 If (S And 8)=8 Then
  Parity:=1 Else { Odd }
 Parity:=0;      { None}
End;

{$ENDIF}

{$IFDEF Useless}
Function ReadChar(Pattern: Integer): Char;
Const
 NumLock = 32;
 CapsLock = 64;
 ScrlLock = 16;
var
 Status : byte;
 i: Integer;
begin
    Status := (Mem[$0000:$0417] and 176);
    I:=1;
    If Pattern=1 Then
     Begin
      Repeat;
       If I=1 Then Mem[$0000:$0417] := NumLock;
       If I=2 Then Mem[$0000:$0417] := CapsLock;
       If I=3 Then Mem[$0000:$0417] := ScrlLock;
       Inc(I);
       If I=4 then I:=1;
       CDelay(500);
      Until (keypressed);
     End;
    If Pattern=2 Then
     Begin
      Repeat;
       If I=3 Then Mem[$0000:$0417] := NumLock;
       If I=2 Then Mem[$0000:$0417] := CapsLock;
       If I=1 Then Mem[$0000:$0417] := ScrlLock;
       Inc(I);
       If I=4 then I:=1;
       CDelay(500);
      Until (keypressed);
     End;
    If Pattern=3 Then
     Begin
      Repeat;
       If I=1 Then Mem[$0000:$0417] := NumLock+ScrlLock;
       If I=2 Then Mem[$0000:$0417] := CapsLock;
       Inc(I);
       If I=3 then I:=1;
       CDelay(500);
      Until (keypressed);
     End;
    If Pattern=4 Then
     Begin
      Repeat;
       If I=1 Then Mem[$0000:$0417] := NumLock+ScrlLock+CapsLock;
       If I=2 Then Mem[$0000:$0417] := 0;
       Inc(I);
       If I=3 then I:=1;
       CDelay(500);
      Until (Keypressed);
     End;
    Mem[$0000:$0417] := Status;           { restore old Locks               }
    ReadChar:=ReadKey;
End;

Procedure MoveLong(FromP: Pointer; ToP: pointer; Len: longint);
type
   longtype        = array[1 .. 63 * 1024] of char;
   longtypeptr     = ^ longtype;
   ptrrec          = record
      ofs, seg     : word; end;
const
   longtypelen     = sizeof(longtype);
begin
   { fix the pointers: offsets between 0 and 15 }
   inc(ptrrec(fromp).seg, ptrrec(fromp).ofs div 16);
   ptrrec(fromp).ofs := ptrrec(fromp).ofs and 15;
   inc(ptrrec(top).seg, ptrrec(top).ofs div 16);
   ptrrec(top).ofs := ptrrec(top).ofs and 15;

   { move pieces }
   while len > sizeof(longtype) do begin
      { faster than: move(fromp^, top^, sizeof(longtype)); }
      asm
         push    ds
         lds     si,fromp
         les     di,top
         mov     cx,(longtypelen / 2)
         cld
         rep     movsw
         pop     ds
      end;
      dec(len, sizeof(longtype));
      inc(ptrrec(fromp).seg, sizeof(longtype) div 16);
      inc(ptrrec(top).seg, sizeof(longtype) div 16);
   end;
   if len <> 0 then
      { faster than: move(fromp^, top^, len); }
      asm
         push    ds
         lds     si,fromp
         les     di,top
         mov     cx,word(len)
         shr     cx, 1
         cld
         jnc     @wordmove
         movsb
      @wordmove:
         rep     movsw
         pop     ds
      end;
end;

Procedure RAMShot(FN: String);
Const
 TotalRAM = 640;
Var
 Index    : Word;
 PhotoFile: File;
Begin
 Index := 0;
 Assign(PhotoFile,FN);
 ReWrite(PhotoFile,1);
 For Index:=0 To ((TotalRAM DIV $40) - $1) Do
  Begin
   BlockWrite(PhotoFile,Ptr(Index,$0000)^,$8000);
   BlockWrite(PhotoFile,Ptr(Index,$8000)^,$8000)
  End;
 Close(PhotoFile)
End;

Procedure Init_Box(Text1, Text2, Text3: String);
Var
 Text_Buf: Array[1..3] Of String[60];
 MaxLen: Integer;
 Spaces: Integer;
 Count: Integer;
 Lines: Integer;
 Count2: Integer;
Begin
 Text_Buf[1]:=Text1;
 Text_Buf[2]:=Text2;
 Text_Buf[3]:=Text3;
 If Odd(Length(Text_Buf[1])) Then Text_Buf[1]:=Text_Buf[1]+' ';
 If Odd(Length(Text_Buf[2])) Then Text_Buf[2]:=Text_Buf[2]+' ';
 If Odd(Length(Text_Buf[3])) Then Text_Buf[3]:=Text_Buf[3]+' ';
 MaxLen:=Length(Text_Buf[1]);
 If Length(Text_Buf[2])>MaxLen Then MaxLen:=Length(Text_Buf[2]);
 If Length(Text_Buf[3])>MaxLen Then MaxLen:=Length(Text_Buf[3]);
 Lines:=0;
 If Text_Buf[1]='' Then Exit;
 Inc(Lines);
 If Text_Buf[2]<>'' Then Inc(Lines);
 If Text_Buf[3]<>'' Then Inc(Lines);
 MaxLen:=MaxLen+2;
 Spaces:=40-(MaxLen DIV 2);
 GotoXY(Spaces,10-Lines);
 TextColor(1);
 Write('Ú'); For Count:=1 To MaxLen Do Write('Ä'); Write('¿');
 GotoXY(Spaces,11-Lines);
 For Count:=1 To Lines Do
  Begin
   Write('³');
   TextColor(15);
   For Count2:=1 To (MaxLen-Length(Text_Buf[Count])) DIV 2 Do Write(' ');
   Write(Text_Buf[Count]);
   For Count2:=1 To (MaxLen-Length(Text_Buf[Count])) DIV 2 Do Write(' ');
   TextColor(1);
   Write('³');
   GotoXY(Spaces,11-Lines+Count);
  End;
 Write('À'); For Count:=1 To MaxLen Do Write('Ä'); Write('Ù');
End;

Procedure Copy_File(Source, Dest: String; Display: Boolean; VAR Success: Boolean);
Var
  Buf: Array[1..2048] of Char;
  FromF, ToF: file;
  NumRead, NumWritten: Word;
Begin
  If Display=True Then Save_Screen;
  If Display=True Then Init_Box('Copying File:',Source+' => '+Dest,'Please wait...');
  Assign(FromF,Source);
  {$I-} Reset(FromF, 1); {$I+}
  If IOResult<>0 Then
   Begin
    If Display=True Then
     Begin
      Restore_Screen;
      Save_Screen;
      Init_Box('Error opening file:',Source,'Copy aborted.');
      CDelay(5000);
      Restore_Screen;
     End;
    Success:=False;
    Exit;
   End;
  Assign(ToF, Dest);
  {$I-} Rewrite(ToF, 1); {$I+}
  If IOResult<>0 Then
   Begin
    If Display=True Then
     Begin
      Restore_Screen;
      Save_Screen;
      Init_Box('Error creating destination file:',Dest,'Copy aborted.');
      CDelay(5000);
      Restore_Screen;
     End;
    Success:=False;
    Exit;
   End;
  Repeat
    BlockRead(FromF,buf,
              SizeOf(buf),NumRead);
    BlockWrite(ToF,buf,NumRead,NumWritten);
  Until (NumRead = 0) or
        (NumWritten <> NumRead);
  Close(FromF);
  Close(ToF);
  Success:=True;
  If Display=True Then Restore_Screen;
End;

{ For ExecWin below }
Procedure Int29Handler(AX,BX,CX,DX,SI,DI,DS,ES,BP: Word); Interrupt;
Var Dummy: Byte; Begin Write(Chr(Lo(AX))); Asm Sti; End; End;


Function ExecWin(ProgName,Params: String;
                 LeftCol,TopLine,RightCol,BottomLine: Word): Word;
Var A: Word;
Begin
 GotoXY(LeftCol, TopLine);
 Write(Chr(201));
 For A:=1 To (RightCol-LeftCol)-1 Do Write(Chr(205));
 Write(Chr(187));
 For A:=1 To (BottomLine-TopLine)-1 Do
  Begin
   GotoXY(LeftCol,TopLine+A);
   Write(Chr(186));
   GotoXY(RightCol,TopLine+A);
   Write(Chr(186));
  End;
 GotoXY(LeftCol,BottomLine); Write(Chr(200));
 For A:=1 To (RightCol-LeftCol)-1 Do Write(Chr(205));
 Write(Chr(188));
 Window(LeftCol+1,TopLine+1,RightCol-1, BottomLine-1);
 ClrScr;
 GotoXY(1,1);
 GetIntVec($29,OldIntVect29);
 SetIntVec($29,@Int29Handler);
 {.$M 10000,0,0}
 SwapVectors; Exec(ProgName,Params); SwapVectors;
 ExecWin:=DOSExitCode;
 SetIntVec($29,OldIntVect29);
 Window(LeftCol,TopLine,RightCol,BottomLine); ClrScr; Window(1, 1, 80, 25);
End;

Function ExecWin2(ProgName,Params: String;
                 LeftCol,TopLine,RightCol,BottomLine: Word): Word;
Var A: Word;
    OldAttr: Byte;
Begin
 OldAttr:=TextAttr;
 Window(LeftCol,TopLine,RightCol, BottomLine);
 ClrScr;
 GotoXY(1,1);
 GetIntVec($29,OldIntVect29);
 SetIntVec($29,@Int29Handler);
 {.$M 10000,0,0}
 SwapVectors; Exec(ProgName,Params); SwapVectors;
 ExecWin2:=DOSExitCode;
 SetIntVec($29,OldIntVect29);
 TextAttr:=OldAttr;
 Window(LeftCol,TopLine,RightCol,BottomLine); ClrScr; Window(1, 1, 80, 25);
End;

Function CvtToReal(LngInt: LongInt): Real;
Begin
 CvtToReal:=LngInt;
End;

Function CvtToWord(RealToRound: Real): Word;
Begin
 If RealToRound>65535 Then RealToRound:=65535;
 CvtToWord:=Trunc(RealToRound);
End;

Function CvtToInt(RealToRound: Real): Integer;
Begin
 If RealToRound>32767 Then RealToRound:=32767;
 CvtToInt:=Trunc(RealToRound);
End;

Function CvtToLInt(RealToRound: Real): LongInt;
Begin
 If RealToRound>2147483647 Then RealToRound:=2147483647;
 CvtToLInt:=Trunc(RealToRound);
End;

Function CvtToByte(IntToRound: Integer): Byte;
Begin
 If IntToRound>255 Then IntToRound:=255;
 CvtToByte:=IntToRound;
End;

Function WordToInt(WordToRound: Word): Integer;
Begin
 If WordToRound>32767 Then WordToRound:=32767;
 WordToInt:=WordToRound;
End;

Function RoundOff(RealToRound: Real): Real;
Begin
 RoundOff:=Int(RealToRound);
End;

Function WordVal(ChrStr: String): Word;
Var TW: Integer;
    Code: Word;
Begin
 Val(ChrStr,TW,Code);
 If Code<>0 Then TW:=-1;
 WordVal:=TW;
End;

{$ENDIF}

End.

