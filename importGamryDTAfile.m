function Data = importGamryDTAfile(filename)
%IMPORTGAMRYDTAFILE Import data from a Gamry DTA file
%  Data = importGamryDTAfile(FILENAME) reads data from the text file
%  FILENAME, locating the data starting point dynamically based on the
%  line containing "ZCURVE". The variable names are on the next line,
%  and the data starts three lines after "ZCURVE".
%
%  Example:
%  Data = importGamryDTAfile("C:\data.DTA");
%
%  See also READTABLE.

%% Open the file to locate the "ZCURVE" line
fid = fopen(filename, 'r');
if fid == -1
    error('File could not be opened.');
end

% Initialize line counter
lineNumber = 0;
dataStartLine = [];

% Read each line until we find "ZCURVE"
while ~feof(fid)
    line = fgetl(fid);
    lineNumber = lineNumber + 1;
    if contains(line, "ZCURVE")
        dataStartLine = lineNumber + 3;  % Data starts three lines after "ZCURVE"
        break;
    end
end

% Close the file after locating "ZCURVE"
fclose(fid);

% Check if "ZCURVE" was found
if isempty(dataStartLine)
    error('"ZCURVE" not found in the file.');
end

%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 12);

% Specify range and delimiter
opts.DataLines = [dataStartLine, Inf];  % Start from the located data start line
opts.Delimiter = "\t";

% Specify column names and types
opts.VariableNames = ["Var1", "Pt", "Time", "Freq", "Zreal", "Zimag", "Zsig", "Zmod", "Zphz", "Idc", "Vdc", "IERange"];
opts.SelectedVariableNames = ["Pt", "Time", "Freq", "Zreal", "Zimag", "Zsig", "Zmod", "Zphz", "Idc", "Vdc", "IERange"];
opts.VariableTypes = ["char", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, "Var1", "WhitespaceRule", "preserve");
opts = setvaropts(opts, "Var1", "EmptyFieldRule", "auto");

% Import the data
Data = readtable(filename, opts);

end