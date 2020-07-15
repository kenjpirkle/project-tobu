const BlockType = @import("block_type.zig").BlockType;

pub const Chunk = packed struct {
    pub const hor_blocks = 16;
    pub const vert_blocks = 1024;

    blocks: [vert_blocks][hor_blocks][hor_blocks]BlockType,
    // TODO: RLE - see if run-length encoding is faster for storage and real-time
};
