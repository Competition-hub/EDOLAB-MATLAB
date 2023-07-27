%********************************FTMPSO*****************************************************
%Author: Delaram Yazdani
%E-mail: delaram DOT yazdani AT yahoo DOT com
%Last Edited: July 12, 2021
%
% ------------
% Reference:
% ------------
%
%  Danial Yazdani et al.,
%            "A novel multi-swarm algorithm for optimization in dynamic environments based on particle swarm optimization"
%             Applied Soft Computing 13, 4 (2013), pp. 2144�2158.
%
% --------
% License:
% --------
% This program is to be used under the terms of the GNU General Public License
% (http://www.gnu.org/copyleft/gpl.html).
% e-mail: danial DOT yazdani AT gmail DOT com
% Copyright notice: (c) 2023 Danial Yazdani
%*****************************************************************************************
function [Optimizer,Problem] = SubPopulationGenerator_FTMPSO(Dimension,MinCoordinate,MaxCoordinate,PopulationSize,Problem)
Optimizer.Gbest_past_environment = NaN(1,Dimension);
Optimizer.k=2;
Optimizer.ConvergenceLimit=1;
Optimizer.GbestPositionHistory = inf(Optimizer.k,Dimension);
Optimizer.Velocity = zeros(PopulationSize,Dimension);
Optimizer.X = MinCoordinate + ((MaxCoordinate-MinCoordinate).*rand(PopulationSize,Dimension));
[Optimizer.FitnessValue,Problem] = fitness(Optimizer.X,Problem);
Optimizer.PbestPosition = Optimizer.X;
if Problem.RecentChange == 0
    Optimizer.PbestValue = Optimizer.FitnessValue;
    [Optimizer.BestValue,GbestID] = max(Optimizer.PbestValue);
    Optimizer.BestPosition = Optimizer.PbestPosition(GbestID,:);
else
    Optimizer.FitnessValue = -inf(PopulationSize,1);
    Optimizer.PbestValue = Optimizer.FitnessValue;
    [Optimizer.BestValue,GbestID] = max(Optimizer.PbestValue);
    Optimizer.BestPosition = Optimizer.PbestPosition(GbestID,:);
end