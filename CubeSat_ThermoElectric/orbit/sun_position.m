function [r_sun, u_sun] = sun_position(JD)
%SUN_POSITION  Position du Soleil en repere ECI, pour un jour julien
%   donne (ephemeride analytique basse precision).
%
%   [r_sun, u_sun] = SUN_POSITION(JD)
%
%   ENTREE
%     JD : jour julien [-] (peut etre un vecteur pour evaluer plusieurs
%          instants a la fois -- toutes les operations sont vectorisees)
%
%   SORTIES
%     r_sun : position Terre->Soleil, vecteur complet [km] (3xN ou 3x1)
%     u_sun : direction unitaire Terre->Soleil (3xN ou 3x1)
%
%   SOURCE : Morsch Filho et al., Energies 13(24):6691, 2020, Eq.21b-i.
%   (Eq.21a, le calcul du jour julien lui-meme, est fait en amont dans
%   TLE_TO_COE.m.)

% --- Eq.21b : nombre de jours depuis J2000 ---------------------------------
nd = JD(:).' - 2451545;

% --- Eq.21c-d : anomalie moyenne et longitude moyenne du Soleil -----------
Ms = deg2rad(mod(357.529 + 0.98560023*nd, 360));
Ls = deg2rad(mod(280.459 + 0.98564736*nd, 360));

% --- Eq.21e : longitude ecliptique -------------------------------------------
lambda = Ls + deg2rad(1.915)*sin(Ms) + deg2rad(0.0200)*sin(2*Ms);

% --- Eq.21f : obliquite de l'ecliptique ----------------------------------------
epsil = deg2rad(23.439 - 3.56e-7*nd);

% --- Eq.21g : vecteur unitaire Terre -> Soleil (ECI) ----------------------------
u_sun = [cos(lambda); cos(epsil).*sin(lambda); sin(epsil).*sin(lambda)];

% --- Eq.21h-i : distance et vecteur Soleil complet --------------------------------
AU = 149597870.691;    % unite astronomique [km]
r_sun_mag = (1.00014 - 0.01671*cos(Ms) - 0.000140*cos(2*Ms)) * AU;
r_sun = r_sun_mag .* u_sun;

end