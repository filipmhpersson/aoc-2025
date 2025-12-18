const std = @import("std");

const Coordinate = struct { x: usize, y: usize };

pub fn day9_readAndStart(allocator: std.mem.Allocator) !void {
    const input = try std.fs.cwd().readFileAlloc(allocator, "input/day9", 1024 * 1024);
    const result = try day9(input, allocator);
    const result_ste2 = try day9_step2_test2(input, allocator);
    std.debug.print("Day 9 result '{d}' step 2 '{d}'\n", .{ result, result_ste2 });
}

fn day9(input: []const u8, allocator: std.mem.Allocator) !isize {
    var rows = std.mem.splitAny(u8, input, ",\n");
    var coordinates: std.ArrayList(Coordinate) = .empty;

    defer coordinates.deinit(allocator);
    while (true) {
        const x = rows.next();
        if (x == null or x.?.len == 0) {
            break;
        }
        const y = rows.next();

        try coordinates.append(allocator, Coordinate{
            .x = try std.fmt.parseInt(usize, x.?, 10),
            .y = try std.fmt.parseInt(usize, y.?, 10),
        });
    }

    var biggestBox: isize = 0;
    for (coordinates.items[0 .. coordinates.items.len - 1], 0..) |source, i| {
        for (i + 1..coordinates.items.len - 1) |j| {
            const target = coordinates.items[j];
            const height: isize = std.math.cast(isize, source.x).? - std.math.cast(isize, target.x).? + 1;
            const width: isize = std.math.cast(isize, source.y).? - std.math.cast(isize, target.y).? + 1;
            const box: isize = @intCast(height * width);
            if (box > biggestBox) {
                biggestBox = box;
            }
        }
    }
    return biggestBox;
}
const L = struct {
    data: Coordinate,
    node: std.DoublyLinkedList.Node = .{},
};
fn day9_step2_test2(input: []const u8, allocator: std.mem.Allocator) !isize {
    var list: std.DoublyLinkedList = .{};

    var input_rows = std.mem.splitAny(u8, input, ",\n");
    var coordinates: std.ArrayList(Coordinate) = .empty;
    defer coordinates.deinit(allocator);
    while (true) {
        const x = input_rows.next();
        if (x == null or x.?.len == 0) {
            break;
        }
        const y = input_rows.next();

        const coordinate = Coordinate{
            .x = try std.fmt.parseInt(usize, x.?, 10),
            .y = try std.fmt.parseInt(usize, y.?, 10),
        };

        try coordinates.append(allocator, coordinate);

        const node_ptr = try allocator.create(L);
        node_ptr.*.data = coordinate;
        list.append(&node_ptr.*.node);
    }

    for (coordinates.items[0 .. coordinates.items.len - 1], 0..) |source, i| {
        for (i + 1..coordinates.items.len - 1) |j| {
            _ = coordinates.items[j];
            var it = list.first;
            var index: u32 = 1;
            while (it) |node| : (it = node.next) {
                const l: *L = @fieldParentPtr("node", node);
                const d = l.*.data;
                if (d.x == source.x and d.y == source.y) {}

                index += 1;
            }
        }
    }

    return 1;
}
fn findStart(node: *const L, source: Coordinate) ?*const L {
    if (node.*.data.x == source.x and node.*.data.y == source.y) {
        return node;
    }
    while (node.*.node.next) |nxt| {
        const l: *L = @fieldParentPtr("node", nxt);
        if (l.*.data.x == source.x and l.*.data.y == source.y) {
            return l;
        }
    }

    while (node.*.node.prev) |nxt| {
        const l: *L = @fieldParentPtr("node", nxt);
        if (l.*.data.x == source.x and l.*.data.y == source.y) {
            return l;
        }
    }

    return null;
}

