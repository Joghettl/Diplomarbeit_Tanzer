% ---------------------------------------------------------
% Transient Stability Analysis - N-1 Contingency (RMS)
% 6.-Ordnung-Modell + PI-Blindleistungsregelung (PQ-Knoten)
% Inklusive exponentieller Hauptflusssättigung
% ---------------------------------------------------------
clear; clc; close all;
addpath('C:\Users\tanze\OneDrive - TU Wien\Studium\Elektrische und nachhaltige Energiesysteme\4. Semester\Masterarbeit\Matlab Simulation\Transient_stab');

%% 1. System Parameters (Per Unit)
U_base = 380e3;                  % Bezugsspannung
S_base = 1000e6;                 % Bezugsscheinleistung
Z_base = (U_base^2) / S_base;    % Bezugsimpedanz
Y_base = 1 / Z_base;             % Bezugsadmittanz

% Leitungsparameter (200 km)
R_km = 0.0209;                  % Spezifischer Leitungswiderstand R'
X_km = 0.304;                   % Spezifische Leitungsreaktanz X'
B_km = 13*1e-9 *2*pi*50;        % Spezifische Leitungsuszeptanz B'
L_line = 200;                   % Leitungslänge
Z_phys = (R_km + 1i*X_km) * L_line;     % nichtbezogene Längsimpedanz
Y_shunt_phys = (1i * B_km) * L_line;    % nichtbezogene Queradmittanz
Z_pu = Z_phys / Z_base;                 % Bezogene Längsimpedanz
Y_shunt_pu = Y_shunt_phys / Y_base;     % Bezogene Queradmittanz

p.y_series = 1 / Z_pu;                  % Bezogene Längsimpedanz
p.y_shunt_half = Y_shunt_pu / 2;        % halbe bezogene Queradmittanz für das pi Ersatzschaltbild
p.omega0 = 2 * pi * 50;                 % Kreisfrequenz

% Meshing
L_line_mesh = 200;                              % Leitungslänge der Vermaschungleitung -> Änderbarer Parameter
Z_phys_mesh = (R_km + 1i*X_km)*L_line_mesh;
Y_shunt_phys_mesh = (1i * B_km) * L_line_mesh;
p.y_series_mesh = 1 / (Z_phys_mesh/Z_base);
p.y_shunt_half_mesh = (Y_shunt_phys_mesh/Y_base)/2;

if(L_line_mesh > 200)
    p.y_series_mesh = 0; 
    p.y_shunt_half_mesh = 0;
end

%% Generatoren (6. Ordnung + PI-Blindleistungsregelung)
S_nom1 = 500e6;  % Nennleistung der Maschine
S_nom2 = 500e6;  % Nennleistung der Maschine

%% Generator 1 alle Einheiten in pu
p.H1 = 4.0 * (S_nom1 / S_base);    % Trägheitskonstante H
p.D1 = 0.1 * (S_nom1 / S_base);    % Dämpfung D
p.Xd1 = 2.0 * (S_base / S_nom1);   % synchrone Reaktanz in d-Richtung
p.Xq1 = 1.8 * (S_base / S_nom1);   % synchrone Reaktanz in q-Richtung
p.Xdp1 = 0.25 * (S_base / S_nom1); % transiente Reaktanz in d-Richtung
p.Xqp1 = 0.5 * (S_base / S_nom1);  % transiente Reaktanz in q-Richtung
p.Xdpp1 = 0.20 * (S_base / S_nom1); % subtransiente Reaktanz in d-Richtung
p.Xqpp1 = 0.20 * (S_base / S_nom1); % subtransiente Reaktanz in q-Richtung
p.Td0p1 = 5.0; % transiente Leerlaufzeitkonstante in d-Richtung
p.Tq0p1 = 1.0; % transiente Leerlaufzeitkonstante in q-Richtung
p.Td0pp1= 0.05; % subtransiente Leerlaufzeitkonstante in d-Richtung
p.Tq0pp1= 0.05; % subtransiente Leerlaufzeitkonstante in q-Richtung
p.R1 = 0.05 * (S_base / S_nom1);   % Droop für Turbinenregelung
p.Tg1 = 0.2; % Turbinen Governor 

p.Pm_max1 = 0.55; % Maximal 550 MW mechanische Leistung
p.Pm_min1 = 0.0;  % Keine negative mechanische Leistung

% Exponentielle Sättigungsparameter Generator 1 
p.E_th1 = 0.8;      % Schwellenwert / pu
p.A_sat1 = 0.05;    % Skalierungsfaktor A
p.B_sat1 = 5.0;     % Exponentieller Faktor B

% Generator 2 
p.H2 = 4.0 * (S_nom2 / S_base);    % Trägheitskonstante H
p.D2 = 0.1 * (S_nom2 / S_base);    % Dämpfung D
p.Xd2 = 2.0 * (S_base / S_nom2);   % synchrone Reaktanz in d-Richtung
p.Xq2 = 1.8 * (S_base / S_nom2);   % synchrone Reaktanz in q-Richtung
p.Xdp2 = 0.25 * (S_base / S_nom2); % transiente Reaktanz in d-Richtung
p.Xqp2 = 0.5 * (S_base / S_nom2);  % transiente Reaktanz in q-Richtung
p.Xdpp2 = 0.20 * (S_base / S_nom2); % subtransiente Reaktanz in d-Richtung
p.Xqpp2 = 0.20 * (S_base / S_nom2); % subtransiente Reaktanz in q-Richtung
p.Td0p2 = 5.0; % transiente Leerlaufzeitkonstante in d-Richtung
p.Tq0p2 = 1.0; % transiente Leerlaufzeitkonstante in q-Richtung
p.Td0pp2= 0.05; % subtransiente Leerlaufzeitkonstante in d-Richtung
p.Tq0pp2= 0.05; % subtransiente Leerlaufzeitkonstante in q-Richtung
p.R2 = 0.05 * (S_base / S_nom2);   % Droop für Turbinenregelung
p.Tg2 = 0.2; % Turbinen Governor 

p.Pm_max2 = 0.55; % Maximal 550 MW mechanische Leistung
p.Pm_min2 = 0.0;  % Minimal 0 MW mechanische Leistung

% Sättigungsparameter Generator 2
p.E_th2 = 0.8;      % Schwellenwert / pu
p.A_sat2 = 0.05;    % Skalierungsfaktor A
p.B_sat2 = 5.0;     % Exponentieller Faktor B

% PI-Regler (PQ-Knoten)
p.Kp_Q = 0.1;    % Proportionalbeiwert
p.Ki_Q = 1.0;    % Integralbeiwert
p.Efd_max = 5.0;  % Maximale Erregung
p.Efd_min = 0.0;  % Minimale Erregung

% Netzankopplung der Maschinen
p.Y_g1 = 1 / (1i * p.Xdpp1); % Über subtransiente Reaktanz
p.Y_g2 = 1 / (1i * p.Xdpp2); % Über subtransiente Reaktanz

%% Externe Netze
c_factor = 1.1;         
f_sys = 50;             

% Externes Netz 1 (Slack, SS1)
p.U_ext = 1.0;              % Spannung
Sk1 = 13e9;                 % Kurzschlussleistung VA
Tg1 = 32e-3;                % Netzzeitkonstante für Freileitungsnetze in ms
z_grid1_abs = c_factor * (U_base^2) / Sk1; % Netzimpedanz in Ohm
X_grid1 = 2*pi*f_sys * (z_grid1_abs / sqrt((1/Tg1)^2 + (2*pi*f_sys)^2)); % Netzreaktanz in Ohm
R_grid1 = sqrt(z_grid1_abs^2 - X_grid1^2); % ohmscher Netzwiderstand in Ohm
p.Z_ext = (R_grid1 + 1i * X_grid1) / Z_base; % Netzimpedanz in pu
p.Y_ext = 1 / p.Z_ext;

