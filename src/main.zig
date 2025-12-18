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
const day9 = @import("day9.zig");

test "include day1 tests" {
    _ = @import("day1.zig");
    _ = @import("day2.zig");
    _ = @import("day3.zig");
    _ = @import("day4.zig");
    _ = @import("day5.zig");
    _ = @import("day6.zig");
    _ = @import("day7.zig");
    _ = @import("day8.zig");
    _ = @import("day9.zig");
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
    // try day9.day9_readAndStart(allocator);
    // _ = arena.reset(.free_all);
    //
    try day10_readAndStart(allocator);

    try aoc_2025.bufferedPrint();
}

fn day10_readAndStart(allocator: std.mem.Allocator) !void {
    const input = try std.fs.cwd().readFileAlloc(allocator, "input/day10", 1024 * 1024);
    const res = try day10(input, allocator);
    const res2 = try day10_step2(input, allocator);
    std.debug.print("Day 10 result '{d}' step 2 '{d}'\n", .{ res, res2 });
}

const machine_step2 = struct {
    joltage: std.ArrayList(usize),
    buttons: std.ArrayList(std.ArrayList(usize)),
    cache: std.AutoHashMap(u64, usize),

    const ButtonPoints = struct { button: []usize, points: usize };

    const QueueItem = struct {
        data: QueueData,
        node: std.DoublyLinkedList.Node = .{},
    };

    const QueueData = struct {
        data: []usize,
        steps: usize,
    };

    fn turnItOn(self: *machine_step2, allocator: std.mem.Allocator) !usize {
        // var queue: std.DoublyLinkedList = .{};
        //

        var index: usize = 0;
        while (true) {
            var points: std.ArrayList(ButtonPoints) = .empty;
            defer points.deinit(allocator);
            for (self.buttons.items, 0..) |b, i| {
                try points.append(
                    allocator,
                    ButtonPoints{ .button = b.items, .points = getButtonPoints(i, self.buttons, self.joltage.items) },
                );
            }

            std.mem.sort(ButtonPoints, points.items, {}, struct {
                fn greatherThan(_: void, a: ButtonPoints, b: ButtonPoints) bool {
                    return a.points > b.points;
                }
            }.greatherThan);

            std.debug.print("BUTTON ITEMS {any}\n", .{points.items});
            std.debug.print("JOLT {any}\n", .{self.joltage});
            for (points.items[0].button) |b| {
                self.joltage.items[b] = self.joltage.items[b] - 1;
            }
            index += 1;
            var res = true;
            for (self.joltage.items) |j| {
                if (j > 0) {
                    res = false;
                    break;
                }
            }
            if (res) {
                return index;
            }
        }

        // for (self.buttons.items, 0..) |b, i| {
        //     try points.append(
        //         allocator,
        //         ButtonPoints{ .button = b.items, .points = getButtonPoints(i, self.buttons, self.joltage.items) },
        //     );
        // }
        //
        // std.mem.sort(ButtonPoints, points.items, {}, struct {
        //     fn greatherThan(_: void, a: ButtonPoints, b: ButtonPoints) bool {
        //         return a.button.len > b.button.len;
        //     }
        // }.greatherThan);
        //
        // var start_copy = try allocator.alloc(usize, self.*.joltage.items.len);
        // for (0..start_copy.len) |i| {
        //     start_copy[i] = 0;
        // }
        //
        // while (true) {
        //     std.debug.print("LOOPING  max len {d}\n", .{maxLen});
        //     var btn: std.ArrayList(ButtonPoints) = .empty;
        //     for (points.items) |p| {
        //         if (p.button.len >= maxLen) {
        //             try btn.append(allocator, p);
        //         }
        //     }
        //     var bestresult: usize = 0;
        //
        //     for (btn.items) |bt| {
        //         var cpy = try allocator.alloc(usize, self.*.joltage.items.len);
        //         for (0..start_copy.len) |i| {
        //             cpy[i] = 0;
        //         }
        //         for (bt.button) |butt| {
        //             cpy[butt] = 1;
        //         }
        //
        //         std.debug.print("STARTING {any} btns {any} with extra {any}\n", .{ cpy, btn.items, bt.button });
        //         const res1 = try self.fill_recurse(btn.items, self.joltage.items, cpy, allocator);
        //         std.debug.print("GOT RES {d}\n", .{res1});
        //         if (bestresult == 0 or res1 < bestresult) {
        //             bestresult = res1;
        //         }
        //     }
        //     if (bestresult > 0) {
        //         return bestresult + 1;
        //     }
        //     maxLen -= 1;
        //     if (maxLen == 0) {
        //         break;
        //     }
        // }
        // const res1 = try self.fill_recurse(points.items, self.joltage.items, start_copy, allocator);
        // //const res1 = fill(0, points, self.joltage.items, start_copy);
        // return res1;
        // std.debug.print("RES {d}\n", .{res1});
        // for (0..points.items.len) |i| {
        //     std.debug.print("POINTS {any} {d}\n", .{ points.items[i].button, points.items[i].points });
        // }
        //
        // var start = QueueItem{ .data = QueueData{ .data = start_copy, .steps = 0 } };
        //
        // // enqueue
        // queue.append(&start.node);
        // var count: usize = 0;
        //
        // // dequeue
        // queueloop: while (queue.pop()) |node| {
        //     const item: ?*QueueItem = @fieldParentPtr("node", node);
        //
        //     for (points.items) |button| {
        //         var copy = try allocator.dupe(usize, item.?.data.data);
        //
        //         for (button.button.items) |lightToChange| {
        //             copy[lightToChange] = copy[lightToChange] + 1;
        //         }
        //
        //         // std.debug.print("adding {any} to copy {any}\n", .{ button.button.items, copy });
        //         var result = true;
        //         //std.debug.print("COMPARIN {any} TO {any}\n", .{ copy, self.*.joltage.items });
        //         for (0..copy.len) |i| {
        //             if (copy[i] > self.*.joltage.items[i]) {
        //                 continue :queueloop;
        //             }
        //
        //             if (copy[i] < self.*.joltage.items[i]) {
        //                 result = false;
        //             }
        //         }
        //         if (result) {
        //             return item.?.data.steps + 1;
        //         }
        //         const q_p = try allocator.create(QueueItem);
        //
        //         q_p.* = QueueItem{ .data = QueueData{ .data = copy, .steps = item.?.data.steps + 1 } };
        //         queue.append(&q_p.*.node);
        //     }
        //     defer allocator.free(item.?.data.data);
        //     count += 1;
        // }
        //
        // return 0;
    }

    fn fill_recurse(self: *machine_step2, buttons: []ButtonPoints, voltages: []const usize, copy: []const usize, allocator: std.mem.Allocator) !usize {
        for (buttons, 0..) |button, i| {
            const key = hashPair(i, copy);
            const exists = self.cache.get(key);
            if (exists) |res| {
                return res;
            }
            var cpy = try allocator.dupe(usize, copy);
            for (button.button) |lightToChange| {
                cpy[lightToChange] = cpy[lightToChange] + 1;
            }
            var result = true;
            for (0..cpy.len) |j| {
                if (cpy[j] > voltages[j]) {
                    try self.cache.put(key, 0);
                    return 0;
                }

                if (cpy[j] < voltages[j]) {
                    result = false;
                }
            }
            if (result) {
                try self.cache.put(key, 1);
                std.debug.print("ADDED {any} TO RES\n", .{button.button});
                return 1;
            }
            const res = try self.fill_recurse(buttons, voltages, cpy, allocator);
            if (res != 0) {
                try self.cache.put(key, res + 1);
                std.debug.print("ADDED {any} TO RES\n", .{button.button});
                return res + 1;
            } else {
                try self.cache.put(key, 0);
            }
        }
        return 0;
    }

    pub fn hashPair(button: usize, copy: []const usize) u64 {
        var hasher = std.hash.Wyhash.init(0);
        hasher.update(std.mem.asBytes(&button));
        for (copy) |a| {
            hasher.update(std.mem.asBytes(&a));
            hasher.update(",");
        }
        return hasher.final();
    }

    fn fill(selectedButtonIndex: usize, buttons: std.ArrayList(ButtonPoints), voltages: []const usize, copy: []usize) usize {
        var i: usize = 0;
        var buttonIndex = selectedButtonIndex;
        queueloop: while (true) {
            std.debug.print("BUTTON INDEX {d}\n", .{buttonIndex});
            const button = buttons.items[buttonIndex].button;
            for (button) |lightToChange| {
                copy[lightToChange] = copy[lightToChange] + 1;
            }

            var result = true;
            for (0..copy.len) |j| {
                if (copy[j] > voltages[j]) {
                    for (button) |lightToChange| {
                        copy[lightToChange] = copy[lightToChange] - 1;
                    }
                    buttonIndex += 1;
                    continue :queueloop;
                }

                if (copy[j] < voltages[j]) {
                    result = false;
                }
            }
            i += 1;

            std.debug.print("   ADDED {any}\n ", .{button});
            if (result) {
                return i;
            }
        }
    }

    fn getButtonPoints(selectedButtonIndex: usize, buttons: std.ArrayList(std.ArrayList(usize)), voltages: []const usize) usize {
        var points: usize = 0;
        const button = buttons.items[selectedButtonIndex];

        points += button.items.len;
        var highest: usize = 0;
        for (voltages) |v| {
            if (highest == 0 or v > highest) {
                highest = v;
            }
        }

        voltloop: for (voltages, 0..) |volt, i| {
            for (button.items) |b| {
                if (b == i) {
                    if (volt > 0) {
                        if (volt < highest) {} else {
                            points += volt + 1;
                        }
                    } else {
                        points = 0;
                        break :voltloop;
                    }
                }
            }
        }

        for (buttons.items, 0..) |b, i| {
            if (i == selectedButtonIndex) {
                continue;
            }

            const exist = std.mem.indexOfAny(usize, button.items, b.items);
            if (exist != null) {
                if (points > 0) {
                    points -= 1;
                }
            }
        }
        return points;
    }
};

