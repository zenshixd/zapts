const std = @import("std");
const FileSource = std.build.FileSource;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const jdz_dep = b.dependency("jdz_allocator", .{
        .target = target,
        .optimize = optimize,
    });
    const zapts_module = b.addModule("zapts", .{
        .root_source_file = b.path("src/compile.zig"),
        .imports = &.{
            .{
                .name = "jdz_allocator",
                .module = jdz_dep.module("jdz_allocator"),
            },
        },
    });

    const exe = b.addExecutable(.{
        .name = "zapts",
        .root_source_file = zapts_module.root_source_file,
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("jdz_allocator", jdz_dep.module("jdz_allocator"));
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .test_runner = b.path("tests/unit_tests_runner.zig"),
        .filter = b.option([]const u8, "filter", "Filter tests to run"),
    });
    exe_unit_tests.root_module.addImport("jdz_allocator", jdz_dep.module("jdz_allocator"));

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    const compile_tests = b.addTest(.{
        .root_source_file = b.path("tests/e2e_tests_runner.zig"),
        .target = target,
        .optimize = optimize,
        .test_runner = b.path("tests/e2e_tests_runner.zig"),
    });
    compile_tests.root_module.addImport("jdz_allocator", jdz_dep.module("jdz_allocator"));
    compile_tests.root_module.addImport("zapts", zapts_module);

    const run_compile_tests = b.addRunArtifact(compile_tests);

    const compile_tests_step = b.step("test:compiler", "Run local compiler tests");
    compile_tests_step.dependOn(&run_compile_tests.step);

    if (b.args) |args| {
        run_compile_tests.addArgs(args);
    }
}
