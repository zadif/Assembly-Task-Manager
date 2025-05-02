 include functionHeaders.inc 
.386
.model flat, stdcall
.stack 4096

CloseHandle PROTO STDCALL :DWORD
OpenProcess PROTO STDCALL :DWORD, :DWORD, :DWORD
TerminateProcess PROTO STDCALL :DWORD, :DWORD

; ... (rest of the code remains the same) ...
PROCESS_TERMINATE EQU 1h
.data

    pid         dd 0                  ; Storage for the Process ID entered by the user
    hProcess    dd ?                  ; Storage for the process handle returned by OpenProcess

    ; User interaction strings
    promptText  db "Enter PID to terminate: ", 0
    successText db "Process terminated successfully.", 0
    failOpenText db "Error: Could not open process. Invalid PID or insufficient permissions.", 0
    failTermText db "Error: Failed to terminate process (already exited or protected?).", 0
    failCloseText db "Warning: Failed to close process handle.", 0 ; Less critical error (optional message)

.code

terminateProcess2 PROC
  mov edx, OFFSET promptText
    call WriteString      ; Display prompt message
    call ReadDec          ; Read user input (PID) into EAX
    mov pid, eax          ; Store the entered PID

     invoke OpenProcess, PROCESS_TERMINATE,  FALSE,   pid               

      test eax, eax
    jz   OpenFailed         ; If EAX is zero, jump to the OpenFailed error handler

    ; Store the valid process handle
    mov hProcess, eax       ; Save the handle returned by OpenProcess

    ; --- Attempt to terminate the process ---
    invoke TerminateProcess,
           hProcess,    
           0               
             test eax, eax
    jz   TerminateFailed    ; If EAX is zero, jump to the TerminateFailed error handler

    ; --- Termination Successful ---
    mov edx, OFFSET successText
    call WriteString        ; Display success message
    jmp  CloseAndExit  

OpenFailed:
        ; Handle error if OpenProcess failed
    mov edx, OFFSET failOpenText
    call WriteString
    jmp  Done 

TerminateFailed:
; Handle error if TerminateProcess failed (but OpenProcess succeeded)
    mov edx, OFFSET failTermText
    call WriteString
CloseAndExit :
 invoke CloseHandle, hProcess

    jmp Done
Done:
call Crlf             ; Print a newline for cleaner output
    ret   
terminateProcess2 ENDP

END



