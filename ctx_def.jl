# The context class, gathers all information about the program

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
end

# Push global scope
ctx_new() = Ctx([], [symtable_new()], [], [])
