const warn = @import("std").debug.warn;
const perlin = @import("perlin_noise.zig");
const constants = @import("game_constants.zig");

pub const World = struct {
    const sizes = [_]f64{
        16.0, 8.0, 4.0, 2.0, 1.0, 0.5, 0.25,
    };
    const local_size: f64 = 0.015625;

    // 32,256 total vertices
    // 84 chunks
    lods: [sizes.len][12][8][8][6]f32 = undefined,
    close: [4][64][64 * 6]f32 = undefined,

    pub fn generate() !World {
        // perlin noise with falloff map for landmasses
        // temperature map
        // moisture map
        //
        // 512km^2 terrain in memory
        // LOD levels (furthest to closest)
        // 128km^2 12
        //  64km^2 12
        //  32km^2 12
        //  16km^2 12
        //   8km^2 12
        //   4km^2 12
        //   2km^2 12
        //   1km^2  4
        var w: World = undefined;

        // calculate lods
        var offset: f64 = 0.0;
        for (sizes) |size, li| {
            var chunk: usize = 0;
            // top row
            while (chunk < 4) : (chunk += 1) {
                // outer edges first
                // top left corner quad
                var col: usize = 0;
                var row: usize = 0;

                var c0: f64 = @intToFloat(f64, col);
                var r0: f64 = @intToFloat(f64, row);
                var c1: f64 = @intToFloat(f64, col + 1);
                var r1: f64 = @intToFloat(f64, row + 1);
                const ch: f64 = @intToFloat(f64, chunk);
                const cs: f64 = ch * size * 8.0;

                var x0: f64 = offset + cs;
                var y0: f64 = offset;
                var x1: f64 = undefined;
                var y1: f64 = undefined;

                var height: f32 = undefined;

                height = heightAt(x0, y0);
                w.lods[li][chunk][row][col][0] = height;
                w.lods[li][chunk][row][col][4] = height;

                x1 = offset + cs + (size * c1);
                height = heightAt(x1, y0);
                w.lods[li][chunk][row][col][3] = height;

                y1 = offset + cs + (size * r1);
                height = heightAt(x0, y1);
                w.lods[li][chunk][row][col][1] = height;

                height = heightAt(x1, y1);
                w.lods[li][chunk][row][col][2] = height;
                w.lods[li][chunk][row][col][5] = height;

                // top row quads
                col = 1;
                while (col < 8) : (col += 1) {
                    c1 = @intToFloat(f64, col + 1);
                    r1 = @intToFloat(f64, row + 1);
                    x1 = offset + cs + (size * c1);
                    y1 = offset + cs + (size * r1);

                    w.lods[li][chunk][row][col][0] = w.lods[li][chunk][row][col - 1][3];
                    w.lods[li][chunk][row][col][1] = w.lods[li][chunk][row][col - 1][5];
                    w.lods[li][chunk][row][col][4] = w.lods[li][chunk][row][col - 1][3];

                    height = heightAt(x1, y0);
                    w.lods[li][chunk][row][col][3] = height;

                    height = heightAt(x1, y1);
                    w.lods[li][chunk][row][col][2] = height;
                    w.lods[li][chunk][row][col][5] = height;
                }

                // left edge quads
                row = 1;
                col = 0;
                while (row < 8) : (row += 1) {
                    c0 = @intToFloat(f64, col);
                    r0 = @intToFloat(f64, row);
                    c1 = @intToFloat(f64, col + 1);
                    r1 = @intToFloat(f64, row + 1);
                    x0 = offset + cs;
                    x1 = offset + cs + (size * c1);
                    y1 = offset + cs + (size * r1);

                    w.lods[li][chunk][row][col][0] = w.lods[li][chunk][row - 1][col][1];
                    w.lods[li][chunk][row][col][3] = w.lods[li][chunk][row - 1][col][2];
                    w.lods[li][chunk][row][col][4] = w.lods[li][chunk][row - 1][col][1];

                    height = heightAt(x0, y1);
                    w.lods[li][chunk][row][col][1] = height;

                    height = heightAt(x1, y1);
                    w.lods[li][chunk][row][col][2] = height;
                    w.lods[li][chunk][row][col][5] = height;
                }

                // the rest
                row = 1;
                while (row < 8) : (row += 1) {
                    col = 1;
                    while (col < 8) : (col += 1) {
                        w.lods[li][chunk][row][col][0] = w.lods[li][chunk][row - 1][col][1];
                        w.lods[li][chunk][row][col][1] = w.lods[li][chunk][row][col - 1][2];
                        w.lods[li][chunk][row][col][3] = w.lods[li][chunk][row - 1][col][2];
                        w.lods[li][chunk][row][col][4] = w.lods[li][chunk][row - 1][col][1];

                        c1 = @intToFloat(f64, col + 1);
                        r1 = @intToFloat(f64, row + 1);
                        x1 = offset + cs + (size * c1);
                        y1 = offset + cs + (size * r1);

                        height = heightAt(x1, y1);
                        w.lods[li][chunk][row][col][2] = height;
                        w.lods[li][chunk][row][col][5] = height;
                    }
                }
            }
            // bottom row
            while (chunk < 8) : (chunk += 1) {
                // outer edges first
                // top left corner quad
                var col: usize = 0;
                var row: usize = 0;

                var c0: f64 = @intToFloat(f64, col);
                var r0: f64 = @intToFloat(f64, row);
                var c1: f64 = @intToFloat(f64, col + 1);
                var r1: f64 = @intToFloat(f64, row + 1);
                const ch: f64 = @intToFloat(f64, chunk - 4);
                const cs: f64 = ch * size * 8.0;
                const boff: f64 = 512.0 - offset - (size * 8.0);

                var x0: f64 = offset + cs;
                var y0: f64 = boff;
                var x1: f64 = undefined;
                var y1: f64 = undefined;

                var height: f32 = undefined;

                height = heightAt(x0, y0);
                w.lods[li][chunk][row][col][0] = height;
                w.lods[li][chunk][row][col][4] = height;

                x1 = offset + cs + (size * c1);
                height = heightAt(x1, y0);
                w.lods[li][chunk][row][col][3] = height;

                y1 = boff + (size * r1);
                height = heightAt(x0, y1);
                w.lods[li][chunk][row][col][1] = height;

                height = heightAt(x1, y1);
                w.lods[li][chunk][row][col][2] = height;
                w.lods[li][chunk][row][col][5] = height;

                // top row quads
                col = 1;
                while (col < 8) : (col += 1) {
                    c1 = @intToFloat(f64, col + 1);
                    r1 = @intToFloat(f64, row + 1);
                    x1 = offset + cs + (size * c1);
                    y1 = boff + (size * r1);

                    w.lods[li][chunk][row][col][0] = w.lods[li][chunk][row][col - 1][3];
                    w.lods[li][chunk][row][col][1] = w.lods[li][chunk][row][col - 1][2];
                    w.lods[li][chunk][row][col][4] = w.lods[li][chunk][row][col - 1][3];

                    height = heightAt(x1, y0);
                    w.lods[li][chunk][row][col][3] = height;

                    height = heightAt(x1, y1);
                    w.lods[li][chunk][row][col][2] = height;
                    w.lods[li][chunk][row][col][5] = height;
                }

                // left edge quads
                row = 1;
                col = 0;
                while (row < 8) : (row += 1) {
                    c0 = @intToFloat(f64, col);
                    r0 = @intToFloat(f64, row);
                    c1 = @intToFloat(f64, col + 1);
                    r1 = @intToFloat(f64, row + 1);
                    x0 = offset + cs;
                    x1 = offset + cs + (size * c1);
                    y1 = boff + (size * r1);

                    w.lods[li][chunk][row][col][0] = w.lods[li][chunk][row - 1][col][1];
                    w.lods[li][chunk][row][col][3] = w.lods[li][chunk][row - 1][col][2];
                    w.lods[li][chunk][row][col][4] = w.lods[li][chunk][row - 1][col][1];

                    height = heightAt(x0, y1);
                    w.lods[li][chunk][row][col][1] = height;

                    height = heightAt(x1, y1);
                    w.lods[li][chunk][row][col][2] = height;
                    w.lods[li][chunk][row][col][5] = height;
                }

                // the rest
                row = 1;
                while (row < 8) : (row += 1) {
                    col = 1;
                    while (col < 8) : (col += 1) {
                        w.lods[li][chunk][row][col][0] = w.lods[li][chunk][row - 1][col][1];
                        w.lods[li][chunk][row][col][1] = w.lods[li][chunk][row][col - 1][2];
                        w.lods[li][chunk][row][col][3] = w.lods[li][chunk][row - 1][col][2];
                        w.lods[li][chunk][row][col][4] = w.lods[li][chunk][row - 1][col][1];

                        c1 = @intToFloat(f64, col + 1);
                        r1 = @intToFloat(f64, row + 1);
                        x1 = offset + cs + (size * c1);
                        y1 = boff + (size * r1);

                        height = heightAt(x1, y1);
                        w.lods[li][chunk][row][col][2] = height;
                        w.lods[li][chunk][row][col][5] = height;
                    }
                }
            }
            // left side
            while (chunk < 10) : (chunk += 1) {
                // outer edges first
                // top left corner quad
                var col: usize = 0;
                var row: usize = 0;

                var c0: f64 = @intToFloat(f64, col);
                var r0: f64 = @intToFloat(f64, row);
                var c1: f64 = @intToFloat(f64, col + 1);
                var r1: f64 = @intToFloat(f64, row + 1);
                const ch: f64 = @intToFloat(f64, chunk - 8);
                const cs: f64 = ch * size * 8.0;
                const toff: f64 = offset + (size * 8.0) + cs;

                var x0: f64 = offset;
                var y0: f64 = toff;
                var x1: f64 = undefined;
                var y1: f64 = undefined;

                var height: f32 = undefined;

                height = heightAt(x0, y0);
                w.lods[li][chunk][row][col][0] = height;
                w.lods[li][chunk][row][col][4] = height;

                x1 = offset + cs + (size * c1);
                height = heightAt(x1, y0);
                w.lods[li][chunk][row][col][3] = height;

                y1 = offset + cs + (size * r1);
                height = heightAt(x0, y1);
                w.lods[li][chunk][row][col][1] = height;

                height = heightAt(x1, y1);
                w.lods[li][chunk][row][col][2] = height;
                w.lods[li][chunk][row][col][5] = height;

                // top row quads
                col = 1;
                while (col < 8) : (col += 1) {
                    c1 = @intToFloat(f64, col + 1);
                    r1 = @intToFloat(f64, row + 1);
                    x1 = offset + (size * c1);
                    y1 = toff + (size * r1);

                    w.lods[li][chunk][row][col][0] = w.lods[li][chunk][row][col - 1][3];
                    w.lods[li][chunk][row][col][1] = w.lods[li][chunk][row][col - 1][2];
                    w.lods[li][chunk][row][col][4] = w.lods[li][chunk][row][col - 1][3];

                    height = heightAt(x0, y1);
                    w.lods[li][chunk][row][col][3] = height;

                    height = heightAt(x1, y1);
                    w.lods[li][chunk][row][col][2] = height;
                    w.lods[li][chunk][row][col][5] = height;
                }

                // left edge quads
                row = 1;
                col = 0;
                while (row < 8) : (row += 1) {
                    c0 = @intToFloat(f64, col);
                    r0 = @intToFloat(f64, row);
                    c1 = @intToFloat(f64, col + 1);
                    r1 = @intToFloat(f64, row + 1);
                    x0 = offset;
                    x1 = offset + (size * c1);
                    y1 = toff + (size * r1);

                    w.lods[li][chunk][row][col][0] = w.lods[li][chunk][row - 1][col][1];
                    w.lods[li][chunk][row][col][3] = w.lods[li][chunk][row - 1][col][2];
                    w.lods[li][chunk][row][col][4] = w.lods[li][chunk][row - 1][col][1];

                    height = heightAt(x1, y0);
                    w.lods[li][chunk][row][col][1] = height;

                    height = heightAt(x1, y1);
                    w.lods[li][chunk][row][col][2] = height;
                    w.lods[li][chunk][row][col][5] = height;
                }

                // the rest
                row = 1;
                while (row < 8) : (row += 1) {
                    col = 1;
                    while (col < 8) : (col += 1) {
                        w.lods[li][chunk][row][col][0] = w.lods[li][chunk][row - 1][col][1];
                        w.lods[li][chunk][row][col][1] = w.lods[li][chunk][row][col - 1][2];
                        w.lods[li][chunk][row][col][3] = w.lods[li][chunk][row - 1][col][2];
                        w.lods[li][chunk][row][col][4] = w.lods[li][chunk][row - 1][col][1];

                        c1 = @intToFloat(f64, col + 1);
                        r1 = @intToFloat(f64, row + 1);
                        x1 = offset + (size * c1);
                        y1 = toff + (size * r1);

                        height = heightAt(x1, y1);
                        w.lods[li][chunk][row][col][2] = height;
                        w.lods[li][chunk][row][col][5] = height;
                    }
                }
            }
            // right size
            while (chunk < 12) : (chunk += 1) {
                // outer edges first
                // top left corner quad
                var col: usize = 0;
                var row: usize = 0;

                var c0: f64 = @intToFloat(f64, col);
                var r0: f64 = @intToFloat(f64, row);
                var c1: f64 = @intToFloat(f64, col + 1);
                var r1: f64 = @intToFloat(f64, row + 1);
                const ch: f64 = @intToFloat(f64, chunk - 10);
                const cs: f64 = ch * size * 8.0;
                const toff: f64 = offset + (size * 8.0) + cs;
                const roff: f64 = 512.0 - offset - (size * 8.0);

                var x0: f64 = roff;
                var y0: f64 = toff;
                var x1: f64 = undefined;
                var y1: f64 = undefined;

                var height: f32 = undefined;

                height = heightAt(x0, y0);
                w.lods[li][chunk][row][col][0] = height;
                w.lods[li][chunk][row][col][4] = height;

                x1 = roff + (size * c1);
                height = heightAt(x1, y0);
                w.lods[li][chunk][row][col][3] = height;

                y1 = toff + (size * r1);
                height = heightAt(x0, y1);
                w.lods[li][chunk][row][col][1] = height;

                height = heightAt(x1, y1);
                w.lods[li][chunk][row][col][2] = height;
                w.lods[li][chunk][row][col][5] = height;

                // top row quads
                col = 1;
                while (col < 8) : (col += 1) {
                    c1 = @intToFloat(f64, col + 1);
                    r1 = @intToFloat(f64, row + 1);
                    x1 = roff + (size * c1);
                    y1 = toff + (size * r1);

                    w.lods[li][chunk][row][col][0] = w.lods[li][chunk][row][col - 1][3];
                    w.lods[li][chunk][row][col][1] = w.lods[li][chunk][row][col - 1][2];
                    w.lods[li][chunk][row][col][4] = w.lods[li][chunk][row][col - 1][3];

                    height = heightAt(x0, y1);
                    w.lods[li][chunk][row][col][3] = height;

                    height = heightAt(x1, y1);
                    w.lods[li][chunk][row][col][2] = height;
                    w.lods[li][chunk][row][col][5] = height;
                }

                // left edge quads
                row = 1;
                col = 0;
                while (row < 8) : (row += 1) {
                    c0 = @intToFloat(f64, col);
                    r0 = @intToFloat(f64, row);
                    c1 = @intToFloat(f64, col + 1);
                    r1 = @intToFloat(f64, row + 1);
                    x0 = roff;
                    x1 = roff + (size * c1);
                    y1 = toff + (size * r1);

                    w.lods[li][chunk][row][col][0] = w.lods[li][chunk][row - 1][col][1];
                    w.lods[li][chunk][row][col][3] = w.lods[li][chunk][row - 1][col][2];
                    w.lods[li][chunk][row][col][4] = w.lods[li][chunk][row - 1][col][1];

                    height = heightAt(x1, y0);
                    w.lods[li][chunk][row][col][1] = height;

                    height = heightAt(x1, y1);
                    w.lods[li][chunk][row][col][2] = height;
                    w.lods[li][chunk][row][col][5] = height;
                }

                // the rest
                row = 1;
                while (row < 8) : (row += 1) {
                    col = 1;
                    while (col < 8) : (col += 1) {
                        w.lods[li][chunk][row][col][0] = w.lods[li][chunk][row - 1][col][1];
                        w.lods[li][chunk][row][col][1] = w.lods[li][chunk][row][col - 1][2];
                        w.lods[li][chunk][row][col][3] = w.lods[li][chunk][row - 1][col][2];
                        w.lods[li][chunk][row][col][4] = w.lods[li][chunk][row - 1][col][1];

                        c1 = @intToFloat(f64, col + 1);
                        r1 = @intToFloat(f64, row + 1);
                        x1 = roff + (size * c1);
                        y1 = toff + (size * r1);

                        height = heightAt(x1, y1);
                        w.lods[li][chunk][row][col][2] = height;
                        w.lods[li][chunk][row][col][5] = height;
                    }
                }
            }

            offset += (size * 8.0);
        }
        // calculate close

        offset = 254.0;
        var chunk: usize = 0;
        while (chunk < 4) : (chunk += 1) {}

        // w.lods[0][0][0][7][3] = 45.0;
        // w.lods[0][1][0][0][0] = 45.0;

        warn("45: {d:.5}, 0: {d:.5}\n", .{ w.lods[0][0][0][7][3], w.lods[0][1][0][0][0] });

        // warn("128 chunk\n", .{});
        // var i: usize = 0;
        // while (i < 1) : (i += 1) {
        //     var j: usize = 0;
        //     while (j < 8) : (j += 1) {
        //         var q: usize = 0;
        //         warn("quad: {}:{}: ", .{ i, j });
        //         while (q < 6) : (q += 1) {
        //             warn("{d:.2},", .{w.lods[0][0][i][j][q]});
        //         }
        //         warn("\n", .{});
        //     }
        // }

        // warn("16 chunk\n", .{});
        // i = 0;
        // while (i < 1) : (i += 1) {
        //     var j: usize = 0;
        //     while (j < 8) : (j += 1) {
        //         var q: usize = 0;
        //         warn("quad: {}:{}: ", .{ i, j });
        //         while (q < 6) : (q += 1) {
        //             warn("{d:.2},", .{w.lods[3][0][i][j][q]});
        //         }
        //         warn("\n", .{});
        //     }
        // }

        return w;
    }

    inline fn heightAt(x: f64, y: f64) f32 {
        const h = @floatCast(f32, perlin.octavePerlin(x / 256.0, y / 256.0, 1.0, 7, 0.35) * constants.height_scale);
        // warn("{d:.2},", .{h});
        return h;
    }
};
