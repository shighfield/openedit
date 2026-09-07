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

  All bodies here are placeholder stubs pending the ncurses/Video-unit
  port: Local always reports True, the read routines never return input,
  and the write routines do nothing yet.

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

  SysOpName/UserName/UserFirst/UserLast/BBSName default to empty since
  nothing populates them anymore (the LOCAL.DEF-reading code that used
  to set them was BBS-door-session setup, removed with the MSGINF
  rewrite). SysOpName gets a real value from Config^.RegName right
  after InitTurboCOMM runs (see oedit2.pas); UserName/UserFirst/UserLast
  staying empty is a known gap - se_util.pas's LoadUser (keys per-user
  color prefs off UserName) and PersonalDicName (spell-check personal
  dictionary filename, off UserFirst/UserLast) degrade to a single
  shared identity until something asks the local user who they are.
}

Interface

Const
 Security: Word = 65535;

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
  Local_Keypressed := False;
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
End;

Procedure SWriteLn(S: String);
Begin
End;

Procedure Remote_Screen(S: String);
Begin
End;

Procedure SClrScr;
Begin
End;

Procedure SClrEol;
Begin
End;

Procedure STextBackground(C: Integer);
Begin
End;

Procedure SGotoXY(X, Y: Integer);
Begin
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
