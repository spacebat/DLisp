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


struct Symbol
{
    const string text;

    string toString()
    {
        return text;
    }
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
        {
            if (!is_valid_member_type(v))
            {
                //throw new TypeError(format(
                throwEx!TypeError(format(
                   "Invalid type: %s. Must be one of %s", v.type, T.stringof));
            }
        }
    }

    private const bool is_valid_member_type(in Variant v)
    {
        assert(v.hasValue(), format("VList element %s is not initialised"));

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

    string toString()
    {
        auto value_str = "";

        foreach(v; values)
        {
            if (value_str.length)
            {
                value_str ~= " ";
            }

            value_str ~= format("%s", v);

        }

        return format("(%s)", value_str);
    }

    void opCatAssign(U)(U u) if (staticIndexOf!(U, T) >= 0)
    {
        values ~= *new Variant;
        values[$-1] = u;
    }

    U opIndex(U)(uint i)
    {
        if (values.length > i)
        {
            return values[i];
        }
        else
        {
            throw new IndexError(format(
                            "VList does not have a value at index %s; " ~
                            "length is: %s", i, values.length));
        }
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
        {
            assert (
                   value.type == typeid(Pair) ||
                   value.type == typeid(Symbol) ||
                   value.type == typeid(Number) ||
                   value.type == typeid(EmptyList),
                format("Sexpr has an illegal type: %s",
                       to!string(value.type)));
        }
    }

    bool has_value() @property
    {
        return value.hasValue;
    }
}

struct List(ElementTypes...)
{
    struct MetaList
    {
        List!(ElementTypes) *list = null;
        alias list this;
    }

    alias ThisType = List!(ElementTypes);
    alias AllElemTypes = Algebraic!(MetaList, ElementTypes);
    alias Element = Algebraic!AllElemTypes;

    Element[] elements;

    alias elements this;

    uint length() const @property
    {
        return elements.length;
    }

    void opCatAssign(T)(T t)
    {
        elements.length += 1;
        Element e = new Element;
        e = t;
    }

    string toString()
    {
        auto s = "(";

        foreach(i, e; elements)
        {
            s ~= format("%s", e);
            if (i < (elements.length - 1))
            {
                s ~= " ";
            }
        }
        return s ~ ")";
    }
}

alias ExpressionKinds = TypeTuple!(Number, Symbol, Pair, Sexpr, EmptyList);
alias SexprList = List!ExpressionKinds;
