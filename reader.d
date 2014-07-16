#!/usr/bin/dmd

module Kernel.reader;

import std.stdio;
import std.string;
import std.variant : Variant;
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

enum Lexeme
{
    OpenParen, CloseParen, PairInfix
}

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
        {
            throw new ReadError(format("Illegal lexeme at position %s of "
                                       "input string: '%s'", n, ill));
        }
    }
}

Sexpr parse(string s=null)
{
    Sexpr sexpr;
    int paren_count = 0;
    string accumulated_chars = "";

    void append_tok_if_chars()
    {
        writeln("append_tok_if_chars: " ~ accumulated_chars);
        if (accumulated_chars.length == 0)
        {
            return;
        }

        try
        {
            Number number = parse_number(accumulated_chars);
            writeln("parsed number ", number);

            sexpr ~= number;

            accumulated_chars = "";
            return;
        } catch (ConvException ignored) {}

        if (digits.indexOf(accumulated_chars[0]) >= 0)
        {
            throw new ReadError(format(
                "Symbols must not begin with a digit: '%s'", accumulated_chars));
        }
        else if (accumulated_chars == pair_infix)
        {
            writeln("DEBUG: handling Pair infix operator: TODO!");
        }
        else
        {
            writeln("  append new Symbol: " ~ accumulated_chars);
            sexpr ~= *new Symbol(accumulated_chars);
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

            //writeln("char ", i, ": '", c, "'");
            if (WHITESPACE.indexOf(c) >= 0)
            {
                append_tok_if_chars();
            }
            else if ((EXTENDED_ALPHABET ~ digits).indexOf(c) >= 0)
            {
                accumulated_chars ~= c;
            }
            else
            {
                if (str_c == open_paren)
                {
                    writeln(" ( => append new Pair");
                    parens += 1;
                    sexpr ~= *new Pair;
                }
                else if (str_c == close_paren)
                {
                    writeln(" ) => close current object, join to previous");
                    parens -= 1;
                    append_tok_if_chars();
                }
                else
                {
                    throw new ReadError(format(
                                "Illegal character at position %s of '%s'",
                                i, chop(s)));
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
            throw new ReadError("Unexpected ')' character");
         }
        while (paren_count != 0)
        {
            paren_count += do_parse();
        }
    }

    return sexpr;
}
