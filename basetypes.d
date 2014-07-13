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
    Sexpr car, cdr;

    bool has_car = false,
         has_cdr = false;

    invariant()
    {
        if (car.hasValue)
        {
            assert (is_expression_type(car),
                    format("CAR: Not a valid Sexpr type: %s", car));
        }

        if (cdr.hasValue)
        {
            assert (is_expression_type(cdr),
                    format("CAR: Not a valid Sexpr type: %s", cdr));
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

        if (has_car && car.hasValue)
        {
            car_string = to!string(car);

            if (has_cdr && car.hasValue)
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

    auto var = cast(Variant)t;

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




mixin template TaggedUnion(Types ...)
{
    private auto getUnionContent()
    {
        string s;
        foreach(T; Types)
        {
            s ~=  fullyQualifiedName!T ~ " member_" ~ T.mangleof ~ ";";
        }

        return s;
    }

    private auto getTag()
    {
        string s;
        foreach(T; Types)
        {
            s ~= T.mangleof ~ ",";
        }

        return "enum Tag {" ~ s ~ "}";
    }

    private auto getSwitchContent()
    {
        string s;
        foreach(T; Types)
        {
            s ~= "case Tag." ~ T.mangleof;
            s ~= ": return fun(member_" ~ T.mangleof ~ ");";
        }

        return s;
    }

    struct TaggedUnion
    {
    private:
        union
        {
            mixin(getUnionContent());
        }

        mixin(getTag());

        Tag tag;

    public:
        this(T)(T t) if(is(typeof(mixin("Tag." ~ T.mangleof))))
        {
            mixin("tag = Tag." ~ T.mangleof ~ ";");
            mixin("member_" ~ T.mangleof ~ " = t;");
        }

        auto ref apply(alias fun)()
        {
            final switch(tag)
            {
                mixin(getSwitchContent());
            }
        }
    }
}



class Sexpr
{
    mixin TaggedUnion!(Pair, Number, Symbol);

    this(T)(T t) if (is(T == Pair) || is(T == Number) || is(T == Symbol))
    {


    }
    //Variant value;

    //this(T)(T t)
    //{
    //    writeln("Sexpr: ", t);
    //    value = t;
    //}

    //invariant()
    //{
    //    if (value.hasValue)
    //        assert (is_expression_type(value),
    //                format("Not a valid Sexpr type: %s", value));
    //}

    //string toString()
    //{
    //    auto str = "Sexpr: ";
    //    if (value.hasValue)
    //        return str ~ to!string(value);
    //    return str ~ "undefined";
    //}

    //void opAssign(T)(T t)
    //{
    //    value = t;
    //}

    //void opCatAssign(T)(T t)
    //{
    //    bool try_append(Pair p, T t)
    //    {
    //        writeln("try_append: ", t);
    //        if (!p.has_car)
    //        {
    //            p.car = t;
    //            return true;
    //        }
    //        return false;
    //    }

    //    writeln("Trying to append ", t, " of type ", T.stringof,
    //            " to Sexpr of type ", value.type);

    //    debug assert (value.hasValue);
    //    debug assert (value.type == typeid(Pair));

    //    Pair *p = value.peek!Pair;
    //    debug assert (p != null);

    //    while (!try_append(*p, t))
    //    {
    //        if (p.has_cdr)
    //        {
    //            Pair *cdr_pair = p.cdr.peek!Pair;

    //            if (cdr_pair)
    //            {
    //                p = cdr_pair;
    //            }
    //            else
    //            {
    //                throw new TypeError(format(
    //                                    "Cannot append to improper list ", p));
    //            }
    //        }
    //        else
    //        {
    //            p.cdr = new Sexpr(new Pair);
    //            p = p.cdr;
    //        }
    //    }
    //}

    //alias value this;
}
