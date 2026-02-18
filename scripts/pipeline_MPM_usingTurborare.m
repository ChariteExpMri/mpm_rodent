

%% ==================================================================
%%  MPM pipeline
%% turborare is used as 't2.nii' and registered to MD/T1/PD space,
%% --->advantage: better biascorrection compared to scenario where
%% 1st volume of T1(or MT/PD) is used as 't2.nii'
%% ===================================================================

%%  ######################################################################
%%  [PART-1] ANTx-setup, BRUKER IMPORT, CONFIGURATIONS
%%  ######################################################################


%% ===============================================
%% [1]  set parameter
%% ===============================================

try; antcb('close'); end
clear all
cf;clear, clc, warning off;

v.study      ='H:\Daten-2\Imaging\AG_Boehm_Sturm\ERC_Syn_2025\GEMI_pilot_2025\mpm_ana'; %study-folder
v.paraw      ='H:\Daten-2\Imaging\AG_Boehm_Sturm\ERC_Syn_2025\GEMI_pilot_2025\raw' ; %Bruker-rawdata-folder
v.mpm        ='D:\MATLAB\mpm'                       ;%PATH of: wrapper functions
v.MPMtoolbox ='D:\MATLAB\hMRI-toolbox-0.2.4'        ;%%PATH of: MPM-toolbox

% ===============================================
cd(v.study);
if exist(fullfile(v.study,'dat'))==7    %remove dat-folder if exist
    rmdir(fullfile(v.study,'dat'),'s');
end
%remove mpm-folder if exist
if exist(fullfile(v.study,'mpm'))==7    %remove mpm-folder if exis
    rmdir(fullfile(v.study,'mpm'),'s');
end
if exist(fullfile(v.study,'templates'))==7  %remove templates-folder if exist
    rmdir(fullfile(v.study,'templates'),'s');
end

%% ===============================================
%% [2]  make ANTx-project
%% ===============================================
cprintf('*[0 .5 0]',['MAKE ANTX-PROJECT '  '\n']);
makeproject('projectname',fullfile(v.study,'proj.m'), 'voxsize',[.07 .07 .07],...
    'wa_refpath','D:\MATLAB\anttemplates\mouse_Allen2017HikishimaLR',...
    'wa_species','mouse')
antcb('load',fullfile(v.study,'proj.m')); % LOAD A PROJECT-FILE "proj.m"

%% ===============================================
%% [3]  import Bruker data
%% ===============================================
cprintf('*[0 .5 0]',['IMPORT BRUKER DATA '  '\n']);
% DISPLAY all Bruker-files from 'raw'-folder, PLEASE INSPECT THE TABLE BEFORE DOING THE NEXT STEP
w1=xbruker2nifti(v.paraw,0,[],[],'gui',0,'show',1);
% ===============================================
% FILTER and DISPLAY a list of Bruker files for MPM-files
protocol='MPM_3D';
%THIS MIGHT CONTAIN MAGNITUDE AND PHASE VOLUMES
w2=xbruker2nifti(w1,0,[],[],'gui',0,'show',1,'flt',...
    {'protocol',protocol});
%USE ONLY THE MAGNITUDE VOLUME BY USING ONLY THE PrcNo OF [1]
w2=xbruker2nifti(w1,0,[],[],'gui',0,'show',1,'flt',...
    {'protocol',protocol,'PrcNo','1'});
% ===============================================
% IMPORT Bruker files where the protocol name contains MPM-data
w3=xbruker2nifti(w2,0,[],[],'gui',0,'show',0,'flt',{'protocol',protocol},...
    'paout',fullfile(v.study,'dat'),'ExpNo_File',1);
%IMPORT TURBORARE
w4=xbruker2nifti(w1,0,[],[],'gui',0,'show',0,'flt',{'protocol','TurboRARE'},...
    'paout',fullfile(v.study,'dat'),'ExpNo_File',1);
dispfiles;% check files

%% ==============================================
%%  [4] rename files
%% ===============================================
cprintf('*[0 .5 0]',['RENAME FILES '  '\n']);
antcb('selectdirs','all');
xrename(0,['.*' protocol '.*pd' '.*'],'in_PD.nii','copy');
xrename(0,['.*' protocol '.*t1' '.*'],'in_T1.nii','copy');
xrename(0,['.*' protocol '.*mt' '.*'],'in_MT.nii','copy');
xrename(0,['.*' 'TurboRARE'  '.*'],'t2.nii','copy');
dispfiles;% check files

%% =========================================================================================================================
%%  [5] change ANTx-config: 
%%  Because brains are skullstripped and stored in PBS --> we use another segmentation-type(6)
%% ==========================================================================================================================
cprintf('*[0 .5 0]',['SET  TYPE OF SKULLSTRIPPING'  '\n']);
antcb('set','wa.usePriorskullstrip',6);
drawnow;


%%  ######################################################################
%%  [PART-2] MPM-ANALYSIS
%%  ######################################################################

