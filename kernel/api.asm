.include "jmptable.inc" 

.segment "CODE"
.proc kernel_init
  LDX #$00
  @print:
    LDA ready,X
    CMP #$00
    BEQ mainloop
    JSR CHROUT
    INX
    JMP @print

  mainloop:
    JSR CHRIN
    JSR CHROUT
    JMP mainloop

  LDA #$0  ; Exit code
  RTS
.endproc

.import stdout_buffer
.import write_ptr
.proc chrout
  TAY
  TXA
  PHA
  TYA
  LDX write_ptr
  STA stdout_buffer,X
  INC write_ptr
  PLA
  TAX
  RTS
.endproc

.import key_state_current
.import key_state_prev
.import key_state_changed
.proc chrin
  JSR scan_kb
  
  LDX #$08
  chkrows:
    LDA key_state_current,X
    AND key_state_changed,X
    BEQ continue

    TXA
    ASL
    ASL
    ASL
    TAY  ; now Y is an index of key_layout

    LDA key_state_current,X
    AND key_state_changed,X 
    AND #%10000000
    BNE return
    INY
    LDA key_state_current,X
    AND key_state_changed,X 
    AND #%01000000
    BNE return
    INY
    LDA key_state_current,X
    AND key_state_changed,X 
    AND #%00100000
    BNE return
    INY
    LDA key_state_current,X
    AND key_state_changed,X 
    AND #%00010000
    BNE return
    INY
    LDA key_state_current,X
    AND key_state_changed,X 
    AND #%00001000
    BNE return
    INY
    LDA key_state_current,X
    AND key_state_changed,X 
    AND #%00000100
    BNE return
    INY
    LDA key_state_current,X
    AND key_state_changed,X 
    AND #%00000010
    BNE return
    INY
    LDA key_state_current,X
    AND key_state_changed,X 
    AND #%00000001
    BNE return
    INY
  
  continue:
    DEX
    BPL chkrows
    JMP chrin

return:
  ; ignore if only shift pressed
  CPY #60  
  BEQ chrin

  ; upper if shift pressed
  LDX #7
  LDA key_state_current,X
  AND #%00001000
  BNE with_shift
  LDA key_layout,Y
  RTS

  with_shift:
  LDA shifted_key_layout,Y
  RTS
.endproc

.import scan_kb
.proc scnkey
  JSR scan_kb
  RTS
.endproc

.segment "RODATA"
ready:
  .byte "NesX shell", $0a, "READY.", $0a, $0

key_layout:
  .byte $38, $0a, "[]\SY", $01
  .byte $37, "@;'-/=^"
  .byte $36, "olk,.p0"
  .byte $35, "iujmn98"
  .byte $34, "yghbv76"
  .byte $33, "trdfc54"
  .byte $32, "wsaxze3"
  .byte $31, "EqC G12"
  .byte $31, $1e, $10, $11, $1f, " DI"

shifted_key_layout:
  .byte $38, $0a, "{}\SY", $01
  .byte $37, "@:", '"', "_?+^"
  .byte $36, "OLK<>P)"
  .byte $35, "IUJMN(*"
  .byte $34, "YGHBV&^"
  .byte $33, "TRDFC%$"
  .byte $32, "WSAXZE#"
  .byte $31, "EqC G!@"
  .byte $31, $1e, $10, $11, $1f, " DI"

.segment "JMPTABLE"
  JMP kernel_init
  JMP scnkey
  JMP chrin
  JMP chrout
  