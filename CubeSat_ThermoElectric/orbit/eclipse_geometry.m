function [ecl, cos_sz] = eclipse_geometry(r_eci, u_sun, R_E)
%ECLIPSE_GEOMETRY  Indicateur d'eclipse (ombre cylindrique) et cosinus
%   de l'angle solaire zenithal au point sub-satellite, a partir de la
%   position reelle du satellite et de la direction du Soleil (ECI).
%
%   [ecl, cos_sz] = ECLIPSE_GEOMETRY(r_eci, u_sun, R_E)
%
%   ENTREES
%     r_eci : position ECI du satellite [km], 3x1 ou 3xN
%     u_sun : direction unitaire Terre->Soleil (ECI), meme taille que r_eci
%     R_E   : rayon terrestre [km]
%
%   SORTIES (meme nombre de colonnes que l'entree)
%     ecl    : 1 si le satellite est a l'ombre de la Terre, 0 sinon
%     cos_sz : cosinus de l'angle solaire zenithal au point sub-satellite
%              (= u_sun . r_hat) -- sert a ponderer l'albedo (nul cote
%              nuit du point sub-satellite)
%
%   METHODE : modele d'ombre cylindrique standard (Vallado, Fundamentals
%   of Astrodynamics and Applications, algorithme "Shadow"). Le
%   satellite est a l'ombre s'il est cote nuit (cos_sz<0) ET si sa
%   distance perpendiculaire a l'axe Terre-Soleil est inferieure au
%   rayon terrestre. Meme formule que celle deja utilisee dans le
%   modele idealise (orbital_kinematics) et dans les scripts de
%   visualisation -- factorisee ici en fonction reutilisable.

r_mag  = vecnorm(r_eci, 2, 1);          % 1xN
r_hat  = r_eci ./ r_mag;                 % 3xN
cos_sz = sum(u_sun .* r_hat, 1);         % 1xN, produit scalaire colonne par colonne

d_perp = r_mag .* sqrt(max(0, 1 - cos_sz.^2));
ecl = double((cos_sz < 0) & (d_perp < R_E));   % 1xN, 0/1

end