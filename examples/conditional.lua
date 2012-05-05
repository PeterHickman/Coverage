function odd( number )
    if( number % 2 == 1 ) then
        return true
    else
        return false
    end
end

function even( number )
    return not odd( number )
end

function special( number )
    return number == 42
end

function other( a, b )
    if( odd( a ) and even( b ) ) then
        return "yes"
    else
        return "no"
    end
end

function another( a, b )
    if( odd( a ) or special( b ) ) then
        return "yes"
    else
        return "no"
    end
end

other( 2, 3 )
other( 2, 2 )
other( 2, 1 )

another( 1, 1 )
another( 1, 42 )
another( 1, 2 )
