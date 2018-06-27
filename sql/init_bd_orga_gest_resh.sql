/*  

-- Base de données sur l'organisme de la gestion des réseaux humides

--  #################################################################### SUIVI CODE SQL ####################################################################

2018-06-25 : FV / initialisation du code
2018-06-25 : FV / hypothèse :
1 table geo pour les organismes compétents
1 table geo pour les zones de gestion.
1 table geo pour les lots (si sectorisation carto)
1 table alpha pour les presta
1 orga à de 0 à n zones de gestion.
1 zone de gestion appartient à 1 et 1 seul organisme gestionnaire.
1 zone de gestion contient de 1 à n lot
1 lot appartient à 1 et 1 seule zone de gestion
1 lot est affecté à 1 et 1 seul prestataire
1 zone de gestion est obligatoirment à l'intérieur de la zone de compétence de l'organisme en charge du réseau
1 lot est obligatoirement à l'intérieur d'une zone de gestion
1 orga ne peut pas intersecter un autre orga pour le meme type de réseau
1 vue alpha par réseau et par orga compétent
1 vue alpha pour tab de synthèse par commune de tous les réseaux


DO

2018-06-25 : FV / transformation classe entité contrat en zone de gestion car cela permet de traiter les cas de régie à ce niveau
2018-06-26 : FV / ajout de la vérification que l'orga compétent intersect le pays compiégnois lors de l'insert ou l'update

TODO
* gérer les non superposition entre organismes (voir zone de gestion et lot) PAR TYPE DE RESEAU
* voir pour gérer prb de topologie pour la vue par commune
* st_overlaps autorise une geometrie totalement à l'intérieur d'une autre ... à vérifier
* changer les fonctions d'interrogation spatiale de base par du st_relate

* faut il prévoir lors de l'insert d'un orga, l'insert d'une de zone de gestion et d'un lot de la meme emprise ... ca permettrait de traiter les cas communs. Ne resterait donc plus qu'à découper ensuite au besoin.
* voir pour faire une vue matérialisée pour la synthèse communale pour des questions de performances
-- Prb de l'infra communal pour des gestions spécifiques (ZAC interco ou privé pour habitat et l'éco, raccrochement de secteurs d'une commune sur la gestion de la commune voisine ...)

*/


-- #################################################################### SCHEMA  ####################################################################


-- Schema: m_reseau_humide

-- DROP SCHEMA m_reseau_humide;

CREATE SCHEMA m_reseau_humide
  AUTHORIZATION postgres;

GRANT ALL ON SCHEMA r_objet TO postgres;
GRANT ALL ON SCHEMA r_objet TO groupe_sig WITH GRANT OPTION;
COMMENT ON SCHEMA m_reseau_humide
  IS 'Données géographiques métiers';
 


-- #################################################################### ORGANISME COMPETENT ########################################################

-- Table: m_reseau_humide.geo_resh_orga_compet

-- DROP TABLE m_reseau_humide.geo_resh_orga_compet;

