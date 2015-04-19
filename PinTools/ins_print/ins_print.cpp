#include "pin.H"
extern "C" {
#include "xed-interface.h"
}
#include <iostream>
#include <fstream>

std::ofstream *output;
KNOB<BOOL> KnobNoLibraryTrace(KNOB_MODE_WRITEONCE, "pintool", "no-lib", "0", "Disable tracing non-module code such as library");

static
VOID Fini(INT32 code, VOID *v)
{
	output->close();
}

static
VOID InsPrint(ADDRINT ip, std::string *ins_disas)
{
	*output << std::hex << ip << ": " << *ins_disas << endl;
}

static
VOID InsPrintBranchOrCall(ADDRINT ip, ADDRINT target, BOOL is_taken, std::string *ins_disas)
{
	std::string sym = RTN_FindNameByAddress(target);
	std::string br_str = "[br=";

	if(is_taken)
		br_str += "1]";
	else
		br_str += "0]";

	if(sym.length() > 0)
		*output << std::hex << ip << ": " << *ins_disas << "; " << sym << " " << br_str << endl;
	else
		*output << std::hex << ip << ": " << *ins_disas << " " << br_str << endl;
}

static
VOID InsPrintMemoryRead(ADDRINT ip, ADDRINT src, ADDRINT src_size, std::string *ins_disas)
{
	std::string read_str = "Read -> [";

	for(UINT32 i = 0; i < src_size; i++)
		read_str += StringHex(*((UINT8*) (src + i)), 1, false);
	read_str += "]";

	*output << std::hex << ip << ": " << *ins_disas << "; " << read_str << endl;
}

static
VOID Ins(INS ins, VOID *p)
{
/*
	IMG img = IMG_Invalid();

	if(KnobNoLibraryTrace) {
		// IMG_FindByAddress(..) returns stale IMG object
		img = IMG_FindByAddress(INS_Address(ins));
		if(!IMG_IsMainExecutable(img))
			return;
	}
*/
	if(INS_IsBranchOrCall(ins)) {
		INS_InsertCall(ins, IPOINT_BEFORE, (AFUNPTR) InsPrintBranchOrCall,
			IARG_INST_PTR, IARG_BRANCH_TARGET_ADDR, IARG_BRANCH_TAKEN,
			IARG_PTR, new std::string(INS_Disassemble(ins)), IARG_END);
	}
	else if((INS_Opcode(ins) == XED_ICLASS_MOV) && INS_IsMemoryRead(ins)) {
		INS_InsertCall(ins, IPOINT_BEFORE, (AFUNPTR) InsPrintMemoryRead,
			IARG_INST_PTR, IARG_MEMORYREAD_EA, IARG_MEMORYREAD_SIZE,
			IARG_PTR, new std::string(INS_Disassemble(ins)), IARG_END);
	}
	else {
		INS_InsertCall(ins, IPOINT_BEFORE, (AFUNPTR) InsPrint,
			IARG_INST_PTR,
			IARG_PTR, new std::string(INS_Disassemble(ins)), IARG_END);
	}
}

int main(int argc, char **argv)
{
	PIN_InitSymbols();
	PIN_Init(argc, argv);
	output = new std::ofstream("ins_output.txt", std::ofstream::trunc);

	INS_AddInstrumentFunction(Ins, NULL);
	PIN_AddFiniFunction(Fini, NULL);

	PIN_StartProgram();
	return 0;
}
