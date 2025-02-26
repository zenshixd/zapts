const std = @import("std");
const FileSource = std.build.FileSource;

pub const BuildConfig = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.Mode,
    filter: ?[]const u8,
};

pub fn build(b: *std.Build) void {
    const config = getBuildConfig(b);

    addZaptsExe(b, config);
    addUnitTests(b, config);
    addRefTests(b, config);
}

fn getBuildConfig(b: *std.Build) BuildConfig {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    return BuildConfig{
        .target = target,
        .optimize = optimize,
        .filter = b.option([]const u8, "filter", "Filter tests to run"),
    };
}

fn addZaptsExe(b: *std.Build, config: BuildConfig) void {
    const exe = b.addExecutable(.{
        .name = "zapts",
        .root_source_file = b.path("src/main.zig"),
        .target = config.target,
        .optimize = config.optimize,
    });

    b.installArtifact(exe);

    const run = b.addRunArtifact(exe);
    run.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run.addArgs(args);
    }

    const step = b.step("run", "Run the app");
    step.dependOn(&run.step);
}

fn addUnitTests(b: *std.Build, config: BuildConfig) void {
    var test_name = std.ArrayList(u8).init(std.heap.page_allocator);
    defer test_name.deinit();

    if (config.filter) |filter| {
        test_name.appendSlice("test_") catch unreachable;
        test_name.appendSlice(filter) catch unreachable;
    } else {
        test_name.appendSlice("test") catch unreachable;
    }

    std.mem.replaceScalar(u8, test_name.items, ' ', '_');

    const clean_coverage = b.addSystemCommand(&.{
        "rm",
        "-rf",
        b.pathJoin(&.{ b.build_root.path.?, "lcov-report" }),
    });
    const exe = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .name = test_name.items,
        .target = config.target,
        .optimize = config.optimize,
        .test_runner = .{
            .path = b.path("src/tests/unit_tests_runner.zig"),
            .mode = .simple,
        },
        .filter = config.filter,
    });

    const run = b.addSystemCommand(&.{
        "kcov",
        "--clean",
        "--include-pattern=src",
        b.pathJoin(&.{ b.build_root.path.?, "lcov-report" }),
    });
    run.addArtifactArg(exe);

    if (b.option(bool, "update", "Update snapshots")) |_| {
        run.setEnvironmentVariable("ZAPTS_SNAPSHOT_UPDATE", "1");
    }

    const step = b.step("test", "Run unit tests");
    step.dependOn(&clean_coverage.step);
    step.dependOn(&run.step);
}

fn addRefTests(b: *std.Build, config: BuildConfig) void {
    var test_name = std.ArrayList(u8).init(std.heap.page_allocator);
    defer test_name.deinit();

    if (config.filter) |filter| {
        test_name.appendSlice("reftest_") catch unreachable;
        test_name.appendSlice(filter) catch unreachable;
    } else {
        test_name.appendSlice("reftest") catch unreachable;
    }
    std.mem.replaceScalar(u8, test_name.items, ' ', '_');

    const exe = b.addTest(.{
        .name = test_name.items,
        .root_source_file = b.path("src/tests/ref_tests_runner.zig"),
        .target = config.target,
        .optimize = config.optimize,
        .test_runner = .{
            .path = b.path("src/tests/ref_tests_runner.zig"),
            .mode = .simple,
        },
        .filter = config.filter,
    });
    exe.root_module.addImport("zapts", b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
    }));

    const run = b.addRunArtifact(exe);

    const step = b.step("test:ref", "Run reference tests");
    step.dependOn(&run.step);
}
