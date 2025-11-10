const express = require('express');
const pool = require('./database/db');
const authRoutes = require('./routes/authRoutes');
const app = express();
const PORT = process.env.PORT || 3000;
// Middleware
app.use(express.json());
// Routes
app.use('/api/auth', authRoutes);
// Health check
app.get('/api/health', async (req, res) => {
// À COMPLÉTER
// Testez la connexion avec SELECT NOW()
});
app.listen(PORT, () => {
console.log(`🚀 Serveur démarré sur http://localhost:${PORT}`);
});