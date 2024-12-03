function Data = importCHI_CSVfile(filename)
% Import all csv files as data
% this will start importing all the .csv files in that folder.
% if you get errors, it is probably because you have other .csv files that
% aren't EIS measurements. Make sure all .csv files in the folder are EIS
% measurements.

% Function to find the starting row
find_start_row = @(filename) findRowWithWord(filename, 'Freq/Hz') + 2;

startRow = find_start_row(filename);

opts = delimitedTextImportOptions("NumVariables", 5);
opts.DataLines = [startRow, Inf]; % Start importing from the identified row
opts.Delimiter = ",";
opts.VariableNames = ["Freq", "Zreal", "Zimag", "Zmod", "Zphz"];
opts.VariableTypes = ["double", "double", "double", "double", "double"];
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

Data = readtable(filename, opts);
end

function row = findRowWithWord(filename, word)
    fid = fopen(filename, 'r');
    row = 0;
    tline = fgetl(fid);
    while ischar(tline)
        row = row + 1;
        if contains(tline, word)
            break;
        end
        tline = fgetl(fid);
    end
    fclose(fid);
end