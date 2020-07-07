usingnamespace @import("../c.zig");

pub const Colour = packed struct {
    const Self = @This();

    red: f32,
    green: f32,
    blue: f32,
    alpha: f32,

    pub fn setRGB(self: *Self, red: f32, green: f32, blue: f32) void {
        self.red = red;
        self.green = green;
        self.blue = blue;
    }
};
