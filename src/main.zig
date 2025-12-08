const std = @import("std");
const aoc_2025 = @import("aoc_2025");
const day1 = @import("day1.zig");
const day2 = @import("day2.zig");
const day3 = @import("day3.zig");
const day4 = @import("day4.zig");
const day5 = @import("day5.zig");
const day6 = @import("day6.zig");
const day7 = @import("day7.zig");
const day8 = @import("day8.zig");

test "include day1 tests" {
    _ = @import("day1.zig");
    _ = @import("day2.zig");
    _ = @import("day3.zig");
    _ = @import("day4.zig");
    _ = @import("day5.zig");
    _ = @import("day6.zig");
    _ = @import("day7.zig");
    _ = @import("day8.zig");
}
pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();

    try day1.parseAndStart(allocator);
    _ = arena.reset(.free_all);
    try day2.readDay2(allocator);
    _ = arena.reset(.free_all);
    try day3.day3_readAndStart(allocator);
    _ = arena.reset(.free_all);
    try day4.day4_readAndStart(allocator);
    _ = arena.reset(.free_all);
    try day5.day5_readAndStart(allocator);
    _ = arena.reset(.free_all);
    try day6.day6_readAndStart(allocator);
    _ = arena.reset(.free_all);
    try day7.day7_readAndStart(allocator);
    _ = arena.reset(.free_all);
    try day8.day8_readAndStart(allocator);
    _ = arena.reset(.free_all);

    try aoc_2025.bufferedPrint();
}
