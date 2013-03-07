#What is coverage

Coverage is a tool that, when used with unit tests, will tell you what
lines of code have actually been exercised by the tests. This will allow
you to write tests to specifically cover parts of your code that are not
being exercised by the tests.

Alternatively parts of your code that are not exercised by the tests may,
in fact, be redundant. This might be especially true in a large evolved 
code base where old code has just been left laying around and, as it is not
causing any errors, has not been removed.

#Using coverage

I am presently developing a pure lua XML parser (called plxml.lua). Along 
with the unit tests I want to know what parts of my code might be missed 
by the tests. So I have a simple script run the tests and report the coverage:

    #!/bin/sh

    WHERE=/usr/local/share/lua/5.1/

    # Generate coverage stats
    lua $WHERE/coverage.lua plxml.lua tests/*

    # Report coverage stats
    lua $WHERE/report_coverage.lua plxml.lua > report.txt

    rm coverage.out

    tail -n 5 report.txt

    echo
    echo Full report in report.txt

The coverage statistics are gathered by:

    lua $WHERE/coverage.lua plxml.lua tests/*

this runs all the tests in the tests directory and records all the statistics
against the plxml.lua. These results are then written out to a file called
'coverage.out'.

To generate the report:

    lua $WHERE/report_coverage.lua plxml.lua > report.txt

This reads the 'coverage.txt' file and the source file (plxml.lua) and creates
a report showing the lines of code that were exercised by the tests and those 
that were not along with some summary statistics at the end.

#Running a simple example

In the examples directory there are some tests we can run to show the usage of
the coverage. First lets generate coverage for simple.lua:

    lua ../coverage.lua simple.lua

This executes simple.lua and collects statistics. To view the report:

    lua ../report_coverage.lua simple.lua

    1       true    function odd( number )
    2       false       if( number % 2 == 1 ) then
    3       false           return true
    4       true        else
    5       false           return false
    6       true        end
    7       true    end
    8
    9       true    function nextnumber( number )
    10      true        if( number % 2 == 1 ) then
    11      true            return ( number * 3 ) + 1
    12      true        else
    13      true            return number / 2
    14      true        end
    15      true    end
    16
    17      true    function solve( number )
    18      true        print(number)
    19      true        while( number > 1 ) do
    20      true            number = nextnumber( number )
    21      true            print(number)
    22      true        end
    23      true    end
    24
    25      true    solve( 50 )

    Total lines in file ..: 25
    Total lines of code ..: 22
    Code covered .........: 19 (86.36%)
    Code missed ..........: 3

The first column is the line number from the source file, the second column is either
true, false or blank. Blank means that it was that lines was either blank in the source
file or a comment. True means that this was a line of code in the source that was 
executed during the tests end false means that it was not.

Reading the report we can see that the function odd() was not actually executed. Although
the 'function odd ( number )', the 'else' and 'end's are marked as true the real code, on
lines 2, 3 and 5, has not been run. This is because it is not being called. it should 
have been used in the if conditional at line 10.

It might seem strange that the 'function ...', 'else' and 'end's were flagged as true but 
the code was not actually run. This is because lua reports the 'function ...' as being 
executed when it compiles the source. The 'else' and 'end's are marked as true by the 
coverage reporter as this it is what I feel is right, lua itself does not report them 
as executed.

So we have a choice, remove the odd() function or use it at line 10.

#Things to look out for

The source even.lua shows two implementations of a function to check if a number is even.
Although both are functionally equivalent evenbad() is written in a way, on a single line,
that makes coverage reporting hard. Lets run them:

    lua ../coverage.lua even.lua even.test.lua
    lua ../report_coverage.lua even.lua

    1       true    function evenbad( number )
    2       true        if( number % 2 == 0 ) then return "even" else return "odd" end
    3       true    end
    4
    5       true    function evengood( number )
    6       true        if( number % 2 == 0 ) then 
    7       true            return "even" 
    8       true        else 
    9       false           return "odd" 
    10      true        end
    11      true    end

    Total lines in file ..: 11
    Total lines of code ..: 10
    Code covered .........: 9 (90.00%)
    Code missed ..........: 1

From even.test.lua it is clear that we are only testing even numbers. But the coverage
report of evenbad(), lines 1 to 3, would seem to say that the function has full coverage.
This is not so if you consider the coverage of evengood(), lines 5 to 11.

This is a limitation of this coverage tool which is based on a debug hook that reports
each time a line is executed. This it is unlikely to change unless something 
significant happens to Lua to allow greater granularity. You will have to look out for it.

The source conditional.lua show something else to watch out for. First we run the report:

    lua ../coverage.lua conditional.lua 
    lua ../report_coverage.lua conditional.lua 

    1       true    function odd( number )
    2       true            if( number % 2 == 1 ) then
    3       true                    return true
    4       true            else
    5       true                    return false
    6       true            end
    7       true    end
    8
    9       true    function even( number )
    10      false           return not odd( number )
    11      true    end
    12
    13      true    function special( number )
    14      false           return number == 42
    15      true    end
    16
    17      true    function other( a, b )
    18      true            if( odd( a ) and even( b ) ) then
    19      false                   return "yes"
    20      true            else
    21      true                    return "no"
    22      true            end
    23      true    end
    24
    25      true    function another( a, b )
    26      true            if( odd( a ) or special( b ) ) then
    27      true                    return "yes"
    28      true            else
    29      false                   return "no"
    30      true            end
    31      true    end
    32
    33      true    other( 2, 3 )
    34      true    other( 2, 2 )
    35      true    other( 2, 1 )
    36
    37      true    another( 1, 1 )
    38      true    another( 1, 42 )
    39      true    another( 1, 2 )

    Total lines in file ..: 39
    Total lines of code ..: 33
    Code covered .........: 29 (87.88%)
    Code missed ..........: 4

From lines 9 to 11 it is clear that the function even() was not called but the
only line that calls it, the conditional on line 18, is marked as exercised. This
is because of the 'and' operator. The left hand side, the odd(), always fails as
it is always called with an even number. Lua knows the conditional has failed and
even() is never called.

Likewise the function special() on lines 13 to 15 is never called. This is because
the 'or' operator does not need to be called because the left hand side, the odd(),
always succeeds. Again Lua knows that the conditional has succeeded and does not bother
to evaluate the rest of the conditional.

Reporting these accurately is called 'branch coverage' and we can't do that for the
same reasons we have difficulty when everything is crammed onto a single line.

#Testing and the pursuit of coverage

Coverage is not an end in itself, it is only an aid to evaluating the effectiveness of
your unit tests. This may reveal parts of your code that can be changed but do not
make changes to your code just to hit that magic 100% coverage. After a series of 'if' 
and 'elseif' statements you might put a final 'else' with an error that reads
"This should never happen". This is called defensive programming and you may find that 
it seems to be impossible to actually trigger that condition. It's ok, better safe 
than sorry.

You can improve coverage in two ways: writing better tests (simply adding more tests does
not necessarily improve coverage) or removing the offending code.

Never just remove code because testing it is too hard.
