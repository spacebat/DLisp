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

    bool _dotted = false;

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

    bool dotted() @property
    {
        return _dotted;
    }

    void set_dotted()
    {
        _dotted = true;
    }
}

Pair cons(Sexpr car, Sexpr cdr)
{
    return new Pair(car, cdr);
}



class List
{
    Pair head = null, end = null;

    private static bool is_valid_elem_type(T)()
    {
        static if (is(T == Sexpr))
        {
            return true;
        }
        else static if (is(T == List))
        {
            return true;
        }
        else
        {
            alias types = BaseTypeTuple!T;
            foreach(t; types)
            {
                if (is(t == Sexpr))
                {
                    return true;
                }
            }
        }

        return false;
    }

    void opCatAssign(T)(T t) if (is_valid_elem_type!T())
    {

    }
}

alias NumberType = double;

class Number : Sexpr
{
    NumberType value;
    alias value this;

    this (NumberType value)
    {
        this,value = value;
    }

    override string toString()
    {
        return to!string(value);
    }
}
