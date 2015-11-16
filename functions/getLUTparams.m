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
Prompt(3,:) = {'Approx. T (nm):', 'dApprox', []};
Formats(2,1).type = 'edit';
Formats(2,1).style = 'edit';
Formats(2,1).format = 'float';
Formats(2,1).size = [50 30];
DefAns.dApprox = 100;

% Lookup table increment
Prompt(4,:) = {'Increment (nm):', 'dt', []};
Formats(2,2).type = 'edit';
Formats(2,2).style = 'edit';
Formats(2,2).format = 'float';
Formats(2,2).size = [50 30];
DefAns.dt = 1;

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

% Method:
Prompt(7,:) = {'    Method:    ', 'method', []};
Formats(4,1).type = 'list';
Formats(4,1).style = 'togglebutton';
Formats(4,1).format = 'text';
Formats(4,1).items = {'accurate','relative'};
DefAns.method = 'accurate';

% Consider Temperature:
Prompt(8,:) = {'Consider Temp: ', 'useTemp', []};
Formats(4,2).type = 'list';
Formats(4,2).style = 'togglebutton';
Formats(4,2).format = 'text';
Formats(4,2).items = {'No','Yes'};
DefAns.useTemp = 'No';

% Temperature
Prompt(9,:) = {'T for lut gen: ', 'temperature', []};
Formats(5,1).type = 'edit';
Formats(5,1).style = 'edit';
Formats(5,1).format = 'float';
Formats(5,1).size = [50 30];
DefAns.temperature = 25;

% Lookup table min Temp
Prompt(10,:) = {'   Min Temp:   ', 'minTemp', []};
Formats(6,1).type = 'edit';
Formats(6,1).style = 'edit';
Formats(6,1).format = 'float';
Formats(6,1).size = [50 30];
DefAns.minTemp = 25;

% Lookup table max Temp
Prompt(11,:) = {'   Max Temp:   ', 'maxTemp', []};
Formats(6,2).type = 'edit';
Formats(6,2).style = 'edit';
Formats(6,2).format = 'float';
Formats(6,2).size = [50 30];
DefAns.maxTemp = 70;


[Answer,Cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options);

end