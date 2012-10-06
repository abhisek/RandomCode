module RbWinDBG

	class DbgHelp < ::Metasm::DynLdr
		DBGHELP_DLL = 'C:\\Program Files\\Debugging Tools For Windows (x86)\\dbghelp.dll'
		
		new_api_c <<EOS, DBGHELP_DLL
		
#line #{__LINE__}
typedef enum _MINIDUMP_TYPE {
    MiniDumpNormal                         = 0x00000000,
    MiniDumpWithDataSegs                   = 0x00000001,
    MiniDumpWithFullMemory                 = 0x00000002,
    MiniDumpWithHandleData                 = 0x00000004,
    MiniDumpFilterMemory                   = 0x00000008,
    MiniDumpScanMemory                     = 0x00000010,
    MiniDumpWithUnloadedModules            = 0x00000020,
    MiniDumpWithIndirectlyReferencedMemory = 0x00000040,
    MiniDumpFilterModulePaths              = 0x00000080,
    MiniDumpWithProcessThreadData          = 0x00000100,
    MiniDumpWithPrivateReadWriteMemory     = 0x00000200,
    MiniDumpWithoutOptionalData            = 0x00000400,
    MiniDumpWithFullMemoryInfo             = 0x00000800,
    MiniDumpWithThreadInfo                 = 0x00001000,
    MiniDumpWithCodeSegs                   = 0x00002000,
    MiniDumpWithoutAuxiliaryState          = 0x00004000,
    MiniDumpWithFullAuxiliaryState         = 0x00008000,
    MiniDumpWithPrivateWriteCopyMemory     = 0x00010000,
    MiniDumpIgnoreInaccessibleMemory       = 0x00020000,
    MiniDumpWithTokenInformation           = 0x00040000,
    MiniDumpValidTypeFlags                 = 0x0007ffff,
} MINIDUMP_TYPE;

typedef int BOOL;
typedef char CHAR;
typedef unsigned char BYTE;
typedef unsigned long DWORD;
typedef unsigned __int64 DWORD64;
typedef void *HANDLE;
typedef unsigned __int64 *PDWORD64;
typedef void *PVOID;
typedef unsigned long ULONG;
typedef unsigned long ULONG_PTR;
typedef unsigned __int64 ULONG64;
typedef const CHAR *PCSTR;
typedef CHAR *PSTR;

BOOL
__stdcall
MiniDumpWriteDump(
    HANDLE hProcess,
    DWORD ProcessId,
    HANDLE hFile,
    MINIDUMP_TYPE DumpType,
    PVOID ExceptionParam,
    PVOID UserStreamParam,
    PVOID CallbackParam
    );

EOS

		def self.create_minidump(pid, path)
			# TODO: CreateFileA
			DbgHelp.minidumpwritedump(
				::Metasm::WinAPI.openprocess(Metasm::WinAPI::PROCESS_ALL_ACCESS, 0, pid),
				pid,
				hFile,
				0x00000002,
				0,0,0)
		end
	end

end