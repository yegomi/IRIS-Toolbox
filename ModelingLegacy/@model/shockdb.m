function [d, YXEPG] = shockdb(this, d, range, varargin)
% shockdb  Create model-specific database with random shocks
%
%
% __Syntax__
%
% Input arguments marked with a `~` sign may be omitted.
%
%     OutputData = shockdb(M, InputData, Range, ...)
%
%
% __Input arguments__
%
% * `M` [ model ] - Model object.
%
% * `InputData` [ struct | empty ] - Input database to which shock time
% series will be added; if omitted or empty, a new database will be
% created; if `D` already contains shock time series, the data generated by
% `shockdb` will be added up with the existing data.
%
% * `Range` [ numeric ] - Date range on which the shock time series will be
% generated and returned; if `D` already contains shock time series
% going before or after `Range`, these will be clipped down to `Range` in
% the output database.
%
%
% __Output arguments__
%
% * `OutputData` [ struct ] - Database with shock time series added.
%
%
% __Options__
%
% * `NumOfDraws=@auto` [ numeric | @auto ] - Number of draws (i.e. columns)
% generated for each shock; if `@auto`, the number of draws is equal to the
% number of alternative parameterizations in the model `M`, or to the
% number of columns in shock series existing in the input database,
% `InputData`.
%
% * `ShockFunc=@zeros` [ `@lhsnorm` | `@randn` | `@zeros` ] - Function used
% to generate random draws for new shock time series; if `@zeros`, the new
% shocks will simply be filled with zeros; the random numbers will be
% adjusted by the respective covariance matrix implied by the current model
% parameterization.
%
%
% __Description__
%
%
% __Example__
%

% -IRIS Macroeconomic Modeling Toolbox
% -Copyright (c) 2007-2019 IRIS Solutions Team

TYPE = @int8;
TIME_SERIES_CONSTRUCTOR = iris.get('DefaultTimeSeriesConstructor');
TIME_SERIES_TEMPLATE = TIME_SERIES_CONSTRUCTOR( );

persistent inputParser
if isempty(inputParser)
    inputParser = extend.InputParser('model.shockdb');
    inputParser.addRequired('Model', @(x) isa(x, 'model'));
    inputParser.addRequired('InputDatabank', @(x) isempty(x) || isstruct(x));
    inputParser.addRequired('Range', @(x) DateWrapper.validateProperRangeInput(x));
    inputParser.addOptional('NumOfDrawsOptional', @auto, @(x) isequal(x, @auto) || (isnumeric(x) && isscalar(x) && x==round(x) && x>=1));
    inputParser.addParameter('NumOfDraws', @auto, @(x) isnumeric(x) && isscalar(x) && x==round(x) && x>=1);
    inputParser.addParameter('ShockFunc', @zeros, @(x) isa(x, 'function_handle'));
end
inputParser.parse(this, d, range, varargin{:});
numOfDrawsOptional = inputParser.Results.NumOfDrawsOptional;
opt = inputParser.Options;
if ~isequal(numOfDrawsOptional, @auto)
    opt.NumOfDraws = numOfDrawsOptional;
end

%--------------------------------------------------------------------------

numOfQuantities = numel(this.Quantity.Name);
indexOfShocks = this.Quantity.Type==TYPE(31) | this.Quantity.Type==TYPE(32);
ne = sum(indexOfShocks);
nv = length(this);
numOfPeriods = numel(range);
lsName = this.Quantity.Name(indexOfShocks);
lsLabel = this.Quantity.LabelOrName;
lsLabel = lsLabel(indexOfShocks);

if isempty(d) || isequal(d, struct( ))
    E = zeros(ne, numOfPeriods);
else
    E = datarequest('e', this, d, range);
end
numOfShocks = size(E, 3);

if isequal(opt.NumOfDraws, @auto)
    opt.NumOfDraws = max(nv, numOfShocks);
end
checkNumOfDraws( );

numOfLoops = max([nv, numOfShocks, opt.NumOfDraws]);
if numOfShocks==1 && numOfLoops>1
    E = repmat(E, 1, 1, numOfLoops);
end

if isequal(opt.ShockFunc, @lhsnorm)
    S = lhsnorm(sparse(1, ne*numOfPeriods), speye(ne*numOfPeriods), numOfLoops);
else
    S = opt.ShockFunc(numOfLoops, ne*numOfPeriods);
end

for ithLoop = 1 : numOfLoops
    if ithLoop<=nv
        Omg = covfun.stdcorr2cov(this.Variant.StdCorr(:, :, ithLoop), ne);
        F = covfun.factorise(Omg);
    end
    iS = S(ithLoop, :);
    iS = reshape(iS, ne, numOfPeriods);
    E(:, :, ithLoop) = E(:, :, ithLoop) + F*iS;
end

if nargout==1
    for i = 1 : ne
        name = lsName{i};
        e = permute(E(i, :, :), [2, 3, 1]);
        d.(name) = replace(TIME_SERIES_TEMPLATE, e, range(1), lsLabel{i});
    end
elseif nargout==2
    [minShift, maxShift] = getActualMinMaxShifts(this);
    numOfExtendedPeriods = numOfPeriods-minShift+maxShift;
    baseColumns = (1:numOfPeriods) - minShift;
    YXEPG = nan(numOfQuantities, numOfExtendedPeriods, numOfLoops);
    YXEPG(indexOfShocks, baseColumns, :) = E;
end

return


    function checkNumOfDraws( )
        if nv>1 && opt.NumOfDraws>1 && nv~=opt.NumOfDraws
            utils.error('model:shockdb', ...
                ['Input argument NDraw is not compatible with the number ', ...
                'of alternative parameterizations in the model object.']);
        end
        
        if numOfShocks>1 && opt.NumOfDraws>1 && numOfShocks~=opt.NumOfDraws
            utils.error('model:shockdb', ...
                ['Input argument NDraw is not compatible with the number ', ...
                'of alternative data sets in the input database.']);
        end
        
        if numOfShocks>1 && nv>1 && nv~=numOfShocks
            utils.error('model:shockdb', ...
                ['The number of alternative data sets in the input database ', ...
                'is not compatible with the number ', ...
                'of alternative parameterizations in the model object.']);
        end
    end%
end%

