
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
Sobel Filter: 1.21x Speedup 
The parallel version of the Sobel filter performs faster than the sequential version.
to  improve:
AVX2 optimizations: SIMD processes multiple pixels in parallel.
Memory access pattern optimization: Efficient prefetching and aligned memory loads reduce cache misses.
Reduced loop overhea d: SIMD allows fewer iterations over the data compared to scalar operations.

Wiener Filter: 1.08x Slowdown 
The parallel version of the Wiener filter is slower than the sequential version.
reasons for slowdown:
Higher memory bandwidth usage: Wiener filtering involves convolution and FFT, which may lead to excess memory accesses.
Cache inefficiencies: Large kernel sizes might not fully utilize AVX2 registers efficiently.
Overhead of parallelization: If the computation is not entirely vector friendly, AVX2 operations may introduce additional overhead.

3. Memory Access and Cache Effects
Sobel filter benefits from localized memory access patterns, making it work with cache.
Wiener filter, with its dependence on convolution, likely causes more cache misses and higher memory latency.
Cache alignment issues: If AVX2 memory loads orstores are misaligned, performance degrades due to partial loads and unaligned accesses.

4. Potential Optimizations
To further improve performance, consider:
A. Wiener Filter Optimizations
Optimize memory access patterns:
Prefetching and blocking techniques can improve the cache efficiency.
Align memory allocations to 32-byte boundaries for AVX2.

Reevaluate parallelization approach:
If it has too many dependent operations, a hybrid approach (mixing SIMD and scalar code) might be better.

Improve FFT implementation:
Consider AVX2-optimized FFT kernels or test different data layouts.

B. Sobel Filter Optimizations
Check if more SIMD width can be used:
If processing 8 pixels at a time, try processing 16 pixels using YMM registers (AVX2).

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

