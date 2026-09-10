function [ecl, cos_sz] = eclipse_geometry(r_eci, r_sun, R_E)
%ECLIPSE_GEOMETRY  Indicateur d'eclipse et cosinus de l'angle solaire
%   zenithal, par TEST ANGULAIRE (cone d'ombre) -- remplace la version
%   precedente fondee sur le modele d'ombre cylindrique (Vallado).
%
%   [ecl, cos_sz] = ECLIPSE_GEOMETRY(r_eci, r_sun, R_E)
%
%   ENTREES
%     r_eci : position ECI du satellite [km], 3x1 ou 3xN
%     r_sun : position ECI du Soleil (VECTEUR COMPLET, pas seulement la
%             direction unitaire -- cf. note ci-dessous), meme taille
%             que r_eci. C'est la sortie r_sun de sun_position.m,
%     R_E   : rayon terrestre [km]
%
%   SORTIES (meme nombre de colonnes que l'entree)
%     ecl    : 1 si le satellite est a l'ombre de la Terre, 0 sinon
%     cos_sz : cosinus de l'angle solaire zenithal au point sub-satellite
%              (= cos(chi) ci-dessous) -- meme grandeur et meme usage
%              en aval (ponderation de l'albedo) que dans la version
%              precedente, donc AUCUN changement necessaire cote flux/.
%
%   METHODE : test angulaire, mesure au centre de la Terre (cf. schema
%   "Diagram to estimate the shadow", Eq.31a-d de la reference associee) :
%
%     chi_c   = acos(R_E/|r|)         angle limite du cone d'ombre cote
%                                      satellite (0 en surface, ->90 deg
%                                      loin de la Terre)
%     chi_sun = acos(R_E/|r_sun|)     meme angle cote Soleil (~90 deg,
%                                      le Soleil etant tres eloigne --
%                                      c'est ce terme qui transforme le
%                                      cylindre en cone legerement
%                                      convergent, plus realiste qu'un
%                                      cylindre pur)
%     chi     = acos(r.r_sun/(|r||r_sun|))   ecart angulaire total entre
%                                      satellite et Soleil, vu depuis le
%                                      centre de la Terre
%
%   Le satellite est ECLAIRE si chi <= chi_c+chi_sun, A L'OMBRE sinon.
%
%   ATTENTION -- CONDITION CORRIGEE PAR RAPPORT AU DOCUMENT SOURCE :

r_mag    = vecnorm(r_eci, 2, 1);          % 1xN
rsun_mag = vecnorm(r_sun, 2, 1);          % 1xN

% --- Eq.31a-b : angles limites du cone d'ombre ----------------------------
chi_c   = acos(R_E ./ r_mag);
chi_sun = acos(R_E ./ rsun_mag);

% --- Eq.31c : ecart angulaire satellite-Soleil, vu depuis la Terre --------
% (cos(chi) = cos_sz : meme grandeur que dans l'ancienne version, calculee
% ici directement sans repasser par un vecteur unitaire separe)
cos_sz = sum(r_eci .* r_sun, 1) ./ (r_mag .* rsun_mag);
chi = acos(cos_sz);

% --- Eq.31d (corrigee) : test d'eclipse -------------------------------------
ecl = double(chi > chi_c + chi_sun);

end