function len = rnglen(varargin)
% numeric.rnglen  Position of dates relative to a start date
%
% Backend IRIS function
% No help provided

% -IRIS Macroeconomic Modeling Toolbox
% -Copyright (c) 2007-2018 IRIS Solutions Team

% rnglen(range)  returns  range(end)-range(1)+1
% rnglen(date, dates)  returns  dates-date+1

%---------------------------------------------------------------------------

if nargin==1
    referenceDate = varargin{1}(1);
    dates = varargin{1}(end);
else
    referenceDate = varargin{1};
    dates = varargin{2};
end

if isnan(referenceDate) && isnan(dates)
    len = 0;
    return
end

freqOfReference = DateWrapper.getFrequencyAsNumeric(referenceDate);
freqOfDates = DateWrapper.getFrequencyAsNumeric(dates);
DateWrapper.checkMixedFrequency(freqOfReference, freqOfDates);
serialOfReference = DateWrapper.getSerial(referenceDate);
serialOfDates = DateWrapper.getSerial(dates);
len = round(serialOfDates - serialOfReference + 1);

end%
