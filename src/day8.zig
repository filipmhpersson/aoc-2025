const std = @import("std");

const Coordinate = struct {
    id: usize,
    x: isize,
    y: isize,
    z: isize,
};

const Connection = struct {
    distance: usize,
    fst: Coordinate,
    snd: Coordinate,
};
pub fn day8_readAndStart(allocator: std.mem.Allocator) !void {
    const input = try std.fs.cwd().readFileAlloc(allocator, "input/day8", 1024 * 1024);
    const result = try day8(input, allocator, 1000);
    const result_step2 = try day8_step2(input, allocator);
    std.debug.print("Day 8 '{d}' step 2 '{d}'\n", .{ result, result_step2 });
}

fn day8(input: []const u8, allocator: std.mem.Allocator, iterations: usize) !usize {
    var coordinates = try make_coordinates(input, allocator);
    defer coordinates.deinit(allocator);

    var allConnections = try make_connections_sorted(coordinates, allocator);
    defer allConnections.deinit(allocator);

    const circuit_t = std.ArrayList(usize);
    var circuits: std.ArrayList(circuit_t) = .empty;
    for (0..iterations) |i| {
        const connection = allConnections.items[i];
        var found = false;
        var fstCircuit: ?usize = null;
        var sndCircuit: ?usize = null;
        for (0..circuits.items.len) |j| {
            const c = &circuits.items[j];
            for (c.items) |cIds| {
                if (cIds == connection.fst.id) {
                    found = true;
                    fstCircuit = j;
                }

                if (cIds == connection.snd.id) {
                    sndCircuit = j;
                    found = true;
                }
            }
        }
        if (fstCircuit) |fst| {
            var c = &circuits.items[fst];
            if (sndCircuit) |snd| {
                if (fst == snd) {} else {
                    const c2 = &circuits.items[snd];
                    for (c2.*.items) |num| {
                        try c.append(allocator, num);
                    }

                    circuits.items[snd].deinit(allocator);
                    _ = circuits.orderedRemove(snd);
                }
            } else {
                try c.append(allocator, connection.snd.id);
            }
        } else if (sndCircuit) |snd| {
            var c = &circuits.items[snd];
            try c.append(allocator, connection.fst.id);
        } else {
            var circuit: std.ArrayList(usize) = .empty;
            try circuit.append(allocator, connection.fst.id);
            try circuit.append(allocator, connection.snd.id);
            try circuits.append(allocator, circuit);
        }
    }

    std.mem.sort(std.array_list.Aligned(usize, null), circuits.items, {}, cmp);
    const result = circuits.items[0].items.len * circuits.items[1].items.len * circuits.items[2].items.len;
    for (0..circuits.items.len) |i| {
        var c = circuits.items[i];

        defer c.deinit(allocator);
    }
    defer circuits.deinit(allocator);
    return result;
}

fn day8_step2(input: []const u8, allocator: std.mem.Allocator) !usize {
    var coordinates = try make_coordinates(input, allocator);
    defer coordinates.deinit(allocator);

    var allConnections = try make_connections_sorted(coordinates, allocator);
    defer allConnections.deinit(allocator);

    const circuit_t = std.ArrayList(usize);
    var circuits: std.ArrayList(circuit_t) = .empty;
    for (coordinates.items) |c| {
        var circuit: std.ArrayList(usize) = .empty;
        try circuit.append(allocator, c.id);
        try circuits.append(allocator, circuit);
    }

    var i: usize = 0;
    while (true) {
        const connection = allConnections.items[i];
        var fstCircuit: ?usize = null;
        var sndCircuit: ?usize = null;
        for (0..circuits.items.len) |j| {
            const c = &circuits.items[j];
            for (c.items) |cIds| {
                if (cIds == connection.fst.id) {
                    fstCircuit = j;
                }

                if (cIds == connection.snd.id) {
                    sndCircuit = j;
                }
            }
        }
        if (fstCircuit) |fst| {
            var c = &circuits.items[fst];
            if (sndCircuit) |snd| {
                if (fst == snd) {} else {
                    const c2 = &circuits.items[snd];
                    for (c2.*.items) |num| {
                        try c.append(allocator, num);
                    }

                    circuits.items[snd].deinit(allocator);
                    _ = circuits.orderedRemove(snd);
                }
            }
        }
        i += 1;

        if (circuits.items.len == 1) {
            for (0..circuits.items.len) |x| {
                var c = circuits.items[x];

                defer c.deinit(allocator);
            }
            defer circuits.deinit(allocator);
            return @intCast(connection.snd.x * connection.fst.x);
        }
    }

    return 0;
}

