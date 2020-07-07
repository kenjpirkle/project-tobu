const warn = @import("std").debug.warn;
const builtin = @import("std").builtin;
const Allocator = @import("std").mem.Allocator;
const Glyph = @import("glyph.zig").Glyph;
const Vector4 = @import("../gl/vector.zig").Vector4;
const math = @import("std").math;
usingnamespace @import("../c.zig");

pub fn Font(comptime char_count: u32, comptime font_size: u32) type {
    return struct {
        const Self = @This();

        texture_transforms: [char_count]Vector4,
        glyphs: [char_count]Glyph,
        bitmap: []u8,
        bitmap_size: u32,
        max_glyph_height: u32,
        max_ascender: u32,
        allocator: *Allocator,

        pub fn init(self: *Self, allocator: *Allocator, path: [*]const u8) !void {
            self.allocator = allocator;

            var ft: FT_Library = undefined;
            if (FT_Init_FreeType(&ft) != 0) {
                warn("could not initialize FreeType library\n", .{});
                return error.FreeTypeLibraryFailed;
            }
            defer _ = FT_Done_FreeType(ft);

            var face: FT_Face = undefined;
            if (FT_New_Face(ft, path, 0, &face) != 0) {
                warn("could not load font: {}\n", .{path});
                return error.FreeTypeLoadFaceFailed;
            }
            defer _ = FT_Done_Face(face);

            _ = FT_Set_Pixel_Sizes(face, 0, font_size);

            // TODO: find out if this call is necessary when using multiple textures
            glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

            const ceil_dim = @floatToInt(u32, @ceil(math.sqrt(128.0)));
            const pixel_height = face.*.size.*.metrics.height >> 6;
            const max_dim = @intCast(u32, (1 + pixel_height)) * ceil_dim;
            self.max_glyph_height = @intCast(u32, pixel_height);
            self.max_ascender = @intCast(u32, face.*.size.*.metrics.ascender >> 6);

            var tex_width: c_long = 1;
            while (tex_width < max_dim) {
                tex_width *= 2;
            }
            const tex_height: c_long = tex_width;

            self.bitmap_size = @intCast(u32, tex_height);
            const size: usize = @intCast(usize, tex_height * tex_width);
            self.bitmap = try allocator.alloc(u8, size);
            for (self.bitmap) |*bit| {
                bit.* = 0;
            }

            var pen_x: c_long = 0;
            var pen_y: c_long = 0;

            const uv_multi: f32 = 1.0 / @intToFloat(f32, tex_width);

            var c: usize = 0;
            while (c < char_count) : (c += 1) {
                const ch = @intCast(c_ulong, c);
                if (FT_Load_Char(face, ch, FT_LOAD_RENDER | FT_LOAD_FORCE_AUTOHINT) != 0) {
                    warn("could not load '{}'\n", .{c});
                } else {
                    const bmp: *FT_Bitmap = &face.*.glyph.*.bitmap;
                    const bmp_width = @intCast(c_long, bmp.*.width);

                    if (pen_x + bmp_width >= tex_width) {
                        pen_x = 0;
                        pen_y += pixel_height + 1;
                    }

                    var x: c_long = 0;
                    var y: c_long = 0;

                    var i: c_long = 0;
                    while (i < bmp.*.rows) : (i += 1) {
                        var j: c_long = 0;
                        while (j < bmp.*.width) : (j += 1) {
                            x = pen_x + j;
                            y = pen_y + i;
                            const pixel_index = @intCast(usize, (y * tex_width) + x);
                            const buffer_index = @intCast(usize, (i * bmp.*.pitch) + j);
                            self.bitmap[pixel_index] = bmp.buffer[buffer_index];
                        }
                    }

                    const px = @intCast(u32, pen_x);
                    const py = @intCast(u32, pen_y);

                    self.texture_transforms[c] = .{
                        .x = @intToFloat(f32, pen_x) * uv_multi,
                        .y = @intToFloat(f32, pen_y) * uv_multi,
                        .z = @intToFloat(f32, bmp.*.width) * uv_multi,
                        .w = @intToFloat(f32, bmp.*.rows) * uv_multi,
                    };

                    self.glyphs[c].x0 = px;
                    self.glyphs[c].y0 = py;
                    self.glyphs[c].x1 = px + @intCast(u32, bmp.*.width);
                    self.glyphs[c].y1 = py + @intCast(u32, bmp.*.rows);
                    self.glyphs[c].x_off = @intCast(i32, face.*.glyph.*.bitmap_left);
                    self.glyphs[c].y_off = @intCast(i32, face.*.glyph.*.bitmap_top);
                    self.glyphs[c].advance = @intCast(u32, face.*.glyph.*.advance.x >> 6);

                    pen_x += @intCast(c_long, bmp.*.width + 1);
                }
            }
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.bitmap);
        }

        pub fn createTexture(self: *Self) GLuint64 {
            var texture: GLuint = undefined;
            glGenTextures(1, &texture);

            if (builtin.mode == .Debug) {
                warn("texture id: {}\n", .{texture});
            }

            const t2d = GL_TEXTURE_2D;
            const size = @intCast(c_int, self.bitmap_size);

            glBindTexture(t2d, texture);
            glTexImage2D(t2d, 0, GL_RED, size, size, 0, GL_RED, GL_UNSIGNED_BYTE, self.bitmap.ptr);

            glTexParameteri(t2d, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
            glTexParameteri(t2d, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
            glTexParameteri(t2d, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(t2d, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

            const handle: GLuint64 = glGetTextureHandleARB(texture);

            if (builtin.mode == .Debug) {
                warn("texture handle id: {}\n", .{handle});
            }

            glMakeTextureHandleResidentARB(handle);
            return handle;
        }

        fn printGlyphs(self: *Self) void {
            warn("number of glyphs: {}\n", .{self.glyphs.len});
            for (self.glyphs) |glyph, i| {
                warn("glyph: '{c}', advance: {}\n", .{ @intCast(u8, i), glyph.advance });
            }
        }
    };
}
