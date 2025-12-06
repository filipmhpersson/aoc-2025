const std = @import("std");

const range = struct { start: u64, end: u64 };

pub fn day5_readAndStart(allocator: std.mem.Allocator) !void {
    const input = try std.fs.cwd().readFileAlloc(allocator, "input/day5", 1024 * 1024);
    const result = try day5(input, allocator);
    const result_step2 = try day5_step2(input, allocator);
    std.debug.print("Day 5 {d} Step 2 {d}\n", .{ result, result_step2 });
}

fn day5(input: []const u8, allocator: std.mem.Allocator) !u64 {
    var rows = std.mem.splitAny(u8, input, "\n");
    var ranges: std.ArrayList(range) = .empty;
    defer ranges.deinit(allocator);
    var result: u64 = 0;

    var parseRanges = true;
    rowloop: while (rows.next()) |row| {
        if (row.len == 0) {
            if (parseRanges) {
                std.mem.sort(range, ranges.items, {}, struct {
                    fn lessThan(_: void, a: range, b: range) bool {
                        return a.end < b.end;
                    }
                }.lessThan);

                parseRanges = false;
                continue;
            } else {
                break;
            }
        }

        if (parseRanges) {
            const middle = std.mem.indexOf(u8, row, "-").?;
            const r = range{
                .start = try std.fmt.parseInt(u64, row[0..middle], 0),
                .end = try std.fmt.parseInt(u64, row[middle + 1 ..], 10),
            };
            try ranges.append(allocator, r);
        } else {
            const item = try std.fmt.parseInt(u64, row, 10);

            for (ranges.items) |r| {
                if (item < r.start) {
                    if (item < r.end) {}
                    continue;
                } else if (item >= r.start) {
                    if (item <= r.end) {
                        result += 1;
                        continue :rowloop;
                    }
                }
            }
        }
    }
    return result;
}

fn day5_step2(input: []const u8, allocator: std.mem.Allocator) !u64 {
    var rows = std.mem.splitAny(u8, input, "\n");
    var ranges: std.ArrayList(range) = .empty;
    defer ranges.deinit(allocator);

    var result: usize = 0;

    while (rows.next()) |row| {
        if (row.len == 0) {
            break;
        }
        const middle = std.mem.indexOf(u8, row, "-").?;
        var r = range{
            .start = try std.fmt.parseInt(u64, row[0..middle], 10),
            .end = try std.fmt.parseInt(u64, row[middle + 1 ..], 10),
        };

        const existingRanges = try recurseOverlappingRecurse(&r, ranges.items, allocator);
        for (existingRanges) |er| {
            result += er.end - er.start + 1;
            try ranges.append(allocator, er);
        }
        allocator.free(existingRanges);
    }

    return result;
}

const RangeOrDouble = union(enum) { single: range, double: double, None: bool, Keep: bool };
const double = struct { before: range, after: range };

fn recurseOverlappingRecurse(r: *const range, overlapping: []const range, allocator: std.mem.Allocator) ![]const range {
    var itemToChange = r.*;
    var ranges: std.ArrayList(range) = .empty;
    for (overlapping) |o| {
        const res = try calculateOverlapping(&itemToChange, &o);
        switch (res) {
            .None => return try ranges.toOwnedSlice(allocator),
            .double => {
                const b = try recurseOverlappingRecurse(&res.double.before, overlapping, allocator);
                try ranges.appendSlice(allocator, b);
                defer allocator.free(b);
                const c = try recurseOverlappingRecurse(&res.double.after, overlapping, allocator);
                defer allocator.free(c);
                try ranges.appendSlice(allocator, c);
                return try ranges.toOwnedSlice(allocator);
            },
            .single => {
                itemToChange = res.single;
            },
            .Keep => {},
        }
    }
    try ranges.append(allocator, itemToChange);
    return ranges.toOwnedSlice(allocator);
}

fn calculateOverlapping(r: *range, overlapping: *const range) !RangeOrDouble {
    const newStart = r.*.start;
    const newEnd = r.*.end;

    if (newStart < overlapping.*.start and newEnd > overlapping.*.end) {
        const before = range{ .start = r.start, .end = overlapping.*.start - 1 };
        const after = range{ .end = r.end, .start = overlapping.*.end - 1 };
        return RangeOrDouble{ .double = double{ .after = after, .before = before } };
    }

    if (newStart >= overlapping.start and newStart <= overlapping.end) {
        if (newEnd <= overlapping.end) {
            return RangeOrDouble{ .None = true };
        }

        return RangeOrDouble{ .single = range{ .start = overlapping.end + 1, .end = r.end } };
    }

    if (newEnd >= overlapping.start and newEnd <= overlapping.end) {
        if (newStart > overlapping.start - 1) {
            return RangeOrDouble{ .None = true };
        }
        return RangeOrDouble{ .single = range{ .start = r.start, .end = overlapping.start - 1 } };
    }

    return RangeOrDouble{ .Keep = true };
}

test "day 5 samples" {
    const input =
        \\3-5
        \\10-14
        \\16-20
        \\12-18
        \\
        \\1
        \\5
        \\8
        \\11
        \\17
        \\32
    ;

    const allocator = std.testing.allocator;

    const result = try day5(input, allocator);
    try std.testing.expectEqual(3, result);
}

test "day 5 step2 samples" {
    const input =
        \\2-4
        \\3-5
        \\3-6
        \\1-7
        \\10-14
        \\16-20
        \\9-20
    ;

    const allocator = std.testing.allocator;
    const result = try day5_step2(input, allocator);
    try std.testing.expectEqual(19, result);
}

test "day 5 step2 lab" {
    const input =
        \\12-13
        \\11-12
        \\10-14
    ;

    const allocator = std.testing.allocator;
    const result = try day5_step2(input, allocator);
    try std.testing.expectEqual(5, result);
}

test "day 5 step2" {
    const input =
        \\3-5
        \\10-14
        \\16-20
        \\12-18
    ;

    const allocator = std.testing.allocator;
    const result = try day5_step2(input, allocator);
    try std.testing.expectEqual(14, result);
}