fn walkToTarget(node: *const L, source: Coordinate, target: Coordinate) bool {
    const x_source: isize = @intCast(source.x);
    const y_source: isize = @intCast(source.y);

    const x_target: isize = @intCast(target.x);
    const y_target: isize = @intCast(source.y);

    const x_walk = x_target - x_source;
    const y_walk = y_target - y_source;
    const cpy = node.*;

    const expected = getCompassDirection(source, target);
    switch (expected) {
        .N, .S, .W, .E => {
            const it = node.*.node.next.?;
            const l: *L = @fieldParentPtr("node", it);
            if (is_same(&l.*.data, &target)) return true;

            const back = node.*.node.prev;
            if (back == null) {
                return false;
            }
            const backCord: *L = @fieldParentPtr("node", back.?);
            return is_same(&backCord.*.data, &target);
        },
        else => {},
    }

    _ = x_walk;
    _ = y_walk;
    _ = cpy;

    const dir = getCompassDirection(source, target);
    // var next: *L = node.*.node.next.?;
    // const next_l: *L = @fieldParentPtr("node", next);
    // var back: *L = node.*.node.prev.?;
    // const back_l: *L = @fieldParentPtr("node", back);

    switch (dir) {
        .NE => {},
        .SE => {},
        .SW => {},
        .NW => {},
        else => {},
    }

    return false;
}

fn is_same(source: *const Coordinate, target: *const Coordinate) bool {
    return source.*.x == target.*.x and source.*.y == target.*.y;
}
fn getCompassDirection(source: Coordinate, target: Coordinate) compassDirection {
    var dir: compassDirection = undefined;
    if (source.x == target.x) {
        if (source.y > target.y) {
            return compassDirection.N;
        } else {
            return compassDirection.S;
        }
    }
    if (source.y == target.y) {
        if (source.x > target.x) {
            return compassDirection.W;
        } else {
            return compassDirection.E;
        }
    }

    if (source.y < target.y) {
        if (source.x < target.x) {
            dir = compassDirection.SE;
        } else {
            dir = compassDirection.SW;
        }
    } else {
        if (source.x < target.x) {
            dir = compassDirection.NE;
        } else {
            dir = compassDirection.NW;
        }
    }
    return dir;
}

fn day9_step2_test(input: []const u8, allocator: std.mem.Allocator) !isize {
    var input_rows = std.mem.splitAny(u8, input, ",\n");
    var coordinates: std.ArrayList(Coordinate) = .empty;
    defer coordinates.deinit(allocator);
    var columns: std.AutoHashMap(usize, std.ArrayList(usize)) = .init(allocator);
    var rows: std.AutoHashMap(usize, std.ArrayList(usize)) = .init(allocator);
    var len: usize = 0;
    var hgt: usize = 0;
    while (true) {
        const x = input_rows.next();
        if (x == null or x.?.len == 0) {
            break;
        }
        const y = input_rows.next();

        const coordinate = Coordinate{
            .x = try std.fmt.parseInt(usize, x.?, 10),
            .y = try std.fmt.parseInt(usize, y.?, 10),
        };
        var row = try rows.getOrPut(coordinate.y);
        if (!row.found_existing) {
            row.value_ptr.* = .empty;
        }
        try row.value_ptr.append(allocator, coordinate.x);

        var column = try columns.getOrPut(coordinate.x);
        if (!column.found_existing) {
            column.value_ptr.* = .empty;
        }
        try column.value_ptr.append(allocator, coordinate.y);

        try coordinates.append(allocator, coordinate);
        if (coordinate.x + 1 > hgt) {
            hgt = coordinate.x + 1;
        }
        if (coordinate.y + 1 > len) {
            len = coordinate.y + 1;
        }
    }

    var list: std.DoublyLinkedList = .{};

    const first = coordinates.items[0];
    var start = coordinates.items[0];
    var startNode = L{ .data = start };
    list.append(&startNode.node);
    std.debug.print("hello\n", .{});
    var i: usize = 0;
    bigloop: while (true) {
        i += 1;
        const next_h = rows.get(start.y).?;
        for (next_h.items) |n| {
            if (next_h.items.len == 1 or n != start.x) {
                const next_v = columns.get(n).?;
                for (next_v.items) |v| {
                    if (next_v.items.len == 1 or v != start.y) {
                        const node_h_ptr = try allocator.create(L);
                        node_h_ptr.*.data = Coordinate{ .x = n, .y = start.y };
                        std.debug.print("Starting from {any}, found  next {any}\n", .{ start, node_h_ptr.*.data });
                        list.append(&node_h_ptr.*.node);
                        start = Coordinate{ .x = n, .y = v };
                        if (start.x == first.x and start.y == first.y) {
                            std.debug.print("MATCH?? first {any} start{any}\n", .{ first, start });
                            break :bigloop;
                        }

                        const node_v_ptr = try allocator.create(L);
                        node_v_ptr.*.data = start;

                        list.append(&node_v_ptr.*.node);
                        break;
                    }
                }
            }
        }
    }

    var it = list.first;
    var index: u32 = 1;
    while (it) |node| : (it = node.next) {
        const l: *L = @fieldParentPtr("node", node);
        std.debug.print("FROM NODE {any}\n", .{l.data});
        index += 1;
        if (index > 15) {
            break;
        }
    }

    return 1;
}

