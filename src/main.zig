const std = @import("std");
const aoc_2025 = @import("aoc_2025");
const day1 = @import("day1.zig");
const day2 = @import("day2.zig");
const day3 = @import("day3.zig");
const day4 = @import("day4.zig");
const day5 = @import("day5.zig");

test "include day1 tests" {
    _ = @import("day1.zig");
    _ = @import("day2.zig");
    _ = @import("day3.zig");
    _ = @import("day4.zig");
    _ = @import("day5.zig");
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

    try day6_readAndStart(allocator);
    _ = arena.reset(.free_all);

    try aoc_2025.bufferedPrint();
}

pub fn day6_readAndStart(allocator: std.mem.Allocator) !void {
    const input = try std.fs.cwd().readFileAlloc(allocator, "input/day6", 1024 * 1024);
    const result = try day6(input, allocator);
    const result_step2 = try day6_step2(input, allocator);
    std.debug.print("Day 6 '{d}' step 2 '{d}'\n", .{ result, result_step2 });
}

pub fn day6(input: []const u8, allocator: std.mem.Allocator) !u128 {
    var rows = std.mem.splitAny(u8, input, "\n");
    var r_cnt: usize = 0;
    while (rows.next()) |row| {
        if (row.len > 0) {
            r_cnt += 1;
        }
    }
    //remove operations row
    r_cnt = r_cnt - 1;

    rows.reset();

    var c_cnt: usize = 0;
    var columnsSplit = std.mem.splitAny(u8, rows.peek().?, " ");
    while (columnsSplit.next()) |cs| {
        if (cs.len != 0) {
            c_cnt += 1;
        }
    }

    var operations: []u8 = try allocator.alloc(u8, c_cnt);
    var math_num = try allocator.alloc(u128, c_cnt * r_cnt);
    defer allocator.free(operations);
    defer allocator.free(math_num);

    {
        var i: usize = 0;
        while (rows.next()) |row| {
            if (row.len == 0) {
                break;
            }
            var cells = std.mem.splitAny(u8, row, " ");

            var j: usize = 0;
            while (cells.next()) |cell| {
                if (cell.len == 0) {
                    continue;
                }

                const number = std.fmt.parseInt(u128, cell, 10) catch {
                    //We are assuming this is the math operation since its not a number
                    operations[j] = cell[0];
                    j += 1;
                    continue;
                };
                math_num[j * r_cnt + i] = number;
                j += 1;
            }
            i += 1;
        }
    }

    var total: u128 = 0;
    for (0..c_cnt) |c| {
        var result: u128 = 0;
        const operation = operations[c];
        for (0..r_cnt) |r| {
            const num = math_num[r + c * r_cnt];
            if (result == 0) {
                result += num;
            } else {
                switch (operation) {
                    '*' => result = result * num,
                    '+' => result = result + num,
                    else => unreachable,
                }
            }
        }
        total += result;
    }
    return total;
}

pub fn day6_step2(input: []const u8, allocator: std.mem.Allocator) !usize {
    var rows = std.mem.splitAny(u8, input, "\n");
    var r_cnt: usize = 0;
    var rowsForNumbers: usize = 0;
    var operations: std.ArrayList(u8) = .empty;
    defer operations.deinit(allocator);

    while (rows.next()) |row| {
        if (row.len > 0) {
            if (row[0] == '+' or row[0] == '*') {
                for (row) |c| {
                    if (c != ' ') {
                        try operations.append(allocator, c);
                    }
                }
            } else {
                rowsForNumbers += 1;
            }
        }
    }
    std.mem.reverse(u8, operations.items);
    rows.reset();
    const c_cnt: usize = @intCast(rows.peek().?.len);

    var list = try allocator.alloc(u8, c_cnt * rowsForNumbers);
    defer allocator.free(list);
    while (rows.next()) |row| {
        if (row.len > 0) {
            if (row[0] == '+' or row[0] == '*') {
                break;
            } else {
                var insertPoint: usize = 0;
                var rev = std.mem.reverseIterator(row);
                while (rev.next()) |c| {
                    const math = r_cnt + (insertPoint * rowsForNumbers);
                    list[math] = c;

                    insertPoint += 1;
                }

                r_cnt += 1;
            }
        }
    }
    var curr: std.ArrayList(u8) = .empty;
    defer curr.deinit(allocator);
    var numbers: std.ArrayList([]const u8) = .empty;
    defer numbers.deinit(allocator);
    for (list, 0..) |c, i| {
        if (i % rowsForNumbers == 0) {
            try numbers.append(allocator, try curr.toOwnedSlice(allocator));
            curr.clearRetainingCapacity();
        }
        if (c != ' ') {
            try curr.append(allocator, c);
        }
    }

    try numbers.append(allocator, try curr.toOwnedSlice(allocator));
    var result: usize = 0;
    var total: usize = 0;
    var operation_index: usize = 0;
    var operation = operations.items[operation_index];
    for (numbers.items) |n| {
        if (n.len == 0) {
            operation = operations.items[operation_index];
            operation_index += 1;
            total += result;
            result = 0;
            defer allocator.free(n);
            continue;
        }
        const num = try std.fmt.parseInt(u32, n, 10);
        if (result == 0) {
            result = num;
        } else {
            switch (operation) {
                '+' => result += num,
                '*' => result *= num,
                else => {
                    unreachable;
                },
            }
        }
        defer allocator.free(n);
    }

    total += result;
    result = 0;
    return total;

    //remove operations row
}

test "day 6 sample" {
    const input =
        \\123 328  51 64 
        \\ 45 64  387 23 
        \\  6 98  215 314
        \\*   +   *   + 
    ;
    const allocator = std.testing.allocator;

    const res = day6(input, allocator);
    try std.testing.expectEqual(4277556, res);
}

test "day 6 sample step2" {
    const input =
        \\123 328  51 64 
        \\ 45 64  387 23 
        \\  6 98  215 314
        \\*   +   *   + 
    ;
    const allocator = std.testing.allocator;

    const res = try day6_step2(input, allocator);
    try std.testing.expectEqual(3263827, res);
}
