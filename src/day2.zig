const std = @import("std");
var buf: [1024 * 8]u8 = undefined;

pub fn readDay2(allocator: std.mem.Allocator) !void {
    const inputFile = try std.fs.cwd().openFile("input/day2", .{ .mode = .read_only });
    const input = try inputFile.readToEndAlloc(allocator, 1024 * 1024);
    const result = try parseAndStart(input[0 .. input.len - 1]);
    const result2 = try parseAndStartDay2(input[0 .. input.len - 1], allocator);
    std.debug.print("DAY 2 '{d}' STEP 2 '{d}'\n", .{ result, result2 });
}
fn parseAndStart(input: []const u8) !u64 {
    var ranges = std.mem.splitAny(u8, input, ",");
    var invalidIds: u64 = 0;

    while (ranges.next()) |range| {
        var ids = std.mem.splitAny(u8, range, "-");
        const start = ids.next().?;
        const end = ids.next().?;

        const startInt = try std.fmt.parseInt(u64, start, 10);
        const endInt = try std.fmt.parseInt(u64, end, 10);
        for (startInt..endInt + 1) |i| {
            const str = try std.fmt.bufPrint(buf[0..], "{d}", .{i});
            if (str.len % 2 == 0) {
                const lStr = str[0..(str.len / 2)];
                const rStr = str[(str.len / 2)..];
                if (std.mem.eql(u8, lStr, rStr)) {
                    invalidIds += i;
                }
            }
        }
    }
    return invalidIds;
}
fn parseAndStartDay2(input: []const u8, allocator: std.mem.Allocator) !u64 {
    var ranges = std.mem.splitAny(u8, input, ",");
    var invalidIds: u64 = 0;

    while (ranges.next()) |range| {
        var ids = std.mem.splitAny(u8, range, "-");
        const start = ids.next().?;
        const end = ids.next().?;

        const startInt = try std.fmt.parseInt(u64, start, 10);
        const endInt = try std.fmt.parseInt(u64, end, 10);
        for (startInt..endInt + 1) |i| {
            const str = try std.fmt.bufPrint(buf[0..], "{d}", .{i});
            if (try isRepeating(str, allocator)) {
                invalidIds += i;
            }
        }
    }
    return invalidIds;
}

fn isRepeating(input: []const u8, allocator: std.mem.Allocator) !bool {
    if (input.len == 1) {
        return false;
    }
    var validFactors: std.ArrayList(u64) = .empty;
    defer validFactors.deinit(allocator);
    try validFactors.append(allocator, 1);
    const floor = @divFloor(input.len, 2);
    for (0..floor + 1) |i| {
        if (i == 0 or i == 1) continue;
        if (input.len % (i) == 0) {
            try validFactors.append(allocator, i);
        }
    }
    for (validFactors.items) |factor| {
        var taken: u64 = 0;
        var prev = input[taken..factor];
        taken = factor;
        while (true) {
            const current = input[taken .. factor + taken];
            if (!std.mem.eql(u8, current, prev)) {
                break;
            }
            prev = current;

            taken += factor;
            if (taken >= input.len) {
                return true;
            }
        }
    }
    return false;
}

test "repeating magic" {
    const allocator = std.testing.allocator;
    try std.testing.expectEqual(true, try isRepeating("1188511885", allocator));
    try std.testing.expectEqual(true, try isRepeating("2121212121", allocator));
    try std.testing.expectEqual(true, try isRepeating("11", allocator));
    try std.testing.expectEqual(false, try isRepeating("12", allocator));
}

test "sample day 2" {
    const input = "11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124";

    const res = parseAndStart(input);
    try std.testing.expectEqual(1227775554, res);
}
