const std = @import("std");
const FileSource = std.build.FileSource;

pub fn build(b: *std.Build) void {
    const gpa = std.heap.page_allocator;
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const zapts_module = b.addModule("zapts", .{
        .root_source_file = b.path("src/compile.zig"),
    });

    const exe = b.addExecutable(.{
        .name = "zapts",
        .root_source_file = zapts_module.root_source_file,
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const maybe_filter = b.option([]const u8, "filter", "Filter tests to run");
    const test_name = if (maybe_filter) |filter|
        std.mem.replaceOwned(u8, gpa, filter, " ", "_") catch @panic("oom")
    else
        "test";
    defer {
        if (maybe_filter) |_| {
            gpa.free(test_name);
        }
    }
    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .name = test_name,
        .target = target,
        .optimize = optimize,
        .test_runner = .{
            .path = b.path("src/tests/unit_tests_runner.zig"),
            .mode = .simple,
        },
        .filter = maybe_filter,
    });

    const run_unit_tests = b.addSystemCommand(&.{
        "kcov",
        "--clean",
        "--include-pattern=src",
        b.pathJoin(&.{ b.build_root.path.?, "lcov-report" }),
    });
    run_unit_tests.addArtifactArg(exe_unit_tests);

    if (b.option(bool, "update", "Update snapshots")) |_| {
        run_unit_tests.setEnvironmentVariable("ZAPTS_SNAPSHOT_UPDATE", "1");
    }

    const unit_tests_step = b.step("test", "Run unit tests");
    unit_tests_step.dependOn(&run_unit_tests.step);

    const run_test_artifact_path = b.addSystemCommand(&.{
        "echo",
    });
    run_test_artifact_path.addArtifactArg(exe_unit_tests);

    const test_artifact_path_step = b.step("test:artifact", "Print test artifact path");
    test_artifact_path_step.dependOn(&run_test_artifact_path.step);

    const compile_tests = b.addTest(.{
        .root_source_file = b.path("tests/e2e_tests_runner.zig"),
        .target = target,
        .optimize = optimize,
        .test_runner = .{
            .path = b.path("tests/e2e_tests_runner.zig"),
            .mode = .simple,
        },
    });
    compile_tests.root_module.addImport("zapts", zapts_module);

    const run_compile_tests = b.addRunArtifact(compile_tests);

    const compile_tests_step = b.step("test:compiler", "Run local compiler tests");
    compile_tests_step.dependOn(&run_compile_tests.step);

    if (b.args) |args| {
        run_compile_tests.addArgs(args);
    }
}
