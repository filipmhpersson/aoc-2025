const std = @import("std");

pub fn day7_readAndStart(allocator: std.mem.Allocator) !void {
    const input = try std.fs.cwd().readFileAlloc(allocator, "input/day7", 1024 * 1024);
    const result = try day7(input, allocator);
    const result_step2 = try day7_step2(input, allocator);
    std.debug.print("Day 7 result '{d}' step 2 '{d}'\n", .{ result, result_step2 });
}

fn day7(input: []const u8, allocator: std.mem.Allocator) !usize {
    var split = std.mem.splitAny(u8, input, "\n");
    var rows: std.ArrayList([]u8) = .empty;
    while (split.next()) |s| {
        if (s.len == 0) {
            break;
        }

        const row = try allocator.dupe(u8, s);
        try rows.append(allocator, row);
    }
    const data = try rows.toOwnedSlice(allocator);

    const start = std.mem.indexOf(u8, data[0], "S");
    const result = beamDown(data, start.?, 1);
    for (data) |r| {
        defer allocator.free(r);
    }
    defer allocator.free(data);
    return result;
}

fn day7_step2(input: []const u8, allocator: std.mem.Allocator) !usize {
    var split = std.mem.splitAny(u8, input, "\n");
    var rows: std.ArrayList([]u8) = .empty;
    while (split.next()) |s| {
        if (s.len == 0) {
            break;
        }

        const row = try allocator.dupe(u8, s);
        try rows.append(allocator, row);
    }
    const data = try rows.toOwnedSlice(allocator);

    const start = std.mem.indexOf(u8, data[0], "S");
    const result = try countTimeLines(data, start.?, 1, allocator);
    for (data) |r| {
        defer allocator.free(r);
    }
    defer allocator.free(data);
    return result;
}

fn beamDown(input: [][]u8, beamIndex: usize, currentRow: usize) usize {
    if (currentRow >= input.len) {
        return 0;
    }
    const c = input[currentRow][beamIndex];
    if (c == '|') {
        return 0;
    }

    if (c == '^') {
        var result: usize = 0;
        const left = input[currentRow][beamIndex - 1];
        if (left != '|') {
            input[currentRow][beamIndex - 1] = '|';
            result += beamDown(input, beamIndex - 1, currentRow + 1);
        }
        const right = input[currentRow][beamIndex + 1];

        if (right != '|') {
            input[currentRow][beamIndex + 1] = '|';
            result += beamDown(input, beamIndex + 1, currentRow + 1);
        }
        result += 1;
        return result;
    } else {
        input[currentRow][beamIndex] = '|';
        return beamDown(input, beamIndex, currentRow + 1);
    }
}

//Recursive fail step 2
fn beamDownTimeline(input: [][]u8, beamIndex: usize, currentRow: usize) usize {
    if (currentRow >= input.len) {
        return 1;
    }
    const c = input[currentRow][beamIndex];

    if (c == '^') {
        var result: usize = 0;
        input[currentRow][beamIndex - 1] = '|';
        result += beamDownTimeline(input, beamIndex - 1, currentRow + 1);

        input[currentRow][beamIndex + 1] = '|';
        result += beamDownTimeline(input, beamIndex + 1, currentRow + 1);
        return result;
    } else {
        input[currentRow][beamIndex] = '|';
        return beamDownTimeline(input, beamIndex, currentRow + 1);
    }
}

//Solution step 2
fn countTimeLines(input: [][]u8, beamIndex: usize, currentRow: usize, allocator: std.mem.Allocator) !usize {
    var beamIndices = try allocator.alloc(usize, input[1].len);
    defer allocator.free(beamIndices);
    for (beamIndices) |*v| {
        v.* = 0;
    }
    var timeLines: usize = 1;

    beamIndices[beamIndex] = 1;

    for (currentRow..input.len) |i| {
        var temp = try allocator.alloc(usize, input[1].len);
        defer allocator.free(temp);
        for (temp) |*v| {
            v.* = 0;
        }
        var indicesToClear: std.ArrayList(usize) = .empty;
        var first = false;
        for (input[i], 0..) |c, j| {
            if (c == '^') {
                if (!first) {
                    first = true;
                }
                try indicesToClear.append(allocator, j);
                timeLines += beamIndices[j];
                temp[j - 1] += beamIndices[j];
                temp[j + 1] += beamIndices[j];
            }
        }

        for (temp, 0..) |t, j| {
            beamIndices[j] += t;
        }
        for (indicesToClear.items) |j| {
            beamIndices[j] = 0;
        }
        indicesToClear.clearAndFree(allocator);
    }
    return timeLines;
}

test "day 7 sample" {
    const input =
        \\.......S.......
        \\...............
        \\.......^.......
        \\...............
        \\......^.^......
        \\...............
        \\.....^.^.^.....
        \\...............
        \\....^.^...^....
        \\...............
        \\...^.^...^.^...
        \\...............
        \\..^...^.....^..
        \\...............
        \\.^.^.^.^.^...^.
        \\...............
    ;
    const allocator = std.testing.allocator;
    const result = try day7(input, allocator);
    try std.testing.expectEqual(21, result);
}

test "day 7 step 2 sample" {
    const input =
        \\.......S.......
        \\...............
        \\.......^.......
        \\...............
        \\......^.^......
        \\...............
        \\.....^.^.^.....
        \\...............
        \\....^.^...^....
        \\...............
        \\...^.^...^.^...
        \\...............
        \\..^...^.....^..
        \\...............
        \\.^.^.^.^.^...^.
        \\...............
    ;
    const allocator = std.testing.allocator;
    const result = try day7_step2(input, allocator);
    try std.testing.expectEqual(40, result);
}
