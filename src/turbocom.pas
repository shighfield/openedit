Unit TurboCOM;
{$I DEFINES.INC}

{
  Stripped-down replacement for the original TurboCOMM Communications
  Library (by Steve Blinch & Michael Helliker) - see src/legacy/turbocom.pas
  for the full FOSSIL/modem-door original.

  Only the 18 routines the real OpenEdit build (oedit2.pas, se_util.pas,
  seusered.pas) actually calls are kept. Everything else that unit exported
  - FOSSIL/carrier/remote I/O, multi-node file locking, DOS-multitasker
  critical sections, ANSI music - is gone; this editor is local-only now.

  Local always reports True (no remote BBS caller exists anymore), so the
  S-prefixed local/remote-echo routines (SWrite/SWriteLn/SClrScr/SClrEol/
  STextBackground/SGotoXY) and Local_Keypressed now just call the real CRT
  unit equivalents directly - not the deferred ncurses/Video-unit port,
  just the obvious local-only mapping. This was a real bug, not a stub
  waiting on later work: se_util.pas's Get_Key has
  `Repeat ... Until (Remote_Keypressed) Or (Local_Keypressed);` as its
  input loop, and with both hardcoded False this was an infinite loop
  that never read a key - the editor would clear the screen and then
  hang forever. Remote_Screen/Remote_Keypressed/ReceiveChar correctly
  stay no-ops; there's no remote party to serve. SRead (line-input with
  in-place editing) is still a stub returning its Default unchanged -
  a separate, larger gap than this fix, not addressed here.

  The original unit's Interface section wasn't just those 58 routines -
  it also held a ~45-symbol Const/Var block of BBS door-session state
  (caller identity, security level, baud rate, time limits, etc). The
  first stub pass only ported the functions and missed that block
  entirely, leaving oedit2.pas/se_util.pas referencing undeclared
  identifiers (latent - nothing here has been compiled yet). Below are
  just the survivors: symbols still referenced now that the BBS
  message-base and MSGINF drop-file code is gone. Everything here
  defaults to zero/empty (Pascal zero-inits statics) except Security,
  which needs a non-zero default and so is a typed Const, not a Var -
  Turbo Pascal doesn't allow inline initializers on plain Var
  declarations, which was itself a latent syntax error in the previous
  version of this line.

  Security was the caller's BBS security level, read from the door drop
  file in the original unit. oedit2.pas gates Import/Export on it
  (TurboCOM.Security>=Config^.ImportSecurity/ExportSecurity); defaulted
  high so a local single-user run is never blocked by it.

  SysOpName/BBSName default to empty since nothing populates them
  anymore (the LOCAL.DEF-reading code that used to set them was
  BBS-door-session setup, removed with the MSGINF rewrite). SysOpName
  gets a real value from Config^.RegName right after InitTurboCOMM runs
  (see oedit2.pas); UserName/UserFirst/UserLast default to the OS
  username (also set in oedit2.pas's main flow) - se_util.pas's
  LoadUser (per-user color prefs) and PersonalDicName (spell-check
  personal dictionary filename) both key off them.

  AnsiCode (ANSI color-code lookup table, index 0-47) was missed by
  the first two restore passes - those checked Const/Var names but not
  a Const *array* - and only surfaced once an actual FPC compile got
  far enough to hit it. Restored verbatim from the original unit;
  values are plain ANSI escape sequences, no BIOS/hardware dependency.
}

Interface

Uses CRT;

Const
 Security: Word = 65535;
 AnsiCode      : Array[0..47] Of String[7] =    {  ANSI codes, 40+ = BG attr }
        ('[0m',    '[0;34m', '[0;32m',
         '[0;36m', '[0;31m', '[0;35m',
         '[0;33m', '[0;37m', '[1;30m',
         '[1;34m', '[1;32m', '[1;36m',
         '[1;31m', '[1;35m', '[1;33m',
         '[1;37m', '','', '', '','', '',
         '','', '', '','', '', '','', '',
         '','', '', '','', '', '','', '',
         '[40m',   '[44m',   '[42m',
         '[46m',   '[41m',   '[45m',
         '[43m',   '[47m');

Var
 SysPath         : String[50];
 ProgName        : String[62];
 BBSName         : String[50];
 SysOpName       : String[50];
 UserName        : String[50];
 UserFirst       : String[50];
 UserLast        : String[50];
 BaudRate        : Word;
 NodeNum         : Integer;
 ComPort         : Integer;
 TimeLeft        : Real;
 TimeOutDelay    : Real;
 TimeCheck       : Boolean;
 LocalANSIKeys   : Boolean;
 ProhibitStatus  : Boolean;
 Slicing         : Real;
 LastSlice       : Real;
 HelpScrPrgName  : String[20];
 Detailed        : Boolean;
 InputFore       : Integer;
 InputBack       : Integer;
 LimitExceeded   : String[80];
 HookErrorHandler: Boolean;
 SingleLineStat  : Boolean;
 SReadHighBit    : Boolean;

