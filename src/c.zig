pub usingnamespace @cImport({
    @cDefine("_NO_CRT_STDIO_INLINE", "1");
    @cInclude("stdio.h");
    @cInclude("glad.h");
    @cInclude("glfw3.h");
    @cInclude("freetype.h");
    @cInclude("sqlite3.h");
});
