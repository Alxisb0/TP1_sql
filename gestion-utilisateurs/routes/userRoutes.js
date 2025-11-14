const express = require('express');
const router = express.Router();
const pool = require('../database/db');
const { requireAuth } = require('../middleware/auth');

router.get('/', requireAuth, async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const offset = (page - 1) * limit;

  try {
    const totalResult = await pool.query(`SELECT COUNT(*) AS total FROM utilisateurs`);
    const total = parseInt(totalResult.rows[0].total);

    const usersResult = await pool.query(
      `SELECT utilisateurs.id,
              utilisateurs.email,
              utilisateurs.nom,
              utilisateurs.prenom,
              utilisateurs.actif,
              array_agg(roles.nom) AS roles
       FROM utilisateurs
       LEFT JOIN utilisateur_roles ON utilisateur_roles.utilisateur_id = utilisateurs.id
       LEFT JOIN roles ON roles.id = utilisateur_roles.role_id
       GROUP BY utilisateurs.id
       ORDER BY utilisateurs.id
       LIMIT $1 OFFSET $2`,
      [limit, offset]
    );

    res.json({
      page: page,
      limit: limit,
      total: total,
      total_pages: Math.ceil(total / limit),
      users: usersResult.rows
    });

  } catch (error) {
    console.error('Erreur liste utilisateurs:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// PUT /api/users/:id
router.put('/:id', requireAuth, async (req, res) => {
  const { id } = req.params;
  const { nom, prenom, actif } = req.body;

  try {
    const result = await pool.query(
      `UPDATE utilisateurs
       SET nom = $1,
           prenom = $2,
           actif = $3,
           date_modification = NOW()
       WHERE id = $4
       RETURNING id, email, nom, prenom, actif, date_modification`,
      [nom, prenom, actif, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    res.json({
      message: 'Utilisateur mis à jour',
      user: result.rows[0]
    });

  } catch (error) {
    console.error('Erreur mise à jour utilisateur:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// DELETE /api/users/:id
router.delete('/:id', requireAuth, async (req, res) => {
  const { id } = req.params;

  if (parseInt(id) === req.user.id) {
    return res.status(400).json({
      error: 'Vous ne pouvez pas supprimer votre propre compte.'
    });
  }

  try {
    const result = await pool.query(
      `DELETE FROM utilisateurs
       WHERE id = $1
       RETURNING id, email, nom, prenom, actif`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    res.json({
      message: 'Utilisateur supprimé',
      user: result.rows[0]
    });
  } catch (error) {
    console.error('Erreur suppression utilisateur:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});






// GET /api/users/:id
router.get('/:id', requireAuth, async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query(
      `SELECT 
          id, email, nom, prenom, actif, date_creation, date_modification
       FROM utilisateurs
       WHERE id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    res.json({ user: result.rows[0] });

  } catch (error) {
    console.error('Erreur récupération utilisateur:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});



// GET /api/users/:id/permissions
router.get('/:id/permissions', requireAuth, async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query(
      `SELECT DISTINCT 
          permissions.nom,
          permissions.ressource,
          permissions.action,
          permissions.description
       FROM utilisateurs
       INNER JOIN utilisateur_roles 
          ON utilisateur_roles.utilisateur_id = utilisateurs.id
       INNER JOIN roles 
          ON roles.id = utilisateur_roles.role_id
       INNER JOIN role_permissions 
          ON role_permissions.role_id = roles.id
       INNER JOIN permissions 
          ON permissions.id = role_permissions.permission_id
       WHERE utilisateurs.id = $1`,
      [id]
    );

    res.json({
      utilisateur_id: parseInt(id),
      permissions: result.rows
    });

  } catch (error) {
    console.error('Erreur récupération permissions:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;
