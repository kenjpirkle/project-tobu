const std = @import("std");
const builtin = std.builtin;
const warn = std.debug.warn;
const allocator = std.heap.c_allocator;
const Timer = std.time.Timer;
const Camera = @import("camera.zig").Camera;
const ShaderSource = @import("shaders/shader.zig").ShaderSource;
const Shader = @import("shaders/shader.zig").Shader;
const OpaqueBlockShader = @import("shaders/opaque_block_shader.zig").OpaqueBlockShader;
const DefaultShader = @import("shaders/default_shader.zig").DefaultShader;
const zglm = @import("zglm/zglm.zig");
const math = std.math;
const DrawArraysIndirectCommand = @import("gl/draw_arrays_indirect_command.zig").DrawArraysIndirectCommand;
const DrawElementsIndirectCommand = @import("gl/draw_elements_indirect_command.zig").DrawElementsIndirectCommand;
const perlin = @import("perlin_noise.zig");
const constants = @import("game_constants.zig");
const World = @import("world.zig").World;
usingnamespace @import("c.zig");

pub fn checkOpenGLError() void {
    var gl_error = glGetError();
    while (gl_error != GL_NO_ERROR) : (gl_error = glGetError()) {
        warn("glError: {}\n", .{gl_error});
    }
}

pub const KeyboardState = struct {
    key: c_int,
    scan_code: c_int,
    action: c_int,
    modifiers: c_int,
};

