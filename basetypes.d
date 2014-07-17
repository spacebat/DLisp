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

    string toString()
    {
        writeln("Pair.toString");
        string car_string, cdr_string;

        if (has_car && car.has_value)
        {
            writeln("...has_car && car.has_value");
            car_string = car.toString();

            if (has_cdr && car.has_value)
            {
                cdr_string = to!string(cdr);
            }
        }

        string repr = "(" ~ car_string;

        if (cdr_string.length)
        {
            repr ~= " ";
        }

        return repr ~ cdr_string ~ ")";
    }

    //string toString()
    //{
    //    return "Pair: " ~ to!string(car) ~ " | " ~ to!string(cdr);
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
    writeln("is_expression_type: testing ", typeid(t));
    return (is(T == Number) || is(T == Symbol) || is(T == Pair));
    //if (staticIndexOf!(T, ExpressionTypes) >= 0)
    //{
    //    return true;
    //}

    //auto var = cast(Variant)t.value;

    //if (var != null)
    //{
    //    foreach(E; ExpressionTypes)
    //    {
    //        if (var.type == typeid(E))
    //        {
    //            return true;
    //        }
    //    }
    //}

    //return false;
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

    string toString()
    {
        return value.toString();
    }

    invariant()
    {
        if (value.hasValue)
        {
               assert (value.type == typeid(Pair) ||
                       value.type == typeid(Symbol) ||
                       value.type == typeid(Number),
                            format("Sexpr has an illegal type: %s",
                                    to!string(value.type)));
        }
    }

    bool has_value() @property
    {
        return value.hasValue;
    }

    void opCatAssign(T)(T t) if (is_sexpr_value_kind!T || is(T == Sexpr))
    {
        writeln("opCatAssign: ", t);

        if (!value.hasValue)
        {
            writeln("  -> assign this Sexpr to ", t);
            value = t;
        }
        else
        {
            if (value.type != typeid(Pair))
            {
                throw new TypeError("Cannot append a " ~ T.stringof ~ "to " ~
                                    "a non-Pair S-Expression");
            }
            else
            {
                // Traverse the linked-Pairs until an empty CDR is found,
                // else throw an exception
                auto iter_p = value.peek!Pair;
                auto seeking = true;

                while (seeking)
                {
                    if (iter_p.has_cdr)
                    {
                        if (iter_p.cdr.type != typeid(Pair))
                        {
                            throw new
                            TypeError("Cannot append a " ~ T.stringof ~ "to " ~
                                "a non-Pair S-Expression");
                        }
                        else
                        {
                            iter_p = iter_p.cdr.peek!Pair;
                        }
                    }
                    else
                    {
                        seeking = false;
                        iter_p.car = new Sexpr(t);
                    }
                }
            }
        }
    }
}

