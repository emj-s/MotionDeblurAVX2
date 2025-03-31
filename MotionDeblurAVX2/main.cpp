#include <iostream>
#include <fstream>
#include <vector>
#include <cstdint>
#include <cstring>

extern "C" void sobel_avx2(uint8_t* input, uint8_t* output, int width, int height);


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
bool loadBMP(const std::string& filename, BMPHeader& bmpHeader, DIBHeader& dibHeader, std::vector<uint8_t>& imageData);
bool saveBMP(const std::string& filename, const BMPHeader& bmpHeader, const DIBHeader& dibHeader, const std::vector<uint8_t>& imageData);
std::vector<uint8_t> convert4bitTo8bit(const std::vector<uint8_t>& imageData, int width, int height);
std::vector<uint8_t> convert8bitTo4bit(const std::vector<uint8_t>& imageData, int width, int height);

int main() {
    std::string inputFile = "C:\\dichi\\Term2\\MotionDeblurAVX2\\x64\\Debug\\input.bmp";
    std::string outputFile = "C:\\dichi\\Term2\\MotionDeblurAVX2\\x64\\Debug\\output.bmp";

    BMPHeader bmpHeader;
    DIBHeader dibHeader;
    std::vector<uint8_t> imageData;

    if (!loadBMP(inputFile, bmpHeader, dibHeader, imageData)) {
        std::cerr << "Error: Failed to load BMP file." << std::endl;
        return 1;
    }

    if (dibHeader.bitCount != 4) {
        std::cerr << "Error: Only 4-bit grayscale BMP is supported." << std::endl;
        return 1;
    }

    int width = dibHeader.width;
    int height = dibHeader.height;

    // Convert 4-bit grayscale to 8-bit grayscale
    std::vector<uint8_t> image8bit = convert4bitTo8bit(imageData, width, height);
    std::vector<uint8_t> outputImage(image8bit.size(), 0);

    // Apply Sobel filter using AVX2 NASM
    sobel_avx2(image8bit.data(), outputImage.data(), width, height);

    // Convert back to 4-bit (optional, if you want to save as 4-bit)
    std::vector<uint8_t> output4bit = convert8bitTo4bit(outputImage, width, height);

    // Save the output BMP
    if (!saveBMP(outputFile, bmpHeader, dibHeader, output4bit)) {
        std::cerr << "Error: Failed to save BMP file." << std::endl;
        return 1;
    }

    std::cout << "Sobel filter applied successfully!" << std::endl;
    return 0;
}

// Function to load a BMP file
bool loadBMP(const std::string& filename, BMPHeader& bmpHeader, DIBHeader& dibHeader, std::vector<uint8_t>& imageData) {
    std::ifstream file(filename, std::ios::binary);
    if (!file) return false;

    file.read(reinterpret_cast<char*>(&bmpHeader), sizeof(BMPHeader));
    file.read(reinterpret_cast<char*>(&dibHeader), sizeof(DIBHeader));

    if (dibHeader.bitCount != 4) return false;  // Ensure it's a 4-bit BMP

    int imageSize = dibHeader.imageSize;
    imageData.resize(imageSize);
    file.seekg(bmpHeader.offset, std::ios::beg);
    file.read(reinterpret_cast<char*>(imageData.data()), imageSize);

    return true;
}

// Function to save a BMP file
bool saveBMP(const std::string& filename, const BMPHeader& bmpHeader, const DIBHeader& dibHeader, const std::vector<uint8_t>& imageData) {
    std::ofstream file(filename, std::ios::binary);
    if (!file) return false;

    file.write(reinterpret_cast<const char*>(&bmpHeader), sizeof(BMPHeader));
    file.write(reinterpret_cast<const char*>(&dibHeader), sizeof(DIBHeader));
    file.write(reinterpret_cast<const char*>(imageData.data()), imageData.size());

    return true;
}

// Convert 4-bit grayscale to 8-bit grayscale
std::vector<uint8_t> convert4bitTo8bit(const std::vector<uint8_t>& imageData, int width, int height) {
    std::vector<uint8_t> output(width * height);
    for (size_t i = 0, j = 0; i < imageData.size(); i++) {
        output[j++] = (imageData[i] >> 4) * 17;
        output[j++] = (imageData[i] & 0xF) * 17;
    }
    return output;
}

// Convert 8-bit grayscale back to 4-bit grayscale
std::vector<uint8_t> convert8bitTo4bit(const std::vector<uint8_t>& imageData, int width, int height) {
    std::vector<uint8_t> output((width * height) / 2);
    for (size_t i = 0, j = 0; i < output.size(); i++) {
        output[i] = ((imageData[j] / 17) << 4) | (imageData[j + 1] / 17);
        j += 2;
    }
    return output;
}
