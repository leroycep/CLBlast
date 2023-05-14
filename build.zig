const std = @import("std");

const Backend = enum {
    opencl,
    cuda,
};

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const backend = b.option(Backend, "backend", "Specify the backend library to perform computations") orelse .opencl;
    const should_install_samples = b.option(bool, "samples", "Install the sample programs") orelse false;

    const clblast = b.addStaticLibrary(.{
        .name = "clblast",
        .target = target,
        .optimize = optimize,
    });
    clblast.c_std = .C11;
    clblast.addIncludePath("include/");
    clblast.addIncludePath("src/");
    clblast.installHeader("include/clblast.h", "clblast.h");
    clblast.installHeader("include/clblast_c.h", "clblast_c.h");
    clblast.installHeader("include/clblast_half.h", "clblast_half.h");
    // lib.installHeader("src/clpp11.hpp", "clpp11.hpp");
    clblast.addCSourceFiles(&.{}, &.{"-std=c++11"});

    clblast.addCSourceFiles(&.{
        "src/database/database.cpp",
        "src/routines/common.cpp",
        "src/utilities/compile.cpp",
        "src/utilities/clblast_exceptions.cpp",
        "src/utilities/timing.cpp",
        "src/utilities/utilities.cpp",
        "src/api_common.cpp",
        "src/cache.cpp",
        "src/kernel_preprocessor.cpp",
        "src/routine.cpp",
        "src/routines/levelx/xinvert.cpp",
        "src/tuning/configurations.cpp",

        // Level 1 routines
        "src/routines/level1/xswap.cpp",
        "src/routines/level1/xscal.cpp",
        "src/routines/level1/xcopy.cpp",
        "src/routines/level1/xaxpy.cpp",
        "src/routines/level1/xdot.cpp",
        "src/routines/level1/xdotu.cpp",
        "src/routines/level1/xdotc.cpp",
        "src/routines/level1/xnrm2.cpp",
        "src/routines/level1/xasum.cpp",
        "src/routines/level1/xamax.cpp",

        // Level 2 routines
        "src/routines/level2/xgemv.cpp",
        "src/routines/level2/xgbmv.cpp",
        "src/routines/level2/xhemv.cpp",
        "src/routines/level2/xhbmv.cpp",
        "src/routines/level2/xhpmv.cpp",
        "src/routines/level2/xsymv.cpp",
        "src/routines/level2/xsbmv.cpp",
        "src/routines/level2/xspmv.cpp",
        "src/routines/level2/xtrmv.cpp",
        "src/routines/level2/xtbmv.cpp",
        "src/routines/level2/xtpmv.cpp",
        "src/routines/level2/xtrsv.cpp",
        "src/routines/level2/xger.cpp",
        "src/routines/level2/xgeru.cpp",
        "src/routines/level2/xgerc.cpp",
        "src/routines/level2/xher.cpp",
        "src/routines/level2/xhpr.cpp",
        "src/routines/level2/xher2.cpp",
        "src/routines/level2/xhpr2.cpp",
        "src/routines/level2/xsyr.cpp",
        "src/routines/level2/xspr.cpp",
        "src/routines/level2/xsyr2.cpp",
        "src/routines/level2/xspr2.cpp",

        // Level 3 routines
        "src/routines/level3/xgemm.cpp",
        "src/routines/level3/xsymm.cpp",
        "src/routines/level3/xhemm.cpp",
        "src/routines/level3/xsyrk.cpp",
        "src/routines/level3/xherk.cpp",
        "src/routines/level3/xsyr2k.cpp",
        "src/routines/level3/xher2k.cpp",
        "src/routines/level3/xtrmm.cpp",
        "src/routines/level3/xtrsm.cpp",

        // Level X routines
        "src/routines/levelx/xhad.cpp",
        "src/routines/levelx/xomatcopy.cpp",
        "src/routines/levelx/xim2col.cpp",
        "src/routines/levelx/xcol2im.cpp",
        "src/routines/levelx/xconvgemm.cpp",
        "src/routines/levelx/xaxpybatched.cpp",
        "src/routines/levelx/xgemmbatched.cpp",
        "src/routines/levelx/xgemmstridedbatched.cpp",

        // Database
        "src/database/kernels/copy/copy.cpp",
        "src/database/kernels/pad/pad.cpp",
        "src/database/kernels/padtranspose/padtranspose.cpp",
        "src/database/kernels/transpose/transpose.cpp",
        "src/database/kernels/xaxpy/xaxpy.cpp",
        "src/database/kernels/xdot/xdot.cpp",
        "src/database/kernels/xgemm/xgemm.cpp",
        "src/database/kernels/xgemm_direct/xgemm_direct.cpp",
        "src/database/kernels/xgemv/xgemv.cpp",
        "src/database/kernels/xgemv_fast/xgemv_fast.cpp",
        "src/database/kernels/xgemv_fast_rot/xgemv_fast_rot.cpp",
        "src/database/kernels/xger/xger.cpp",
        "src/database/kernels/invert/invert.cpp",
        "src/database/kernels/gemm_routine/gemm_routine.cpp",
        "src/database/kernels/trsv_routine/trsv_routine.cpp",
        "src/database/kernels/xconvgemm/xconvgemm.cpp",
    }, &.{"-std=c++11"});
    switch (backend) {
        .opencl => {
            clblast.addCSourceFiles(&.{
                "src/api_common.cpp",
                "src/clblast.cpp",
                "src/clblast_c.cpp",
                "src/tuning/tuning_api.cpp",
            }, &.{"-std=c++11"});
        },
        else => std.debug.panic("Backend not implemented in build.zig: {}", .{backend}),
    }

    clblast.defineCMacro("OPENCL_API", "1");
    clblast.linkSystemLibrary("OpenCL");
    clblast.linkLibC();
    clblast.linkLibCpp();
    b.installArtifact(clblast);

    // sample programs
    switch (backend) {
        .opencl => {
            const C_SAMPLES = [_][]const u8{
                "sasum",
                "samax",
                "dgemv",
                "sgemm",
                "haxpy",
                "cache",
            };
            for (C_SAMPLES) |sample| {
                const sample_exe = addCSample(b, sample, clblast, target, optimize);
                if (should_install_samples) b.installArtifact(sample_exe);
            }
        },
        else => std.debug.panic("Backend not implemented in build.zig: {}", .{backend}),
    }
}

fn addCSample(b: *std.Build, name: []const u8, clblast: *std.Build.CompileStep, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) *std.Build.CompileStep {
    const sample_exe = b.addExecutable(.{
        .name = b.fmt("clblast_sample_{s}_c", .{name}),
        .target = target,
        .optimize = optimize,
    });
    sample_exe.c_std = .C99;
    sample_exe.addCSourceFile(b.fmt("samples/{s}.c", .{name}), &.{});
    sample_exe.linkLibrary(clblast);
    sample_exe.linkSystemLibrary("OpenCL");

    return sample_exe;
}
