module Kernel.exceptions;

import std.string : format;

alias NotImplementedError = Exception;

string generate_exception_mixin(in string name)
{
    /*
     * This might be the ugliest piece of code ever written, but it saves
     * a *lot* boilerplate bullshit.
     */
    return
          "class " ~ name ~ " : Exception\n"
        ~ "{\n"
            ~ "this(string msg)\n"
            ~ "{\n"
            ~ "     super(format(\"" ~ name ~": %s\", msg));\n"
            ~ "}\n"
        ~ "}\n";
}


mixin(generate_exception_mixin("KeyError"));
mixin(generate_exception_mixin("ReadError"));
mixin(generate_exception_mixin("EvalError"));
mixin(generate_exception_mixin("TypeError"));
mixin(generate_exception_mixin("UnknownSymbolError"));
mixin(generate_exception_mixin("IllegalMutationException"));
mixin(generate_exception_mixin("IllegalAssignmentType"));
