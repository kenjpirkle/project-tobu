usingnamespace @import("../c.zig");

pub const QuadTransform = packed struct {
    x: u16,
    y: u16,
    width: u16,
    height: u16,
};
