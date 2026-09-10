function coe = tle_to_coe(tle, varargin)
%TLE_TO_COE  Extrait les elements orbitaux classiques (COE) d'un TLE.
%
%   coe = TLE_TO_COE(tle)
%   coe = TLE_TO_COE(tle, 'mu', ..., 'R_E', ...)
%
%   Les colonnes lues suivent la specification a positions fixes du
%   format TLE (documentation CelesTrak, "Two-Line Elements: A short
%   course", T.S. Kelso). Les formules de conversion (mouvement moyen
%   -> demi-grand axe, moment cinetique, equation de Kepler, anomalie
%   vraie) suivent Vallado [Fundamentals of Astrodynamics and
%   Applications, 4e ed.] et Morsch Filho et al. (Energies, 2020),
%   Eq.1-4.
%
%   OPTIONS (paires nom/valeur)
%     'mu'  (defaut 398600 km^3/s^2)
%     'R_E' (defaut 6378 km)
%   Ces deux valeurs sont stockees dans coe.mu / coe.R_E, pour que les
%   fonctions en aval (propagate_orbit.m, etc.) les reutilisent
%   directement plutot que de redefinir leurs propres valeurs par
%   defaut independantes -- evite qu'un appel avec un mu different
%   laisse a/h0 calcules avec l'ancienne valeur.
%
%   SORTIE (struct coe) -- angles en RADIANS, vitesses en rad/s
%     .i, .Omega, .e, .omega, .M0   : elements classiques a l'epoque
%     .n                            : mouvement moyen [rad/s]
%     .a                            : demi-grand axe [km]
%     .h0                           : moment cinetique specifique a
%                                      l'epoque [km^2/s]
%     .theta0                       : anomalie vraie a l'epoque [rad]
%     .T_orb                        : periode orbitale [s]
%     .mu, .R_E                     : constantes utilisees pour ce calcul
%                                      (a reutiliser en aval, cf. ci-dessus)
%     .epoch_JD                     : jour julien de l'epoque du TLE
%     .epoch_datevec                : [Y M D h m s] calendaire
%     .name, .norad_id              : recopies depuis tle

p = inputParser;
addParameter(p, 'mu', 398600);    % km^3/s^2
addParameter(p, 'R_E', 6378);     % km
parse(p, varargin{:});
mu  = p.Results.mu;

line1 = tle.line1;
line2 = tle.line2;

% --- Elements orbitaux (colonnes fixes du TLE) ----------------------------
i_deg      = str2double(line2(9:16));
Omega_deg  = str2double(line2(18:25));
e          = str2double(['0.' line2(27:33)]);
omega_deg  = str2double(line2(35:42));
M_deg      = str2double(line2(44:51));
n_rev_day  = str2double(line2(53:63));

n = n_rev_day * 2*pi / 86400;          % mouvement moyen [rad/s]
a = (mu / n^2)^(1/3);                  % 3e loi de Kepler
h0 = sqrt(a * mu * (1 - e^2));         % moment cinetique specifique

coe.i     = deg2rad(i_deg);
coe.Omega = deg2rad(Omega_deg);
coe.e     = e;
coe.omega = deg2rad(omega_deg);
coe.M0    = deg2rad(M_deg);
coe.n     = n;
coe.a     = a;
coe.h0    = h0;
coe.T_orb = 2*pi / n;
coe.mu    = mu;             % stocke pour reutilisation par propagate_orbit.m
coe.R_E   = p.Results.R_E;  % idem (non utilise dans ce fichier, transmis tel quel)

% --- Anomalie vraie a l'epoque (equation de Kepler, Newton-Raphson) -------
E = coe.M0;
for k = 1:50
    E = E - (E - e*sin(E) - coe.M0) / (1 - e*cos(E));
end
coe.theta0 = 2*atan( sqrt((1+e)/(1-e)) * tan(E/2) );

% --- Epoque calendaire (necessaire pour sun_position.m) -------------------
epoch_yr  = str2double(line1(19:20));
epoch_day = str2double(line1(21:32));
year = (2000+epoch_yr)*(epoch_yr < 57) + (1900+epoch_yr)*(epoch_yr >= 57); % regle Y2K
dv = datevec(datenum(year,1,0) + epoch_day);
coe.epoch_datevec = dv;

y_ = dv(1); m_ = dv(2); d_ = dv(3);
UT = dv(4) + dv(5)/60 + dv(6)/3600;
coe.epoch_JD = 367*y_ - floor(7*(y_ + floor((m_+9)/12))/4) + floor(275*m_/9) ...
               + d_ + UT/24 + 1721013.5;

coe.name     = tle.name;
coe.norad_id = tle.norad_id;

end