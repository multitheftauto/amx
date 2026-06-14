#include <gtest/gtest.h>
#include <string>
#include <vector>
#include <cstring>

// Forward declare the function from util.cpp
extern "C" void GetAbsolutePath(const char* relative, char* dest);

class SecurityTest : public ::testing::TestWithParam<std::string> {};

TEST_P(SecurityTest, BufferBoundaryMaintained) {
    // Invariant: No write beyond allocated buffer boundary regardless of input length
    std::string payload = GetParam();
    
    const size_t BUFFER_SIZE = 256;
    const size_t GUARD_SIZE = 16;
    std::vector<char> buffer(BUFFER_SIZE + GUARD_SIZE, 0xAA);
    
    // Set guard bytes after the intended buffer
    char* dest = buffer.data();
    char* guard_start = dest + BUFFER_SIZE;
    memset(guard_start, 0xCC, GUARD_SIZE);
    
    // Call the actual production function
    GetAbsolutePath(payload.c_str(), dest);
    
    // Assert: Guard bytes must remain untouched (no buffer overflow)
    for (size_t i = 0; i < GUARD_SIZE; i++) {
        ASSERT_EQ(static_cast<unsigned char>(guard_start[i]), 0xCC)
            << "Buffer overflow detected at guard offset " << i
            << " with input length " << payload.length();
    }
    
    // Assert: Destination must be null-terminated within bounds
    bool null_found = false;
    for (size_t i = 0; i < BUFFER_SIZE; i++) {
        if (dest[i] == '\0') {
            null_found = true;
            break;
        }
    }
    ASSERT_TRUE(null_found) << "No null terminator within buffer bounds";
}

INSTANTIATE_TEST_SUITE_P(
    AdversarialInputs,
    SecurityTest,
    ::testing::Values(
        std::string(512, 'A'),  // Exploit: oversized path
        std::string(255, 'B'),  // Boundary: near typical buffer size
        "valid/path/file.txt"   // Valid: normal input
    )
);

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}