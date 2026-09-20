const std = @import("std");

const Coordinate = struct { x: u32, y: u32 };

pub fn day9_readAndStart(allocator: std.mem.Allocator) !void {
    const input = try std.fs.cwd().readFileAlloc(allocator, "input/day9", 1024 * 1024);
    const result = try day9(input, allocator);
    const result_ste2 = try day9_step2_test2(input, allocator);
    std.debug.print("Day 9 result '{d}' step 2 '{d}'\n", .{ result, result_ste2 });
}

fn day9(input: []const u8, allocator: std.mem.Allocator) !usize {
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
            .x = try std.fmt.parseInt(u32, x.?, 10),
            .y = try std.fmt.parseInt(u32, y.?, 10),
        });
    }

    var biggestBox: usize = 0;
    for (coordinates.items[0 .. coordinates.items.len - 1], 0..) |source, i| {
        for (i + 1..coordinates.items.len - 1) |j| {
            const target = coordinates.items[j];

            const dir = getCompassDirection(source, target);
            var height: usize = 0;
            var width: usize = 0;
            switch (dir) {
                .SE => {
                    height = target.y - source.y + 1;
                    width = target.x - source.x + 1;
                },
                .NE => {
                    width = target.x - source.x + 1;
                    height = source.y - target.y + 1;
                },
                .SW => {
                    width = source.x - target.x + 1;
                    height = target.y - source.y + 1;
                },
                .NW => {
                    width = source.x - target.x + 1;
                    height = source.y - target.y + 1;
                },
                .S => {
                    width = 1;
                    height = target.y - source.y + 1;
                },
                .N => {
                    width = 1;
                    height = source.y - target.y + 1;
                },
                .E => {
                    height = 1;
                    width = target.x - source.x + 1;
                },
                .W => {
                    height = 1;
                    width = source.x - target.x + 1;
                },
            }

            const res = height * width;
            if (res > biggestBox) {
                biggestBox = res;
            }
        }
    }
    return biggestBox;
}
const L = struct {
    data: Coordinate,
    node: std.DoublyLinkedList.Node = .{},
};
fn day9_step2_test2(input: []const u8, allocator: std.mem.Allocator) !usize {
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
            .x = try std.fmt.parseInt(u32, x.?, 10),
            .y = try std.fmt.parseInt(u32, y.?, 10),
        };

        try coordinates.append(allocator, coordinate);

        const node_ptr = try allocator.create(L);
        node_ptr.*.data = coordinate;
        list.append(&node_ptr.*.node);
    }

    var it = list.first;
    var result: usize = 0;
    var index: usize = 1;
    const len = list.len();
    while (it) |node| : (it = node.next) {
        if (len == index - 1) {
            break;
        }
        const l: *L = @fieldParentPtr("node", node);
        const source = l.data;
        for (index..coordinates.items.len) |j| {
            const target = coordinates.items[j];
            const rect = getRect(l.data, target);

            if (!polygonPiercesRect(rect, coordinates.items) and rectCornersInsideOrOn(rect, coordinates.items)) {
                const dir = getCompassDirection(l.data, target);
                var height: usize = 0;
                var width: usize = 0;
                switch (dir) {
                    .SE => {
                        height = target.y - source.y + 1;
                        width = target.x - source.x + 1;
                    },
                    .NE => {
                        width = target.x - source.x + 1;
                        height = source.y - target.y + 1;
                    },
                    .SW => {
                        width = source.x - target.x + 1;
                        height = target.y - source.y + 1;
                    },
                    .NW => {
                        width = source.x - target.x + 1;
                        height = source.y - target.y + 1;
                    },
                    .S => {
                        width = 1;
                        height = target.y - source.y + 1;
                    },
                    .N => {
                        width = 1;
                        height = source.y - target.y + 1;
                    },
                    .E => {
                        height = 1;
                        width = target.x - source.x + 1;
                    },
                    .W => {
                        height = 1;
                        width = source.x - target.x + 1;
                    },
                }

                const res = height * width;
                if (res > result) {
                    std.debug.print("FOUND RES {d} in {any} to {any} dir={any}\n", .{ res, l.data, target, dir });
                    result = res;
                }
            }
        }
        index += 1;
    }
    var current = list.last;
    while (current) |node| {
        const next = node.prev;
        const item: *L = @fieldParentPtr("node", node);
        allocator.destroy(item);
        current = next;
    }

    return result;
}
fn rectHasInteriorPointInside(rect: Rect, coords: []const Coordinate) bool {
    const xmin = rect.topLeft.x;
    const xmax = rect.topRight.x;
    const ymin = rect.topLeft.y; // depending on your coordinate orientation
    const ymax = rect.bottomLeft.y;
    if (xmin == xmax or ymin == ymax) {
        // If degenerate rectangles are allowed, decide rules; easiest: treat as false or handle separately.
        return false;
    }
    const PX: i64 = @as(i64, xmin) * 2 + 1;
    const PY: i64 = @as(i64, ymin) * 2 + 1;
    return pointInPolyDoubled(PX, PY, coords);
}

