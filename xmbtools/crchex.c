/*
** Copyright (C) 2017 Sandor Zsuga (Jubatian)
**
** This Source Code Form is subject to the terms of the Mozilla Public
** License, v. 2.0. If a copy of the MPL was not distributed with this
** file, You can obtain one at http://mozilla.org/MPL/2.0/.
**
** Processes an Intel HEX file to append a complemented CRC32 to it (so
** calculating the complete data's CRC32 including the CRC value would result
** 0xFFFFFFFF).
**
** Must be compiled with a C compiler having an int size of at least 32 bits.
**
** Call with two parameters: The first parameter is the HEX file to process,
** the second is the total ROM size to cover with CRC (including the appended
** four CRC bytes). The ROM is padded by 0xFF as needed. Output is generated
** to standard out.
**
** The second parameter may have a 'b' or 'k' postfix (upper or lower case) to
** indicate Byte or KByte units (1 KByte = 1024 Bytes).
*/



#include <stdlib.h>
#include <stdio.h>
#include <string.h>



/* Current AVR chips have 384K ROM at most */
#define BIN_MAX_SIZE 384U * 1024U



typedef unsigned int  auint; /* Architecture unsigned integer */
typedef signed int    boole; /* Boolean */
typedef unsigned char uint8; /* Unsigned 8 bit byte used for reading files */

#define FALSE (0)
#define TRUE  (!FALSE)



typedef struct{
 auint  type;          /* Hex file row data type:
                       ** 0: Data
                       ** 1: EOF
                       ** 2: Extended seg. addr.
                       ** 3: Start seg. addr. (Program entry point)
                       ** 4: Extended lin. addr.
                       ** 5: Start lin. addr. (Program entry point) */
 auint  len;           /* Type 0: Length of data field */
 auint  addr;          /* Associated address. For data fields this is the
                       ** address field, for types 2-5, the address encoded
                       ** according  to the type. */
 uint8  d[256];        /* Data field contents */
}hex_line_t;

#define HEX_RT_DATA  0U
#define HEX_RT_EOF   1U
#define HEX_RT_ESEGA 2U
#define HEX_RT_SSEGA 3U
#define HEX_RT_ELINA 4U
#define HEX_RT_SLINA 5U



#define HEX_CHAR_INV ((auint)(-1))

/*
** Converts hex character to integer, HEX_CHAR_INV if character is invalid.
** (Note: valid values are below 16 which is a more robust test condition)
*/
auint hex_char_to_int(uint8 c)
{
 if ((c >= (uint8)('0')) && (c <= (uint8)('9'))){ return c - (uint8)('0'); }
 if ((c >= (uint8)('a')) && (c <= (uint8)('f'))){ return c - (uint8)('a') + 10U; }
 if ((c >= (uint8)('A')) && (c <= (uint8)('F'))){ return c - (uint8)('A') + 10U; }
 return HEX_CHAR_INV;
}



#define HEX_BYTE_INV ((auint)(-1))

/*
** Reads a byte from a HEX file, HEX_BYTE_INV if the byte is invalid.
** (Note: valid values are below 256 which is a more robust test condition)
*/
auint hex_byte_read(FILE* fp)
{
 uint8 b8;
 auint hval;
 auint res;

 if (fread(&b8, 1, 1, fp) != 1){ return HEX_BYTE_INV; }
 hval = hex_char_to_int(b8);
 if (hval >= 16U){ return HEX_BYTE_INV; }
 res  = hval << 4;

 if (fread(&b8, 1, 1, fp) != 1){ return HEX_BYTE_INV; }
 hval = hex_char_to_int(b8);
 if (hval >= 16U){ return HEX_BYTE_INV; }
 res |= hval;

 return res;
}



