clear; clc;
%Parameter & Systemaufbau (Doppelleitung)
Sn = 1000; % MVA
Un = 380;  % kV (in pu Rechnung)
Zn = (380^2)/Sn; 
U1 = 1.0; 
delta1 = 0.0; % Slack

% Leitungsparameter
n_active = 2;  % 1 - N-1 Fall, 2 - N-0 Fall
R_L = 1.214/58*200;  
X_L = 17.66/58*200;   
C_L = 13*10^(-9)*200; 

z_line_s = (R_L + 1j*X_L)/Zn;
y_line_s = 1 / z_line_s;
y_line_q = 2*pi*50*C_L/(1/Zn);

% Admittanzmatrix
Y_bus = [ (n_active*(y_line_s+y_line_q/2)), -(n_active*y_line_s);
         -(n_active*y_line_s),  (n_active*(y_line_s+y_line_q/2))];
Y_mag = abs(Y_bus);
theta = angle(Y_bus);

% Vorgegebene Last (P2/Q2)
P2_soll = -1.5; 
Q2_soll = 0.5;
epsilon = 1e-5; %Fehlerabweichung
max_iter = 20;

% Zustandsraum mittels Gitter definieren
res = 150; % Auflösung (150x150 Punkte)
u2_range = linspace(0.01, 2.0, res);      % Startspannung von 0 bis 2 pu
d2_range = linspace(-pi, pi, res);        % Startwinkel von -180 bis 180 Grad

[D2_start, U2_start] = meshgrid(d2_range, u2_range);
Conv_Map = zeros(size(D2_start)); % 0=Divergenz, 1=Stabile Lösung, 2=Instabile Lösung
Iter_Map = zeros(size(D2_start)); % Benötigte Iterationen

%% 3. Simulation über das Gitter
fprintf('Simuliere Konvergenzregionen für %d Punkte...\n', numel(D2_start));

for i = 1:numel(D2_start)
    U2 = U2_start(i);
    delta2 = D2_start(i);
    converged = false;
    
    for k = 1:max_iter
        % Leistungsflussgleichungen
        P2_c = U2 * U1 * Y_mag(2,1) * cos(theta(2,1) + delta1 - delta2) + ...
               U2^2 * Y_mag(2,2) * cos(theta(2,2));
        Q2_c = -U2 * U1 * Y_mag(2,1) * sin(theta(2,1) + delta1 - delta2) - ...
               U2^2 * Y_mag(2,2) * sin(theta(2,2));

        dP = P2_soll - P2_c;
        dQ = Q2_soll - Q2_c;
        
        if norm([dP, dQ]) < epsilon
            converged = true;
            break;
        end

        % Jacobi-Matrix
        J11 = U2 * U1 * Y_mag(2,1) * sin(theta(2,1) + delta1 - delta2); % Ableitung nach dem Spannungswinkel (P)
        J12 = U1 * Y_mag(2,1) * cos(theta(2,1) + delta1 - delta2) + 2*U2*Y_mag(2,2)*cos(theta(2,2)); %Ableitung nach der Spannung (P)
        J21 = U2 * U1 * Y_mag(2,1) * cos(theta(2,1) + delta1 - delta2); % ableitung der Blindleistungsgleichung nach dem Spannungswinkel
        J22 = -U1 * Y_mag(2,1) * sin(theta(2,1) + delta1 - delta2) - 2*U2*Y_mag(2,2)*sin(theta(2,2)); % Ableitung nach der Spannung (Q)
        
        % Update Schritt
        x = [J11, J12; J21, J22] \ [dP; dQ];
        delta2 = delta2 + x(1);
        U2 = U2 + x(2);
        
        if abs(U2) > 5, break; end % Divergenz-Check
    end
    
    if converged
        % Unterscheidung der Lösungen
        if U2 > 0.53
            Conv_Map(i) = 1; % Blau, stabil
        else
            Conv_Map(i) = 2; % Rot, instabil
        end
        Iter_Map(i) = k;
    else
        Conv_Map(i) = 0; % Weiß, kiene Konvergenz
    end
end

% Visualisierung
%Hier kam Ki zum Einsatz
figure('Color', 'w', 'Position', [100, 100, 1100, 450]);

% Linker Plot: Einzugsbereiche der Lösungen
subplot(1,2,1);
imagesc(rad2deg(d2_range), u2_range, Conv_Map);
set(gca, 'YDir', 'normal');
colormap(gca, [1 1 1; 0 0.4 0.8; 0.8 0.2 0]); % Weiß, Blau, Rot
xlabel('Start-Winkel \delta_2 [Grad]'); ylabel('Start-Spannung U_2 [pu]');
title('Konvergenzregionen (Blau: Stabil, Rot: Instabil)');

% Rechter Plot: Iterations-Heatmap (zeigt die fraktalen Grenzen)
subplot(1,2,2);
imagesc(rad2deg(d2_range), u2_range, Iter_Map);
set(gca, 'YDir', 'normal');
colormap(gca, jet); colorbar;
xlabel('Start-Winkel \delta_2 [Grad]'); ylabel('Start-Spannung U_2 [pu]');
title('Anzahl der Iterationen (Fraktale Struktur)');