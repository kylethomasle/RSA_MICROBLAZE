/*
 * @file rsa_wrapper.cpp
 *
 * @brief implemetnation of RSACore class
 *
 * @author: Kyle Thomas Le
 * @version v1.0: initial release
 */

#include "rsa_wrapper.h"

RSACore::RSACore(uint64_t core_base_addr) {
	base_addr = core_base_addr;
}

RSACore::~RSACore(){
}


void RSACore::write_pq(uint32_t p, uint32_t q) {
	Xil_Out64( base_addr + P_REG, p );
	Xil_Out64( base_addr + Q_REG, q );
}

void RSACore::write_msg(uint32_t msg) {
	Xil_Out64( base_addr + MSG_IN_REG, msg);
}

void RSACore::write_key(uint64_t key) {
	Xil_Out64( base_addr + KEY_IN_REG, key);
}

void RSACore::write_n(uint64_t n) {
	Xil_Out64( base_addr + N_IN_REG, n);
}

void RSACore::go(int value) {
	uint64_t control_reg = value << GO_SHIFT;

	Xil_Out64( base_addr + CONTROL_REG, control_reg );
}

void RSACore::reset(int value) {
	uint64_t control_reg = ((value << RESET_INVERT_SHIFT) | (value << RESET_MOD_SHIFT));

	Xil_Out64( base_addr + CONTROL_REG, control_reg );
}

void RSACore::set_mode(int mode, int encryptdecrypt) {
	uint64_t mode_reg = ((encryptdecrypt << ENCRYPT_DECRYPT_SHIFT) | (mode << MODE_SHIFT));

	Xil_Out64( base_addr + MODE_REG, mode_reg );
}

uint64_t RSACore::read_msg() {
	return Xil_In64( base_addr + MSG_OUT_REG );
}

uint64_t RSACore::read_encryption_key() {
	return Xil_In64( base_addr + ENCRYPT_REG );
}

uint64_t RSACore::read_decryption_key() {
	return Xil_In64( base_addr + DECRYPT_REG );
}

uint64_t RSACore::read_n() {
	return Xil_In64( base_addr + N_OUT_REG );
}

uint32_t RSACore::read_counter() {
	return Xil_In64( base_addr + COUNT_REG );
}


void RSACore::read_data(uint64_t array[]) {
	int var;
	while(1) {														// Calling isBusy() never reads a proper value, manually reading fixes
		var = Xil_In64( base_addr + STATUS_REG ) & FINISH_FIELD;
		if( var ) break;
		usleep(100);
	}

	array[0] = this->read_msg();
	array[1] = this->read_encryption_key();
	array[2] = this->read_decryption_key();
	array[3] = this->read_n();
	array[4] = this->read_counter();
}

bool RSACore::isBusy() {
	int status = Xil_In64( base_addr + STATUS_REG ) & FINISH_FIELD;

	if( status )
		return false;
	else
		return true;
}

/* Procedure:
 * 	1. Hold module in reset (not required)
 *  2. Write p and q values
 *  3. Write msg value
 *  4. Set to key generation mode, write encryption/decryption mode
 *  5. Release reset (not required if 1. is not done)
 *  6. Start module
 *  7. Read values once calculations are done and write to array
 *  8. Stop module
 */

void RSACore::generate_message_primes(uint32_t p, uint32_t q,
			uint32_t msg, int encrypt_decrypt, uint64_t array[]) {
	reset(1);
	write_pq(p, q);
	write_msg(msg);
	set_mode(1, encrypt_decrypt);
	reset(0);
	go(1);

	read_data(array);
	go(0);
}

/* Procedure:
 * 	1. Hold module in reset (not required)
 *  2. Write msg value
 *  3. Write modulus value
 *  4. Write key value
 *  4. Set to msg generation only mode, encryption/decryption value does not matter
 *  5. Release reset (not required if 1. is not done)
 *  6. Start module
 *  7. Read values once calculations are done and write to array
 *  8. Stop module
 */

void RSACore::generate_message_key(uint32_t msg, uint64_t key, uint64_t n, uint64_t array[]) {
	reset(1);
	write_msg(msg);
	write_n(n);
	write_key(key);
	set_mode(0, 0);
	reset(0);
	go(1);

	read_data(array);
	go(0);
}