% Externes Netz 2 (SS2)
p.U_ext2_mag = 1.0;         %Spannung
Sk2 = 5e9;              % Kurzschlussleistung
XR2 = 10;               % X/R Verhältnis von 10
theta_k2 = atan(XR2);   
z_grid2_abs_pu = (c_factor * U_base^2 / Sk2) / Z_base; 
p.Z_ext2 = z_grid2_abs_pu * exp(1i * theta_k2); % Netzimpedanz in pu
p.Y_ext2 = 1 / p.Z_ext2; % Netzadmittanz in pu

P_gen1_set = 0.4; % stationärer Arbeitspunkt Wirkleistung
Q_gen1_set = 0.1; % stationärer Arbeitspunkt Blindleistung
P_gen2_set = 0.4; % stationärer Arbeitspunkt Wirkleistung
Q_gen2_set = 0.1; % stationärer Arbeitspunkt Blindleistung

% ZIP loads Koeffizienten
p.P0_1 = 0.0; 
p.Q0_1 = 0.0;
p.kp_z = 0.0; 
p.kp_i = 0.0; 
p.kp_p = 1.0;
p.kq_z = 0.0; 
p.kq_i = 0.0; 
p.kq_p = 1.0;

% Fehlerklärungszeit in s
p.t_fault = 1.0; % Fehlereintritt
p.t_clear = 1.15; % Fehlerklärung
tspan = [0 30];    % simulationszeitraum

%% Setup für die Iteration
P_test_values = (0.0 : 0.8 : 2.4); % Testwirkleistungswerte
P_test_values = [P_test_values, 2.6, 2.8]; 
tan_phi = -0.12; % Leistungsfaktor
colors = lines(length(P_test_values)); 

Ergebnis_Spannungsverlauf_Dyn = table();

% Plots für die Auswertung - Hier ist KI zum Einsatz gekommen
fig_PQ = figure('Name', 'P-Q Trajektorien der Generatoren', 'Position', [100, 100, 800, 900]);
subplot(2,1,1); hold on; grid on; xlabel('P_{gen1} / pu'); ylabel('Q_{gen1} / pu'); title('PQ-Trajektorien Generator 1');
subplot(2,1,2); hold on; grid on; xlabel('P_{gen2} / pu'); ylabel('Q_{gen2} / pu'); title('PQ-Trajektorien Generator 2');

fig_P_time = figure('Name', 'Wirkleistungsabgabe der Generatoren', 'Position', [100, 100, 800, 900]);
subplot(2,1,1); hold on; grid on; xlabel('Zeit / s'); ylabel('P_{gen1} / pu'); title('Wirkleistungsabgabe Generator 1');
subplot(2,1,2); hold on; grid on; xlabel('Zeit / s'); ylabel('P_{gen2} / pu'); title('Wirkleistungsabgabe Generator 2');

fig_Q_time = figure('Name', 'Blindleistungsabgabe der Generatoren', 'Position', [100, 100, 800, 900]);
subplot(2,1,1); hold on; grid on; xlabel('Zeit / s'); ylabel('Q_{gen1} / pu'); title('Blindleistungsabgabe Generator 1');
subplot(2,1,2); hold on; grid on; xlabel('Zeit / s'); ylabel('Q_{gen2} / pu'); title('Blindleistungsabgabe Generator 2');

fig_PU = figure('Name', 'Dynamische P-U Trajektorien', 'Position', [200, 200, 800, 600]);
hold on; grid on; xlabel('Empfangene Wirkleistung P_{recv} an SS2 / pu'); ylabel('Knotenspannung U_{2} / pu'); title('Dynamische P-U Trajektorien');

fig_V_time = figure('Name', 'Sammelschienenspannung über Zeit', 'Position', [250, 250, 800, 900]);
subplot(2,1,1); hold on; grid on; xlabel('Zeit / s'); ylabel('Spannung U_{1} / pu'); title('Spannungsverlauf an SS1');
subplot(2,1,2); hold on; grid on; xlabel('Zeit / s'); ylabel('Spannung U_{2} / pu'); title('Spannungsverlauf an SS2');

fig_P_delta = figure('Name', 'Leistung-Polradwinkel (P-theta)', 'Position', [300, 300, 800, 900]);
subplot(2,1,1); hold on; grid on; xlabel('Polradwinkel \vartheta_1 / °'); ylabel('Wirkleistung P_{Gen1} / pu'); title('P-\vartheta Trajektorie - Generator 1');
subplot(2,1,2); hold on; grid on; xlabel('Polradwinkel \vartheta_2 / °'); ylabel('Wirkleistung P_{Gen2} / pu'); title('P-\vartheta Trajektorie - Generator 2');

fig_delta_delta = figure('Name', 'Polradwinkel Trajektorie', 'Position', [350, 350, 700, 600]);
hold on; grid on; xlabel('Polradwinkel \vartheta_1 / °', 'FontSize', 11); ylabel('Polradwinkel \vartheta_2 / °', 'FontSize', 11); title('\vartheta_1 - \vartheta_2 Trajektorie', 'FontSize', 12, 'FontWeight', 'bold');

fig_Efd = figure('Name', 'Erregerspannungen der elektrischen Maschinen', 'Position', [400, 250, 800, 900]);
subplot(2,1,1); hold on; grid on; xlabel('Zeit / s'); ylabel('U_{f1} / pu'); title('Erregerspannung U_f - Generator 1');
subplot(2,1,2); hold on; grid on; xlabel('Zeit / s'); ylabel('U_{f2} / pu'); title('Erregerspannung U_f - Generator 2');

fig_Ifd = figure('Name', 'Erregerstrom der elektrischen Maschinen', 'Position', [450, 250, 800, 900]);
subplot(2,1,1); hold on; grid on; xlabel('Zeit / s'); ylabel('I_{f1} / pu'); title('Erregerstrom I_{f} - Generator 1');
subplot(2,1,2); hold on; grid on; xlabel('Zeit / s'); ylabel('I_{f2} / pu'); title('Erregerstrom I_{f} - Generator 2');

fig_Igen = figure('Name', 'Statorstrom der elektrischen Maschinen', 'Position', [500, 250, 800, 900]);
subplot(2,1,1); hold on; grid on; xlabel('Zeit / s'); ylabel('|I_{gen1}| / pu'); title('Statorstrom (Betrag) - Generator 1');
subplot(2,1,2); hold on; grid on; xlabel('Zeit / s'); ylabel('|I_{gen2}| / pu'); title('Statorstrom (Betrag) - Generator 2');

fig_delta_time = figure('Name', 'Polradwinkel über Zeit', 'Position', [550, 250, 800, 900]);
subplot(2,1,1); hold on; grid on; xlabel('Zeit / s'); ylabel('Polradwinkel \vartheta_1 / °'); title('Polradwinkel über Zeit - Generator 1');
subplot(2,1,2); hold on; grid on; xlabel('Zeit / s'); ylabel('Polradwinkel \vartheta_2 / °'); title('Polradwinkel über Zeit - Generator 2');

fig_freq_time = figure('Name', 'Frequenzabweichung über Zeit', 'Position', [600, 250, 800, 900]);
subplot(2,1,1); hold on; grid on; xlabel('Zeit / s'); ylabel('\Delta f_1 / Hz'); title('Frequenzabweichung - Generator 1');
subplot(2,1,2); hold on; grid on; xlabel('Zeit / s'); ylabel('\Delta f_2 / Hz'); title('Frequenzabweichung - Generator 2');

