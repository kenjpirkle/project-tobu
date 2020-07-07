const QuadTransform = @import("quad_transform.zig").QuadTransform;
usingnamespace @import("../c.zig");

pub const Quad = packed struct {
    const Self = @This();

    transform: QuadTransform,
    layer: u8,
    character: u8,

    pub inline fn contains(self: *Self, x: u16, y: u16) bool {
        return (x >= self.transform.x) and (x <= self.transform.x + self.transform.width) and (y >= self.transform.y) and (y <= self.transform.y + self.transform.height);
    }

    pub inline fn containsX(self: *Self, x: u16) bool {
        return (x >= self.transform.x) and (x <= self.transform.x + self.transform.width);
    }

    pub inline fn containsY(self: *Self, y: u16) bool {
        return (y >= self.transform.y) and (y <= self.transform.y + self.transform.height);
    }
};
