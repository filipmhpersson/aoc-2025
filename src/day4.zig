const std = @import("std");

pub fn day4_readAndStart(allocator: std.mem.Allocator) !void {
    const file = try std.fs.cwd().readFile("input/day4", &buf);
    const result = try day4(file, allocator);
    const result_step2 = try day4_step2_init(file, allocator);
    std.debug.print("Day 4 res '{d}' step 2 '{d}'\n", .{ result, result_step2 });
}

fn day4(input: []const u8, allocator: std.mem.Allocator) !usize {
    var result: usize = 0;
    const rowLen = std.mem.indexOf(u8, input, "\n");
    var rowList: std.ArrayList([]const u8) = .empty;
    var split = std.mem.splitAny(u8, input, "\n");
    var count: usize = 0;
    while (split.next()) |s| {
        count += 1;
        if (s.len == 0) {
            continue;
        }
        try rowList.append(allocator, s);
    }
    const rows = try rowList.toOwnedSlice(allocator);

    defer allocator.free(rows);
    for (rows, 0..) |row, i| {
        for (row, 0..) |c, j| {
            if (c != '@') {
                continue;
            }

            if (getNeighouringAt(rows, i, j, rowLen.?) < 4) {
                result += 1;
            }
        }
    }
    return result;
}
fn day4_step2_init(input: []const u8, allocator: std.mem.Allocator) !usize {
    const rowLen = std.mem.indexOf(u8, input, "\n");
    var rowList: std.ArrayList([]u8) = .empty;
    var split = std.mem.splitAny(u8, input, "\n");
    var count: usize = 0;
    while (split.next()) |s| {
        count += 1;
        if (s.len == 0) {
            continue;
        }
        const row = try allocator.dupe(u8, s);
        try rowList.append(allocator, row);
    }
    var rows = try rowList.toOwnedSlice(allocator);
    defer allocator.free(rows);
    return try day4_step2(&rows, rowLen.?, allocator);
}

pub fn day4_step2(rows: *[][]u8, rowLen: usize, allocator: std.mem.Allocator) !usize {
    var result: usize = 0;

    var coords: std.ArrayList(coordinate) = .empty;
    defer coords.clearAndFree(allocator);
    for (rows.*, 0..) |row, i| {
        for (row, 0..) |c, j| {
            if (c != '@') {
                continue;
            }

            if (getNeighouringAtPtr(rows, i, j, rowLen) < 4) {
                try coords.append(allocator, coordinate{ .row = i, .column = j });
                result += 1;
            }
        }
    }
    if (result == 0) {
        for (rows.*) |row| {
            allocator.free(row);
        }
        return result;
    }
    for (coords.items) |item| {
        rows.*[item.row][item.column] = 'x';
    }
    return try day4_step2(rows, rowLen, allocator) + result;
}
const coordinate = struct { row: usize, column: usize };

fn getNeighouringAtPtr(rows_ptr: *[][]const u8, row: usize, column: usize, rowLength: usize) usize {
    const rows = rows_ptr.*;
    var rolls: usize = 0;
    if (row > 0) {
        //do top row
        if (column > 0) {
            if (rows[row - 1][column - 1] == '@') {
                rolls += 1;
            }
        }
        if (rows[row - 1][column] == '@') {
            rolls += 1;
        }
        if (column < rowLength - 1) {
            if (rows[row - 1][column + 1] == '@') {
                rolls += 1;
            }
        }
    }

    //do middlerow

    if (column > 0) {
        if (rows[row][column - 1] == '@') {
            rolls += 1;
        }
    }
    if (column < rowLength - 1) {
        if (rows[row][column + 1] == '@') {
            rolls += 1;
        }
    }

    if (row < rows.len - 1) {
        //do top row
        if (column > 0) {
            if (rows[row + 1][column - 1] == '@') {
                rolls += 1;
            }
        }
        if (rows[row + 1][column] == '@') {
            rolls += 1;
        }
        if (column < rowLength - 1) {
            if (rows[row + 1][column + 1] == '@') {
                rolls += 1;
            }
        }
    }
    return rolls;
}
fn getNeighouringAt(rows: [][]const u8, row: usize, column: usize, rowLength: usize) usize {
    var rolls: usize = 0;
    if (row > 0) {
        //do top row
        if (column > 0) {
            if (rows[row - 1][column - 1] == '@') {
                rolls += 1;
            }
        }
        if (rows[row - 1][column] == '@') {
            rolls += 1;
        }
        if (column < rowLength - 1) {
            if (rows[row - 1][column + 1] == '@') {
                rolls += 1;
            }
        }
    }

    //do middlerow

    if (column > 0) {
        if (rows[row][column - 1] == '@') {
            rolls += 1;
        }
    }
    if (column < rowLength - 1) {
        if (rows[row][column + 1] == '@') {
            rolls += 1;
        }
    }

    if (row < rows.len - 1) {
        //do top row
        if (column > 0) {
            if (rows[row + 1][column - 1] == '@') {
                rolls += 1;
            }
        }
        if (rows[row + 1][column] == '@') {
            rolls += 1;
        }
        if (column < rowLength - 1) {
            if (rows[row + 1][column + 1] == '@') {
                rolls += 1;
            }
        }
    }
    return rolls;
}

test "day4 sample" {
    const input =
        \\..@@.@@@@.
        \\@@@.@.@.@@
        \\@@@@@.@.@@
        \\@.@@@@..@.
        \\@@.@@@@.@@
        \\.@@@@@@@.@
        \\.@.@.@.@@@
        \\@.@@@.@@@@
        \\.@@@@@@@@.
        \\@.@.@@@.@.
    ;
    const allocator = std.testing.allocator;

    const result = try day4(input, allocator);
    try std.testing.expectEqual(13, result);
}

test "day4 step2 sample" {
    const input =
        \\..@@.@@@@.
        \\@@@.@.@.@@
        \\@@@@@.@.@@
        \\@.@@@@..@.
        \\@@.@@@@.@@
        \\.@@@@@@@.@
        \\.@.@.@.@@@
        \\@.@@@.@@@@
        \\.@@@@@@@@.
        \\@.@.@@@.@.
    ;
    const allocator = std.testing.allocator;

    const result = try day4_step2_init(input, allocator);
    try std.testing.expectEqual(43, result);
}
var buf: [1024 * 1024]u8 = undefined;
