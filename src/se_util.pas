Unit SE_Util;
{$DEFINE CompileExtra}
{.$DEFINE SpellChecker}
{$I DEFINES.INC}
{$D-}
Interface

uses dos;

Function Timer: Real;
Procedure XSWrite(S: String);
Procedure XSWriteLn(S: String);
Function NoPipe(S: String): String;
Function Encode(S: String; Wid: Byte): String;
Procedure FunkyWrite(S: String);
Procedure KeyDelay(D: Word);
Function LongRandom(Max: LongInt): LongInt;
Function GetCurrDate: String;
Procedure LocalSetColor(Atr: Byte);
Procedure LocalFunkyWrite(S: String);
Procedure FunkyWriteLn(S: String);
Function Get_Key: Char;
Procedure SaveWin(X1,Y1,Wid,Hgt: Integer);
Procedure LoadWin(X1,Y1,Wid,Hgt: Integer);
Function GetTimeDate: String;
Procedure DInc(Var B: Byte);
Procedure DInc2(Var B: Byte);
Function LowInt(B: Byte): Byte;
Procedure Box(Wid,Len: Byte; Remote: Boolean);
Function Initials(S: String): String;
Procedure GetAttrChar(Var SAttr: Integer; Var SChar: Char);
Function HackPrevent(S: String): String;
Procedure FancyClear;
Procedure FixChainsaw;
Procedure ResetUser;
Procedure LoadUser;
Function SpellCheck: Boolean;
Procedure Scroll_Screen(Lines: Integer);
Procedure Refresh_Screen;
Procedure Set_PhyLine;
Procedure Cursor_Down(Force: Boolean);
Procedure Cursor_Up;
Procedure Cursor_Left;
Procedure Reposition;                     { Update physical cursor position }
Procedure Count_Lines;
Function CurLength: Integer;
Procedure RepoNoEOL;
Procedure Update_Eol;            { Update screen after changing End-of-Line }
Function CurChar: Char;
Procedure Split_Line;              { Splits the current line at the Cursor, }
Procedure Join_Lines;  { Join current line with following line, if possible }
Procedure Insert_Line(Contents: String);
Procedure Cursor_Right;
Procedure Remove_Trailing;
Procedure Append_Space;
Procedure Word_Wrap;       { Line is full and a character must be inserted. }
Procedure Cursor_NewLine;
Procedure Delete_Line;
Procedure Insert_Char(C: Char);  { Insert character at the cursor position, }
Procedure Delete_Char;
Procedure StatTimeUpdate;
Procedure StatusBar;
Function GetLow: Char;
Function PageNum: String;
Procedure AbortDisabled;
Procedure MinLinesNotMet;
Procedure Prepare_Screen;
Procedure Display_Message_Header;
Function LS(Num: Word): String;
Function LoadS: String;
Procedure XRename(N1,N2: String);
Procedure Cursor_EndLine;
Procedure Display_Footer(B: Byte);
Procedure Plain_Footer(B: Byte);
Procedure DisplayFooterTime;
Function Expired: Boolean;

{$I SEDIT.INC}

Type
 Str20          = String[20];
 Str35          = String[35];
 Str81          = String[255];  { max line length - wraps at window width (was 81 for the fixed 80-col screen) }
 PhysType       = Array[1..200] of Str81;
 ACType         = Record A: Byte; C: Char; End;
 WinData        = Array[0..79,0..24] Of ACType;
 LangType       = Array[1..LangCnt] Of String[75];

