/*
 * @file rsa_wrapper.h
 *
 * @brief Access RSA Core over AXI
 *
 * @author: Kyle Thomas Le
 * @version: v1.0: initial release
 */

#ifndef _RSA_WRAPPER_H_INCLUDED
#define _RSA_WRAPPER_H_INCLUDED

#include "xil_io.h"
#include "xil_types.h"
#include "sleep.h"

/**********************************************************************
 * RSA custom-ip core driver
 **********************************************************************/
/**
 * RSA core driver from custom-ip
 *  - Write and send data to RSA IP.
 *
 * HDL parameter:
 *  - RSA_WIDTH (unused): # bits of input
 */

class RSACore {
public:
	/**
	 *  Register map for writing
	 *
	 */

	enum {
		P_REG = 0,			// P prime ( for key generation mode )
		Q_REG = 8,			// Q prime ( for key generation mode )
		MSG_IN_REG = 16,	// Msg input ( for both modes)
		KEY_IN_REG = 24,	// Key input ( for encryption/decryption only mode )
		N_IN_REG = 32,		// N input ( for encryption/decryption only mode )
		CONTROL_REG = 40,	// Control signals, go and resets
		MODE_REG = 48		// Mode signals, key generation mode or encryption/decryption only mode
	};

	/*
	 * Field shift for writing
	 *
	 */

	enum {
		RSA_WIDTH = 32,				// HDL Parameter for the RSA input width
		RESET_INVERT_SHIFT = 0,		// Bit 0 of CONTROL_REG
		RESET_MOD_SHIFT = 1,		// Bit 1 of CONTORL_REG
		GO_SHIFT = 2,				// Bit 2 of CONTROL_REG
		MODE_SHIFT = 0, 			// Bit 0 of MODE_REG
		ENCRYPT_DECRYPT_SHIFT = 1 	// Bit 1 of MODE_REG
	};


	/*
	 * Register map for reading
	 *
	 */

	enum {
		MSG_OUT_REG = 0,	// Msg output ( for both modes )
		ENCRYPT_REG = 8,	// Encryption key output ( invalid output when using encryption/decryption only mode and decrypting )
		DECRYPT_REG = 16,	// Decryption key output ( invalid output when using encryption/decryption only mode and encrypting )
		N_OUT_REG = 24,		// N output ( for both modes )
		COUNT_REG = 32,		// Count output ( for both modes )
		STATUS_REG = 40		// Status signal, when the module is finished
	};

	/*
	 * Field masks for reading
	 *
	 */

	enum {
		COUNT_FIELD = 0xFF,		// First 32 bits of COUNT_REG
		FINISH_FIELD = 0x01		// Bit 0 of STATUS_REG
	};

	/* Methods */

	/**
	 *  Constructor
	 *  	Set base address to private variable
	 */

	RSACore(uint64_t core_base_addr);
	~RSACore();	// Unused

	/*
	 *  Generate values using the primes p and q, either encrypting or decrypting the message
	 *
	 * @param p uint32_t 1st prime
	 * @param q uint32_t 2nd prime
	 * @param msg uint32_t message to be encrypted/decrypted
	 * @param encrypt_decrypt int specifies if encrypting or decrypting. 1 for encryption, 0 for decryption
	 * @param array uint64_t[] passthrough array which all the results are stored into
	 *
	 */
	void generate_message_primes(uint32_t p, uint32_t q, uint32_t msg, int encrypt_decrypt, uint64_t array[5]);

	/*
	 *  Generate values using the key and modulus, creating the message based on the key
	 *
	 * @param msg uint32_t message to be encrypted/decrypted
	 * @param key uint64_t input key, either encryption or decryption key
	 * @param n uint64_t modulus, used with key to generate specific message
	 * @param array uint64_t[] passthrough array which all the results are stored into
	 *
	 */
	void generate_message_key(uint32_t msg, uint64_t key, uint64_t n, uint64_t array[5]);

	/*
	 * 	Write p and q into their registers
	 *
	 * @param p uint32_t 1st prime
	 * @param q uint32_t 2nd prime
	 *
	 */
	void write_pq(uint32_t p, uint32_t q);

	/*
	 * 	Write msg into its register
	 *
	 * @param msg uint32_t message to be encrypted/decrypted
	 *
	 */
	void write_msg(uint32_t msg);

	/*
	 * 	Write key into its register
	 *
	 * @param key uint64_t key used for encryption/decryption
	 *
	 */
	void write_key(uint64_t key);

	/*
	 * 	Write n into its register
	 *
	 * @param n uint64_t modulus used alongside key for encryption/decryption
	 *
	 */
	void write_n(uint64_t n);

	/*
	 * 	Write to the module to either start or stop it
	 *
	 * @param value int 1 to start the module, 0 to stop
	 *
	 * @note If go is deasserted, module will still finish its
	 * 		current calculation
	 */
	void go(int value);

	/*
	 * 	Write to module to reset and start it again
	 *
	 * @param value int 1 to hold in reset, 0 to release reset
	 *
	 * @note Reset will abruptly interrupt the module and reset it
	 *      to its initial state.
	 * @note Requires go to be high for it to work after reset
	 *
	 */
	void reset(int value);

	/*
	 * 	Write to module to set up mode of operation
	 *
	 * @param mode int 1 is key generation and message generation mode
	 * 				   0 is message generation mode only
	 * @param encryptdecrypt int 1 is encryption, 0 is decryption
	 *
	 */
	void set_mode(int mode, int encryptdecrypt);

	/*
	 * 	Read data from module: output message, decryption key,
	 * 				encryption key, modulus, and clock cycles
	 * 				and write it to input array
	 *
	 * 	@param array uint64_t which all the data is written to
	 *
	 *  @note Data is not written until module is finished. If code hangs,
	 *        it is because of this method
	 *  @note depending on encryption/decryption mode, the decryption or
	 *        encryption key will be junk (0)
	 */
	void read_data(uint64_t array[5]);

	/*
	 * 	Read output message from module
	 *
	 * @return uint64_t of output message
	 *
	 */
	uint64_t read_msg();

	/*
	 * 	Read output encryption key from module
	 *
	 * @return uint64_t of output encryption key
	 */
	uint64_t read_encryption_key();

	/*
	 * 	Read output decryption key from module
	 *
	 * @return uint64_t of output decryption key
	 */
	uint64_t read_decryption_key();

	/*
	 * 	Read output modulus from module
	 *
	 * @return uint64_t of output modulus
	 */
	uint64_t read_n();

	/*
	 * 	Read output counter from module
	 *
	 * @return uint64_t of output counter
	 */
	uint32_t read_counter();

	/*
	 * 	Check if module is busy and not ready
	 *
	 * @return bool true if busy, false if ready
	 */
	bool isBusy();

private:
	uint64_t base_addr;		// Base address for writing to AXI
};

#endif