fn pointOnSegmentDoubled(PX: i64, PY: i64, ax: u32, ay: u32, bx: u32, by: u32) bool {
    const AX: i64 = @as(i64, ax) * 2;
    const AY: i64 = @as(i64, ay) * 2;
    const BX: i64 = @as(i64, bx) * 2;
    const BY: i64 = @as(i64, by) * 2;

    if (AX == BX) { // vertical
        if (PX != AX) return false;
        const lo = @min(AY, BY);
        const hi = @max(AY, BY);
        return lo <= PY and PY <= hi;
    } else { // horizontal
        if (PY != AY) return false;
        const lo = @min(AX, BX);
        const hi = @max(AX, BX);
        return lo <= PX and PX <= hi;
    }
}
fn rectCornersInsideOrOn(rect: Rect, coords: []const Coordinate) bool {
    const corners = [_]Coordinate{ rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight };
    for (corners) |c| {
        const PX: i64 = @as(i64, c.x) * 2;
        const PY: i64 = @as(i64, c.y) * 2;
        if (!pointInPolyDoubled(PX, PY, coords)) return false;
    }
    return true;
}

fn pointInPolyDoubled(PX: i64, PY: i64, coords: []const Coordinate) bool {
    // Boundary check first
    var i: usize = 0;
    while (i < coords.len) : (i += 1) {
        const p = coords[i];
        const q = coords[(i + 1) % coords.len];
        if (pointOnSegmentDoubled(PX, PY, p.x, p.y, q.x, q.y)) return true;
    }

    var crossings: usize = 0;
    i = 0;
    while (i < coords.len) : (i += 1) {
        const p = coords[i];
        const q = coords[(i + 1) % coords.len];

        // Count only vertical edges for horizontal ray cast
        if (p.x == q.x) {
            const ex: i64 = @as(i64, p.x) * 2;
            var y1: i64 = @as(i64, p.y) * 2;
            var y2: i64 = @as(i64, q.y) * 2;
            if (y1 > y2) std.mem.swap(i64, &y1, &y2);

            // Half-open in y: [y1, y2)
            if (y1 <= PY and PY < y2) {
                if (ex > PX) crossings += 1;
            }
        }
    }

    return (crossings & 1) == 1;
}
fn rectBounds(rect: Rect) struct { xmin: u32, xmax: u32, ymin: u32, ymax: u32 } {
    const xmin = @min(rect.topLeft.x, rect.bottomLeft.x);
    const xmax = @max(rect.topRight.x, rect.bottomRight.x);
    const ymin = @min(rect.topLeft.y, rect.topRight.y);
    const ymax = @max(rect.bottomLeft.y, rect.bottomRight.y);
    return .{ .xmin = xmin, .xmax = xmax, .ymin = ymin, .ymax = ymax };
}
fn polygonPiercesRect(rect: Rect, coords: []const Coordinate) bool {
    const b = rectBounds(rect);
    const xmin = b.xmin;
    const xmax = b.xmax;
    const ymin = b.ymin;
    const ymax = b.ymax;

    // Degenerate rectangles: if line/point rectangles are allowed, handle separately.
    if (xmin == xmax or ymin == ymax) return false;

    var i: usize = 0;
    while (i < coords.len) : (i += 1) {
        const p = coords[i];
        const q = coords[(i + 1) % coords.len];

        if (p.x == q.x) { // vertical edge
            const ex = p.x;
            const ey1 = @min(p.y, q.y);
            const ey2 = @max(p.y, q.y);

            if (xmin < ex and ex < xmax) {
                if (@max(ey1, ymin) < @min(ey2, ymax)) return true;
            }
        } else { // horizontal edge
            const ey = p.y;
            const ex1 = @min(p.x, q.x);
            const ex2 = @max(p.x, q.x);

            if (ymin < ey and ey < ymax) {
                if (@max(ex1, xmin) < @min(ex2, xmax)) return true;
            }
        }
    }
    return false;
}

