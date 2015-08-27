function [Answer, Cancelled] = getLUTparams()
% Get parameters for lookup table generation, using 'inputsdlg'

Formats = {};
Prompt = {};
DefAns = {};
Options.Resize = 'on';
Options.Interpreter = 'tex';
Options.CancelButton = 'on';
Options.ApplyButton = 'off';
Options.Buttonnames = {'Ok', 'Quit'};

Title = 'LUT paramter selection';

% Immersion medium:
Prompt(1,:) = {'  Immersion:   ', 'medium', []};
Formats(1,1).type = 'list';
Formats(1,1).style = 'togglebutton';
Formats(1,1).format = 'text';
Formats(1,1).items = {'air','water'};
DefAns.medium = 'air';

% Film material
Prompt(2,:) = {'Film Material: ', 'film', []};
Formats(1,2).type = 'list';
Formats(1,2).style = 'togglebutton';
Formats(1,2).format = 'text';
Formats(1,2).items = {'SiO2','PMMA'};
DefAns.film = 'SiO2';

% Approximate film thickness
Prompt(3,:) = {' Approximate t:', 'dApprox', []};
Formats(2,1).type = 'edit';
Formats(2,1).style = 'edit';
Formats(2,1).format = 'float';
Formats(2,1).size = [50 30];
DefAns.dApprox = 100;

% Lookup table increment
Prompt(4,:) = {'  Increment:   ', 'dt', []};
Formats(2,2).type = 'edit';
Formats(2,2).style = 'edit';
Formats(2,2).format = 'float';
Formats(2,2).size = [50 30];
DefAns.dt = 0.1;

% Lookup table nm above
Prompt(5,:) = {'  Look above:  ', 'plus', []};
Formats(3,1).type = 'edit';
Formats(3,1).style = 'edit';
Formats(3,1).format = 'float';
Formats(3,1).size = [50 30];
DefAns.plus = 10;

% Lookup table nm below
Prompt(6,:) = {'  Look below:  ', 'minus', []};
Formats(3,2).type = 'edit';
Formats(3,2).style = 'edit';
Formats(3,2).format = 'float';
Formats(3,2).size = [50 30];
DefAns.minus = 10;

% Temperature
Prompt(7,:) = {'Temperature (C)', 'temperature', []};
Formats(4,1).type = 'edit';
Formats(4,1).style = 'edit';
Formats(4,1).format = 'float';
Formats(4,1).size = [50 30];
DefAns.temperature = 20;

% Method:
Prompt(8,:) = {'    Method:    ', 'method', []};
Formats(4,2).type = 'list';
Formats(4,2).style = 'togglebutton';
Formats(4,2).format = 'text';
Formats(4,2).items = {'accurate','relative'};
DefAns.method = 'accurate';

[Answer,Cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options);

end