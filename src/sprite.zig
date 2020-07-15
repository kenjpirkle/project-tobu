const warn = @import("std").debug.warn;
const builtin = @import("std").builtin;
const Game = @import("game.zig").Game;
const Quad = @import("gl/quad.zig").Quad;
const Colour = @import("gl/colour.zig").Colour;
const QuadColourIndices = @import("gl/quad_colour_indices.zig").QuadColourIndices;
const DrawArraysIndirectCommand = @import("gl/draw_arrays_indirect_command.zig").DrawArraysIndirectCommand;
usingnamespace @import("c.zig");
const image = @cImport({
    @cInclude("stb_image.h");
});

pub const Sprite = struct {
    const Self = @This();

    file_path: []const u8 = undefined,
    texture_id: GLuint = undefined,
    width: c_int = undefined,
    height: c_int = undefined,

    pub fn insertIntoGame(self: *Self, game: *Game) void {
        game.quad_shader.quad_data.append(&[_]Quad{.{
            .transform = .{
                .x = @intCast(u16, (@divTrunc(game.width, 2) - @intCast(u16, @divTrunc(self.width, 2)))),
                .y = @intCast(u16, (@divTrunc(game.height, 2) - @intCast(u16, @divTrunc(self.height, 2)))),
                .width = @intCast(u16, self.width),
                .height = @intCast(u16, self.height),
            },
            .layer = 1,
            .character = 0,
        }});
        game.quad_shader.colour_data.append(&[_]Colour{
            .{
                .red = 0.0,
                .green = 0.0,
                .blue = 0.0,
                .alpha = 0.0,
            },
        });
        game.quad_shader.colour_index_data.append(&[_]QuadColourIndices{
            .{
                .top_left = 0,
                .bottom_left = 0,
                .top_right = 0,
                .bottom_right = 0,
            },
        });
        game.quad_shader.draw_command_data.append(&[_]DrawArraysIndirectCommand{
            .{
                .vertex_count = 4,
                .instance_count = 1,
                .first_vertex = 0,
                .base_instance = 0,
            },
        });
    }

    pub fn generateTexture(self: *Self, game: *Game) !void {
        var n: c_int = undefined;

        var data = image.stbi_load("assets\\hero.png", &self.width, &self.height, &n, 0);
        defer image.stbi_image_free(data);

        if (builtin.mode == .Debug) {
            warn("x: {}, y: {}\n", .{ self.width, self.height });
        }

        if (data == null) {
            return error.ImageLoadFailed;
        }

        glGenTextures(1, &self.texture_id);
        glBindTexture(GL_TEXTURE_2D, self.texture_id);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, self.width, self.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

        const handle = glGetTextureHandleARB(self.texture_id);
        if (builtin.mode == .Debug) {
            warn("image handle: {}\n", .{handle});
        }
        game.quad_shader.texture_handle_data.append(&[_]GLuint64{handle});
        glMakeTextureHandleResidentARB(handle);
    }
};