fn findStart(node: *const L, source: Coordinate) ?*const L {
    if (node.*.data.x == source.x and node.*.data.y == source.y) {
        return node;
    }
    var nxt = node.*.node.next;
    while (nxt) |n| : (nxt = n.next) {
        const l: *L = @fieldParentPtr("node", n);
        if (l.*.data.x == source.x and l.*.data.y == source.y) {
            return l;
        }
    }

    var back = node.*.node.prev;
    while (back) |b| : (back = b.prev) {
        const l: *L = @fieldParentPtr("node", b);
        if (l.*.data.x == source.x and l.*.data.y == source.y) {
            return l;
        }
    }

    return null;
}

fn walkToTarget(node: *const L, source: Coordinate, target: Coordinate, list: std.DoublyLinkedList) bool {
    const expected = getCompassDirection(source, target);
    switch (expected) {
        .N, .S, .W, .E => {
            var it = node.*.node.next;
            if (it == null) {
                it = list.first;
            }
            const l: *L = @fieldParentPtr("node", it.?);
            // std.debug.print("HERE {any} to {any}\n", .{ l.data, target });
            if (is_same(&l.*.data, &target)) return true;
            // std.debug.print("HERE ??\n", .{});

            var back = node.*.node.prev;
            if (back == null) {
                back = list.last;
            }
            const backCord: *L = @fieldParentPtr("node", back.?);
            return is_same(&backCord.*.data, &target);
        },
        else => {},
    }

    var next = node.*.node.next;
    if (next == null) {
        next = list.first;
    }
    const next_l: *L = @fieldParentPtr("node", next.?);
    const nextD = getCompassDirection(source, next_l.data);
    var back = node.*.node.prev;
    if (back == null) {
        back = list.last;
    }

    switch (expected) {
        .NE => {
            switch (nextD) {
                .N => {
                    const canWalk = canWalkToTarget(
                        node,
                        target,
                        compassDirection.N,
                        compassDirection.E,
                        list,
                        walkForward,
                    );
                    if (!canWalk) {
                        return false;
                    }

                    return canWalkToTarget(
                        node,
                        target,
                        compassDirection.E,
                        compassDirection.N,
                        list,
                        walkBackward,
                    );
                },
                .E => {
                    const canWalk = canWalkToTarget(
                        node,
                        target,
                        compassDirection.E,
                        compassDirection.N,
                        list,
                        walkForward,
                    );
                    if (!canWalk) {
                        return false;
                    }

                    return canWalkToTarget(
                        node,
                        target,
                        compassDirection.N,
                        compassDirection.E,
                        list,
                        walkBackward,
                    );
                },
                else => return false,
            }
        },
        .SE => {
            switch (nextD) {
                .S => {
                    const canWalk = canWalkToTarget(
                        node,
                        target,
                        compassDirection.S,
                        compassDirection.E,
                        list,
                        walkForward,
                    );
                    if (!canWalk) {
                        return false;
                    }

                    return canWalkToTarget(
                        node,
                        target,
                        compassDirection.E,
                        compassDirection.S,
                        list,
                        walkBackward,
                    );
                },
                .E => {
                    const canWalk = canWalkToTarget(
                        node,
                        target,
                        compassDirection.E,
                        compassDirection.S,
                        list,
                        walkForward,
                    );
                    if (!canWalk) {
                        return false;
                    }

                    return canWalkToTarget(
                        node,
                        target,
                        compassDirection.S,
                        compassDirection.E,
                        list,
                        walkBackward,
                    );
                },
                else => return false,
            }
        },
        .SW => {
            switch (nextD) {
                .S => {
                    const canWalk = canWalkToTarget(
                        node,
                        target,
                        compassDirection.S,
                        compassDirection.W,
                        list,
                        walkForward,
                    );
                    // std.debug.print("CAN WALK {any} SW S\n", .{canWalk});
                    if (!canWalk) {
                        return false;
                    }

                    const r = canWalkToTarget(
                        node,
                        target,
                        compassDirection.W,
                        compassDirection.S,
                        list,
                        walkBackward,
                    );

                    // std.debug.print("CAN WALK {any} from {any} TO {any} DIR W\n", .{ node.data, target, r });
                    return r;
                },
                .W => {
                    const canWalk = canWalkToTarget(
                        node,
                        target,
                        compassDirection.W,
                        compassDirection.S,
                        list,
                        walkForward,
                    );
                    if (!canWalk) {
                        return false;
                    }

                    return canWalkToTarget(
                        node,
                        target,
                        compassDirection.S,
                        compassDirection.W,
                        list,
                        walkBackward,
                    );
                },
                else => return false,
            }
        },
        .NW => {
            switch (nextD) {
                .N => {
                    const canWalk = canWalkToTarget(
                        node,
                        target,
                        compassDirection.N,
                        compassDirection.W,
                        list,
                        walkForward,
                    );
                    // std.debug.print("CAN WALK {any} NW N\n", .{canWalk});
                    if (!canWalk) {
                        return false;
                    }

                    return canWalkToTarget(
                        node,
                        target,
                        compassDirection.W,
                        compassDirection.N,
                        list,
                        walkBackward,
                    );
                },

                .W => {
                    const canWalk = canWalkToTarget(
                        node,
                        target,
                        compassDirection.W,
                        compassDirection.N,
                        list,
                        walkForward,
                    );
                    // std.debug.print("CAN WALK {any} NW W\n", .{canWalk});
                    if (!canWalk) {
                        return false;
                    }

                    return canWalkToTarget(
                        node,
                        target,
                        compassDirection.N,
                        compassDirection.W,
                        list,
                        walkBackward,
                    );
                },
                else => return false,
            }
        },
        else => {},
    }
    unreachable;
}

