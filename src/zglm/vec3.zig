const math = @import("std").math;

pub const Vec3 = packed struct {
    const Self = @This();

    x: f32,
    y: f32,
    z: f32,

    pub const zero: Vec3 = .{
        .x = 0.0,
        .y = 0.0,
        .z = 0.0,
    };

    pub const one: Vec3 = .{
        .x = 1.0,
        .y = 1.0,
        .z = 1.0,
    };

    pub inline fn dot(self: *const Self, other: Vec3) f32 {
        return (self.x * other.x) + (self.y * other.y) + (self.z * other.z);
    }

    pub inline fn magnitude(self: *const Self) f32 {
        return self.dot(self.*);
    }

    pub inline fn euclideanMagnitude(self: *const Self) f32 {
        return math.sqrt(self.magnitude());
    }

    pub inline fn add(self: *const Self, other: Vec3) Vec3 {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
            .z = self.z + other.z,
        };
    }

    pub inline fn addScalar(self: *const Self, scalar: f32) Vec3 {
        return .{
            .x = self.x + scalar,
            .y = self.y + scalar,
            .z = self.z + scalar,
        };
    }

    pub inline fn subtract(self: *const Self, other: Vec3) Vec3 {
        return .{
            .x = self.x - other.x,
            .y = self.y - other.y,
            .z = self.z - other.z,
        };
    }

    pub inline fn subtractScalar(self: *const Self, scalar: f32) Vec3 {
        return .{
            .x = self.x - scalar,
            .y = self.y - scalar,
            .z = self.z - scalar,
        };
    }

    pub inline fn multiply(self: *const Self, other: Vec3) Vec3 {
        return .{
            .x = self.x * other.x,
            .y = self.y * other.y,
            .z = self.z * other.z,
        };
    }

    pub inline fn scale(self: *const Self, scalar: f32) Vec3 {
        return .{
            .x = self.x * scalar,
            .y = self.y * scalar,
            .z = self.z * scalar,
        };
    }

    pub inline fn divide(self: *const Self, other: Vec3) Vec3 {
        return .{
            .x = self.x / other.x,
            .y = self.y / other.y,
            .z = self.z / other.z,
        };
    }

    pub inline fn divideScalar(self: *const Self, scalar: f32) Vec3 {
        return .{
            .x = self.x / scalar,
            .y = self.y / scalar,
            .z = self.z / scalar,
        };
    }

    pub inline fn normalize(self: *const Self) Vec3 {
        var norm = self.euclideanMagnitude();

        if (norm == 0.0) {
            return zero;
        } else {
            return self.scale(1.0 / norm);
        }
    }

    pub inline fn cross(self: *const Self, other: Vec3) Vec3 {
        return .{
            .x = (self.y * other.z) - (self.z * other.y),
            .y = (self.z * other.x) - (self.x * other.z),
            .z = (self.x * other.y) - (self.y * other.x),
        };
    }

    pub inline fn crossNormalize(self: *const Self, other: Vec3) Vec3 {
        return self.cross(other).normalize();
    }

    pub inline fn angle(self: *const Self, other: Vec3) f32 {
        const norm: f32 = 1.0 / (self.euclideanMagnitude() * other.euclideanMagnitude());
        const dot_result: f32 = self.dot(other) * norm;

        if (dot_result > 1.0) {
            return 0.0;
        } else if (dot_result < -1.0) {
            return math.pi;
        } else {
            return math.acos(dot_result);
        }
    }

    pub inline fn rotate(self: *const Self, a: f32, axis: Vec3) Vec3 {
        const c: f32 = math.cos(a);
        var v1 = self.scale(c);
        const s: f32 = math.sin(a);
        const k = axis.normalize();
        var v2 = k.cross(self.*).scale(s);
        v1 = v1.add(v2);
        v2 = k.scale(k.dot(self.*) * (1.0 - c));
        return v1.add(v2);
    }
};
