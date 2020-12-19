# Syntax
Alpha is mainly inspired by Julia and Python.
The syntax is more wordy than C-like languages and we use line breaks to
delimit statements.
Blocks are delimited by begin and end (like in Julia) though any statement
can be used in an if-else or loop structure (unlike Julia).

## Declarations
A declaration in alpha is made by the let keyword :

```alpha
let x be 2 + 2
```

Since all local variables containing data are ints, no type is required.

## Operators
Operators are Python-like except is which delineates the equality operator
(== in most of languages) and := refering to the assignment operator.

| Precedence | Operators |
| ---------- | --------- |
| 1  | call() |
| 2  | _unary_- |
| 3  | \* / |
| 4  | + - |
| 5  | <= >= < > |
| 6  | is != |
| 7  | and |
| 8  | or |
| 9  | not |
| 10 | := += -= \*= /= |

## Loops
We can declare two types of loops using the loop keyword.
Note that loops accepts block and non block statements for a lighter syntax.

### Loop when (while)
A while loop is made with this syntax :

```alpha
loop when i <= n
begin
    result := result * i
    i := i + 1
end
```

### Loop with (for)
A for loop is made using this syntax :

```alpha
loop with i from 1 to n
    result := result * i
```

## Functions
Functions are slightly different compared to other languages.
Firstly, there are two types of functions : functions and procedure.
The first type describes returning functions and the latter is for functions
that return nothing.
Use fun or proc to declare a function.
Then use the take keyword to declare arguments (this section can be ommited).
Lastly a block statement is required containing the body of the function.

```alpha
fun myfunction      # fun can be replaced by proc if nothing is returned
take a, b, c        # Args
begin
    return a + b + c
end
```