fn make_connections_sorted(coordinates: std.ArrayList(Coordinate), allocator: std.mem.Allocator) !std.ArrayList(Connection) {
    var map = std.AutoHashMap(u64, Connection).init(allocator);

    defer map.deinit();
    var allConnections: std.ArrayList(Connection) = .empty;
    for (coordinates.items) |source| {
        for (coordinates.items) |target| {
            const key = hashPair(&source, &target);
            if (map.contains(key)) {
                continue;
            }
            if (source.id == target.id) {
                continue;
            }
            const x = std.math.pow(isize, source.x - target.x, 2);
            const y = std.math.pow(isize, source.y - target.y, 2);
            const z = std.math.pow(isize, source.z - target.z, 2);

            const math: usize = @intCast(x + y + z);
            const distance = std.math.sqrt(math);
            const connection = Connection{ .distance = distance, .fst = source, .snd = target };
            try map.put(key, connection);
            try allConnections.append(allocator, connection);
        }
    }

    std.mem.sort(Connection, allConnections.items, {}, struct {
        fn lessThan(_: void, a: Connection, b: Connection) bool {
            return a.distance < b.distance;
        }
    }.lessThan);
    return allConnections;
}

pub fn make_coordinates(input: []const u8, allocator: std.mem.Allocator) !std.ArrayList(Coordinate) {
    var split = std.mem.splitAny(u8, input, "\n");
    var coordinates: std.ArrayList(Coordinate) = .empty;
    var coordinateId: usize = 0;
    while (split.next()) |row| {
        if (row.len == 0) {
            break;
        }

        var numbers = std.mem.splitAny(u8, row, ",");

        const coordinate = Coordinate{
            .id = coordinateId,
            .x = try std.fmt.parseInt(isize, numbers.next().?, 10),
            .y = try std.fmt.parseInt(isize, numbers.next().?, 10),
            .z = try std.fmt.parseInt(isize, numbers.next().?, 10),
        };
        coordinateId += 1;
        try coordinates.append(allocator, coordinate);
    }
    return coordinates;
}

fn cmp(_: void, a: std.array_list.Aligned(usize, null), b: std.array_list.Aligned(usize, null)) bool {
    return a.items.len > b.items.len;
}

pub fn hashPair(foo1: *const Coordinate, foo2: *const Coordinate) u64 {
    var hasher = std.hash.Wyhash.init(0);
    if (foo1.id > foo2.id) {
        hasher.update(std.mem.asBytes(foo1));
        hasher.update(std.mem.asBytes(foo2));
    } else {
        hasher.update(std.mem.asBytes(foo2));
        hasher.update(std.mem.asBytes(foo1));
    }
    return hasher.final();
}

test "day 8 sample" {
    const input =
        \\162,817,812
        \\57,618,57
        \\906,360,560
        \\592,479,940
        \\352,342,300
        \\466,668,158
        \\542,29,236
        \\431,825,988
        \\739,650,466
        \\52,470,668
        \\216,146,977
        \\819,987,18
        \\117,168,530
        \\805,96,715
        \\346,949,466
        \\970,615,88
        \\941,993,340
        \\862,61,35
        \\984,92,344
        \\425,690,689
    ;
    const result = try day8(input, std.testing.allocator, 10);
    try std.testing.expectEqual(40, result);
}

test "day 8 sample step 2" {
    const input =
        \\162,817,812
        \\57,618,57
        \\906,360,560
        \\592,479,940
        \\352,342,300
        \\466,668,158
        \\542,29,236
        \\431,825,988
        \\739,650,466
        \\52,470,668
        \\216,146,977
        \\819,987,18
        \\117,168,530
        \\805,96,715
        \\346,949,466
        \\970,615,88
        \\941,993,340
        \\862,61,35
        \\984,92,344
        \\425,690,689
    ;
    const result = try day8_step2(input, std.testing.allocator);
    try std.testing.expectEqual(25272, result);
}
