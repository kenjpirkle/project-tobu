usingnamespace @import("zglm/zglm.zig");

pub const Camera = struct {
    position: Vec3,
    target: Vec3,
    direction: Vec3,
    projection: Mat4,
};
