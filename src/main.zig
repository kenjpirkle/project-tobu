const std = @import("std");
const fs = std.fs;
const perlin = @import("perlin_noise.zig");
const falloff = std.mem.bytesAsSlice(f32, @embedFile("../falloff.dat"));
const World = @import("world.zig").World;
const Game = @import("game.zig").Game;

pub fn main() anyerror!void {
    // const f = try fs.Dir.readFileAlloc(fs.cwd(), std.heap.c_allocator, "falloff.dat", 8192 * 8192 * @sizeOf(f32));
    // const falloff = std.mem.bytesAsSlice(f32, f);
    // const falloff = try perlin.generateFalloutMap(4096, std.heap.c_allocator);
    // defer std.heap.c_allocator.free(falloff);
    // var norm_fallout: []f32 = try std.heap.c_allocator.alloc(f32, 4096 * 4096);
    // for (falloff) |v, i| {
    //     norm_fallout[i] = v * 255.0;
    // }
    // defer std.heap.c_allocator.free(norm_fallout);
    // try perlin.heightMapToFile(norm_fallout, "fallout.bmp");
    // const f = try fs.Dir.createFile(fs.cwd(), "falloff.dat", .{});
    // const bytes = std.mem.sliceAsBytes(falloff);
    // try fs.File.writeAll(f, bytes);
    // f.close();
    var game: Game = undefined;
    try game.init();
    defer game.deinit();
    game.start();
}