fig_theta_time = figure('Name', 'Spannungswinkel der Sammelschienen über Zeit', 'Position', [650, 250, 800, 900]);
subplot(2,1,1); hold on; grid on; xlabel('Zeit / s'); ylabel('Spannungswinkel \delta_1 / °'); title('Spannungswinkel an SS1');
subplot(2,1,2); hold on; grid on; xlabel('Zeit / s'); ylabel('Spannungswinkel \delta_2 / °'); title('Spannungswinkel an SS2');

x0_lf = [0.1, 0.1, 1.0, 1.0];

%% Statische P-U Kurven 
% Werte aus statischen Skript
params_stat.Sn = S_base / 1e6;       % 1000 MVA
params_stat.Un = U_base / 1e3;       % 380 kV
params_stat.f  = f_sys;              % 50 Hz
params_stat.Sk = Sk1 / 1e6;          % 13000 MVA
params_stat.Tg = Tg1;                % 32e-3 s
params_stat.Sk2 = Sk2 / 1e6;         % 5000 MVA
params_stat.XR2 = XR2;               % 10
params_stat.P_gen = P_gen2_set;      % 0.4 pu
params_stat.Q_gen = Q_gen2_set;      % 0.1 pu
params_stat.L_total = L_line;        % 200 km
params_stat.R_per_km = R_km;         % 0.0209
params_stat.X_per_km = X_km;         % 0.304
params_stat.C_per_km = 13e-9;        % Kapazität
params_stat.epsilon = 1e-9;
params_stat.max_iter = 20;

% P-Werte für statische Kurve (Erzeugerzählpfeilsystem)
P_stat_eval = 0.0 : -0.05 : -4.5; 

% Initialisierung der P/U - Arrays
P_recv_stat_n2 = []; 
U_stat_n2 = [];
P_recv_stat_n1 = []; 
U_stat_n1 = [];

for idx_stat = 1:length(P_stat_eval)
    P_load_val = P_stat_eval(idx_stat); 
    Q_load_val = P_load_val * tan_phi;
    
    % Berechnung n-0-Fall
    [T_n2, ~, ~, ~, ~, ~] = berechne_leistungsfluss_diskret(P_load_val, Q_load_val, 2, params_stat, L_line_mesh);
    if T_n2.Iter < params_stat.max_iter
        P_recv_stat_n2(end+1) = T_n2.P_recv; 
        U_stat_n2(end+1) = T_n2.U_End;
    end
    
    % Berechnung n-1-Fall
    [T_n1, ~, ~, ~, ~, ~] = berechne_leistungsfluss_diskret(P_load_val, Q_load_val, 1, params_stat, L_line_mesh);
    if T_n1.Iter < params_stat.max_iter
        P_recv_stat_n1(end+1) = T_n1.P_recv;
        U_stat_n1(end+1) = T_n1.U_End;
    end
end

% Statische Kurven in fig_PU plotten
figure(fig_PU); hold on;
plot(P_recv_stat_n2, U_stat_n2, '--k', 'LineWidth', 1.5, 'DisplayName', 'Statisch n-0');
plot(P_recv_stat_n1, U_stat_n1, '-.k', 'LineWidth', 1.5, 'DisplayName', 'Statisch n-1');


