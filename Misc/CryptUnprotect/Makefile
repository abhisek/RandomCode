!include <win32.mak>

all: unprotect.exe

.c.obj:
  $(cc) $(cdebug) $(cflags) $(cvars) $*.c

unprotect.exe: unprotect.obj
  $(link) $(conflags) -out:unprotect.exe unprotect.obj $(conlibs)

clean:
	del *.obj *.lib *.exp *.pdb