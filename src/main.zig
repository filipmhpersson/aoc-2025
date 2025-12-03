const std = @import("std");
const aoc_2025 = @import("aoc_2025");
const day1 = @import("day1.zig");
const day2 = @import("day2.zig");

test "include day1 tests" {
    _ = @import("day1.zig");
    _ = @import("day2.zig");
}
pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();

    try day1.parseAndStart(allocator);
    _ = arena.reset(.free_all);
    try day2.readDay2(allocator);

    try aoc_2025.bufferedPrint();
}

var buf: [1024 * 8]u8 = undefined;