Function Local: Boolean;
Function Remote_Keypressed: Boolean;
Function Local_Keypressed: Boolean;
Function SKeypressed: Boolean;
Function ReceiveChar(PNum: Word): Char;
Procedure SWrite(S: String);
Procedure SWriteLn(S: String);
Procedure Remote_Screen(S: String);
Procedure SClrScr;
Procedure SClrEol;
Procedure STextBackground(C: Integer);
Procedure SGotoXY(X, Y: Integer);
Procedure Disconnect;
Procedure ReleaseSlice;
Function Nsl: Real;
Procedure UpdateStatus(Forced: Boolean);
Procedure InitTurboCOMM;
Procedure SRead(Var S: String; Len: Byte; Default: String);

Implementation

{ CP437 -> UTF-8 translation for the box-drawing/line-art bytes ($80-$FF)
  this codebase writes throughout its screen chrome. The original DOS
  program wrote these bytes straight to a CP437 text-mode display; a
  modern terminal expects UTF-8 and renders unmapped high bytes as a
  replacement-character glyph. CP437Hi[b] holds the UTF-8 encoding of
  the Unicode codepoint CP437 byte b maps to (generated programmatically
  from the standard CP437 table - not hand-transcribed, since this file
  has already lost invisible bytes twice this session to hand-typing). }
Const
 CP437Hi: Array[$80..$FF] Of String[3] = (
  #195#135,#195#188,#195#169,#195#162,
  #195#164,#195#160,#195#165,#195#167,
  #195#170,#195#171,#195#168,#195#175,
  #195#174,#195#172,#195#132,#195#133,
  #195#137,#195#166,#195#134,#195#180,
  #195#182,#195#178,#195#187,#195#185,
  #195#191,#195#150,#195#156,#194#162,
  #194#163,#194#165,#226#130#167,#198#146,
  #195#161,#195#173,#195#179,#195#186,
  #195#177,#195#145,#194#170,#194#186,
  #194#191,#226#140#144,#194#172,#194#189,
  #194#188,#194#161,#194#171,#194#187,
  #226#150#145,#226#150#146,#226#150#147,#226#148#130,
  #226#148#164,#226#149#161,#226#149#162,#226#149#150,
  #226#149#149,#226#149#163,#226#149#145,#226#149#151,
  #226#149#157,#226#149#156,#226#149#155,#226#148#144,
  #226#148#148,#226#148#180,#226#148#172,#226#148#156,
  #226#148#128,#226#148#188,#226#149#158,#226#149#159,
  #226#149#154,#226#149#148,#226#149#169,#226#149#166,
  #226#149#160,#226#149#144,#226#149#172,#226#149#167,
  #226#149#168,#226#149#164,#226#149#165,#226#149#153,
  #226#149#152,#226#149#146,#226#149#147,#226#149#171,
  #226#149#170,#226#148#152,#226#148#140,#226#150#136,
  #226#150#132,#226#150#140,#226#150#144,#226#150#128,
  #206#177,#195#159,#206#147,#207#128,
  #206#163,#207#131,#194#181,#207#132,
  #206#166,#206#152,#206#169,#206#180,
  #226#136#158,#207#134,#206#181,#226#136#169,
  #226#137#161,#194#177,#226#137#165,#226#137#164,
  #226#140#160,#226#140#161,#195#183,#226#137#136,
  #194#176,#226#136#153,#194#183,#226#136#154,
  #226#129#191,#194#178,#226#150#160,#194#160);

Function CP437ToUtf8(S: String): String;
Var I: Integer; R: String;
Begin
 R:='';
 For I:=1 To Length(S) Do
  If Ord(S[I])<$80 Then R:=R+S[I]
  Else R:=R+CP437Hi[Ord(S[I])];
 CP437ToUtf8:=R;
End;

Function Local: Boolean;
Begin
  Local := True;
End;

Function Remote_Keypressed: Boolean;
Begin
  Remote_Keypressed := False;
End;

Function Local_Keypressed: Boolean;
Begin
  Local_Keypressed := KeyPressed;
End;

Function SKeypressed: Boolean;
Begin
  SKeypressed := False;
End;

Function ReceiveChar(PNum: Word): Char;
Begin
  ReceiveChar := #0;
End;

Procedure SWrite(S: String);
Begin
  Write(CP437ToUtf8(S));
End;

Procedure SWriteLn(S: String);
Begin
  WriteLn(CP437ToUtf8(S));
End;

Procedure Remote_Screen(S: String);
Begin
End;

Procedure SClrScr;
Begin
  ClrScr;
End;

Procedure SClrEol;
Begin
  ClrEol;
End;

Procedure STextBackground(C: Integer);
Begin
  TextBackground(C);
End;

Procedure SGotoXY(X, Y: Integer);
Begin
  GotoXY(X, Y);
End;

Procedure Disconnect;
Begin
End;

Procedure ReleaseSlice;
Begin
End;

Function Nsl: Real;
Begin
  Nsl := 0;
End;

Procedure UpdateStatus(Forced: Boolean);
Begin
End;

Procedure InitTurboCOMM;
Begin
End;

Procedure SRead(Var S: String; Len: Byte; Default: String);
Begin
  S := Default;
End;

End.