%% 3. Hauptschleife über alle P-Werte
for idx = 1:length(P_test_values)
    disp(P_test_values(idx));
    p.P0_2 = P_test_values(idx); % Lastinit
    p.Q0_2 = p.P0_2 * tan_phi; % Lastinit
    
    Y_load1_Z = (p.P0_1 * p.kp_z) - 1i * (p.Q0_1 * p.kq_z); % Z-Anteil der ZIP-Last
    Y_load2_Z = (p.P0_2 * p.kp_z) - 1i * (p.Q0_2 * p.kq_z); % Z-Anteil der ZIP-Last
    
    y_ser_tot = 2 * p.y_series + p.y_series_mesh; % Serienelemente in der Admittanzmatrix
    y_sh_tot  = 2 * p.y_shunt_half + p.y_shunt_half_mesh; % Querelemente in der Admittanzmatrix
    
    % Admittanzmatrix im Vorfehlerfall
    p.pre.Y11 = Y_load1_Z + y_ser_tot + y_sh_tot + p.Y_g1 + p.Y_ext; 
    p.pre.Y22 = Y_load2_Z + y_ser_tot + y_sh_tot + p.Y_g2 + p.Y_ext2; 
    p.pre.Y12 = -y_ser_tot; 
    p.pre.Y21 = -y_ser_tot;
    
    %Admittanzmatrix im Fehlerfall
    Y_fault = 2.0 - 1i*15.0; %Fehleradmittanz

    %p.flt.Y22 = p.pre.Y22 + Y_fault ; 
    % p.flt.Y11 = p.pre.Y11;
    p.flt.Y22 = p.pre.Y22;         % Fehleradmittanz hier hinzufügen oder wegnehmen, Fehlerort ändern
    p.flt.Y11 = p.pre.Y11+Y_fault; % Fehleradmittanz hier hinzufügen oder wegnehmen, Fehlerort ändern
    p.flt.Y12 = p.pre.Y12; % Serien Elemente
    p.flt.Y21 = p.pre.Y21; % Serien Elemente

    %Admittanzmatrix nach dem Fehler
    p.pst.Y11 = Y_load1_Z + p.y_series + p.y_shunt_half + p.Y_g1 + p.Y_ext + p.y_series_mesh + p.y_shunt_half_mesh;
    p.pst.Y22 = Y_load2_Z + p.y_series + p.y_shunt_half + p.Y_g2 + p.Y_ext2 + p.y_series_mesh + p.y_shunt_half_mesh;
    p.pst.Y12 = -p.y_series-p.y_series_mesh; p.pst.Y21 = -p.y_series-p.y_series_mesh;
    
    % Statischer Leistungsfluss für die Initialisierung der Maschine
    opt = optimoptions('fsolve', 'Display', 'none', 'TolFun', 1e-8);
    lf_fun = @(x) loadflow_mismatch(x, P_gen1_set, Q_gen1_set, P_gen2_set, Q_gen2_set, p.pre, p);
    [x_lf, ~, exitflag] = fsolve(lf_fun, x0_lf, opt);
    
    if exitflag <= 0, warning('Lastfluss konvergierte nicht.'); continue; end
    x0_lf = x_lf;
    
    Up1_c_0 = x_lf(3) * exp(1i * x_lf(1)); % stationäre komplexe Polradspannung Gen 1 gekoppelt über die Subtransiente Reaktanz, entspricht daher nicht der realen Polradspannung
    Up2_c_0 = x_lf(4) * exp(1i * x_lf(2)); % stationäre komplexe Polradspannung Gen 1 gekoppelt über die Subtransiente Reaktanz, entspricht daher nicht der realen Polradspannung
    [V_bus_0, ~, I_gen1_0, I_gen2_0] = solve_network_algebraic(Up1_c_0, Up2_c_0, p.pre, p); % Netzgleichungen mit Polradspannungen berechnen
    Vt1_0 = V_bus_0(1); % stationäre Sammelschienenspannung
    Vt2_0 = V_bus_0(2); % stationäre Sammelschienenspannung
    
    delta1_0 = angle(Vt1_0 + 1i * p.Xq1 * I_gen1_0); %stationärer Polradwinkel
    delta2_0 = angle(Vt2_0 + 1i * p.Xq2 * I_gen2_0); %stationärer Polradwinkel

    I1_dq_0 = I_gen1_0 * exp(-1i * (delta1_0 - pi/2)); %  Statorstrom in d/q Koordinaten
    Id1_0 = real(I1_dq_0);                             %  Statorstrom in d-Richtung
    Iq1_0 = imag(I1_dq_0);                             %  Statorstrom in q-Richtung

    V1_dq_0 = Vt1_0 * exp(-1i * (delta1_0 - pi/2));    % stationäre Klemmenspannung des Generators, im Prinzip wie Sammelschienenspannung nur im dq Bezugssystem
    Vq1_0 = imag(V1_dq_0);                             % Anteil der Q-Achse

    I2_dq_0 = I_gen2_0 * exp(-1i * (delta2_0 - pi/2)); % Statorstrom in d/q Koordinaten
    Id2_0 = real(I2_dq_0);                             % Statorstrom in d-Richtung
    Iq2_0 = imag(I2_dq_0);                             % Stationäre Sammelschienenspannung

    V2_dq_0 = Vt2_0 * exp(-1i * (delta2_0 - pi/2));  % Stationäre Klemmenspannung des Generators, im Prinzip wie Sammelschienenspannung nur im dq Bezugssystem
    Vq2_0 = imag(V2_dq_0);                           % Anteil der Q-Achse
    
    Ed_p1_0  = (p.Xq1 - p.Xqp1) * Iq1_0;             % Transiente Polradspannung in d-Richtung (stationär)
    Eq_p1_0  = Vq1_0 + p.Xdp1 * Id1_0;               % Transiente Polradspannung in q-Richtung (stationär)
    Ed_pp1_0 = Ed_p1_0 + (p.Xqp1 - p.Xqpp1) * Iq1_0; % subtransiente Polradspannung in d-Richtung (stationär)
    Eq_pp1_0 = Eq_p1_0 - (p.Xdp1 - p.Xdpp1) * Id1_0; % subtransiente Polradspannung in d-Richtung (stationär)
    
    Ed_p2_0  = (p.Xq2 - p.Xqp2) * Iq2_0;              % Transiente Polradspannung in d-Richtung (stationär)
    Eq_p2_0  = Vq2_0 + p.Xdp2 * Id2_0;                % Transiente Polradspannung in q-Richtung (stationär)
    Ed_pp2_0 = Ed_p2_0 + (p.Xqp2 - p.Xqpp2) * Iq2_0;  % subtransiente Polradspannung in d-Richtung (stationär)
    Eq_pp2_0 = Eq_p2_0 - (p.Xdp2 - p.Xdpp2) * Id2_0;  % subtransiente Polradspannung in d-Richtung (stationär)
    
    p.Pm1_ref = Ed_pp1_0 * Id1_0 + Eq_pp1_0 * Iq1_0 + (p.Xdpp1 - p.Xqpp1) * Id1_0 * Iq1_0;  % Stationäre mechanische Wirkleistungsabgabe der Maschine
    p.Pm2_ref = Ed_pp2_0 * Id2_0 + Eq_pp2_0 * Iq2_0 + (p.Xdpp2 - p.Xqpp2) * Id2_0 * Iq2_0;  % Stationäre mechanische Wirkleistungsabgabe der Maschine
    
    Q_gen1_0 = imag(Vt1_0 * conj(I_gen1_0)); % stationäre Blindleistungsabgabe 
    Q_gen2_0 = imag(Vt2_0 * conj(I_gen2_0)); % stationäre Blindleistungsabgabe 
    
    p.Efd1_0 = Eq_p1_0 + (p.Xd1 - p.Xdp1) * Id1_0;  % Feldspannung (stationär Polradspannung)
    p.Q_ref1 = Q_gen1_0;                            % Blindleistungssollwert
    Q_int1_0 = 0;                                   % stat. Blindleistungsintegralbeiwert
    
    p.Efd2_0 = Eq_p2_0 + (p.Xd2 - p.Xdp2) * Id2_0;  % Feldspannung (stationär Polradspannung)
    p.Q_ref2 = Q_gen2_0;                            % Blindleistungssollwert
    Q_int2_0 = 0;                                   % stat. Blindleistungsintegralbeiwert
    
    x0 = [delta1_0; 0; Eq_p1_0; Ed_p1_0; Eq_pp1_0; Ed_pp1_0; p.Pm1_ref; Q_int1_0; ...
          delta2_0; 0; Eq_p2_0; Ed_p2_0; Eq_pp2_0; Ed_pp2_0; p.Pm2_ref; Q_int2_0];
          
    options = odeset('RelTol', 1e-4, 'AbsTol', 1e-5);
    try
        [t, x] = ode15s(@(t,x) sys_dynamics(t, x, p), tspan, x0, options); % numerischer Solver für das DAE
        
        %Initialisierung der Variablen fürs Post Processing
        Vt1_mag = zeros(length(t), 1); 
        Vt2_mag = zeros(length(t), 1); 
        theta1 = zeros(length(t), 1);  
        theta2 = zeros(length(t), 1);
        P_send = zeros(length(t), 1); 
        Q_send = zeros(length(t), 1); 
        P_recv = zeros(length(t), 1); 
        Q_recv = zeros(length(t), 1); 
        P_loss = zeros(length(t), 1); 
        Q_loss = zeros(length(t), 1);
        P_ext1 = zeros(length(t), 1); 
        Q_ext1 = zeros(length(t), 1);
        P_ext2 = zeros(length(t), 1);
        Q_ext2 = zeros(length(t), 1);
        P_gen1 = zeros(length(t), 1); 
        Q_gen1 = zeros(length(t), 1);
        P_gen2 = zeros(length(t), 1); 
        Q_gen2 = zeros(length(t), 1);
        Efd1_plt = zeros(length(t), 1); 
        Efd2_plt = zeros(length(t), 1);
        Ifd1_plt = zeros(length(t), 1); 
        Ifd2_plt = zeros(length(t), 1);
        
        Igen1_mag_plt = zeros(length(t), 1); 
        Igen2_mag_plt = zeros(length(t), 1);
        
        %Post-Processing der Variablen für die Darstellung in den
        %Diagrammen
        for k = 1:length(t)
            %Übergabe der Werte von der sys_dynamics Funktion
            delta1 = x(k, 1); % Polradwinkel 1 für jeden Zeitschritt
            Eq_pp1 = x(k, 5); % subtransiente Polradspannung in d-Richtung 1 für jeden Zeitschritt
            Ed_pp1 = x(k, 6); % subtransiente Polradspannung in q-Richtung 1 für jeden Zeitschritt
            Q_int1 = x(k, 8); % Blindleistungsregelung
            delta2 = x(k, 9); % Polradwinkel 2 für jeden Zeitschritt
            Eq_pp2 = x(k, 13); % subtransiente Polradspannung in d-Richtung 1 für jeden Zeitschritt
            Ed_pp2 = x(k, 14); % subtransiente Polradspannung in q-Richtung 1 für jeden Zeitschritt
            Q_int2 = x(k, 16); % Polradwinkel 2 für jeden Zeitschritt
            
            Up1_c = (Ed_pp1 + 1i * Eq_pp1) * exp(1i * (delta1 - pi/2)); % komplexe subtransiente Polradspannung für Netzkopplung
            Up2_c = (Ed_pp2 + 1i * Eq_pp2) * exp(1i * (delta2 - pi/2)); % komplexe subtransiente Polradspannung für Netzkopplung
            
            % Admittanzmatrix angeben
            if t(k) < p.t_fault
                net = p.pre; n_lines = 2; 
            elseif t(k) < p.t_clear
                net = p.flt; n_lines = 2; 
            else
                net = p.pst; n_lines = 1; 
            end
            
            [V_bus, ~, I_gen1, I_gen2] = solve_network_algebraic(Up1_c, Up2_c, net, p); % Hier werden die  Netzgleichungen aufgerufen um auf die Netzvariablen auf Basis der dynamischen Parameter für jeden Zeitschritt zu berechnen.
            Vt1 = V_bus(1); 
            Vt2 = V_bus(2);
            
            Vt1_mag(k) = abs(Vt1); 
            Vt2_mag(k) = abs(Vt2);
            theta1(k) = angle(Vt1) * (180 / pi); 
            theta2(k) = angle(Vt2) * (180 / pi);
            
            P_gen1(k) = real(Up1_c * conj(I_gen1)); 
            P_gen2(k) = real(Up2_c * conj(I_gen2));
            Q_gen1(k) = imag(Vt1 * conj(I_gen1));   
            Q_gen2(k) = imag(Vt2 * conj(I_gen2));

            %Post Processing für  Plots
            Efd1_raw = p.Efd1_0 + p.Kp_Q * (p.Q_ref1 - Q_gen1(k)) + p.Ki_Q * Q_int1;
            Efd1_plt(k) = max(min(Efd1_raw, p.Efd_max), p.Efd_min);
            
            Efd2_raw = p.Efd2_0 + p.Kp_Q * (p.Q_ref2 - Q_gen2(k)) + p.Ki_Q * Q_int2;
            Efd2_plt(k) = max(min(Efd2_raw, p.Efd_max), p.Efd_min);
            
            y_ser_act = n_lines * p.y_series; 
            y_sh_act  = n_lines * p.y_shunt_half;
            I_line_12 = (Vt1 - Vt2) * y_ser_act + Vt1 * y_sh_act;
            S_12 = Vt1 * conj(I_line_12); % Übertragene Leistung
            
            I_line_21_arrival = (Vt1 - Vt2) * y_ser_act - Vt2 * y_sh_act;
            S_21_arrival = Vt2 * conj(I_line_21_arrival); % Für PU Plot
            
            %PU Plot
            P_send(k) = real(S_12); Q_send(k) = imag(S_12); 
            P_recv(k) = real(S_21_arrival); 
            Q_recv(k) = imag(S_21_arrival);
            P_loss(k) = P_send(k) - P_recv(k); 
            Q_loss(k) = Q_send(k) - Q_recv(k);
            
            I_ext1_inj = (p.U_ext - Vt1) / p.Z_ext;
            S_ext1 = Vt1 * conj(I_ext1_inj);
            P_ext1(k) = real(S_ext1); Q_ext1(k) = imag(S_ext1);
            
            U_ext2_c = p.U_ext2_mag * exp(1i * angle(Vt2)); 
            I_ext2_inj = (U_ext2_c - Vt2) / p.Z_ext2;
            S_ext2 = Vt2 * conj(I_ext2_inj);
            P_ext2(k) = real(S_ext2);
            Q_ext2(k) = imag(S_ext2); 
            
            I1_dq = I_gen1 * exp(-1i * (delta1 - pi/2)); 
            Id1 = real(I1_dq);

            I2_dq = I_gen2 * exp(-1i * (delta2 - pi/2)); 
            Id2 = real(I2_dq);
            
            Eq_p1 = x(k, 3); 
            Eq_p2 = x(k, 11);
          
            S_sat1_post = p.A_sat1 * exp(p.B_sat1 * (Eq_p1 - p.E_th1)) * (Eq_p1 > p.E_th1);
            S_sat2_post = p.A_sat2 * exp(p.B_sat2 * (Eq_p2 - p.E_th2)) * (Eq_p2 > p.E_th2);
            
            Ifd1_plt(k) = Eq_p1 + (p.Xd1 - p.Xdp1) * Id1 + S_sat1_post;
            Ifd2_plt(k) = Eq_p2 + (p.Xd2 - p.Xdp2) * Id2 + S_sat2_post;
            
            Igen1_mag_plt(k) = abs(I_gen1);
            Igen2_mag_plt(k) = abs(I_gen2);

        end
        
        row_n0 = table(2, -p.P0_2, -p.Q0_2, Vt2_mag(1), theta2(1), tan_phi, 'VariableNames', {'LTG', 'P_soll', 'Q_soll', 'U_End', 'd_End', 'tan_phi'});
        row_n1 = table(1, -p.P0_2, -p.Q0_2, Vt2_mag(end), theta2(end), tan_phi, 'VariableNames', {'LTG', 'P_soll', 'Q_soll', 'U_End', 'd_End', 'tan_phi'});
        Ergebnis_Spannungsverlauf_Dyn = [Ergebnis_Spannungsverlauf_Dyn; row_n0; row_n1];
        
        % Plotting
        figure(fig_PQ);  
        subplot(2,1,1); plot(P_gen1, Q_gen1, '-', 'Color', colors(idx,:), 'LineWidth', 1.5, 'DisplayName', sprintf('Last: %.2f pu', P_test_values(idx)));
        plot(P_gen1(1), Q_gen1(1), 'o', 'MarkerSize', 6, 'MarkerFaceColor', colors(idx,:), 'HandleVisibility', 'off'); 
        plot(P_gen1(end), Q_gen1(end), 'x', 'MarkerSize', 6, 'MarkerFaceColor', colors(idx,:), 'HandleVisibility', 'off');
        subplot(2,1,2); plot(P_gen2, Q_gen2, '-', 'Color', colors(idx,:), 'LineWidth', 1.5, 'DisplayName', sprintf('Last: %.2f pu', P_test_values(idx)));
        plot(P_gen2(1), Q_gen2(1), 'o', 'MarkerSize', 6, 'MarkerFaceColor', colors(idx,:), 'HandleVisibility', 'off'); plot(P_gen2(end), Q_gen2(end), 'x', 'MarkerSize', 6, 'MarkerFaceColor', colors(idx,:), 'HandleVisibility', 'off');
        
        figure(fig_P_time);  
        subplot(2,1,1); plot(t,P_gen1, '-', 'Color', colors(idx,:), 'LineWidth', 1.5, 'DisplayName', sprintf('Last: %.2f pu', P_test_values(idx)));
        subplot(2,1,2); plot(t,P_gen2, '-', 'Color', colors(idx,:), 'LineWidth', 1.5, 'DisplayName', sprintf('Last: %.2f pu', P_test_values(idx)));
        
        figure(fig_Q_time);  
        subplot(2,1,1); plot(t, Q_gen1, '-', 'Color', colors(idx,:), 'LineWidth', 1.5, 'DisplayName', sprintf('Last: %.2f pu', P_test_values(idx)));
        subplot(2,1,2); plot(t, Q_gen2, '-', 'Color', colors(idx,:), 'LineWidth', 1.5, 'DisplayName', sprintf('Last: %.2f pu', P_test_values(idx)));
        
        
        figure(fig_PU); plot(P_recv, Vt2_mag, '-', 'Color', colors(idx,:), 'LineWidth', 1.5, 'DisplayName', sprintf('Last: %.2f pu', P_test_values(idx)));
        plot(P_recv(1), Vt2_mag(1), 'o', 'MarkerSize', 6, 'MarkerFaceColor', colors(idx,:), 'HandleVisibility', 'off'); plot(P_recv(end), Vt2_mag(end), 'x', 'MarkerSize', 8, 'MarkerEdgeColor', colors(idx,:), 'LineWidth', 2, 'HandleVisibility', 'off');
        
        figure(fig_V_time);
        subplot(2,1,1); plot(t, Vt1_mag, 'Color', colors(idx,:), 'LineWidth', 1.5, 'DisplayName', sprintf('Last: %.2f pu', P_test_values(idx)));
        subplot(2,1,2); plot(t, Vt2_mag, 'Color', colors(idx,:), 'LineWidth', 1.5, 'DisplayName', sprintf('Last: %.2f pu', P_test_values(idx)));
        
        delta1_deg = x(:,1) * 180/pi - theta1; 
        delta2_deg = x(:,9) * 180/pi - theta2;
        
        figure(fig_P_delta);
        subplot(2,1,1); plot(delta1_deg, P_gen1, '-', 'Color', colors(idx,:), 'LineWidth', 1.5, 'DisplayName', sprintf('Last: %.2f pu', P_test_values(idx)));
        plot(delta1_deg(1), P_gen1(1), 'o', 'MarkerSize', 6, 'MarkerFaceColor', colors(idx,:), 'HandleVisibility', 'off'); plot(delta1_deg(end), P_gen1(end), 'x', 'MarkerSize', 6, 'MarkerFaceColor', colors(idx,:), 'HandleVisibility', 'off');
        subplot(2,1,2); plot(delta2_deg, P_gen2, '-', 'Color', colors(idx,:), 'LineWidth', 1.5, 'DisplayName', sprintf('Last: %.2f pu', P_test_values(idx)));
        plot(delta2_deg(1), P_gen2(1), 'o', 'MarkerSize', 6, 'MarkerFaceColor', colors(idx,:), 'HandleVisibility', 'off'); plot(delta2_deg(end), P_gen2(end), 'x', 'MarkerSize', 6, 'MarkerFaceColor', colors(idx,:), 'HandleVisibility', 'off');
        
        figure(fig_delta_delta); plot(delta1_deg, delta2_deg, '-', 'Color', colors(idx,:), 'LineWidth', 1.5, 'DisplayName', sprintf('Last: %.2f pu', P_test_values(idx)));
        plot(delta1_deg(1), delta2_deg(1), 'o', 'MarkerSize', 6, 'MarkerFaceColor', colors(idx,:), 'HandleVisibility', 'off'); plot(delta1_deg(end), delta2_deg(end), 'x', 'MarkerSize', 8, 'MarkerEdgeColor', colors(idx,:), 'LineWidth', 2, 'HandleVisibility', 'off');
         
        figure(fig_Efd);
        subplot(2,1,1); plot(t, Efd1_plt, '-', 'Color', colors(idx,:), 'LineWidth', 1.5, 'DisplayName', sprintf('Last: %.2f pu', P_test_values(idx)));
        subplot(2,1,2); plot(t, Efd2_plt, '-', 'Color', colors(idx,:), 'LineWidth', 1.5, 'DisplayName', sprintf('Last: %.2f pu', P_test_values(idx)));
        
        figure(fig_Ifd);
        subplot(2,1,1); plot(t, Ifd1_plt, '-', 'Color', colors(idx,:), 'LineWidth', 1.5, 'DisplayName', sprintf('Last: %.2f pu', P_test_values(idx)));
        subplot(2,1,2); plot(t, Ifd2_plt, '-', 'Color', colors(idx,:), 'LineWidth', 1.5, 'DisplayName', sprintf('Last: %.2f pu', P_test_values(idx)));
        
        figure(fig_Igen);
        subplot(2,1,1); plot(t, Igen1_mag_plt, '-', 'Color', colors(idx,:), 'LineWidth', 1.5, 'DisplayName', sprintf('Last: %.2f pu', P_test_values(idx)));
        subplot(2,1,2); plot(t, Igen2_mag_plt, '-', 'Color', colors(idx,:), 'LineWidth', 1.5, 'DisplayName', sprintf('Last: %.2f pu', P_test_values(idx)));
        
        % Absoluter Polradwinkel im synchronen Bezugssystem (in Grad)
        delta1_abs_deg = x(:,1) * 180/pi; 
        delta2_abs_deg = x(:,9) * 180/pi;
        
        % Frequenzabweichung in Hertz (d_omega ist in pu, f_sys = 50 Hz)
        df1 = x(:,2) * 50; 
        df2 = x(:,10) * 50;

        figure(fig_delta_time);
        % Wir verwenden delta1_deg und delta2_deg (Rotorwinkel minus Klemmenspannungswinkel)
        subplot(2,1,1); plot(t, delta1_deg, '-', 'Color', colors(idx,:), 'LineWidth', 1.5, 'DisplayName', sprintf('Last: %.2f pu', P_test_values(idx)));
        subplot(2,1,2); plot(t, delta2_deg, '-', 'Color', colors(idx,:), 'LineWidth', 1.5, 'DisplayName', sprintf('Last: %.2f pu', P_test_values(idx)));
        
        figure(fig_freq_time);
        subplot(2,1,1); plot(t, df1, '-', 'Color', colors(idx,:), 'LineWidth', 1.5, 'DisplayName', sprintf('Last: %.2f pu', P_test_values(idx)));
        subplot(2,1,2); plot(t, df2, '-', 'Color', colors(idx,:), 'LineWidth', 1.5, 'DisplayName', sprintf('Last: %.2f pu', P_test_values(idx)));

        % Spannungswinkel der Sammelschienen über Zeit plotten ---
        figure(fig_theta_time);
        subplot(2,1,1); plot(t, theta1, '-', 'Color', colors(idx,:), 'LineWidth', 1.5, 'DisplayName', sprintf('Last: %.2f pu', P_test_values(idx)));
        subplot(2,1,2); plot(t, theta2, '-', 'Color', colors(idx,:), 'LineWidth', 1.5, 'DisplayName', sprintf('Last: %.2f pu', P_test_values(idx)));
        

        % Phasenraumdarstellung (Phase Portrait) für Generator 1
        
        if abs(p.P0_2 - P_test_values(end)) < 1e-3 
            fig_Phase = figure('Name', 'Phasenraumdarstellung Generator 1', 'Position', [750, 350, 800, 500]);
            hold on; grid on;
            
            % Winkel in Grad und Drehzahl in Hz
            delta1_abs_deg = x(:,1) * 180/pi; 
            df1_hz = x(:,2) * 50; % Frequenzabweichung in Hz
            
            xlabel('Absoluter Rotorwinkel \delta_1 / °', 'FontSize', 11);
            ylabel('Frequenzabweichung \Delta f_1 / Hz', 'FontSize', 11);
            title('Phasenraum-Trajektorie (Phase Portrait)', 'FontSize', 12);
            
            % Indizes für die Phasen
            idx_pre = find(t < p.t_fault);
            idx_flt = find(t >= p.t_fault & t < p.t_clear);
            idx_pst = find(t >= p.t_clear);
            
            % Trajektorien der drei Zeitabschnitte plotten
            plot(delta1_abs_deg(idx_pre), df1_hz(idx_pre), 'k-', 'LineWidth', 2, 'DisplayName', 'Pre-Fault (Stationär)');
            plot(delta1_abs_deg(idx_flt), df1_hz(idx_flt), 'r-', 'LineWidth', 2, 'DisplayName', 'Fault (Kurzschluss)');
            plot(delta1_abs_deg(idx_pst), df1_hz(idx_pst), 'b-', 'LineWidth', 1.5, 'DisplayName', 'Post-Fault (Ausschwingen)');
            
            % Markante Punkte
            plot(delta1_abs_deg(idx_flt(1)), df1_hz(idx_flt(1)), 'ro', 'MarkerFaceColor', 'r', 'DisplayName', 'Fehlereintritt');
            plot(delta1_abs_deg(idx_pst(1)), df1_hz(idx_pst(1)), 'gs', 'MarkerFaceColor', 'g', 'DisplayName', 'Fehlerklärung');
            plot(delta1_abs_deg(end), df1_hz(end), 'kd', 'MarkerFaceColor', 'k', 'DisplayName', 'Neuer stationärer Punkt');
            
            % Startpunkt in der Mitte markieren
            yline(0, 'k--', 'HandleVisibility', 'off');
            
            legend('Location', 'best');
            hold off;
        end


        %Phasenraumdarstellung (Phase Portrait) für Generator 2 mit KI
        %erstellt
     
        if abs(p.P0_2 - 3.5) < 1e-3 
            fig_Phase2 = figure('Name', 'Phasenraumdarstellung Generator 2', 'Position', [750, 350, 800, 500]);
            hold on; grid on;
            
            % Winkel in Grad und Drehzahl in Hz für Generator 2
            % x(:,9) = delta2, x(:,10) = d_omega2
            delta2_abs_deg = x(:,9) * 180/pi; 
            df2_hz = x(:,10) * 50; % Frequenzabweichung in Hz
            
            xlabel('Absoluter Rotorwinkel \delta_2 / °', 'FontSize', 11);
            ylabel('Frequenzabweichung \Delta f_2 / Hz', 'FontSize', 11);
            title('Phasenraum-Trajektorie (Phase Portrait) - Generator 2', 'FontSize', 12);
            
            % Indizes für die Phasen
            idx_pre = find(t < p.t_fault);
            idx_flt = find(t >= p.t_fault & t < p.t_clear);
            idx_pst = find(t >= p.t_clear);
            
            % Trajektorien der drei Zeitabschnitte plotten
            plot(delta2_abs_deg(idx_pre), df2_hz(idx_pre), 'k-', 'LineWidth', 2, 'DisplayName', 'Pre-Fault (Stationär)');
            plot(delta2_abs_deg(idx_flt), df2_hz(idx_flt), 'r-', 'LineWidth', 2, 'DisplayName', 'Fault (Kurzschluss)');
            plot(delta2_abs_deg(idx_pst), df2_hz(idx_pst), 'b-', 'LineWidth', 1.5, 'DisplayName', 'Post-Fault (Ausschwingen)');
            
            % Markante Punkte
            plot(delta2_abs_deg(idx_flt(1)), df2_hz(idx_flt(1)), 'ro', 'MarkerFaceColor', 'r', 'DisplayName', 'Fehlereintritt');
            plot(delta2_abs_deg(idx_pst(1)), df2_hz(idx_pst(1)), 'gs', 'MarkerFaceColor', 'g', 'DisplayName', 'Fehlerklärung');
            plot(delta2_abs_deg(end), df2_hz(end), 'kd', 'MarkerFaceColor', 'k', 'DisplayName', 'Neuer stationärer Punkt');
            
            % Nulllinie für die Frequenzabweichung markieren
            yline(0, 'k--', 'HandleVisibility', 'off');
            
            legend('Location', 'best');
            hold off;
        end
    
        

    catch ME
        warning('Solver abgerissen bei P = %.2f pu. Grund: %s', p.P0_2, ME.message);
    end
        
