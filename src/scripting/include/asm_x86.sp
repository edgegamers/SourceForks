//  This file is a part of SourceForks.
//  Common x86 instructions

//  Jump Rel-8
enum JSHORT
{
	//  Overflow
	JSHORT_NO   = 0x70,
	JSHORT_O    = 0x71,

	//  Carry
	JSHORT_C    = 0x72,
	JSHORT_NC   = 0x73,

	//  Zero
	JSHORT_Z    = 0x74,
	JSHORT_NZ   = 0x75,

	//  Below/Equal
	JSHORT_BE   = 0x76,
	JSHORT_NBE  = 0x77,

	//  Sign
	JSHORT_S    = 0x78,
	JSHORT_NS   = 0x79,

	//  Parity
	JSHORT_P    = 0x7A,
	JSHORT_NP   = 0x7B,

	//  Less
	JSHORT_L    = 0x7C,
	JSHORT_NL   = 0x7D,

	//  Less/Equal
	JSHORT_LE   = 0x7E,
	JSHORT_NLE  = 0x7F,

	//  Greater (Alias)
	JSHORT_G    = JSHORT_NLE,
	JSHORT_GE   = JSHORT_NL,
};

enum PREFIX
{
	PREFIX_OPERAND = 0x66,
	PREFIX_ADDRESS = 0x67
};

enum PUSH
{
	PUSH_IMM8   = 0x6A,
	//  Warning: Do not use without a prefix
	PUSH_IMM16  = 0x68,
	PUSH_IMM32  = 0x68
};

//  Jump rel-16/32
//enum JNEAR
//{  
//}