fn walkBackward(node: *const L, list: std.DoublyLinkedList) *L {
    const next = node.node.prev;
    if (next != null) {
        return @fieldParentPtr("node", next.?);
    } else {
        return @fieldParentPtr("node", list.last.?);
    }
}
fn walkForward(node: *const L, list: std.DoublyLinkedList) *L {
    const next = node.node.next;
    if (next != null) {
        return @fieldParentPtr("node", next.?);
    } else {
        return @fieldParentPtr("node", list.first.?);
    }
}

const Rect = struct { topRight: Coordinate, topLeft: Coordinate, bottomRight: Coordinate, bottomLeft: Coordinate };
fn getRect(from: Coordinate, to: Coordinate) Rect {
    const dir = getCompassDirection(from, to);
    switch (dir) {
        .S => {
            return Rect{
                .topLeft = from,
                .topRight = from,
                .bottomLeft = to,
                .bottomRight = to,
            };
        },
        .E => {
            return Rect{
                .topLeft = from,
                .topRight = to,
                .bottomLeft = from,
                .bottomRight = to,
            };
        },
        .W => {
            return Rect{
                .topLeft = to,
                .topRight = from,
                .bottomLeft = to,
                .bottomRight = from,
            };
        },
        .N => {
            return Rect{
                .topLeft = to,
                .topRight = to,
                .bottomLeft = from,
                .bottomRight = from,
            };
        },
        .NE => {
            return Rect{
                .topLeft = Coordinate{ .y = to.y, .x = from.x },
                .topRight = to,
                .bottomLeft = from,
                .bottomRight = Coordinate{ .x = to.x, .y = from.y },
            };
        },
        .SE => {
            return Rect{
                .topLeft = from,
                .topRight = Coordinate{ .y = from.y, .x = to.x },
                .bottomLeft = Coordinate{ .y = to.y, .x = from.x },
                .bottomRight = to,
            };
        },
        .SW => {
            return Rect{
                .topLeft = Coordinate{ .y = from.y, .x = to.x },
                .topRight = from,
                .bottomLeft = to,
                .bottomRight = Coordinate{ .y = to.y, .x = from.x },
            };
        },
        .NW => {
            return Rect{
                .topLeft = to,
                .topRight = Coordinate{ .x = from.x, .y = to.y },
                .bottomLeft = Coordinate{ .x = to.x, .y = from.y },
                .bottomRight = from,
            };
        },
    }
}