pub const Game = struct {
    const Self = @This();

    // const lod5_vertices = (constants.lod5_scale - 1) * (constants.lod5_scale - 1) * 6;

    window: *GLFWwindow = undefined,
    keyboard_state: KeyboardState = undefined,
    width: u16 = undefined,
    height: u16 = undefined,
    video_mode: *const GLFWvidmode = undefined,
    default_shader: DefaultShader = undefined,
    timer: Timer = undefined,
    before_frame: u64 = 0,
    time_delta: u64 = 0,
    delta_time: f64 = 0.0,
    last_frame: f64 = 0.0,
    world: World = undefined,

    // camera: Camera = undefined,

    camera_pos: zglm.Vec3 = undefined,
    camera_front: zglm.Vec3 = undefined,
    camera_up: zglm.Vec3 = undefined,

    first_mouse: bool = undefined,
    yaw: f32 = undefined,
    pitch: f32 = undefined,
    last_x: f32 = undefined,
    last_y: f32 = undefined,
    fov: f32 = undefined,

    pub fn init(self: *Self) !void {
        // var values = try perlin.generateHeightMap(constants.lod5_scale, constants.world_scale, allocator);
        // var vertices = try allocator.alloc(f32, lod5_vertices);
        // defer allocator.free(vertices);
        // var vertex: usize = 0;
        // var i: usize = 0;
        // while (i < constants.lod5_scale - 1) : (i += 1) {
        //     var j: usize = 0;
        //     while (j < constants.lod5_scale - 1) : (j += 1) {
        //         const index: usize = ((constants.lod5_scale - 1 - i) * constants.lod5_scale) + j;
        //         const above_index: usize = ((constants.lod5_scale - 2 - i) * constants.lod5_scale) + j;
        //         vertices[vertex] = values[index] * constants.height_scale;
        //         vertices[vertex + 1] = values[index + 1] * constants.height_scale;
        //         vertices[vertex + 2] = values[above_index] * constants.height_scale;
        //         vertices[vertex + 3] = values[index + 1] * constants.height_scale;
        //         vertices[vertex + 4] = values[above_index + 1] * constants.height_scale;
        //         vertices[vertex + 5] = values[above_index] * constants.height_scale;

        //         vertex += 6;
        //     }
        // }
        // try perlin.heightMapToFile(values[0..], "perlin_map.bmp");
        // allocator.free(values);

        // const vertices = blk: {
        //     var vs = try allocator.alloc(GLuint, lod5_vertices);
        //     var i: u32 = 0;
        //     var row: u32 = 0;
        //     var quad: u32 = 0;
        //     while (i < lod5_vertices) : (i += 6) {
        //         const index: GLuint = (constants.lod5_scale - 1 - row) * (constants.lod5_scale) + quad;
        //         const above_index: GLuint = (constants.lod5_scale - 2 - row) * (constants.lod5_scale) + quad;

        //         // 1st triangle
        //         vis[i] = index;
        //         vis[i + 1] = index + 1;
        //         vis[i + 2] = above_index;
        //         // 2nd triangle
        //         vis[i + 3] = index + 1;
        //         vis[i + 4] = above_index + 1;
        //         vis[i + 5] = above_index;

        //         quad += 1;
        //         if (quad == constants.lod5_scale - 1) {
        //             quad = 0;
        //             row += 1;
        //         }
        //     }
        //     break :blk vis;
        // };
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

        setGlState(self.width, self.height);
        try self.default_shader.init();

        const w: f32 = @intToFloat(f32, self.width);
        const h: f32 = @intToFloat(f32, self.height);
        const projection_matrix: zglm.Mat4 = zglm.perspective(zglm.toRadians(70.0), w / h, 0.001, 10000.0);
        self.default_shader.setProjection(projection_matrix);

        self.world = try World.generate();

        self.default_shader.vertex_buffer.beginModify();
        for (self.world.lods) |lod| {
            for (lod) |chunk| {
                for (chunk) |row| {
                    for (row) |quad| {
                        self.default_shader.vertex_buffer.append(&quad);
                    }
                }
            }
        }
        self.default_shader.vertex_buffer.endModify();
        self.default_shader.draw_command_buffer.beginModify();
        var i: usize = 0;
        while (i < 84) : (i += 1) {
            self.default_shader.draw_command_buffer.append(&[_]DrawArraysIndirectCommand{
                .{
                    .vertex_count = 384,
                    .instance_count = 1,
                    .base_vertex = @intCast(GLuint, i * 384),
                    .base_instance = @intCast(GLuint, i),
                },
            });
        }
        self.default_shader.draw_command_buffer.endModify();

        self.first_mouse = true;
        self.yaw = -90.0;
        self.pitch = 0.0;
        self.last_x = @intToFloat(f32, self.width) * 2.0;
        self.last_y = @intToFloat(f32, self.height) * 2.0;
        self.fov = 60.0;

        self.camera_pos = .{
            .x = 0.0,
            .y = 185.0,
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

            const view = zglm.lookAt(
                self.camera_pos,
                self.camera_pos.add(self.camera_front),
                self.camera_up,
            );
            self.default_shader.setView(view);

            glMultiDrawArraysIndirect(GL_TRIANGLES, @intToPtr(?*const c_void, 0), @intCast(GLint, self.default_shader.draw_command_buffer.data.len), 0);

            // self.time_delta = self.timer.lap() - self.before_frame;
            glfwSwapBuffers(self.window);
            glfwPollEvents();
        }
    }

    pub fn display(self: *Self) void {
        // FIXED GL_INVALID_OPERATION error generated. Bound draw indirect buffer is not large enough. BECAUSE THE SECOND ARGUMENT IN glMultiDrawArraysIndirect SHOULD BE 0 (null) AND !NOT! THE ADDRESS OF THE MAPPED BUFFER
        glMultiDrawArraysIndirect(GL_TRIANGLE_STRIP, @intToPtr(?*const c_void, 0), 1, 0);
        glfwSwapBuffers(self.window);
    }

    inline fn setWindowHints() void {
        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 6);
        glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
        glfwWindowHint(GLFW_SAMPLES, 4);
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
        // glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
        // glEnable(GL_POLYGON_SMOOTH);
        glClearColor(40.0 / 255.0, 175.0 / 255.0, 234.0 / 255.0, 1.0);
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

        const camera_speed: f32 = if (glfwGetKey(self.window, GLFW_KEY_SPACE) == GLFW_PRESS) 300 * @floatCast(f32, self.delta_time) else 10 * @floatCast(f32, self.delta_time);
        const old_y = self.camera_pos.y;
        if (glfwGetKey(self.window, GLFW_KEY_W) == GLFW_PRESS) {
            self.camera_pos = self.camera_pos.add(self.camera_front.scale(camera_speed));
            self.camera_pos.y = old_y;
        }
        if (glfwGetKey(self.window, GLFW_KEY_S) == GLFW_PRESS) {
            self.camera_pos = self.camera_pos.subtract(self.camera_front.scale(camera_speed));
            self.camera_pos.y = old_y;
        }
        if (glfwGetKey(self.window, GLFW_KEY_A) == GLFW_PRESS) {
            self.camera_pos = self.camera_pos.subtract(self.camera_front.crossNormalize(self.camera_up).scale(camera_speed));
        }
        if (glfwGetKey(self.window, GLFW_KEY_D) == GLFW_PRESS) {
            self.camera_pos = self.camera_pos.add(self.camera_front.crossNormalize(self.camera_up).scale(camera_speed));
        }
        if (glfwGetKey(self.window, GLFW_KEY_E) == GLFW_PRESS) {
            self.camera_pos.y += 1.0 * camera_speed;
        }
        if (glfwGetKey(self.window, GLFW_KEY_Q) == GLFW_PRESS) {
            self.camera_pos.y -= 1.0 * camera_speed;
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

        const x = @floatCast(f32, x_pos);
        const y = @floatCast(f32, y_pos);

        if (ui.first_mouse) {
            ui.last_x = x;
            ui.last_y = y;
            ui.first_mouse = false;
        }

        var x_offset: f32 = x - ui.last_x;
        var y_offset: f32 = ui.last_y - y;
        ui.last_x = x;
        ui.last_y = y;

        const sensitivity: f32 = 0.1;
        x_offset *= sensitivity;
        y_offset *= sensitivity;

        ui.yaw += x_offset;
        ui.pitch += y_offset;

        if (ui.pitch > 89.0) {
            ui.pitch = 89.0;
        }
        if (ui.pitch < -89.0) {
            ui.pitch = -89.0;
        }

        const front: zglm.Vec3 = .{
            .x = math.cos(zglm.toRadians(ui.yaw)) * math.cos(zglm.toRadians(ui.pitch)),
            .y = math.sin(zglm.toRadians(ui.pitch)),
            .z = math.sin(zglm.toRadians(ui.yaw)) * math.cos(zglm.toRadians(ui.pitch)),
        };
        ui.camera_front = front.normalize();
    }

    fn onMouseButtonEvent(win: ?*GLFWwindow, button: c_int, action: c_int, modifiers: c_int) callconv(.C) void {
        const ui = @ptrCast(*Self, @alignCast(@alignOf(Self), glfwGetWindowUserPointer(win)));
        if (button == GLFW_MOUSE_BUTTON_LEFT and action == GLFW_PRESS) {}
    }
};