CREATE TABLE m_reseau_humide.geo_resh_orga_compet
(
  id_orga bigint NOT NULL, 
  type_res character varying(30) NOT NULL,
  sstype_res character varying(30) NOT NULL,
  type_orga character varying(30),
  nom_orga character varying(80) NOT NULL,
  siret character varying(80),
  observ character varying(254),
  src character varying(80),
  date_sai timestamp without time zone NOT NULL DEFAULT now(),   
  date_maj timestamp without time zone,
  geom geometry(Polygon,2154) NOT NULL,
       
  CONSTRAINT geo_resh_orga_compet_pkey PRIMARY KEY (id_orga)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE m_reseau_humide.geo_resh_orga_compet
  OWNER TO postgres;
GRANT ALL ON TABLE m_reseau_humide.geo_resh_orga_compet TO groupe_sig WITH GRANT OPTION;
GRANT ALL ON TABLE m_reseau_humide.geo_resh_orga_compet TO postgres;

COMMENT ON TABLE m_reseau_humide.geo_resh_orga_compet
  IS 'Table géographique des organismes assurant une compétence d''un réseau hummide';
COMMENT ON COLUMN m_reseau_humide.geo_resh_orga_compet.id_orga IS 'Identifiant unique de l''organisme compétent';
COMMENT ON COLUMN m_reseau_humide.geo_resh_orga_compet.type_res IS 'Type de réseau';
COMMENT ON COLUMN m_reseau_humide.geo_resh_orga_compet.sstype_res IS 'Sous-type de réseau';
COMMENT ON COLUMN m_reseau_humide.geo_resh_orga_compet.type_orga IS 'Type d''organisme compétent';
COMMENT ON COLUMN m_reseau_humide.geo_resh_orga_compet.nom_orga IS 'Nom de d''organisme compétent';
COMMENT ON COLUMN m_reseau_humide.geo_resh_orga_compet.siret IS 'Numéro SIRET de l''organisme compétent';
COMMENT ON COLUMN m_reseau_humide.geo_resh_orga_compet.observ IS 'Observations';
COMMENT ON COLUMN m_reseau_humide.geo_resh_orga_compet.src IS 'Source de l''information';
COMMENT ON COLUMN m_reseau_humide.geo_resh_orga_compet.date_sai IS 'Horodatage de l''intégration en base de l''objet';
COMMENT ON COLUMN m_reseau_humide.geo_resh_orga_compet.date_maj IS 'Horodatage de la mise à jour en base de l''objet';
COMMENT ON COLUMN m_reseau_humide.geo_resh_orga_compet.geom IS 'Emprise de la zone de compétence de l''organisme';


-- Sequence: m_reseau_humide.geo_resh_orga_compet_id_seq

-- DROP SEQUENCE m_reseau_humide.geo_resh_orga_compet_id_seq;

CREATE SEQUENCE m_reseau_humide.geo_resh_orga_compet_id_seq
  INCREMENT 1
  MINVALUE 0
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE m_reseau_humide.geo_resh_orga_compet_id_seq
  OWNER TO postgres;
GRANT ALL ON SEQUENCE m_reseau_humide.geo_resh_orga_compet_id_seq TO postgres;
GRANT ALL ON SEQUENCE m_reseau_humide.geo_resh_orga_compet_id_seq TO groupe_sig WITH GRANT OPTION;
ALTER TABLE m_reseau_humide.geo_resh_orga_compet ALTER COLUMN id_orga SET DEFAULT nextval('m_reseau_humide.geo_resh_orga_compet_id_seq'::regclass);



-- #################################################################### ZONE DE GESTION ########################################################

-- Table: m_reseau_humide.geo_resh_gest

-- DROP TABLE m_reseau_humide.geo_resh_gest;

CREATE TABLE m_reseau_humide.geo_resh_gest
(
  id_gest bigint NOT NULL,
  id_orga bigint NOT NULL,
  mode_gest character varying(3) NOT NULL,
  ref_gest character varying(80),
  date_debut date,
  date_fin date,
  observ character varying(254),
  src character varying(80),
  date_sai timestamp without time zone NOT NULL DEFAULT now(),   
  date_maj timestamp without time zone,
  geom geometry(Polygon,2154) NOT NULL,
       
  CONSTRAINT geo_resh_gest_pkey PRIMARY KEY (id_gest),
  CONSTRAINT geo_resh_id_orga_fkey FOREIGN KEY (id_orga)
      REFERENCES m_reseau_humide.geo_resh_orga_compet (id_orga) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION  
)
WITH (
  OIDS=FALSE
);
ALTER TABLE m_reseau_humide.geo_resh_gest
  OWNER TO postgres;
GRANT ALL ON TABLE m_reseau_humide.geo_resh_gest TO groupe_sig WITH GRANT OPTION;
GRANT ALL ON TABLE m_reseau_humide.geo_resh_gest TO postgres;

COMMENT ON TABLE m_reseau_humide.geo_resh_gest
  IS 'Table géographique des zone de gestion d''un organisme exercant une compétence d''un réseau humide';
COMMENT ON COLUMN m_reseau_humide.geo_resh_gest.id_gest IS 'Identifiant unique de la zone de gestion';
COMMENT ON COLUMN m_reseau_humide.geo_resh_gest.id_orga IS 'Identifiant unique de l''organisme compétent';
COMMENT ON COLUMN m_reseau_humide.geo_resh_gest.mode_gest IS 'Mode de gestion';
COMMENT ON COLUMN m_reseau_humide.geo_resh_gest.ref_gest IS 'Référence de la zone de gestion';
COMMENT ON COLUMN m_reseau_humide.geo_resh_gest.date_debut IS 'Date de début du contrat en cas d''une gestion externalisée';
COMMENT ON COLUMN m_reseau_humide.geo_resh_gest.date_fin IS 'Date de fin du contrat en cas d''une gestion externalisée';
COMMENT ON COLUMN m_reseau_humide.geo_resh_gest.observ IS 'Observations';
COMMENT ON COLUMN m_reseau_humide.geo_resh_gest.src IS 'Source de l''information';
COMMENT ON COLUMN m_reseau_humide.geo_resh_gest.date_sai IS 'Horodatage de l''intégration en base de l''objet';
COMMENT ON COLUMN m_reseau_humide.geo_resh_gest.date_maj IS 'Horodatage de la mise à jour en base de l''objet';
COMMENT ON COLUMN m_reseau_humide.geo_resh_gest.geom IS 'Emprise de la zone d''effet du gest';


-- Sequence: m_reseau_humide.geo_resh_gest_id_seq

-- DROP SEQUENCE m_reseau_humide.geo_resh_gest_id_seq;

CREATE SEQUENCE m_reseau_humide.geo_resh_gest_id_seq
  INCREMENT 1
  MINVALUE 0
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE m_reseau_humide.geo_resh_gest_id_seq
  OWNER TO postgres;
GRANT ALL ON SEQUENCE m_reseau_humide.geo_resh_gest_id_seq TO postgres;
GRANT ALL ON SEQUENCE m_reseau_humide.geo_resh_gest_id_seq TO groupe_sig WITH GRANT OPTION;
ALTER TABLE m_reseau_humide.geo_resh_gest ALTER COLUMN id_gest SET DEFAULT nextval('m_reseau_humide.geo_resh_gest_id_seq'::regclass);



-- #################################################################### LOT ########################################################

-- Table: m_reseau_humide.geo_resh_lot

-- DROP TABLE m_reseau_humide.geo_resh_lot;

CREATE TABLE m_reseau_humide.geo_resh_lot
(
  id_lot bigint NOT NULL,
  id_gest bigint NOT NULL,
  prest character varying(80),
  observ character varying(254),
  src character varying(80),
  date_sai timestamp without time zone NOT NULL DEFAULT now(),   
  date_maj timestamp without time zone,
  geom geometry(Polygon,2154) NOT NULL,
       
  CONSTRAINT geo_resh_lot_pkey PRIMARY KEY (id_lot),
  CONSTRAINT geo_resh_id_gest_fkey FOREIGN KEY (id_gest)
      REFERENCES m_reseau_humide.geo_resh_gest (id_gest) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION  
)
WITH (
  OIDS=FALSE
);
ALTER TABLE m_reseau_humide.geo_resh_lot
  OWNER TO postgres;
GRANT ALL ON TABLE m_reseau_humide.geo_resh_lot TO groupe_sig WITH GRANT OPTION;
GRANT ALL ON TABLE m_reseau_humide.geo_resh_lot TO postgres;

COMMENT ON TABLE m_reseau_humide.geo_resh_lot
  IS 'Table géographique des lots d''une zone de gestion d''un organisme exercant une compétence d''un réseau humide';
COMMENT ON COLUMN m_reseau_humide.geo_resh_lot.id_lot IS 'Identifiant unique du lot';
COMMENT ON COLUMN m_reseau_humide.geo_resh_lot.id_gest IS 'Identifiant unique de la zone de gestion de l''organisme compétent';
COMMENT ON COLUMN m_reseau_humide.geo_resh_lot.prest IS 'Nom du prestataire assurant la gestion du réseau du lot';
COMMENT ON COLUMN m_reseau_humide.geo_resh_lot.observ IS 'Observations';
COMMENT ON COLUMN m_reseau_humide.geo_resh_lot.src IS 'Source de l''information';
COMMENT ON COLUMN m_reseau_humide.geo_resh_lot.date_sai IS 'Horodatage de l''intégration en base de l''objet';
COMMENT ON COLUMN m_reseau_humide.geo_resh_lot.date_maj IS 'Horodatage de la mise à jour en base de l''objet';
COMMENT ON COLUMN m_reseau_humide.geo_resh_lot.geom IS 'Emprise de la zone d''effet du lot';


-- Sequence: m_reseau_humide.geo_resh_lot_id_seq

-- DROP SEQUENCE m_reseau_humide.geo_resh_lot_id_seq;

CREATE SEQUENCE m_reseau_humide.geo_resh_lot_id_seq
  INCREMENT 1
  MINVALUE 0
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE m_reseau_humide.geo_resh_lot_id_seq
  OWNER TO postgres;
GRANT ALL ON SEQUENCE m_reseau_humide.geo_resh_lot_id_seq TO postgres;
GRANT ALL ON SEQUENCE m_reseau_humide.geo_resh_lot_id_seq TO groupe_sig WITH GRANT OPTION;
ALTER TABLE m_reseau_humide.geo_resh_lot ALTER COLUMN id_lot SET DEFAULT nextval('m_reseau_humide.geo_resh_lot_id_seq'::regclass);


-- #################################################################### PRESTATAIRE ########################################################






-- ####################################################################################################################################################
-- ###                                                                                                                                              ###
-- ###                                                                DOMAINES DE VALEURS                                                           ###
-- ###                                                                                                                                              ###
-- ####################################################################################################################################################


-- Table: m_reseau_humide.lt_resh_type_orga

-- DROP TABLE m_reseau_humide.lt_resh_type_orga;

CREATE TABLE m_reseau_humide.lt_resh_type_orga
(
  code character varying(2) NOT NULL, 
  valeur character varying(80) NOT NULL,

  CONSTRAINT lt_resh_type_orga_pkey PRIMARY KEY (code)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE m_reseau_humide.lt_resh_type_orga
  OWNER TO postgres;
GRANT ALL ON TABLE m_reseau_humide.lt_resh_type_orga TO postgres;
GRANT ALL ON TABLE m_reseau_humide.lt_resh_type_orga TO groupe_sig WITH GRANT OPTION;
COMMENT ON TABLE m_reseau_humide.lt_resh_type_orga
  IS 'Code permettant de décrire le type d''organisme exercant une compétence sur les réseaux';
COMMENT ON COLUMN m_reseau_humide.lt_resh_type_orga.code IS 'Code ';
COMMENT ON COLUMN m_reseau_humide.lt_resh_type_orga.valeur IS 'Valeur ';

INSERT INTO m_reseau_humide.lt_resh_type_orga(
            code, valeur)
    VALUES
    ('00','Non renseigné'),
    ('01','Commune'),
    ('02','Intercommunalité'),
    ('03','Syndicat'),
    ('99','Autre');
    
    
-- Table: m_reseau_humide.lt_resh_type_res

-- DROP TABLE m_reseau_humide.lt_resh_type_res;

CREATE TABLE m_reseau_humide.lt_resh_type_res
(
  code character varying(2) NOT NULL, 
  valeur character varying(80) NOT NULL,
  sigle character varying(3) NOT NULL,

  CONSTRAINT lt_resh_type_res_pkey PRIMARY KEY (code)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE m_reseau_humide.lt_resh_type_res
  OWNER TO postgres;
GRANT ALL ON TABLE m_reseau_humide.lt_resh_type_res TO postgres;
GRANT ALL ON TABLE m_reseau_humide.lt_resh_type_res TO groupe_sig WITH GRANT OPTION;
COMMENT ON TABLE m_reseau_humide.lt_resh_type_res
  IS 'Code permettant de décrire le type de réseau humide';
COMMENT ON COLUMN m_reseau_humide.lt_resh_type_res.code IS 'Code';
COMMENT ON COLUMN m_reseau_humide.lt_resh_type_res.valeur IS 'Valeur';
COMMENT ON COLUMN m_reseau_humide.lt_resh_type_res.sigle IS 'Sigle';

INSERT INTO m_reseau_humide.lt_resh_type_res(
            code, valeur, sigle)
    VALUES
    ('0','Non renseigné','NR'),
    ('1','Adduction d''eau potable','AEP'),
    ('2','Assainissement','ASS'),
    ('3','Chauffage urbain','CHA'),
    ('4','Arrosage','ARR'),
    ('9','Autre','AUT');      


-- Table: m_reseau_humide.lt_resh_sstype_res

-- DROP TABLE m_reseau_humide.lt_resh_sstype_res;

CREATE TABLE m_reseau_humide.lt_resh_sstype_res
(
  code character varying(2) NOT NULL, 
  valeur character varying(80) NOT NULL,
  sigle character varying(5) NOT NULL,

  CONSTRAINT lt_resh_sstype_res_pkey PRIMARY KEY (code)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE m_reseau_humide.lt_resh_sstype_res
  OWNER TO postgres;
GRANT ALL ON TABLE m_reseau_humide.lt_resh_sstype_res TO postgres;
GRANT ALL ON TABLE m_reseau_humide.lt_resh_sstype_res TO groupe_sig WITH GRANT OPTION;
COMMENT ON TABLE m_reseau_humide.lt_resh_sstype_res
  IS 'Code permettant de décrire le sous type de réseau humide';
COMMENT ON COLUMN m_reseau_humide.lt_resh_sstype_res.code IS 'Code';
COMMENT ON COLUMN m_reseau_humide.lt_resh_sstype_res.valeur IS 'Valeur';
COMMENT ON COLUMN m_reseau_humide.lt_resh_sstype_res.sigle IS 'Sigle';

INSERT INTO m_reseau_humide.lt_resh_sstype_res(
            code, valeur, sigle)
    VALUES
    ('00','Non renseigné','NR'),
    ('10','Adduction d''eau potable','AEP'),
    ('11','Distribution d''eau potable','AEP_d'),
    ('12','Production d''eau potable','AEP_p'),
    ('20','Assainissement','ASS'),
    ('21','Eau usée','EU'),
    ('22','Eau pluviale','EP'),
    ('30','Chauffage urbain','CHA'),
    ('40','Arrosage','ARR'),    
    ('99','Autre','AUT');     

-- Table: m_reseau_humide.lt_resh_mode_gest

-- DROP TABLE m_reseau_humide.lt_resh_mode_gest;

CREATE TABLE m_reseau_humide.lt_resh_mode_gest
(
  code character varying(2) NOT NULL,
  valeur character varying(80) NOT NULL,
  definition character varying(3) NOT NULL,
  CONSTRAINT lt_resh_mode_gest_pkey PRIMARY KEY (code)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE m_reseau_humide.lt_resh_mode_gest
  OWNER TO postgres;
GRANT ALL ON TABLE m_reseau_humide.lt_resh_mode_gest TO postgres;
GRANT ALL ON TABLE m_reseau_humide.lt_resh_mode_gest TO groupe_sig WITH GRANT OPTION;
COMMENT ON TABLE m_reseau_humide.lt_resh_mode_gest
  IS 'Code permettant de décrire le mode de gestion d''un réseau';
COMMENT ON COLUMN m_reseau_humide.lt_resh_mode_gest.code IS 'Code';
COMMENT ON COLUMN m_reseau_humide.lt_resh_mode_gest.valeur IS 'Valeur ';
COMMENT ON COLUMN m_reseau_humide.lt_resh_mode_gest.definition IS 'Définition ';

INSERT INTO m_reseau_humide.lt_resh_mode_gest(
            code, valeur, definition)
    VALUES
    ('00','Non renseigné','NR'),
    ('01','Régie','REG'),
    ('02','Prestations de service','PS'),
    ('03','Délégation de Service Public','DSP'),
    ('04','Concession de Service Public','CSP'),
    ('99','Autre','AUT');



-- ####################################################################################################################################################
-- ###                                                                                                                                              ###
-- ###                                                                        FKEY                                                                  ###
-- ###                                                                                                                                              ###
-- ####################################################################################################################################################


-- Foreign Key: m_reseau_humide.lt_resh_type_orga_fkey

-- ALTER TABLE m_reseau_humide.geo_resh_orga_compet DROP CONSTRAINT lt_resh_type_orga_fkey;

ALTER TABLE m_reseau_humide.geo_resh_orga_compet
  ADD CONSTRAINT lt_resh_type_orga_fkey FOREIGN KEY (type_orga)
      REFERENCES m_reseau_humide.lt_resh_type_orga (code) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION;


-- Foreign Key: m_reseau_humide.lt_resh_type_res_fkey

-- ALTER TABLE m_reseau_humide.geo_resh_orga_compet DROP CONSTRAINT lt_resh_type_res_fkey;

ALTER TABLE m_reseau_humide.geo_resh_orga_compet
  ADD CONSTRAINT lt_resh_type_res_fkey FOREIGN KEY (type_res)
      REFERENCES m_reseau_humide.lt_resh_type_res (code) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION;


-- Foreign Key: m_reseau_humide.lt_resh_sstype_res_fkey

-- ALTER TABLE m_reseau_humide.geo_resh_orga_compet DROP CONSTRAINT lt_resh_sstype_res_fkey;

ALTER TABLE m_reseau_humide.geo_resh_orga_compet
  ADD CONSTRAINT lt_resh_sstype_res_fkey FOREIGN KEY (sstype_res)
      REFERENCES m_reseau_humide.lt_resh_sstype_res (code) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION;

    
-- Foreign Key: m_reseau_humide.lt_resh_mode_gest_fkey

-- ALTER TABLE m_reseau_humide.geo_resh_gest DROP CONSTRAINT lt_resh_mode_gest_fkey;

ALTER TABLE m_reseau_humide.geo_resh_gest
  ADD CONSTRAINT lt_resh_mode_gest_fkey FOREIGN KEY (mode_gest)
      REFERENCES m_reseau_humide.lt_resh_mode_gest (code) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION;
      
      
      

-- ####################################################################################################################################################
-- ###                                                                                                                                              ###
-- ###                                                                        VUES                                                                  ###
-- ###                                                                                                                                              ###
-- ####################################################################################################################################################




-- View: m_reseau_humide.an_v_resh_commune

-- DROP VIEW m_reseau_humide.an_v_resh_commune;

CREATE OR REPLACE VIEW m_reseau_humide.an_v_resh_commune AS 
 SELECT 
  ROW_NUMBER () OVER () as gid,
  g.insee,
  g.commune,
  lt1.sigle as type_res,
  lt2.valeur as type_orga,
  o.nom_orga,
  lt3.valeur as mode_gest,
  l.prest
   

   FROM r_osm.geo_v_osm_commune_apc g
   LEFT JOIN m_reseau_humide.geo_resh_orga_compet o ON ST_Intersects(ST_Buffer(o.geom, -1), g.geom) IS TRUE
   LEFT JOIN m_reseau_humide.lt_resh_sstype_res lt1 ON lt1.code = o.sstype_res
   LEFT JOIN m_reseau_humide.lt_resh_type_orga lt2 ON lt2.code = o.type_orga
   LEFT JOIN m_reseau_humide.geo_resh_gest c ON ST_Intersects(ST_Buffer(c.geom,-1), g.geom) IS TRUE
   LEFT JOIN m_reseau_humide.lt_resh_mode_gest lt3 ON lt3.code = c.mode_gest
   LEFT JOIN m_reseau_humide.geo_resh_lot l ON ST_Intersects(ST_Buffer(l.geom, -1), g.geom) IS TRUE
   ORDER BY g.insee;

ALTER TABLE m_reseau_humide.an_v_resh_commune
  OWNER TO postgres;
COMMENT ON VIEW m_reseau_humide.an_v_resh_commune
  IS 'Synthèse communale de la gestion des réseaux humides (tri par commune)';



-- ####################################################################################################################################################
-- ###                                                                                                                                              ###
-- ###                                                                      TRIGGER                                                                 ###
-- ###                                                                                                                                              ###
-- ####################################################################################################################################################



-- #################################################################### FONCTION TRIGGER - GEO_RESH_ORGA_COMPET #############################################


-- Function: m_reseau_humide.ft_geo_resh_orga_compet()

-- DROP FUNCTION m_reseau_humide.ft_geo_resh_orga_compet();

CREATE OR REPLACE FUNCTION m_reseau_humide.ft_geo_resh_orga_compet()
  RETURNS trigger AS
$BODY$

BEGIN

-- INSERT
IF (TG_OP = 'INSERT') THEN

-- le type de réseau est déduit par le choix du sous-type
NEW.type_res = LEFT(NEW.sstype_res,1);
-- en cas d'insert, la date de maj est obligatoirement NULL
NEW.date_maj = NULL;
-- vérification que l'emprise de l'organisme compétent ne ne supperpose par avec un autre pour le même sous-type de réseau OU que l'organisme compétent intersecte le pays compiégnois
--NEW.geom = CASE WHEN ST_Overlaps(NEW.geom,(SELECT ST_Union(geom) FROM m_reseau_humide.geo_resh_orga_compet as u WHERE NEW.sstype_res = u.sstype_res)) = TRUE OR ST_Intersects(NEW.geom, (SELECT geom FROM r_osm.geo_v_osm_contour_apc)) = FALSE THEN NULL ELSE NEW.geom END;

-- vérification par une matrice de relation spatiale que l'emprise du nouvel organisme compétent ne se supperpose pas avec celle d'un autre organisme compétent sur le même sous-type de réseau ET que l'organisme compétent intersecte le pays compiégnois
NEW.geom = CASE WHEN (SELECT b.id_orga FROM m_reseau_humide.geo_resh_orga_compet b WHERE (ST_relate(NEW.geom, b.geom, '2********') AND (NEW.sstype_res = b.sstype_res))) IS NULL AND ST_Intersects(NEW.geom, (SELECT geom FROM r_osm.geo_v_osm_contour_apc)) = TRUE THEN NEW.geom ELSE NULL END;

RETURN NEW;

-- UPDATE
ELSIF (TG_OP = 'UPDATE') THEN

-- le type de réseau est déduit par le choix du sous-type
NEW.type_res = LEFT(NEW.sstype_res,1);
-- en cas d'update, la date de maj est obligatoirement horodatée
NEW.date_maj = now();
-- vérification par une matrice de relation spatiale que l'emprise du nouvel organisme compétent ne se supperpose pas avec celle d'un autre organisme compétent sur le même sous-type de réseau ET que l'organisme compétent intersecte le pays compiégnois
NEW.geom = CASE WHEN (SELECT b.id_orga FROM m_reseau_humide.geo_resh_orga_compet b WHERE (ST_relate(NEW.geom, b.geom, '2********') AND (NEW.sstype_res = b.sstype_res))) IS NULL AND ST_Intersects(NEW.geom, (SELECT geom FROM r_osm.geo_v_osm_contour_apc)) = TRUE THEN NEW.geom ELSE NULL END;
RETURN NEW;

END IF;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION m_reseau_humide.ft_geo_resh_orga_compet()
  OWNER TO postgres;
COMMENT ON FUNCTION m_reseau_humide.ft_geo_resh_orga_compet() IS 'Fonction trigger pour insert ou update';



-- Trigger: t_geo_resh_orga_compet on m_reseau_humide.geo_resh_orga_compet

-- DROP TRIGGER t_geo_resh_orga_compet ON m_reseau_humide.geo_resh_orga_compet;

CREATE TRIGGER t_geo_resh_orga_compet
  BEFORE INSERT OR UPDATE
  ON m_reseau_humide.geo_resh_orga_compet
  FOR EACH ROW
  EXECUTE PROCEDURE m_reseau_humide.ft_geo_resh_orga_compet();
  


-- #################################################################### FONCTION TRIGGER - GEO_RESH_ZONE DE GESTION #############################################


-- Function: m_reseau_humide.ft_geo_resh_gest()

-- DROP FUNCTION m_reseau_humide.ft_geo_resh_gest();

CREATE OR REPLACE FUNCTION m_reseau_humide.ft_geo_resh_gest()
  RETURNS trigger AS
$BODY$

BEGIN

-- INSERT
IF (TG_OP = 'INSERT') THEN

-- en cas de régie SANS prestations, il n'y a pas d'externalisation donc pas de date de début ou de fin de contrat
NEW.date_debut = CASE WHEN NEW.mode_gest = '01' THEN NULL ELSE NEW.date_debut END;
NEW.date_fin = CASE WHEN NEW.mode_gest = '01' THEN NULL ELSE NEW.date_fin END;
-- en cas d'insert, la date de maj est obligatoirement NULL
NEW.date_maj = NULL;
-- vérification que l'emprise de la zone de gestion est bien à l'intérieur de la zone de l'organisme compétent référencé
NEW.geom = CASE WHEN ST_Within(NEW.geom,(SELECT geom FROM m_reseau_humide.geo_resh_orga_compet as o WHERE NEW.id_orga = o.id_orga)) = FALSE THEN NULL ELSE NEW.geom END;
RETURN NEW;

-- UPDATE
ELSIF (TG_OP = 'UPDATE') THEN

-- en cas de régie SANS prestations, il n'y a pas d'externalisation donc pas de date de début ou de fin de contrat
NEW.date_debut = CASE WHEN NEW.mode_gest = '01' THEN NULL ELSE NEW.date_debut END;
NEW.date_fin = CASE WHEN NEW.mode_gest = '01' THEN NULL ELSE NEW.date_fin END;
-- en cas d'update, la date de maj est obligatoirement horodatée
NEW.date_maj = now();
-- vérification que l'emprise du gest est bien à l'intérieur de la zone de l'organisme compétent référencé pour le gest ET que la nouvelle emprise englobe bien (l'union) de(s) lot(s) référencé(s)
NEW.geom = CASE WHEN ST_Within(NEW.geom,(SELECT geom FROM m_reseau_humide.geo_resh_orga_compet as o WHERE NEW.id_orga = o.id_orga)) = FALSE 
OR ST_Contains(NEW.geom,(SELECT ST_Union(geom) FROM m_reseau_humide.geo_resh_lot as l WHERE NEW.id_gest = l.id_gest)) = FALSE THEN NULL ELSE NEW.geom END;
RETURN NEW;

END IF;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION m_reseau_humide.ft_geo_resh_gest()
  OWNER TO postgres;
COMMENT ON FUNCTION m_reseau_humide.ft_geo_resh_gest() IS 'Fonction trigger pour insert ou update';





-- Trigger: t_geo_resh_gest on m_reseau_humide.geo_resh_gest

-- DROP TRIGGER t_geo_resh_gest ON m_reseau_humide.geo_resh_gest;

CREATE TRIGGER t_geo_resh_gest
  BEFORE INSERT OR UPDATE
  ON m_reseau_humide.geo_resh_gest
  FOR EACH ROW
  EXECUTE PROCEDURE m_reseau_humide.ft_geo_resh_gest();



-- #################################################################### FONCTION TRIGGER - GEO_RESH_LOT #############################################


-- Function: m_reseau_humide.ft_geo_resh_lot()

-- DROP FUNCTION m_reseau_humide.ft_geo_resh_lot();

CREATE OR REPLACE FUNCTION m_reseau_humide.ft_geo_resh_lot()
  RETURNS trigger AS
$BODY$

BEGIN

-- INSERT
IF (TG_OP = 'INSERT') THEN

-- en cas d'insert, la date de maj est obligatoirement NULL
NEW.date_maj = NULL;
-- vérification que l'emprise du lot est bien à l'intérieur du gest référencé pour le lot
NEW.geom = CASE WHEN ST_Within(NEW.geom,(SELECT geom FROM m_reseau_humide.geo_resh_gest as c WHERE NEW.id_gest = c.id_gest)) = FALSE THEN NULL ELSE NEW.geom END;
RETURN NEW;

-- UPDATE
ELSIF (TG_OP = 'UPDATE') THEN

-- en cas d'update, la date de maj est obligatoirement horodatée
NEW.date_maj = now();
-- vérification que l'emprise du lot est bien à l'intérieur du gest référencé pour le lot
NEW.geom = CASE WHEN ST_Within(NEW.geom,(SELECT geom FROM m_reseau_humide.geo_resh_gest as c WHERE NEW.id_gest = c.id_gest)) = FALSE THEN NULL ELSE NEW.geom END;
RETURN NEW;

END IF;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION m_reseau_humide.ft_geo_resh_lot()
  OWNER TO postgres;
COMMENT ON FUNCTION m_reseau_humide.ft_geo_resh_lot() IS 'Fonction trigger pour insert ou update';



-- Trigger: t_geo_resh_lot on m_reseau_humide.geo_resh_lot

-- DROP TRIGGER t_geo_resh_lot ON m_reseau_humide.geo_resh_lot;

CREATE TRIGGER t_geo_resh_lot
  BEFORE INSERT OR UPDATE
  ON m_reseau_humide.geo_resh_lot
  FOR EACH ROW
  EXECUTE PROCEDURE m_reseau_humide.ft_geo_resh_lot();




-- ####################################################################################################################################################
-- ###                                                                                                                                              ###
-- ###                                                                  BAC A SABLE                                                                 ###
-- ###                                                                                                                                              ###
-- ####################################################################################################################################################

/*

--SELECT * FROM m_reseau_humide.geo_resh_orga_compet as a WHERE st_overlaps(a.geom, (SELECT geom FROM m_reseau_humide.geo_resh_orga_compet WHERE id_orga = 1)) IS TRUE;
--SELECT * FROM m_reseau_humide.geo_resh_orga_compet as a WHERE st_intersects(a.geom, (SELECT geom FROM m_reseau_humide.geo_resh_orga_compet WHERE id_orga = 1)) IS TRUE;
SELECT * FROM m_reseau_humide.geo_resh_orga_compet as a WHERE st_touches(a.geom, (SELECT geom FROM m_reseau_humide.geo_resh_orga_compet WHERE id_orga = 1)) IS TRUE;
SELECT a.id_orga as a, b.id_orga as b FROM m_reseau_humide.geo_resh_orga_compet a, m_reseau_humide.geo_resh_orga_compet b WHERE (ST_Relate(a.geom, b.geom, '2********') AND (a.sstype_res = b.sstype_res) AND (a.id_orga <> b.id_orga));




*/
