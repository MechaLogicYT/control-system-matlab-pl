% Autor - MechaLogic
% Kanal YouTube - wpadnij po inne poradniki. 
% Link do filmiku z omowieniem - https://youtu.be/x7VKcr5l810

% Regulator PID, synteza parametryczna - Matlab + Simulink

% Jezeli nie dziala SIMULINK -> 
% 1 - Plik MATLAB i SIMULINK musza byc w tym samym folderze. 
% 2 - Workspace musi byc zaladowany: 
% Odpalasz Matlaba i w tym momencie zmienne sa wpisywane do Simulinka
% 3 - Bloczek swieci na czerwono/blad ze zmiennymi -> Skopiuj bloczek i
% skopiowany bloczek wstaw za ten co jest w ukladzie. 

clc; clear; 

% Kr -> licznik transmitancji, wzmocnienie podstawowe naszego sygnalu
% Kp -> wzmocnienie regulatora P 
% Ti -> parametr calkujacy
% Td -> parametr rozniczkujacy 
% I_simulink - Parametr do gotowego bloczku PID
% D_simulink - Parametr do gotowego bloczku PID

% R = tf([Kp*Ti*Td  Kp*Ti  Kp],[Ti 0]);

% Parametr do Czlonu D, filtr. W recznie zbudowanym regulatorze PID
N = 100; 

% L1 - licznik[M1]
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

% Regulator PID

% Metoda 1 - Zapas wzmocnienia Bode + Ziegler Nicholson

Sample_time = 0.1; %  narzucam sampletime do Step w Simulinku

T_oscylacje = 2*pi*(1 / Wcp); % Wyznaczanie okresu oscylacji
ZapasWzmocnieniaBezwymiarowy_bode = GM;

% Granica stabilnosc - wykres oscylacyjny 
K_oscylacje = ZapasWzmocnieniaBezwymiarowy_bode;


Kp_PID_Bode = 0.6*K_oscylacje;
Ti_PID_Bode = T_oscylacje/2;
Td_PID_Bode = T_oscylacje/8;
I_simulink_Bode = Kp_PID_Bode/Ti_PID_Bode;
D_simulink_Bode = Kp_PID_Bode*Td_PID_Bode;

L_PID1 = [Kp_PID_Bode*Ti_PID_Bode*Td_PID_Bode ...
          Kp_PID_Bode*Ti_PID_Bode ...
          Kp_PID_Bode];
M_PID1 = [Ti_PID_Bode 0];

% Rownanie regulatora PID - Bode
R_PID_Bode = tf(L_PID1,M_PID1)

figure(3);
step(feedback(R_PID_Bode*G,1))
grid on
title('PID - Ziegler Nichols (Bode)')

% wyznaczanie uchybu 

sygnal_wejsciowy = 1;
sygnal_wyjsciowy = dcgain(feedback(R_PID_Bode*G,1));
uchyb = sygnal_wejsciowy - sygnal_wyjsciowy


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
figure(4);
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

Kp_PID_Tau = 1.2*(T/(Kr*tau));
Ti_PID_Tau = 2*tau;
Td_PID_Tau = 0.5*tau;
I_simulink_Tau = Kp_PID_Tau/Ti_PID_Tau;
D_simulink_Tau = Kp_PID_Tau*Td_PID_Tau;

L_PID2 = [Kp_PID_Tau*Ti_PID_Tau*Td_PID_Tau ...
          Kp_PID_Tau*Ti_PID_Tau ...
          Kp_PID_Tau];
M_PID2 = [Ti_PID_Tau 0];

R_PID_Tau = tf(L_PID2,M_PID2)

figure(5);
step(feedback(R_PID_Tau*G,1))
grid on
title('PID - Metoda T i tau')

% Metoda 3 - najwieksza stala czasowa obiektu transmitancji - (9s+1)
% wzmocnienie - dobierasz cos z przedzialu 0 - Kp_Bode i sprawdzasz 
Ti_stalaCzasowa = 9;
Td_stalaCzasowa = 2;

figure(6);
for K = [0.2 0.5 1 2]
    L_stalaCzasowa = [K*Ti_stalaCzasowa*Td_stalaCzasowa  K*Ti_stalaCzasowa  K];
    M_stalaCzasowa = [Ti_stalaCzasowa 0];
    R_stalaCzasowa = tf(L_stalaCzasowa,M_stalaCzasowa);
    step(feedback(R_stalaCzasowa*G,1))
    hold on
end
grid on
legend('0.2','0.5','1','2')
title('PID - strojenie ręczne')

Kp_optymalizacja = 2;
L_PID5 = [Kp_optymalizacja*Ti_stalaCzasowa*Td_stalaCzasowa Kp_optymalizacja*Ti_stalaCzasowa Kp_optymalizacja];
M_PID5 = [Ti_stalaCzasowa 0];
I_simulink_optymalizacja = Kp_optymalizacja/Ti_stalaCzasowa;
D_simulink_optymalizacja = Kp_optymalizacja*Td_stalaCzasowa;

R_PID_optymalizacja = tf(L_PID5,M_PID5)

L55 = [Kp_optymalizacja*Ti_stalaCzasowa Kp_optymalizacja];
M55 = [0 Ti_stalaCzasowa 0];
R_PI_optymalizacja = tf(L55,M55)


% Wykresy step po zastosowaniu regulatora PID
figure(7)
for PID = [R_PID_Bode,R_PID_Tau,R_PID_optymalizacja]
    step(feedback(PID*G,1))
    hold on
end
grid on
legend('R_PID_Bode','R_PID_Tau','R_PID_optymalizacja')
title('Porównanie metod doboru parametrów Regulatora PID')

figure(8)
step(feedback(R_PID_optymalizacja*G,1))
hold on 
step(feedback(Kp_optymalizacja*G,1))
hold on
step(feedback(R_PI_optymalizacja*G,1))
grid on
legend('PID','P','PI')
title("Porównanie Regulatorów PID i PI i P z tym samym wzmocnieniem")

% gotowa funkcja matlab do analizy step
odpowiedzSkokowa_optymalizacja = stepinfo(feedback(R_PID_optymalizacja*G,1))
odpowiedzSkokowa_Bode = stepinfo(feedback(R_PID_Bode*G,1))
odpowiedzSkokowa_Tau = stepinfo(feedback(R_PID_Tau*G,1))
