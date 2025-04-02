#include <iostream>
#include <vector>
#include <fstream>
#include <cstdint>
#include <cstring>
#include <immintrin.h>

extern "C" void sobel_avx2(uint8_t* input, uint8_t* output, int width, int height);
extern "C" void wiener_avx2(uint8_t* input, uint8_t* output, int width, int height, float K);

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

    // Handle 4-bit BMP
    if (dibHeader.bitCount == 4) {
        std::cout << "Converting 4-bit BMP to 8-bit grayscale..." << std::endl;

        // Read color palette (16 entries for 4-bit)
        std::vector<uint8_t> colorPalette(16 * 4); // 16 colors, 4 bytes each (BGRA)
        file.seekg(sizeof(BMPHeader) + dibHeader.size, std::ios::beg);
        file.read(reinterpret_cast<char*>(colorPalette.data()), 16 * 4);

        // Calculate row padding (rows are padded to 4-byte boundaries)
        int rowWidth = dibHeader.width;
        int rowSizeInBytes = ((rowWidth * 4 + 31) / 32) * 4; // 4-bit row size with padding

        // Read the 4-bit image data
        std::vector<uint8_t> rawData(rowSizeInBytes * std::abs(dibHeader.height));
        file.seekg(bmpHeader.offset, std::ios::beg);
        file.read(reinterpret_cast<char*>(rawData.data()), rawData.size());

        // Convert to 8-bit
        imageData.resize(rowWidth * std::abs(dibHeader.height));

        for (int y = 0; y < std::abs(dibHeader.height); y++) {
            for (int x = 0; x < rowWidth; x++) {
                int bytePos = y * rowSizeInBytes + x / 2;
                uint8_t pixelByte = rawData[bytePos];

                // Extract 4-bit value (high or low nibble)
                uint8_t pixelValue;
                if (x % 2 == 0) {
                    pixelValue = (pixelByte >> 4) & 0x0F; // High nibble
                }
                else {
                    pixelValue = pixelByte & 0x0F;        // Low nibble
                }

                // Convert to 8-bit by scaling (0-15 to 0-255)
                imageData[y * rowWidth + x] = (pixelValue * 255) / 15;
            }
        }

        // Update DIB header to reflect the new 8-bit format
        dibHeader.bitCount = 8;
        dibHeader.imageSize = rowWidth * std::abs(dibHeader.height);
        dibHeader.colorsUsed = 256;
        dibHeader.colorsImportant = 256;

        return true;
    }
    // Handle 8-bit BMP (original code)
    else if (dibHeader.bitCount == 8) {
        // Calculate row size with padding (rows are padded to 4-byte boundaries)
        int rowWidth = dibHeader.width;
        int rowSizeInBytes = ((rowWidth + 3) / 4) * 4;
        int imageSize = rowSizeInBytes * std::abs(dibHeader.height);

        if (dibHeader.imageSize <= 0 || dibHeader.imageSize != imageSize) {
            std::cerr << "Warning: Invalid image size in BMP header. Recalculating..." << std::endl;
            dibHeader.imageSize = imageSize;
        }

        // Read the raw data with padding
        std::vector<uint8_t> rawData(imageSize);
        file.seekg(bmpHeader.offset, std::ios::beg);
        file.read(reinterpret_cast<char*>(rawData.data()), imageSize);

        // Remove padding and store in imageData
        imageData.resize(rowWidth * std::abs(dibHeader.height));
        for (int y = 0; y < std::abs(dibHeader.height); y++) {
            memcpy(&imageData[y * rowWidth], &rawData[y * rowSizeInBytes], rowWidth);
        }

        std::cout << "BMP file loaded successfully! Image size: " << imageData.size() << " bytes" << std::endl;
        return true;
    }
    else {
        std::cerr << "Error: Unsupported BMP format. Expected 4-bit or 8-bit grayscale, but got "
            << dibHeader.bitCount << "-bit." << std::endl;
        return false;
    }
}

bool saveBMP(const std::string& filename, const BMPHeader& bmpHeader, const DIBHeader& dibHeader, const std::vector<uint8_t>& imageData) {
    std::ofstream file(filename, std::ios::binary);
    if (!file) {
        std::cerr << "Error: Could not open file for writing: " << filename << std::endl;
        return false;
    }

    // Create a copy of the headers to modify
    BMPHeader newBmpHeader = bmpHeader;
    DIBHeader newDibHeader = dibHeader;

    // Ensure the DIB header has the correct values
    newDibHeader.bitCount = 8;

    // Calculate row size with padding (rows are padded to 4-byte boundaries)
    int rowWidth = newDibHeader.width;
    int rowSizeInBytes = ((rowWidth + 3) / 4) * 4;
    int paddedImageSize = rowSizeInBytes * std::abs(newDibHeader.height);
    newDibHeader.imageSize = paddedImageSize;

    // Calculate the offset to pixel data (including the color palette for 8-bit)
    uint32_t paletteSize = 256 * 4; // 256 colors, 4 bytes each
    newBmpHeader.offset = sizeof(BMPHeader) + sizeof(DIBHeader) + paletteSize;

    // Calculate the total file size
    newBmpHeader.size = newBmpHeader.offset + paddedImageSize;

    // Write headers
    file.write(reinterpret_cast<const char*>(&newBmpHeader), sizeof(BMPHeader));
    file.write(reinterpret_cast<const char*>(&newDibHeader), sizeof(DIBHeader));

    // Write the grayscale palette for 8-bit
    for (int i = 0; i < 256; i++) {
        uint8_t paletteEntry[4] = {
            static_cast<uint8_t>(i),  // Blue
            static_cast<uint8_t>(i),  // Green
            static_cast<uint8_t>(i),  // Red
            0                         // Reserved
        };
        file.write(reinterpret_cast<const char*>(paletteEntry), 4);
    }

    // Write image data with padding
    std::vector<uint8_t> paddedData(paddedImageSize, 0);
    for (int y = 0; y < std::abs(newDibHeader.height); y++) {
        memcpy(&paddedData[y * rowSizeInBytes], &imageData[y * rowWidth], rowWidth);
        // Padding bytes are already initialized to 0
    }

    file.write(reinterpret_cast<const char*>(paddedData.data()), paddedImageSize);

    if (!file.good()) {
        std::cerr << "Error: Failed to write to file: " << filename << std::endl;
        return false;
    }

    std::cout << "Successfully saved: " << filename << std::endl;
    return true;
}

