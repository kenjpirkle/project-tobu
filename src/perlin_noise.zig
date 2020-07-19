const std = @import("std");
const warn = @import("std").debug.warn;
const c_allocator = std.heap.c_allocator;
const Allocator = std.mem.Allocator;
const image_write = @cImport({
    @cInclude("stb_image_write.h");
});

// int stbi_write_bmp(char const *filename, int w, int h, int comp, const void *data);

const perms = [_]u8{
    151, 160, 137, 91,  90,  15,
    131, 13,  201, 95,  96,  53,
    194, 233, 7,   225, 140, 36,
    103, 30,  69,  142, 8,   99,
    37,  240, 21,  10,  23,  190,
    6,   148, 247, 120, 234, 75,
    0,   26,  197, 62,  94,  252,
    219, 203, 117, 35,  11,  32,
    57,  177, 33,  88,  237, 149,
    56,  87,  174, 20,  125, 136,
    171, 168, 68,  175, 74,  165,
    71,  134, 139, 48,  27,  166,
    77,  146, 158, 231, 83,  111,
    229, 122, 60,  211, 133, 230,
    220, 105, 92,  41,  55,  46,
    245, 40,  244, 102, 143, 54,
    65,  25,  63,  161, 1,   216,
    80,  73,  209, 76,  132, 187,
    208, 89,  18,  169, 200, 196,
    135, 130, 116, 188, 159, 86,
    164, 100, 109, 198, 173, 186,
    3,   64,  52,  217, 226, 250,
    124, 123, 5,   202, 38,  147,
    118, 126, 255, 82,  85,  212,
    207, 206, 59,  227, 47,  16,
    58,  17,  182, 189, 28,  42,
    223, 183, 170, 213, 119, 248,
    152, 2,   44,  154, 163, 70,
    221, 153, 101, 155, 167, 43,
    172, 9,   129, 22,  39,  253,
    19,  98,  108, 110, 79,  113,
    224, 232, 178, 185, 112, 104,
    218, 246, 97,  228, 251, 34,
    242, 193, 238, 210, 144, 12,
    191, 179, 162, 241, 81,  51,
    145, 235, 249, 14,  239, 107,
    49,  192, 214, 31,  181, 199,
    106, 157, 184, 84,  204, 176,
    115, 121, 50,  45,  127, 4,
    150, 254, 138, 236, 205, 93,
    222, 114, 67,  29,  24,  72,
    243, 141, 128, 195, 78,  66,
    215, 61,  156, 180,
} ** 2;

inline fn fade(t: f64) f64 {
    return t * t * t * (t * (t * 6 - 15) + 10);
}

inline fn gradient(hash: u8, x: f64, y: f64, z: f64) f64 {
    return switch (hash & 15) {
        0 => x + y,
        1 => -x + y,
        2 => x - y,
        3 => -x - y,
        4 => x + z,
        5 => -x + z,
        6 => x - z,
        7 => -x - z,
        8 => y + z,
        9 => -y + z,
        10 => y - z,
        11 => -y - z,
        12 => y + x,
        13 => -y + z,
        14 => y - x,
        15 => -y - z,
        else => unreachable,
    };
}

inline fn lerp(a: f64, b: f64, x: f64) f64 {
    return a + x * (b - a);
}

fn perlin(x: f64, y: f64, z: f64) f64 {
    const x_trunc = @floatToInt(u64, x);
    const y_trunc = @floatToInt(u64, y);
    const z_trunc = @floatToInt(u64, z);

    const xi: usize = x_trunc & 255;
    const yi: usize = y_trunc & 255;
    const zi: usize = z_trunc & 255;

    const xf: f64 = x - @intToFloat(f64, x_trunc);
    const yf: f64 = y - @intToFloat(f64, y_trunc);
    const zf: f64 = z - @intToFloat(f64, z_trunc);

    const u = fade(xf);
    const v = fade(yf);
    const w = fade(zf);

    const aaa: u8 = perms[perms[perms[xi] + yi] + zi];
    const aba: u8 = perms[perms[perms[xi] + yi + 1] + zi];
    const aab: u8 = perms[perms[perms[xi] + yi] + zi + 1];
    const abb: u8 = perms[perms[perms[xi] + yi + 1] + zi + 1];
    const baa: u8 = perms[perms[perms[xi + 1] + yi] + zi];
    const bba: u8 = perms[perms[perms[xi + 1] + yi + 1] + zi];
    const bab: u8 = perms[perms[perms[xi + 1] + yi] + zi + 1];
    const bbb: u8 = perms[perms[perms[xi + 1] + yi + 1] + zi + 1];

    var x1: f64 = lerp(gradient(aaa, xf, yf, zf), gradient(baa, xf - 1.0, yf, zf), u);
    var x2: f64 = lerp(gradient(aba, xf, yf - 1.0, zf), gradient(bba, xf - 1.0, yf - 1.0, zf), u);
    var y1: f64 = lerp(x1, x2, v);
    x1 = lerp(gradient(aab, xf, yf, zf - 1.0), gradient(bab, xf - 1.0, yf, zf - 1.0), u);
    x2 = lerp(gradient(abb, xf, yf - 1.0, zf - 1.0), gradient(bbb, xf - 1.0, yf - 1.0, zf - 1.0), u);
    var y2: f64 = lerp(x1, x2, v);

    return (lerp(y1, y2, w) + 1.0) / 2.0;
}

