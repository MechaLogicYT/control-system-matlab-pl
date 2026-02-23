% Autor - MechaLogic
% Kanal YouTube - wpadnij po inne poradniki. 
% Link do filmiku z omowieniem - 

% Regulator PI, synteza parametryczna - Matlab + Simulink

clc; clear; 

% Kr -> licznik transmitancji, wzmocnienie podstawowe naszego sygnalu
% Kp -> wzmocnienie regulatora P 
% Ti -> calkujaca stala czasowa

% L1 - licznik
L1 = [3];

% m2, m3, m4 - (s+1), (6s+1), (9s+1) - mianownik
m2 = [1 1];
m3 = [6 1];
m4 = [9 1];

% zapis mnozenia nawiasow
m5 = conv(m2,m3);
M1 = conv(m4,m5);

% zapis transmitancji 
G = tf(L1,M1)

% Odpowiedz skokowa
figure(1);
step(G)
grid on
title('Odpowiedź skokowa obiektu - G')

[y,t] = step(G);

% Bode - funkcja margin(G) automatycznie zaznacza nam zapas wzmocnienia i
% fazy. W pierwszym odcinku z tej serii omawialem dokladniej jak czytac
% wykresy Bodego i Nyquista

figure(2);
margin(G);

[GM, PM, Wcg, Wcp] = margin(G);

% Regulator PI

% Metoda 1 - Zapas wzmocnienia Bode + Ziegler Nicholson

Sample_time = 0.1; %  narzucam sampletime do Step w Simulinku

T_oscylacje = 2*pi*(1 / Wcp); % Wyznaczanie okresu oscylacji
ZapasWzmocnieniaBezwymiarowy_bode = GM;

% Granica stabilnosc - wykres oscylacyjny 
K_oscylacje = ZapasWzmocnieniaBezwymiarowy_bode;

% Nastawy regulatora PI - Bode + Ziegler Nicholson
Kp_Bode = 0.45*K_oscylacje
Ti_Bode = T_oscylacje/(1.2)
I_simulink = Kp_Bode/Ti_Bode;

% wyznaczanie uchybu 
L22 = [Kp_Bode*Ti_Bode Kp_Bode];
M22 = [Ti_Bode 0];

% Transmitancja Regulatora PI
R_PI_Bode = tf(L22,M22)

sygnal_wejsciowy = 1;
sygnal_wyjsciowy = dcgain(feedback(R_PI_Bode*G,1));
uchyb = sygnal_wyjsciowy - sygnal_wyjsciowy


% Metoda 2 - T i tau, styczna 

% Wyznaczanie stycznej funkcji y(t) - step response 
dy = gradient(y, t);

% punkt najwiekszego nachylenia 
[~, idx] = max(dy);

% t_inflect, y_inflect - punkt przeciecia stycznej z odpowiedzia
% skokowa
t_inflect = t(idx); 
y_inflect = y(idx);
slope = dy(idx); % tangens Y/X, stycznej

% rownanie stycznej
y_tan = slope * (t - t_inflect) + y_inflect;

% wykres step + styczna
figure(3);
step(G)
grid on
title('Odpowiedź skokowa obiektu')

hold on
plot(t, y_tan, '--r')
legend('step', 'tangent')

% miejsce zerowe stycznej - tau
tau = t_inflect - y_inflect / slope
Kr = L1;

% Amplituda sygnalu wejsciowego 
A = 1;
T = Kr/slope

% obliczamy Kp i Ti za pomoca T i tau 
Kp_Tau_T = (0.9)*(T/(Kr*tau))
Ti_Tau_T = 3*tau

L33 = [Kp_Tau_T*Ti_Tau_T Kp_Tau_T];
M33 = [Ti_Tau_T 0];

% Transmitancja Regulatora PI
R_PI_Tau_T = tf(L33,M33)

% Metoda 3 - najwieksza stala czasowa obiektu transmitancji - (9s+1)
% wzmocnienie - dobierasz cos z przedzialu 0 - Kp_Bode i sprawdzasz 
Ti_stalaCzasowa = 9;

figure(4)
for K = [0.2 0.5 1 2]
    L44 = [K*Ti_stalaCzasowa K];
    M44 = [Ti_stalaCzasowa 0];
    R_PI_stalaCzasowa = tf(L44,M44);
    step(feedback(R_PI_stalaCzasowa*G,1))
    hold on
end
grid on
legend('0.2','0.5','1','2')

Kp_optymalizacja = 0.2;
L55 = [Kp_optymalizacja*Ti_stalaCzasowa Kp_optymalizacja];
M55 = [Ti_stalaCzasowa 0];
R_PI_optymalizacja = tf(L55,M55)

% Wykresy step po zastosowaniu regulatora PI
figure(5)
for PI = [R_PI_Bode,R_PI_Tau_T,R_PI_optymalizacja]
    step(feedback(PI*G,1))
    hold on
end
grid on
legend('R_PI_Bode','R_PI_Tau_T','R_PI_optymalizacja')

% uchyb = 0 dla PI. 
figure(6)
step(feedback(R_PI_optymalizacja*G,1))
hold on 
step(feedback(Kp_optymalizacja*G,1))
grid on
legend('PI','P')
title("Porownanie Regulatorow PI i P z tym samym wzmocnieniem")

% gotowa funkcja matlab do analizy step
odpowiedzSkokowa_optymalizacja = stepinfo(feedback(R_PI_optymalizacja*G,1))
