#!/usr/bin/dmd

module Kernel.reader;

import std.stdio;
import std.string;
import std.variant : Variant, variantArray;
import std.conv;
import std.ascii : letters, digits;
import std.typetuple : staticIndexOf;

import Kernel.basetypes;
import Kernel.exceptions;


const string COMMENT = ";";
const string WHITESPACE = " \t\n\r";
const string EXTENDED_ALPHABET = "!$%&*+-./:<=>?@^_~#" ~ letters;
const string[] ILLEGAL_LEXEMES = [
    // r-1rk => 16.1.1
    "‘",
    "’",
    "#(",
    ",",
    ",@",
    "[",
    "]",
    "{",
    "}",
];
const string open_paren = "(";
const string close_paren = ")";
const string operative_prefix = "$";
const string constant_prefix = "#";
const string pair_infix = ".";

Sexpr read()
{
    Sexpr sexpr;
    write(">>> ");

    try
    {
        return parse();
    }
    catch (ReadError e)
    {
        writeln(e.msg);
        read();
    }

    return sexpr;
}

alias NumberType = typeof(Number.value);

Number parse_number(in string s)
{
    auto num = to!NumberType(s);
    Number n;
    n = *new Number(num);
    return n;
}

void scan_for_illegal_lexemes(in string s)
{
    foreach(n, ref ill; ILLEGAL_LEXEMES)
    {
        if (indexOf(s, ill) >= 0)
            throwEx!ReadError(format("Illegal lexeme at position %s of "
                                     "input string: '%s'", n, ill));
    }
}

Sexpr parse(string s=null)
{
    int paren_count = 0;
    string accumulated_chars = "";
    SexprList[] sexprs;

    void append_tok_if_chars()
    {
        if (accumulated_chars.length == 0)
        {
            return;
        }

        try
        {
            sexprs[$-1] ~= parse_number(accumulated_chars);
            accumulated_chars = "";
            return;
        } catch (ConvException ignored) {}

        if (digits.indexOf(accumulated_chars[0]) >= 0)
        {
            throwEx!ReadError(format(
                                  "Symbols must not begin with a digit: '%s'",
                                   accumulated_chars));
        }
        else if (accumulated_chars == pair_infix)
        {
            writeln("TODO: handle Pair infix operator!");
        }
        else
        {
            writeln("  append new Symbol: " ~ accumulated_chars);
            sexprs[$-1] ~= *new Symbol(accumulated_chars);
        }

        accumulated_chars = "";
    }

    int do_parse(string s=null)
    {
        int parens = 0;

        if (s is null)
        {
            s = readln();
        }

        scan_for_illegal_lexemes(s);

        foreach(i, ref c; s)
        {
            string str_c = to!string(c);
            writeln(" ", i, ":= ", str_c);

            if (WHITESPACE.indexOf(c) >= 0)
            {
                append_tok_if_chars();
                writeln(" ~~> ", sexprs);
                continue;
            }
            else
            {
                if ((EXTENDED_ALPHABET ~ digits).indexOf(c) >= 0)
                {
                    accumulated_chars ~= c;
                }
                else
                {
                    if (str_c == open_paren)
                    {
                        parens += 1;
                        //sexprs.length += 1;
                        sexprs ~= *new SexprList;

                        //writeln(" new Object!");
                        writeln(" ~~> ", sexprs);
                    }
                    else if (str_c == close_paren)
                    {
                        append_tok_if_chars();

                        if (sexprs.length > 1)
                        {
                            SexprList head = sexprs[$-1];
                            sexprs.length -= 1;
                            sexprs[$-1] ~= head;

                            writeln(" close current object");
                        }

                        parens -= 1;

                        writeln(" ~~> ", sexprs);
                    }
                    else
                    {
                        throwEx!ReadError(
                            format("Illegal character at position %s of '%s'",
                                   i, chop(s)));
                    }
                }
            }
        }
        return parens;
    }

    paren_count = do_parse(s);

    if (paren_count != 0)
    {
        if (paren_count < 0)
        {
            throwEx!ReadError(format("Unexpected '%s' character",
                                     close_paren));
        }
        while (paren_count != 0)
        {
            paren_count += do_parse();
        }
    }

    //return sexprs[0];
    assert (0, "not implemented!");
}
