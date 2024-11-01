function [Imp, var_names] = CirStr2FuncHan(circuit_str)
% This function will take a circuit string and convert it to a function
% handle and return it as Imp(element_vals). Where element_vals is used as
% a cell array of input variables. The names of those variables are
% returned as a cell array of chars in var_names.
% Initialize counters
R_count = 0;
C_count = 0;
L_count = 0;
W_count = 0;
O_count = 0;
T_count = 0;
G_count = 0;
% % extra gerischer elements
% FracG_count = 0;
% FinG_count = 0;


% Create a list to store variable names
var_list = {};

% Initialize the expression
expr_str = circuit_str;

% Replace 's(' with '(' (since series addition is just addition)
%expr_str = strrep(expr_str, 's(', '(');

% Replace 'p(' with 'par(' to handle parallel configurations
%expr_str = strrep(expr_str, 'p(', 'par(');

% Replace each occurrence of 'R', 'C', 'L' with unique variable names
% and their impedance expressions
[expr_str, var_list, R_count] = replace_elements(expr_str, 'R',...
    @(n) ['R' num2str(n)], @identity, var_list, R_count);
[expr_str, var_list, C_count] = replace_elements(expr_str, 'C',...
    @(n) ['C' num2str(n)], @(var) ['1./(1j.*w.*' var ')'], var_list, C_count);
[expr_str, var_list, L_count] = replace_elements(expr_str, 'L',...
    @(n) ['L' num2str(n)], @(var) ['1j.*w.*' var], var_list, L_count);
[expr_str, var_list, W_count] = replace_elements(expr_str, 'W',...
    @(n) ['Yo_W' num2str(n)], @(var) ['1./' var './sqrt(1j.*w)'], var_list, W_count);
[expr_str, var_list, T_count] = replace_elements(expr_str, 'T',...
    @(n) ["T_Yo" + num2str(n) "T_B" + num2str(n)],...
    @(var) ['coth(' var{2} '.*sqrt(1j.*w))./' var{1} './sqrt(1j.*w)'], var_list, T_count);
[expr_str, var_list, O_count] = replace_elements(expr_str, 'O',...
    @(n) ["O_Yo" + num2str(n) "O_B" + num2str(n)],...
    @(var) ['tanh(' var{2} '.*sqrt(1j.*w))./' var{1} './sqrt(1j.*w)'], var_list, O_count);
[expr_str, var_list, G_count] = replace_elements(expr_str, 'G',...
    @(n) ["G_Yo" + num2str(n) "G_k" + num2str(n)],...
    @(var) ['(' var{2} '+1j.*w).^(-0.5)./' var{1}], var_list, G_count);
% Process 'par' functions recursively
expr_str = process_par(expr_str);
% Process 'ser' functions recursively
expr_str = process_ser(expr_str);

% Replace commas in series configurations with '+'
expr_str = process_commas(expr_str);

% Create the function handle string
% Function arguments
var_list{end+1} = 'w';
var_list_unique = unique(var_list, 'stable'); % Remove duplicates
var_names = var_list_unique;
func_args = join(var_list_unique, ',');

% Full function string
func_str = join(['@(', func_args, ') ', expr_str],'');

% Display the function string for debugging
disp("Function string: " + func_str);

% Now replace substrings to match the format of element_vars passed
% into Imp
func_str = replace(func_str,func_args,'element_vals');
for v = 1:length(var_list_unique)
    func_str = replace(func_str, var_list_unique{v}, append('element_vals{',num2str(v),'}'));
end

% Now, create the function handle
Imp = str2func(func_str{1});
end

% Helper function to replace elements with unique variables and expressions
function [expr_str, var_list, elem_count] = replace_elements(expr_str, elem_symbol, var_func, imp_func, var_list, elem_count)
% Regular expression to find standalone element symbols
pattern = ['\<', elem_symbol, '\>'];
[match_starts, match_ends] = regexp(expr_str, pattern);
% Process matches in forward order
offset = 0; % Since we are changing expr_str length
for idx = 1:length(match_starts)
    elem_count = elem_count +1;
    var_name = var_func(elem_count);
    if isstring(var_name)
        for i = 1:length(var_name)
            var_list{end+1} = var_name{i};
        end
    elseif ischar(var_name)
        var_list{end+1} = var_name;
    else
        error('var_name is not a string or char')
    end
    imp_expr = imp_func(var_name);
    % Adjust positions because expr_str length may have changed
    start_pos = match_starts(idx) + offset;
    end_pos = match_ends(idx) + offset;
    expr_str = [expr_str(1:start_pos-1), imp_expr, expr_str(end_pos+1:end)];
    % Update offset
    offset = offset + length(imp_expr) - (end_pos - start_pos +1);
