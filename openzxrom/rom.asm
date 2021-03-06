; rom.asm: A freely-licenced replacement firmware for the ZX Spectrum
; From the Open82 project
; Copyright (c) 2009 Matthew Westcott
;
; $Id$
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License version 2 as
; published by the Free Software Foundation.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
;
; Author contact information:
;
; E-mail: matthew@west.co.tt
; Postal address: 14 Daisy Hill Drive, Adlington, Chorley,
;                 Lancs, PR6 9NE, United Kingdom

; macro to mark addresses up to (and not including) addr as unused memory
fillto	macro addr
	if addr < $
	.warning "Memory overflow! Inspect the binary for the string MEMORY OVERFLOW to find out where."
		;sorry, I don't know how else to get Pasmo to identify the address it failed at...
	db "MEMORY OVERFLOW"
	else
	ds addr - $, 0xF7	; 0xF7 = RST 0x0030
	endif
	endm

; 0x0000: restart and interrupt routines
	include "restarts.asm"
; Startup procedure
	include "startup.asm"
; 0x0205: Keyboard scanning
	include "keyboard.asm"
; 0x03b5: Beeper
	include "speaker.asm"
; Character printing
	include "printing.asm"
; 0x0556: Cassette handling routines
	include "cassette.asm"
; Main interpreter loop
	include "interpreter.asm"
; 0x0d6b: Clear screen
	include "clear_screen.asm"
; Error handling
	include "errors.asm"
; Memory management
	include "memory.asm"
; Expression parsing / evaluation
	include "expressions.asm"
; Function evaluation
	include "functions.asm"
; Command execution
	include "commands.asm"

	fillto 0x1601
; 'open stream' routine; as the only stream we handle at present is the upper screen,
; this is a no-op
	ret

; 0x2030: Print string
	include "print_string.asm"
; 0x2298: High-resolution graphics routines
	include "graphics.asm"
; 0x2ab6 (approx): Floating-point calculator routines
	include "calculator.asm"
; Error diagnostics
	include "diagnostics.asm"
; ---------------
splash_text
	include "splash_screen.asm"
splash_text_end

; ---------------			
	fillto 0x386e
		; Free space in the original ROM, filled with 0xff.
		; Frequently used as an interrupt table, so we shall aim to retain as much of
		; this as possible. (At minimum we should retain the 0xff bytes at 0x**ff and
		; 0x**00 - well-behaved hardware *should* always use these addresses for the
		; jump address)
	ds 0x3d00 - $, 0xff
; ---------------			
	fillto 0x3d00
font
	if defined FONT_CLAIRSYS
	incbin "fonts/clairsys.bin"
	else
	include "fonts/zx81_ace.asm"
	endif

screen	equ 0x4000
attributes	equ 0x5800
attributes_end	equ 0x5b00

; System variables specific to Open82:
cursor_addr	equ 0x5b00	; Screen address at which next character will be displayed
next_char_type	equ 0x5b02	; how to interpret next character received by RST 0x0010:
		; 00 = ordinary character
		; 10, 11, 12, 13 = ink, paper, flash, bright value
		; 16 = y coordinate (PRINT AT)
		; 17 = x coordinate (PRINT TAB)

; System variables common with original ROM:
last_key	equ 0x5c08	; ASCII / control code of last key pressed
font_ptr	equ 0x5c36	; pointer to font bitmap (minus 0x0100 bytes)

sysvars_base	equ 0x5c3a	; IY points here to allow indirect access to system variables

flags	equ 0x5c3b	; misc flags - bit 5 set means new key available in last_key
curr_line_num	equ 0x5c45	; current line number
border_colour	equ 0x5c48	; border colour (actually an attribute code: paper = border colour, ink = contrasting)
vars_addr	equ 0x5c4b	; pointer to start of variables table
next_line_ptr	equ 0x5c55	; pointer to first (header) byte of next program line
interp_ptr	equ 0x5c5d	; pointer to bit of program currently being executed
workspace	equ 0x5c61	; pointer to start of temporary workspace / string storage area
calc_stack	equ 0x5c63	; pointer to start of calculator stack
stkend	equ 0x5c65	; pointer to first unused byte after the calculator stack
		; (and start of spare memory)
stkend_hi	equ 0x5c66	; high byte of stkend
breg	equ 0x5c67	; temporary storage for B register, used in calculator routines
mem	equ 0x5c68	; pointer to base of calculator's memory area
flags2	equ 0x5c6a	; misc flags - notably, bit 3 set means that caps lock is enabled
rand_seed	equ 0x5c76	; seed for random number generator
frames	equ 0x5c78	; 3-byte frame counter (lowest byte first)
udg_ptr	equ 0x5c7b	; pointer to UDG bitmaps
perm_attribute	equ 0x5c8d	; attribute value for global use (e.g. in CLS)
perm_mask	equ 0x5c8e	; copied to temp_mask at the start of a PRINT
temp_attribute	equ 0x5c8f	; attribute value for temporary use in putchar
temp_mask	equ 0x5c90	; set bits will be preserved when applying temp_attribute to screen
membot	equ 0x5c92	; calculator's memory area; space for 6 x 5-byte values
ramtop	equ 0x5cb2	; where to reset stack pointer to on NEW
prog_mem	equ 0x5ccb	; traditional start of BASIC program memory
udg_mem	equ 0xff58	; traditional start of user-defined graphic bitmaps

; offsets used to access system variables from IY:

iy_flags	equ flags - sysvars_base
