#include <windows.h>
#include <wincrypt.h>
#include <stdio.h>
#include <stdlib.h>

#pragma comment(lib, "crypt32")

int main(int argc, char **argv)
{
	DATA_BLOB	dataIn;
	DATA_BLOB	dataOut;
	FILE		*fp;
	DWORD		dwSize;

	if(argc != 3) {
		printf("Usage: \n");
		printf("%s [in] [out]\n", argv[0]);
		return -1;
	}

	fp = fopen(argv[1], "rb");
	if(fp == NULL) {
		printf("[-] Failed to open input file\n");
		return -1;
	}

	fseek(fp, 0L, SEEK_END);
	dwSize = ftell(fp);
	fseek(fp, 0L, SEEK_SET);

	dataIn.cbData = dwSize;
	dataIn.pbData = (BYTE*) malloc(dwSize + 1);

	if(!dataIn.pbData) {
		printf("[-] Failed to allocate memory for encrypted data\n");
		return -1;
	}

	fread((char*) dataIn.pbData, dwSize, 1, fp);
	fclose(fp);

	printf("[+] Encrypted data size: %d\n", dwSize);

	dataOut.cbData = 0;
	dataOut.pbData = NULL;

	if(CryptUnprotectData(&dataIn, NULL, NULL, NULL, NULL, 0, &dataOut)) {
		printf("[+] Decrypted data size: %d\n", dataOut.cbData);
	}
	else {
		printf("[-] Failed to decrypt data\n");
		return -1;
	}

	fp = fopen(argv[2], "wb");
	if(fp == NULL) {
		printf("[-] Failed to open output file\n");
		return -1;
	}

	printf("[+] Writing decrypted data to output file: %s\n", argv[2]);
	fwrite((void*) dataOut.pbData, dataOut.cbData, 1, fp);
	fclose(fp);

	return 0;
}