Const
 InternalLineLim = 4000;
 DelimiterChars = [#32..#47,#91..#96,#123..#255];
 TopScreen      : Word = 1;              { First screen line for text entry }
 ScrLines       : Word = 21;        { Number of screen lines for text entry }
 PageUpDnSiz    : Word = 21;   { Number of lines to scroll by during PgUp/Dn }
 FootRow        : Word = 25;
 PromptRow      : Word = 24;
 Max_Msg_Lines  : Word = InternalLineLim;
 Insert_Mode    : Boolean = True;
 Only2MinMsg    : Boolean = False;
 Only1MinMsg    : Boolean = False;
 Force          : Boolean = False;
 ForceLines     : Byte = 0;
 WWrap          : Byte = 78;
 HighAsciiColor = 8;
 DigitColor     = 11;
 LowCaseColor   = 7;
 UpCaseColor    = 15;
 SymbolColor    = 9;
 StatBar        : Byte = 1;
 InputFunky     : Boolean = False;
 PF_overridepos : Byte = 0;
 OKPageNum      : Boolean = True;
 TimeUpdated    : Boolean = False;
 OKUpdateFooter : Boolean = False;
 HasAddedSig    : Boolean = False;

Var
{ Footer         : Array[1..2] Of String[250];}
 PlainFooter    : Array[1..2] Of String[250];
 MsgTxtFile     : String;
 LastAutoSave   : Real;
 LastStatTime   : Real;
 QuoteOrMenu    : String[30];
 CfgPath        : String[126];
 DecryptKey     : String;
 Config         : ^ConfigRec;
 ConfigFile     : File Of ConfigRec;
 User           : UserRec;
 UserFile       : File Of UserRec;
 Last           : Byte;
 NC,HC,BC,PC,FZ,
 FC,FL,FS,FD,IC,
 IL,IS,ID       : String[15];
 YN             : Array[False..True] Of String[20];
 WinRec         : ^WinData;
 ExitSave       : Pointer;
 TopLine,
 CLine,
 CCol           : Integer;
 MNum,
 Linenum,LineCnt,
 A,N            : Word;
 PhyLine        : ^PhysType;
 ToInitials     : String[2];
 Par,
 Tmp            : String;
 LastWasCR,
 ForceMenu      : Boolean;
 MText          : Array[1..InternalLineLim] of ^Str81;
 MsgTmp,F       : Text;
 MC             : Char;
 MsgAreaPos,
 UIDX           : LongInt;
 ReEditing,
 LocalKeypress  : Boolean;
 SigFile        : File Of SigType;
 Sig            : SigType;
 Lang           : ^LangType;
 MemLang        : Boolean;
 Danger         : Byte;
 LanguageFile   : String[8];
 CurrTimeX,
 CurrTimeY,
 UserTimeX,
 UserTimeY      : Byte;
 XtraTxt        : Text;
 XtraS          : String[127];
Implementation

Uses Utilpack,TurboCOM,ScreenIO,RCRC32;

Function Timer: Real;
Var H,M,S,S100: Word;
Begin
 GetTime(H,M,S,S100);
 Timer:=H*3600.0+M*60.0+S+S100/100.0;
End;

Procedure XSWrite(S: String);
Var I: Byte;
    IxD: String[2];
    Code: String[15];
Begin
 While Pos('|',S)>0 Do
  Begin
   I:=Pos('|',S);
   Delete(S,I,1);
   IxD:=Copy(S,I,2);
   Delete(S,I,2);
   If IxD='NC' Then Insert(NC,S,I) Else
   If IxD='HC' Then Insert(HC,S,I) Else
   If IxD='BC' Then Insert(BC,S,I) Else
   If IxD='PC' Then Insert(PC,S,I) Else
   If IxD='FZ' Then Insert(FZ,S,I) Else
   If IxD='FC' Then Insert(FC,S,I) Else
   If IxD='FL' Then Insert(FL,S,I) Else
   If IxD='FS' Then Insert(FS,S,I) Else
   If IxD='FD' Then Insert(FD,S,I) Else
   If IxD='IC' Then Insert(IC,S,I) Else
   If IxD='IL' Then Insert(IL,S,I) Else
   If IxD='ID' Then Insert(ID,S,I) Else
   If IxD='IS' Then Insert(IS,S,I) Else
   If (IxD[1] in ['0'..'9','A'..'F']) And
      (IxD[2] in ['0'..'9','A'..'F']) Then
       Begin
        If IxD[1]='0' Then
         Insert(ANSICode[IntVal('$'+IxD)],S,I)
        Else
        Begin
         If (IxD[2]='0') Then
          Begin
           Code:=ANSICode[40+IntVal('$'+IxD[1])];
           Insert('0;30;',Code,3);
           Insert(Code,S,I);
          End
         Else
          Insert(ANSICode[IntVal('$'+IxD[2])]+ANSICode[40+IntVal('$'+IxD[1])],S,I);
        End;
       End;
  End;
 SWrite(S);
End;

Procedure XSWriteLn(S: String);
Begin
 XSWrite(S+#13+#10);
End;

Function NoPipe(S: String): String;
Var I: Byte;
Begin
 While Pos('|',S)>0 Do
  Begin
   I:=Pos('|',S);
   Delete(S,I,3);
  End;
 NoPipe:=S;
End;

Function Encode(S: String; Wid: Byte): String;
Var
 Tmp: Byte;
 Out: String;
 Typ: Byte;
Begin
 Typ:=0;
 Out:='';
 If Length(S)>Wid-2 Then
  Begin
   S[0]:=Chr(Wid-3);
   S:=S+'¯';
  End;
 S:=' '+Pad(S,Wid-1);
 For Tmp:=1 To Length(S) Do
  Begin
   Case S[Tmp] Of
     'A'..'Z': If Typ<>1 Then Begin Typ:=1; Out:=Out+'|IC'; End;
     'a'..'z': If Typ<>2 Then Begin Typ:=2; Out:=Out+'|IL'; End;
     '0'..'9': If Typ<>3 Then Begin Typ:=3; Out:=Out+'|ID'; End;
     Else      If Typ<>4 Then Begin Typ:=4; Out:=Out+'|IS'; End;
    End;
   Out:=Out+S[Tmp];
  End;
 S:=Out+'[0m';
 Encode:=S;
End;

Procedure FunkyWrite(S: String);
Var
 Ct: Integer;
 Out: String;
 Attr: Byte;
Begin
 Attr:=0;
 Out:='';
 For Ct:=1 To Length(S) Do
  Begin
   Case S[Ct] of
     'A'..'Z': If Attr<>1 Then
                Begin
                 If Length(Out)>248 Then Begin SWrite(Out); Out:=''; End;
                 If InputFunky Then Out:=Out+IC Else Out:=Out+FC; Attr:=1;
                End;
     'a'..'z': If Attr<>2 Then
                Begin
                 If Length(Out)>248 Then Begin SWrite(Out); Out:=''; End;
                 If InputFunky Then Out:=Out+IL Else Out:=Out+FL; Attr:=2;
                End;
     '0'..'9': If Attr<>3 Then
                Begin
                 If Length(Out)>248 Then Begin SWrite(Out); Out:=''; End;
                 If InputFunky Then Out:=Out+ID Else Out:=Out+FD; Attr:=3;
                End;
     ' '     : ;
     Else      If Attr<>4 Then
                Begin
                 If Length(Out)>248 Then Begin SWrite(Out); Out:=''; End;
                 If InputFunky Then Out:=Out+IS Else Out:=Out+FS; Attr:=4;
                End;
    End;
   Out:=Out+S[Ct];
  End;
 SWrite(Out);
 InputFunky:=False;
End;

Function HackPrevent(S: String): String;
Var Tmp: Byte;
Begin
 For Tmp:=1 To Length(S) Do
  S[Tmp]:=Chr(Ord(S[Tmp])-Ord(S[0]));
 HackPrevent:=S;
End;

Procedure KeyDelay(D: Word);
Var CTime: Real;
Begin
 CTime:=Timer+(D / 1000);
 Repeat Until (Timer>=CTime) Or (Local_Keypressed Or Remote_Keypressed)
End;

Function LongRandom(Max: LongInt): LongInt;
Var L: LongInt;
Begin
 L:=LONGINT(Random(46340)+1)*LONGINT(Random(46340)+1);
 If Max<>0 Then
  LongRandom:=L Mod Max
 Else
  LongRandom:=0;
End;

Function GetCurrDate: String;
Const
 MonthName: Array[1..12] Of String[12]=(
           'Jan', 'Feb', 'Mar', 'Apr', 'May',
           'Jun', 'Jul', 'Aug', 'Sep', 'Oct',
           'Nov', 'Dec');
Var
 D,M,Y,Dow,H,S,S100: Word;
 DStr: String;
Begin
 GetDate(Y,M,D,Dow);
 DStr:=LeadingZero(D);
 DStr:=DStr+'-'+MonthName[M]+'-'+StrVal(Y-1900); {-1900}
 GetTime(H,M,S,S100);
 DStr:=DStr+'  '+LeadingZero(H)+':'+LeadingZero(M);
 GetCurrDate:=DStr;
End;

Procedure LocalSetColor(Atr: Byte);
Begin
 If (LastSlice+Slicing<=Timer) Then ReleaseSlice;
 Case Chr(Atr) Of
   '0'..'9': TextColor(DigitColor);
   'a'..'z': TextColor(LowCaseColor);
   'A'..'Z': TextColor(UpCaseColor);
   Else      TextColor(SymbolColor);
  End;
End;

Procedure LocalFunkyWrite(S: String);
Var Ct: Integer;
Begin
 For Ct:=1 To Length(S) Do
  Begin
   If (LastSlice+Slicing<=Timer) Then ReleaseSlice;
   LocalSetColor(Ord(S[Ct])); SWrite(S[Ct]);
  End;
End;

Procedure FunkyWriteLn(S: String);
Begin
 If (LastSlice+Slicing<=Timer) Then ReleaseSlice;
 FunkyWrite(S);
 SWriteLn('');
End;

Procedure PerformAutoSave;
Var
 F: Text;
 A: Word;
Begin
 If Expired Then Exit;
 Assign(F,SysPath+'AUTOSAVE.SE!');
 ReWrite(F);
 WriteLn(F,'Message text preserved by Tie-EDIT AutoSave '+UnpackedDT(CurrentDT));
 WriteLn(F,'');
 For A:=1 To LineCnt Do WriteLn(F,MText[A]^);
 Close(F);
End;

Function Get_Key: Char;
Var
 Ch1         : Char;
 OrigUF      : Boolean;
Begin
 OrigUF:=OKUpdateFooter;
 Repeat
  If (TimeUpdated) And (OKUpdateFooter) Then
   Begin
    DisplayFooterTime;
    TimeUpdated:=False;
   End;
  If (LastStatTime<>Trunc(Nsl/60)) Then
   Begin
    StatTimeUpdate;
    LastStatTime:=Trunc(Nsl/60);
    TimeUpdated:=True;
    If OKUpdateFooter Then
     Begin
      DisplayFooterTime;
      TimeUpdated:=False;
     End;
   End;
  If (LastAutoSave+(2*60)<=Timer) Then
   Begin
    If Config^.AutoSave Then PerformAutoSave;
    LastAutoSave:=Timer;
   End;
  If (LastSlice+Slicing<=Timer) Then ReleaseSlice;
 Until (Remote_Keypressed) Or (Local_Keypressed);
 OKUpdateFooter:=OrigUF;
 If Remote_Keypressed Then
  Begin Ch1:=ReceiveChar(ComPort-1); Get_Key:=Ch1; LocalKeypress:=False; End
 Else
  Begin Ch1:=ReadKey; Get_Key:=Ch1; LocalKeypress:=True; End;
End;

Procedure GetAttrChar(Var SAttr: Integer; Var SChar: Char);
{ Was a BIOS "read char/attr under cursor" call - no equivalent without a
  real screen buffer. Stubbed pending the ncurses/Video-unit port. }
Begin
 SChar:=' '; SAttr:=7;
End;

Procedure SaveWin(X1,Y1,Wid,Hgt: Integer);
Var
 XCnt,YCnt,SAt: Integer;
 SCh: Char;
Begin
 New(WinRec);
 For YCnt:=0 To Hgt-1 Do
  For XCnt:=0 To Wid-1 Do
   Begin
    If (LastSlice+Slicing<=Timer) Then ReleaseSlice;
    GotoXY(X1+XCnt,Y1+YCnt); GetAttrChar(SAt,SCh);
    WinRec^[XCnt,YCnt].A:=SAt; WinRec^[XCnt,YCnt].C:=SCh;
   End;
End;

Procedure LoadWin(X1,Y1,Wid,Hgt: Integer);
Var
 XCnt,YCnt,
 OldF,OldB,
 CBack,CFore: Integer;
Begin
 CBack:=-1;
 OldF:=0; OldB:=0;
 For YCnt:=0 To Hgt-1 Do
  For XCnt:=0 To Wid-1 Do
   Begin
    If (LastSlice+Slicing<=Timer) Then ReleaseSlice;
    If Not ((WhereX=X1+XCnt) And (WhereY=Y1+YCnt)) Then SGotoXY(X1+XCnt,Y1+YCnt);
    CBack:=0;
    While WinRec^[XCnt,YCnt].A>=16 Do Begin Dec(WinRec^[XCnt,YCnt].A,16); Inc(CBack); End;
    CFore:=WinRec^[XCnt,YCnt].A;
    If (OldF<>CFore) Then Begin SWrite(ANSICode[CFore]); OldF:=CFore; End;
    If (OldB<>CBack) Then Begin STextBackground(CBack); OldB:=CBack; End;
    SWrite(WinRec^[XCnt,YCnt].C);
   End;
 Dispose(WinRec);
End;

Function GetTimeDate: String;
Const
 MonthName: Array[1..12] Of String[12]=(
           'Jan', 'Feb', 'Mar', 'Apr', 'May',
           'Jun', 'Jul', 'Aug', 'Sep', 'Oct',
           'Nov', 'Dec');
Var
 D,M,Y,Dow,H,S,S100: Word;
 DStr: String;
 PM: Boolean;
Begin
 PM:=False;
 GetDate(Y,M,D,Dow);
 Case Config^.DateFormat Of
   0: DStr:=LeadingZero(D)+'-'+MonthName[M]+'-'+StrVal(Y-1900);   {-1900}
   1: DStr:=LeadingZero(D)+'-'+LeadingZero(M)+'-'+StrVal(Y-1900); {-1900}
   2: DStr:=LeadingZero(M)+'-'+LeadingZero(D)+'-'+StrVal(Y-1900); {-1900}
  End;

 GetTime(H,M,S,S100);
 Case Config^.TimeFormat Of
   0: Begin
       if (H>12) Then Begin Dec(H,12); PM:=True; End;
       DStr:=DStr+' '+LeadingZero(H)+':'+LeadingZero(M);
       If PM Then DStr:=DStr+'pm' Else DStr:=DStr+'am';
      End;
   1: DStr:=DStr+' '+LeadingZero(H)+':'+LeadingZero(M);
  End;
 Encode(DStr,19); Delete(DStr,8,1); GetTimeDate:=DStr; { Added Delete(DStr,8,2) to format date Dec/05/00}
End;

Procedure DInc(Var B: Byte);
Begin
 Inc(B);
 If B>15 Then B:=1;
End;

Procedure DInc2(Var B: Byte);
Begin
 Inc(B);
 If B>7 Then B:=0;
End;

Function LowInt(B: Byte): Byte;
Begin
 If B>7 Then Dec(B,8);
 LowInt:=B;
End;

Procedure Box(Wid,Len: Byte; Remote: Boolean);
Var
 Tmp: Byte;
 X1,Y1,X2,Y2: Byte;
Begin
 If Remote Then SWrite(BC) Else TextAttr:=Config^.BC;
 If Remote Then SGotoXY(40-(Wid Div 2)-1-1,12-(Len Div 2)) Else GotoXY(40-(Wid Div 2)-1-1,12-(Len Div 2));
 If Remote Then SWrite('Ú'+MakeStr(Wid+2,#196)+'¿') Else Write('Ú'+MakeStr(Wid+2,#196)+'¿');
 For Tmp:=1 To Len Do
  Begin
   If Remote Then SGotoXY(40-(Wid Div 2)-1-1,12-(Len Div 2)+Tmp) Else GotoXY(40-(Wid Div 2)-1-1,12-(Len Div 2)+Tmp);
   If Remote Then SWrite('³'+Pad('',Wid+2)+'³') Else Write('³'+Pad('',Wid+2)+'³');
   If Remote Then SWrite('[1;30m') Else TextAttr:=$08;
   If Remote Then
    Begin SWrite(GetChar); SWrite(GetChar); End
   Else
    Begin SWrite(GetChar); SWrite(GetChar); End;
   If Remote Then SWrite(BC) Else TextAttr:=Config^.BC;
  End;
 If Remote Then SGotoXY(40-(Wid Div 2)-1-1,12-(Len Div 2)+Len+1) Else GotoXY(40-(Wid Div 2)-1-1,12-(Len Div 2)+Len+1);
 If Remote Then SWrite('À'+MakeStr(Wid+2,#196)+'Ù') Else Write('À'+MakeStr(Wid+2,#196)+'Ù');
 If Remote Then SWrite('[1;30m') Else TextAttr:=$08;
 If Remote Then
  Begin SWrite(GetChar); SWrite(GetChar); End
 Else
  Begin SWrite(GetChar); SWrite(GetChar); End;
 If Remote Then SGotoXY(40-(Wid Div 2)-1+2-1,12-(Len Div 2)+Len+2) Else GotoXY(40-(Wid Div 2)-1+2-1,12-(Len Div 2)+Len+2);
 If Remote Then
  For Tmp:=1 To Wid+4 Do SWrite(GetChar)
 Else
  For Tmp:=1 To Wid+4 Do SWrite(GetChar);
End;

Function Initials(S: String): String;
Var I: String[2];
Begin
 S:=RTrim(LTrim(S));
 I[0]:=#2;
 I[1]:=S[1];
 I[2]:=S[2];
 While (S[Length(S)-1]<>' ') And (S<>'') Do Delete(S,Length(S),1);
 If S<>'' Then I[2]:=S[Length(S)];
 Initials:=I;
End;

Procedure FancyClear;
{ Was a direct video-memory scroll-wipe animation - no equivalent without
  a real screen buffer. Stubbed to a plain clear pending the
  ncurses/Video-unit port. }
Begin
 ClrScr;
End;

Procedure FixChainsaw;
Var
 InF: Text;
 OutF: text;
 Hold: String;
 S: String;
Begin
 S:='';
 Hold:='';
 Assign(InF,MsgTxtFile);
 Reset(InF);
 Assign(OutF,CfgPath+'$TIE-EDITMP.$~$');
 ReWrite(OutF);
 Repeat
  If S='' Then
   Begin
    ReadLn(InF,S);
    If Pos('>',S) in [1..5] Then Begin Delete(S,1,Pos('>',S)); If S[1]=' ' Then Delete(S,1,1); End;
    If (Pos(' ',S)=0) And (Length(S)>70) Then
     Begin
      If Hold<>'' Then WriteLn(OutF,' '+ToInitials+'> '+Hold);
      WriteLn(OutF,' '+ToInitials+'> '+Copy(S,1,60));
      Delete(S,1,60); Hold:=S; S:=''; Continue;
     End;
    If Pos('* In a mess',S) in [1..10] Then Begin WriteLn(OutF,S); Hold:=''; S:=''; Continue; End;
    If (RTrim(LTrim(S))='') Then
     Begin
      If Hold<>'' Then WriteLn(OutF,' '+ToInitials+'> '+Hold);
      WriteLn(OutF,' '+ToInitials+'> '+S); Hold:=''; S:=''; Continue;
     End;
    If (Pos('... ',S) in [1..2]) Or
       (Pos('--- ',S) in [1..2]) Or
       (Pos('-*- ',S) in [1..2]) Then
     Begin
      If Hold<>'' Then WriteLn(OutF,' '+ToInitials+'> '+Hold);
      Hold:='';
     End;

    S:=RTrim(LTrim(S))+' ';
    If (Pos('>',S) in [1..5]) Then
     Begin
      If Hold<>'' Then WriteLn(OutF,' '+ToInitials+'> '+Hold);
      WriteLn(OutF,' '+ToInitials+'> '+S); Hold:=''; S:='';
      Continue;
     End;
   End;
  If Length(Hold)+Pos(' ',S)<=70 Then
   Begin
    Hold:=Hold+Copy(S,1,Pos(' ',S));
    Delete(S,1,Pos(' ',S));
   End
  Else
   Begin
    WriteLn(OutF,' '+ToInitials+'> '+RTrim(LTrim(Hold))); Hold:='';
    If Pos(' ',S)>70 Then
     Begin
      WriteLn(OutF,' '+ToInitials+'> '+RTrim(LTrim(Copy(S,1,70))));
      Delete(S,1,70);
     End;
   End;
 Until (Eof(InF) And (S='') And (Hold=''));
 Close(InF);
 Close(OutF);
 Erase(InF);
 XRename(CfgPath+'$TIE-EDITMP.$~$',MsgTxtFile);
End;

Procedure ResetUser;
Begin
 FillChar(User,SizeOf(User),#0);
 With User Do
  Begin
   FillChar(Expand,SizeOf(Expand),#0);
   User.NC:=Config^.NC;
   User.HC:=Config^.HC;
   User.BC:=Config^.BC;
   User.PC:=Config^.PC;
   User.FZ:=Config^.FZ;
   User.FC:=Config^.FC;
   User.FL:=Config^.FL;
   User.FS:=Config^.FS;
   User.FD:=Config^.FD;
   User.IC:=Config^.IC;
   User.ID:=Config^.ID;
   User.IL:=Config^.IL;
   User.IS:=Config^.IS;
   User.FieldColor:=Config^.FieldColor;

   UseExpand:=True;
   UseTaglines:=True;
   UseKeywords:=False;

   NameCRC:=CCRC32(UCase(UserName));
   Name:=UserName;
  End;
End;

Procedure LoadUser;
Var UCRC: LongInt;
Begin
 UCRC:=CCRC32(UCase(UserName));
 Assign(UserFile,CfgPath+'TIE-EDITUSR.CFG');
 UIDX:=-1;
 ResetUser;
 {$I-} Reset(UserFile); {$I+}
 If IOResult<>0 Then
  Begin
   ReWrite(UserFile);
   Write(UserFile,User);
   UIDX:=0;
   Close(UserFile);
   Exit;
  End;
 While Not Eof(UserFile) Do
  Begin
   Read(UserFile,User);
   If User.NameCRC=UCRC Then
    Begin
     If User.Name='' Then
      Begin
       User.Name:=Username;
       Seek(UserFile,FilePos(UserFile)-1);
       Write(UserFile,User);
      End;
     UIDX:=FilePos(UserFile)-1;
     If Not User.ChgdColors Then
      Begin
       User.NC:=Config^.NC;
       User.HC:=Config^.HC;
       User.BC:=Config^.BC;
       User.PC:=Config^.PC;
       User.FZ:=Config^.FZ;
       User.FC:=Config^.FC;
       User.FL:=Config^.FL;
       User.FS:=Config^.FS;
       User.FD:=Config^.FD;
       User.IC:=Config^.IC;
       User.ID:=Config^.ID;
       User.IL:=Config^.IL;
       User.IS:=Config^.IS;
      End;
     Close(UserFile);
     Exit;
    End;
  End;
 If UIDX=-1 Then Begin UIDX:=FileSize(UserFile); ResetUser; End;
 Close(UserFile);
End;


Procedure Remove_Trailing;
Begin
 While MText[CLine]^[Length(MText[CLine]^)]=' ' Do Delete(MText[CLine]^,Length(MText[CLine]^),1);
End;

Function CurChar: Char;
Var CC,CL: Byte;
Begin
 CC:=CCol; CL:=CurLength;
 If CCol <= CurLength Then CurChar:=MText[CLine]^[CCol] Else CurChar:=' ';
End;

Procedure Update_Eol;            { Update screen after changing End-of-Line }
Begin
 Remove_Trailing; Reposition; SClrEol; Set_PhyLine;
End;

Procedure Insert_Line(Contents: String);
Var
 I: Integer;
Begin
 If CLine=Max_Msg_Lines-1 Then Exit;
 For I:=Max_Msg_Lines-1 DownTo CLine+1 Do MText[i]^:=MText[i-1]^;
 MText[CLine]^:=Contents;
 If CLine<LineCnt Then Inc(LineCnt);
 If CLine>LineCnt Then LineCnt:=CLine;
End;

Procedure Split_Line;              { Splits the current line at the Cursor, }
Var PCol: Integer;                     { leaves Cursor in original position }
    Hold,Quote: String[100];
Begin
 PCol:=CCol; Remove_Trailing; Par:=Copy(MText[CLine]^,CCol,79);

 If (Pos('>',MText[CLine]^) in [1..5]) And (CCol<=Length(MText[CLine]^)) And (CCol>Pos('>',MText[CLine]^)) Then
  Begin
   Hold:=MText[CLine]^; Quote:='';
   Repeat
    Quote:=Quote+Copy(Hold,1,Pos('>',Hold));
    Delete(Hold,1,Pos('>',Hold));
    If Hold[1]=' ' Then Begin Delete(Hold,1,1); Quote:=Quote+' '; End;
   Until Not (Pos('>',Hold) in [1..5]);
   Par:=Quote+Par;
  End;

 MText[CLine]^[0] := Chr(CCol-1);         { Remove it from the current line }
 Update_Eol; CCol:=1;                                   { Open a blank line }
 Inc(CLine); Insert_Line(Par);
 If CLine-TopLine > ScrLines-2 Then
  Scroll_Screen(Config^.ScrollSiz)
 Else
  Refresh_screen;
 Dec(CLine); CCol:=PCol;
End;

Procedure Cursor_NewLine;
Var A: Byte;
Begin
 If CLine=Max_Msg_Lines-1 Then Exit;
 If Insert_Mode Then Split_Line;
 CCol:=1; Cursor_Down(True);
End;

Procedure Delete_Line;
Var I: Integer;
Begin
 For I:=CLine To Max_Msg_Lines-1 Do MText[I]^:=MText[I+1]^;
 MText[Max_Msg_Lines-1]^:='';
 If (CLine<=LineCnt) And (LineCnt>1) Then Dec(LineCnt);
End;

Procedure Join_Lines;  { Join current line with following line, if possible }
Var CC,CL: Byte;
Begin
 If ((CurLength + Length(MText[CLine+1]^))>=79) And (Pos(#32,MText[CLine+1]^)=0) Then Exit;
 CC:=CCol; CL:=CurLength;
 If (CurLength + Length(MText[CLine+1]^))<79 Then
  Begin
   If ((MText[CLine]^[Length(MText[CLine]^)]<>' ') And (MText[CLine]^<>'')) And
      ((MText[CLine+1]^[1]<>' ') And (MText[CLine+1]^<>'')) Then
    MText[CLine]^:=MText[CLine]^+' ';

   MText[CLine]^:=MText[CLine]^+MText[CLine+1]^;
   Inc(CLine); Delete_Line; Dec(CLine);
   If MText[CLine]^[Length(MText[CLine]^)]=' ' Then Delete(MText[CLine]^,Length(MText[CLine]^),1);
  End
  Else
  Begin
   If (MText[CLine]^<>'') And (MText[CLine]^[Length(MText[CLine]^)]<>' ') Then MText[CLine]^:=MText[CLine]^+' ';
   While (Length(MText[CLine]^)+Pos(#32,MText[CLine+1]^)<WWrap) And (MText[CLine+1]^<>'') Do
    Begin
     If MText[CLine+1]^[Length(MText[CLine+1]^)]<>' ' Then MText[CLine+1]^:=MText[CLine+1]^+' ';
     MText[CLine]^:=MText[CLine]^+Copy(MText[CLine+1]^,1,Pos(#32,MText[CLine+1]^));
     Delete(MText[CLine+1]^,1,Pos(#32,MText[CLine+1]^));
    End;
  End;
 Refresh_screen;
End;

Procedure Word_Wrap;       { Line is full and a character must be inserted. }
Var
 PCol: Integer; PLine: Integer;
 Hold,HoldNext: String;
 NewWord: String;
Label ReLoop,NotDone;
Begin
 If CLine=Max_Msg_Lines-1 Then
  Begin Cursor_Left; If Insert_Mode Then Delete_Char; Exit; End;

 PCol:=CCol; PLine:=CLine; CCol:=CurLength;
 If CurChar=' ' Then { Insert a c/r if line ends with a space}
  Begin
   If (LastSlice+Slicing<=Timer) Then ReleaseSlice;
   Cursor_NewLine; Exit;
  End;
 While (CCol>0) And (CurChar<>' ') Do Dec(CCol);
 If CCol=0 Then  { Cancel wrap If no spaces in whole line }
  Begin
   If (LastSlice+Slicing<=Timer) Then ReleaseSlice;
   CCol:=1; Cursor_Down(True); Exit;
  End;
 Par:=Copy(MText[CLine]^,CCol+1,79);     { Get the portion to be moved down }
 MText[CLine]^[0]:=Chr(CCol-1);   { Remove from current line & refresh screen }
 Update_Eol;           { Place text on open a new line following the cursor }
 Inc(CLine);
 If (LastSlice+Slicing<=Timer) Then ReleaseSlice;

{ Insert_Line(Par);}
 MText[CLine]^:=RTrim(MText[CLine]^);
 Hold:=Par+' '+MText[CLine]^;
 ReLoop:
 MText[CLine+1]^:=RTrim(MText[CLine+1]^);
 HoldNext:=MText[CLine+1]^;
 If Length(Hold)<WWrap Then
  Begin
   MText[CLine]^:=Hold;
   SGotoXY(1,CLine-TopLine+Topscreen); SClrEol; FunkyWrite(Hold);
  End
 Else
  Begin
   NewWord:='';
   NotDone:
   While (Hold[Length(Hold)]<>#32) And (Length(Hold)>0) Do
    Begin
     NewWord:=Hold[Length(Hold)]+NewWord;
     Delete(Hold,Length(Hold),1);
    End;
   If Length(Hold)>=WWrap Then Begin NewWord:=' '+NewWord; Delete(Hold,Length(Hold),1); Goto NotDone; End;
   HoldNext:=NewWord+' '+HoldNext;
   Hold:=LTrim(Hold);
   MText[CLine]^:=RTrim(Hold);
   SGotoXY(1,CLine-TopLine+Topscreen); SClrEol; FunkyWrite(Hold);

   Inc(CLine);
   Hold:=LTrim(HoldNext);
   Goto Reloop;
  End;

 If (PCol<Length(MText[CLine-1]^)) Then MText[CLine]^:=MText[CLine]^+' ';
{ Join_Lines;} { Restore cursor to proper position after the wrap }
 If MText[CLine]^[Length(MText[CLine]^)]=' ' Then Delete(MText[CLine]^,Length(MText[CLine]^),1);
 CLine:=PLine;
 If PCol>CurLength Then
  Begin
   CCol:=PCol-CurLength-1; Cursor_Down(True);
   If (LastSlice+Slicing<=Timer) Then ReleaseSlice;
  End
 Else
  CCol := PCol;                          { Restore original cursor position }
 If (LastSlice+Slicing<=Timer) Then ReleaseSlice;
 If MText[Cline]^=' ' Then MText[CLine]^:='';
 { Screws up wordwrap if you type to the end of one line, then keep typing
   till the end of the next }
 If (CLine-TopLine >= ScrLines) Then
  Scroll_Screen(Config^.ScrollSiz)
 Else
  Refresh_Screen;
End;

Procedure Append_Space;
Begin
 MText[CLine]^:=MText[CLine]^+' ';
End;

Procedure Cursor_Right;
Begin
 If CCol>CurLength Then
  Begin
   If CLine<LineCnt Then
    Begin CCol:=1; Cursor_Down(True); End;
  End
  Else
   Begin FunkyWrite(CurChar); Inc(CCol); End;
End;

Procedure Insert_Char(C: Char);  { Insert character at the cursor position, }
Begin                                                 { word-wrap if needed }
 If (LastSlice+Slicing<=Timer) Then ReleaseSlice;
 If CCol<CurLength Then Remove_Trailing;
 If (CurLength>=WWrap) Or (CCol >=WWrap) Then Word_Wrap; Count_Lines;
 If Insert_Mode And (CCol<=CurLength) Then
  Begin
   Insert(C,MText[CLine]^,CCol);     { Update display line following cursor }
   FunkyWrite(Copy(MText[CLine]^,CCol,79)); { Pos cursor for next insertion }
   Inc(CCol); Reposition;
  End
  Else
  Begin { Append a character to the end of a line }
   While CurLength<CCol Do Append_Space; MText[CLine]^[CCol] := C;
   Cursor_Right;
  End;
 Set_PhyLine;
End;

Procedure Delete_Char;
Begin
 If CCol>CurLength Then { Delete whole line if it is empty }
  Join_Lines
 Else { Delete in the middle of a line }
  If CCol<=CurLength Then
   Begin
    Delete(MText[CLine]^,CCol,1);
    FunkyWrite(Copy(MText[CLine]^,CCol,79));
    SWrite(' ');
    Reposition;
    Set_PhyLine;
   End;
End;

Function SpellCheck: Boolean;
Const
 SpellLang = 'en_CA';
 MaxMisspell = 2000;
Var
 Tmp, SpcPos, PtrPos: Word;
 AToZ: Boolean;
 Ct: Word;
 NewWord, OrigWord, SearchWord: String[50];
 OrigS, S: String;
 C: Char;
 ShellCmd, InFile, OutFile, DicFile: String;
 F: Text;
 Misspelled: Array[1..MaxMisspell] Of String[50];
 MisspelledCnt: Word;
 SkipWord: Array[1..99] Of String[20];
 SkipWords: Byte;
 SkipTmp: Byte;
 SkipIt: Boolean;
 OIM: Boolean;
 FirstLine: Boolean;
 OldCLine: Word;

Label LemmeOut;

 Function IsMisspelled(W: String): Boolean;
 Var I: Word; UW: String[50];
 Begin
  UW:=UCase(W);
  IsMisspelled:=False;
  For I:=1 To MisspelledCnt Do
   If Misspelled[I]=UW Then Begin IsMisspelled:=True; Exit; End;
 End;

 Procedure AddWord(W: String);
 Var PF: Text;
 Begin
  Assign(PF,DicFile);
  {$I-} Append(PF); {$I+}
  If IOResult<>0 Then ReWrite(PF);
  WriteLn(PF,W);
  Close(PF);
  Inc(SkipWords);
  If SkipWords<=99 Then SkipWord[SkipWords]:=W;
 End;

Begin
 SpellCheck:=True;
 {Ask Spellchk? is stored inverted on User.UseSpellChk - False means "ask me"}
 If User.UseSpellChk Then Exit;
 Plain_Footer(2);
 SGotoXY(65-Length(LS(42)),FootRow);
 FunkyWrite(' '+LS(42)+' (y/N) ');
 Repeat C:=UpCase(GetLow); If C=#13 Then C:='N'; Until C in ['Y','N',#27];
 If C=#27 Then
  Begin
   Display_Footer(2);
   Reposition;
   SpellCheck:=False;
   Exit;
  End;
 If C='N' Then Exit;

 DicFile:=CfgPath+'tie-edit.dic';
 InFile:=CfgPath+'tie-edit_spell.in';
 OutFile:=CfgPath+'tie-edit_spell.out';

 SGotoXY(1,FootRow); XSWrite(#27+'[0m'+#27+'[K  '); FunkyWrite(LS(44));

 Assign(F,InFile); Rewrite(F);
 For Ct:=1 To LineCnt Do
  Begin
   S:=MText[Ct]^;
   If Not ((S='') Or (Pos('>',S) in [1..5])) Then WriteLn(F,S);
  End;
 Close(F);

 ShellCmd:=GetEnv('SHELL');
 If ShellCmd='' Then ShellCmd:='/bin/sh';
 Exec(ShellCmd,'-c "hunspell -l -d '+SpellLang+' -p '+DicFile+' <'+InFile+' >'+OutFile+' 2>/dev/null"');

 MisspelledCnt:=0;
 If (DosError<>0) Or (DosExitCode<>0) Then
  Begin
   SGotoXY(1,FootRow); XSWrite(#27+'[0m'+#27+'[K  ');
   FunkyWrite('Spellcheck unavailable - hunspell not found');
   CDelay(1200);
   Display_Footer(2);
   Reposition;
   Exit;
  End;

 {$I-} Assign(F,OutFile); Reset(F); {$I+}
 If IOResult=0 Then
  Begin
   While Not Eof(F) Do
    Begin
     ReadLn(F,S);
     If (S<>'') And (MisspelledCnt<MaxMisspell) Then
      Begin
       Inc(MisspelledCnt);
       Misspelled[MisspelledCnt]:=UCase(S);
      End;
    End;
   Close(F);
  End;

 SkipWords:=0;
 CLine:=1;
 Scroll_Screen(0);
 CLine:=1;
 FirstLine:=True;
 While (CLine<>LineCnt) Or ((CLine=1) And (LineCnt=1)) Do
  Begin
   If FirstLine Then
     FirstLine:=False
   Else
    Begin
     If CLine=LineCnt Then Break;
     Cursor_Down(True);
    End;
   S:=MText[CLine]^;
   If (S='') Or (Pos('>',S) in [1..5]) Then Continue;
   OrigS:=S;
   S:=UCase(S)+' ';
   While Pos('/',S)>0 Do S[Pos('/',S)]:=#32;
   While Pos('/',OrigS)>0 Do OrigS[Pos('/',OrigS)]:=#32;
   PtrPos:=0;
   While S<>'' Do
    Begin
     If (S[1]=' ') Then
     Begin
       Inc(PtrPos);
       Delete(S,1,1);
       Delete(OrigS,1,1);
       Continue;
     End;
     SpcPos:=Pos(' ',S)-1;
     Inc(PtrPos,SpcPos);
     SearchWord:=Copy(S,1,SpcPos);
     OrigWord:=Copy(OrigS,1,SpcPos);
     Delete(S,1,SpcPos);
     Delete(OrigS,1,SpcPos);
     AToZ:=False;
     For Tmp:=1 To Length(SearchWord) Do
      Begin
       If (SearchWord[Tmp]<>#39) And (SearchWord[Tmp]<>#45) And
          ((SearchWord[Tmp]<#65) Or (SearchWord[Tmp]>#90)) Then
          SearchWord[Tmp]:=#32;
       If Not (SearchWord[Tmp] in [#39,#45,#32]) Then AToZ:=True;
      End;
     While Pos(#32,SearchWord)>0 Do Delete(SearchWord,Pos(#32,SearchWord),1);
     If (SearchWord='') Or (Length(SearchWord)<=2) Or (Not AToZ) Then Continue;

     SkipIt:=False;
     For SkipTmp:=1 To SkipWords Do
      If SkipWord[SkipTmp]=OrigWord Then SkipIt:=True;
     If (Not SkipIt) And (IsMisspelled(SearchWord)) Then
      Begin
       SGotoXY(PtrPos-Length(OrigWord)+1,CLine-TopLine+TopScreen);
       XSWrite('|IC'+OrigWord);
       SGotoXY(1,FootRow); XSWrite(#27+'[0m'+#27+'[K  '); FunkyWrite(LS(46));
       NewWord:=OrigWord;
       Case UpCase(GetLow) Of
          'C': Begin
                SGotoXY(1,FootRow);
                XSWrite(#27+'[0m'+#27+'[K  '); FunkyWrite(LS(47)+' ');
                SRead(NewWord,Length(OrigWord)+5,OrigWord);
                SGotoXY(1,FootRow); SWrite(#27+'[0m'+#27+'[K');
                CCol:=PtrPos-Length(OrigWord)+1;
                OIM:=Insert_Mode;
                Reposition;
                OldCLine:=CLine;
                For SkipTmp:=1 To Length(NewWord) Do
                 Begin
                  If SkipTmp<=Length(OrigWord) Then Insert_Mode:=False Else Insert_Mode:=True;
                  Insert_Char(NewWord[SkipTmp]);
                 End;
                Insert_Mode:=True;
                If Length(NewWord)<Length(OrigWord) Then
                 For SkipTmp:=1 To (Length(OrigWord)-Length(NewWord)) Do Delete_Char;
                Insert_Mode:=OIM;
                CLine:=OldCLine;
                PtrPos:=CCol-1;
               End;
          'A': Begin
                Inc(SkipWords);
                If SkipWords<=99 Then SkipWord[SkipWords]:=OrigWord;
               End;
          'S': ;
          'D': AddWord(OrigWord);
          'Q': Goto LemmeOut;
         End;
       If NewWord=OrigWord Then
        Begin
         SGotoXY(PtrPos-Length(OrigWord)+1,CLine-TopLine+TopScreen);
         FunkyWrite(OrigWord);
        End;
      End;
     If S=' ' Then S:='';
    End;
  End;

 LemmeOut:

 SGotoXY(1,FootRow); XSWrite(#27+'[0m'+#27+'[K  '); FunkyWrite(LS(48));
 Repeat C:=GetLow; Until C in [#13,#27];
 If C=#27 Then
  Begin
   SWrite(#27+'[0m'+#27+'[2J');
   StatusBar;
   Display_Footer(3);
   Prepare_Screen;
   Reposition;
  End;
 SpellCheck:=(C=#13);
 While (SKeypressed) Or (Keypressed) Do GetLow;
End;

Procedure Set_PhyLine;
Begin
 PhyLine^[CLine-TopLine+1]:=MText[CLine]^;
End;

Procedure Count_Lines;
Begin;
 If (LastSlice+Slicing<=Timer) Then ReleaseSlice;
 LineCnt:=Max_Msg_Lines-1;
 While (LineCnt>1) And (Length(MText[LineCnt]^)=0) Do Dec(LineCnt);
End;

Procedure Reposition;                     { Update physical cursor position }
Var Eol: Integer;
Begin
 Eol:= CurLength+1;
 If CCol>Eol Then CCol:=Eol;
 Count_Lines;
 While CLine>Max_Msg_Lines-1 Do Cursor_Up;
 SGotoXY(CCol,CLine-TopLine+Topscreen);
End;

Procedure Refresh_Screen;
Var
   PLine:   Integer;
   PCol:    Integer;
   PhLine:  Integer;
Begin
 If (CLine>=Max_Msg_Lines-1) Then CLine:=Max_Msg_Lines-1;

 PLine:=CLine; CLine:=TopLine;
 PCol:=CCol; CCol:=1;                 { Backspace to before the line number }

 For CLine:=TopLine To TopLine+ScrLines-1 do
  Begin
   If (LastSlice+Slicing<=Timer) Then ReleaseSlice;
   PhLine:=CLine-TopLine+1;
   If CLine<=Max_Msg_Lines-1 Then
    Begin
     If MText[CLine]^<>PhyLine^[PhLine] Then
      Begin
       Reposition;
       If MText[CLine]^[3]='>' Then SWrite(ANSICode[8]);
       If CurLength>0 Then Funkywrite(MText[CLine]^);
       If CurLength<Length(PhyLine^[PhLine]) Then SClrEol;
       Set_PhyLine;
      End;
    End
    Else
    Begin
     If Cline=Max_Msg_Lines Then
      PhyLine^[CLine-TopLine+1]:=MText[Max_Msg_Lines]^
     Else
      PhyLine^[CLine-TopLine+1]:='';
     SGotoXY(1,CLine-TopLine+Topscreen); SWrite(PhyLine^[CLine-TopLine+1]); SClrEol;
    End;

  End;
 CCol:=PCol; CLine:=PLine; Reposition;
End;

Procedure Scroll_Screen(Lines: Integer);
Begin
 Inc(TopLine,Lines);
 If (CLine<TopLine) Or (CLine>=TopLine+ScrLines) Then TopLine:=CLine-ScrLines Div 2;
 If TopLine<1 Then
  TopLine:=1
 Else
 Begin
  If TopLine>=Max_Msg_Lines-1 Then Dec(TopLine,Config^.ScrollSiz div 2);
  If TopLine>=Max_Msg_Lines-1 Then Dec(TopLine,Config^.ScrollSiz div 2);
  If TopLine>=Max_Msg_Lines-1 Then Dec(TopLine);
 End;
 Refresh_Screen;
{ SGotoXY(69,22); XSWrite('|NC'+PageNum);}
 Display_Footer(1);
 SGotoXY(CCol,CLine-TopLine+Topscreen);
End;

Procedure Cursor_Down(Force: Boolean);
Begin
 If CLine>=Max_Msg_Lines-1 Then Exit;
 If (Not Force) And (CLine>=LineCnt+1) Then Exit;
 Inc(CLine);
 If (CLine-TopLine>=ScrLines) Then
  Scroll_Screen(Config^.ScrollSiz)
 Else
  RepoNoEOL;
End;

Function CurLength: Integer;
Begin
 CurLength:=Length(MText[CLine]^);
End;

Procedure RepoNoEOL;
Begin
 Count_Lines;
 SGotoXY(CCol,CLine-TopLine+Topscreen);
End;

Function PageNum: String;
Begin
 If CLine Mod ScrLines = 0 Then
  PageNum:=Zero(CLine Div ScrLines,3)
 Else
  PageNum:=Zero(CLine Div ScrLines+1,3);
End;

Procedure StatTimeUpdate;
Var X,Y,A: Byte;
Begin Exit;
 X:=WhereX; Y:=WhereY;
 A:=TextAttr;
 TextAttr:=$1F;
 GotoXY(75,25); SWrite(Copy(FormatTime(Nsl),1,5));
 GotoXY(X,Y);
 TextAttr:=A;
End;

Procedure StatusBar;
Var X,Y,A: Byte;
Begin Exit;
 X:=WhereX; Y:=WhereY;
 A:=TextAttr;
 GotoXY(1,25);
 If StatBar=3 Then StatBar:=1;
 Case StatBar Of
   1: Begin
       TextAttr:=$1F; ClrEol;
        SWrite(' '+Pad(UserName,55)+'[F1] Help');
      End;
   2: Begin
       TextAttr:=$1B; ClrEol; SWrite(' F1 ');
       TextAttr:=$1F; SWrite('More Help '); TextAttr:=$19; SWrite('þ ');
       TextAttr:=$1B; SWrite('F5 ');
       TextAttr:=$1F; SWrite('Beep '); TextAttr:=$19; SWrite('þ ');
       TextAttr:=$1B; SWrite('F10 ');
       TextAttr:=$1F; SWrite('Shell');
      End;
  End;
 TextAttr:=A;
 GotoXY(X,Y);
End;

Function GetLow: Char;
Var C: Char;
Begin
 Repeat C:=Get_Key; Until C in [#13,#27,#32..#126];
 GetLow:=C;
End;

Procedure MinLinesNotMet;
Begin
 Plain_Footer(2);
 SGotoXY(70-Length(LS(68)),FootRow);
 FunkyWrite(' '+LS(68)+' '+Zero(ForceLines,3)+' '+LS(69)+' ');
 CDelay(1000);
 Display_Footer(2);
 Reposition;
End;

Procedure AbortDisabled;
Begin
 Plain_Footer(2);
 SGotoXY(74-Length(LS(70)),FootRow); FunkyWrite(' '+LS(70)+' ');
 CDelay(1000);
 Display_Footer(2);
 Reposition;
End;

Procedure Prepare_Screen;
Var I: Integer;
Begin
 LineNum:=1; For I:=1 to ScrLines Do PhyLine^[I]:='';
 Scroll_Screen(0);
 If (LastSlice+Slicing<=Timer) Then ReleaseSlice;
 Display_Message_Header;
End;

Procedure Display_Message_Header;
Begin SGotoXY(1,1); Reposition; End;

Procedure Cursor_Up;
Begin
 If CLine>1 Then Dec(CLine);
 If CLine<TopLine Then Scroll_Screen(-Config^.ScrollSiz) Else RepoNoEOL;
End;

{ English UI strings are compiled in so the editor runs without ENGLISH.LNG
  beside the binary; other languages still load from external .LNG files. }
{$I english_lng.inc}

Function LS(Num: Word): String;
Type XType = Array[1..83] Of Char;
Var
 XF: File Of XType;
 X: XType;
 S: String;
Begin
 If MemLang Then Begin LS:=Lang^[Num]; Exit; End;
 If UCase(LanguageFile)='ENGLISH' Then Begin LS:=EmbeddedLang[Num]; Exit; End;
 Assign(XF,CfgPath+LanguageFile+'.LNG');
 Reset(XF); Seek(XF,Num-1+1); Read(XF,X); Close(XF);
 Move(X[6],S[1],75); S[0]:=#75; Delete(S,Pos(#0,S),255); S:=RTrim(S);
 LS:=S;
End;

Function LoadS: String;
Type XType = Array[1..83] Of Char;
Var
 XF: File Of XType;
 X: XType;
 S: String;
 Cnt: Word;
Begin
 Cnt:=0;
 If UCase(LanguageFile)='ENGLISH' Then
 Begin
  { English is compiled in (english_lng.inc); never touch the disk for it. }
  For Cnt:=1 To LangCnt Do Lang^[Cnt]:=EmbeddedLang[Cnt];
  Exit;
 End;
 Assign(XF,CfgPath+LanguageFile+'.LNG');
 FileMode:=66;
 Reset(XF);
 Read(XF,X);
 While Not Eof(XF) Do
  Begin
   Read(XF,X);
   Move(X[6],S[1],75); S[0]:=#75; Delete(S,Pos(#0,S),255); S:=RTrim(S);
   Inc(Cnt);
   Lang^[Cnt]:=S;
  End;
 Close(XF);
End;

Procedure XRename(N1,N2: String);
Var
 F1,F2: File;
 Buf: Array[1..4096] Of Byte;
 NR: Word;
Begin
 Assign(F1,N1);
 If (UpCase(N1[1])=UpCase(N2[1])) Then Begin Rename(F1,N2); Exit; End;
 Reset(F1,1);
 Assign(F2,N2);
 ReWrite(F2,1);
 Repeat
  BlockRead(F1,Buf,SizeOf(Buf),NR);
  BlockWrite(F2,Buf,NR);
 Until (NR=0);
 Close(F1);
 Erase(F1);
 Close(F2);
End;

Procedure Cursor_EndLine;
Begin
 CCol:=WWrap; Reposition;
End;

Procedure Cursor_Left;
Begin
 If CCol=1 Then
  Begin
   Cursor_Up; Cursor_EndLine;
  End
  Else
  Begin
   If (Not Local) Then Remote_Screen(#27'[D'); GotoXY(WhereX-1,WhereY);
   Dec(CCol);
   If (LastSlice+Slicing<=Timer) Then ReleaseSlice;
  End;
End;

Procedure XSFWrite(S: String);
Var
 Cmd: String;
 Funky: Boolean;
 Out: String;
 T: String[50];
 FillN: Integer;
Begin
 Funky:=False;
 While Pos('@',S)>0 Do
  Begin
   If Funky Then
    FunkyWrite(Copy(S,1,Pos('@',S)-1))
   Else
    XSWrite(Copy(S,1,Pos('@',S)-1));
   Delete(S,1,Pos('@',S));
   Cmd:=UCase(Copy(S,1,Pos('@',S)-1));
   Delete(S,1,Pos('@',S));
   If Cmd='F' Then Funky:=True;
   If Cmd='/F' Then Funky:=False;
   If Cmd='P' Then S:=PageNum+S;
   If Cmd='VER' Then S:=Ver+S;
   If Cmd='FILL' Then For FillN := WhereX To ScreenCols-1 Do SWrite(#196);
   If Copy(Cmd,1,2)='CT' Then
    Begin
     CurrTimeX:=IntVal(Copy(Cmd,4,2));
     CurrTimeY:=FootRow;
    End;
   If Copy(Cmd,1,2)='UT' Then
    Begin
     UserTimeX:=IntVal(Copy(Cmd,4,2));
     UserTimeY:=IntVal(Copy(Cmd,7,2));
    End;
   If Copy(Cmd,1,2)='TP' Then
    Begin
     Case Config^.TimeFormat Of
       0: ;
       1: S:=Copy(Cmd,3,1)+S;
      End;
    End;
   If Cmd='TIME' Then
    Begin
     Case Config^.TimeFormat Of
       0: FT12Hour:=True;
       1: FT12Hour:=False;
      End;
     T:=Utilpack.FormatTime(Timer);
     Delete(T,6,3);
     S:=T+S;
    End;
   If Cmd='LEFT' Then S:=Zero(Trunc(Nsl/60),3)+S;
   If Copy(Cmd,1,2)='LS' Then S:=LS(IntVal(Copy(Cmd,3,2)))+S;
   If Cmd='QUOTEORMENU' Then S:=QuoteOrMenu+S;
   If Copy(Cmd,1,2)='OS' Then
    Begin
     Delete(Cmd,1,3);
     If Insert_Mode Then
      Cmd:=Copy(Cmd,1,Pos('~',Cmd)-1)
     Else
      Cmd:=Copy(Cmd,Pos('~',Cmd)+1,255);
     While Pos('`',Cmd)>0 Do Cmd[Pos('`',Cmd)]:='@';
     S:=Cmd+S
    End;
  End;
 If Funky Then FunkyWrite(S) Else XSWrite(S);
End;

Procedure Plain_Footer(B: Byte);
Const
 Default: Array[1..2] Of String[140] = (
   '',
   '|HCÀ|PCÄÄ|BCÄÄ @f@Tie-EDIT v@VER@@/f@ -[@f@@TIME@@/f@]-|BC@FILL@|NCÙ@CT:23,23@');
 Default2: Array[1..2] Of String[140] = (
   '[0;34mÄÄÄÄÄÄÄ[1m[[37m@TIME@[34m][0;34m@TPÄ@Ä[1m[[37m@LEFT@ Mins[34m][0;34mÄÄÄÄÄÄÄÄÄÄÄÄ'+
   'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ',
   '[1;33m[K Tie-EDIT v@VER@@CT:09,22@@UT:18,22@');

Var
 Tmp: Byte;

Begin
 If (PlainFooter[1]='') And (PlainFooter[2]='') Then
  Begin
   PlainFooter[1]:=Default[1];
   PlainFooter[2]:=Default[2];
  End;
 Tmp:=PromptRow;
 If PF_overridepos <> 0 Then
  Begin
   Tmp:=PF_overridepos;
   PF_overridepos:=0;
  End;
 SGotoXY(1,Tmp); If B in [1,3] Then SClrEol;
 SGotoXY(1,Tmp+1); If B in [2,3] Then Begin XSFWrite(PlainFooter[2]); SWriteLn(''); End;
End;

Procedure DisplayFooterTime;
Var
 T: String[50];
 X,Y: Byte;
Begin
 X:=WhereX; Y:=WhereY;
 Case Config^.TimeFormat Of
   0: FT12Hour:=True;
   1: FT12Hour:=False;
  End;
 T:=Utilpack.FormatTime(Timer);
 Delete(T,6,3);
 SGotoXY(CurrTimeX,CurrTimeY); FunkyWrite(T);
 SGotoXY(X,Y);
End;

Procedure Display_Footer(B: Byte);
Var
 Tmp: Byte;
Begin
 If (B=1) And (Not OKPageNum) Then Exit;
 SGotoXY(1,PromptRow);
 Plain_Footer(B);
 If B in [1,3] Then
  Begin
   DisplayFooterTime;
   SGotoXY(ScreenCols-6,FootRow);
   XSFWrite('|PC[|NC@P@|PC]|BC');
  End;
 If B in [2,3] Then
  Begin
   SGotoXY(38+20-Length(LS(5)+LS(6)+QuoteOrMenu),FootRow);
   XSFWrite('@f@@quoteormenu@@/f@ |FS<|FCE|FLsc|FS> @f@@ls05@@/f@  |FS<^|FCZ|FS> @f@@ls06@@/f@ ');
  End;
End;

Function Expired: Boolean;
Begin
 Expired:=False;
End;

End.
