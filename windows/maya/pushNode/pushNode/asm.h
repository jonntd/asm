#pragma once

extern "C"
{
	void push_no_stress_loop(double* pts, float* normals, double weight, int point_count);
	void push_no_stress_avx_loop(double* pts, float* normals, double weight, int point_count);
	void push_no_stress_avx_threaded(double* pts, float* normals, double weight, int point_count);
}