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
  LDA #%10010000   ; включить NMI
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

  LDA #$0f;#$0f
  STA PPUDATA
  LDA #$10;#$26
  STA PPUDATA
  LDA #$30
  STA PPUDATA
  LDA #$30
  STA PPUDATA

  lda #$23          ; Старший байт адреса Attribute Table ($23C0)
  sta $2006
  lda #$C0          ; Младший байт адреса Attribute Table
  sta $2006

  ldx #64           ; Всего 64 байта атрибутов на одну nametable
  lda #$00          ; Значение 0 назначает палитру 0 всем блокам
clear_attributes:
  sta $2007         ; Записываем нули в PPU
  dex
  bne clear_attributes

  ; init variables
  LDX #$00
  STX write_ptr
  STX read_ptr

  LDA #%00001110 ; фон + спрайты
  STA PPUMASK

  LDA #$20
  STA cursor_raw_h
  LDA #$20
  STA cursor_raw_l
  
  LDX #00
  put_string:
    LDA hello_string,X
    CMP #$00
    BEQ after_string
    STA stdout_buffer,X
    INC write_ptr
    INX
    JMP put_string

  after_string:
    JSR $FF81

  loop:
  JMP loop
.endproc

.segment "RODATA"

hello_string:
  .byte "BIOS v. 0.1", $0a, $0
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