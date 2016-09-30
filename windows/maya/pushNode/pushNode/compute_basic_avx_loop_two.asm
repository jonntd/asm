.code
	push_no_stress_avx_loop_two proc
	;function signature
	;extern "C" void push_no_stress_loop(double* pts, float* normals, double weight, int point_count);
	; this mean we expect the following arguments in the following registers
	; pts -> this is a double* but that doesn mean it will go into xmm*, 
	;        it will actually go into rcx
	; normals -> same as above but in rdx 
	; weight -> xmm2
	; point_count -> r9 
	
	mov r10,rdx ;we save rdx (the normal pointer) into r10
	mov rdx,0; ; we claer it out
	mov rax , r9; move the point count into rax
	mov r11,2; set the divident
	div r11 ; divide by two, now rax has the modulus , rdx has the reminder.
	;TODO do an and operation with one to get reminder and do a right shift to devide by two

	vbroadcastsd ymm2, xmm2 ; loading the weight on all 4 slots of the register

	MainLoop:
	vmovupd ymm0,  qword ptr[rcx] ; loading 4 doubles into the first register
								 ; it holds the positions

	vmovups xmm1, dword ptr[r10] ; here we load 4 floats, the normals, the normals
								; are packed 3 at the times not 4, so one is actually 
								; from next one, but won't affect the computation since is 
								; affecting only the w component
	vcvtps2pd ymm1, xmm1 ;converting float4 to double 4

	vmulpd ymm1, ymm1, ymm2 ; scaling the normal

	vaddpd ymm0, ymm0,ymm1 ; summing the vector 
	vmovupd qword ptr [rcx], ymm0 ;writing the result to memory

	;here we apply the same code  since we are looping two elements at the same time
	add rcx,32 ;shifting the points pointer
	add r10,12 ; shifting the normals pointer

	vmovupd ymm0,  qword ptr[rcx] ; loading 4 doubles into the first register
								 ; it holds the positions

	vmovups xmm1, dword ptr[r10] ; here we load 4 floats, the normals, the normals
								; are packed 3 at the times not 4, so one is actually 
								; from next one, but won't affect the computation since is 
								; affecting only the w component
	vcvtps2pd ymm1, xmm1 ;converting float4 to double 4

	vmulpd ymm1, ymm1, ymm2 ; scaling the normal

	vaddpd ymm0, ymm0,ymm1 ; summing the vector 
	vmovupd qword ptr [rcx], ymm0 ;writing the result to memory
	add rcx,32 ;shifting the points pointer
	add r10,12 ; shifting the normals pointer

	dec rax ;decrementing the counter
	cmp rax,0 ;check if we are done
	jnz MainLoop ;if not repeat the loop

	;taking care of last vertex if we have
	cmp rdx,1; checking if we have a reminder of 1, if we do we move forward
			;otherwise we jump out
	jnz Exit

	;same exact procedure for last vertex
	vmovupd ymm0,  qword ptr[rcx] ; loading 4 doubles into the first register
								 ; it holds the positions

	vmovups xmm1, dword ptr[r10] ; here we load 4 floats, the normals, the normals
								; are packed 3 at the times not 4, so one is actually 
								; from next one, but won't affect the computation since is 
								; affecting only the w component
	vcvtps2pd ymm1, xmm1 ;converting float4 to double 4

	vmulpd ymm1, ymm1, ymm2 ; scaling the normal

	vaddpd ymm0, ymm0,ymm1 ; summing the vector 
	vmovupd qword ptr [rcx], ymm0 ;writing the result to memory

	Exit:
	ret
	
	push_no_stress_avx_loop_two endp
end