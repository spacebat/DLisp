#!/usr/bin/dmd

module Kernel.basetypes;

import std.variant;
import std.conv : to;
import std.traits;
import std.typecons : Tuple;
import std.stdio;
import std.typetuple;

import Kernel.exceptions;

struct Symbol
{
    const string text;

    string toString()
    {
        return text;
    }
}

struct Nothing {}

struct Maybe(T)
{
    Variant value = Nothing;
    private const bool _is_set;

    this(U)(U u) if (is(U == T))
    {
        assert (_is_set != true);
        value = u;
        _is_set = true;
    }

    alias value this;
}

struct EmptyList {}

Pair cons(Sexpr *car, Sexpr* cdr)
{
    return * new Pair(car, cdr);
}

struct VList(T...)
{
    Variant[] values;

    invariant()
    {
        foreach(v; values)
            if (!is_valid_member_type(v))
                throw new
                    TypeError(format("Invalid type: %s. Must be one of %s",
                                     v.type, T.stringof));
    }

    private const bool is_valid_member_type(in Variant v)
    {
        assert (v.hasValue(), format("VList element %s is not initialised"));

        foreach(t; T)
        {
            // There must be a less crummy way than this...
            if (v.peek!t != null)
            {
                return true;
            }
        }
        return false;
    }

    void opCatAssign(U)(U u) if (staticIndexOf!(U, T) >= 0)
    {
        writeln(" [VList ~= ", U.stringof, ": ", u, "]");
        values ~= *new Variant;
        values[$-1] = u;
    }

    U opIndex(U)(uint i)
    {
        if (values.length > i)
            return values[i];
        else
            throw new IndexError(format(
                        "VList does not have a value at index %s; " ~
                        "length is: %s", i, values.length));
    }
}

struct Pair
{
    private Sexpr* car = null,
                   cdr = null;

    this(Sexpr* car, Sexpr* cdr)
    {
        this.car = car;
        this.cdr = cdr;
    }

    invariant()
    {
        assert (car != null);
        assert (cdr != null);
    }
}

alias NumberType = double;

struct Number
{
    NumberType value;
    alias value this;

    string toString()
    {
        return to!string(value);
    }
}

alias AtomicTypes = TypeTuple!(Number, Symbol);
alias ExpressionTypes = TypeTuple!(Number, Symbol, Pair, Sexpr);

bool is_type_in_typetuple(T...)(TypeInfo info)
{
    foreach(t; T)
    {
        if (info == typeid(t))
        {
            return true;
        }
    }
    return false;
}

bool is_atomic_type(TypeInfo info)
{
    return is_type_in_typetuple!AtomicTypes(info);
}

bool is_sexpr_value_kind(T)() @property
{
    return (is(T == Pair) || is(T == Symbol) || is (T == Number));
}

alias SexprKind = Algebraic!(Number, Symbol, Pair, EmptyList);

struct Sexpr
{
    SexprKind value;
    alias value this;

    this(T)(T t) if (is_sexpr_value_kind!T)
    {
        value = t;
    }

    invariant()
    {
        assert(value.hasValue());
    }

    string toString()
    {
        if (!value.hasValue)
        {
            return "<uninitialised Sexpr>";
        }
        return value.toString();
    }

    invariant()
    {
        if (value.hasValue)
            assert (
                   value.type == typeid(Pair) ||
                   value.type == typeid(Symbol) ||
                   value.type == typeid(Number) ||
                   value.type == typeid(EmptyList),
            format("Sexpr has an illegal type: %s",
                   to!string(value.type)));
    }

    bool has_value() @property
    {
        return value.hasValue;
    }
}

