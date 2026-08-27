# The signals LLVM takes over are IntSigs + KillSigs + InfoSigs in:
# https://github.com/llvm/llvm-project/blob/main/llvm/lib/Support/Unix/Signals.inc
const LLVM_CLOBBERED_SIGNALS = @static if Sys.islinux()
    Cint[
        Base.SIGHUP,
        Base.SIGINT,
        Base.SIGQUIT,
        4,  # SIGILL
        5,  # SIGTRAP
        6,  # SIGABRT
        7,  # SIGBUS
        8,  # SIGFPE
        10, # SIGUSR1
        11, # SIGSEGV
        12, # SIGUSR2
        Base.SIGTERM,
        24, # SIGXCPU
        25, # SIGXFSZ
        31, # SIGSYS
    ]
elseif Sys.isbsd() # Includes macOS
    Cint[
        Base.SIGHUP,
        Base.SIGINT,
        Base.SIGQUIT,
        4,  # SIGILL
        5,  # SIGTRAP
        6,  # SIGABRT
        7,  # SIGEMT
        8,  # SIGFPE
        10, # SIGBUS
        11, # SIGSEGV
        12, # SIGSYS
        Base.SIGTERM,
        24, # SIGXCPU
        25, # SIGXFSZ
        29, # SIGINFO
        30, # SIGUSR1
        31, # SIGUSR2
    ]
else
    Cint[]
end

# Comfortably larger than `struct sigaction` anywhere (152 bytes on linux/x86_64);
# the extra padding is never read by the kernel.
const SIGACTION_BUFSIZE = 512

function save_signal_handlers()
    map(LLVM_CLOBBERED_SIGNALS) do sig
        buf = zeros(UInt8, SIGACTION_BUFSIZE)
        rc = @ccall sigaction(sig::Cint, C_NULL::Ptr{Cvoid}, buf::Ptr{UInt8})::Cint
        if rc != 0
            nothing
        else
            buf
        end
    end
end

function restore_signal_handlers(saved)
    for (sig, buf) in zip(LLVM_CLOBBERED_SIGNALS, saved)
        if buf !== nothing
            @ccall sigaction(sig::Cint, buf::Ptr{UInt8}, C_NULL::Ptr{Cvoid})::Cint
        end
    end
end

# LLVM installs its crash handlers from `llvm::sys::RegisterHandlers()`, reached
# by most of the functions in: https://llvm.org/doxygen/Signals_8h.html
# It returns early once it has run, so calling this from `__init__` stops any
# later libclang call from clobbering Julia's handlers. We have to keep Julia's
# handlers because the GC will itself cause benign segfaults when started with
# multiple threads, which will otherwise kill the process if LLVM's handlers are
# installed.
#
# `clang_enableStackTraces` is the least-invasive libclang function that reaches
# `RegisterHandlers()`. It also appends LLVM's stack-trace printer to LLVM's
# crash callbacks with no C API to remove it, but that callback is unreachable
# since LLVM only consults the list from its own signal handler, which we
# immediately overwrite.
function preregister_llvm_signal_handlers()
    if !Sys.isunix()
        return
    end

    saved = save_signal_handlers()
    try
        clang_enableStackTraces()
    finally
        restore_signal_handlers(saved)
    end
end
