pub usingnamespace @cImport({
    @cDefine("_NO_CRT_STDIO_INLINE", "1");
    @cInclude("stdio.h");
    @cInclude("freetype.h");
    @cInclude("glad.h");
    @cInclude("glfw3.h");
});
