const std = @import("std");
const FileSource = std.build.FileSource;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const jdz_dep = b.dependency("jdz_allocator", .{
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "zapts",
        .root_source_file = b.path("src/main.zig"),
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
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    const compile_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .test_runner = b.path("src/tests_runner.zig"),
    });
    compile_tests.root_module.addImport("jdz_allocator", jdz_dep.module("jdz_allocator"));

    const run_compile_tests = b.addRunArtifact(compile_tests);

    const compile_tests_step = b.step("test:compiler", "Run local compiler tests");
    compile_tests_step.dependOn(&run_compile_tests.step);

    if (b.args) |args| {
        run_compile_tests.addArgs(args);
    }
}
