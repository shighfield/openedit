Program DictEdit;
{$M 64000,0,20000}
{$I c:\bp\oedit\DEFINES.INC}

Uses Utilpack,Crt,DESUnit,DOS;
Const BarColor = 1;
{$I c:\bp\oedit\SEDIT.INC}
Var

 PersonalDic: Boolean;
 PDN: String;
 Config: ConfigRec;
 ConfigFile: File Of ConfigRec;
 CfgPath: String;

 SearchFor: String[35];
 OnScreen: Array[1..7] Of String[35];
 Index: Array[1..10000] Of LongInt;
 IndexCnt: Word;
 Section: Char;
 S1,S2: String;
 C: Char;
 Tmp,
 Top,Hil: LongInt;
 Idx: LongInt;
 IdxFile: File Of LongInt;
 DatFile: File;

Procedure Center(S: String; B: Byte);
Begin
 GotoXY(40-(Length(S) Div 2),B);
 Write(S);
End;

Procedure Box(X,Y,Wid,Len: Byte);
Const BA = BarColor;
Var Tmp: Byte;
Begin
 TextAttr:=BA;
 GotoXY(X,Y);
 Write('Ś'+MakeStr(Wid-2,'Ä')+'æ');
 For Tmp:=Y+1 To Y+Len Do
  Begin
   TextAttr:=BA;
   GotoXY(X,Tmp);
   Write('³'+MakeStr(Wid-2,' ')+'³');
   TextAttr:=$08; Write(GetChar); Write(GetChar);
  End;
 TextAttr:=BA;
 GotoXY(X,Y+Len+1); Write('Ą'+MakeStr(Wid-2,'Ä')+'Ł');
 TextAttr:=$08; Write(GetChar); Write(GetChar);
 GotoXY(X+2,Y+Len+2); For Tmp:=1 To Wid Do Write(GetChar);
End;