fn day9_step2(input: []const u8, allocator: std.mem.Allocator) !usize {
    var input_rows = std.mem.splitAny(u8, input, ",\n");
    var coordinates: std.ArrayList(Coordinate) = .empty;
    defer coordinates.deinit(allocator);
    // var columns: std.AutoHashMap(usize, std.ArrayList(usize)) = .init(allocator);
    // var rows: std.AutoHashMap(usize, std.ArrayList(usize)) = .init(allocator);
    var len: usize = 0;
    var hgt: usize = 0;
    while (true) {
        const x = input_rows.next();
        if (x == null or x.?.len == 0) {
            break;
        }
        const y = input_rows.next();

        const coordinate = Coordinate{
            .x = try std.fmt.parseInt(usize, x.?, 10),
            .y = try std.fmt.parseInt(usize, y.?, 10),
        };
        // var row = try rows.getOrPut(coordinate.y);
        // if (!row.found_existing) {
        //     row.value_ptr.* = .empty;
        // }
        // try row.value_ptr.append(allocator, coordinate.y);
        //
        // var column = try columns.getOrPut(coordinate.x);
        // if (!column.found_existing) {
        //     column.value_ptr.* = .empty;
        // }
        // try column.value_ptr.append(allocator, coordinate.x);

        try coordinates.append(allocator, coordinate);
        if (coordinate.x + 1 > hgt) {
            hgt = coordinate.x + 1;
        }
        if (coordinate.y + 1 > len) {
            len = coordinate.y + 1;
        }
    }

    const arr: [][]u8 = try allocator.alloc([]u8, len);

    std.debug.print("INIT dots", .{});
    for (0..len) |i| {
        arr[i] = try allocator.alloc(u8, hgt);
        for (0..hgt) |j| {
            arr[i][j] = '.';
        }
    }

    std.debug.print("INIT X", .{});
    for (coordinates.items) |coord| {
        arr[coord.y][coord.x] = 'X';
    }

    std.debug.print("INIT # rows", .{});
    for (arr, 0..) |row, i| {
        var start: ?usize = null;
        for (row, 0..) |c, j| {
            if (c == 'X' or c == '#') {
                if (start) |s| {
                    for (s + 1..j) |n| {
                        arr[i][n] = '#';
                    }
                } else {
                    start = j;
                }
            }
        }
    }

    for (0..arr[0].len) |i| {
        var start: ?usize = null;
        for (0..arr.len) |j| {
            const c = arr[j][i];
            if (c == 'X' or c == '#') {
                if (start) |s| {
                    for (s + 1..j) |n| {
                        arr[n][i] = '#';
                    }
                } else {
                    start = j;
                }
            }
        }
    }

    var biggestBox: usize = 0;
    for (coordinates.items[0 .. coordinates.items.len - 1], 0..) |source, i| {
        for (i + 1..coordinates.items.len - 1) |j| {
            const target = coordinates.items[j];
            const box = walkToAndFrom(source, target, arr);
            if (box > biggestBox) {
                biggestBox = box;
            }
        }
    }

    // var highest: usize = 0;
    // for (coordinates.items) |i| {
    //     var start = Direction.right;
    //     while (true) {
    //         std.debug.print("EVALUATING cord {any} dir {any}\n", .{ i, start });
    //         const res = fullRect(i, arr, start);
    //         if (res > highest) {
    //             std.debug.print("SETTING HIGHEST cord {any} dir {any} point {d}\n", .{ i, start, res });
    //
    //             highest = res;
    //         }
    //         start = nextDirection(start) orelse break;
    //     }
    // }

    std.debug.print("CLEAR\n ", .{});
    for (arr) |a| {
        defer allocator.free(a);
    }
    defer allocator.free(arr);

    return biggestBox;
}
const compassDirection = enum {
    NW,
    N,
    NE,
    E,
    SE,
    S,
    SW,
    W,
};