fn perlinRepeat(repeat: u64, x: f64, y: f64, z: f64) f64 {}

fn octavePerlin(x: f64, y: f64, z: f64, octaves: u8, persistence: f64) f64 {
    var total: f64 = 0.0;
    var frequency: f64 = 1.0;
    var amplitude: f64 = 1.0;
    var max_value: f64 = 0.0;

    var i: u8 = 0;
    while (i < octaves) : (i += 1) {
        total += perlin(x * frequency, y * frequency, z * frequency) * amplitude;
        max_value += amplitude;
        amplitude *= persistence;
        frequency *= 2;
    }

    return total / max_value;
}

pub fn generateHeightMap(comptime scale: usize, allocator: *Allocator) ![]f32 {
    var values = try allocator.alloc(f32, scale * scale);

    var min: f64 = 1.0;
    var max: f64 = 0.0;
    var x: usize = 0;
    while (x < scale) : (x += 1) {
        var y: usize = 0;
        while (y < scale) : (y += 1) {
            const fp = octavePerlin(@intToFloat(f64, x) / @intToFloat(f64, scale), @intToFloat(f64, y) / @intToFloat(f64, scale), 1.0 / 1024.0, 7, 0.36);
            if (min > fp) {
                min = fp;
            }
            if (max < fp) {
                max = fp;
            }
            values[x * scale + y] = @floatCast(f32, fp);
        }
    }

    var i: usize = 0;
    while (i < values.len) : (i += 1) {
        const new_v = (values[i] - min) / (max - min);
        values[i] = @floatCast(f32, new_v * 255.0);
    }

    return values;
}

pub fn generateNoise(comptime scale: usize) !void {
    var values = try c_allocator.alloc(f64, scale * scale);
    defer c_allocator.free(values);

    var min: f64 = 1.0;
    var max: f64 = 0.0;
    var x: usize = 0;
    while (x < scale) : (x += 1) {
        var y: usize = 0;
        while (y < scale) : (y += 1) {
            const fp = octavePerlin(@intToFloat(f64, x) / 64.0, @intToFloat(f64, y) / 64.0, 1.0 / 1024.0, 7, 0.25);
            if (min > fp) {
                min = fp;
            }
            if (max < fp) {
                max = fp;
            }
            values[x * scale + y] = fp;
        }
    }

    var pixels = try c_allocator.alloc(u8, scale * scale);
    defer c_allocator.free(pixels);

    var i: usize = 0;
    while (i < values.len) : (i += 1) {
        const new_v = (values[i] - min) / (max - min);
        // warn("{d:.5} = ({d:.5} - {d:.5}) / ({d:.5} - {d:.5});\n", .{ new_v, v.*, min, max, min });
        pixels[i] = @floatToInt(u8, new_v * 255.0);
    }

    const result = image_write.stbi_write_bmp("test.bmp", scale, scale, 1, pixels.ptr);

    if (result == 0) {
        return error.ImageCouldNotBeWritten;
    }
}

pub fn heightMapToFile(height_map: []f32) !void {
    var pixels = try c_allocator.alloc(u8, height_map.len);
    defer c_allocator.free(pixels);

    var i: usize = 0;
    while (i < height_map.len) : (i += 1) {
        pixels[i] = @floatToInt(u8, height_map[i]);
    }

    const scale = @intCast(c_int, std.math.sqrt(height_map.len));
    const result = image_write.stbi_write_bmp("test.bmp", scale, scale, 1, pixels.ptr);

    if (result == 0) {
        return error.ImageCouldNotBeWritten;
    }
}
