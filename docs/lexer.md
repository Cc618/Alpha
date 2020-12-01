# Lexer
The lexer is included within the parser module.
This document describes the syntax of regular expressions (regexes)
parsed by the lexer.

## Syntax
The syntax is inspired by standard regexes.
However, the syntax is slightly different than other regexes.


## Operators
- <state>\* : Kleen star, 0 or more <state>
- <state>? : 0 or 1 <state>

## Groups
- alpha : \_a-zA-Z
- num : 0-9
- alnum : Union of alpha and num sets
- \n : Line feed
- \t : Tab
- \s : Blank char (\t or space)
- . : All characters except line feed ([\n])

## Examples
- Identifiers :
```
[alpha][alnum]*
```
- Integers :
```
-?[num][num]*
```
- Julia inline comments :
```
#[.]*
```
