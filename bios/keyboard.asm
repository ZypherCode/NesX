.include "constants.inc"

.segment "CODE"

.import key_state_current
.import key_state_prev
.import key_state_changed
.export scan_kb
.proc scan_kb
  LDX #8
  @copy_curr2prev:
  LDA key_state_current,X
  STA key_state_prev,X
  DEX
  BPL @copy_curr2prev

  @read:
;Reads the keyboard matrix state.
  lda #$05
  sta $4016          ;reset keyboard
  nop
  nop
  nop
  nop
  nop
  nop                ;wait for keyboard to get ready
  
;Read all 9 rows in column 0 and 1:
  ldx #$00           ;loop counter
@loop_r:

;Read column 0 keys:
  lda #$04           ;select colum 0 (from second lap: also select next row)
  sta $4016
  ldy #$0A           ;loop counter
@wait1:
  dey
  bne @wait1
  nop
  nop                ;wait to give time to scan all keys
  lda $4017          ;read key state of selected row and column
  lsr a              ;right shift to get key state into low nibble
  and #$0F           ;clear high nibble
  sta key_state_current+0,x  ;save column 0 key states in RAM

;Read column 1 keys:
  lda #$06           ;select colum 1
  sta $4016
  ldy #$0A           ;loop counter
@wait2:
  dey
  bne @wait2
  nop
  nop                ;wait to give time to scan all keys
  lda $4017          ;read key status of selected row and column
  rol a
  rol a
  rol a              ;rotate left to get key status to high nibble
  and #$F0           ;clear low nibble
  ora key_state_current+0,x  ;merge A with column 0 key status
  eor #$FF           ;invert key states so that 0=unpressed
  ldy #$08           ;loop counter for 8 bits
@store:
  asl a              ;shift bit 7 left into carry
  ror key_state_current+0,x  ;store key state bit to RAM from carry
  dey
  bne @store         ;loop for storing all 8 bits in RAM
  
  inx
  cpx #$09
  bne @loop_r        ;loop for all 9 rows

  LDX #8
  @get_changed:
  LDA key_state_current,X
  EOR key_state_prev,X
  STA key_state_changed,X
  DEX
  BPL @get_changed
  
  rts
.endproc