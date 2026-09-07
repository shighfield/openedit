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
}

Interface

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
