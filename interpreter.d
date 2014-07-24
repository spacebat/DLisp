module Lisp.interpreter;

import std.stdio : writeln;
import std.conv : to;
import std.string : join;

import Kernel.basetypes;
import Kernel.reader;

alias print = writeln;

int main()
{
    string output;

    while(true)
    {
        List[] lists = read();

        foreach (i, list; lists)
        {
            writeln(list, "\n");
        }

        try
        {
            //output = eval(e, current_env);
            //print(output);
        }
        catch (Exception e)
        {
            writeln(e.msg);
        }
    }

    return 0;
}
