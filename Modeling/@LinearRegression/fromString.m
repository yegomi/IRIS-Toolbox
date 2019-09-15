function this = fromString(inputString)

persistent parser
if isempty(parser)
    parser = extend.InputParser('LinearRegression.fromString');
    addRequired(parser, 'inputString', @validate.list);
end
parse(parser, inputString);
opt = parser.Options;

%--------------------------------------------------------------------------

inputString0 = inputString;
inputString = string(inputString);
if numel(inputString)==1
    inputString = split(inputString, '=');
end
inputString = strrep(inputString, " ", "");

if numel(inputString)~=2
    hereThrowInvalidInputString( );
end

this = LinearRegression( );

hereGetLhsName( );
hereGetRhsNames( );

hereParseDependent( );
hereParseExplanatory( );

return


    function hereGetLhsName( )
        lhsName = regexp(inputString(1), "\<[A-Za-z]\w*\>(?!\()", "match");
        if numel(lhsName)~=1
            hereThrowInvalidLhs( );
        end
        this.LhsName = lhsName;
    end%


    function hereParseDependent( )
        lhsName = this.LhsName;
        if inputString(1)==lhsName
            this.Dependent = regression.Term(lhsName);
            return
        end
        transform = regexp(inputString(1), "^(\<[A-Za-z]\w*\>)\(" + lhsName + "\)$", "tokens");
        if ~iscell(transform) || numel(transform)~=1 || numel(transform{1})~=1
            hereThrowInvalidLhs( );
        end
        try
            this.Dependent = regression.Term(this, lhsName, "Transform=", transform{1});
        catch
            hereThrowInvalidLhs( );
        end
    end%


    function hereParseExplanatory( )
        open = strfind(inputString(2), "(");
        close = strfind(inputString(2), ")");
        level = zeros(1, strlength(inputString(2)));
        level(open) = 1;
        level(close) = -1;
        level = cumsum(level);
        pos = strfind(inputString(2), "+");
        pos(level(pos)>0) = [ ];
        for i = pos
            inputString(2) = replaceBetween(inputString(2), i, i, "&");
        end
        termStrings = split(inputString(2), "&");
        numTerms = numel(termStrings);
        for i = 1 : numTerms
            if startsWith(termStrings(i), "?*")
                termStrings(i) = extractAfter(termStrings(i), 2);
                this = addExplanatory(this, termStrings(i));
            else
                this = addExplanatory(this, termStrings(i), 'Fixed=', 1);
            end
        end
    end%
        


    function hereGetRhsNames( )
        rhsNames = regexp(inputString(2), "\<[A-Za-z]\w*\>(?!\()", "match");
        rhsNames = unique(rhsNames, "stable");
        rhsNames = setdiff(rhsNames, this.LhsName);
        this.RhsNames = rhsNames;
    end%


    function hereThrowInvalidLhs( )
        thisError = { 'LinearRegression:InvalidInputString'
                      'Invalid specification of the dependent term in a LinearRegression: %s'};
        throw(exception.Base(thisError, 'error'), inputString(1));
    end%


    function hereThrowInvalidInputString( )
        thisError = { 'LinearRegression:InvalidInputString'
                      'Invalid input string to define LinearRegression: %s' };
        throw(exception.Base(thisError, 'error'), join(strtrim(inputString0), ", "));
    end%
end%
