/* psql -U postgres
CREATE DATABASE gestion_utilisateurs;
\c gestion_utilisateurs
*/

-- TASK 1 

CREATE TABLE utilisateurs (
    id  SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL CHECK (email LIKE '%@%'),
    password_hash VARCHAR(255) NOT NULL,
    nom VARCHAR(100),
    prenom VARCHAR(100),
    actif BOOLEAN DEFAULT TRUE,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



CREATE INDEX idx_utilisateurs_email ON utilisateurs(email);
CREATE INDEX idx_utilisateurs_actif ON utilisateurs(actif);


--TASK 2 


CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE permissions (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) UNIQUE NOT NULL,
    ressource VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL,
    description TEXT,
    CONSTRAINT unique_ressource_action UNIQUE (ressource, action)
);



-- TASK 3 

CREATE TABLE utilisateur_roles (
    utilisateur_id INT,
    role_id INT,
    date_assignation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (utilisateur_id, role_id),
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
);

CREATE TABLE role_permissions (
    role_id INT,
    permission_id INT,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
);



-- TASK 4 
CREATE TABLE sessions (
    id SERIAL PRIMARY KEY,
    utilisateur_id INT,
    token VARCHAR(100) UNIQUE NOT NULL,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_expiration TIMESTAMP,
    actif BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE
);

CREATE TABLE logs_connexion (
    id SERIAL PRIMARY KEY,
    utilisateur_id INT, --
    email_tentative VARCHAR(255) CHECK (email_tentative LIKE '%@%'),
    date_heure TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    adresse_ip VARCHAR(50),
    user_agent TEXT,
    succes BOOLEAN,
    message TEXT,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE SET NULL
);

-- TASK 5 


-- Insérer des rôles
INSERT INTO roles (nom, description) VALUES
('admin', 'Administrateur avec tous les droits'),
('moderator', 'Modérateur de contenu'),
('user', 'Utilisateur standard');
-- Insérer des permissions
INSERT INTO permissions (nom, ressource, action, description) VALUES
('read_users', 'users', 'read', 'Lire les utilisateurs'),
('write_users', 'users', 'write', 'Créer/modifier des utilisateurs'),
('delete_users', 'users', 'delete', 'Supprimer des utilisateurs'),
('read_posts', 'posts', 'read', 'Lire les posts'),
('write_posts', 'posts', 'write', 'Créer/modifier des posts'),
('delete_posts', 'posts', 'delete', 'Supprimer des posts');


INSERT INTO role_permissions (role_id, permission_id)
SELECT roles.id, permissions.id
FROM roles, permissions
WHERE roles.nom = 'admin';

INSERT INTO role_permissions (role_id, permission_id)
SELECT roles.id, permissions.id
FROM roles, permissions
WHERE roles.nom = 'moderator'
  AND permissions.nom IN ('read_users', 'read_posts', 'write_posts', 'delete_posts');

INSERT INTO role_permissions (role_id, permission_id)
SELECT roles.id, permissions.id
FROM roles, permissions
WHERE roles.nom = 'user'
  AND permissions.nom IN ('read_users', 'read_posts', 'write_posts');




-- TASK 6 

CREATE OR REPLACE FUNCTION utilisateur_a_permission(
    p_utilisateur_id INT,
    p_ressource VARCHAR,
    p_action VARCHAR
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT NULL
        FROM utilisateurs
        JOIN utilisateur_roles ON utilisateurs.id = utilisateur_roles.utilisateur_id
        JOIN role_permissions ON utilisateur_roles.role_id = role_permissions.role_id
        JOIN permissions ON role_permissions.permission_id = permissions.id
        WHERE utilisateurs.id = p_utilisateur_id
          AND utilisateurs.actif = TRUE
          AND permissions.ressource = p_ressource
          AND permissions.action = p_action
    );
END;
$$ LANGUAGE plpgsql;



-- TASK 7 


SELECT
    u.id,
    u.email,
    u.nom,
    u.prenom,
    u.actif,
    array_agg(r.nom) AS roles
FROM utilisateurs u
JOIN utilisateur_roles ur ON u.id = ur.utilisateur_id
JOIN roles r ON ur.role_id = r.id
WHERE u.id = 1
GROUP BY u.id, u.email, u.nom, u.prenom, u.actif;



-- TASK 8 



SELECT DISTINCT
    u.id AS utilisateur_id,
    u.email,
    p.nom AS permission,
    p.ressource,
    p.action
FROM utilisateurs u
JOIN utilisateur_roles ur ON u.id = ur.utilisateur_id
JOIN role_permissions rp ON ur.role_id = rp.role_id
JOIN permissions p ON rp.permission_id = p.id
WHERE u.id = 1
ORDER BY p.ressource, p.action;



-- TASK 9 



SELECT
    r.nom AS role,
    COUNT(ur.utilisateur_id) AS nombre_utilisateurs
FROM roles r
JOIN utilisateur_roles ur ON r.id = ur.role_id
GROUP BY r.id, r.nom
ORDER BY nombre_utilisateurs DESC;




--TASK 10 


SELECT
    u.id,
    u.email,
    array_agg(r.nom) AS roles
FROM utilisateurs u
JOIN utilisateur_roles ur ON u.id = ur.utilisateur_id
JOIN roles r ON ur.role_id = r.id
WHERE r.nom IN ('admin', 'moderator')
GROUP BY u.id, u.email
HAVING COUNT(DISTINCT r.nom) = 2;





-- TASK 11 

SELECT
    DATE(date_heure) AS jour,
    COUNT(*) AS tentatives_echouees
FROM logs_connexion
WHERE succes = false
    AND date_heure >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY DATE(date_heure)
ORDER BY jour DESC;






CREATE OR REPLACE FUNCTION est_token_valide(p_token VARCHAR)
RETURNS BOOLEAN AS $$
BEGIN
RETURN EXISTS (
SELECT 1
FROM sessions s
INNER JOIN utilisateurs u ON s.utilisateur_id = u.id
WHERE s.token = p_token
AND s.actif = true
AND s.date_expiration > CURRENT_TIMESTAMP
AND u.actif = true
);
END;
$$ LANGUAGE plpgsql;




-- TASK 26 

-- token retourné : "1f3d8e3a-a031-4116-8ace-8c83d56761e5"

