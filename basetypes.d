#!/usr/bin/dmd

module Kernel.basetypes;

import std.variant;
import std.conv : to;
import std.traits;
import std.typecons;
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

struct Pair
{
    private Sexpr * car = null,
                    cdr = null;

    bool has_car() @property
    {
        return car !is null;
    }

    bool has_cdr() @property
    {
        return cdr !is null;
    }

    invariant()
    {
        if (car !is null)
        {
            assert (is_expression_type(car),
                    "Value in CAR is not a valid type");
        }

        if (cdr !is null)
        {
            assert (is_expression_type(cdr),
                    "Value in CDR is not a valid type");
        }
    }

    string toString()
    {
        string car_string, cdr_string;

        if (has_car && car.has_value)
        {
            car_string = to!string(car);

            if (has_cdr && car.has_value)
            {
                cdr_string = to!string(cdr);
            }
        }

        string repr = "(" ~ car_string;

        if (repr.length > 1)
        {
            repr.length += 1;
        }

        return repr ~ cdr_string ~ ")";
    }

    //string toString()
    //{
    //    return "Pair: " ~ to!string(car) ~ " | " ~ to!stringcdr;
    //}
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

bool is_expression_type(T)(T t)
{
    if (staticIndexOf!(T, ExpressionTypes) >= 0)
    {
        return true;
    }

    auto var = cast(Variant)t.value;

    if (var != null)
    {
        foreach(E; ExpressionTypes)
        {
            if (var.type == typeid(E))
            {
                return true;
            }
        }
    }

    return false;
}

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

//struct SexprEnum
//{
//    auto TNumber = new Object();
//    auto TSymbol = new Object();
//    auto TPair = new Object();


//    const Number() @property { return TNumber; }
//    const Symbol() @property { return TSymbol; }
//    const Pair() @property { return TPair; }
//}

bool is_sexpr_value_kind(T)() @property
{
    return (is(T == Pair) || is(T == Symbol) || is (T == Number));
}

alias SexprKind = Algebraic!(Number, Symbol, Pair);

struct Sexpr
{
    SexprKind value;
    alias value this;

    this(T)(T t) if (is_sexpr_value_kind!T)
    {
        value = t;
    }

    //bool has_value() @property
    //{
    //    return value.hasValue;
    //}

    void opCatAssign(T)(T t) if (is_sexpr_value_kind!T || is(T == Sexpr))
    {
        writeln("opCatAssign: ", t);

        if (!value.hasValue)
        {
            value = t;
        }
    }
}

