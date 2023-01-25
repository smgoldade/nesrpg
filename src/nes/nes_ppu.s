; Author: Steven Goldade
.include "nes_ppu.inc"
.include "nes_zeropage.inc"

PPU_CTRL = $2000    ; V - VBlank NMI (0: off, 1: on)
                    ; P - PPU Master Slave (0: read from EXT, 1: output on EXT)
                    ; H - Sprite Size (0: 8x8 sprite, 1: 8x16 sprite)
                    ; B - Background Pattern Table Address (0: $0000, 1: $1000)
                    ; S - Sprite Pattern Table Address (0: $0000, 1: $1000)
                    ; I - VRAM Increment per R/W of PPU_DATA (0: 1, 1: $20)
                    ; NN - Base Name Table Address (0: $2000, 1: $2400, 2: $2800, 3: $2C00)
PPU_MASK = $2001    ; B - Emphasize blue
                    ; G - Emphasize green
                    ; R - Emphasize red
                    ; s - Show Sprites
                    ; b - Show Background
                    ; M - Show sprites in leftmost 8 pixels
                    ; m - Show background in leftmost 8 bixels
                    ; G - Grayscale
PPU_STATUS = $2002  ; V - vblank has started
                    ; S - Sprite 0 Hit
                    ; O - Sprite overflow
                    ; ..... - Open Bus

PPU_SCROLL = $2005
PPU_ADDR = $2006
PPU_DATA = $2007

NAMETABLE_0 = $2000
.export _NAMETABLE_0 = NAMETABLE_0
ATTRIBUTE_TABLE_0 = $23C0
.export _ATTRIBUTE_TABLE_0 = ATTRIBUTE_TABLE_0
NAMETABLE_1 = $2400
.export _NAMETABLE_1 = NAMETABLE_1
ATTRIBUTE_TABLE_1 = $27C0
.export _ATTRIBUTE_TABLE_1 = ATTRIBUTE_TABLE_1
NAMETABLE_2 = $2800
.export _NAMETABLE_2 = NAMETABLE_2
ATTRIBUTE_TABLE_2 = $2BC0
.export _ATTRIBUTE_TABLE_2 = ATTRIBUTE_TABLE_2
NAMETABLE_3 = $2C00
.export _NAMETABLE_3 = NAMETABLE_3
ATTRIBUTE_TABLE_3 = $2FC0
.export _ATTRIBUTE_TABLE_3 := ATTRIBUTE_TABLE_3

NT_BUFFER = $0700

BACKGROUND_PALETTE = $3F00
SPRITE_PALETTE := $3F10

.code
;void __fastcall__ ppu_off();
.proc _ppu_off
    lda ZP_PPU_MASK
    and #%11100111
    sta ZP_PPU_MASK
    jmp _ppu_wait_nmi
.endproc

;void __fastcall__ ppu_on();
.proc _ppu_on
    lda ZP_PPU_MASK
    ora #%00011000
    sta ZP_PPU_MASK
    jmp _ppu_wait_nmi
.endproc

;void __fastcall__ ppu_wait_nmi(void);
.proc _ppu_wait_nmi
    lda ZP_PPU_FRAME_CNT
@1:
    cmp ZP_PPU_FRAME_CNT ;ZP_PPU_FRAME_CNT incremented at the end of NMI, once it changes we know the NMI happened
    beq @1
    rts
.endproc

; void __fastcall__ ppu_set_addr(u16 addr);
.proc _ppu_set_addr
    stx PPU_ADDR
    sta PPU_ADDR
    rts
.endproc

; void __fastcall__ ppu_write(const u8* data, u16 size);
.import popax
.proc _ppu_write
    sta ZP_LEN
    stx ZP_LEN+1
    jsr popax
    sta ZP_PTR
    stx ZP_PTR+1
    ldy #$00
@1:
    lda (ZP_PTR),y  ; A = *PTR
    sta PPU_DATA    ; PPU_DATA = A
    inc ZP_PTR      ; ++PTR_LO
    bne @2          ; IF PTR_LO == 0
    inc ZP_PTR+1    ;    ++PTR_HI
@2:
    dec ZP_LEN      ; --LEN_LO
    bne @1          ; IF LEN_LO != 0 JMP @1
    cpy ZP_LEN+1    ; IF LEN_HI == 0
    bne @3          ;
    rts             ;    RETURN
@3:
    dec ZP_LEN+1    ; ELSE LEN_HI--
    jmp @1          ; JMP @1
.endproc

