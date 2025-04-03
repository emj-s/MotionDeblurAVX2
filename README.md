
# Project Proposal - *High-Performance Image Processing with SIMD: Real-Time Motion Deblurring*

--- Link to video ---
https://drive.google.com/file/d/1UQdDzEJRSzg4MnCgLF4M8W8EhH3C1pu6/view?usp=sharing

--- Links to source codes ---

## Description

The proposed program is an AVX2-optimized deblurring pipeline that runs on NASM and C++. The aim of the project is to avchieve image deblurring with real-time performance while preserving the quality.

The project utilizes Sobel filter for edge detection and Weiner deconvolution that will later be parallelized to optimize the performance and maximize CPU utilization.




![commandprompt](https://github.com/user-attachments/assets/a63ba4e2-c364-4954-8a32-66fa65fa9db8)


## Execution Screenshots

## Discussion of Execution times Sequential vs Parallel

## Execution time comparison
Filter	Sequential (ms)	Parallel (ms)	Speedup
Wiener Filter	70.6054	76.0097	🔻 1.08x slower
Sobel Filter	51.4555	42.6482	⚡ 1.21x faster
Observations:
Sobel Filter Performance:
The parallel Sobel filter is 1.21x faster, showing a noticeable improvement in execution time.
This suggests that AVX2 optimizations and memory access patterns are beneficial for edge detection.

Wiener Filter Performance:
Surprisingly, the parallel Wiener filter is 1.08x slower than the sequential version.
what to improve in:
Overhead from AVX2 instructions.
Memory access inefficiencies.
Potential bottlenecks in convolution or FFT computation.

