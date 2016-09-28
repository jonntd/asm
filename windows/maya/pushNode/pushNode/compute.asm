.data
ONE qword -0.5


.code
	push_no_stress_loop proc
	;function signature
	;extern "C" void push_no_stress_loop(double* pts, float* normals, double weight, int point_count);
	; this mean we expect the following arguments in the following registers
	; pts -> this is a double* but that doesn mean it will go into xmm*, 
	;        it will actually go into rcx
	; normals -> same as above but in rdx 
	; weight -> xmm2
	; point_count -> r9 
	
	MainLoop:

	;processing x coord
	movsd xmm6,  qword ptr[rcx] ; load point single coord into register
	movss xmm7,  dword ptr[rdx] ; load normal single coord into register
	cvtss2sd xmm7, xmm7 ; convert normals single precision to double precision
	mulsd xmm7, xmm2 ;scale the normal value
	addsd xmm6, xmm7  ; perform the addition
	movsd mmword ptr[rcx ] , xmm6 ;store result into memory
	;processing y coord
	add rcx,8
	add rdx,4
	movsd xmm6,  qword ptr[rcx] ; load point single coord into register
	movss xmm7,  dword ptr[rdx] ; load normal single coord into register
	cvtss2sd xmm7, xmm7 ; convert normals single precision to double precision
	mulsd xmm7, xmm2 ;scale the normal value
	addsd xmm6, xmm7  ; perform the addition
	movsd mmword ptr[rcx ] , xmm6 ;store result into memory

	;processing z coord
	add rcx,8
	add rdx,4
	movsd xmm6,  qword ptr[rcx] ; load point single coord into register
	movss xmm7,  dword ptr[rdx] ; load normal single coord into register
	cvtss2sd xmm7, xmm7 ; convert normals single precision to double precision
	mulsd xmm7, xmm2 ;scale the normal value
	addsd xmm6, xmm7  ; perform the addition
	movsd mmword ptr[rcx ] , xmm6 ;store result into memory

	add rcx,16
	add rdx,4

	dec r9
	cmp r9,0
	jnz MainLoop;
	ret

	push_no_stress_loop endp
end
;000001F731D9303B  mov         rax,qword ptr [ptr]  
;000001F731D93043  movsd       xmm0,mmword ptr [rax]  
;000001F731D93047  movsd       mmword ptr [y],xmm0  
