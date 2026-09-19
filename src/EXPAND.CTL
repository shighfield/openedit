;
; Open!EDIT Phrase Expansion Control File
; Copyright (c) 2011, by Shawn Highfield
;
; Any text after a semicolon (;) is ignored.
;
; The format of this file is:
;
; <originaltext> <newtext>
;
;    <originaltext> is the text that the USER should type in, i.e. "L8r".
;    <newtext>      is the text that Open!EDIT should replace <originaltext>
;                   with, i.e. "Later".
;
; The only restrictions on phrases in this file are that:
;  1) neither <originaltext> nor <newtext> may be longer than 20 characters.
;  2) <originaltext> may not contain any spacees.
;
; Examples:
;
; L8r Later
; (Expands "L8r" into "Later")
;
; TTYL Talk tp you later
; (Expands "TTYL" into "Talk to you later")
;

TTYL Talk to you later
FRUIT Beer is good