Procedure XWrite(S: String);
Begin
 TextAttr:=$07;
 While Pos('^\',S)>0 Do
  Begin
   Write(Copy(S,1,Pos('^\',S)-1));
   Delete(S,1,Pos('^\',S)+1);
   Case S[1] Of
     'S': Begin
           Delete(S,1,1);
           Write(Pad('',IntVal(Copy(S,1,2))));
           Delete(S,1,2);
          End;
     Else Begin
           TextAttr:=LIntVal('$'+Copy(S,1,2));
           Delete(S,1,2);
          End;
    End;
  End;
 Write(S);
End;

Procedure StatWrite(S: String);
Var Wmn,Wmx: Word; X,Y,A: Byte;
Begin
 X:=WhereX; Y:=WhereY; A:=TextAttr;
 Wmn:=WindMin; Wmx:=WindMax;
 Window(1,1,80,25);
 GotoXY(1,1); TextAttr:=$07; ClrEol; XWrite('^\0F'+S);
 WindMin:=Wmn; WindMax:=Wmx;
 GotoXY(X,Y); TextAttr:=A;
End;

Procedure AddMainDic(S: String);
Var
 OrigS,XS: String[35];
 DatFile: File;
 MiscWordStart,
 ShouldBePos: LongInt;
 NR: Word;

 Procedure DoAddMainDic(S: String);
 Begin
  If S='' Then Exit;    {If [Enter] then Quit}
  Seek(DatFile,FileSize(DatFile));
  BlockWrite(DatFile,S,Length(S)+1);
  SaveScreen(4);
  Window(1,1,80,25);
  GotoXY(45,15); XWrite('^\07                              ');
  GotoXY(45,15); XWrite('^\0F'+S+'^\07 added.');
  GotoXY(45,16); XWrite('^\07Press any key.                ');
  GotoXY(45,17); XWrite('^\07                              '); ReadKey;
  RestoreScreen(4);
 End;

Label CheckMisc;
Begin
 Assign(DatFile,Config.DictionaryPath+'OE_DIC.DAT');
 Reset(DatFile,1);

 OrigS:=S; While Length(S)<3 Do S:=S+'A'; XS:=S;
 ShouldBePos:=((ord(S[1])-Ord('A'))*26*26)+((ord(S[2])-Ord('A'))*26)+(ord(S[3])-Ord('A'));
 Seek(IdxFile,ShouldBePos);
 Read(IdxFile,Idx);
 If Idx=-1 Then Goto CheckMisc;
 Seek(DatFile,Idx+256);
 Repeat
  BlockRead(DatFile,S[0],1,NR);
  BlockRead(DatFile,S[1],Ord(S[0]),NR);
  If (S=OrigS) Then
   Begin
    SaveScreen(4);
    Window(1,1,80,25);
    GotoXY(45,15); XWrite('^\07  Word already exists in main ');
    GotoXY(45,16); XWrite('^\07  dictionary!  Press any key. ');
    GotoXY(45,17); XWrite('^\07                              '); ReadKey;
    RestoreScreen(4);
    Close(DatFile);
    Exit;
   End;
 Until (NR=0) Or (XS[1]+XS[2]+XS[3]<>S[1]+S[2]+S[3]);

 CheckMisc:
 Seek(DatFile,252);
 BlockRead(DatFile,MiscWordStart,SizeOf(MiscWordStart),NR);
 If (MiscWordStart=$1A0A0D73) Or (MiscWordStart=0) Or (MiscWordStart=16777216) Then MiscWordStart:=440061;
 Seek(DatFile,MiscWordStart+256);
 Repeat
  BlockRead(DatFile,S[0],1,NR);
  BlockRead(DatFile,S[1],Ord(S[0]),NR);
  If (S=OrigS) Then
   Begin
    SaveScreen(4);
    Window(1,1,80,25);
    GotoXY(45,15); XWrite('^\07  Word already exists in main ');
    GotoXY(45,16); XWrite('^\07  dictionary!  Press any key. ');
    GotoXY(45,17); XWrite('^\07                              '); ReadKey;
    RestoreScreen(4);
    Close(DatFile);
    Exit;
   End;
 Until (NR=0);

 DoAddMainDic(OrigS);
 Close(DatFile);
 Exit;
End;

Procedure OpenSection;
Var
 MiscWordStart,
 ShouldBePos: LongInt;
 Idx: LongInt;
 S: String;
 NR: Word;
 LS: Byte;
 MajorC,MinorC,MinorxC: Byte;
 FirstWord,LastWord: String;
Begin

 If Section<>'!' Then
  Begin
   StatWrite('Loading dictionary section "'+Section+'", please wait...');
   ShouldBePos:=((ord(Section)-Ord('A'))*26*26)+((ord('A')-Ord('A'))*26)+(ord('A')-Ord('A'));
   Seek(IdxFile,ShouldBePos);
   Repeat
    Read(IdxFile,Idx);
   Until Idx<>-1;
   Seek(DatFile,Idx+256);
  End
  Else
  Begin
   StatWrite('Loading unsorted dictionary section, please wait...');
   Seek(DatFile,252);
   BlockRead(DatFile,MiscWordStart,SizeOf(MiscWordStart),NR);
   If (MiscWordStart=$1A0A0D73) Or (MiscWordStart=0) Or (MiscWordStart=16777216) Then MiscWordStart:=440061;
    { ^ Old Dict Style }
   Seek(DatFile,MiscWordStart+256);
  End;
 IndexCnt:=0;
 Repeat
  Inc(IndexCnt);
  Index[IndexCnt]:=FilePos(DatFile);
  BlockRead(DatFile,S[0],1,NR);
  BlockRead(DatFile,S[1],Ord(S[0]),NR);
  If IndexCnt=1 Then FirstWord:=S;
  If S=MakeStr(Length(S),#255) Then Dec(IndexCnt);
  If Section='!' Then S[1]:='!';
  If (S[1]=Section) And (NR<>0) Then LastWord:=S;
 Until ((S[1]<>Section) And (S[1]<>#255)) Or (NR=0);
 Dec(IndexCnt);
 If Section<>'!' Then
  StatWrite('Current Dictionary Section: '+FirstWord+' to '+LastWord)
 Else
  StatWrite('Current Dictionary Section: Unsorted Words')
End;

Function GetWord(L: LongInt): String;
Var
 S: String;
 NR: Word;
Begin
 GetWord:='';
 If IndexCnt>=L Then
  Begin
   Seek(DatFile,Index[L]);
   BlockRead(DatFile,S[0],1,NR);
   BlockRead(DatFile,S[1],Ord(S[0]),NR);
   If S=MakeStr(Length(S),#255) Then S:='[empty]';
   GetWord:=S;
  End;
End;

Procedure SetWord(L: LongInt; S: String);
Var
 NR: Word;
Begin
 If IndexCnt>=L Then
  Begin
   Seek(DatFile,Index[L]);
   BlockWrite(DatFile,S[0],1,NR);
   BlockWrite(DatFile,S[1],Ord(S[0]),NR);
  End;
End;

Procedure AddWord(S: String);
Var
 NR: Word;
Begin
 Seek(DatFile,FileSize(DatFile));
 BlockWrite(DatFile,S[0],1,NR);
 BlockWrite(DatFile,S[1],Ord(S[0]),NR);
End;

Procedure AddNewWord;
Var Wmn,Wmx: Word;
    X,Y,A,Tmp: Byte;
    S: String;
Begin
 X:=WhereX; Y:=WhereY; A:=TextAttr;
 Wmn:=WindMin; Wmx:=WindMax;
 Window(1,1,80,25);
 GotoXY(45,15); XWrite('^\07Enter new word to add:        ');
 GotoXY(45,17); XWrite('^\07                              ');
 GotoXY(45,16); TextAttr:=$1F; Read_Str(S,30,'');
 S:=Ucase(S); For Tmp:=1 To Length(S) Do If Not (S[Tmp] in ['A'..'Z','-','''']) Then S[Tmp]:=#0;
 While Pos(#0,S)>0 Do Delete(S,Pos(#0,S),1);
 If S<>'' Then
  Begin
   Close(DatFile);
   AddMainDic(S);
   Reset(DatFile,1);
  End;
 GotoXY(45,15); XWrite('^\0FENTER^\07 Edit Word  ^\0FINS^\07 Add Word');
 GotoXY(45,16); XWrite('^\0FA-Z,!^\07 Section    ^\0FDEL^\07 Kill Word');
 GotoXY(45,17); XWrite('^\0FHOME ^\07 Personal Dictionaries');
 WindMin:=Wmn; WindMax:=Wmx;
 GotoXY(X,Y); TextAttr:=A;
End;

Procedure Redisp;
Var Max: Word;
Begin
 Max:=8; If Max>IndexCnt Then Max:=IndexCnt;
 TextAttr:=$07; ClrScr;
 For Tmp:=1 To Max Do
  Begin
   GotoXY(1,Tmp); Write(' '+Pad(GetWord(Tmp),31));
  End;
End;

Function X(S: String): String;
Begin
 If S='' Then X:='[unknown name]' Else X:=S;
End;

Procedure PersonalReload;
Var S: String; NR: Word;
Begin
  If Not PersonalDic Then Exit;
  Seek(DatFile,0); IndexCnt:=0;
  Repeat
   Inc(IndexCnt);
   Index[IndexCnt]:=FilePos(DatFile);
   BlockRead(DatFile,S[0],1,NR);
   BlockRead(DatFile,S[1],Ord(S[0]),NR);
  Until NR=0;
  Dec(IndexCnt);
  Top:=0; Hil:=1;
  Redisp;
End;

Function PersonalDicName(UserFirst,UserLast: String): String;
Var
 Nom: String;
 Tmp: Byte;
 Ext: String[3];
Begin
 Nom:='';
 For Tmp:=1 To Length(UserLast) Do
  If UpCase(UserLast[Tmp]) in ['A'..'Z'] Then Nom:=Nom+UpCase(UserLast[Tmp]);
 If Nom[0]>#8 Then Nom[0]:=#8; Nom:=Nom+'.';
 Ext:='';
 For Tmp:=1 To Length(UserFirst) Do
  Begin
   If UpCase(UserFirst[Tmp]) in ['A'..'Z'] Then Ext:=Ext+UpCase(UserFirst[Tmp]);
   If Length(Ext)=3 Then Break;
  End;
 Nom:=Nom+Ext;
 If Nom[0]>#12 Then Nom[0]:=#12;
 PersonalDicName:=Nom;
End;

Procedure PersonalDics;
Type
 Str35 = String[35];
Var
 S: String;
 ChangedIndex: Boolean;
 User: UserRec;
 UserFile: File Of UserRec;
 Hil,Top,Tmp,Max: Word;
 C: Char;
 NFirst,NLast: String;
 UIdx: Array[1..3500] Of Word;
 Users: Word;
 FN,N: String;
 PersonalIdx: Str35;
 PersonalIdxFile: File Of Str35;

 Procedure EditDic(XPos: LongInt);
 Var
  F: File;
  NR: Word;
 Begin
  Seek(PersonalIdxFile,XPos);
  Read(PersonalIdxFile,PersonalIdx);
  ChangedIndex:=True;
  IndexCnt:=0;
  N:=PersonalIdx+' ';
  NFirst:=Copy(N,1,Pos(' ',N)); Delete(N,1,Pos(' ',N));
  NLast:=N;
  FN:=PersonalDicName(Nfirst,Nlast);
  Assign(F,Config.DictionaryPath+FN);
  Reset(F,1);
  Repeat
   Inc(IndexCnt);
   Index[IndexCnt]:=FilePos(F);
   BlockRead(F,S[0],1,NR);
   BlockRead(F,S[1],Ord(S[0]),NR);
   If Copy(S,1,5)='*PDF*' Then Dec(IndexCnt);
  Until NR=0;
  Close(F);
  Dec(IndexCnt);
  PersonalDic:=True;
  Close(DatFile);
  PDN:=Config.DictionaryPath+FN;
  Assign(DatFile,Config.DictionaryPath+FN);
  Reset(DatFile,1);
 End;

Begin
 SaveScreen(5);
 Window(1,1,80,25);
 GotoXY(45,15); XWrite('^\0FENTER^\07 Edit user''s dictionary ');
 GotoXY(45,16); XWrite('^\0FESC  ^\07 Back to main dictionary ');
 GotoXY(45,17); XWrite('                             ');
 Window(5,13,37,20);
 ChangedIndex:=False;
 SaveScreen(3);
 StatWrite('^\0FCurrent Dictionary: Personal User Dictionaries');

 Assign(PersonalIdxFile,CfgPath+'SEUSRDIC.IDX');
 {$I-} Reset(PersonalIdxFile); {$I+}
 Users:=0;
 If IOResult=0 Then
  Begin
   While Not Eof(PersonalIdxFile) Do
    Begin
     Read(PersonalIdxFile,PersonalIdx);
     If PersonalIdx<>'' Then
      Begin
       N:=PersonalIdx+' ';
       NFirst:=RTrim(LTrim(Copy(N,1,Pos(' ',N)-1))); Delete(N,1,Pos(' ',N));
       NLast:=Rtrim(LTrim(N));
       FN:=PersonalDicName(Nfirst,Nlast);
       If FileExists(Config.DictionaryPath+FN) Then
        Begin
         Inc(Users);
         UIdx[Users]:=FilePos(PersonalIdxFile)-1;
        End;
      End;
    End;
  End;
 If Users=0 Then
  Begin
    Window(1,1,80,25);
    Box(18,9,43,6);
    GotoXY(20,11); XWrite('^\07Sorry, there are no personal dictionar-');
    GotoXY(20,12); XWrite('^\07ies available for editing at this time.');
    GotoXY(20,14); XWrite('^\07                         Press any key.');
    ReadKey;
    RestoreScreen(3);
    RestoreScreen(5);
    Exit;
  End;
 Hil:=1; Top:=0;
 TextAttr:=$07; ClrScr;
 Max:=8; If Max>Users Then Max:=Users;
 For Tmp:=1 To Max Do
  Begin
   Seek(PersonalIdxFile,UIdx[Tmp]);
   Read(PersonalIdxFile,PersonalIdx);
   GotoXY(1,Tmp); Write(' ',Pad(X(PersonalIdx),31));
  End;
 Repeat
  Seek(PersonalIdxFile,UIdx[Hil+Top]); Read(PersonalIdxFile,PersonalIdx);
  GotoXY(1,Hil); TextAttr:=$1F; Write(' ',Pad(X(PersonalIdx),31));
  C:=UpCase(ReadKey);
  GotoXY(1,Hil); TextAttr:=$07; Write(' ',Pad(X(PersonalIdx),31));
  Case C Of
    #13: Begin EditDic(UIdx[Top+Hil]); If PersonalDic Then C:=#27; End;
    #00: Case ReadKey Of
          'H': Begin
                Dec(Hil);
                If Hil=0 Then
                 Begin
                  Inc(Hil);
                  If Top>0 Then
                   Begin
                    Dec(Top);
                    GotoXY(1,1); InsLine;
                    Seek(PersonalIdxFile,UIdx[Hil+Top]); Read(PersonalIdxFile,PersonalIdx);
                    GotoXY(1,1); Write(' ',Pad(X(PersonalIdx),31));
                   End;
                 End;
               End;
          'P': Begin
                If Hil+1<=Users Then Inc(Hil);
                If Hil=9 Then
                 Begin
                  Dec(Hil);
                  If Top+Hil+1<=Users Then
                   Begin
                    Inc(Top);
                    GotoXY(1,1); DelLine;
                    Seek(PersonalIdxFile,UIdx[Hil+Top]); Read(PersonalIdxFile,PersonalIdx);
                    GotoXY(1,8); Write(' ',Pad(X(PersonalIdx),31));
                   End;
                 End;
               End;
         End;
   End;
 Until C=#27;
 RestoreScreen(5);
 RestoreScreen(3);
 Close(PersonalIdxFile);
 If PersonalDic Then
  Begin
   StatWrite('^\0FCurrent Dictionary: Personal Dictionary, +FN');
   Exit;
  End;
 If ChangedIndex Then OpenSection;
End;

Procedure LoadConfig;
Begin
 CfgPath:=FExpand(GetEnv('OEDIT'));
 cfgpath:= (cfgpath+'\DICT');

 If CfgPath[Length(CfgPath)]<>'\' Then CfgPath:=CfgPath+'\';
   CfgPath:=FExpand(RemoveWildCard(ParamStr(0)));
   Assign(ConfigFile,CfgPath+'OEDIT.CFG');
   FileMode:=66; {$I-} Reset(ConfigFile); {$I+} FileMode:=2;

 { * Check in current directory                      }
 If IOResult<>0 Then
  Begin
   CfgPath:=FExpand(''); Assign(ConfigFile,CfgPath+'OEDIT.CFG');
   FileMode:=66; {$I-} Reset(ConfigFile); {$I+} FileMode:=2;
  End;

 { * Check in execution path                         }
 If IOResult<>0 Then
  Begin
   CfgPath:=FExpand(RemoveWildCard(ParamStr(0)));
   Assign(ConfigFile,CfgPath+'OEDIT.CFG');
   FileMode:=66; {$I-} Reset(ConfigFile); {$I+} FileMode:=2;
  End;

 { * Can't find the damned thing                     }
 If IOResult<>0 Then
  Begin
   Writeln('');
   WriteLn('ž Cannot locate OEDIT.CFG.  Please run DICTEDIT from the Open!Edit directory.');
   Halt;
  End;
{ Read(ConfigFile,Config);}
 Close(ConfigFile);

  If Config.DictionaryPath[Length(Config.DictionaryPath)]<>'.\DICT' Then
    Config.DictionaryPath:=Config.DictionaryPath+'.\DICT\';

{ writeln(cfgpath);
 delay(2000);}

End;

Procedure PackFile;
Var
 Fin,Fout: File;
 S: String;
 NR: Word;
 XPacked: Boolean;
Begin
 XPacked:=False;
 Assign(Fin,PDN);
 Reset(Fin,1);
 Assign(Fout,'$$DICTMP.$$$');
 ReWrite(Fout,1);
 Repeat
  BlockRead(Fin,S[0],1,NR);
  BlockRead(Fin,S[1],Ord(S[0]),NR);
  If NR<>0 Then
   Begin
    If S<>MakeStr(Length(S),#255) Then BlockWrite(FOut,S,Length(S)+1) Else XPacked:=True;
   End;
 Until NR=0;
 Close(Fout);
 Close(Fin);
 If XPacked Then
  Begin
   Erase(Fin);
   Rename(Fout,PDN);
  End
  Else
  Begin
   Erase(Fout);
  End;
End;

Begin {Main}
 LoadConfig;

 Assign(IdxFile,Config.DictionaryPath+'OE_DIC.IDX');
 {$I-} Reset(IdxFile); {$I+}
 If IOresult<>0 Then
  Begin
   writeln('');
   WriteLn('ž Could not locate ',Config.DictionaryPath+'OE_DIC.IDX!');
   Writeln('ž Make sure OE_DIC.IDX is located in the .\DICT directory.');
   Halt;
  End;
 Assign(DatFile,Config.DictionaryPath+'OE_DIC.DAT');
 {$I-} Reset(DatFile,1); {$I+}
 If IOresult<>0 Then
  Begin
   writeln('');
   WriteLn('ž Could not locate ',Config.DictionaryPath+'OE_DIC.DAT!');
   Writeln('ž Make sure OE_DIC.DAT is located in the .\DICT directory.');
   Halt;
  End;

 PersonalDic:=False;
 Section:='A';
(* DES(Mem[Seg(EncVer):Ofs(EncVer)+1],Mem[Seg(Ver):Ofs(Ver)+1],KeyVer,False);  { Decrypt version number }*)
 Ver[0]:=#5;
 CursorOff;
 FillScr(#176,$07);
 TextAttr:=$0F; GotoXY(1,1); ClrEol;
 TextAttr:=$01; GotoXY(1,2); Write(MakeStr(80,#196));
 TextAttr:=$01; GotoXY(1,24); Write(MakeStr(80,#196));
 TextAttr:=$0F; GotoXY(1,25); ClrEol;
 Write(' Open!Edit v'+Ver+' Dictionary Editor                              [ESC] to exit ');
 Box(4,4,72,4);
 TextAttr:=$07;
 Center('Open!Edit v'+Ver+' Dictionary Editor',6);
 Center('Copyright (C) 2011, By Shawn Highfield',7);

 Box(3,12,36,8);
 Box(43,13,34,5);
 GotoXY(45,15); XWrite('^\0FENTER^\07 Edit Word  ^\0FINS^\07 Add Word');
 GotoXY(45,16); XWrite('^\0FA-Z,!^\07 Section    ^\0FDEL^\07 Kill Word');
 GotoXY(45,17); XWrite('^\0FHOME ^\07 Personal Dictionaries');

 IndexCnt:=0;

 Window(5,13,37,20);
 Top:=0; Hil:=1;
 OpenSection;
 Redisp;
 Repeat
  GotoXY(1,Hil); TextAttr:=$1F; Write(' '+Pad(GetWord(Top+Hil),31));
  C:=ReadKey;
  GotoXY(1,Hil); TextAttr:=$07; Write(' '+Pad(GetWord(Top+Hil),31));
  If Not (C in ['A'..'Z']) Then SearchFor:='';
  Case UpCase(C) Of
    'A'..'Z','!': If Not PersonalDic Then Begin Section:=UpCase(C); OpenSection; Top:=0; Hil:=1; ReDisp; End;
    #27: If PersonalDic Then
          Begin
           TextAttr:=$07;
           ClrScr;
           StatWrite('^\0FPacking user dictionary, please wait...');
           Close(DatFile);
           PackFile;
           PersonalDic:=False;
           Window(1,1,80,25);
           GotoXY(45,15); XWrite('^\0FENTER^\07 Edit Word  ^\0FINS^\07 Add Word');
           GotoXY(45,16); XWrite('^\0FA-Z,!^\07 Section    ^\0FDEL^\07 Kill Word');
           GotoXY(45,17); XWrite('^\0FHOME ^\07 Personal Dictionaries');
           Window(5,13,37,20);
           Assign(DatFile,Config.DictionaryPath+'OE_DIC.DAT');
           Reset(DatFile,1);
           OpenSection; C:=#255;
           Top:=0; Hil:=1; Redisp;
          End;
    #13: If GetWord(Top+Hil)<>'[empty]' Then
          Begin
           GotoXY(2,Hil); S2:=GetWord(Top+Hil);
           Read_StrLF:=False;
           Read_Str(S1,30,S2);
           If (Length(S1)=Length(S2)) And (Copy(S1,1,3)=Copy(S2,1,3)) Then
            Begin
             SetWord(Top+Hil,S1);
            End
            Else
            Begin
             SetWord(Top+Hil,MakeStr(Length(S2),#255));
             Close(DatFile);
             AddMainDic(S1);
             Reset(DatFile,1);
             PersonalReload;
            End;
          End;
    #0: Case ReadKey Of
          'S': Begin SetWord(Top+Hil,MakeStr(Length(GetWord(Top+Hil)),#255)); End;
          'I': If PersonalDic Then AddMainDic(GetWord(Top+Hil));
          'R': Begin AddNewWord; PersonalReload; End;
          'G': If Not PersonalDic Then
                Begin
                 PersonalDics;
                 If PersonalDic Then
                  Begin
                   Hil:=1; Top:=0; Redisp;
                   Window(1,1,80,25);
                   GotoXY(45,15); XWrite('^\0FENTER^\07 Edit Word  ^\0FINS^\07 Add Word');
                   GotoXY(45,16); XWrite('^\0FDEL  ^\07 Kill Word  ^\0FESC^\07 Main Dic');
                   GotoXY(45,17); XWrite('^\0FPGUP ^\07 Add word to main dic   ');
                   Window(5,13,37,20);
                  End;
                End;
          'H': Begin
                Dec(Hil);
                If Hil=0 Then
                 Begin
                  Inc(Hil);
                  If Top>0 Then
                   Begin
                    Dec(Top);
                    GotoXY(1,1); InsLine;
                    GotoXY(1,1); Write(' '+Pad(GetWord(Top+Hil),31));
                   End;
                 End;
               End;
          'P': Begin
                If Hil+1<=IndexCnt Then Inc(Hil);
                If Hil=9 Then
                 Begin
                  Dec(Hil);
                  If Top+Hil+1<=IndexCnt Then
                   Begin
                    Inc(Top);
                    GotoXY(1,1); DelLine;
                    GotoXY(1,8); Write(' '+Pad(GetWord(Top+Hil),31));
                   End;
                 End;
               End;

         End;
   End;
 Until C=#27;
 Window(1,1,80,25);
 ClrScr;
 TextAttr:=$01;
 WriteLn('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
 TextAttr:=$07;
 WriteLn('                      Open!Edit v'+Ver+' Dictionary Editor');
 WriteLn('                     Copyright (C) 2011, By Shawn Highfield');
 TextAttr:=$01;
 WriteLn('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
 TextAttr:=$07;
 WriteLn;
 Close(IdxFile);
 Close(DatFile);
 CursorOn;
End.