fn walkToAndFrom(source: Coordinate, target: Coordinate, rows: [][]u8) usize {
    const direction = enum {
        NW,
        NE,
        SE,
        SW,
    };
    var dir: direction = undefined;
    if (source.x < target.x) {
        if (source.y < target.y) {
            dir = direction.SE;
        } else {
            dir = direction.SW;
        }
    } else {
        if (source.y < target.y) {
            dir = direction.NE;
        } else {
            dir = direction.NW;
        }
    }
    // std.debug.print("INVESTIGATING s {any} t {any} dir {any}\n", .{ source, target, dir });

    switch (dir) {
        .SE => {
            const validRight = validPath(source, target, rows, .right);
            const validBot = validPath(source, target, rows, .bottom);
            // std.debug.print("VALID RIGHT {any} VALID BOT {any}\n", .{ validRight, validBot });
            if (!validBot or !validRight) {
                return 0;
            }
            const validDown = validPath(Coordinate{ .y = source.y, .x = target.x }, target, rows, .bottom);
            const valid2 = validPath(Coordinate{ .y = target.y, .x = source.x }, target, rows, .right);
            // std.debug.print("VALID EXTRA {any}\n", .{validDown});
            if (!validDown or !valid2) {
                return 0;
            }
        },
        .SW => {
            const validLeft = validPath(source, target, rows, .left);
            const validBot = validPath(source, target, rows, .bottom);
            if (!validBot or !validLeft) {
                return 0;
            }
            const validDown = validPath(Coordinate{ .y = source.y, .x = target.x }, target, rows, .bottom);
            const valid2 = validPath(Coordinate{ .y = target.y, .x = source.x }, target, rows, .left);
            if (!validDown or !valid2) {
                return 0;
            }
        },
        .NW => {
            const validLeft = validPath(source, target, rows, .left);
            const validTop = validPath(source, target, rows, .top);
            if (!validTop or !validLeft) {
                return 0;
            }
            const validDown = validPath(Coordinate{ .y = source.y, .x = target.x }, target, rows, .top);
            const valid2 = validPath(Coordinate{ .y = target.y, .x = source.x }, target, rows, .left);
            if (!validDown or !valid2) {
                return 0;
            }
        },

        .NE => {
            const validRight = validPath(source, target, rows, .right);
            const validBot = validPath(source, target, rows, .top);
            if (!validBot or !validRight) {
                return 0;
            }
            const vald1 = validPath(Coordinate{ .y = source.y, .x = target.x }, target, rows, .top);
            const valid2 = validPath(Coordinate{ .y = target.y, .x = source.x }, target, rows, .right);
            if (!vald1 or !valid2) {
                return 0;
            }
        },
    }

    var height: usize = 0;
    var width: usize = 0;
    switch (dir) {
        .SE => {
            height = target.x - source.x + 1;
            width = target.y - source.y + 1;
        },
        .NE => {
            width = target.y - source.y + 1;
            height = source.x - target.x + 1;
        },
        .SW => {
            width = source.y - target.y + 1;
            height = target.x - source.x + 1;
        },
        .NW => {
            width = source.y - target.y + 1;
            height = source.x - target.x + 1;
        },
    }
    const res: usize = @intCast(height * width);
    // std.debug.print("DOING MATH s {any} t {any} h {d} w {d} r {d}\n", .{ source, target, height, width, res });
    return res;
}

fn validPath(source: Coordinate, target: Coordinate, rows: [][]u8, dir: Direction) bool {
    var next = source;

    while (true) {
        switch (dir) {
            .left, .right => {
                if (target.y == next.y) {
                    return true;
                }
                if (dir == .right) {
                    next.y = next.y + 1;
                    if (next.y > target.y) {
                        return false;
                    }
                } else {
                    next.y = next.y - 1;
                    if (next.y < target.y) {
                        return false;
                    }
                }
            },
            .top, .bottom => {
                if (target.x == next.x) {
                    return true;
                }
                if (dir == .top) {
                    next.x = next.x - 1;
                    if (next.x < target.x) {
                        return false;
                    }
                } else {
                    next.x = next.x + 1;
                    if (next.x > target.x) {
                        return false;
                    }
                }
            },
        }
        if (rows[next.y][next.x] != 'X' and rows[next.y][next.x] != '#') {
            return false;
        }
    }
}

