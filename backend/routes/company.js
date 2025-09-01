const express = require('express');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const Company = require('../db/models/Company');

const router = express.Router();

// Minimal auth middleware (JWT in Authorization header)
function auth(req, res, next) {
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Missing token' });
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded; // { id, role, iat, exp }
    next();
  } catch (e) {
    return res.status(401).json({ error: 'Invalid/expired token' });
  }
}

function requireCompany(req, res, next) {
  if (req.user?.role !== 'Company') {
    return res.status(403).json({ error: 'Company access required' });
  }
  next();
}

/**
 * GET /api/company/me
 * Returns company profile (excluding email & password)
 */
router.get('/me', auth, requireCompany, async (req, res) => {
  const id = req.user.id;
  const company = await Company.findById(id).select(
    'name description location contactInfo createdAt updatedAt'
  );
  if (!company) return res.status(404).json({ error: 'Company not found' });
  res.json({ company });
});

/**
 * PUT /api/company
 * Update allowed fields
 * body: { name?, description?, location?, contactInfo? }
 */
router.put('/', auth, requireCompany, async (req, res) => {
  const id = req.user.id;
  const allowed = ['name', 'description', 'location', 'contactInfo'];
  const update = {};
  for (const k of allowed) {
    if (k in req.body) update[k] = req.body[k];
  }

  try {
    const company = await Company.findByIdAndUpdate(id, update, {
      new: true,
      runValidators: true,
      select: 'name description location contactInfo createdAt updatedAt',
    });
    if (!company) return res.status(404).json({ error: 'Company not found' });
    res.json({ message: 'Updated', company });
  } catch (err) {
    if (err.name === 'ValidationError') {
      return res.status(400).json({ error: err.message });
    }
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

/**
 * DELETE /api/company
 * Deletes the company account
 */
router.delete('/', auth, requireCompany, async (req, res) => {
  const id = req.user.id;
  const doc = await Company.findByIdAndDelete(id);
  if (!doc) return res.status(404).json({ error: 'Company not found' });
  res.json({ message: 'Deleted' });
});


// GET /api/company/:id  (public read)
// Returns a subset of fields safe for public display
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ error: 'Invalid company id' });
    }

    const company = await Company.findById(id)
      .select('name description location contactInfo createdAt updatedAt')
      .lean();

    if (!company) {
      return res.status(404).json({ error: 'Company not found' });
    }

    return res.json({ company });
  } catch (err) {
    console.error('GET /api/company/:id error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
