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
    Sexpr * car, cdr;

    bool has_car = false,
         has_cdr = false;

    invariant()
    {
        if (car.has_value)
        {
            assert (is_expression_type(car),
                    "Value in CAR is not a valid type");
        }

        if (cdr.has_value)
        {
            assert (is_expression_type(cdr),
                    "Value in CDR is not a valid type");
        }
    }

    bool set_car(T)(T t) @property
    {
        car = t;
        return has_car = true;
    }

    bool set_cdr(T)(T t) @property
    {
        cdr = t;
        return has_cdr = true;
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
//    writeln("is_expression_type? ", t);

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
        if (info == typeid(t))
            return true;
    return false;
}

bool is_atomic_type(TypeInfo info)
{
    return is_type_in_typetuple!AtomicTypes(info);
}

enum SexprType
{
    Number,
    Symbol,
    Pair,
}

bool is_sexpr_value_kind(T)()
{
    return (is(T == Pair) || is(T == Symbol) || is (T == Number));
}

struct SexprValue
{
    Algebraic!(Pair, Symbol, Number) value;
    TypeInfo type;

    void opAssign(T)(T t) if (is_sexpr_value_kind!T)
    {
        value = t;
        type = typeid(T);
    }

    T to(T)() if (is_sexpr_value_kind!T)
    {
        if (type == typeid(T))
        {
            return value.peek!T;
        }
        return null;
    }

    alias value this;
}

struct Sexpr
{
    SexprValue value;
    alias value this;
    bool has_value = false;

    this(T)(T t) if (is_sexpr_value_kind!T)
    {
        writeln("new Sexpr, of type: ", T.stringof);
        has_value = true;
        value = t;
    }

    void opAssign(T)(T t) if (is_sexpr_value_kind!T)
    {
        if (has_value)
        {
            debug writeln("Sexpr.opAssign: comparing existing type ", type,
                          " with ", typeid(T));
            assert (typeid(T) == type);
        }
        value = t;
    }

    void opCatAssign(T)(T t)
    {
        writeln("Sexpr.opCatAssign ", T.stringof, ": ", t);

        bool try_append(ref Pair p, T t)
        {
            writeln("try_append: ", t);

            if (!p.has_car)
            {
                p.car = new Sexpr(t);
                return true;
            }
            return false;
        }

        debug assert (has_value);
        debug assert (value.type == typeid(Pair), format(
                     "Cannot append %s to a non-Pair expression", T.stringof));

        auto pair = *value.peek!Pair;
        //while (!try_append(pair, t))
        //{
        //    if (pair.has_cdr)
        //    {
        //        if (is(pair.cdr.type == Pair))
        //        {
        //            pair = *pair.cdr.value.peek!Pair;
        //        }
        //        else
        //        {
        //            throw new TypeError(format(
        //                            "Cannot append to improper list ", pair));
        //        }
        //    }
        //    else
        //    {
        //        pair.cdr = new Sexpr(*new Pair);
        //        pair = pair.cdr.peek!Pair;
        //    }
        //}
    }
}