fn fullRect(cur: Coordinate, rows: [][]u8, dir: Direction) usize {
    var d = dir;

    var cord = cur;
    std.debug.print("{any}\n", .{cord});
    const first = walkRect(&cord, rows, d);
    d = nextDir(d);
    var curd = cur;
    std.debug.print("CURD {any}\n", .{curd});
    const second = walkRect(&curd, rows, d);

    d = nextDir(d);
    const third = walkRect(&curd, rows, dir);

    d = nextDir(d);
    std.debug.print("{any}\n", .{cord});
    const fourth = walkRect(&cord, rows, d);
    std.debug.print("{d} {d} {d} {d}\n", .{ first, second, third, fourth });
    if (first == third and second == fourth) {
        return (@min(first, third)) * (@min(second, fourth));
    } else {
        return 0;
    }
}

fn nextDir(dir: Direction) Direction {
    return switch (dir) {
        .top => Direction.right,
        .bottom => Direction.left,
        .left => Direction.top,
        .right => Direction.bottom,
    };
}

fn walkRect(cur: *Coordinate, rows: [][]u8, dir: Direction) usize {
    var next = cur.*;
    switch (dir) {
        .top => if (cur.x == 0) {
            return 0;
        } else {
            next.y = next.y - 1;
        },
        .bottom => if (next.y + 1 >= rows.len) {
            return 0;
        } else {
            next.y = next.y + 1;
        },
        .left => if (next.x == 0) {
            return 0;
        } else {
            next.x = next.x - 1;
        },
        .right => if (next.x + 1 >= rows[next.y].len) {
            return 0;
        } else {
            next.x = next.x + 1;
        },
    }

    const result = rows[next.y][next.x];

    if (result == '#') {
        cur.* = next;
        return walkRect(cur, rows, dir) + 1;
    } else if (result == 'X') {
        cur.* = next;
        const res = walkRect(cur, rows, dir) + 1;
        if (res == 0) {
            return 0;
        } else {
            return res + 1;
        }
    } else {
        return 0;
    }
}

fn isAllowed(c: u8) bool {
    return c == 'X' or c == '#';
}

fn nextDirection(dir: Direction) ?Direction {
    switch (dir) {
        .right => return Direction.bottom,
        .bottom => return Direction.left,
        .left => return Direction.top,
        .top => return null,
    }
}

fn walk(cur: Coordinate, rows: [][]u8, dir: Direction) bool {
    const next = switch (dir) {
        .top => if (cur.x == 0) return false else Coordinate{ .y = cur.y - 1, .x = cur.x },
        .bottom => if (cur.y + 1 >= rows.len) return false else Coordinate{ .y = cur.y + 1, .x = cur.x },
        .left => if (cur.x == 0) return false else Coordinate{ .y = cur.y, .x = cur.x - 1 },
        .right => if (cur.x + 1 >= rows[cur.y].len) return false else Coordinate{ .y = cur.y, .x = cur.x + 1 },
    };

    const result = rows[next.y][next.x];

    if (result == 'X') {
        return true;
    } else if (result == '#') {
        return false;
    } else {
        const res = walk(next, rows, dir);
        if (res) {
            rows[next.y][next.x] = '#';
        }
        return res;
    }
}

const Direction = enum { right, bottom, left, top };

test "day 9 sample" {
    const input =
        \\7,1
        \\11,1
        \\11,7
        \\9,7
        \\9,5
        \\2,5
        \\2,3
        \\7,3
    ;

    const result = try (day9(input, std.testing.allocator));
    try std.testing.expectEqual(50, result);
}

// test "day 9 sample step2" {
//     const input =
//         \\7,1
//         \\11,1
//         \\11,7
//         \\9,7
//         \\9,5
//         \\2,5
//         \\2,3
//         \\7,3
//     ;
//
//     const result = try (day9_step2_test2(input, std.testing.allocator));
//     try std.testing.expectEqual(24, result);
// }

