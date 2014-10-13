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


PList[] read()
{
    PList[] sexprs;
    write(">>> ");

    try
    {
        sexprs = parse();
    }
    catch (ReadError e)
    {
        writeln(e.msg);
        read();
    }

    return sexprs;
}



Number parse_number(in string s)
{
    auto num = to!NumberType(s);
    Number n;
    n = new Number(num);
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

PList[] parse(string s=null)
{
    int paren_count = 0;
    string accumulated_chars = "";
    PList[] lists;

    void append_tok_if_chars()
    {
        if (accumulated_chars.length == 0)
        {
            return;
        }

        try
        {
            lists[$-1] ~= parse_number(accumulated_chars);
            accumulated_chars = "";
            return;
        }
        catch (ConvException ignored) {}

        if (digits.indexOf(accumulated_chars[0]) >= 0)
        {
            throwEx!ReadError(format("Symbols cannot start with a digit: " ~
                                     "'%s'", accumulated_chars));
        }
        else
        {
            if (lists.length == 0)
            {
                lists ~= new PList;
            }

            lists[$-1] ~= new Symbol(accumulated_chars);
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

            if (WHITESPACE.indexOf(c) >= 0)
            {
                append_tok_if_chars();
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
                    if (str_c == ReadTable.open_paren)
                    {
                        parens += 1;
                        lists ~= new PList;
                    }
                    else if (str_c == ReadTable.close_paren)
                    {
                        append_tok_if_chars();

                        if (lists.length > 1)
                        {
                            PList head = lists[$-1];
                            lists.length -= 1;
                            lists[$-1] ~= head;
                        }

                        parens -= 1;
                    }
                    else
                    {
                        throwEx!ReadError(format(
                                    "Illegal character at position %s of '%s'",
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
                                     ReadTable.close_paren));
        }
        while (paren_count != 0)
        {
            paren_count += do_parse();
        }
    }

    if (lists.length > 0)
    {
        foreach(list; lists)
        {
            writeln(list);
        }
    }

    return lists;
}

