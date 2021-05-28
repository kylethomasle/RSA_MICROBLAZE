/*
 * Empty C++ Application
 */

#ifdef testmethod

#include "stdio.h"
#include <inttypes.h>
#include "xil_printf.h"
#include "RSA_Update.h"
#include "xparameters.h"
#include "xil_io.h"
#include "sleep.h"

#define RSA_ADDR XPAR_RSA_UPDATE_0_S00_AXI_BASEADDR

int main()
{
	int gos = 1;
	int reset = 0;
	int encryptdecrypt = 1;
	int modes = 0;
	xil_printf("Initial...");
	uint32_t p = 13;
	uint32_t q = 11;
	uint32_t msg = 9;

	uint64_t i_key = 7;
	uint64_t n = 143;
	uint64_t go = (go | (gos << 2) | (reset << 1) | reset);
	uint64_t mode = (mode | encryptdecrypt << 1 | modes);

	Xil_Out64((RSA_ADDR) + (RSA_UPDATE_S00_AXI_SLV_REG0_OFFSET), (u64)(p));
	Xil_Out64((RSA_ADDR) + (RSA_UPDATE_S00_AXI_SLV_REG1_OFFSET), (u64)(q));
	Xil_Out64((RSA_ADDR) + (RSA_UPDATE_S00_AXI_SLV_REG2_OFFSET), (u64)(msg));
	Xil_Out64((RSA_ADDR) + (RSA_UPDATE_S00_AXI_SLV_REG3_OFFSET), (u64)(i_key));
	Xil_Out64((RSA_ADDR) + (RSA_UPDATE_S00_AXI_SLV_REG4_OFFSET), (u64)(n));


	Xil_Out64((RSA_ADDR) + (RSA_UPDATE_S00_AXI_SLV_REG6_OFFSET), (u64)(mode));
	xil_printf("starting...\n\r");
	Xil_Out64((RSA_ADDR) + (RSA_UPDATE_S00_AXI_SLV_REG5_OFFSET), (u64)(go));

	uint64_t var;
	while( 1 ) {
		var = Xil_In64((RSA_ADDR) + (RSA_UPDATE_S00_AXI_SLV_REG5_OFFSET)) & 1;
		if( var ) break;
		usleep(100);
	};

	uint64_t msg_out = Xil_In64((RSA_ADDR) + (RSA_UPDATE_S00_AXI_SLV_REG0_OFFSET));
	uint64_t encrypt_out = Xil_In64((RSA_ADDR) + (RSA_UPDATE_S00_AXI_SLV_REG1_OFFSET));
	uint64_t decrypt_out = Xil_In64((RSA_ADDR) + (RSA_UPDATE_S00_AXI_SLV_REG2_OFFSET));
	uint64_t n_out = Xil_In64((RSA_ADDR) + (RSA_UPDATE_S00_AXI_SLV_REG3_OFFSET));
	uint64_t count = Xil_In64((RSA_ADDR) + (RSA_UPDATE_S00_AXI_SLV_REG4_OFFSET));

	xil_printf("MSGOUT: %d \n\r", msg_out);
	xil_printf("ENCRYPT: %d \n\r", encrypt_out);
	xil_printf("DECRYPT: %d \n\r", decrypt_out);
	xil_printf("N: %d \n\r", n_out);
	xil_printf("Count: %d \n\r", count);

}

#endif
