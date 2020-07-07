usingnamespace @import("../c.zig");

pub const QuadColourIndices = packed struct {
    top_left: u8,
    bottom_left: u8,
    top_right: u8,
    bottom_right: u8,
};
