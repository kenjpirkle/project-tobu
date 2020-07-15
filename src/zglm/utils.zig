const math = @import("std").math;

pub fn toRadians(degree: f32) f32 {
    return degree * math.pi / 180.0;
}