end

% Legenden Formatierung, KI- generiert
figure(fig_PQ); subplot(2,1,1); legend('Location', 'best'); subplot(2,1,2); legend('Location', 'best');
figure(fig_P_time); subplot(2,1,1); legend('Location', 'best'); subplot(2,1,2); legend('Location', 'best');
figure(fig_P_time); subplot(2,1,1); legend('Location', 'best'); subplot(2,1,2); legend('Location', 'best');
figure(fig_PU); legend('Location', 'southwest'); hold off;
figure(fig_V_time); subplot(2,1,1); legend('Location', 'best'); subplot(2,1,2); legend('Location', 'best');
figure(fig_P_delta); subplot(2,1,1); legend('Location', 'best'); subplot(2,1,2); legend('Location', 'best');
figure(fig_delta_delta); legend('Location', 'best'); hold off;
figure(fig_Efd); subplot(2,1,1); legend('Location', 'best'); subplot(2,1,2); legend('Location', 'best'); hold off;
figure(fig_Ifd); subplot(2,1,1); legend('Location', 'best'); subplot(2,1,2); legend('Location', 'best');
figure(fig_Igen); subplot(2,1,1); legend('Location', 'best'); subplot(2,1,2); legend('Location', 'best');
figure(fig_delta_time); subplot(2,1,1); legend('Location', 'best'); subplot(2,1,2); legend('Location', 'best');
figure(fig_freq_time); subplot(2,1,1); legend('Location', 'best'); subplot(2,1,2); legend('Location', 'best');
figure(fig_theta_time); subplot(2,1,1); legend('Location', 'best'); subplot(2,1,2); legend('Location', 'best');


