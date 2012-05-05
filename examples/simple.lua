function odd( number )
    if( number % 2 == 1) then
        return true
    else
        return false
    end
end

function nextnumber( number )
    if( number % 2 == 1 ) then
        return ( number * 3 ) + 1
    else
        return number / 2
    end
end

function solve( number )
    print(number)
    while( number > 1 ) do
        number = nextnumber( number )
        print(number)
    end
end

solve( 50 )
