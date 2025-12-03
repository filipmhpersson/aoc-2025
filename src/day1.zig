const std = @import("std");

const Direction = enum {
    left,
    right,
};

const Turn = struct {
    dir: Direction,
    points: i32,
};

pub fn parseAndStart(allocator: std.mem.Allocator) !void {
    const input = try std.fs.cwd().readFileAlloc(allocator, "input/day1.txt", 1024 * 1024 * 1024);
    var rows = std.mem.splitAny(u8, input, "\n");
    var turns: std.ArrayList(Turn) = .empty;
    while (rows.next()) |row| {
        if (row.len == 0) {
            break;
        }
        const dir = switch (row[0]) {
            'L' => Direction.left,
            'R' => Direction.right,
            else => unreachable,
        };
        const points = try std.fmt.parseInt(i32, row[1..], 10);

        try turns.append(allocator, Turn{ .dir = dir, .points = points });
    }

    const turnsSlice = try turns.toOwnedSlice(allocator);
    const timesTurned = day_1_dial(turnsSlice);
    const timesTurnedStepTwo = try day_1_dial_step_2(turnsSlice);
    std.debug.print("DAY 1 STEP 1 '{d}' STEP 2 '{d}'\n", .{ timesTurned, timesTurnedStepTwo });
}

fn day_1_dial(turns: []const Turn) u32 {
    var dialValue: i32 = 50;
    var timesOnZero: u32 = 0;
    for (turns) |turn| {
        switch (turn.dir) {
            .left => {
                dialValue = @mod(dialValue - turn.points + 100, 100);
            },
            .right => {
                dialValue = dialValue + turn.points;
                dialValue = @mod(dialValue, 100);
            },
        }
        if (dialValue == 0) {
            timesOnZero += 1;
        }
    }
    return timesOnZero;
}

fn day_1_dial_step_2(turns: []const Turn) !i32 {
    std.debug.print("\n", .{});
    var dialValue: i32 = 50;
    var timesOnZero: i32 = 0;
    for (turns) |turn| {
        var timesRotated: i32 = 0;
        switch (turn.dir) {
            .left => {
                const tmp = dialValue - turn.points;
                if (tmp <= 0) {
                    if (dialValue == 0) {
                        //Remove edge case of loop starting at 0, dont count the first iteration
                        timesRotated -= 1;
                    }
                    const t = try std.math.divFloor(i32, (100 - dialValue) + turn.points, 100);
                    timesRotated += t;
                }
                dialValue = @mod(tmp, 100);
            },
            .right => {
                dialValue = dialValue + turn.points;

                if (dialValue >= 100) {
                    timesRotated += @divFloor(dialValue, 100);
                }
                dialValue = @mod(dialValue, 100);
            },
        }
        timesOnZero += timesRotated;
    }
    return timesOnZero;
}

test "Day one dial baby" {
    const input = [_]Turn{.{ .dir = Direction.left, .points = 50 }};
    const value = day_1_dial(&input);
    try std.testing.expectEqual(1, value);
}

test "Day one sample" {
    const input = [_]Turn{
        .{ .dir = Direction.left, .points = 68 },
        .{ .dir = Direction.left, .points = 30 },
        .{ .dir = Direction.right, .points = 48 },
        .{ .dir = Direction.left, .points = 5 },
        .{ .dir = Direction.right, .points = 60 },
        .{ .dir = Direction.left, .points = 55 },
        .{ .dir = Direction.left, .points = 1 },
        .{ .dir = Direction.left, .points = 99 },
        .{ .dir = Direction.right, .points = 14 },
        .{ .dir = Direction.left, .points = 82 },
    };

    const value = day_1_dial(&input);

    try std.testing.expectEqual(3, value);
}
test "Day one step two sample" {
    const input = [_]Turn{
        .{ .dir = Direction.left, .points = 68 },
        .{ .dir = Direction.left, .points = 30 },
        .{ .dir = Direction.right, .points = 48 },
        .{ .dir = Direction.left, .points = 5 },
        .{ .dir = Direction.right, .points = 60 },
        .{ .dir = Direction.left, .points = 55 },
        .{ .dir = Direction.left, .points = 1 },
        .{ .dir = Direction.left, .points = 99 },
        .{ .dir = Direction.right, .points = 14 },
        .{ .dir = Direction.left, .points = 82 },
    };

    const value = try day_1_dial_step_2(&input);

    try std.testing.expectEqual(6, value);
}
test "Day one step two the trick" {
    const input = [_]Turn{
        .{ .dir = Direction.right, .points = 500 },
        .{ .dir = Direction.left, .points = 500 },
    };

    const value = try day_1_dial_step_2(&input);

    try std.testing.expectEqual(10, value);
}
test "Day one step two the other trick" {
    const input = [_]Turn{
        .{ .dir = Direction.left, .points = 50 },
    };

    const value = try day_1_dial_step_2(&input);

    try std.testing.expectEqual(1, value);
}
