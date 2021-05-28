/*
 * @file rsa_main.cpp
 *
 * @brief User interaction with RSA module through UART
 *
 * @author: Kyle Thomas Le
 * @version v1.0: initial release
 */

// Includes
#include "xil_printf.h"
#include "rsa_wrapper.h"
#include "xparameters.h"
#include "xuartlite.h"
#include "sleep.h"
#include "math.h"

// Definitions
#define RSA_ADDR XPAR_RSA_UPDATE_0_S00_AXI_BASEADDR
#define BUFFER_SIZE 16
#define UART_ID XPAR_AXI_UARTLITE_0_DEVICE_ID

// Class calls
RSACore RSA(RSA_ADDR);
XUartLite UART;

// UART read buffer
u8 RecvBuffer[BUFFER_SIZE];

/*
 * 	Scan UART for integers. Stop when ! is received.
 * 	Convert the integer input into a decimal number.
 *
 * @return uint64_t of the input converted to decimal
 *
 * @note If a non-integer that isn't ! is inputed, it
 * 		is ignored
 */

uint64_t scan_input()
{
	u8 byteConfirmed;
	u8 valueReceived;
	u8 *p = &RecvBuffer[0];
	int counter = 0;
	uint64_t result = 0;

	XUartLite_ResetFifos(&UART);
	while(1)
	{
		byteConfirmed = XUartLite_Recv(&UART, &valueReceived, 1);
		if(byteConfirmed == 1)
		{
			if(valueReceived >= 48 && valueReceived <= 57)
			{
				*p = valueReceived - 48;
				p += 1;
				counter += 1;
			}
			else if(valueReceived == 33)
				break;
		}
	}

	for(int i = 0; i < counter; i++) {
		result += RecvBuffer[i] * pow(10, counter - 1 - i);
	}

	return result;
}


int main()
{
	// Initialize UART
	XUartLite_Initialize(&UART, UART_ID);

	// Variable declaration
	uint32_t decision;
	uint32_t msg;
	uint32_t p;
	uint32_t q;
	uint64_t n;
	uint64_t key;
	uint64_t output[5];
	int encryptdecrypt;
	float time;
	int time_whole, time_decimal;

	// Starting Message
	xil_printf("******MICROBLAZE IMPLEMENTATION FOR RSA******\n");
	xil_printf("\t\t\t\t\t-> ECE 4300 Group E <-\n\r");
	xil_printf("**Please enter the following for the corresponding mode: \n");
	xil_printf("\t\t-> [0!] - Key generation with message generation.\n");
	xil_printf("\t\t-> [1!] - Message generation only.\n\r");
	usleep(2000);				// Sleep for 2ms to allow message to finish printing
	decision = scan_input(); 	// Check for mode input

	if(decision)	// Message Generation only mode
	{
		// Insert input message
		xil_printf("****You have chosen message generation only mode****\n\r");
		xil_printf("\tPlease enter your input message (digits only), followed by a ! when finished: ");
		usleep(2000);
		msg = scan_input();
		xil_printf("\n\t\t-> You inputted %lu \n\r", msg);

		// Insert input modulus
		xil_printf("\tPlease enter your modulus, Q, followed by a ! when finished: ");
		usleep(2000);
		n = scan_input();
		xil_printf("\n\t\t-> You inputted %lu \n\r", n);

		// Insert input key
		xil_printf("\tLastly, please enter your key, followed by a ! when finished: ");
		usleep(2000);
		key = scan_input();
		xil_printf("\n\t\t-> You inputted %lu \n\r", key);

		// Run RSA Algorithm in message generation only mode
		xil_printf("\n\r****   RUNNING RSA ALGORIHTM    ****\n");
		xil_printf("**** MESSAGE GENERATION ONLY MODE ****\n\r");

		RSA.generate_message_key(msg, key, n, output);

		// Print relevant values
		xil_printf(" Finished! The following are your values: \n\r");
		time = (float)output[4] * 0.01;		// Calculate time taken, 0.01 based on 100 MHz clock
		time_whole = time;
		time_decimal = (time - time_whole) * 1000;

		xil_printf(" \t\t->Output message: %lu\n", output[0]);							// Output message
		xil_printf(" \t\t->Operation took: %d.%003d us!\n\r", time_whole, time_decimal);	// Time the module took
	}
	else			// Key generation with message generation mode
	{
		// Insert input message
		xil_printf("****You have chosen key generation with message generation mode****\n\r");
		xil_printf("\tPlease enter your input message (numbers only), followed by a ! when finished: ");
		usleep(2000);
		msg = scan_input();
		xil_printf("\n\t\t-> You inputted %lu \n\r", msg);

		// Insert 1st prime, p
		xil_printf("\tPlease enter your first prime, p, followed by a ! when finished: ");
		usleep(2000);
		p = scan_input();
		xil_printf("\n\t\t-> You inputted %lu \n\r", p);

		// Insert 2nd prime, q
		xil_printf("\tPlease enter your second prime, q, followed by a ! when finished: ");
		usleep(2000);
		q = scan_input();
		xil_printf("\n\t\t-> You inputted %lu \n\r", q);

		// State which mode of operation
		xil_printf("\t[1!] if encrypting or [0!] if decrypting your message: ");
		usleep(2000);
		encryptdecrypt = scan_input();

		if(encryptdecrypt)
			xil_printf("\n\t\t-> You specified to perform Encryption\n\r");
		else
			xil_printf("\n\t\t-> You specified to perform Decryption\n\r");

		// Run RSA Algorithm in key generation with message generation mode
		xil_printf("\n\r****          RUNNING RSA ALGORIHTM			   ****\n");
		xil_printf("**** KEY GENERATION WITH MESSAGE GENERATION MODE ****\n\r");

		RSA.generate_message_primes(p, q, msg, encryptdecrypt, output);

		// Print relevant values
		xil_printf("\tFinished! The following are your values: \n");
		time = (float)output[4] * 0.01;		// Calculate time taken, 0.01 based on 100 MHz clock
		time_whole = time;
		time_decimal = (time - time_whole) * 1000;

		xil_printf(" \t\t-> Output message: %lu \n", output[0]);					// Output message
		xil_printf(" \t\t-> Encryption key (keep private!): %lu \n", output[1]);	// Output encryption key
		xil_printf(" \t\t-> Decryption key: %lu \n", output[2]);					// Output decryption key
		xil_printf(" \t\t-> Modulus: %lu \n\r", output[3]);							// Output modulus
		xil_printf(" \t\t-> Operation took: %d.%003d us!\n\r", time_whole, time_decimal); // Time the module took
	}

	xil_printf("\n\rThank you for using. Press CPU_RESET button on the board to use again.\n\r\n\r");
}