fn canWalkToTarget(
    node: *const L,
    target: Coordinate,
    dir: compassDirection,
    sndDir: compassDirection,
    list: std.DoublyLinkedList,
    comptime f: fn (*const L, std.DoublyLinkedList) *L,
) bool {
    var boundingValidated = false;
    var prevCoord = node.data;

    const source = node.data;
    const rect = getRect(source, target);
    var next = f(node, list);
    while (true) {
        const l: *L = next;

        if (is_same(&l.data, &target)) {
            if (!boundingValidated) {
                return false;
            } else {
                return true;
            }
        }
        if (l.data.x > rect.topLeft.x and l.data.x < rect.topRight.x and l.data.y > rect.topRight.y and l.data.y < rect.bottomLeft.y) {
            return false;
        }

        switch (dir) {
            // # # # X # T
            // # # # # # #
            // # # # S # Y
            .N => {
                const compareCord = Coordinate{
                    .y = target.y,
                    .x = source.x,
                };

                if (is_same(&l.data, &compareCord)) {
                    boundingValidated = true;
                }

                // std.debug.print("WALKING FROM {any} to {any}\n", .{ source, compareCord });
                switch (sndDir) {
                    .W => {
                        // # # # X # T
                        // # # # # # #
                        // # # # S # Y
                        //
                        if (l.data.y == target.y and l.data.x >= source.x) {
                            // std.debug.print("FOUND DIRECT MATCH\n", .{});
                            boundingValidated = true;
                        } else if (l.data.x >= source.x and l.data.y > target.y and prevCoord.y < target.y) {
                            // std.debug.print("walked past\n", .{});
                            boundingValidated = true;
                        } else if (l.data.x >= source.x and l.data.y < target.y and prevCoord.y > target.y) {
                            // std.debug.print("reverse walked past {any} matches x {d} y {d}\n", .{ l.data, source.x, target.y });
                            boundingValidated = true;
                        }
                    },
                    .E => {
                        if ((l.data.y == target.y and l.data.x <= source.x) or
                            (l.data.x <= source.x and l.data.y > target.y and prevCoord.y < target.y) or
                            (l.data.x <= source.x and l.data.y < target.y and prevCoord.y > target.y))
                            boundingValidated = true;
                    },
                    else => unreachable,
                }
            },

            .S => {
                const compareCord = Coordinate{ .y = target.y, .x = source.x };
                if (is_same(&l.data, &compareCord)) {
                    boundingValidated = true;
                }

                switch (sndDir) {
                    .W => {
                        if ((l.data.y == target.y and l.data.x <= source.x) or
                            (l.data.x >= source.x and l.data.y > target.y and prevCoord.y < target.y) or
                            (l.data.x >= source.x and l.data.y < target.y and prevCoord.y > target.y))
                            boundingValidated = true;
                    },
                    .E => {
                        if ((l.data.y == target.y and l.data.x <= source.x) or
                            (l.data.x <= source.x and l.data.y > target.y and prevCoord.y < target.y) or
                            (l.data.x <= source.x and l.data.y < target.y and prevCoord.y > target.y))
                            boundingValidated = true;
                    },
                    else => unreachable,
                }
            },
            // # # # S # Y
            // # # # # # #
            // # # # X # T
            .E, .W => {
                const compareCord = Coordinate{ .y = source.y, .x = target.x };
                if (is_same(&l.data, &compareCord)) {
                    boundingValidated = true;
                }

                // std.debug.print("{any} WALKING FROM source {any} cur {any} to {any}\n", .{ dir, source, l.data, compareCord });
                switch (sndDir) {
                    .N => {
                        if (l.data.x == target.x and l.data.y >= source.y) {
                            // std.debug.print("FOUND DIRECT MATCH\n", .{});
                            boundingValidated = true;
                        } else if (l.data.y >= source.y and l.data.x > target.x and prevCoord.x < target.x) {
                            // std.debug.print("FOUND overarching MATCH\n", .{});
                            boundingValidated = true;
                        } else if (l.data.y >= source.y and l.data.x < target.x and prevCoord.x > target.x) {
                            // std.debug.print("FOUND reverse MATCH\n", .{});
                            boundingValidated = true;
                        }
                    },
                    .S => {
                        if ((l.data.x == target.x and l.data.y <= source.y) or
                            (l.data.y <= source.y and l.data.x > target.x and prevCoord.x < target.x) or
                            (l.data.y <= source.y and l.data.x < target.x and prevCoord.x > target.x))
                            boundingValidated = true;
                    },
                    else => unreachable,
                }
            },
            else => unreachable,
        }

        prevCoord = l.data;
        next = f(l, list);
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

test "day 9 sample step2" {
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

    const result = try (day9_step2_test2(input, std.testing.allocator));
    try std.testing.expectEqual(24, result);
}

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
        .{ .source = Coordinate{ .x = 2, .y = 5 }, .target = Coordinate{ .x = 7, .y = 3 }, .expected = compassDirection.NE },
    };

    for (input) |t| {
        const res = getCompassDirection(t.source, t.target);
        try std.testing.expectEqual(t.expected, res);
    }
}

