%********************************mCMAES*****************************************************
%Authors: Delaram Yazdani and Danial Yazdani
%E-mails: delaram DOT yazdani AT yahoo DOT com
%         danial DOT yazdani AT gmail DOT com
%Last Edited: January 12, 2022
%
% ------------
% Reference:
% ------------
%
%  Danial Yazdani et al.,
%            "Scaling up dynamic optimization problems: A divide-and-conquer approach"
%             IEEE Transactions on Evolutionary Computation, vol. 24(1), pp. 1 - 15, 2019.
%
% --------
% License:
% --------
% This program is to be used under the terms of the GNU General Public License
% (http://www.gnu.org/copyleft/gpl.html).
% E-mail: danial DOT yazdani AT gmail DOT com
% Copyright notice: (c) 2023 Danial Yazdani
%*****************************************************************************************
function [Problem,E_bbc,E_o,CurrentError,VisualizationInfo,Iteration] = main_mCMAES(VisualizationOverOptimization,PeakNumber,ChangeFrequency,Dimension,ShiftSeverity,EnvironmentNumber,RunNumber,BenchmarkName)
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
    Optimizer.SwarmNumber       = 1;
    Optimizer.PopulationSize = 1;
    Optimizer.FreeSwarmID       = 1;%Index of the free swarm
    Optimizer.Dimension         = Problem.Dimension;
    Optimizer.lambda            = 5; % 4 + floor(3*log(Optimizer.Dimension));
    Optimizer.mu                = floor(Optimizer.lambda/2);
    Optimizer.weights           = log(Optimizer.mu+1/2)-log(1:Optimizer.mu)';
    Optimizer.weights           = Optimizer.weights/sum(Optimizer.weights);     % normalize recombination weights array
    Optimizer.mueff             = sum(Optimizer.weights)^2/sum(Optimizer.weights.^2);
    Optimizer.cc                = (4 + Optimizer.mueff/Optimizer.Dimension) / (Optimizer.Dimension+4 + 2*Optimizer.mueff/Optimizer.Dimension); % time constant for cumulation for C
    Optimizer.cs                = (Optimizer.mueff+2) / (Optimizer.Dimension+Optimizer.mueff+5);  % t-const for cuOptimizer.mulation for Optimizer.sigma control
    Optimizer.c1                = 2 / ((Optimizer.Dimension+1.3)^2+Optimizer.mueff);    % learning rate for rank-one update of C
    Optimizer.cmu               = min(1-Optimizer.c1, 2 * (Optimizer.mueff-2+1/Optimizer.mueff) / ((Optimizer.Dimension+2)^2+Optimizer.mueff));  % and for rank-mu update
    Optimizer.damps             = 1 + 2*max(0, sqrt((Optimizer.mueff-1)/(Optimizer.Dimension+1))-1) + Optimizer.cs; % damping for sigma
    Optimizer.chiN              = Optimizer.Dimension^0.5*(1-1/(4*Optimizer.Dimension)+1/(21*Optimizer.Dimension^2));  % expectation of
    Optimizer.MaxCoordinate     = Problem.MaxCoordinate;
    Optimizer.MinCoordinate     = Problem.MinCoordinate;
    Optimizer.MinExclusionLimit = 0.5 * ((Optimizer.MaxCoordinate-Optimizer.MinCoordinate) / ((10) ^ (1 / Optimizer.Dimension)));
    Optimizer.ExclusionLimit    = Optimizer.MinExclusionLimit;
    Optimizer.ConvergenceLimit  = Optimizer.ExclusionLimit;
    [Optimizer.pop,Problem] = SubPopulationGenerator_mCMAES(Optimizer.Dimension,Optimizer.MinCoordinate,Optimizer.MaxCoordinate,Optimizer.PopulationSize,Problem);
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
                    VisualizationInfo{Iteration}.Individuals(counter,:) = Optimizer.pop(ii).X(:,jj);
                end
            end
            VisualizationInfo{Iteration}.IndividualNumber = counter;
            VisualizationInfo{Iteration}.FE = Problem.FE;
        end
        %% Optimization
        [Optimizer,Problem] = IterativeComponents_mCMAES(Optimizer,Problem);
        if Problem.RecentChange == 1%When an environmental change has happened
            Problem.RecentChange = 0;
            [Optimizer,Problem] = ChangeReaction_mCMAES(Optimizer,Problem);
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