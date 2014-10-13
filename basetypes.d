#!/usr/bin/dmd

module Kernel.basetypes;

import std.variant;
import std.conv : to;
import std.traits;
import std.typecons;
import std.stdio;
import std.string;
import std.typetuple;

import Kernel.exceptions;

class ReadTable
{
    static string open_paren = "(";
    static string close_paren = ")";
    static string operative_prefix = "$";
    static string constant_prefix = "#";
    static string pair_infix = ".";
}

abstract class Sexpr
{
}

class Symbol : Sexpr
{
    const string text;

    this(string s)
    {
        text = s;
    }

    override string toString()
    {
        return text;
    }
}

class Pair : Sexpr
{
    Sexpr car, cdr;

    this ()
    {
        car = null;
        cdr = null;
    }

    this (Sexpr car, Sexpr cdr)
    {
        this.car = car;
        this.cdr = cdr;
    }

    private bool _cdr_is_pair()
    {
        return (to!Pair(cdr) !is null);
    }

    override string toString()
    {
        string s;

        if (car)
        {
            s ~= car.toString();

            if (cdr !is null)
            {
                s ~= " ";

                if (!_cdr_is_pair())
                {
                    s ~= ". ";
                }

                s ~= cdr.toString();
            }
        }

        return format("(%s)", s);
    }
}

Pair cons(Sexpr car, Sexpr cdr)
{
    return new Pair(car, cdr);
}

bool is_atomic_type(T)()
{
    return (is(T == Symbol) || is(T == Number));
}

alias NumberType = double;

class Number : Sexpr
{
    NumberType value;
    alias value this;

    this (NumberType value)
    {
        this.value = value;
    }

    override string toString()
    {
        return to!string(value);
    }
}


class PList : Sexpr
{
    /*
     * A list made up of joined Pairs, aka, a singly-linked list.
     */
    Pair head = null,
         end = null;

    uint length = 0;

    override string toString()
    {
        debug writeln("...in PList.toString");
        string s;

        if (head !is null && head.car !is null)
        {
            Pair p = head;
            auto x = 0;

            while (p.car !is null)
            {
                s ~= p.car.toString();

                if (p.cdr !is null)
                {
                    s ~= " ";
                    p = cast(Pair)p.cdr;
                }
                else
                {
                    break;
                }
            }
        }

        return format("(%s)", s);
    }

    private void _extend(T)(T t)
    {
        // Should not be called
        end.car = t;
        end.cdr = new Pair;
        length += 1;
        end = to!Pair(end.cdr);
    }

    void opCatAssign(T)(T t)
    out
    {
        assert(head !is null);
        assert(end !is null);
        assert(end != head);
        assert(end.car is null);
    }
    body
    {
        writefln("PList.opCatAssign(%s : %s) ", t, T.stringof);

        if (head is null)
        {
            debug assert(end is null);
            head = new Pair;
            end = head;
            _extend(t);
            //~ writeln(" -> Appended to HEAD");
        }
        else if (end.car is null)
        {
            _extend(t);
            //~ writefln(" -> Append to END (%s)", length);
        }
    }
}