/*
** Reads a line from a HEX file.
** Returns TRUE on success along with filling the passed hex_line_t structure.
** Empty lines in the file are skipped. Returns FALSE only if the line is
** invalid or the end of the file is reached.
*/
boole hex_read(FILE* fp, hex_line_t* hline)
{
 uint8 b8;
 auint hval;
 auint i;
 auint chks = 0U;

 do{
  if (fread(&b8, 1, 1, fp) != 1){ return FALSE; }
  if (b8 > 0x20U) break; /* Find first non-blank character */
 }while(TRUE);

 if (b8 != (uint8)(':')){ return FALSE; } /* Not a valid start of HEX file row */

 /* Read length of HEX row */

 hval = hex_byte_read(fp);
 if (hval >= 256U){ return FALSE; }
 chks += hval;
 (hline->len)  = hval;

 /* Read address */

 hval = hex_byte_read(fp);
 if (hval >= 256U){ return FALSE; }
 chks += hval;
 (hline->addr) = hval << 8;

 hval = hex_byte_read(fp);
 if (hval >= 256U){ return FALSE; }
 chks += hval;
 (hline->addr) |= hval;

 /* Read row type */

 hval = hex_byte_read(fp);
 if (hval >= 256U){ return FALSE; }
 chks += hval;
 (hline->type) = hval;

 /* Check length according to record type */

 hval = (hline->len);
 switch (hline->type){
  case HEX_RT_DATA:  break;
  case HEX_RT_EOF:   if (hval != 0U){ return FALSE; } break;
  case HEX_RT_ESEGA: if (hval != 2U){ return FALSE; } break;
  case HEX_RT_SSEGA: if (hval != 4U){ return FALSE; } break;
  case HEX_RT_ELINA: if (hval != 2U){ return FALSE; } break;
  case HEX_RT_SLINA: if (hval != 4U){ return FALSE; } break;
  default:           break;
 }

 /* Read data */

 switch (hline->type){

  case HEX_RT_ESEGA:
  case HEX_RT_SSEGA:
  case HEX_RT_ELINA:
  case HEX_RT_SLINA: /* Data is address */

   if ((hline->addr) != 0U){ return FALSE; } /* Address field must be zero for these */

   (hline->addr) = 0U;
   for (i = 0U; i < (hline->len); i++){
    hval = hex_byte_read(fp);
    if (hval >= 256U){ return FALSE; }
    chks += hval;
    (hline->addr) = ((hline->addr) << 8) | hval;
   }
   break;

  case HEX_RT_DATA:  /* Data bytes (0 - 255) */

   for (i = 0U; i < (hline->len); i++){
    hval = hex_byte_read(fp);
    if (hval >= 256U){ return FALSE; }
    chks += hval;
    (hline->d[i]) = hval;
   }
   break;

  case HEX_RT_EOF:   /* EOF must have no data */

   if ((hline->addr) != 0U){ return FALSE; } /* Address field must be zero */
   if ((hline->len)  != 0U){ return FALSE; } /* No data */
   break;

  default:           /* Unknown field type */

   return FALSE;
   break;

 }

 /* Checksum */

 hval = hex_byte_read(fp);
 if (hval >= 256U){ return FALSE; }
 chks += hval;

 if ((chks & 0xFFU) != 0U){ return FALSE; } /* Checksum error */

 return TRUE;        /* Hex file line succesfully processed */
}



/*
** Pre-calculate CRC32 accelerator table. The table must be 256 elements long.
*/
void crc_gen_table(auint* crc_table)
{
 auint rem;
 auint dbt;
 auint bit;

 for (dbt = 0U; dbt < 256U; dbt++){
  rem = dbt;
  for (bit = 0U; bit < 8U; bit++){
   rem = rem >> 1;
   if ((rem & 1U) != 0U){ rem ^= 0xEDB88320UL; } /* CRC32 polynomial */
  }
  crc_table[dbt] = rem;
 }
}



/*
** Compute complemented CRC32 for the passed data. The CRC32 is written at the
** end of it.
*/
void crc_calc(uint8* data, auint dlen)
{
 auint crc = 0xFFFFFFFFUL;
 auint crc_table[256];
 auint pos;

 if (dlen < 4U){ return; } /* CRC32 doesn't fit (too short data) */

 crc_gen_table(&crc_table[0]);

 for (pos = 0; pos < (dlen - 4U); pos ++){
  crc = crc_table[data[pos] ^ (crc & 0xFFU)] ^ (crc >> 8);
 }

 crc ^= 0xFFFFFFFFUL;
 data[pos + 0U] = (crc      ) & 0xFFU;
 data[pos + 1U] = (crc >>  8) & 0xFFU;
 data[pos + 2U] = (crc >> 16) & 0xFFU;
 data[pos + 3U] = (crc >> 24) & 0xFFU;
}