test "day 9 walk tests" {
    const input = [_]struct { source: Coordinate, target: Coordinate, res: bool }{
        .{
            .source = Coordinate{ .x = 2, .y = 5 },
            .target = Coordinate{ .x = 7, .y = 3 },
            .res = true,
        },

        .{
            .source = Coordinate{ .x = 7, .y = 1 },
            .target = Coordinate{ .x = 11, .y = 1 },
            .res = true,
        },

        // Adjacent on same column (X=7)
        .{ .source = Coordinate{ .x = 7, .y = 1 }, .target = Coordinate{ .x = 7, .y = 3 }, .res = true },

        // (9,5) to (2,3): same rectangle as (2,5)→(7,3) but different corners - Area=24
        .{ .source = Coordinate{ .x = 9, .y = 5 }, .target = Coordinate{ .x = 2, .y = 3 }, .res = true },
        .{ .source = Coordinate{ .x = 2, .y = 3 }, .target = Coordinate{ .x = 9, .y = 5 }, .res = true },

        // Adjacent on same column (X=9)
        .{ .source = Coordinate{ .x = 9, .y = 7 }, .target = Coordinate{ .x = 9, .y = 5 }, .res = true },

        // (2,3) to (9,5): valid rectangle
        .{ .source = Coordinate{ .x = 2, .y = 3 }, .target = Coordinate{ .x = 9, .y = 5 }, .res = true },

        .{
            .source = Coordinate{ .x = 2, .y = 5 },
            .target = Coordinate{ .x = 11, .y = 1 },
            .res = false,
        },

        .{
            .source = Coordinate{ .x = 2, .y = 5 },
            .target = Coordinate{ .x = 9, .y = 7 },
            .res = false,
        },

        .{
            .source = Coordinate{ .x = 7, .y = 1 },
            .target = Coordinate{ .x = 11, .y = 7 },
            .res = false,
        },

        .{
            .source = Coordinate{ .x = 2, .y = 3 },
            .target = Coordinate{ .x = 11, .y = 7 },
            .res = false,
        },

        .{
            .source = Coordinate{ .x = 11, .y = 1 },
            .target = Coordinate{ .x = 2, .y = 5 },
            .res = false,
        },

        .{
            .source = Coordinate{ .x = 11, .y = 7 },
            .target = Coordinate{ .x = 7, .y = 3 },
            .res = false,
        },
        .{
            .source = Coordinate{ .x = 7, .y = 3 },
            .target = Coordinate{ .x = 11, .y = 7 },
            .res = false,
        },
    };

    var h: L = .{ .data = Coordinate{ .x = 7, .y = 3 } };
    var a: L = .{ .data = Coordinate{ .x = 7, .y = 1 } };
    var b: L = .{ .data = Coordinate{ .x = 11, .y = 1 } };
    var c: L = .{ .data = Coordinate{ .x = 11, .y = 7 } };
    var d: L = .{ .data = Coordinate{ .x = 9, .y = 7 } };
    var e: L = .{ .data = Coordinate{ .x = 9, .y = 5 } };
    var f: L = .{ .data = Coordinate{ .x = 2, .y = 5 } };
    var g: L = .{ .data = Coordinate{ .x = 2, .y = 3 } };
    var list: std.DoublyLinkedList = .{};

    list.append(&a.node);
    list.append(&b.node);
    list.append(&c.node);
    list.append(&d.node);
    list.append(&e.node);
    list.append(&f.node);
    list.append(&g.node);
    list.append(&h.node);

    std.debug.print("LIST {d}\n", .{list.len()});
    for (input) |t| {
        const first = list.first.?;
        const l: *L = @fieldParentPtr("node", first);
        const start = findStart(l, t.source);
        const res = walkToTarget(start.?, t.source, t.target, list);
        try std.testing.expectEqual(t.res, res);
    }
}

