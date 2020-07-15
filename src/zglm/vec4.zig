const Vec3 = @import("vec3.zig").Vec3;
const math = @import("std").math;

pub const Vec4 = packed struct {
    const Self = @This();

    x: f32,
    y: f32,
    z: f32,
    w: f32,

    pub const zero: Vec4 = .{
        .x = 0.0,
        .y = 0.0,
        .z = 0.0,
        .w = 0.0,
    };

    pub const one: Vec4 = .{
        .x = 1.0,
        .y = 1.0,
        .z = 1.0,
        .w = 1.0,
    };

    pub inline fn fromVec3(v3: Vec3, last: f32) Vec4 {
        return .{
            .x = v3.x,
            .y = v3.y,
            .z = v3.z,
            .w = last,
        };
    }

    pub inline fn dot(self: *const Self, other: Vec4) f32 {
        return (self.x * other.x) + (self.y * other.y) + (self.z * other.z) + (self.z * other.z);
    }

    pub inline fn magnitude(self: *const Self) f32 {
        return self.dot(self.*);
    }

    pub inline fn euclideanMagnitude(self: *const Self) f32 {
        return math.sqrt(self.magnitude());
    }

    pub inline fn add(self: *const Self, other: Vec4) Vec4 {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
            .z = self.z + other.z,
            .w = self.w + other.w,
        };
    }

    pub inline fn addScalar(self: *const Self, scalar: f32) Vec4 {
        return .{
            .x = self.x + scalar,
            .y = self.y + scalar,
            .z = self.z + scalar,
            .w = self.w + scalar,
        };
    }

    pub inline fn subtract(self: *const Self, other: Vec4) Vec4 {
        return .{
            .x = self.x - other.x,
            .y = self.y - other.y,
            .z = self.z - other.z,
            .w = self.w - other.w,
        };
    }

    pub inline fn subtractScalar(self: *const Self, scalar: f32) Vec4 {
        return .{
            .x = self.x - scalar,
            .y = self.y - scalar,
            .z = self.z - scalar,
            .w = self.w - scalar,
        };
    }

    pub inline fn multiply(self: *const Self, other: Vec4) Vec4 {
        return .{
            .x = self.x * other.x,
            .y = self.y * other.y,
            .z = self.z * other.z,
            .w = self.w * other.w,
        };
    }

    pub inline fn scale(self: *const Self, scalar: f32) Vec4 {
        return .{
            .x = self.x * scalar,
            .y = self.y * scalar,
            .z = self.z * scalar,
            .w = self.w * scalar,
        };
    }

    pub inline fn divide(self: *const Self, other: Vec4) Vec4 {
        return .{
            .x = self.x / other.x,
            .y = self.y / other.y,
            .z = self.z / other.z,
            .w = self.w / other.w,
        };
    }

    pub inline fn divideScalar(self: *const Self, scalar: f32) Vec4 {
        return .{
            .x = self.x / scalar,
            .y = self.y / scalar,
            .z = self.z / scalar,
            .w = self.w / scalar,
        };
    }

    pub inline fn normalize(self: *const Self) Vec4 {
        var norm = self.euclideanMagnitude();

        if (norm == 0.0) {
            return zero;
        } else {
            return self.scale(1.0 / norm);
        }
    }
};
