.code
	push_no_stress_avx_loop proc
	;function signature
	;extern "C" void push_no_stress_loop(double* pts, float* normals, double weight, int point_count);
	; this mean we expect the following arguments in the following registers
	; pts -> this is a double* but that doesn mean it will go into xmm*, 
	;        it will actually go into rcx
	; normals -> same as above but in rdx 
	; weight -> xmm2
	; point_count -> r9 
	
	;creating stack frame, not really needed i will remove that later
	push rbp;
	mov rbp , rsp;
	MainLoop:

	vmovupd ymm0,  qword ptr[rcx] ; loading 4 doubles into the first register
								 ; it holds the positions

	vmovups xmm1, dword ptr[rdx] ; here we load 4 floats, the normals, the normals
								; are packed 3 at the times not 4, so one is actually 
								; from next one, but won't affect the computation since is 
								; affecting only the w component
	vcvtps2pd ymm1, xmm1 ;converting float4 to double 4

	vbroadcastsd ymm2, xmm2 ; loading the weight on all 4 slots of the register
	vmulpd ymm1, ymm1, ymm2 ; scaling the normal

	vaddpd ymm0, ymm0,ymm1 ; summing the vector 
	vmovupd qword ptr [rcx], ymm0 ;writing the result to memory

	add rcx,32 ;shifting the points pointer
	add rdx,12 ; shifting the normals pointer

	dec r9 ;decrementing the counter
	cmp r9,0 ;check if we are done
	jnz MainLoop ;if not repeat the loop


	;deleting stack frame
	mov rsp, rbp;
	pop rbp
	ret
	
	push_no_stress_avx_loop endp
end
