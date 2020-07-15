const std = @import("std");
const warn = std.debug.warn;
const allocator = std.heap.c_allocator;
usingnamespace @import("../c.zig");

const IdList = std.ArrayList(GLuint);

pub const ShaderSource = struct {
    shader_type: c_uint,
    source: []const u8,
};

pub const Shader = struct {
    program: GLuint,

    pub fn init(shaders: []const ShaderSource) !Shader {
        var ids = IdList.init(allocator);
        defer ids.deinit();

        const program = glCreateProgram();
        for (shaders) |shader| {
            const id = try ids.addOne();
            id.* = try loadShader(shader);
            glAttachShader(program, id.*);
        }

        glLinkProgram(program);
        try printProgramLog(program);

        for (ids.items) |id| {
            glDetachShader(program, id);
            glDeleteShader(id);
        }

        return Shader{ .program = program };
    }

    fn loadShader(shader_source: ShaderSource) !GLuint {
        const data = try std.fs.cwd().readFileAlloc(allocator, shader_source.source, 1024 * 1024 * 1024);

        const shader_id = glCreateShader(shader_source.shader_type);
        const c_data = @ptrCast([*c]const [*c]const u8, &data);
        const c_size = @ptrCast([*c]const c_int, &data.len);

        glShaderSource(shader_id, 1, c_data, c_size);
        glCompileShader(shader_id);

        try printShaderLog(shader_source.source, shader_id);
        return shader_id;
    }

    fn printShaderLog(path: []const u8, shader: GLuint) !void {
        var len: c_int = undefined;
        var chars_written: c_int = undefined;

        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &len);
        if (len > 0) {
            var error_log = try allocator.alloc(u8, @intCast(usize, len));
            defer allocator.free(error_log);
            glGetShaderInfoLog(shader, len, &chars_written, error_log.ptr);
            warn("shader compilation failed: {}\nshader info log: {}", .{ path, error_log });
            return error.ShaderCompilationFailed;
        }
    }

    fn printProgramLog(program: GLuint) !void {
        var len: c_int = undefined;
        var chars_written: c_int = undefined;

        glGetProgramiv(program, GL_INFO_LOG_LENGTH, &len);
        if (len > 0) {
            var error_log = try allocator.alloc(u8, @intCast(usize, len));
            defer allocator.free(error_log);
            glGetProgramInfoLog(program, len, &chars_written, error_log.ptr);
            warn("program info log: {}\n", .{error_log});
        }
    }

    pub fn getUniformLocation(self: *Shader, name: [*]const u8) !c_int {
        const id = glGetUniformLocation(self.program, name);
        if (id == -1)
            return error.GlUniformNotFound;
        return id;
    }
};
