#include <iostream>
#include <vector>
#include <fstream>
#include <cstdint>
#include <cstring>
#include <immintrin.h>

extern "C" void sobel_avx2(uint8_t* input, uint8_t* output, int width, int height);
extern "C" void wiener_avx2(uint8_t* input, uint8_t* output, int width, int height, double K);

#pragma pack(push, 1)
struct BMPHeader {
    uint16_t type;
    uint32_t size;
    uint16_t reserved1;
    uint16_t reserved2;
    uint32_t offset;
};

struct DIBHeader {
    uint32_t size;
    int32_t width;
    int32_t height;
    uint16_t planes;
    uint16_t bitCount;
    uint32_t compression;
    uint32_t imageSize;
    int32_t xPixelsPerMeter;
    int32_t yPixelsPerMeter;
    uint32_t colorsUsed;
    uint32_t colorsImportant;
};
#pragma pack(pop)

// Function prototypes
bool loadBMP(const std::string& filename, BMPHeader& bmpHeader, DIBHeader& dibHeader, std::vector<uint8_t>& imageData) {
    std::ifstream file(filename, std::ios::binary);

    if (!file) {
        std::cerr << "Error: File not found: " << filename << std::endl;
        return false;
    }

    std::cout << "Reading BMP headers..." << std::endl;

    // Read BMP and DIB headers
    file.read(reinterpret_cast<char*>(&bmpHeader), sizeof(BMPHeader));
    file.read(reinterpret_cast<char*>(&dibHeader), sizeof(DIBHeader));

    // Validate BMP type
    if (bmpHeader.type != 0x4D42) { // 'BM' in hex
        std::cerr << "Error: Invalid BMP file (not 'BM' type)." << std::endl;
        return false;
    }

    // Validate that it's an 8-bit grayscale BMP
    if (dibHeader.bitCount != 8) {
        std::cerr << "Error: Unsupported BMP format. Expected 8-bit grayscale, but got "
            << dibHeader.bitCount << "-bit." << std::endl;
        return false;
    }

    // Fix invalid image size
    int imageSize = dibHeader.imageSize;
    if (imageSize <= 0) {
        std::cerr << "Warning: Invalid image size in BMP header. Recalculating..." << std::endl;
        imageSize = dibHeader.width * std::abs(dibHeader.height);
    }

    // Resize vector to hold image data
    imageData.resize(imageSize);

    // Seek to pixel data and read it
    file.seekg(bmpHeader.offset, std::ios::beg);
    file.read(reinterpret_cast<char*>(imageData.data()), imageSize);

    // Verify that the image data was read correctly
    if (file.gcount() != imageSize) {
        std::cerr << "Error: Failed to read the expected image data." << std::endl;
        return false;
    }

    std::cout << "BMP file loaded successfully! Image size: " << imageSize << " bytes" << std::endl;
    return true;
}


bool saveBMP(const std::string& filename, const BMPHeader& bmpHeader, const DIBHeader& dibHeader, const std::vector<uint8_t>& imageData) {
    std::ofstream file(filename, std::ios::binary);
    if (!file) return false;

    file.write(reinterpret_cast<const char*>(&bmpHeader), sizeof(BMPHeader));
    file.write(reinterpret_cast<const char*>(&dibHeader), sizeof(DIBHeader));
    file.write(reinterpret_cast<const char*>(imageData.data()), imageData.size());

    return true;
}

int main() {
    std::string inputFile = "C:\\Users\\Samantha Jade\\Downloads\\input.bmp";
    std::string outputFile = "C:\\Users\\Samantha Jade\\Downloads\\output.bmp";

    BMPHeader bmpHeader;
    DIBHeader dibHeader;
    std::vector<uint8_t> imageData;

    if (!loadBMP(inputFile, bmpHeader, dibHeader, imageData)) {
        std::cerr << "Error: Failed to load BMP file." << std::endl;
        return 1;
    }

    if (dibHeader.bitCount != 8) {
        std::cerr << "Error: Only 8-bit grayscale BMP is supported." << std::endl;
        return 1;
    }

    int width = dibHeader.width;
    int height = dibHeader.height;

    std::vector<uint8_t> deblurredImage(imageData.size(), 0);
    wiener_avx2(imageData.data(), deblurredImage.data(), width, height, 0.01);

    std::vector<uint8_t> sobelImage(imageData.size(), 0);
    sobel_avx2(deblurredImage.data(), sobelImage.data(), width, height);

    if (!saveBMP(outputFile, bmpHeader, dibHeader, sobelImage)) {
        std::cerr << "Error: Failed to save BMP file." << std::endl;
        return 1;
    }

    std::cout << "Wiener deconvolution and Sobel filter applied successfully!" << std::endl;
    return 0;
}