/*
** Main function processing a hex file to add CRC32 to it
*/
int main(int argc, char* argv[])
{
 FILE*      fp;
 hex_line_t hline;
 uint8      bin[BIN_MAX_SIZE];
 auint      siz;
 auint      pos;
 auint      cval;
 auint      hoff;
 auint      soff;
 auint      toff;
 boole      comp;
 auint      chks;
 auint      i;

 /* Not enough params: print usage info */

 if (argc < 3){
  printf("XMBurner HEX-CRC32 tool\n"
         "\n"
         "Copyright Sandor Zsuga (Jubatian), 2017\n"
         "Licensed under Mozilla Public License v 2.0\n"
         "\n"
         "crchex hexfile.hex size\n"
         "\n"
         "- hexfile.hex: The input file to process (Intel HEX format)\n"
         "- size: The size in Bytes (default) or KBytes ('K' suffix) of output\n"
         "\n"
         "Applies CRC32 to a program binary provided in Intel HEX format, generating\n"
         "the result on standard output (Intel HEX format). The CRC32 is in negated\n"
         "form so when processing the entire binary should give 0xFFFFFFFF for a\n"
         "correct binary.\n");
  exit(1);
 }

 /* Read output size */

 siz = 0U;
 pos = 0U;
 do{
  cval = argv[2][pos];
  if       ((cval >= (auint)('0')) && (cval <= (auint)('9'))){
   siz = (siz * 10U) + cval - (auint)('0');
  }else if ((cval == (auint)('K')) || (cval == (auint)('k'))){
   siz = siz * 1024U;
   break;
  }else{
   break;
  }
  pos ++;
 }while(TRUE);
 if (siz > BIN_MAX_SIZE){
  printf("Output size too large (max: %u KBytes)\n", BIN_MAX_SIZE / 1024U);
  exit(1);
 }

 /* Open input file */

 fp = fopen(argv[1], "rb");
 if (fp == NULL){
  fprintf(stderr, "The input file (%s) couldn't be opened!\n", argv[1]);
  exit(1);
 }

 /* Read hex file, filling up the binary */

 memset(&bin[0], 0xFFU, BIN_MAX_SIZE);

 hoff = 0U; /* Current address high (<< 16) */
 soff = 0U; /* Start offset (to save it if there is any such record) */
 comp = FALSE; /* Not completed yet */

 do{

  if (!hex_read(fp, &hline)){

   if (feof(fp) != 0){
    fprintf(stderr, "Warning: End of input without proper termination\n");
    comp = TRUE;
   }else{
    fprintf(stderr, "Error: Encountered invalid content in input file\n");
    exit(1);
   }

  }else{

   switch (hline.type){

    case HEX_RT_ESEGA:
    case HEX_RT_SSEGA:

     fprintf(stderr, "Error: Segmented 16 bit HEX files are not supported\n");
     exit(1);
     break;

    case HEX_RT_ELINA:

     hoff = (hline.addr << 16);
     break;

    case HEX_RT_SLINA:

     soff = (hline.addr);
     break;

    case HEX_RT_EOF:

     comp = TRUE;
     break;

    case HEX_RT_DATA:

     toff = (hoff + hline.addr) & 0xFFFFFFFFUL;
     if       (toff >= BIN_MAX_SIZE){
      fprintf(stderr, "Error: Address (0x%08X) out of range!\n", toff);
      exit(1);
     }else if ((toff + hline.len) >= BIN_MAX_SIZE){
      fprintf(stderr, "Error: Data reaches beyond valid address range (0x%08X + %u)!\n", toff, hline.len);
      exit(1);
     }else{
      memcpy(&bin[toff], &hline.d[0U], hline.len);
     }
     break;

    default:
     fprintf(stderr, "Error: Invalid type (%u) in HEX file!\n", hline.type);
     exit(1);

   }

  }

 }while(!comp);

 /* Calculate CRC */

 crc_calc(bin, siz);

 /* Create output HEX file */

 pos = 0U;
 do{

  /* Generate a linear address high row */

  if ((pos & 0xFFFFU) == 0U){
   chks = 0U - (0x02U + 0x04U +
       ((pos >> 24) & 0xFFU) +
       ((pos >> 16) & 0xFFU));
   printf(":02000004%02X%02X%02X\n",
       ((pos >> 24) & 0xFFU),
       ((pos >> 16) & 0xFFU),
       (chks & 0xFFU));
  }

  /* Generate data rows (placing 16 bytes in each as usual) */

  chks = 0U - (0x10U + ((pos >> 8) & 0xFFU) + (pos & 0xFFU));
  printf(":10%02X%02X00", ((pos >> 8) & 0xFFU), (pos & 0xFFU));
  for (i = 0U; i < 16U; i++){
   chks -= bin[pos + i];
   printf("%02X", bin[pos + i]);
  }
  printf("%02X\n", chks & 0xFFU);
  pos += 16U;

 }while (pos < siz);

 /* Add start location */

 chks = 0U - (0x04U + 0x05U +
     ((soff >> 24) & 0xFFU) +
     ((soff >> 16) & 0xFFU) +
     ((soff >>  8) & 0xFFU) +
     ((soff      ) & 0xFFU));
 printf(":04000005%02X%02X%02X%02X%02X\n",
     ((soff >> 24) & 0xFFU),
     ((soff >> 16) & 0xFFU),
     ((soff >>  8) & 0xFFU),
     ((soff      ) & 0xFFU),
     (chks & 0xFFU));

 /* Add termination */

 printf(":00000001FF\n");

 fclose(fp);

 exit(0);
 return 0;
}
