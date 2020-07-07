usingnamespace @import("c.zig");

pub fn MapBuffer(comptime T: type, comptime size: usize) type {
    return struct {
        const Self = @This();
        const map_flags: GLbitfield = GL_MAP_READ_BIT | GL_MAP_WRITE_BIT | GL_MAP_PERSISTENT_BIT | GL_MAP_COHERENT_BIT;
        const create_flags: GLbitfield = map_flags | GL_DYNAMIC_STORAGE_BIT;

        data: []T,
        fence: GLsync,

        pub fn init(self: *Self, id: GLuint, target: GLenum) void {
            glBindBuffer(target, id);
            glNamedBufferStorage(id, @sizeOf(T) * size, null, create_flags);
            const ptr = glMapBufferRange(target, 0, @sizeOf(T) * size, map_flags);
            self.data.ptr = @ptrCast([*]T, @alignCast(@alignOf([*]T), ptr));
            self.data.len = 0;
            self.fence = glFenceSync(GL_SYNC_GPU_COMMANDS_COMPLETE, 0);
        }

        pub fn beginModify(self: *Self) void {
            glWaitSync(self.fence, 0, GL_TIMEOUT_IGNORED);
        }

        pub fn endModify(self: *Self) void {
            glDeleteSync(self.fence);
            self.fence = glFenceSync(GL_SYNC_GPU_COMMANDS_COMPLETE, 0);
        }

        pub fn append(self: *Self, values: []const T) void {
            const len = self.data.len;
            self.data.len += values.len;
            var i: usize = 0;
            for (values) |*value| {
                self.data[len + i] = values[i];
                i += 1;
            }
        }
    };
}
