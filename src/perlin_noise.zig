const warn = @import("std").debug.warn;
const image_write = @cImport({
    @cInclude("stb_image_write.h");
});

// int stbi_write_bmp(char const *filename, int w, int h, int comp, const void *data);

pub fn generateNoise() !void {
    var pixels: [512 * 512]u8 = undefined;
    var i: usize = 0;
    while (i < pixels.len) : (i += 1) {
        const p: u8 = blk: {
            if (i % 3 == 0) {
                break :blk 225;
            } else if (i % 2 == 0) {
                break :blk 125;
            } else {
                break :blk 25;
            }
        };
        pixels[i] = p;
    }

    const result = image_write.stbi_write_bmp("test.bmp", 512, 512, 1, &pixels[0]);

    if (result == 0) {
        return error.ImageCouldNotBeWritten;
    }
}
