% M. Donoughue 
% Intended to impliment the iterative approach for stiffness matching as
% oiutlined in Boeman et al.

clear;

%Set variables
substrate_height = 1; % Substrate height (normalised to 1)
backing_beam_height = 0; %Backing beam height

%Thermo and backing are chosen here, change string to change material
ThermoMaterial='ePLA'; %PVDF,PLA,ABS,ePLA
BackingMaterial='ePLA'; %PVDF,PLA,ABS,ePLA

%NOTE: For PLA as backing ePLA is preffered as TDS is avalable

%2.45 GPa for PVDF (3DxTech)
%2.4 GPa for ABS
%(https://store.makerbot.com/3d-printers-materials/method-materials/abs-material/abs#Y2DOWUW)
% 2.6 GPa for standard PLA
% 2.865 GPa for ePLA (Ecomax PLA, 3DXTech)
%https://www.iemai3d.com/wp-content/uploads/2021/03/PLA_TDS__EN.pdf
%Material choices for thermoplastic
if strcmp(ThermoMaterial, 'PLA')
    Thermo_youngs_modulus=2.6e9;
elseif strcmp(ThermoMaterial, 'ePLA' )
    Thermo_youngs_modulus=2.865e9;
elseif strcmp(ThermoMaterial,  'PVDF')
    Thermo_youngs_modulus=2.45e9;
elseif strcmp(ThermoMaterial, 'ABS')
    Thermo_youngs_modulus=2.4e9;
else 
    material='Error';
    Thermo_youngs_modulus=0;
    disp('Not valid, change or enter material type')
end

%material choices for backing
if strcmp(BackingMaterial, 'PLA')
    Back_youngs_modulus=2.6e9;
elseif strcmp(BackingMaterial, 'ePLA' )
    Back_youngs_modulus=2.865e9;
elseif strcmp(BackingMaterial,  'PVDF')
    Back_youngs_modulus=2.45e9;
elseif strcmp(BackingMaterial, 'ABS')
    Back_youngs_modulus=2.4e9;
else 
    material='Error';
    Thermoplastic_youngs_modulus=0;
    disp('Not valid, change or enter material type')
end

%sample parameters
htpb_youngs_modulus = 1490000000; %Substrate material E
specimen_width = .024; % Specimen width
Total_Thickness=12.7; %mm


substrate_Y = substrate_height/2; %Substrate neutral axis
%find initial stiffness
thermo_stiffness = (specimen_width*Thermo_youngs_modulus*(substrate_height^3)/12)+(specimen_width*Thermo_youngs_modulus*substrate_height*(substrate_height-substrate_Y+backing_beam_height/2)^2);
composite_Y = ((backing_beam_height*(substrate_height+backing_beam_height/2)+(htpb_youngs_modulus*(substrate_height)^2)/(2*Back_youngs_modulus)))/(backing_beam_height+substrate_height*(htpb_youngs_modulus/Back_youngs_modulus));
Comp_stiffness = (specimen_width*Back_youngs_modulus*(backing_beam_height^3))/12+specimen_width*Back_youngs_modulus*backing_beam_height*(substrate_height-substrate_Y+backing_beam_height/2)^2 + (specimen_width*htpb_youngs_modulus*(substrate_height^3))/12+specimen_width*htpb_youngs_modulus*substrate_height*(substrate_Y-substrate_height/2)^2;

%composite (backed) leg stiffness increased by addition of thicker backing
%until stiffness is matched
while Comp_stiffness < thermo_stiffness
     comp1 = (substrate_height + (0.5 * backing_beam_height)) * backing_beam_height;
     comp2 = ((substrate_height ^ 2) * htpb_youngs_modulus) / (2 * Back_youngs_modulus);
     comp3 = backing_beam_height + (substrate_height * (htpb_youngs_modulus / Back_youngs_modulus));
     composite_Y= (comp1 + comp2) / comp3;
     comp4 = (specimen_width * htpb_youngs_modulus * (substrate_height ^ 3)) / 12;
     comp5 = (specimen_width * htpb_youngs_modulus * substrate_height) * ((composite_Y - (substrate_height / 2)) ^ 2);
     comp6 = (specimen_width * Back_youngs_modulus * (backing_beam_height ^ 3)) / 12;
     comp7 = (specimen_width * Back_youngs_modulus * backing_beam_height) * ((substrate_height + (backing_beam_height / 2) - composite_Y) ^ 2);
     Comp_stiffness= comp4 + comp5 + comp6 + comp7;
     backing_beam_height = backing_beam_height + .000001;
 end

 %Previous measurements were mormalized to the substrate thickness, so
 %converted into thickness here
 Adjustment_Factor=Total_Thickness/(backing_beam_height+substrate_height*2);
 Sub_out=Adjustment_Factor*substrate_height;
 Back_out=Adjustment_Factor*backing_beam_height;

 %print the results
 disp(material)
 disp("Sample should be:")
 disp([num2str(Sub_out),' mm thermoplastic (substrate)'])
 disp([num2str(Sub_out), ' mm HTPB'])
 disp([num2str(Back_out),' mm thermoplstic (backing)'])