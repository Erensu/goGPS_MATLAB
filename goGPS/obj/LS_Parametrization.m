%   CLASS LS_Parametrization
% =========================================================================
%
% DESCRIPTION
%   Class to handle the possible paramterization of the various GNSS
%   unknonw in a LS system
%
% EXAMPLE
%   LSP = LS_Parametrization();
%
% SEE ALSO
%   - Least_Square
% FOR A LIST OF CONSTANTs and METHODS use doc Main_Settings

%--------------------------------------------------------------------------
%               ___ ___ ___
%     __ _ ___ / __| _ | __|
%    / _` / _ \ (_ |  _|__ \
%    \__, \___/\___|_| |___/
%    |___/                    v 1.0 beta 3jp
%
%--------------------------------------------------------------------------
%  Copyright (C) 2009-2019 Mirko Reguzzoni, Eugenio Realini
%  Written by:       Giulio Tagliaferro
%  Contributors:     
%  A list of all the historical goGPS contributors is in CREDITS.nfo
%--------------------------------------------------------------------------
%
%    This program is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%--------------------------------------------------------------------------
% 01100111 01101111 01000111 01010000 01010011
%--------------------------------------------------------------------------
classdef LS_Parametrization < handle
    properties (Constant)
        % time paramterization
        CONST = 1;
        EP_WISE = 2;
        STEP_CONST = 3;
        SPLINE_ZERO = 4;
        SPLINE_LIN = 5;
        SPLINE_CUB = 6;
        RULE_BASED = 7;
        
        % rec paramterization
        SING_REC = 1;
        MULTI_REC = 2;
        ALL_REC = 3;
        
        % sat paramterization
        SING_SAT = 1;
        MULTI_SAT = 2;
        ALL_SAT = 3;
        
        % track paramterization paramterization
        SING_TRACK = 1;
        SINGLE_FREQ = 2;
        ALL_FREQ = 3;
        RULE = 5; % warnign only sequential & allowed
        
        % spatial paramterization 
        %TBD
    end
    
    properties
        % paramterization [(time paramterization) (rec paramterization) (sat paramterization) (tracking paramterization)]
        rec_x = [this.CONST this.SING_REC this.ALL_SAT this.ALL_FREQ];
        rec_y = [this.CONST this.SING_REC this.ALL_SAT this.ALL_FREQ];
        rec_z = [this.CONST this.SING_REC this.ALL_SAT this.ALL_FREQ];
        
        sat_x = [this.EP_WISE this.ALL_REC this.SING_SAT this.ALL_FREQ];
        sat_y = [this.EP_WISE this.ALL_REC this.SING_SAT this.ALL_FREQ];
        sat_z = [this.EP_WISE this.ALL_REC this.SING_SAT this.ALL_FREQ];
        
        rec_eb = [this.CONST this.SING_REC this.ALL_SAT this.RULE];
        rec_eb_line = [this.CONST this.SING_REC this.ALL_SAT this.RULE];

        
        sat_eb = [this.CONST this.ALL_REC this.SING_SAT this.SING_TRACK];
        
        amb  = [this.STEP_CONST this.SING_REC this.SING_SAT this.SING_TRACK];

        rec_clk = [this.EP_WISE this.ALL_REC this.ALL_SAT this.ALL_FREQ];
        sat_clk = [this.EP_WISE this.ALL_REC this.SING_SAT this.ALL_FREQ];
      
        tropo = [this.EP_WISE this.SING_REC this.ALL_SAT this.ALL_FREQ];
        tropo_n = [this.EP_WISE this.SING_REC this.ALL_SAT this.ALL_FREQ];
        tropo_e = [this.EP_WISE this.SING_REC this.ALL_SAT this.ALL_FREQ];
        tropo_s =  [this.SPLINE_CUB this.SING_REC this.SING_SAT this.ALL_FREQ];
        tropo_v = [this.EP_WISE this.ALL_REC this.ALL_SAT this.ALL_FREQ];
              
        iono =  [this.EP_WISE this.SING_REC this.SING_SAT this.SING_FREQ];
             
        ant_mp = [this.CONST this.SING_REC this.ALL_SAT this.SING_FREQ];
        
        % options to keep track of spline rate, rule based distinction,
        % cycle slips
        rec_x_opt;
        rec_y_opt;
        rec_z_opt;
        rec_eb_opt;
        rec_eb_opt_lin;
        rec_eb_opt.rule      = {['PSRANGE:' num2str(this.SING_TRACK)],['PHASE&NOT*GLONASS:' num2str(this.SING_FREQ)],['PHASE&GLONASS:ALL_FREQ' num2str(this.ALL_FREQ)]};
        rec_eb_opt_line.rule = {['PHASE&GLONASS:' num2str(this.ALL_FREQ)]};

        amb_opt;
        rec_clk_opt;
        tropo_opt;
        tropo_n_opt;
        tropo_e_opt;
        tropo_v_opt;
        sat_clk_opt;
        ant_mp_opt;
        iono_opt;
        tropo_s_opt.spline_rate = 900;
        sat_x_opt;
        sat_y_opt;
        sat_z_opt;
        sat_eb_opt;
    end
    
    methods
        function [parametriz, option] = getParametrization(this, par_class)
            % get the parametrization and the options for the paramter
            % class p
            %
            % SYNTAX:
            %    [parametriz, option] = getParametrization(this, par_class)
            switch par_class
                case LS_Manipulator_new.PAR_REC_X
                    parametriz = this.rec_x;
                    option = this.rec_x_opt;
                case LS_Manipulator_new.PAR_REC_Y
                    parametriz = this.rec_y;
                    option = this.rec_y_opt;
                case LS_Manipulator_new.PAR_REC_EB
                    parametriz = this.rec_eb;
                    option = this.rec_eb_opt;
                case LS_Manipulator_new.PAR_REC_EB_LIN
                    parametriz = this.rec_eb_lin;
                    option = this.rec_eb_lin_opt;
                case LS_Manipulator_new.PAR_SAT_EB
                    parametriz = this.sat_eb;
                    option = this.rec_x_opt;
                case LS_Manipulator_new.PAR_AMB
                    parametriz = this.amb;
                    option = this.amb_opt;
                case LS_Manipulator_new.PAR_REC_CLK
                    parametriz = rec_clk;
                    option = this.rec_clk_opt;
                case LS_Manipulator_new.PAR_SAT_CLK
                    parametriz = sat_clk;
                    option = this.sat_clk_opt;
                case LS_Manipulator_new.PAR_TROPO
                    parametriz = this.tropo;
                    option = this.tropo_opt;
                case LS_Manipulator_new.PAR_TROPO_N
                    parametriz = this.tropo_n;
                    option = this.tropo_n_opt;
                case LS_Manipulator_new.PAR_TROPO_S
                    parametriz = this.tropo_s;
                    option = this.tropo_s_opt;
                case LS_Manipulator_new.PAR_TROPO_E
                    parametriz = this.tropo_e;
                    option = this.tropo_e_opt;
                case LS_Manipulator_new.PAR_TROPO_V
                    parametriz = this.tropo_v;
                    option = this.tropo_v_opt;
                case LS_Manipulator_new.PAR_IONO
                    parametriz = this.iono;
                    option = this.iono_opt;
                case LS_Manipulator_new.PAR_ANT_MP
                    parametriz = this.ant_mp;
                    option = this.ant_mp_opt;
            end
        end
    end
end