test "day 9 special walk tests" {
    // Polygon: 7,1 → 11,1 → 11,7 → 9,7 → 9,5 → 2,5 → 2,3 → 7,3 → (back to 7,1)
    //
    // Visual (X is horizontal, Y is vertical, origin top-left):
    //   Y=1:  .......#...#..   (7,1) and (11,1)
    //   Y=3:  ..#....#......   (2,3) and (7,3)
    //   Y=5:  ..#......#....   (2,5) and (9,5)
    //   Y=7:  .........#.#..   (9,7) and (11,7)
    //
    const input = [_]struct { source: Coordinate, target: Coordinate, res: bool }{
        // === VALID CASES ===
        // (2,5) to (7,3): Area=24, the answer for part 2 sample
        // Forward: 2,5 → 2,3 → 7,3 ✓ stays in x:[2,7], y:[3,5]
        // Backward: 2,5 → 9,5 → ... but we only need one valid path
        // j

        .{
            .source = Coordinate{ .x = 1, .y = 3 },
            .target = Coordinate{ .x = 5, .y = 5 },
            .res = false,
        },

        .{
            .source = Coordinate{ .x = 5, .y = 5 },
            .target = Coordinate{ .x = 1, .y = 3 },
            .res = false,
        },
        .{
            .source = Coordinate{ .x = 1, .y = 3 },
            .target = Coordinate{ .x = 5, .y = 2 },
            .res = false,
        },
    };

    //         \\7,1
    //         \\11,1
    //         \\11,7
    //         \\9,7
    //         \\9,5
    //         \\2,5
    //         \\2,3
    //         \\7,3
    var a: L = .{ .data = Coordinate{ .x = 1, .y = 3 } };
    var b: L = .{ .data = Coordinate{ .x = 2, .y = 3 } };
    var c: L = .{ .data = Coordinate{ .x = 2, .y = 4 } };
    var d: L = .{ .data = Coordinate{ .x = 3, .y = 4 } };
    var e: L = .{ .data = Coordinate{ .x = 3, .y = 2 } };
    var f: L = .{ .data = Coordinate{ .x = 5, .y = 2 } };
    var g: L = .{ .data = Coordinate{ .x = 5, .y = 5 } };
    var h: L = .{ .data = Coordinate{ .x = 1, .y = 5 } };
    var list: std.DoublyLinkedList = .{};

    list.append(&a.node);
    list.append(&b.node);
    list.append(&c.node);
    list.append(&d.node);
    list.append(&e.node);
    list.append(&f.node);
    list.append(&g.node);
    list.append(&h.node);

    std.debug.print("LIST {d}\n", .{list.len()});
    for (input) |t| {
        const first = list.first.?;
        const l: *L = @fieldParentPtr("node", first);
        const start = findStart(l, t.source);
        const res = walkToTarget(start.?, t.source, t.target, list);
        try std.testing.expectEqual(t.res, res);
    }
}

