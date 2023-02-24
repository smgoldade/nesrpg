// Author: Steven Goldade
#ifndef _NES_ATTRIBUTE_TABLE_H_
#define _NES_ATTRIBUTE_TABLE_H_
#include "../core.h"
/**
 * Inserts data into the PPU update buffer to update the given attribute with the provided data.
 * This update happens during the vertical blanking NMI generated by the PPU.
 *
 * @param data the data to copy to the attribute table
 * @param size the size of the data to copy
 * @param attribute_table the attribute table to copy to (0-3)
 * @param x the x value on the attribute table for the start of the data
 * @param y the y value on the attribute table for the start of the data
 */
extern void __fastcall__ ppu_nmi_at_update(const u8* data, u8 size, u8 attribute_table, u8 x, u8 y);

extern const u8* ATTRIBUTE_TABLE_0;
extern const u8* ATTRIBUTE_TABLE_1;
extern const u8* ATTRIBUTE_TABLE_2;
extern const u8* ATTRIBUTE_TABLE_3;

#define AT_WIDTH 8
#define AT_HEIGHT 8
#define AT0_ADDR(x,y) ((u16)(&ATTRIBUTE_TABLE_0) | (y << 3) | x)
#define AT1_ADDR(x,y) ((u16)(&ATTRIBUTE_TABLE_1) | (y << 3) | x)
#define AT2_ADDR(x,y) ((u16)(&ATTRIBUTE_TABLE_2) | (y << 3) | x)
#define AT3_ADDR(x,y) ((u16)(&ATTRIBUTE_TABLE_3) | (y << 3) | x)

#define ATTRIBUTE_TOP_LEFT_READ(x) (x & 0x3)
#define ATTRIBUTE_TOP_RIGHT_READ(x) ((x & 0xC) >> 2)
#define ATTRIBUTE_BOTTOM_LEFT_READ(x) ((x & 0x30) >> 4)
#define ATTRIBUTE_BOTTOM_RIGHT_READ(x) ((x & 0xC0) >> 6)

#define ATTRIBUTE_TOP_LEFT_WRITE(x,y) BIT_WRITE_0_2(x,y)
#define ATTRIBUTE_TOP_RIGHT_WRITE(x,y) BIT_WRITE_2_2(x,y)
#define ATTRIBUTE_BOTTOM_LEFT_WRITE(x,y) BIT_WRITE_4_2(x,y)
#define ATTRIBUTE_BOTTOM_RIGHT_WRITE(x,y) BIT_WRITE_6_2(x,y)

#endif //_NES_ATTRIBUTE_TABLE_H_