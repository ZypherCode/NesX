.include "constants.inc"

.segment "CODE"

.import stdout_buffer
.import write_ptr
.import read_ptr

.import cursor_raw_l
.import cursor_raw_h
.import nmi_counter
.import scroll
.import ppu_ctrl
.import allow_scroll

.proc check_borders
  LDA cursor_raw_h
  CMP #$23
  BNE check_nt2
  LDA cursor_raw_l
  CMP #$c0
  BNE return

  LDA #$28
  STA cursor_raw_h
  LDA #$00
  STA cursor_raw_l
  LDA #$ff
  STA allow_scroll

  check_nt2:
  LDA cursor_raw_h
  CMP #$2b
  BNE return
  LDA cursor_raw_l
  CMP #$c0
  BNE return

  LDA #$20
  STA cursor_raw_h
  LDA #$00
  STA cursor_raw_l

return:
  JSR do_scroll
  RTS
.endproc

.proc do_scroll
  LDX #$00
  LDA allow_scroll
  BEQ return

  CLC
  LDA scroll
  ADC #8
  TAX
  CMP #240
  BNE return
  LDA #$0
  STA scroll
  LDA ppu_ctrl
  EOR #%00000010
  STA ppu_ctrl
  STA PPUCTRL
  RTS
  
return:
  STX scroll
  LDX PPUSTATUS
  LDX cursor_raw_h
  STX PPUADDR
  LDX cursor_raw_l
  STX PPUADDR
  LDX #32
  clear:
    LDA $20
    STA PPUDATA
    DEX
    CPX #$0
    BNE clear

  RTS
.endproc

.proc new_line
  LDA #$20  ; This symbol clears the cursor. Do not use #$0a here!
  JSR draw_char

  LDA cursor_raw_l
  AND #%11110000
  STA cursor_raw_l

  AND #%00010000
  BEQ if_even

  if_odd:
    CLC
    LDA cursor_raw_l
    ADC #$10
    STA cursor_raw_l
    BNE return
    INC cursor_raw_h
    JMP return

  if_even:
    CLC
    LDA cursor_raw_l
    ADC #$20
    STA cursor_raw_l
    BNE return
    INC cursor_raw_h

return:
  JSR check_borders

  LDX PPUSTATUS
  LDX cursor_raw_h
  STX PPUADDR
  LDX cursor_raw_l
  STX PPUADDR
  RTS
.endproc

.proc draw_char ; A = tile 
  CMP #$0a
  BNE draw
  JSR new_line
  RTS

draw:
  STA PPUDATA 
  INC cursor_raw_l
  BNE return
  INC cursor_raw_h

return:
  LDA cursor_raw_l
  AND #%00011111
  BNE no_check

  JSR check_borders

  no_check:
  RTS 
.endproc

.export nmi_handler
.proc nmi_handler
  pha     ; Сохранить A
  txa     ; Передать X в A
  pha     ; Сохранить X
  tya     ; Передать Y в A
  pha     ; Сохранить Y
  php     ; Сохранить флаги (процессорный статус)

  INC nmi_counter

  LDX PPUSTATUS
  LDX cursor_raw_h
  STX PPUADDR
  LDX cursor_raw_l
  STX PPUADDR

  LDY #$0
print_stdout:
  LDX read_ptr
  CPX write_ptr
  BEQ exit

  CPY #3
  BEQ exit

  LDX read_ptr
  LDA stdout_buffer,X
  JSR draw_char
  INC read_ptr

  INY
  JMP print_stdout

exit:
  LDA nmi_counter
  AND #%00010000
  BNE hide_cursor
  LDA #$db
  STA PPUDATA
  JMP oamdma
  hide_cursor:
  LDA #$20
  STA PPUDATA
  oamdma:

  ; LDA PPUSTATUS
  ; LDA #$00
  ; STA OAMADDR
  ; LDA #$20
  ; STA OAMDMA

  LDA #$00  ; Отключить скроллинг
  STA $2005
  LDA scroll
  STA $2005

  plp     ; Восстановить флаги
  pla     ; Восстановить Y
  tay     ; Передать из A в Y
  pla     ; Восстановить X
  tax     ; Передать из A в X
  pla     ; Восстановить A

  RTI
.endproc