; void __fastcall__ ppu_nmi_nt_update(const u8* data, u8 size, u8 nametable, u8 x, u8 y);
.import popa
.proc _ppu_nmi_nt_update
    ldy ZP_NT_BUF_LEN
    sta NT_BUFFER,y
    jsr popax
    sta ZP_PTR
    stx ZP_PTR+1
    lda ZP_PTR+1
    asl
    asl
    sta ZP_PTR+1
    ldy ZP_NT_BUF_LEN
    lda NT_BUFFER,y
    lsr
    lsr
    lsr
    clc
    adc ZP_PTR+1
    sta ZP_PTR+1
    lda NT_BUFFER,y
    asl
    asl
    asl
    asl
    asl
    clc
    adc ZP_PTR
    sta ZP_PTR
    lda ZP_PTR+1
    adc #>NAMETABLE_0
    sta NT_BUFFER,y
    iny
    lda ZP_PTR
    sta NT_BUFFER,y
    iny
    sty ZP_NT_BUF_LEN
    jsr popax
    ldy ZP_NT_BUF_LEN
    clc
    sbc #$00
    sta ZP_LEN
    sta NT_BUFFER,y
    iny
    sty ZP_NT_BUF_LEN
    stx ZP_PTR
    jsr popa
    sta ZP_PTR+1
    ldy ZP_LEN
    tya
    clc
    adc ZP_NT_BUF_LEN
    sta ZP_NT_BUF_LEN
    tax
@1:
    lda (ZP_PTR),y
    sta NT_BUFFER,x
    dex
    dey
    bpl @1
    rts
.endproc

.proc ppu_wait
    bit PPU_STATUS
    bpl ppu_wait
    rts
.endproc

.rodata
; defines one step darker for each palette color
DARKEN_COLORS:  .byte $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F
                .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0F, $0F, $0F
                .byte $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1A, $1B, $1C, $0F, $0F, $0F
                .byte $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2A, $2B, $2C, $2D, $0F, $0F
; defines one step lighter for each palette color
LIGHTEN_COLORS: .byte $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1A, $1B, $1C, $2D, $2D, $2D
                .byte $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2A, $2B, $2C, $2D, $2D, $2D
                .byte $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3A, $3B, $3C, $3D, $2D, $2D
                .byte $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $2D, $2D

.code
;nes_color __fastcall__ ppu_darken_color(nes_color color)
.proc _ppu_darken_color
    tax
    lda DARKEN_COLORS,x
    rts
.endproc

;nes_color __fastcall__ ppu_lighten_color(nes_color color)
.proc _ppu_lighten_color
    tax
    lda LIGHTEN_COLORS,x
    rts
.endproc

;void __fastcall__ ppu_darken_bg(void)
.proc _ppu_darken_bg
    ldy #$00
@1:
    lda ZP_BG_PALETTE,y
    jsr _ppu_darken_color
    sta ZP_BG_PALETTE,y
    iny
    cpy #$10
    bne @1
    jmp ppu_set_bg_palette_update
.endproc

;void __fastcall__ ppu_lighten_bg(void)
.proc _ppu_lighten_bg
    ldy #$00
@1:
    lda ZP_BG_PALETTE,y
    jsr _ppu_lighten_color
    sta ZP_BG_PALETTE,y
    iny
    cpy #$10
    bne @1
    jmp ppu_set_bg_palette_update
.endproc

;void __fastcall__ ppu_bg_palette(const nes_palette* data);
.proc _ppu_bg_palette
    sta ZP_PTR
    stx ZP_PTR+1
    ldy #$0F
@1:
    lda (ZP_PTR),y
    sta ZP_BG_PALETTE,y
    dey
    bpl @1
    jmp ppu_set_bg_palette_update
.endproc

.proc ppu_set_bg_palette_update
    lda ZP_PPU_UPDATE
    ora #%00000001
    sta ZP_PPU_UPDATE
    rts
.endproc

;void __fastcall__ ppu_spr_palette(const nes_palette* data);
.proc _ppu_spr_palette
    sta ZP_PTR
    stx ZP_PTR+1
    ldy #$0F
@1:
    lda (ZP_PTR),y
    sta ZP_SPR_PALETTE,y
    dey
    bpl @1
    jmp ppu_set_spr_palette_update
.endproc

.proc ppu_set_spr_palette_update
    lda ZP_PPU_UPDATE
    ora #%00000010
    sta ZP_PPU_UPDATE
    rts
.endproc

;--------------------------
; OAM
;--------------------------
OAM_ADDR := $2003
OAM_DATA := $2004
OAM_DMA := $4014