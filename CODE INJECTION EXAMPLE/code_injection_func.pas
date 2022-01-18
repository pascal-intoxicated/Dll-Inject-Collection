{

  ###################################################
  #          CODED BY. PASCAL-INTOXICATED           #
  ###################################################

  DATE : 2022-01-18
  IDE  : Delphi XE 10.3 Community Edition

}

unit code_injection_func;

interface

Uses
  WinApi.Windows;

implementation

Procedure MessageBoxInlineASM();
Begin
  {
    int MessageBoxA(
      [in, optional] HWND   hWnd,
      [in, optional] LPCSTR lpText,
      [in, optional] LPCSTR lpCaption,
      [in]           UINT   uType
    );
  }
  Asm
    push $00  //UINT   uType
    push $00  //LPCSTR lpCaption
    push $00  //LPCSTR lpText
    push $00  //HWND   hWnd
    call [$FFFFFFFF]
    ret
  End;
End;

Procedure CallFuncEx(TargetHandle : Cardinal; lpBaseAddress, lpFuncAddress: DWORD);
Const
  OPCODE : Byte = $E8;
Var
  Buffer: DWORD;
begin
  WriteProcessMemory(TargetHandle, Pointer(lpBaseAddress), @OPCODE, SizeOf(OPCODE), PNativeUInt(Nil)^);
  Buffer := lpFuncAddress - lpBaseAddress - 5;
  WriteProcessMemory(TargetHandle, Pointer(lpBaseAddress + $01), @Buffer, SizeOf(Buffer), PNativeUint(Nil)^);
end;

Procedure CODE_injection(ProcessId : Integer);
Var
  hProcess : THandle;

  LibBaseAddr, AllocBaseAddr : DWORD;
Begin
  Try
    hProcess := OpenProcess(PROCESS_ALL_ACCESS, FALSE, ProcessId);

    if (hProcess <> 0) then begin
      LibBaseAddr := DWORD(GetProcAddress(GetModuleHandleA('USER32.DLL'), 'MessageBoxA'));

      if (LibBaseAddr <> 0) then begin
        AllocBaseAddr := DWORD(VirtualAllocEx(hProcess, Nil, $128, MEM_COMMIT, PAGE_EXECUTE_READWRITE));

        if (AllocBaseAddr <> 0) then begin
          {
            Write inline ams
          }
          WriteProcessMemory(hProcess, Ptr(AllocBaseAddr), @MessageBoxInlineASM, $128, PNativeUInt(Nil)^);

          {
            call func patch

            AllocBaseAddr + 08 = call
            AllocBaseAddr + 09 = [$FFFFFFFF]
          }
          CallFuncEx(hProcess, AllocBaseAddr + $08, LibBaseAddr);

          {
            inject(create thread) !
          }
          CreateRemoteThread(hProcess, Nil, 0, Ptr(AllocBaseAddr), Nil, 0, PDWORD(Nil)^);
        end;
      end;
    end;
  Finally
    CloseHandle(hProcess);
  End;
End;

end.