end
end

% Identity function for resistors (since their impedance is just R)
function out = identity(var)
out = var;
end

% Function to process 'p' expressions recursively
function expr_out = process_par(expr_in)
% This function finds the first 'par(' and processes it
idx = strfind(expr_in, 'p(');
if isempty(idx)
    expr_out = expr_in;
    return;
else
    idx_start = idx(1) + length('p(');
    % Now, find the matching closing parenthesis
    depth = 1;
    idx_end = idx_start;
    while depth > 0 && idx_end <= length(expr_in)
        if expr_in(idx_end) == '('
            depth = depth +1;
        elseif expr_in(idx_end) == ')'
            depth = depth -1;
        end
        idx_end = idx_end +1;
    end
    idx_end = idx_end -1; % Adjust for overshoot
    % Extract the arguments
    args_str = expr_in(idx_start:idx_end-1); % Exclude last ')'
    % Split the arguments by ','
    args = split_args(args_str);
    % Process each argument recursively
    for k = 1:length(args)
        args{k} = process_par(args{k});
    end
    % Build the expression for parallel impedance
    new_expr_terms = cell(1, length(args));
    for k =1:length(args)
        new_expr_terms{k} = ['1./(', args{k}, ')'];
    end
    new_expr = ['1./(', strjoin(new_expr_terms, ' + '), ')'];
    % Replace the 'par(...)' in expr_in with new_expr
    expr_out = [expr_in(1:idx(1)-1), new_expr, expr_in(idx_end+1:end)];
    % Process again in case there are more 'par('
    expr_out = process_par(expr_out);
end
end

function expr_out = process_ser(expr_in)
% This function finds the first 's(' and processes it
idx = strfind(expr_in, 's(');
if isempty(idx)
    expr_out = expr_in;
    return;
else
    idx_start = idx(1) + length('s(');
    % Now, find the matching closing parenthesis
    depth = 1;
    idx_end = idx_start;
    while depth > 0 && idx_end <= length(expr_in)
        if expr_in(idx_end) == '('
            depth = depth +1;
        elseif expr_in(idx_end) == ')'
            depth = depth -1;
        end
        idx_end = idx_end +1;
    end
    idx_end = idx_end -1; % Adjust for overshoot
    % Extract the arguments
    args_str = expr_in(idx_start:idx_end-1); % Exclude last ')'
    % Split the arguments by ','
    args = split_args(args_str);
    % Process each argument recursively
    for k = 1:length(args)
        args{k} = process_ser(args{k});
    end
    % Build the expression for series impedance
    new_expr_terms = cell(1, length(args));
    for k =1:length(args)
        new_expr_terms{k} = [ args{k}];
    end
    new_expr = [strjoin(new_expr_terms, ' + ')];
    % Replace the 's(...)' in expr_in with new_expr
    expr_out = [expr_in(1:idx(1)-1), new_expr, expr_in(idx_end+1:end)];
    % Process again in case there are more 's('
    expr_out = process_ser(expr_out);
end
end

% Helper function to process commas in series configurations
function expr_out = process_commas(expr_in)
idx = 1;
depth = 0;
expr_out = '';
while idx <= length(expr_in)
    if expr_in(idx) == '('
        depth = depth +1;
        expr_out = [expr_out, '('];
        idx = idx +1;
    elseif expr_in(idx) == ')'
        depth = depth -1;
        expr_out = [expr_out, ')'];
        idx = idx +1;
    elseif expr_in(idx) == ',' && depth == 1
        % Replace comma with '+'
        expr_out = [expr_out, '+'];
        idx = idx +1;
    else
        expr_out = [expr_out, expr_in(idx)];
        idx = idx +1;
    end
end
end

% Helper function to split arguments, accounting for nested parentheses
function args = split_args(args_str)
args = {};
idx = 1;
depth = 0;
arg_start = 1;
while idx <= length(args_str)
    if args_str(idx) == '('
        depth = depth + 1;
    elseif args_str(idx) == ')'
        depth = depth -1;
    elseif args_str(idx) == ',' && depth == 0
        % Found argument separator
        args{end+1} = strtrim(args_str(arg_start:idx-1));
        arg_start = idx +1;
    end
    idx = idx +1;
end
% Add last argument
args{end+1} = strtrim(args_str(arg_start:end));
end
