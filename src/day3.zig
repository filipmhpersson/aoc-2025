const std = @import("std");
pub fn day3_readAndStart(allocator: std.mem.Allocator) !void {
    const inputFile = try std.fs.cwd().openFile("input/day3", .{ .mode = .read_only });
    const input = try inputFile.readToEndAlloc(allocator, 1024 * 1024);
    const result = day3_run(input);
    const result2 = try day3_run_step2(input);
    std.debug.print("DAY 3 '{d}' step 2 '{d}'\n", .{ result, result2 });
}

fn day3_run(input: []const u8) usize {
    var rows = std.mem.splitAny(u8, input, "\n");
    var joltage: usize = 0;
    while (rows.next()) |row| {
        if (row.len == 0) {
            break;
        }

        var fst = row[0];
        var fst_i: usize = 0;
        for (row[1 .. row.len - 1], 1..) |c, i| {
            if (c > fst) {
                fst = c;
                fst_i = i;
            }
        }
        var snd = row[fst_i + 1];

        if (row.len > fst_i + 1) {
            for (row[fst_i + 1 ..]) |c| {
                if (c > snd) {
                    snd = c;
                }
            }
        }

        joltage += ((fst - '0') * 10) + (snd - '0');
    }
    return joltage;
}

pub fn day3_run_step2(input: []const u8) !usize {
    var rows = std.mem.splitAny(u8, input, "\n");
    var ret: usize = 0;
    while (rows.next()) |row| {
        if (row.len == 0) {
            break;
        }
        var joltages: [12]u8 = undefined;
        var start: usize = 0;
        for (0..joltages.len) |i| {
            var cur: u8 = row[start];
            for (row[start .. row.len - 11 + i], start..) |c, j| {
                if (c > cur) {
                    start = j;
                    cur = c;
                }
            }

            start = start + 1;
            joltages[i] = cur;
        }

        ret += try std.fmt.parseInt(u64, &joltages, 10);
    }
    return ret;
}

test "small day3" {
    try std.testing.expectEqual(92, day3_run("818181911112111"));
    try std.testing.expectEqual(98, day3_run("987654321111111"));
    try std.testing.expectEqual(89, day3_run("811111111111119"));
    try std.testing.expectEqual(78, day3_run("234234234234278"));

    try std.testing.expectEqual(190, day3_run("818181911112111\n987654321111111"));
}

test "small day3 step 2" {
    try std.testing.expectEqual(434234234278, try day3_run_step2("234234234234278"));
    try std.testing.expectEqual(987654321111, try day3_run_step2("987654321111111"));
    try std.testing.expectEqual(888911112111, try day3_run_step2("818181911112111"));
    try std.testing.expectEqual(811111111119, try day3_run_step2("811111111111119"));
}
test "day3 full sampe" {
    const input =
        \\ 987654321111111
        \\811111111111119
        \\234234234234278
        \\818181911112111
    ;

    try std.testing.expectEqual(357, day3_run(input));
}
