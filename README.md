
# Project Proposal - *High-Performance Image Processing with SIMD: Real-Time Motion Deblurring*

--- Link to video ---
https://drive.google.com/file/d/1UQdDzEJRSzg4MnCgLF4M8W8EhH3C1pu6/view?usp=sharing

--- Links to source codes ---

## Description

The proposed program is an AVX2-optimized deblurring pipeline that runs on NASM and C++. The aim of the project is to avchieve image deblurring with real-time performance while preserving the quality.

The project utilizes Sobel filter for edge detection and Weiner deconvolution that will later be parallelized to optimize the performance and maximize CPU utilization.



## Execution Screenshots
![commandprompt](https://github.com/user-attachments/assets/a63ba4e2-c364-4954-8a32-66fa65fa9db8)
## Discussion of Execution times Sequential vs Parallel
![image](https://github.com/user-attachments/assets/4ca68021-7ed5-4d06-8930-3e78ecc44a53)

## Execution time comparison
![image](https://github.com/user-attachments/assets/1c48aaa1-3d53-4f5d-859c-1550c56afaa7)

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

