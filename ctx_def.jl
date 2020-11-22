# The context class, gathers all information about the program

@enum Reg ax bx cx dx r8 r9 r10 r11 si di sp bp

mutable struct Ctx
    # --- AST ---
    # Global scope functions
    decls
    # --- Semantic Analysis ---
    scopes
    #  --- Code Generation ---
    # Sections
    code
    data
    # Free scratch registers
    scratch_regs
    # Used in the function
    used_scratch_regs
    n_labels
end

# Push global scope
ctx_new() = Ctx([], [symtable_new()], [], [], [], Set(), 0)

reg2str = Dict{Reg, String}(
        ax => "rax",
        bx => "rbx",
        cx => "rcx",
        dx => "rdx",
        r8 => "r8",
        r9 => "r9",
        r10 => "r10",
        r11 => "r11",
        si => "rsi",
        di => "rdi",
        sp => "rsp",
        bp => "rbp",
    )
