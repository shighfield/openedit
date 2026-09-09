Const
 BlaBla: String[8] = '+++BLAHT';
{ EncVer: String[8] = 'Í<ÅºG'#236'z±'; {v1.72a  }
{ EncVer: String[8] = '0.99a        ';}
 Ver   : String[8] =  '0.99k        ';
 KeyVer: array[1..8] of Char = '§®NS†ç§ä';
 LangCnt           = 103;

Type
 ConfigRec      = Record
   CfgHeader: String[35];
   ExpandWord: Array[0..9,1..2] Of String[25];
   NC,HC,BC,PC,FZ,FC,FL,FS,FD,IC,ID,IL,IS: Byte;
   TabStop: Byte;
   CensorChar: Char;

   DataUEC: LongInt;

   TearLine: Byte;

   RegName: String[40];                                         { SysOpname }

   MaxQuotePct: Real;
   ForceLessQuote: Boolean;

   VowelCensorOnly,
   RandomSymbolCensor: Boolean;

   AbsMaxMsgLines: LongInt;

   DOSSwap: Word;                                    {AltJSwap,UseXMS,UseEMS}

   ForceCtlW: Boolean;

   SpellCheck: Byte; {0=No, 1=Yes, 2=Ask}
   DictionaryPath: String[60];

   RA250: Boolean;                                                {VersionID}

   ImportSecurity,
   ExportSecurity: LongInt;

   ScrollSiz: Byte;

   CensorWords: Array[1..15] Of String[10];

   TimeOutDelay: Byte;
   ExtendedChars: Byte;

   UseExpand,
   Censor,
   UseSigs,
   UseFilter: Boolean;

   DateFormat: Byte;   { 0=DD-Mmm-YY 1=DD-MM-YY 2=MM-DD-YY }
   TimeFormat: Byte;   { 0=01:00pm 1=13:00 }

   RepStr: String[15];

   AutoSave: Boolean;

   LanguageFile: String[8];
   OKSigHiBit: Boolean;

   FieldColor: Byte;

   WrapMargin: Byte;

   Extra: Array[1..6532] Of Byte;

   StartDate: LongInt;
   CfgVer: String[5];

  End;


 SigType        = Array[1..5] Of String[69];
 UserRec        = Record
   NameCRC      : LongInt;
   Expand       : Array[0..9,1..2] Of String[25];
   NC,HC,BC,PC,FZ,FC,FL,FS,FD,IC,ID,IL,IS: Byte;
   UseTagLines,
   UseExpand,
   UseKeywords  : Boolean;
   TagKeyword   : Array[1..4] Of String[10];
   ChgdColors   : Boolean;
   SigPtr       : LongInt;
   UseSpellChk  : Boolean;
   AutoTagline  : Boolean;
   AutoSigs     : Boolean;
   Name         : String[35];
   LangFile     : String[8];
   FieldColor   : Byte;
   Extra        : Array[1..82] Of Byte;
  End;

