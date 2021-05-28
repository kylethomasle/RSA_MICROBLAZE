# ECE4300 FALL GROUP E
## Important Sources

### File Information
This folder holds all of the core HDL sources that allow the system to function. This is done to make it easier to read instead of digging through the project folder.
* RSA_Top.sv : Top module.
  * inverter_custom.sv : Module that handles key generation
  * mod_exponent.sv : Module that handles message encryption or decryption
* mod_custom.sv : Module that calculates the quotient and remainder of its inputs. Used in both submodules.
* RSA_v1_0_S00_AXI.v : AXI address interaction. This is how the communication addressing between SDK and the module is defined. 
* rsa_main.cc : C++ file with the code to write to the RSA module from higher-level programming. 
  * rsa_wrapper.h : Header file for interfacing with the RSA IP through AXI.
  * rsa_wrapper.cpp : Source file implementation of header.

BAUD Rate for accessing the UART terminal: 115200. 
### Address Map
The following is the address map used when reading or writing to the custom IP in order to write or read relevant data.

![AXI Address Map](https://github.com/california-polytechnic-university/ECE4300_FALL_GROUP_E/blob/master/MicroBlaze/Important%20Sources/RSA_AddressMap.jpg)

### Navigating the project folder
* Project was developed in Vivado 2019.1 and Xilinx SDK 2019.1.
* To open the project, open the .xpr file.
* The SDK project sources are located under Final_RSA.sdk/RSA_Reg_test/
* The HDL sources are located under Final_RSA.srcs/

**NOTE: It is important that these files are updated at the same time the files in the main project are updated** 
