#pragma once

extern "C" void push_no_stress_loop(double* pts, float* normals, double weight, int point_count);
extern "C" void push_no_stress_avx_loop(double* pts, float* normals, double weight, int point_count);