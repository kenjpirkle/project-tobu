const std = @import("std");
const Game = @import("game.zig").Game;

pub fn main() anyerror!void {
    var game: Game = undefined;
    try game.init();
    defer game.deinit();
    game.start();
}
