const Mat4 = @import("mat4.zig").Mat4;
const Vec3 = @import("vec3.zig").Vec3;
const math = @import("std").math;

pub inline fn perspective(fovy: f32, aspect: f32, near_value: f32, far_value: f32) Mat4 {
    const f1 = 1.0 / math.tan(fovy * 0.5);
    const f2 = 1.0 / (near_value - far_value);
    return .{
        .c0 = .{
            .x = f1 / aspect,
            .y = 0.0,
            .z = 0.0,
            .w = 0.0,
        },
        .c1 = .{
            .x = 0.0,
            .y = f1,
            .z = 0.0,
            .w = 0.0,
        },
        .c2 = .{
            .x = 0.0,
            .y = 0.0,
            .z = (near_value + far_value) * f2,
            .w = -1.0,
        },
        .c3 = .{
            .x = 0.0,
            .y = 0.0,
            .z = 2.0 * near_value * far_value * f2,
            .w = 0.0,
        },
    };
}

pub inline fn lookAt(eye: Vec3, center: Vec3, up: Vec3) Mat4 {
    const f = center.subtract(eye).normalize();
    const s = f.crossNormalize(up);
    const u = s.cross(f);

    return .{
        .c0 = .{
            .x = s.x,
            .y = u.x,
            .z = -f.x,
            .w = 0.0,
        },
        .c1 = .{
            .x = s.y,
            .y = u.y,
            .z = -f.y,
            .w = 0.0,
        },
        .c2 = .{
            .x = s.z,
            .y = u.z,
            .z = -f.z,
            .w = 0.0,
        },
        .c3 = .{
            .x = -s.dot(eye),
            .y = -u.dot(eye),
            .z = f.dot(eye),
            .w = 1.0,
        },
    };
}
