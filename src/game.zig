const std = @import("std");
const builtin = std.builtin;
const warn = std.debug.warn;
const allocator = std.heap.c_allocator;
const Timer = std.time.Timer;
const Camera = @import("camera.zig").Camera;
const ShaderSource = @import("shaders/shader.zig").ShaderSource;
const Shader = @import("shaders/shader.zig").Shader;
const OpaqueBlockShader = @import("shaders/opaque_block_shader.zig").OpaqueBlockShader;
const zglm = @import("zglm/zglm.zig");
const math = std.math;
const DrawArraysIndirectCommand = @import("gl/draw_arrays_indirect_command.zig").DrawArraysIndirectCommand;
usingnamespace @import("c.zig");
const perlin = @import("perlin_noise.zig");

pub fn checkOpenGLError() bool {
    var found_error = false;
    var gl_error = glGetError();
    while (gl_error != GL_NO_ERROR) : (gl_error = glGetError()) {
        warn("glError: {}\n", .{gl_error});
        found_error = true;
    }

    return found_error;
}

pub const KeyboardState = struct {
    key: c_int,
    scan_code: c_int,
    action: c_int,
    modifiers: c_int,
};

pub const Game = struct {
    const Self = @This();
    const vertices = [_]f32{
        // front face
        -0.5, -0.5, 0.5,
        0.5,  -0.5, 0.5,
        -0.5, 0.5,  0.5,
        0.5,  0.5,  0.5,

        // back face
        0.5,  -0.5, -0.5,
        -0.5, -0.5, -0.5,
        0.5,  0.5,  -0.5,
        -0.5, 0.5,  -0.5,

        // left face
        -0.5, -0.5, -0.5,
        -0.5, -0.5, 0.5,
        -0.5, 0.5,  -0.5,
        -0.5, 0.5,  0.5,

        // right face
        0.5,  -0.5, 0.5,
        0.5,  -0.5, -0.5,
        0.5,  0.5,  0.5,
        0.5,  0.5,  -0.5,

        // top face
        -0.5, 0.5,  0.5,
        0.5,  0.5,  0.5,
        -0.5, 0.5,  -0.5,
        0.5,  0.5,  -0.5,

        // bottom face
        -0.5, -0.5, -0.5,
        0.5,  -0.5, -0.5,
        -0.5, -0.5, 0.5,
        0.5,  -0.5, 0.5,
    };

    const cube_positions = [_]zglm.Vec3{
        .{ .x = 0.0, .y = 0.0, .z = 0.0 },
        .{ .x = 1.0, .y = 0.0, .z = 0.0 },
        .{ .x = 2.0, .y = 0.0, .z = 0.0 },
        .{ .x = 3.0, .y = 0.0, .z = 0.0 },
        .{ .x = 4.0, .y = 0.0, .z = 0.0 },
        .{ .x = 5.0, .y = 0.0, .z = 0.0 },
        .{ .x = 6.0, .y = 0.0, .z = 0.0 },
        .{ .x = 7.0, .y = 0.0, .z = 0.0 },
        .{ .x = 8.0, .y = 0.0, .z = 0.0 },
        .{ .x = 9.0, .y = 0.0, .z = 0.0 },
        .{ .x = 10.0, .y = 0.0, .z = 0.0 },
        .{ .x = 2.0, .y = 5.0, .z = -15.0 },
        .{ .x = -1.5, .y = -2.2, .z = -2.5 },
        .{ .x = -3.8, .y = -2.0, .z = -12.3 },
        .{ .x = 2.4, .y = -0.4, .z = -3.5 },
        .{ .x = -1.7, .y = 3.0, .z = -7.5 },
        .{ .x = 1.3, .y = -2.0, .z = -2.5 },
        .{ .x = 1.5, .y = 2.0, .z = -2.5 },
        .{ .x = 1.5, .y = 0.2, .z = -1.5 },
        .{ .x = -1.3, .y = 1.0, .z = -1.5 },
    };

    window: *GLFWwindow = undefined,
    keyboard_state: KeyboardState = undefined,
    width: u16 = undefined,
    height: u16 = undefined,
    video_mode: *const GLFWvidmode = undefined,
    // opaque_block_shader: OpaqueBlockShader = undefined,
    timer: Timer = undefined,
    before_frame: u64 = 0,
    time_delta: u64 = 0,
    delta_time: f64 = 0.0,
    last_frame: f64 = 0.0,

    // camera: Camera = undefined,

    shader: Shader = undefined,
    vao: GLuint = undefined,
    vbo: GLuint = undefined,
    projection_location: GLint = undefined,
    view_location: GLint = undefined,
    model_location: GLint = undefined,

    camera_pos: zglm.Vec3 = undefined,
    camera_front: zglm.Vec3 = undefined,
    camera_up: zglm.Vec3 = undefined,

    pub fn init(self: *Self) !void {
        try perlin.generateNoise();

        if (glfwInit() == 0) {
            warn("could not initialize glfw\n", .{});
            return error.GLFWInitFailed;
        }

        setWindowHints();

        self.video_mode = glfwGetVideoMode(glfwGetPrimaryMonitor());
        const half_width = @divTrunc(self.video_mode.*.width, 2);
        const half_height = @divTrunc(self.video_mode.*.height, 2);
        self.width = @intCast(u16, half_width);
        self.height = @intCast(u16, half_height);
        self.window = glfwCreateWindow(self.width, self.height, "project-tobu", null, null) orelse return error.GlfwCreateWindowFailed;
        glfwSetWindowPos(self.window, half_width - @divTrunc(half_width, 2), half_height - @divTrunc(half_height, 2));

        glfwMakeContextCurrent(self.window);
        try self.setGlfwState();

        if (builtin.mode == .Debug) {
            glEnable(GL_DEBUG_OUTPUT);
            glDebugMessageCallback(debugMessageCallback, null);
        }

        // try self.opaque_block_shader.init();
        setGlState(self.width, self.height);

        const shaders = [_]ShaderSource{
            .{
                .shader_type = GL_VERTEX_SHADER,
                .source = "shaders/block_vertex.glsl",
            },
            .{
                .shader_type = GL_FRAGMENT_SHADER,
                .source = "shaders/block_fragment.glsl",
            },
        };
        self.shader = try Shader.init(shaders[0..]);

        glGenVertexArrays(1, &self.vao);
        glGenBuffers(1, &self.vbo);
        glBindVertexArray(self.vao);
        glBindBuffer(GL_ARRAY_BUFFER, self.vbo);
        glBufferData(GL_ARRAY_BUFFER, @sizeOf(f32) * vertices.len, &vertices[0], GL_STATIC_DRAW);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, @sizeOf(f32) * 3, @intToPtr(?*const c_void, 0));
        glEnableVertexAttribArray(0);
        glUseProgram(self.shader.program);
        self.projection_location = try self.shader.getUniformLocation("projection");
        self.view_location = try self.shader.getUniformLocation("view");
        self.model_location = try self.shader.getUniformLocation("model");

        const w: f32 = @intToFloat(f32, self.width);
        const h: f32 = @intToFloat(f32, self.height);
        const projection_matrix: zglm.Mat4 = zglm.perspective(zglm.toRadians(45.0), w / h, 0.1, 100.0);

        glProgramUniformMatrix4fv(self.shader.program, self.projection_location, 1, GL_FALSE, @ptrCast([*c]const f32, @alignCast(4, &projection_matrix.c0)));

        self.camera_pos = .{
            .x = 0.0,
            .y = 0.0,
            .z = 3.0,
        };
        self.camera_front = .{
            .x = 0.0,
            .y = 0.0,
            .z = -1.0,
        };
        self.camera_up = .{
            .x = 0.0,
            .y = 1.0,
            .z = 0.0,
        };

        // self.camera = .{
        //     .position = .{
        //         .x = 0.0,
        //         .y = 0.0,
        //         .z = 3.0,
        //     },
        //     .target = .{
        //         .x = 0.0,
        //         .y = 0.0,
        //         .z = 0.0,
        //     },
        //     .direction = .{
        //         .x = 0.0,
        //         .y = 0.0,
        //         .z = 0.0,
        //     },
        //     .projection = zglm.perspective(zglm.toRadians(45.0), w / h, -0.1, -100.0),
        // };

        // self.opaque_block_shader.setProjection(self.camera.projection);

        // self.timer = try Timer.start();
    }

    pub fn deinit(self: *Self) void {
        glfwDestroyWindow(self.window);
        glfwTerminate();
    }

    pub fn start(self: *Self) void {
        while (glfwWindowShouldClose(self.window) == 0) {
            const current_frame: f64 = glfwGetTime();
            self.delta_time = current_frame - self.last_frame;
            self.last_frame = current_frame;

            self.processInput();

            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            glUseProgram(self.shader.program);

            // self.before_frame = self.timer.read();

            const view = zglm.lookAt(
                self.camera_pos,
                self.camera_pos.add(self.camera_front),
                self.camera_up,
            );
            glProgramUniformMatrix4fv(self.shader.program, self.view_location, 1, GL_FALSE, @ptrCast([*c]const f32, @alignCast(4, &view.c0)));

            glBindVertexArray(self.vao);
            var i: usize = 0;
            while (i < cube_positions.len) : (i += 1) {
                const model = zglm.Mat4.identity.translate(cube_positions[i]);
                glProgramUniformMatrix4fv(self.shader.program, self.model_location, 1, GL_FALSE, @ptrCast([*c]const f32, @alignCast(4, &model.c0)));

                glDrawArrays(GL_TRIANGLE_STRIP, 0, 24);
            }

            // self.time_delta = self.timer.lap() - self.before_frame;
            glfwSwapBuffers(self.window);
            glfwPollEvents();
        }
    }

    pub fn display(self: *Self) void {
        // FIXED GL_INVALID_OPERATION error generated. Bound draw indirect buffer is not large enough. BECAUSE THE SECOND ARGUMENT IN glMultiDrawArraysIndirect SHOULD BE 0 (null) AND NOT!!! THE ADDRESS OF THE MAPPED BUFFER
        glMultiDrawArraysIndirect(GL_TRIANGLE_STRIP, @intToPtr(?*const c_void, 0), 1, 0);
        glfwSwapBuffers(self.window);
    }

    inline fn setWindowHints() void {
        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 6);
        glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
        glfwWindowHint(GLFW_SAMPLES, 8);
    }

    inline fn setGlState(window_width: c_int, window_height: c_int) void {
        if (builtin.mode == .Debug) {
            const version: [*:0]const u8 = glGetString(GL_VERSION);
            warn("OpenGL version: {}\n", .{version});
        }

        glViewport(0, 0, window_width, window_height);
        glEnable(GL_CULL_FACE);
        glCullFace(GL_BACK);
        glEnable(GL_DEPTH_TEST);
        glClearColor(0.25, 0.23, 0.25, 1.0);
    }

    inline fn setGlfwState(self: *Self) !void {
        glfwSwapInterval(1);
        glfwSetWindowSizeLimits(self.window, 500, 200, GLFW_DONT_CARE, GLFW_DONT_CARE);
        glfwSetWindowUserPointer(self.window, @ptrCast(*c_void, self));
        _ = glfwSetWindowSizeCallback(self.window, onWindowSizeChanged);
        _ = glfwSetMouseButtonCallback(self.window, onMouseButtonEvent);
        _ = glfwSetCursorPosCallback(self.window, onCursorPositionChanged);
        glfwSetInputMode(self.window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);

        if (gladLoadGLLoader(@ptrCast(GLADloadproc, glfwGetProcAddress)) == 0) {
            warn("could not initialize glad\n", .{});
            return error.GladLoadProcsFailed;
        }

        if (builtin.mode == .Debug) {
            if (glfwExtensionSupported("GL_ARB_bindless_texture") == GLFW_TRUE) {
                warn("GL_ARB_bindless_texture is supported!\n", .{});
            }
        }
    }

    fn processInput(self: *Self) void {
        if (glfwGetKey(self.window, GLFW_KEY_ESCAPE) == GLFW_PRESS) {
            glfwSetWindowShouldClose(self.window, GLFW_TRUE);
        }

        const camera_speed: f32 = 5 * @floatCast(f32, self.delta_time);
        if (glfwGetKey(self.window, GLFW_KEY_W) == GLFW_PRESS) {
            self.camera_pos = self.camera_pos.add(self.camera_front.scale(camera_speed));
        }
        if (glfwGetKey(self.window, GLFW_KEY_S) == GLFW_PRESS) {
            self.camera_pos = self.camera_pos.subtract(self.camera_front.scale(camera_speed));
        }
        if (glfwGetKey(self.window, GLFW_KEY_A) == GLFW_PRESS) {
            self.camera_pos = self.camera_pos.subtract(self.camera_front.crossNormalize(self.camera_up).scale(camera_speed));
        }
        if (glfwGetKey(self.window, GLFW_KEY_D) == GLFW_PRESS) {
            self.camera_pos = self.camera_pos.add(self.camera_front.crossNormalize(self.camera_up).scale(camera_speed));
        }
    }

    fn debugMessageCallback(source: GLenum, error_type: GLenum, id: GLuint, severity: GLenum, length: GLsizei, message: [*c]const u8, user_param: ?*const GLvoid) callconv(.C) void {
        warn("ERROR: {s}\n", .{message});
    }

    fn onWindowSizeChanged(win: ?*GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
        const ui = @ptrCast(*Self, @alignCast(@alignOf(Self), glfwGetWindowUserPointer(win)));
        ui.width = @intCast(u16, width);
        ui.height = @intCast(u16, height);
        glViewport(0, 0, width, height);
        ui.display();
    }

    fn onCursorPositionChanged(win: ?*GLFWwindow, x_pos: f64, y_pos: f64) callconv(.C) void {
        const ui = @ptrCast(*Self, @alignCast(@alignOf(Self), glfwGetWindowUserPointer(win)));
    }

    fn onMouseButtonEvent(win: ?*GLFWwindow, button: c_int, action: c_int, modifiers: c_int) callconv(.C) void {
        const ui = @ptrCast(*Self, @alignCast(@alignOf(Self), glfwGetWindowUserPointer(win)));
        if (button == GLFW_MOUSE_BUTTON_LEFT and action == GLFW_PRESS) {}
    }
};
