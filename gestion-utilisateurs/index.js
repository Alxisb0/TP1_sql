const express = require('express');
const pool = require('./database/db');
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');

const app = express();
const PORT = process.env.PORT || 3000;
// Middleware
app.use(express.json());
// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
// Health check
app.get('/api/health', async (req, res) => {
    try {
        const result = await pool.query('SELECT NOW()');
        res.json({
            status: 'OK',
            database: 'Connected',
            time: result.rows[0].now
        });
    } catch (err) {
        console.error('Erreur connexion DB:', err);
        res.status(500).json({
            status: 'ERROR',
            message: 'Impossible de se connecter à la base'
        });
    }
});

app.listen(PORT, () => {
console.log(`🚀 Serveur démarré sur http://localhost:${PORT}`);
});