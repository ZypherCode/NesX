.include "jmptable.inc" 

.segment "CODE"
.proc kernel_init
  LDA #'K'
  JSR CHROUT
  LDA #'E'
  JSR CHROUT
  LDA #'R'
  JSR CHROUT
  LDA #'N'
  JSR CHROUT
  LDA #'E'
  JSR CHROUT
  LDA #'L'
  JSR CHROUT
  LDA #$0a
  JSR CHROUT

  JSR chrin
  JSR CHROUT

  mainloop:
    JMP mainloop

  LDA #$0  ; Exit code
  RTS
.endproc

.import stdout_buffer
.import write_ptr
.proc chrout
  LDX write_ptr
  STA stdout_buffer,X
  INC write_ptr
  RTS
.endproc

.import key_state_current
.import key_state_prev
.import key_state_changed
.proc chrin
  JSR scan_kb

  search_pressed:
  LDX #$08
  LDA key_state_changed
  AND key_state_current
  BNE return
  DEX
  CMP #$00
  BNE search_pressed
  JMP chrin

return:
  CLC
  TXA
  ADC #$30
  RTS
.endproc

.import scan_kb
.proc scnkey
  JSR scan_kb
  RTS
.endproc

.segment "RODATA"

.segment "JMPTABLE"
  JMP kernel_init
  JMP scnkey
  JMP chrin
  JMP chrout
  