%% =========================================================================================================================
%% [6] set path of MPM-wrapper functions  (or use hyperlink from cmd-window)
%% ==========================================================================================================================
cprintf('*[0 .5 0]',['ADD MPM-PATH'  '\n']);
cd(v.mpm)  ; %go to mpm-wrapper functions
mpmlink    ; %add path path of mpm-wrapper-functions
cd(v.study); %go back to study-path

%% ==============================================
%% [7] MPM-setup
%% ==============================================
cprintf('*[0 .5 0]',['MPM-SETUP'  '\n']);
f_setup('ini','mpm.MPM_path',v.MPMtoolbox); % initialize MPM for this study

my_MPMpath=fullfile(v.study,'mpm'); %folder with MPM-configuration for this study
config    =fullfile(my_MPMpath, 'mpm_config'); %this file is created and is modifed in below steps
excelfile =fullfile(my_MPMpath,'mpm_NIFTIparameters.xlsx');%this file is created and is modifed in below steps

%% ==============================================
%%  [8] check files (not needed now)
%% ===============================================
% edit(config)
cprintf('*[0 .5 0]',['CHECK FILES..MANUALLY CHANGE SETTINGS IF NEEDED'  '\n']);
disp(['<a href="matlab: edit(''' config ''');">' 'edit mpm_config-file'...
    '</a>' ' * please check the configfile* ']);
showinfo2(['excelfile-riginal'],excelfile);

%% ==========================================================
%% [9] write MPM-file names in the excelfile (2nd column)
%% ===========================================================
cprintf('*[0 .5 0]',['WRITE NAMES OF MPM-FILES IN EXCELFILE'  '\n']);
[~,~,a0]=xlsread(excelfile,1);
ha=a0(1,:);
a =a0(2:end,:);
a(:,2)={nan};
a{strcmp(a(:,1),'t2w'),2}='t2.nii';
a{strcmp(a(:,1),'PD' ),2}='in_PD.nii';
a{strcmp(a(:,1),'MT' ),2}='in_MT.nii';
a{strcmp(a(:,1),'T1' ),2}='in_T1.nii';
pwrite2excel(excelfile,{1 'blanko-1'}, ha,[],a);
showinfo2(['excelfile-modified'],excelfile);

%% ========================================================================
%% [10] get orientation from 't2.nii'-space to 'T1/MT/PD'-space
%% please check HTML-file for best preorientation ..than go to next step
%% ========================================================================
f_getconfig(config); % load MPM-config of this study
f_estimPreorientHTML()
%PLEASE CHECK THE HTML-FILE before running the next step (f_setup)!
% --> here the best preorientation is: rotTable-Index [14]: which is '1.5708 0 1.5708'
%--> thus, in the next step we'll set 'mpm.t2w_preorient' to [1.5708 0 1.5708]

%% ================================================================
%% [11] set preorientation from 't2.nii'-space to 'AVGT.nii'-space
%% via f_setup('update',...
%% ================================================================
f_setup('update','mpm.MPM_path',v.MPMtoolbox, 'mpm.t2w_preorient',[1.5708 0 1.5708]);

showinfo2(['excelfile-modified'],excelfile);
disp(['<a href="matlab: edit(''' config ''');">' 'edit mpm_config-file'...
    '</a>' ' * please check the configfile* ']);

%% ============================================================================
%% [12] set preorientation from  'T1/MT/PD'-space to  'AVGT.nii'-space
%% please check HTML-file for best preorientation ..than go to next step
%% ============================================================================
antcb('selectdirs','all');
mdirs= antcb('getsubjects');
F1=fullfile(mdirs{1}, 'in_T1.nii');           %use 'T1' from 1st animal
F2=fullfile(v.study,'templates','AVGT.nii');  %use 'AVGT.nii' from template-path
z=[];
z.source       =F1;%source image ('T1/MT/PD'-space)
z.target       =F2;%reference image ('AVGT.nii'-space)
z.outputstring ='sameOrient'; % % prefix of HTML-fileName
xgetpreorientationHTML(0,z);

%% ==========================================================================
%% [13] set preorientation from 'T1/MT/PD'-space to 'AVGT.nii'-space
%% best preorientation is rotTable-Index [11]: which is '3.1416 0 1.5708'
%% ==========================================================================
antcb('set','wa.orientType',11);

%% ==============================================
%% [14]  RUN MPM-analysis
%%     to see steps, type:  mpm('steps')
%% ===============================================
clear global mpm
cprintf('*[0 .5 0]',['RUN MPM'  '\n']);
loadconfig(fullfile(v.study,'proj.m')); %load ANTX-project of current study

w=struct();
w.mpm_configfile   = fullfile(v.study,'mpm','mpm_config.m' );  % mpm-configfile
w.antx_configfile  = fullfile(v.study,'proj.m' );              % antx-projectfile(configfile)
w.pstep            = 'all' ;%preprocessing steps,'all' or use indices([1:5]; see mpm('steps')
w.hstep            = 'all' ;%hmri-processing steps,'all' or use indices([1:5]; see mpm('steps');
w.mdirs=antcb('getallsubjects')  ; % path of animals-DIRs to process
mpm('nogui',w)             ; % run proccessing steps without GUI