int main() {
    std::string inputFile = "C:\\Users\\Samantha Jade\\Downloads\\input2.bmp";
    std::string outputOriginal = "C:\\Users\\Samantha Jade\\Downloads\\original_8bit2.bmp";
    std::string outputWiener = "C:\\Users\\Samantha Jade\\Downloads\\wiener_output2.bmp";
    std::string outputSobel = "C:\\Users\\Samantha Jade\\Downloads\\sobel_output2.bmp";

    BMPHeader bmpHeader;
    DIBHeader dibHeader;
    std::vector<uint8_t> imageData;

    if (!loadBMP(inputFile, bmpHeader, dibHeader, imageData)) {
        std::cerr << "Error: Failed to load BMP file." << std::endl;
        return 1;
    }

    // After loadBMP, the image should be converted to 8-bit if it was 4-bit
    if (dibHeader.bitCount != 8) {
        std::cerr << "Error: Image conversion failed. Expected 8-bit grayscale." << std::endl;
        return 1;
    }

    int width = dibHeader.width;
    int height = std::abs(dibHeader.height); // Ensure height is positive

    // Print image dimensions for debugging
    std::cout << "Image dimensions: " << width << "x" << height << std::endl;

    // Save the original 8-bit image (after conversion if needed)
    if (!saveBMP(outputOriginal, bmpHeader, dibHeader, imageData)) {
        std::cerr << "Error: Failed to save original 8-bit image." << std::endl;
        return 1;
    }

    /* **************** DEBUG **************** */
    int zeroPixelsInput = 0;
    for (auto pixel : imageData) {
        if (pixel == 0) zeroPixelsInput++;
    }
    std::cout << "Zero pixels in input image: " << zeroPixelsInput << "/" << imageData.size() << std::endl;

    // Add this before calling wiener_avx2
    std::cout << "First 10 pixels of input: ";
    for (int i = 0; i < 10; i++) {
        std::cout << (int)imageData[i] << " ";
    }
    std::cout << std::endl;

    // Apply Wiener filter and save
    std::vector<uint8_t> wienerImage(imageData.size(), 128);
    wiener_avx2(imageData.data(), wienerImage.data(), width, height, 0.5f); // Lower K value for more subtle effect

    std::cout << "First 10 pixels of output: ";
    for (int i = 0; i < 10; i++) {
        std::cout << (int)wienerImage[i] << " ";
    }
    std::cout << std::endl;

    // Debug: Check if Wiener filter produced any non-zero pixels
    int nonZeroWiener = 0;
    int zeroPixelsAfterWiener = 0;
    for (auto pixel : wienerImage) {
        if (pixel > 0) nonZeroWiener++;
    }
    std::cout << "\nWiener filter non-zero pixels: " << nonZeroWiener << "/" << wienerImage.size() << std::endl;
    std::cout << "Zero pixels after Wiener filter: " << zeroPixelsAfterWiener << "/" << wienerImage.size() << std::endl;


    if (!saveBMP(outputWiener, bmpHeader, dibHeader, wienerImage)) {
        std::cerr << "Error: Failed to save Wiener filtered image." << std::endl;
        return 1;
    }

    // Apply Sobel filter directly to the original image and save
    std::vector<uint8_t> sobelImage(imageData.size(), 0);
    sobel_avx2(imageData.data(), sobelImage.data(), width, height);

    // Debug: Check if Sobel filter produced any non-zero pixels
    int nonZeroSobel = 0;
    for (auto pixel : sobelImage) {
        if (pixel > 0) nonZeroSobel++;
    }
    std::cout << "Sobel filter non-zero pixels: " << nonZeroSobel << "/" << sobelImage.size() << std::endl;

    if (!saveBMP(outputSobel, bmpHeader, dibHeader, sobelImage)) {
        std::cerr << "Error: Failed to save Sobel filtered image." << std::endl;
        return 1;
    }

    std::cout << "\nAll processing completed successfully!" << std::endl;
    std::cout << "Original 8-bit image: " << outputOriginal << std::endl;
    std::cout << "Wiener filtered image: " << outputWiener << std::endl;
    std::cout << "Sobel filtered image: " << outputSobel << std::endl;

    return 0;
}