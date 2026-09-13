Unit TurboCOM;
{$I DEFINES.INC}

{
  Stripped-down replacement for the original TurboCOMM Communications
  Library (by Steve Blinch & Michael Helliker) - see src/legacy/turbocom.pas
  for the full FOSSIL/modem-door original.

  Only the 18 routines the real Tie-EDIT build (tie-edit.pas, se_util.pas,
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
  stay no-ops; there's no remote party to serve. SRead (line-input used
  by signature/tagline-keyword/expand-shortcut editing) used to be a
  stub returning its Default unchanged, silently making those fields
  read-only - now a real ReadKey loop (see its body below).

  The original unit's Interface section wasn't just those 58 routines -
  it also held a ~45-symbol Const/Var block of BBS door-session state
  (caller identity, security level, baud rate, time limits, etc). The
  first stub pass only ported the functions and missed that block
  entirely, leaving tie-edit.pas/se_util.pas referencing undeclared
  identifiers (latent - nothing here has been compiled yet). Below are
  just the survivors: symbols still referenced now that the BBS
  message-base and MSGINF drop-file code is gone. Everything here
  defaults to zero/empty (Pascal zero-inits statics). Security (the
  caller's BBS security level, used to typed-Const-default high so
  Import/Export were never blocked by it) was removed along with
  Import/Export themselves once that whole feature came out.

  SysOpName/BBSName default to empty since nothing populates them
  anymore (the LOCAL.DEF-reading code that used to set them was
  BBS-door-session setup, removed with the MSGINF rewrite). SysOpName
  gets a real value from Config^.RegName right after InitTurboCOMM runs
  (see tie-edit.pas); UserName/UserFirst/UserLast default to the OS
  username (also set in tie-edit.pas's main flow) - se_util.pas's
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

{ CP437 -> single-byte ASCII approximation for the box-drawing/line-art
  bytes ($80-$FF) this codebase writes throughout its screen chrome. The
  original DOS program wrote these bytes straight to a CP437 text-mode
  display; a modern terminal expects UTF-8 and renders unmapped high
  bytes as a replacement-character glyph.

  A true CP437->UTF-8 translation was tried first (each high byte mapped
  to the 2-3 byte UTF-8 encoding of its real Unicode codepoint) and was
  reverted: FPC's Unix CRT unit tracks cursor column position and
  auto-wrap by counting output *bytes*, one byte assumed to be one
  column - true for CP437, false for multi-byte UTF-8. A full-width
  80-column border line expands to ~240 bytes after UTF-8 translation,
  so CRT wraps at the 80-byte mark (a third of the way through), often
  splitting a multi-byte character in half and sending genuinely invalid
  UTF-8 - which is why the replacement-character glyph showed up even
  after that first translation. Worse, CRT's internal screen-shadow
  buffer (used to redraw scrolled regions) stores exactly one byte per
  cell, so there's no way to make multi-byte characters round-trip
  through it correctly without replacing CRT entirely (the deferred
  ncurses/Video-unit port, not a small fix).

  CP437Hi[b] instead holds a single ASCII character that approximates
  byte b - box-drawing lines become -/|/+, shading blocks become
  ./:/#, so byte count still equals column count and none of CRT's
  column math breaks. Less pretty (ASCII art instead of true Unicode
  line-drawing) but correct. Generated programmatically, not
  hand-transcribed, matching this session's established practice for
  this file. }
Const
 CP437Hi: Array[$80..$FF] Of Char = (
  #67,#117,#101,#97,#97,#97,#97,#99,
  #101,#101,#101,#105,#105,#105,#65,#65,
  #69,#97,#65,#111,#111,#111,#117,#117,
  #121,#79,#85,#99,#76,#89,#80,#102,
  #97,#105,#111,#117,#110,#78,#97,#111,
  #63,#33,#33,#50,#52,#33,#60,#62,
  #46,#58,#35,#124,#43,#43,#43,#43,
  #43,#43,#124,#43,#43,#43,#43,#43,
  #43,#43,#43,#43,#45,#43,#43,#43,
  #43,#43,#43,#43,#43,#61,#43,#43,
  #43,#43,#43,#43,#43,#43,#43,#43,
  #43,#43,#43,#35,#95,#124,#124,#34,
  #97,#66,#71,#112,#83,#111,#117,#116,
  #70,#79,#87,#100,#56,#102,#101,#110,
  #61,#43,#62,#60,#124,#124,#47,#126,
  #111,#46,#46,#118,#110,#50,#35,#32);

Function CP437ToAscii(S: String): String;
Var I: Integer;
Begin
 For I:=1 To Length(S) Do
  If Ord(S[I])>=$80 Then S[I]:=CP437Hi[Ord(S[I])];
 CP437ToAscii:=S;
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
  Write(CP437ToAscii(S));
End;

Procedure SWriteLn(S: String);
Begin
  WriteLn(CP437ToAscii(S));
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
Var
  Ch: Char;
  StartX, Y: Integer;
Begin
  StartX := WhereX;
  Y := WhereY;
  S := Default;
  Write(S);
  Repeat
    Ch := ReadKey;
    If Ch = #0 Then
      ReadKey { extended key - discard the scancode byte, no cursor movement support here }
    Else If (Ch = #8) Or (Ch = #127) Then
    Begin
      If Length(S) > 0 Then
      Begin
        Delete(S, Length(S), 1);
        GotoXY(StartX, Y);
        Write(S, ' ');
        GotoXY(StartX + Length(S), Y);
      End;
    End
    Else If (Ch >= #32) And (Ch <= #126) And (Length(S) < Len) Then
    Begin
      S := S + Ch;
      Write(Ch);
    End;
  Until Ch in [#13, #27];
  If Ch = #27 Then S := Default;
End;

End.
