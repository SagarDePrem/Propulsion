clear all
 clc 
%%%% inputs
T04=1730;                            % Turbine inlet temperature
B=7;                                 % fan bypass ratio
m=12;                                % mass flow rate to core
T_inf=220  ;                         % ambient temperature
P_inf=0.25*101325  ;                 % ambient pressure
M_inf=0.85      ;                    % flight mach number
gamma=1.4;                           % ratio of specific heats
R=288.66;                               % gas constant
u=M_inf*sqrt(gamma*R*T_inf);         % inlet velocity
Cp=gamma*R/(gamma-1) ;               % specific heat  
prc=linspace(3,50,50)  ;             % compressor pressure ratio
prf= 1.72 ;                          % fan pressure ratio
del_p=0;                             % combustor pressure loss

% isentropic efficiencies 
e_diff=0.93;                         % inlet/diffuser
e_fan=0.85;                          % fan
e_n_cold=0.98;                       % cold stream nozzle
e_n_hot=0.90;                        % hot stream nozzle
e_comp=0.85;                          % compressor
e_turb=0.85;                          % turbine
e_burner=1;                          % burner/combustor

Q=45000000 ;                         % fuel heat capacity 


% cold and hot stream nozzles may choke depending on altitude, B or T04 
prf_critical= (1-(gamma-1)/(e_n_cold*(gamma+1)))^(gamma/(gamma-1));   % to check if cold stream nozzle chokes or not
prc_critical= (1-(gamma-1)/(e_n_hot*(gamma+1)))^(gamma/(gamma-1)) ;   % to check if hot stream nozzle chokes or not

% diffuser stage
T02=T_inf*(1+(gamma-1)*0.5*M_inf^2) ;                   
P02=P_inf*(1+(T02/T_inf-1)*e_diff)^(gamma/(gamma-1));

% fan outlet conditons
P08  =P02*prf  ;                                         % fan outlet pressure
T08=(T02*(1+(prf^((gamma-1)/gamma)-1)/e_fan));           % fan outlet temperature
    
% fan nozzle exit velocity
if P_inf/P08>prf_critical                          % if cold stream nozzle is unchoked
    v9 =sqrt(2*e_n_cold*Cp*T08 *(1-(P_inf/P08 )^((gamma-1)/gamma)));     % unchoked exit velocity at cold stream nozzle
    p9=P_inf;
else                                     % if cold stream nozzle is choked
    p9=P08*prf_critical;                 % exit pressure = critical pressure
    T9=2*T08/(gamma+1);                  % exit temperature = critical temperature
    rho9=p9/(R*T9);                      % exit critical density
    v9=sqrt(gamma*R*T9);                 % choked exit velocity
    sprintf('Cold stream nozzle is choked, diameter-')
    2*sqrt(m*(1+B)/(rho9*v9*3.14))
end

