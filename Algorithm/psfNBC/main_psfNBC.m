%*********************************psfNBC**********************
%
%Author: Zeneng She
%Last Edited: October 30, 2022
% e-mail: shezeneng AT qq DOT com
%
% ------------
% Reference:
% ------------
%
%  Wenjian Luo et al.,
%       "Identifying Species for Particle Swarm Optimization under Dynamic Environments," 
%       Proceedings of the 2018 IEEE Symposium Series on Computational Intelligence, 2019.
%
% --------
% License:
% --------
% This program is to be used under the terms of the GNU General Public License
% (http://www.gnu.org/copyleft/gpl.html).
% e-mail: danial.yazdani AT gmail dot com
% Copyright notice: (c) 2023 Danial Yazdani
%**************************************************************************
function [Problem,E_bbc,E_o,CurrentError,VisualizationInfo,Iteration] = main_psfNBC(VisualizationOverOptimization,PeakNumber,ChangeFrequency,Dimension,ShiftSeverity,EnvironmentNumber,RunNumber,BenchmarkName)
BestErrorBeforeChange = NaN(1,RunNumber);
OfflineError = NaN(1,RunNumber);
CurrentError = NaN (RunNumber,ChangeFrequency*EnvironmentNumber);
for RunCounter=1 : RunNumber
    if VisualizationOverOptimization ~= 1
        rng(RunCounter);%This random seed setting is used to initialize the Problem
    end
    Problem = BenchmarkGenerator(PeakNumber,ChangeFrequency,Dimension,ShiftSeverity,EnvironmentNumber,BenchmarkName);
    rng('shuffle');%Set a random seed for the optimizer
    %% Initialiing Optimizer
    clear Optimizer;
    Optimizer.Dimension = Problem.Dimension;
    Optimizer.PopulationSize = 100;
    Optimizer.MaxCoordinate   = Problem.MaxCoordinate;
    Optimizer.MinCoordinate = Problem.MinCoordinate;
    Optimizer.DiversityPlus = 1;
    Optimizer.x = 0.729843788;
    Optimizer.c1 = 2.05;
    Optimizer.c2 = 2.05;
    Optimizer.RandomizingPercentage = 0.5;
    Optimizer.NumberOfRandomizingParticles = ceil(Optimizer.PopulationSize*Optimizer.RandomizingPercentage);  
    Optimizer.SwarmNumber = 1;
    Optimizer.ratio = 0.9;
    Optimizer.numInitial = (1-Optimizer.ratio)*Optimizer.PopulationSize;
    Optimizer.max_v = (Optimizer.MaxCoordinate - Optimizer.MinCoordinate)/2;
    Optimizer.min_v = -Optimizer.max_v;
    Optimizer.successfault=zeros(1,Optimizer.PopulationSize);
    %% memory
    Optimizer.Mem=[];   %% the memory saves the converged seeds and the best solutions
    Optimizer.Mem_fit=[];
    Optimizer.mem_Maxsize = 50;
    [Optimizer.pop,Problem] = SubPopulationGenerator_psfNBC(Optimizer.Dimension,Optimizer.MinCoordinate,Optimizer.MaxCoordinate,Optimizer.PopulationSize,Problem);
    VisualizationFlag=0;
    Iteration=0;
    if VisualizationOverOptimization==1
        VisualizationInfo = cell(1,Problem.MaxEvals);
    else
        VisualizationInfo = [];
    end
    %% main loop
    while 1
        Iteration = Iteration + 1;
        %% Visualization for education module
        if (VisualizationOverOptimization==1 && Dimension == 2)
            if VisualizationFlag==0
                VisualizationFlag=1;
                T = Problem.MinCoordinate : ( Problem.MaxCoordinate-Problem.MinCoordinate)/100 :  Problem.MaxCoordinate;
                L=length(T);
                F=zeros(L);
                for i=1:L
                    for j=1:L
                        F(i,j) = EnvironmentVisualization([T(i), T(j)],Problem);
                    end
                end
            end
            VisualizationInfo{Iteration}.T=T;
            VisualizationInfo{Iteration}.F=F;
            VisualizationInfo{Iteration}.Problem.PeakVisibility = Problem.PeakVisibility(Problem.Environmentcounter , :);
            VisualizationInfo{Iteration}.Problem.OptimumID = Problem.OptimumID(Problem.Environmentcounter);
            VisualizationInfo{Iteration}.Problem.PeaksPosition = Problem.PeaksPosition(:,:,Problem.Environmentcounter);
            VisualizationInfo{Iteration}.CurrentEnvironment = Problem.Environmentcounter;
            counter = 0;
            for ii=1 : Optimizer.SwarmNumber
                for jj=1 : Optimizer.PopulationSize
                    counter = counter + 1;
                    VisualizationInfo{Iteration}.Individuals(counter,:) = Optimizer.pop(ii).X(jj,:);
                end
            end
            VisualizationInfo{Iteration}.IndividualNumber = counter;
            VisualizationInfo{Iteration}.FE = Problem.FE;
        end
        %% Optimization
        [Optimizer,Problem] = IterativeComponents_psfNBC(Optimizer,Problem);
        if Problem.RecentChange == 1%When an environmental change has happened
            Problem.RecentChange = 0;
            [Optimizer,Problem] = ChangeReaction_psfNBC(Optimizer,Problem);
            VisualizationFlag = 0;
            clc; disp(['Run number: ',num2str(RunCounter),'   Environment number: ',num2str(Problem.Environmentcounter)]);
        end
        if  Problem.FE >= Problem.MaxEvals%When termination criteria has been met
            break;
        end
    end
    %% Performance indicator calculation
    BestErrorBeforeChange(1,RunCounter) = mean(Problem.Ebbc);
    OfflineError(1,RunCounter) = mean(Problem.CurrentError);
    CurrentError(RunCounter,:) = Problem.CurrentError;
end
%% Output preparation
E_bbc.mean = mean(BestErrorBeforeChange);
E_bbc.median = median(BestErrorBeforeChange);
E_bbc.StdErr = std(BestErrorBeforeChange)/sqrt(RunNumber);
E_bbc.AllResults = BestErrorBeforeChange;
E_o.mean = mean(OfflineError);
E_o.median = median(OfflineError);
E_o.StdErr = std(OfflineError)/sqrt(RunNumber);
E_o.AllResults =OfflineError;
if VisualizationOverOptimization==1
    tmp = cell(1, Iteration);
    for ii=1 : Iteration
        tmp{ii} = VisualizationInfo{ii};
    end
    VisualizationInfo = tmp;
end