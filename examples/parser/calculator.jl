include("../parser/lexerparser.jl")

# --- Lexer ---
# TODO : Remove once the lexer is auto generated
# TODO : [\[] etc...

# TODO : Simple regexes
# rule : nothing = ignored, (s) -> nothing = no data but token sent to the parser
regs = Array{Any}([
        # Calculator
        ("(", "(", "(s) -> nothing"),
        (")", ")", "(s) -> nothing"),
        ("+", "+", "(s) -> nothing"),
        # TODO : Match star
        ("*", "x", "(s) -> nothing"),
        ("n", "-?[num][num]*", "(s) -> Base.parse(Int, s)"),
        ("blank", "[\\s][\\s]*", "nothing"),

        # ("let", "let", "(s) -> nothing"),
        # ("=", "=", "(s) -> nothing"),
        # ("comment", "#[.]*", "nothing"),
        # ("line", "[\\n][\\n]*", "(s) -> nothing"),
        # ("blank", "[\\s][\\s]*", "nothing"),
        # ("id", "[alpha][alnum]*", "(s) -> s"),
        # ("int", "-?[num][num]*", "(s) -> Base.parse(Int, s)"),
    ])

# file = "lexer.yy.jl"
# open(file, "w") do io
#     # TODO : Will be done with lexerparser
#     println(io, """
#         include("lexerparser.inc.jl")""")
#     generate_lexer(io, regs)
# end

# --- Parser ---
t_n = tok_new("n", terminal=true)
t_lp = tok_new("(", terminal=true)
t_rp = tok_new(")", terminal=true)
t_plus = tok_new("+", terminal=true)
t_times = tok_new("*", terminal=true)
t_a = tok_new("A")
t_e = tok_new("E")
t_f = tok_new("F")
t_t = tok_new("T")

tokens = [
    t_a,
    t_e,
    t_t,
    t_f,
    t_n,
    t_lp,
    t_rp,
    t_plus,
    t_times,
   ]

prods = [
        prod_new(t_a, [t_e]),
        prod_new(t_e, [t_e, t_plus, t_t]),
        prod_new(t_e, [t_t]),
        prod_new(t_t, [t_t, t_times, t_f]),
        prod_new(t_t, [t_f]),
        prod_new(t_f, [t_lp, t_e, t_rp]),
        prod_new(t_f, [t_n]),
    ]

produce_rules = [
        "(val) -> val",
        "(a, _, b) -> a + b",
        "(val) -> val",
        "(a, _, b) -> a * b",
        "(val) -> val",
        "(_, val, _) -> val",
        "(val) -> val",
    ]

file = "parser.yy.jl"
open(file, "w") do io
    generate(io, regs, tokens, prods, produce_rules)
end