test "day 9 compass tests" {
    const input = [_]struct { source: Coordinate, target: Coordinate, expected: compassDirection }{
        .{ .source = Coordinate{ .x = 0, .y = 1 }, .target = Coordinate{ .x = 0, .y = 0 }, .expected = compassDirection.N },
        .{ .source = Coordinate{ .x = 0, .y = 1 }, .target = Coordinate{ .x = 1, .y = 0 }, .expected = compassDirection.NE },
        .{ .source = Coordinate{ .x = 0, .y = 1 }, .target = Coordinate{ .x = 2, .y = 1 }, .expected = compassDirection.E },
        .{ .source = Coordinate{ .x = 0, .y = 0 }, .target = Coordinate{ .x = 1, .y = 1 }, .expected = compassDirection.SE },
        .{ .source = Coordinate{ .x = 0, .y = 0 }, .target = Coordinate{ .x = 0, .y = 1 }, .expected = compassDirection.S },
        .{ .source = Coordinate{ .x = 1, .y = 0 }, .target = Coordinate{ .x = 0, .y = 1 }, .expected = compassDirection.SW },
        .{ .source = Coordinate{ .x = 2, .y = 1 }, .target = Coordinate{ .x = 0, .y = 1 }, .expected = compassDirection.W },
        .{ .source = Coordinate{ .x = 1, .y = 1 }, .target = Coordinate{ .x = 0, .y = 0 }, .expected = compassDirection.NW },
    };

    for (input) |t| {
        const res = getCompassDirection(t.source, t.target);
        try std.testing.expectEqual(t.expected, res);
    }
}

test "day 9 walk tests" {
    const input = [_]struct { source: Coordinate, target: Coordinate, res: bool }{
        .{ .source = Coordinate{ .x = 0, .y = 0 }, .target = Coordinate{ .x = 0, .y = 1 }, .res = true },
        .{ .source = Coordinate{ .x = 0, .y = 1 }, .target = Coordinate{ .x = 0, .y = 0 }, .res = true },
        //        .{ .source = Coordinate{ .x = 0, .y = 0 }, .target = Coordinate{ .x = 2, .y = 1 }, .res = true },
        .{ .source = Coordinate{ .x = 0, .y = 0 }, .target = Coordinate{ .x = 1, .y = 0 }, .res = false },
        // .{ .source = Coordinate{ .x = 0, .y = 0 }, .target = Coordinate{ .x = 1, .y = 1 }, .res = true },
        // .{ .source = Coordinate{ .x = 0, .y = 0 }, .target = Coordinate{ .x = 0, .y = 1 }, .res = true },
        // .{ .source = Coordinate{ .x = 1, .y = 0 }, .target = Coordinate{ .x = 0, .y = 1 }, .res = true },
        // .{ .source = Coordinate{ .x = 2, .y = 1 }, .target = Coordinate{ .x = 0, .y = 1 }, .res = true },
        // .{ .source = Coordinate{ .x = 1, .y = 1 }, .target = Coordinate{ .x = 0, .y = 0 }, .res = true },
    };
    var list: std.DoublyLinkedList = .{};
    const from = Coordinate{ .x = 0, .y = 0 };
    const to = Coordinate{ .x = 0, .y = 1 };

    var one: L = .{ .data = from };
    var two: L = .{ .data = to };
    var three: L = .{ .data = Coordinate{ .x = 2, .y = 1 } };

    list.append(&one.node);
    list.append(&two.node);
    list.append(&three.node);

    std.debug.print("LIST {d}\n", .{list.len()});
    for (input) |t| {
        const first = list.first.?;
        const l: *L = @fieldParentPtr("node", first);
        const start = findStart(l, t.source);
        const res = walkToTarget(start.?, t.source, t.target);
        try std.testing.expectEqual(t.res, res);
    }
}

// test "day 9 test step2" {

//     const input =
//         \\98104,50456
//         \\98104,51682
//         \\98312,51682
//         \\98312,52884
//         \\97889,52884
//         \\97889,54111
//         \\97979,54111
//         \\97979,55268
//         \\97347,55268
//         \\97347,56539
//     ;
//
//     const result = try (day9_step2(input, std.testing.allocator));
//     try std.testing.expectEqual(24, result);
// }