for i=1:length(prc)
   %   compressor stage
    P03(i)=(P08*prc(i));
    T03(i)=T08*(1+(prc(i)^((gamma-1)/gamma)-1)/e_comp);
    
    % burner fuel air ratio
    f(i)=(T04-T03(i))/(e_burner*Q/Cp-T04);
    
    % turbine inlet pressure
    P04(i)=P03(i)-del_p ;           %  given pressure loss is zero
    
        
   % compressor turbine power balance
    T05(i)=T04-(T03(i)+T02-B*(T08 -T02))/(1+f(i));
    P05(i)=(P04(i)*(1-(1-T05(i)/T04)/e_turb)^(gamma/(gamma-1)));
    T06(i)=T05(i);
    P06(i)=P05(i);  %no losses in jet pipe
     
      % specific thrust, TSFC, efficiencies
      
      if P_inf/P06(i)>prc_critical &&  P_inf/P08>prf_critical           % both nozzles unchoked
           v7(i)=(sqrt(2*e_n_hot*Cp*T06(i)*(1-(P_inf/P06(i))^((gamma-1)/gamma))));
           %  v7 to be used if the nozzle isn't choked since it's assumed that
           %  P_inf=P7 or complete expansion to atmospheric pressure
           t(i)=(1+f(i))*v7(i)+B*v9-(1+B)*u ;  % unchoked nozzle 
           
                     
      elseif  prc_critical>=P_inf/P06(i) && prf_critical>=P_inf/P08      % both nozzles choked
          % choked condition, all parameters are critical conditions
           T7(i)=2*T06(i)/(gamma+1);
           p7(i)=P06(i)*prc_critical;
           v7(i)=(gamma*R*T7(i))^0.5;  
           rho7(i)=p7(i)/(R*T7(i));
      
           t(i)=(1+f(i))*v7(i)+B*(v9-u)-u + (p7(i)-P_inf)/(rho7(i)*v7(i))+B*(p9-P_inf)/(rho9*v9); % choked nozzle thrust
            % exit velocity v7 fixed by critical pressure ratio, 
            % extra pressure thrust terms come to picture  
            sprintf('both nozzles choked at pressure ratio ')
            prc(i)
            sprintf('nozzle diameter')
            sqrt(m/(rho7(i)*v7(i)*3.14))
      
      elseif P_inf/P06(i)> prc_critical &&   prf_critical>=P_inf/P08     % only cold nozzle chokes
          
         v7(i)=(sqrt(2*e_n_hot*Cp*T06(i)*(1-(P_inf/P06(i))^((gamma-1)/gamma))));
         t(i)=(1+f(i))*v7(i)+B*(v9-u)-u+B*(p9-P_inf)/(rho9*v9);
          sprintf('only cold nozzle chokes')
          prc(i)
          
         
      elseif prc_critical>=P_inf/P06(i) &&  P_inf/P08>prf_critical    % only hot nozzle chokes
      
           T7(i)=2*T06(i)/(gamma+1);
           p7(i)=P06(i)*prc_critical;
           v7(i)=(gamma*R*T7(i))^0.5;  
           rho7(i)=p7(i)/(R*T7(i));
      
           t(i)=(1+f(i))*v7(i)+B*(v9-u)-u + (p7(i)-P_inf)/(rho7(i)*v7(i));
           sprintf('only hot nozzle chokes')
           prc(i)
            sprintf('nozzle diameter')
            sqrt(m/(rho7(i)*v7(i)*3.14))
           
      end  
       e_prop(i)=2*t(i)*u/(t(i)*u*2+(1+f(i))*(v7(i)-u)^2+B*(v9-u)^2);  % propulsive efficiency
       e_therm(i)=(t(i)*u*2+(1+f(i))*(v7(i)-u)^2+B*(v9-u)^2)/(2*f(i)*Q); %thermal efficiency
end

s=f./t      ;   % TSFC

    figure
     hold on
      plot(t,s)
       title('TSFC against Specific thrust')
       xlabel('  Specific thrust ')
       ylabel('TSFC')%
 
    
    figure
 hold on
      plot(prc,P06)
      hold on
   line([0 50],[P_inf/prc_critical P_inf/prc_critical])
     title('P06 vs \pi_C')
    xlabel(' Compressor pressure ratio \pi_C ')
      ylabel('P06')
    
     figure
    hold on
       plot(prc,t/(1+B)) 
        title('Specific thrust against \pi_c')
        xlabel('Compressor pressure ratio \pi_C ')
        ylabel('\tau / (dm_0/dt) N.s/kg')%
 
 figure
       hold on
            plot(prc,s*1000*3600)
       title('TSFC against \pi_c')
          xlabel('  Compressor pressure ratio \pi_C')
        ylabel('TSFC  kg/kN.hr')%
   
    figure 
      hold on
      plot(prc,e_prop,'+')
           plot(prc,e_therm ,'o'  )
        plot(prc,e_prop.*e_therm, '*' )
         title('T_{04}=1630 K  ')
          xlabel('\pi_C Compressor pressure ratio')
         ylabel('Efficiencies \eta (High to low - propulsive, thermal, overall)')%
        
