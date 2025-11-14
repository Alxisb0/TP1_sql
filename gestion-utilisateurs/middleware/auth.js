const pool = require('../database/db');

async function requireAuth(req, res, next) {
  const token = req.headers['authorization'];
  if (!token) {
    return res.status(401).json({ error: 'Token manquant' });
  }

  try {
    const result = await pool.query(
      `SELECT utilisateurs.* 
       FROM sessions 
       JOIN utilisateurs ON sessions.utilisateur_id = utilisateurs.id 
       WHERE sessions.token = $1 
         AND sessions.actif = true 
         AND utilisateurs.actif = true 
         AND sessions.date_expiration > NOW()`,
      [token]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Token invalide ou expiré' });
    }

    req.user = result.rows[0];
    next();
  } catch (error) {
    console.error('Erreur middleware auth:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
}




async function requireAuthWithFunction(req, res, next) {
  const token = req.headers['authorization'];

  if (!token) {
    return res.status(401).json({ error: 'Token manquant' });
  }

  try {
    const validResult = await pool.query(
      'SELECT est_token_valide($1) AS valide',
      [token]
    );

    if (!validResult.rows[0].valide) {
      return res.status(401).json({ error: 'Token invalide ou expiré' });
    }

    const userResult = await pool.query(
      `SELECT s.utilisateur_id, u.email, u.nom, u.prenom
       FROM sessions s
       INNER JOIN utilisateurs u ON s.utilisateur_id = u.id
       WHERE s.token = $1`,
      [token]
    );

    req.user = userResult.rows[0];
    next();
  } catch (error) {
    console.error('Erreur middleware auth:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
}




module.exports = {requireAuth,requireAuthWithFunction };