% ODE Function 

function dxdt = sys_dynamics(t, x, p)
    %Initialisierung der Zustandsvariablen
    delta1   = x(1); 
    d_omega1 = x(2); 
    Eq_p1    = x(3); 
    Ed_p1    = x(4); 
    Eq_pp1   = x(5); 
    Ed_pp1   = x(6); 
    Pm1      = x(7); 
    Q_int1   = x(8); 
    delta2   = x(9); 
    d_omega2 = x(10); 
    Eq_p2    = x(11); 
    Ed_p2    = x(12); 
    Eq_pp2   = x(13); 
    Ed_pp2   = x(14); 
    Pm2      = x(15); 
    Q_int2   = x(16); 
    
    % Admittanzmatrix nach Zeit bestimmen
    if t < p.t_fault, net = p.pre; 
    elseif t >= p.t_fault && t < p.t_clear, net = p.flt; 
    else, net = p.pst; 
    end
    
    Up1_c = (Ed_pp1 + 1i * Eq_pp1) *  exp(1i * (delta1 - pi/2)); % subtransiente Polradspannung für Netzkopplung
    Up2_c = (Ed_pp2 + 1i * Eq_pp2) * exp(1i * (delta2 - pi/2)); % subtransiente Polradspannung für Netzkopplung
    
    [V_bus, ~, I_gen1, I_gen2] = solve_network_algebraic(Up1_c, Up2_c, net, p); %Netzgleichungen lösen
    
    Q_gen1 = imag(V_bus(1) * conj(I_gen1)); % Blindleistungsabgabe der Generatoren berechnen
    Q_gen2 = imag(V_bus(2) * conj(I_gen2)); % Blindleistungsabgabe der Generatoren berechnen
    
    I1_dq = I_gen1 * exp(-1i * (delta1 - pi/2)); % Statorstrom in dq Koordinaten
    Id1 = real(I1_dq); % Statorstrom in d-Richtung
    Iq1 = imag(I1_dq); % Statorstrom in q-Richtung

    Pe1 = Ed_pp1 * Id1 + Eq_pp1 * Iq1 + (p.Xdpp1 - p.Xqpp1) * Id1 * Iq1; % Elektrische Wirkleistungsabgabe der Maschine
    
    I2_dq = I_gen2 * exp(-1i * (delta2 - pi/2)); % Statorstrom in dq Koordinaten
    Id2 = real(I2_dq);  % Blindleistungsabgabe der Generatoren berechnen
    Iq2 = imag(I2_dq);  % Blindleistungsabgabe der Generatoren berechnen

    Pe2 = Ed_pp2 * Id2 + Eq_pp2 * Iq2 + (p.Xdpp2 - p.Xqpp2) * Id2 * Iq2; % Elektrische Wirkleistungsabgabe der Maschine
    
    eQ1 = p.Q_ref1 - Q_gen1; % Regelabweichung der Blindleistung
    d_Qint1 = eQ1; % Änderung der des Integralbeiwerts

    Efd1_raw = p.Efd1_0 + p.Kp_Q * eQ1 + p.Ki_Q * Q_int1; % Berechnung der Excitation
    Efd1 = max(min(Efd1_raw, p.Efd_max), p.Efd_min);  % Berechnung der Excitation
    
    eQ2 = p.Q_ref2 - Q_gen2; % Regelabweichung der Blindleistung
    d_Qint2 = eQ2;           % Änderung der des Integralbeiwerts
    Efd2_raw = p.Efd2_0  + p.Kp_Q * eQ2 +p.Ki_Q * Q_int2;  % Bererchnung der Excitation
    Efd2 = max(min(Efd2_raw, p.Efd_max), p.Efd_min);  % Bererchnung der Excitation

    %% Swinggleichung
    d_delta1 = p.omega0 * d_omega1; % Swing-Gleichung
    dd_omega1 = (1 / (2 * p.H1)) * (Pm1 - Pe1 - p.D1 * d_omega1); % Swing-Gleichung
    
    %% Flussdynamik Maschinenmodell 6. Ordnung
    
    S_sat1 = p.A_sat1 * exp(p.B_sat1 * (Eq_p1 - p.E_th1)) * (Eq_p1 > p.E_th1); % Exponentielle Sättigungsfunktion Generator 1

    d_Eq_p1   = (1 / p.Td0p1) * (Efd1 - Eq_p1 - (p.Xd1 - p.Xdp1) * Id1 - S_sat1); % Änderung der transienten Polradspannung in q-Richtung
    d_Ed_p1   = (1 / p.Tq0p1) * (-Ed_p1 + (p.Xq1 - p.Xqp1) * Iq1);                % Änderung der transienten Polradspannung in d-Richtung

    d_Eq_pp1  = (1 / p.Td0pp1) * (Eq_p1 - Eq_pp1 - (p.Xdp1 - p.Xdpp1) * Id1);     % Änderung der subtransienten Polradspannung in q-Richtung
    d_Ed_pp1  = (1 / p.Tq0pp1) * (Ed_p1 - Ed_pp1 + (p.Xqp1 - p.Xqpp1) * Iq1);     % Änderung der subtransienten Polradspannung in d-Richtung

    %% Turbine Governor
    
    % Begrenzung angeforderten Leistung
    Pm1_target = p.Pm1_ref - (d_omega1 / p.R1); % Sollwert der mechanischen Leistung
    Pm1_target = max(min(Pm1_target, p.Pm_max1), p.Pm_min1); % Sollwert der mechanischen Leistung
    d_Pm1 = (1 / p.Tg1) * (Pm1_target - Pm1); %PT1 Regelung

    %% Swing-Gleichung
    
    d_delta2 = p.omega0 * d_omega2; % Swing-Gleichung
    dd_omega2 = (1 / (2 * p.H2)) * (Pm2 - Pe2 - p.D2 * d_omega2); % Swing-Gleichung
    
    % Exponentielle Sättigungsfunktion Generator 2 berechnen
    S_sat2 = p.A_sat2 *  exp(p.B_sat2 * (Eq_p2 - p.E_th2))  * (Eq_p2 > p.E_th2); 

    d_Eq_p2   = (1 / p.Td0p2) * (Efd2 - Eq_p2 - (p.Xd2 - p.Xdp2) * Id2 - S_sat2); % Änderung der transienten Polradspannung in q-Richtung
    d_Ed_p2   = (1 / p.Tq0p2) * (-Ed_p2 +(p.Xq2 - p.Xqp2) * Iq2);                 % Änderung der transienten Polradspannung in d-Richtung

    d_Eq_pp2  = (1 /  p.Td0pp2) * (Eq_p2 - Eq_pp2 - (p.Xdp2 - p.Xdpp2) * Id2); % Änderung der subtransienten Polradspannung in q-Richtung
    d_Ed_pp2  = (1 / p.Tq0pp2) * (Ed_p2 - Ed_pp2 + (p.Xqp2 - p.Xqpp2) * Iq2); % Änderung der subtransienten Polradspannung in d-Richtung
   
    % Begrenzung angeforderten Leistung (Governor)
    Pm2_target = p.Pm2_ref - (d_omega2 / p.R2);  % Sollwert der mechanischen Leistung
    Pm2_target = max(min(Pm2_target, p.Pm_max2), p.Pm_min2);  % Sollwert der mechanischen Leistung
    d_Pm2 = (1 / p.Tg2) * (Pm2_target - Pm2); %Änderung der mech. Leistung
    
    %% Update-Vektor 
    dxdt = [d_delta1; dd_omega1; d_Eq_p1; d_Ed_p1; d_Eq_pp1; d_Ed_pp1; d_Pm1; d_Qint1; ...
            d_delta2; dd_omega2; d_Eq_p2; d_Ed_p2; d_Eq_pp2; d_Ed_pp2; d_Pm2; d_Qint2];
