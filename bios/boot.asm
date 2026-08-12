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

  key_state_current: .res 9
  key_state_prev: .res 9
  key_state_changed: .res 9

  .export stdout_buffer
  .export write_ptr
  .export read_ptr
  .export cursor_raw_l
  .export cursor_raw_h
  .export nmi_counter
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
  LDA #$10
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

  ; init variables
  LDX #$00
  STX write_ptr
  STX read_ptr

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

  ; .byte "  ", $b0, $b0, $b0, $b1, $b1, $b2, $b2, $db, " NesX v.0.1 ", $db, $b2, $b2, $b1, $b1, $b0, $b0, $b0, $0a, $0a
  ; .byte "  CPU: Ricoh RP2A03(07)", $0a
  ; .byte "  FRQ: 1.66-1.79 MHz", $0a
  ; .byte "  RAM: 260/2048 bytes", $0a, $0a
  ; .byte "  Kernel: NesX 0.0", $0a
  ; .byte "  Shell: XSH 0.0", $0a
  ; .byte "  FS: NRFS", $0a
  ; .byte "~$ ", $00  

.segment "VECTORS"
  .addr nmi_handler, reset_handler, irq_handler

.segment "CHR"
  .incbin "ascii.chr"
.segment "STARTUP"