test "day 9 special walk tests two" {
    // Polygon: 7,1 → 11,1 → 11,7 → 9,7 → 9,5 → 2,5 → 2,3 → 7,3 → (back to 7,1)
    //
    // Visual (X is horizontal, Y is vertical, origin top-left):
    //   Y=1:  .......#...#..   (7,1) and (11,1)
    //   Y=3:  ..#....#......   (2,3) and (7,3)
    //   Y=5:  ..#......#....   (2,5) and (9,5)
    //   Y=7:  .........#.#..   (9,7) and (11,7)
    //
    const input = [_]struct { source: Coordinate, target: Coordinate, res: bool }{
        .{
            .source = Coordinate{ .x = 1, .y = 5 },
            .target = Coordinate{ .x = 5, .y = 2 },
            .res = false,
        },
    };
    var a: L = .{ .data = Coordinate{ .x = 1, .y = 3 } };
    var b: L = .{ .data = Coordinate{ .x = 2, .y = 3 } };
    var c: L = .{ .data = Coordinate{ .x = 2, .y = 4 } };
    var d: L = .{ .data = Coordinate{ .x = 3, .y = 4 } };
    var e: L = .{ .data = Coordinate{ .x = 3, .y = 2 } };
    var f: L = .{ .data = Coordinate{ .x = 5, .y = 2 } };
    var g: L = .{ .data = Coordinate{ .x = 5, .y = 5 } };
    var h: L = .{ .data = Coordinate{ .x = 1, .y = 5 } };
    var list: std.DoublyLinkedList = .{};

    list.append(&a.node);
    list.append(&b.node);
    list.append(&c.node);
    list.append(&d.node);
    list.append(&e.node);
    list.append(&f.node);
    list.append(&g.node);
    list.append(&h.node);

    std.debug.print("LIST {d}\n", .{list.len()});
    for (input) |t| {
        const first = list.first.?;
        const l: *L = @fieldParentPtr("node", first);
        const start = findStart(l, t.source);
        std.debug.print("DIR {any}\n", .{getCompassDirection(t.source, t.target)});
        const res = walkToTarget(start.?, t.source, t.target, list);
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