end

function [V_bus, I_ext2_inj, I_gen1, I_gen2] = solve_network_algebraic(Up1_c, Up2_c, net, p)
    Y_bus = [net.Y11, net.Y12; net.Y21, net.Y22];
    %disp(Y_bus)
    I_base = [(Up1_c * p.Y_g1) + (p.U_ext * p.Y_ext); (Up2_c * p.Y_g2)];
    V_bus = Y_bus \ I_base; 
    for iter = 1:5
        V1_mag = abs(V_bus(1)); 
        V2_mag = abs(V_bus(2));
        U_ext2_c = p.U_ext2_mag * exp(1i * angle(V_bus(2))); % Bestimmung des Winkels von Externen Netz 2, deswegen iterativ
        I_ext2_inj = U_ext2_c * p.Y_ext2; %  Quelle
        S_IP_1 = p.P0_1 * (p.kp_i * V1_mag + p.kp_p) + 1i * p.Q0_1 * (p.kq_i * V1_mag + p.kq_p); % ZIP LOAD
        S_IP_2 = p.P0_2 * (p.kp_i * V2_mag + p.kp_p) + 1i * p.Q0_2 * (p.kq_i * V2_mag + p.kq_p); %ZIP Load
        I_load_IP_1 = conj(S_IP_1 / V_bus(1)); % Strom Last
        I_load_IP_2 = conj(S_IP_2 / V_bus(2)); % Strom Last
        I_inj = I_base + [-I_load_IP_1; I_ext2_inj - I_load_IP_2];
        V_bus = Y_bus \ I_inj; % V_Bus_neu
    end
    I_gen1 = (Up1_c - V_bus(1)) * p.Y_g1; % Generatorstrom
    I_gen2 = (Up2_c - V_bus(2)) * p.Y_g2; % Generatorstrom
end

function F = loadflow_mismatch(x, P1_set, Q1_set, P2_set, Q2_set, net,p) %Funktion für die initisialisierung durch statischen Leistungsfluss
    d1 = x(1); 
    d2 = x(2); 
    U1 = x(3); 
    U2 = x(4);

    Up1_c = U1 *  exp(1i * d1); % Gleichseitzen von der Subtransienten Spannung mit SS1
    Up2_c = U2 * exp(1i * d2); % Gleichseitzen von der Subtransienten Spannung mit SS2

    [V_bus, ~, I_gen1, I_gen2] = solve_network_algebraic(Up1_c, Up2_c, net, p); % Netzgleichungen berechnen und die echten subtransienten Polradspannungen berechnen
    
    S_term1 = V_bus(1) *  conj(I_gen1);  
    S_term2 = V_bus(2) *conj(I_gen2);

    F = [real(S_term1) - P1_set; real(S_term2) - P2_set; 
         imag(S_term1) - Q1_set; imag(S_term2) - Q2_set];
end