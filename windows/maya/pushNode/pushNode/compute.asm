.code
	push_no_stress_loop proc
	;function signature
	;extern "C" void push_no_stress_loop(double* pts, float* normals, double weight, int point_count);
	; this mean we expect the following arguments in the following registers
	; pts -> mmx0
	; normals -> mmx1
	; weight -> mmx2
	; point_count -> r9 
	ret
	push_no_stress_loop endp
end
