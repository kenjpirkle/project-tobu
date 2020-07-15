const Vec3 = @import("vec3.zig").Vec3;
const Vec4 = @import("vec4.zig").Vec4;
const math = @import("std").math;

pub const Mat4 = packed struct {
    const Self = @This();

    c0: Vec4,
    c1: Vec4,
    c2: Vec4,
    c3: Vec4,

    pub const zero = Mat4{
        .c0 = .{ .x = 0.0, .y = 0.0, .z = 0.0, .w = 0.0 },
        .c1 = .{ .x = 0.0, .y = 0.0, .z = 0.0, .w = 0.0 },
        .c2 = .{ .x = 0.0, .y = 0.0, .z = 0.0, .w = 0.0 },
        .c3 = .{ .x = 0.0, .y = 0.0, .z = 0.0, .w = 0.0 },
    };

    pub const identity = Mat4{
        .c0 = .{ .x = 1.0, .y = 0.0, .z = 0.0, .w = 0.0 },
        .c1 = .{ .x = 0.0, .y = 1.0, .z = 0.0, .w = 0.0 },
        .c2 = .{ .x = 0.0, .y = 0.0, .z = 1.0, .w = 0.0 },
        .c3 = .{ .x = 0.0, .y = 0.0, .z = 0.0, .w = 1.0 },
    };

    pub inline fn translate(self: *const Self, v: Vec3) Mat4 {
        const v0: Vec4 = self.c0.scale(v.x);
        const v1: Vec4 = self.c1.scale(v.y);
        const v2: Vec4 = self.c2.scale(v.z);

        var m = self.*;
        m.c3 = v0.add(m.c3);
        m.c3 = v1.add(m.c3);
        m.c3 = v2.add(m.c3);
        return m;
    }
};