const machine = struct {
    lights: std.ArrayList(bool),
    buttons: std.ArrayList(std.ArrayList(usize)),

    fn print(self: *const machine) void {
        std.debug.print("MACHINE:\n", .{});

        std.debug.print("    LIGHTS: ", .{});
        for (self.lights.items) |l| {
            if (l) {
                std.debug.print("#", .{});
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
        std.debug.print("    BUTTONS:\n", .{});

        for (self.buttons.items) |b| {
            std.debug.print("       BUTTONGROUP:", .{});
            for (b.items) |bt| {
                std.debug.print("{d},", .{bt});
            }
            std.debug.print("\n", .{});
        }
    }

    const QueueItem = struct {
        data: QueueData,
        node: std.DoublyLinkedList.Node = .{},
    };

    const QueueData = struct {
        data: []bool,
        steps: usize,
    };

    fn turnItOn(self: *const machine, allocator: std.mem.Allocator) !usize {
        var queue: std.DoublyLinkedList = .{};
        var start_copy = try allocator.alloc(bool, self.*.lights.items.len);
        for (0..start_copy.len) |i| {
            start_copy[i] = false;
        }

        var start = QueueItem{ .data = QueueData{ .data = start_copy, .steps = 0 } };

        // enqueue
        queue.append(&start.node);
        var count: usize = 0;

        // dequeue
        while (queue.popFirst()) |node| {
            const item: ?*QueueItem = @fieldParentPtr("node", node);

            for (self.buttons.items) |button| {
                var copy = try allocator.dupe(bool, item.?.data.data);

                for (button.items) |lightToChange| {
                    copy[lightToChange] = !copy[lightToChange];
                }

                if (allLightsOn(copy, self.lights.items)) {
                    return item.?.data.steps + 1;
                }
                const q_p = try allocator.create(QueueItem);

                q_p.* = QueueItem{ .data = QueueData{ .data = copy, .steps = item.?.data.steps + 1 } };
                queue.append(&q_p.*.node);
            }
            defer allocator.free(item.?.data.data);
            count += 1;
        }

        return 0;
    }

    fn allLightsOn(lights: []const bool, target: []const bool) bool {
        for (0..lights.len) |i| {
            if (lights[i] != target[i]) {
                return false;
            }
        }
        return true;
    }
};

fn day10_step2(input: []const u8, allocator: std.mem.Allocator) !usize {
    //[.##.] (3) (1,3) (2) (j, delimiters: []const T)
    //s
    var rows = std.mem.splitAny(u8, input, "\n");
    var machines: std.ArrayList(machine_step2) = .empty;
    while (rows.next()) |row| {
        if (row.len == 0) {
            break;
        }
        var lights: std.ArrayList(bool) = .empty;
        var buttons: std.ArrayList(std.ArrayList(usize)) = .empty;
        var jolatages: std.ArrayList(usize) = .empty;

        const startLights = std.mem.indexOf(u8, row, "[").?;
        const end = std.mem.indexOf(u8, row, "]").?;

        for (row[startLights + 1 .. end]) |c| {
            if (c == '.') {
                try lights.append(allocator, false);
            } else if (c == '#') {
                try lights.append(allocator, true);
            } else {
                unreachable;
            }
        }

        var buttons_split = std.mem.splitAny(u8, row, "(");
        while (buttons_split.next()) |b| {
            const maybe_b_end = std.mem.indexOf(u8, b, ")");
            if (maybe_b_end) |b_end| {
                var lightsToChange: std.ArrayList(usize) = .empty;
                var lightsToChangeSplit = std.mem.splitAny(u8, b[0..b_end], ",");
                while (lightsToChangeSplit.next()) |l| {
                    if (l.len > 0) {
                        try lightsToChange.append(allocator, try std.fmt.parseInt(usize, l, 10));
                    }
                }

                try buttons.append(allocator, lightsToChange);
            }
        }

        var jolatage_split = std.mem.splitAny(u8, row, "{");
        while (jolatage_split.next()) |jolt| {
            const maybe_b_end = std.mem.indexOf(u8, jolt, "}");
            if (maybe_b_end) |jolt_end| {
                var lightsToChangeSplit = std.mem.splitAny(u8, jolt[0..jolt_end], ",");
                while (lightsToChangeSplit.next()) |l| {
                    if (l.len > 0) {
                        try jolatages.append(allocator, try std.fmt.parseInt(usize, l, 10));
                    }
                }
            }
        }
        try machines.append(allocator, machine_step2{ .buttons = buttons, .joltage = jolatages, .cache = .init(allocator) });
    }
    var iters: usize = 0;
    var total: usize = 0;
    for (machines.items) |m| {
        iters += 1;

        var a = m;
        std.debug.print("PROCESSING MACHINE {d}\n", .{iters});
        const res = try a.turnItOn(allocator);
        total += res;
    }

    for (0..machines.items.len) |i| {
        var m = machines.items[i];
        for (0..m.buttons.items.len) |j| {
            var b = m.buttons.items[j];
            b.clearAndFree(allocator);
        }
        m.joltage.clearAndFree(allocator);
        m.buttons.clearAndFree(allocator);
    }
    machines.clearAndFree(allocator);
    return total;
}

fn day10(input: []const u8, allocator: std.mem.Allocator) !usize {
    //[.##.] (3) (1,3) (2) (j, delimiters: []const T)
    //s
    var rows = std.mem.splitAny(u8, input, "\n");
    var machines: std.ArrayList(machine) = .empty;
    while (rows.next()) |row| {
        if (row.len == 0) {
            break;
        }
        var lights: std.ArrayList(bool) = .empty;
        var buttons: std.ArrayList(std.ArrayList(usize)) = .empty;

        const startLights = std.mem.indexOf(u8, row, "[").?;
        const end = std.mem.indexOf(u8, row, "]").?;

        for (row[startLights + 1 .. end]) |c| {
            if (c == '.') {
                try lights.append(allocator, false);
            } else if (c == '#') {
                try lights.append(allocator, true);
            } else {
                unreachable;
            }
        }

        var buttons_split = std.mem.splitAny(u8, row, "(");
        while (buttons_split.next()) |b| {
            const maybe_b_end = std.mem.indexOf(u8, b, ")");
            if (maybe_b_end) |b_end| {
                var lightsToChange: std.ArrayList(usize) = .empty;
                var lightsToChangeSplit = std.mem.splitAny(u8, b[0..b_end], ",");
                while (lightsToChangeSplit.next()) |l| {
                    if (l.len > 0) {
                        try lightsToChange.append(allocator, try std.fmt.parseInt(usize, l, 10));
                    }
                }

                try buttons.append(allocator, lightsToChange);
            }
        }
        try machines.append(allocator, machine{ .buttons = buttons, .lights = lights });
    }
    var iters: usize = 0;
    var total: usize = 0;
    for (machines.items) |m| {
        iters += 1;
        const res = try m.turnItOn(allocator);
        total += res;
    }

    for (0..machines.items.len) |i| {
        var m = machines.items[i];
        for (0..m.buttons.items.len) |j| {
            var b = m.buttons.items[j];
            b.clearAndFree(allocator);
        }
        m.lights.clearAndFree(allocator);
        m.buttons.clearAndFree(allocator);
    }
    machines.clearAndFree(allocator);
    return total;
}

test "day 10 step2 sample" {
    const input =
        \\[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
        \\[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
        \\[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}
    ;

    const alloc = std.heap.page_allocator;
    const res = try day10_step2(input, alloc);
    try std.testing.expectEqual(34, res);
}

test "day 10 step2 realdeal" {
    const input =
        \\[..##.#...#] (0,3,4,7,9) (0,1,9) (1,2,3,4,5) (0,1,3,7,8) (1,3,4,5,6,7,9) (0,1,2,4,5,6,7,8) (0,1,2,3,5,6,8) (1,2,4,5,8,9) (0,4,5,6,7) (0,2,3,5,8,9) (0,2,6,7,8,9) {87,70,44,58,58,67,44,54,55,54}
    ;

    const alloc = std.heap.page_allocator;
    const res = try day10_step2(input, alloc);
    try std.testing.expectEqual(34, res);
}

test "day 10 step2 sample2" {
    const input =
        \\[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
    ;

    const alloc = std.heap.page_allocator;
    const res = try day10_step2(input, alloc);
    try std.testing.expectEqual(12, res);
}
test "day 10 sample" {
    const input =
        \\[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
        \\[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
        \\[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}
    ;

    const alloc = std.heap.page_allocator;
    const res = try day10(input, alloc);
    try std.testing.expectEqual(7, res);
}
