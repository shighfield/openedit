Unit ScreenIO;
{$I DEFINES.INC}

{
  Cross-platform screen + keyboard layer for Tie-EDIT, backed by FPC's
  Video and Keyboard RTL units (Linux console / Win32 console, both from
  the same source). Replaces the old CRT + turbocom display seam.

  Why this exists: the CRT unit tracked screen columns by counting output
  BYTES (one byte = one column) and kept a one-byte-per-cell shadow, which
  made real Unicode impossible and produced wrap/redraw corruption. Video
  gives an explicit cell buffer and owns the cursor, so column tracking is
  exact and WhereX/WhereY are real again. The editor keeps calling the same
  CRT-shaped names (GotoXY, WhereX, ClrScr, ClrEol, TextAttr, ReadKey,
  KeyPressed, Delay) - only the unit they come from changes.

  Output model: the chrome layer builds ANSI-escape strings (via the |XX
  colour tokens -> XSWrite -> SWrite path, and FunkyWrite). WriteAnsi is a
  small interpreter for exactly the escape vocabulary this program emits -
  SGR colour (ESC[..m), cursor position (ESC[y;xH), clear-line (ESC[K),
  clear-screen (ESC[2J), cursor-forward (ESC[nC) - turning it into cell
  writes + attribute state. High bytes ($80..$FF) are mapped to a single
  ASCII approximation (box lines -> -/|/+, shading -> ./:/#) exactly as the
  old turbocom did: ASCII-art borders are a settled design choice, so a
  byte-per-cell model is all that is needed.

  Input model: Keyboard's translated key events replace the two fragile
  hand-rolled paths (DOS scancode, and letter-form VT escape sequences).
  A normal key comes back as its ASCII char; an arrow/navigation key comes
  back already mapped to the WordStar control char the editor's main key
  Case dispatches on (Up->^E, Down->^X, Left->^S, Right->^D, etc.), so no
  escape-sequence parsing survives in the editor.
}

Interface

Uses Video, SysUtils {$IFDEF UNIX}, baseunix, termio {$ELSE}, Keyboard {$ENDIF};

Var
  TextAttr: Byte;           { current attribute, DOS encoding: lo nibble fg
                              (bit3 = intensity), bits 4-6 bg, bit7 blink }

Procedure InitScreen;
Procedure DoneScreen;
Procedure FlushScreen;
Procedure PollDelay;

Procedure GotoXY(X, Y: Byte);
Function  WhereX: Byte;
Function  WhereY: Byte;
Procedure ClrScr;
Procedure ClrEol;
Procedure TextColor(C: Byte);
Procedure TextBackground(C: Byte);
Procedure Window(X1, Y1, X2, Y2: Byte);
Procedure Delay(MS: Word);
Procedure Sound(Hz: Word);
Procedure NoSound;

Function  KeyPressed: Boolean;
Function  ReadKey: Char;

Procedure PutCh(C: Char);          { write one char at the cursor, advancing it }
Procedure WriteAnsi(S: String);    { the ANSI-escape interpreter (backs SWrite) }

Function  ScreenCols: Byte;
Function  ScreenRows: Byte;

Implementation

Const
  { CP437 high byte -> single ASCII approximation. Same table the old
    turbocom used; written as decimal-escape literals (no raw high/control
    bytes) so the source stays pure ASCII. }
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

  { ANSI SGR colour index (0..7) -> DOS colour index. ANSI and DOS swap the
    red/blue bits: ANSI 1=red 4=blue, DOS 4=red 1=blue. }
  AnsiToDos: Array[0..7] Of Byte = (0,4,2,6,1,5,3,7);

Var
  CurX, CurY: Word;                  { 1-based cursor, absolute screen coords }
  WinX1, WinY1, WinX2, WinY2: Word;  { 1-based active window (CRT semantics) }
  Started: Boolean;
  Dirty: Boolean;                    { true when the buffer/cursor changed since the last flush }
  OldExitProc: Pointer;              { chained exit handler, so any Halt restores the terminal }

Function ScreenCols: Byte;
Begin
  If ScreenWidth = 0 Then ScreenCols := 80 Else ScreenCols := ScreenWidth;
End;

Function ScreenRows: Byte;
Begin
  If ScreenHeight = 0 Then ScreenRows := 25 Else ScreenRows := ScreenHeight;
End;

Procedure PutCell(X, Y: Word; C: Char);
Var Idx: LongInt;
Begin
  If (X < 1) Or (Y < 1) Or (X > ScreenWidth) Or (Y > ScreenHeight) Then Exit;
  Idx := (Y - 1) * ScreenWidth + (X - 1);
  If (Idx >= 0) And (Idx < VideoBufSize Div 2) Then
   Begin
    VideoBuf^[Idx] := Ord(C) Or (Word(TextAttr) Shl 8);
    Dirty := True;
   End;
End;

Procedure ClampCursor;
Begin
  If CurX < 1 Then CurX := 1;
  If CurY < 1 Then CurY := 1;
  If CurX > ScreenWidth Then CurX := ScreenWidth;
  If CurY > ScreenHeight Then CurY := ScreenHeight;
End;

Procedure PutCh(C: Char);
Begin
  If Ord(C) >= $80 Then C := CP437Hi[Ord(C)];
  PutCell(CurX, CurY, C);
  Inc(CurX);
  If CurX > WinX2 Then
   Begin
    CurX := WinX1;
    Inc(CurY);
    If CurY > WinY2 Then CurY := WinY2;
   End;
End;

Procedure GotoXY(X, Y: Byte);
Begin
  { CRT GotoXY is relative to the active window's top-left }
  CurX := WinX1 - 1 + X;
  CurY := WinY1 - 1 + Y;
  ClampCursor;
  Dirty := True;
End;

Function WhereX: Byte;
Begin
  WhereX := CurX - (WinX1 - 1);
End;

Function WhereY: Byte;
Begin
  WhereY := CurY - (WinY1 - 1);
End;

Procedure ClrScr;
Var X, Y: Word;
Begin
  For Y := WinY1 To WinY2 Do
   For X := WinX1 To WinX2 Do
    PutCell(X, Y, ' ');
  CurX := WinX1;
  CurY := WinY1;
End;

Procedure ClrEol;
Var X: Word;
Begin
  For X := CurX To WinX2 Do PutCell(X, CurY, ' ');
End;

Procedure TextColor(C: Byte);
Begin
  TextAttr := (TextAttr And $F0) Or (C And $0F);
End;

Procedure TextBackground(C: Byte);
Begin
  TextAttr := (TextAttr And $8F) Or ((C And $07) Shl 4);
End;

Procedure Window(X1, Y1, X2, Y2: Byte);
Begin
  WinX1 := X1; WinY1 := Y1; WinX2 := X2; WinY2 := Y2;
  If WinX2 > ScreenWidth Then WinX2 := ScreenWidth;
  If WinY2 > ScreenHeight Then WinY2 := ScreenHeight;
  If WinX1 < 1 Then WinX1 := 1;
  If WinY1 < 1 Then WinY1 := 1;
  CurX := WinX1; CurY := WinY1;
End;

Procedure Delay(MS: Word);
Begin
  { non-visual; flush pending draws first, then a portable sleep }
  Video.UpdateScreen(False);
  SysUtils.Sleep(MS);
End;

Procedure Sound(Hz: Word);
Begin
  { no PC-speaker equivalent; the beep key is cosmetic - no-op }
End;

Procedure NoSound;
Begin
End;

{ ---- SGR attribute handling ---- }
Procedure ApplySGR(P: Word);
Begin
  Case P Of
    0:     TextAttr := $07;
    1:     TextAttr := TextAttr Or $08;
    5:     TextAttr := TextAttr Or $80;
    30..37: TextAttr := (TextAttr And $F8) Or AnsiToDos[P - 30];
    40..47: TextAttr := (TextAttr And $8F) Or (AnsiToDos[P - 40] Shl 4);
  End;
End;

{ ---- ANSI-escape interpreter ---- }
Procedure WriteAnsi(S: String);
Var
  I, L, K: Integer;
  C, Fin: Char;
  Params: Array[1..8] Of Word;
  NP: Integer;
  Row, Col: Word;
Begin
  I := 1;
  L := Length(S);
  While I <= L Do
   Begin
    C := S[I];
    If (C = #27) And (I < L) And (S[I+1] = '[') Then
     Begin
      { parse CSI: ESC [ p1 ; p2 ; ... final ; params kept in order }
      Inc(I, 2);
      NP := 0;
      Params[1] := 0;
      Repeat
        If NP < 8 Then Inc(NP);
        Params[NP] := 0;
        While (I <= L) And (S[I] >= '0') And (S[I] <= '9') Do
         Begin Params[NP] := Params[NP] * 10 + (Ord(S[I]) - Ord('0')); Inc(I); End;
        If (I <= L) And (S[I] = ';') Then Inc(I) Else Break;
      Until False;
      If I <= L Then
       Begin
        Fin := S[I];
        Inc(I);
        Case Fin Of
          'm': For K := 1 To NP Do ApplySGR(Params[K]);   { in order: 0;34 works }
          'H','f':
            Begin
              Row := Params[1]; If Row = 0 Then Row := 1;
              If NP >= 2 Then Col := Params[2] Else Col := 1;
              If Col = 0 Then Col := 1;
              GotoXY(Col, Row);
            End;
          'J': ClrScr;                    { treat any ESC[nJ as clear-screen }
          'K': ClrEol;
          'C': Begin
                 If Params[1] = 0 Then Params[1] := 1;
                 CurX := CurX + Params[1];
                 If CurX > WinX2 Then CurX := WinX2;
               End;
        End;
       End;
     End
    Else If C = #13 Then
     Begin CurX := WinX1; Inc(I); End
    Else If C = #10 Then
     Begin
       Inc(CurY); CurX := WinX1;
       If CurY > WinY2 Then CurY := WinY2;
       Inc(I);
     End
    Else If C = #27 Then
     Begin Inc(I); End                      { bare ESC - ignore }
    Else
     Begin PutCh(C); Inc(I); End;
   End;
End;

{ ---- keyboard ----
  Unix: read raw bytes straight from stdin in raw mode - the proven model the
  old CRT build used. Every control byte reaches the editor as data (^Z=#26
  Save, Esc=#27 Menu, ^S/^D/^E/^X movement), and arrow/function keys arrive as
  their VT escape sequences (ESC [ A ...), which the editor's own VT-translation
  Case blocks turn into WordStar keys. This sidesteps the FPC Keyboard unit,
  which mis-translates exactly the special keys the editor depends on (Ctrl-Z,
  lone Esc). Non-Unix (Windows console) still uses the Keyboard unit. }

{$IFDEF UNIX}
Function KeyPressed: Boolean;
Var fds: TFDSet; tv: TimeVal;
Begin
  fpFD_ZERO(fds);
  fpFD_SET(0, fds);
  tv.tv_sec := 0;
  tv.tv_usec := 0;
  KeyPressed := fpSelect(1, @fds, Nil, Nil, @tv) > 0;
End;

Function ReadKey: Char;
Var c: Char;
Begin
  If fpRead(0, c, 1) = 1 Then ReadKey := c Else ReadKey := #0;
End;
{$ELSE}
Function MapFnKey(Code: Word): Char;
Begin
  Case Code Of
    kbdUp:     MapFnKey := ^E;
    kbdDown:   MapFnKey := ^X;
    kbdLeft:   MapFnKey := ^S;
    kbdRight:  MapFnKey := ^D;
    kbdHome:   MapFnKey := ^L;
    kbdEnd:    MapFnKey := ^P;
    kbdPgUp:   MapFnKey := ^R;
    kbdPgDn:   MapFnKey := ^C;
    kbdInsert: MapFnKey := ^V;
    kbdDelete: MapFnKey := ^G;
  Else
    MapFnKey := #0;
  End;
End;

Function KeyPressed: Boolean;
Begin
  KeyPressed := PollKeyEvent <> 0;
End;

Function ReadKey: Char;
Var K: TKeyEvent; Flags: Byte; Ch: Char;
Begin
  Repeat
    K := TranslateKeyEvent(GetKeyEvent);
    Flags := GetKeyEventFlags(K);
    If (Flags And kbReleased) <> 0 Then Continue;
    Case (Flags And $03) Of
      kbASCII, kbUniCode:
        Begin Ch := GetKeyEventChar(K); If Ch <> #0 Then Begin ReadKey := Ch; Exit; End; End;
      kbFnKey:
        Begin Ch := MapFnKey(GetKeyEventCode(K)); If Ch <> #0 Then Begin ReadKey := Ch; Exit; End; End;
    End;
  Until False;
End;
{$ENDIF}

Procedure FlushScreen;
Begin
  If Not Dirty Then Exit;
  ClampCursor;
  SetCursorPos(CurX - 1, CurY - 1);
  UpdateScreen(False);
  Dirty := False;
End;

Procedure PollDelay;
Begin
  { keep the Get_Key poll loop from pegging a CPU core while idle }
  SysUtils.Sleep(2);
End;

{$IFDEF UNIX}
Var
  OrigTermios: Termios;
  TermSaved: Boolean;

Procedure InputRawOn;
{ Put stdin into full raw mode so every byte (control chars, Esc) is delivered
  to us verbatim; save the original settings to restore on exit. }
Var t: Termios;
Begin
  TermSaved := False;
  If TCGetAttr(0, OrigTermios) = 0 Then
  Begin
    t := OrigTermios;
    CFMakeRaw(t);
    TCSetAttr(0, TCSANOW, t);
    TermSaved := True;
  End;
End;

Procedure InputRawOff;
Begin
  If TermSaved Then TCSetAttr(0, TCSANOW, OrigTermios);
End;
{$ENDIF}

Procedure DoneScreen;
Begin
  If Not Started Then Exit;
  FlushScreen;
  {$IFDEF UNIX} InputRawOff; {$ELSE} DoneKeyboard; {$ENDIF}
  DoneVideo;
  Started := False;
End;

{ Safety net: if the program Halts (a fatal startup/OOM path) without an
  explicit DoneScreen, restore the terminal on the way out so it is not
  left in raw/alternate-screen mode. }
{$F+}
Procedure ScreenExitHandler;
{$F-}
Begin
  ExitProc := OldExitProc;
  If Started Then DoneScreen;
End;

Procedure InitScreen;
Begin
  If Started Then Exit;
  OldExitProc := ExitProc;
  ExitProc := @ScreenExitHandler;
  InitVideo;
  {$IFDEF UNIX} InputRawOn; {$ELSE} InitKeyboard; {$ENDIF}
  TextAttr := $07;
  WinX1 := 1; WinY1 := 1;
  WinX2 := ScreenCols; WinY2 := ScreenRows;
  CurX := 1; CurY := 1;
  ClrScr;
  FlushScreen;
  Started := True;
End;

Begin
  Started := False;
End.
