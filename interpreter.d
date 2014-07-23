module Lisp.interpreter;

import std.stdio : writeln;
import std.conv : to;

import Kernel.basetypes;
import Kernel.reader;

alias print = writeln;

int main()
{
    //Environment current_env = new GroundEnv();
    string output;

    while(true)
    {
        auto list = read();
        writeln("read: ", list);
        //current_env = Environment.get_current_env();

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
