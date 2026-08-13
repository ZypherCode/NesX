.include "constants.inc" 

.segment "HEADER"
  .include "header.inc"

.segment "ZEROPAGE"

.segment "BSS"
  stdout_buffer: .res 256
  write_ptr: .res 1
  read_ptr: .res 1

  cursor_raw_l: .res 1
  cursor_raw_h: .res 1
  nmi_counter: .res 1
  scroll: .res 1
  ppu_ctrl: .res 1  ; a copy of $2000
  allow_scroll: .res 1

  key_state_current: .res 9
  key_state_prev: .res 9
  key_state_changed: .res 9

  .export stdout_buffer
  .export write_ptr
  .export read_ptr
  .export cursor_raw_l
  .export cursor_raw_h
  .export nmi_counter
  .export scroll
  .export ppu_ctrl
  .export allow_scroll
  .export key_state_current
  .export key_state_prev
  .export key_state_changed

.segment "CODE"

.proc irq_handler
  RTI
.endproc

.import nmi_handler
.import scan_kb

.proc reset_handler
  SEI
  CLD
  LDA #%10010000  ; enable NMI
  STA ppu_ctrl
  STA PPUCTRL

  vblankwait:
    BIT PPUSTATUS
    BPL vblankwait

  ; filling paletts
  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$00
  STX PPUADDR

  LDA #$0f
  STA PPUDATA
  LDA #$2a
  STA PPUDATA
  LDA #$30
  STA PPUDATA
  LDA #$30
  STA PPUDATA

  ; filling attributes table
  lda #$23
  sta $2006
  lda #$C0
  sta $2006

  ldx #64
  lda #$00
clear_attributes:
  sta $2007
  dex
  bne clear_attributes

  lda #$2b
  sta $2006
  lda #$C0
  sta $2006

  ldx #64
  lda #$00
clear_attributes2:
  sta $2007
  dex
  bne clear_attributes2

  ; init variables
  LDX #$00
  STX write_ptr
  STX read_ptr
  STX allow_scroll
  LDX #0
  STX scroll

  ; enable render
  LDA #%00001110
  STA PPUMASK

  ; set cursor position
  LDA #$20
  STA cursor_raw_h
  LDA #$20
  STA cursor_raw_l

  ; init kernel
  JSR $FF81  

  loop:
  JMP loop
.endproc

.segment "RODATA"

.segment "VECTORS"
  .addr nmi_handler, reset_handler, irq_handler

.segment "CHR"
  .incbin "ascii.chr"
.segment "STARTUP"