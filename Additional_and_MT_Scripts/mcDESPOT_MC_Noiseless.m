%% Performs MC simulations for histograms.

close all; clear all;

% Tissue and sequence parameters.
%T1_F = 0.45; T1_S = 1.4; T2_F = 0.015; T2_S = 0.09; M0_F = 0.15; k_FS = 0:4:20; Delta = 0; PC1 = 0 + Delta; PC2 = pi + Delta;

T1_S = 1; T1_F = 0.35; T2_S = 0.080; T2_F = 0.015; k_FS = 0:1:20; M0_F = 0.25; Delta = 0; PC1 = 0 + Delta; PC2 = pi + Delta; % kFS = 10
%T1_S = 1.15; T1_F = 0.4; T2_S = 0.11; T2_F = 0.02; k_FS = 7.5; M0_F = 0.175; Delta = 0; PC1 = 0 + Delta; PC2 = pi + Delta;
%T1_S = 1.3; T1_F = 0.45; T2_S = 0.14; T2_F = 0.025; k_FS = 5; M0_F = 0.1; Delta = 0; PC1 = 0 + Delta; PC2 = pi + Delta;

TR_SPGR = 6.5e-3; TR_SSFP = 6.5e-3; FA_SPGR = deg2rad([2 4 6 8 10 12 14 16 18 20]); FA_SSFP180 = deg2rad([2 6 14 22 30 38 46 54 62 70]); FA_SSFP0 = deg2rad([2 6 14 22 30 38 46 54 62 70]);
%TR_SPGR = 7e-3; TR_SSFP = 7e-3; FA_SPGR = deg2rad([6 8 10 12 14 16]); FA_SSFP180 = deg2rad([15 25 35 45 55 65]); FA_SSFP0 = deg2rad([25 55]);
%TR_SPGR = 5.6e-3; TR_SSFP = 4.4e-3; FA_SPGR = deg2rad([4 5 6 7 9 11 14 18]); FA_SSFP0 = deg2rad([12 16 19 23 27 34 50 70]); FA_SSFP180 = deg2rad([12 16 19 23 27 34 50 70]);

%% Perform stochastic region contraction.

Realisations = 1; Trials = 40000; Iterations = 30; N = 50; Runs = 1; Params = 5;

Solution_B = zeros(length(k_FS),Realisations,Params);
Solution_D = zeros(length(k_FS),Realisations,Params);
Solution_W = zeros(length(k_FS),Realisations,Params);
Solution_Z = zeros(length(k_FS),Realisations,Params);

delete(gcp('nocreate')); c = parcluster('local'); c.NumWorkers = 8; parpool(c, c.NumWorkers);

for ii = 1:length(k_FS)
    
    % Ground-truth signals for mcDESPOT.
    SPGR_Data = SPGR_SteadyState(FA_SPGR, TR_SPGR,'T1_S',T1_S,'T1_F',T1_F,'M0_F',M0_F,'k_FS',k_FS(ii));
    SSFP_Data_0 = SSFP_SteadyState(FA_SSFP0, TR_SSFP, PC1,'T1_S',T1_S,'T2_S',T2_S,'T1_F',T1_F,'T2_F',T2_F,'M0_F',M0_F,'k_FS',k_FS(ii));
    SSFP_Data_180 = SSFP_SteadyState(FA_SSFP180, TR_SSFP, PC2,'T1_S',T1_S,'T2_S',T2_S,'T1_F',T1_F,'T2_F',T2_F,'M0_F',M0_F,'k_FS',k_FS(ii));
    
    % Concatenate SSFP signals.
    SSFP_Data = [SSFP_Data_0 ; SSFP_Data_180];
    
    % Define SNR and define wrt mean SPGR signal.
    SNR = 30; Sigma = mean(SPGR_Data)/SNR;
    
    parfor tt = 1:Realisations

        SPGR_Data_Norm = SPGR_Data./mean(SPGR_Data);
        SSFP_Data_Norm = SSFP_Data./mean(SSFP_Data);
        Data_Noiseless = [SPGR_Data_Norm ; SSFP_Data_Norm];
        
        % Post-normalisation.
        %[Solution(tt,:), ~, ~] = SRC_Sim(Trials, Iterations, N, Runs, FA_SPGR, FA_SSFP0, FA_SSFP180, TR_SPGR, TR_SSFP, Data_NN);
        [Solution_B(ii,tt,:), ~, ~] = SRC_Sim_NoExB(Trials, Iterations, N, Runs, FA_SPGR, FA_SSFP0, FA_SSFP180, TR_SPGR, TR_SSFP, Data_Noiseless);
        [Solution_D(ii,tt,:), ~, ~] = SRC_Sim_NoExD(Trials, Iterations, N, Runs, FA_SPGR, FA_SSFP0, FA_SSFP180, TR_SPGR, TR_SSFP, Data_Noiseless);
        [Solution_W(ii,tt,:), ~, ~] = SRC_Sim_NoExW(Trials, Iterations, N, Runs, FA_SPGR, FA_SSFP0, FA_SSFP180, TR_SPGR, TR_SSFP, Data_Noiseless);
        [Solution_Z(ii,tt,:), ~, ~] = SRC_Sim_NoExZ(Trials, Iterations, N, Runs, FA_SPGR, FA_SSFP0, FA_SSFP180, TR_SPGR, TR_SSFP, Data_Noiseless);
        
    end
    
    disp(['k_{FS} Trial Completed: ', num2str(k_FS(ii))])
    
end